"""
Nila Agent — The Brain (Council Mode)
Multi-LLM Council system: Gemini + Groq + OpenRouter + Ollama collaborate.
Uses the new google.genai SDK. Fully bilingual (Tamil + English).
"""

import asyncio
import json
import re
from typing import Dict, AsyncIterator
from datetime import datetime

from google import genai
from google.genai import types

from core.config import (
    GOOGLE_API_KEY, MODEL_NAME, MAX_TOKENS,
    OLLAMA_HOST, OLLAMA_MODEL, MAX_LOCAL_TOKENS, LOCAL_LLM_TEMPERATURE,
    PROJECT_DIR, FORCE_MODEL, WORKSPACE_DIR,
)
from core.memory import MemoryStore
from core.token_tracker import TokenTracker
from tools.scraper import scrape_web
from tools.summariser import summarise_text
from tools.reasoner import reflect_and_plan
from llm.ollama_client import OllamaClient
from llm.router import HybridRouter, classify_speed
from llm.local_model import LocalModel
from llm.web_search_chain import WebSearchChain
from agents.terminal_agent import (
    TerminalAgent, detect_terminal_action,
    extract_command, extract_path, extract_file_content,
)
from training.self_trainer import SelfTrainer
from training.memory_trainer import MemoryTrainer
from training.conversation_trainer import ConversationTrainer
from training.local_model_adapter import LocalModelAdapter
from knowledge.personal_kb import PersonalKB
from agents.course_agent import CourseAgent, extract_course_params
from agents.schedule_agent import ScheduleAgent
from agents.progress_tracker import ProgressTracker
from agents.data_query import DataQueryEngine
from training.ollama_trainer import OllamaTrainer
from tools.system_actions import SystemActions
from core.context_chain import ContextChain


AGENT_TRIGGERS = {
    "create_course": [
        "prepare a course", "create a course", "make a course", "i want to learn",
        "help me learn", "teach me", "course for", "learning plan", "study plan",
        "koviku sollu", "padikanum", "course pottu kodu",
    ],
    "store_knowledge": [
        "remember this", "store this", "save this", "my project is", "the file is at",
        "the location is", "note this", "keep this", "i am working on",
    ],
    "recall_knowledge": [
        "what do you know about", "where is the", "where is my", "what was", "tell me about my",
        "recall", "what did i say about", "enna sonna", "enge iruku", "sollu",
    ],
    "show_schedule": [
        "show my schedule", "today's tasks", "what do i have today", "daily plan",
        "intha vaaram", "enna pananum today",
    ],
    "mark_complete": [
        "i completed", "done with", "finished", "pannitten", "mudichuten",
        "complete panniten",
    ],
}


def detect_agent_action(user_message: str) -> str:
    """Returns action type or 'chat' for normal conversation."""
    msg = user_message.lower().strip()
    exact_commands = {
        "today": "show_schedule",
        "schedule": "show_schedule",
        "courses": "list_courses",
        "progress": "progress",
    }
    if msg in exact_commands and len(msg.split()) == 1:
        return exact_commands[msg]
    if re.search(r"\bdone\s+day\s+\d+\b", msg):
        return "mark_complete"
    if msg == "done":
        return "mark_complete"
    if msg == "quiz":
        return "quiz"
    if re.search(r"\bshow\s+day\s+\d+\b", msg):
        return "show_day"
    if re.search(r"\bnotes\s+.+\s+day\s+\d+\b", msg):
        return "show_notes"
    for action, phrases in AGENT_TRIGGERS.items():
        if any(phrase in msg for phrase in phrases):
            return action
    return "chat"


# ──────────────────────────────────────────────────────────────────────
# Language detection
# ──────────────────────────────────────────────────────────────────────

def detect_language(text: str) -> str:
    """Detect if message is Tamil script, Tanglish, or English."""
    # Tamil Unicode range: U+0B80 to U+0BFF
    tamil_chars = sum(1 for c in text if '\u0B80' <= c <= '\u0BFF')

    if tamil_chars > 0:
        return "tamil_script"

    # Tanglish detection — common Tamil words in English letters
    tanglish_words = [
        "enaku", "naan", "ungaluku", "enna", "epdi", "evlo", "yenna",
        "poren", "vandhen", "sollu", "seri", "illa", "ama", "therium",
        "theriyala", "pannuven", "paakalam", "konjam", "romba", "vera",
        "da", "di", "bro", "machan", "kanna", "inge", "ange", "eppadi",
        "saapidu", "pasikuthu", "thanni", "kadai", "veettu", "office",
        "porom", "varom", "iruken", "iruku", "mattom", "mudiyathu",
        "pannanum", "panna", "vanakkam", "nalla", "thala", "maapla",
        "ooru", "paaru", "solla", "kelunga", "sollunga", "vaanga",
        "saapadu", "sapadu", "gym", "velai", "padikka", "padichiten",
        "marandhutten", "marandhu", "aachuna", "inniku", "naalaikku",
        "naalu", "rendu", "moonu", "tired", "pasikuthu",
    ]

    text_lower = text.lower()
    # Match whole words to avoid false positives (e.g., "da" in "data")
    import re
    tanglish_count = sum(
        1 for word in tanglish_words
        if re.search(r'\b' + re.escape(word) + r'\b', text_lower)
    )

    if tanglish_count >= 1:
        return "tanglish"

    return "english"


def _get_language_instruction(lang: str) -> str:
    """Return language instruction to prepend to messages."""
    if lang == "tamil_script":
        return (
            "IMPORTANT: The user wrote in Tamil script. You MUST respond "
            "entirely in Tamil script (தமிழ்). Do not use English."
        )
    elif lang == "tanglish":
        return (
            "IMPORTANT: The user wrote in Tanglish (Tamil in English letters). "
            "Respond in Tanglish — Tamil words written in English letters. "
            "Be natural and casual like a Tamil friend."
        )
    else:
        return "Respond in English."


# ──────────────────────────────────────────────────────────────────────
# Tool definitions — passed to Gemini via the new SDK
# ──────────────────────────────────────────────────────────────────────

TOOL_DECLARATIONS = [
    types.FunctionDeclaration(
        name="search_and_scrape",
        description=(
            "Search the web or scrape a specific URL to get live, current information. "
            "Use this whenever you need facts, news, tutorials, documentation, restaurants, "
            "locations, or any real-world data. Call this proactively — do not wait for "
            "the user to ask you to search."
        ),
        parameters=types.Schema(
            type="OBJECT",
            properties={
                "query": types.Schema(
                    type="STRING",
                    description="The search query to look up",
                ),
                "url": types.Schema(
                    type="STRING",
                    description="Optional: specific URL to scrape directly",
                ),
            },
            required=["query"],
        ),
    ),
    types.FunctionDeclaration(
        name="store_memory",
        description=(
            "Store an important fact, goal, or note about the user into persistent "
            "local memory. Use this whenever the user shares something important."
        ),
        parameters=types.Schema(
            type="OBJECT",
            properties={
                "memory_type": types.Schema(
                    type="STRING",
                    description="Type of memory: fact, goal, or note",
                ),
                "key": types.Schema(
                    type="STRING",
                    description="Key name for facts (e.g. 'user_name')",
                ),
                "value": types.Schema(
                    type="STRING",
                    description="The content to store",
                ),
            },
            required=["memory_type", "value"],
        ),
    ),
    types.FunctionDeclaration(
        name="recall_memory",
        description=(
            "Retrieve stored facts, goals, or notes from local memory."
        ),
        parameters=types.Schema(
            type="OBJECT",
            properties={
                "memory_type": types.Schema(
                    type="STRING",
                    description="What to retrieve: fact, goal, note, or all",
                ),
                "key": types.Schema(
                    type="STRING",
                    description="Specific key for facts",
                ),
            },
            required=["memory_type"],
        ),
    ),
    types.FunctionDeclaration(
        name="create_action_plan",
        description=(
            "Generate a structured daily action plan for a goal."
        ),
        parameters=types.Schema(
            type="OBJECT",
            properties={
                "goal": types.Schema(
                    type="STRING",
                    description="The goal to plan for",
                ),
                "duration": types.Schema(
                    type="STRING",
                    description="Timeframe (e.g. '3 months', '6 weeks')",
                ),
            },
            required=["goal"],
        ),
    ),
]


# ──────────────────────────────────────────────────────────────────────
# System prompt
# ──────────────────────────────────────────────────────────────────────

SYSTEM_PROMPT_TEMPLATE = """\
LANGUAGE INTELLIGENCE:
You are fully bilingual in Tamil and English.

Detection rules:
- If the user writes in Tamil script (Tamil Unicode characters) → respond FULLY in Tamil
- If the user writes in Tanglish (Tamil words in English letters, like "enaku pasikuthu", \
"naan gym poren", "enna pannanum") → respond in Tanglish (Tamil in English letters)
- If the user writes in English → respond in English
- NEVER mix languages unless the user does first
- NEVER say "I don't speak Tamil" — you speak it fluently
- Match the user's exact language style and formality level

Tamil personality guidelines:
- Use natural conversational Tamil, not formal/stiff Tamil
- Use common Tamil expressions: "seri", "okay", "illa", "enna", "nalla"
- For Tanglish: match exactly — "pasikuthu-na saapidu da" style responses
- Be warm like a real Tamil friend, not a translator bot
- Never transliterate unnecessarily — if they write Tamil, reply Tamil

TANGLISH EXAMPLES (learn this style):

User: "enaku pasikuthu"
Nila: "Seri da, enna saapidanum? Kitte irukka restaurant search pannattuma, \
illa nee veetla iruka-na enna irukku sollu, quick idea solren!"

User: "naan gym poga marandhutten"
Nila: "Aiyoo! Okay, tomorrow morning forget pannatha. Ipo late aayidichu, \
kal 6am ku alarm vachuko. Consistency thaan muttikku mutti da!"

User: "enna pannanum today"
Nila: "Unoda goals paathen — [list goals here]. Ipo morning aachuna \
learning start pannu, evening gym po. Oru step oru time!"

User: "romba tired a iruku"
Nila: "Understand da. But goals wait pannatha. Konjam rest eduthutu, \
20 minutes aachum padichu po. Small progress also progress thaan!"

---

You are Nila — a personal AI life coach and accountability partner built into \
YearZero, a personal operating system.

Your personality:
- Warm but direct. You care about the user's growth.
- You call the user by name when you know it.
- You are not a generic assistant. You are deeply personal.
- You remember everything the user tells you.
- You proactively notice patterns and push back when the user is inconsistent.

Your capabilities:
- You can search the web and scrape any website to get real information.
- You have persistent local memory — you remember the user across sessions.
- You can create structured action plans and roadmaps.
- You verify effort and challenge the user when they report progress.

Rules you follow:
- ALWAYS recall memory at the start of the first message in each session.
- ALWAYS search the web proactively when you need current facts, tutorials, \
restaurants, locations, or information.
- NEVER make up facts — if you don't know something, search for it.
- Store important user information in memory automatically.
- Be concise but complete. Avoid unnecessary filler.

Current date: {current_date}
User memory summary: {memory_summary}
"""

# System prompt for Mistral (offline fallback — no tools, memory-only)
MISTRAL_SYSTEM_PROMPT = """\
LANGUAGE INTELLIGENCE:
You are fully bilingual in Tamil and English.
- If the user writes in Tamil script → respond FULLY in Tamil script
- If the user writes in Tanglish (Tamil in English letters) → respond in Tanglish
- If the user writes in English → respond in English
- Be warm like a real Tamil friend

You are Nila, a personal AI life coach for YearZero.
You know this user deeply from their stored data.

USER PROFILE:
{facts_json}

ACTIVE GOALS:
{goals_list}

RECENT CONVERSATION:
{last_5_messages}

Today's date: {current_date}

Instructions:
- You ARE Nila. Never break character.
- Answer based ONLY on what you know about this user.
- If asked about tasks today, refer to their goals and suggest relevant actions.
- Be warm, direct, and personal. Use their name if you know it.
- Keep responses concise (under 150 words unless they ask for detail).
- Never say "I don't have access to..." — instead infer from what you know.
"""


class NilaAgent:
    """
    Core Nila agent — Speed-first routing with multi-LLM fallback.

    Routing:
    1. DataQueryEngine — instant JSON answers (no AI)
    2. System commands — model switching, clearing history
    3. Agent triggers — course creation, KB store/recall
    4. Speed classifier → instant_local / needs_web / standard_local / standard_online
    """

    MAX_TOOL_ITERATIONS = 5

    def __init__(self):
        self.memory = MemoryStore()
        self.personal_kb = PersonalKB(self.memory)
        self.course_agent = CourseAgent()
        self.schedule_agent = ScheduleAgent()
        self.progress_tracker = ProgressTracker()
        self.data_engine = DataQueryEngine()
        self.client = genai.Client(api_key=GOOGLE_API_KEY)
        self.course_agent.gemini_client = self.client
        self.ollama = OllamaClient(host=OLLAMA_HOST, model=OLLAMA_MODEL)
        self._ensure_ollama_model_fallback()
        self.ollama_trainer = OllamaTrainer(gemini_client=self.client)
        self.trainer = SelfTrainer(self.memory)

        # New: Continuous learning trainers
        self.conversation_trainer = ConversationTrainer()
        self.model_adapter = LocalModelAdapter()

        self._is_first_message = True

        # Token tracking
        self.token_tracker = TokenTracker()

        # Track last query for retry commands
        self.last_query = None
        self.last_route = None

        # Health checks
        self._gemini_available = bool(GOOGLE_API_KEY)

        # Local model — pre-warmed for instant responses
        self.local = LocalModel(host=OLLAMA_HOST)
        self._ollama_available = self.local.is_available()

        # Track last routing decision for UI
        self.last_route = None

        # Router for statistics
        self.router = HybridRouter()

        # Initialize online providers for web search chain
        self._groq = None
        self._openrouter = None
        try:
            from llm.providers.groq_client import GroqClient
            self._groq = GroqClient()
        except Exception:
            pass
        try:
            from llm.providers.openrouter_client import OpenRouterClient
            self._openrouter = OpenRouterClient()
        except Exception:
            pass

        # Web search chain — auto-failover across providers
        self.web_chain = WebSearchChain(
            gemini_chat_fn=self._chat_gemini,
            groq_client=self._groq,
            openrouter_client=self._openrouter,
            local_model=self.local,
        )

        # Force model state (for manual switching)
        self.force_model = FORCE_MODEL

        # Terminal agent -- file system + command execution
        self.terminal = TerminalAgent()
        self._pending_delete = None

        # Store provider references for direct access in terminal actions
        self.gemini = self.client
        self.groq = self._groq
        self.openrouter = self._openrouter
        self.last_file_context = None
        self.context_chain = ContextChain()
        self.system_actions = SystemActions()

        # Voice Mode State
        self.voice_mode = False
        
        # Initialize StreamManager
        import os
        from core.config import GROQ_API_KEY, GROQ_MODEL
        from llm.stream_manager import StreamManager
        self.stream_manager = StreamManager(
            ollama_host=OLLAMA_HOST,
            ollama_model=OLLAMA_MODEL,
            groq_api_key=GROQ_API_KEY,
            groq_model=GROQ_MODEL,
            gemini_client=self.client
        )


    def _ensure_ollama_model_fallback(self):
        """Deprecated — LocalModel handles auto-detection now."""
        pass

    # ------------------------------------------------------------------
    # Public interface
    # ------------------------------------------------------------------

    def chat(self, user_message: str) -> tuple[str, str]:
        # Handle clear command to reset context chain
        cmd = user_message.strip().lower()
        if cmd == "clear":
            self.context_chain.clear()

        response, route = self._chat_internal(user_message)

        # Don't add system/data query errors/status or none routes to history
        if route not in ["SYSTEM", "LEARNING_STATUS", "NONE"] and response:
            self.context_chain.add_exchange(user_message, response)

        return response, route

    def set_voice_mode(self, enabled: bool):
        self.voice_mode = enabled

    async def chat_async(self, user_message: str) -> tuple[str, str]:
        """Async version of chat(), running _chat_internal in an executor to preserve RAG/PKB."""
        cmd = user_message.strip().lower()
        if cmd == "clear":
            self.context_chain.clear()

        loop = asyncio.get_event_loop()
        response, route = await loop.run_in_executor(None, self._chat_internal, user_message)

        if route not in ["SYSTEM", "LEARNING_STATUS", "NONE"] and response:
            self.context_chain.add_exchange(user_message, response)

        return response, route

    async def chat_stream(self, user_message: str) -> AsyncIterator[str]:
        """
        Stream LLM responses. If the request matches a fast-path system, terminal, 
        or data command, the full result is yielded at once.
        Otherwise, yields tokens on the fly from Ollama, Groq, or Gemini, 
        preserving memory context and system prompts.
        """
        cmd = user_message.strip().lower()
        if cmd == "clear":
            self.context_chain.clear()
            yield "Context chain cleared."
            return

        loop = asyncio.get_event_loop()

        # Check fast paths (data queries, system commands, agent triggers, system actions, terminal actions)
        # Priority 1: DataQueryEngine
        if self.data_engine.must_handle(user_message):
            query_type = self.data_engine.detect_data_query(user_message) or "list_courses"
            response = await loop.run_in_executor(None, self.data_engine.answer, query_type, user_message)
            self.last_route = "DATA_QUERY"
            self.router.record("DATA_QUERY")
            self.memory.add_message("assistant", response)
            yield response
            return

        # Priority 2: System commands
        if cmd in {"learning", "stats", "status", "progress", "nila status"}:
            learning_status = await loop.run_in_executor(None, self.get_learning_status)
            response = self._format_learning_report(learning_status) if learning_status else "🧠 Learning system initializing..."
            self.memory.add_message("assistant", response)
            self.last_route = "LEARNING_STATUS"
            yield response
            return

        system_response = await loop.run_in_executor(None, self._handle_system_command, cmd)
        if system_response is not None:
            self.last_route = "SYSTEM"
            self.router.record("SYSTEM")
            self.memory.add_message("assistant", system_response)
            yield system_response
            return

        # Priority 3: Agent triggers
        direct_response = await loop.run_in_executor(None, self._handle_agent_action, user_message)
        if direct_response is not None:
            self.last_route = "AGENT_MODE"
            self.router.record("AGENT_MODE")
            self.memory.add_message("assistant", direct_response)
            await loop.run_in_executor(None, self._run_trainer, user_message, direct_response)
            yield direct_response
            return

        # Priority 4.25: System actions
        def _check_sys_action():
            return self.system_actions.try_system_action(user_message)
        handled, sys_response = await loop.run_in_executor(None, _check_sys_action)
        if handled:
            self.last_route = "SYSTEM_ACTION"
            self.router.record("SYSTEM")
            self.memory.add_message("assistant", sys_response)
            yield sys_response
            return

        # Priority 4.5: Terminal Agent
        terminal_result = await loop.run_in_executor(None, self._try_terminal_action, user_message)
        if terminal_result is not None:
            self.last_route = "TERMINAL_ACTION"
            self.router.record("TERMINAL")
            self.memory.add_message("assistant", terminal_result)
            yield terminal_result
            return

        # LLM route determination (mimics Priority 4.75 and 5)
        provider = "auto"
        route_name = "ONLINE_GEMINI"
        
        if self.force_model:
            provider = self.force_model
            route_name = f"FORCED_{self.force_model.upper()}"
        else:
            speed = classify_speed(user_message)
            if speed == "terminal_action":
                # Fallback to general terminal handler
                response = await loop.run_in_executor(None, self._handle_terminal_action, user_message)
                if response is not None:
                    self.last_route = "TERMINAL_ACTION"
                    self.router.record("TERMINAL")
                    self.memory.add_message("assistant", response)
                    yield response
                    return
            elif speed == "instant_local":
                provider = "ollama"
                route_name = "INSTANT_LOCAL"
            elif speed == "needs_web":
                # Web search requires scraping and full response assembly before yielding
                response, route = await loop.run_in_executor(
                    None,
                    self.web_chain.search_and_answer,
                    user_message,
                    self.memory.get_context(),
                    self.memory.get_history(last_n=10)[:-1],
                    _get_language_instruction(detect_language(user_message)),
                    self.context_chain.get_chain_prompt()
                )
                self.last_route = route
                self.router.record(route)
                self.memory.add_message("assistant", response)
                await loop.run_in_executor(None, self._run_trainer, user_message, response)
                yield response
                return
            elif speed == "standard_local":
                provider = "ollama"
                route_name = "OFFLINE_LOCAL_LLM"
            else:
                provider = "gemini"
                route_name = "ONLINE_GEMINI"

        self.last_route = route_name
        
        # Build prompt & history for streaming LLM (exact RAG + PKB context injection)
        if provider == "ollama":
            facts = self.memory.get_all_facts()
            goals = self.memory.get_goals()
            history = self.memory.get_history(last_n=5)
            kb_context = self.personal_kb.get_all_context()
            course_summary = self.data_engine.get_course_summary_for_context()
            
            facts_json = json.dumps(facts, indent=2, ensure_ascii=False) if facts else "{}"
            active_goals = [g for g in goals if g.get("status") == "active"]
            goals_list = "\n".join(f"- {g['goal']}" for g in active_goals) if active_goals else "No active goals."
            last_5 = "\n".join(f"{m['role'].upper()}: {m['content'][:150]}" for m in history[-5:]) if history else "No history yet."
            
            system_prompt = MISTRAL_SYSTEM_PROMPT.format(
                facts_json=facts_json,
                goals_list=goals_list,
                last_5_messages=last_5,
                current_date=datetime.now().strftime("%A, %B %d, %Y — %I:%M %p"),
            )
            if course_summary:
                system_prompt += f"\n\n=== THEO'S CURRENT DATA ===\n{course_summary}\n\n=== END OF DATA ==="
            if kb_context:
                system_prompt += f"\n\nYOUR PERSONAL KNOWLEDGE BASE:\n{kb_context}"
        else:
            system_prompt = SYSTEM_PROMPT_TEMPLATE.format(
                current_date=datetime.now().strftime("%A, %B %d, %Y — %I:%M %p"),
                memory_summary=self.memory.get_summary(),
            )
            chain_prompt = self.context_chain.get_chain_prompt()
            if chain_prompt:
                system_prompt = f"{chain_prompt}\n\n{system_prompt}"
                
            kb_context = self.personal_kb.get_all_context()
            if kb_context:
                system_prompt += f"""

YOUR PERSONAL KNOWLEDGE BASE ABOUT THEO:
{kb_context}

This is Theo's personal data. Use it to answer questions about his work.
If Theo asks "what is the location of X" or "what did I say about Y", search this KB first before anything else.
NEVER say you don't know something that's in this KB.
"""

        # Appending voice mode specific personality modifier if enabled
        if getattr(self, "voice_mode", False):
            system_prompt += "\n\nIMPORTANT: You are in VOICE mode. Be brief, friendly, and conversational. Do NOT use markdown formatting, code blocks, or bullet points in your response."

        # Fetch history
        history_msgs = self.memory.get_history(last_n=10)[:-1]

        # Stream via StreamManager
        response_text = ""
        try:
            async for token in self.stream_manager.stream(
                user_message=user_message,
                system_prompt=system_prompt,
                history=history_msgs,
                provider=provider
            ):
                response_text += token
                yield token
        except Exception:
            # Fallback to sync chat
            response_text, route_name = await self.chat_async(user_message)
            yield response_text
            return

        # Record assistant response in memory
        if response_text:
            self.memory.add_message("assistant", response_text)
            self.context_chain.add_exchange(user_message, response_text)
            await loop.run_in_executor(None, self._run_trainer, user_message, response_text)


    def _chat_internal(self, user_message: str) -> tuple[str, str]:
        """
        Process a user message with speed-first routing:
        1. DataQueryEngine — instant JSON answers (no AI)
        2. System commands — model switching
        3. Agent triggers — course creation, KB store/recall
        4. Speed classifier → instant_local / needs_web / standard_local / standard_online

        Returns:
            Tuple of (response_text, route_used)
        """
        # Detect language
        lang = detect_language(user_message)
        lang_instruction = _get_language_instruction(lang)

        # Record the user's message
        self.memory.add_message("user", user_message)

        # Track last query for retry commands
        self.last_query = user_message

        # Priority 1: DataQueryEngine — answer from JSON directly, no AI
        if self.data_engine.must_handle(user_message):
            query_type = self.data_engine.detect_data_query(user_message) or "list_courses"
            response = self.data_engine.answer(query_type, user_message)
            self.last_route = "DATA_QUERY"
            self.router.record("DATA_QUERY")
            self.memory.add_message("assistant", response)
            return response, "DATA_QUERY"

        # Priority 2: System commands (model switching)
        cmd = user_message.strip().lower()

        # Learning status commands
        if cmd in {"learning", "stats", "status", "progress", "nila status"}:
            learning_status = self.get_learning_status()
            if learning_status:
                response = self._format_learning_report(learning_status)
            else:
                response = "🧠 Learning system initializing..."
            self.memory.add_message("assistant", response)
            return response, "LEARNING_STATUS"

        system_response = self._handle_system_command(cmd)
        if system_response is not None:
            self.last_route = "SYSTEM"
            self.router.record("SYSTEM")
            self.memory.add_message("assistant", system_response)
            return system_response, "SYSTEM"

        # Priority 3: Agent triggers (course creation, KB store/recall, etc.)
        direct_response = self._handle_agent_action(user_message)
        if direct_response is not None:
            self.last_route = "AGENT_MODE"
            self.router.record("AGENT_MODE")
            self.memory.add_message("assistant", direct_response)
            self._run_trainer(user_message, direct_response)
            return direct_response, "AGENT_MODE"

        # Priority 4.25: System actions (volume, bluetooth, apps, URLs)
        handled, sys_response = self.system_actions.try_system_action(user_message)
        if handled:
            self.last_route = "SYSTEM_ACTION"
            self.router.record("SYSTEM")
            self.memory.add_message("assistant", sys_response)
            return sys_response, "SYSTEM_ACTION"

        # Priority 4.5: Terminal Agent — check BEFORE routing to any LLM
        terminal_result = self._try_terminal_action(user_message)
        if terminal_result is not None:
            self.last_route = "TERMINAL_ACTION"
            self.router.record("TERMINAL")
            self.memory.add_message("assistant", terminal_result)
            return terminal_result, "TERMINAL_ACTION"

        # Priority 4.75: Forced model override
        if self.force_model:
            return self._handle_forced_model(user_message, lang_instruction, lang)

        # Priority 5: Speed-first routing
        speed = classify_speed(user_message)

        if speed == "terminal_action":
            # Fallback to general terminal handler
            response = self._handle_terminal_action(user_message)
            if response is not None:
                self.last_route = "TERMINAL_ACTION"
                self.router.record("TERMINAL")
                self.memory.add_message("assistant", response)
                return response, "TERMINAL_ACTION"

        elif speed == "instant_local":
            # INSTANT — local model, no API call, sub-second
            response = self.local.quick_reply(
                user_message,
                self.memory.get_quick_context(),
                history=self.memory.get_history(last_n=10)[:-1],
                language=lang,
                context_chain=self.context_chain.get_chain_prompt(),
            )
            self.last_route = "INSTANT_LOCAL"
            self.router.record("OFFLINE_LOCAL")
            self.memory.add_message("assistant", response)
            return response, "INSTANT_LOCAL"

        elif speed == "needs_web":
            # WEB SEARCH — scrape + provider chain
            response, route = self.web_chain.search_and_answer(
                user_message,
                self.memory.get_context(),
                history=self.memory.get_history(last_n=10)[:-1],
                lang_instruction=lang_instruction,
                context_chain=self.context_chain.get_chain_prompt(),
            )
            self.last_route = route
            self.router.record(route)
            self.memory.add_message("assistant", response)
            self._run_trainer(user_message, response)
            # Track tokens for web queries
            tokens_in = self.token_tracker.estimate_tokens(user_message)
            tokens_out = self.token_tracker.estimate_tokens(response)
            if "gemini" in route.lower():
                self.token_tracker.record("gemini", tokens_in, tokens_out)
            elif "groq" in route.lower():
                self.token_tracker.record("groq", tokens_in, tokens_out)
            elif "openrouter" in route.lower():
                self.token_tracker.record("openrouter", tokens_in, tokens_out)
            else:
                self.token_tracker.record("local")
            return response, route

        elif speed == "standard_local":
            # LOCAL with full memory context
            response = self.local.reply_with_memory(
                user_message,
                self.memory.get_context(),
                history=self.memory.get_history(last_n=10)[:-1],
                language=lang,
                context_chain=self.context_chain.get_chain_prompt(),
            )
            self.last_route = "OFFLINE_LOCAL_LLM"
            self.router.record("OFFLINE_LOCAL")
            self.memory.add_message("assistant", response)
            self._run_trainer(user_message, response)
            return response, "OFFLINE_LOCAL_LLM"

        else:  # standard_online
            # ONLINE — Gemini with tool loop, then fallback chain
            try:
                response = self._chat_gemini(user_message, lang_instruction)
                if response and len(response.strip()) > 5:
                    self.last_route = "ONLINE_GEMINI"
                    self.router.record("ONLINE_GEMINI")
                    self.memory.add_message("assistant", response)
                    self._run_trainer(user_message, response)
                    # Track tokens
                    tokens_in = self.token_tracker.estimate_tokens(user_message)
                    tokens_out = self.token_tracker.estimate_tokens(response)
                    self.token_tracker.record("gemini", tokens_in, tokens_out)
                    return response, "ONLINE_GEMINI"
            except Exception:
                pass

            # Gemini failed — try Groq
            if self._groq and self._groq.is_available():
                try:
                    response = self._groq.chat(
                        user_message,
                        system_prompt=self._build_online_system_prompt(),
                        memory_context=self.memory.get_context(),
                        history=self.memory.get_history(last_n=10)[:-1],
                    )
                    if response and len(response.strip()) > 5:
                        self.last_route = "ONLINE_GROQ"
                        self.router.record("ONLINE_GROQ")
                        self.memory.add_message("assistant", response)
                        self._run_trainer(user_message, response)
                        # Track tokens
                        tokens_in = self.token_tracker.estimate_tokens(user_message)
                        tokens_out = self.token_tracker.estimate_tokens(response)
                        self.token_tracker.record("groq", tokens_in, tokens_out)
                        return response, "ONLINE_GROQ"
                except Exception:
                    pass

            # Groq failed — try OpenRouter
            if self._openrouter and self._openrouter.is_available():
                try:
                    response = self._openrouter.chat(
                        user_message,
                        system_prompt=self._build_online_system_prompt(),
                        memory_context=self.memory.get_context(),
                        history=self.memory.get_history(last_n=10)[:-1],
                    )
                    if response and len(response.strip()) > 5:
                        self.last_route = "ONLINE_OPENROUTER"
                        self.router.record("ONLINE_OPENROUTER")
                        self.memory.add_message("assistant", response)
                        self._run_trainer(user_message, response)
                        # Track tokens
                        tokens_in = self.token_tracker.estimate_tokens(user_message)
                        tokens_out = self.token_tracker.estimate_tokens(response)
                        self.token_tracker.record("openrouter", tokens_in, tokens_out)
                        return response, "ONLINE_OPENROUTER"
                except Exception:
                    pass

            # All online failed — local fallback
            if self.local.is_available():
                response = self.local.reply_with_memory(
                    user_message,
                    self.memory.get_context(),
                    history=self.memory.get_history(last_n=10)[:-1],
                    language=lang,
                    context_chain=self.context_chain.get_chain_prompt(),
                )
                self.last_route = "OFFLINE_LOCAL_LLM"
                self.router.record("OFFLINE_LOCAL")
                self.memory.add_message("assistant", response)
                self.token_tracker.record("local")
                return response, "OFFLINE_LOCAL_LLM"

            return "All providers unavailable. Type `status` to check.", "NONE"

    def _handle_system_command(self, cmd: str):
        """Handle model switching commands. Returns response string or None."""
        # Retry commands
        if cmd in {"retry groq", "use groq again", "groq again"}:
            if not self.last_query:
                return "No previous query to retry."
            if not self._groq or not self._groq.is_available():
                return "⚡ Groq unavailable. Check API key."
            try:
                response = self._groq.chat(
                    self.last_query,
                    system_prompt=self._build_online_system_prompt(),
                    memory_context=self.memory.get_context(),
                    history=self.memory.get_history(last_n=10)[:-1],
                    max_tokens=2048,
                )
                self.last_route = "ONLINE_GROQ"
                self.router.record("ONLINE_GROQ")
                self.memory.add_message("assistant", response)
                tokens_in = self.token_tracker.estimate_tokens(self.last_query)
                tokens_out = self.token_tracker.estimate_tokens(response)
                self.token_tracker.record("groq", tokens_in, tokens_out)
                return response
            except Exception as e:
                return f"⚡ Groq error: {str(e)[:100]}"

        if cmd in {"retry openrouter", "use openrouter again", "openrouter again"}:
            if not self.last_query:
                return "No previous query to retry."
            if not self._openrouter or not self._openrouter.is_available():
                return "🌐 OpenRouter unavailable. Check API key."
            try:
                response = self._openrouter.chat(
                    self.last_query,
                    system_prompt=self._build_online_system_prompt(),
                    memory_context=self.memory.get_context(),
                    history=self.memory.get_history(last_n=10)[:-1],
                    max_tokens=2048,
                )
                self.last_route = "ONLINE_OPENROUTER"
                self.router.record("ONLINE_OPENROUTER")
                self.memory.add_message("assistant", response)
                tokens_in = self.token_tracker.estimate_tokens(self.last_query)
                tokens_out = self.token_tracker.estimate_tokens(response)
                self.token_tracker.record("openrouter", tokens_in, tokens_out)
                return response
            except Exception as e:
                return f"🌐 OpenRouter error: {str(e)[:100]}"

        # Model switching commands
        if cmd in {"switch gemini", "switch to gemini", "use gemini"}:
            self.force_model = "gemini"
            return "📡 Switched to Gemini (online). Type 'switch auto' to restore."
        elif cmd in {"switch groq", "switch to groq", "use groq"}:
            self.force_model = "groq"
            return "⚡ Switched to Groq (fast, online). Type 'switch auto' to restore."
        elif cmd in {"switch openrouter", "use openrouter"}:
            self.force_model = "openrouter"
            return "🌐 Switched to OpenRouter. Type 'switch auto' to restore."
        elif cmd in {"switch local", "switch ollama", "switch to ollama", "use local", "use ollama"}:
            self.force_model = "ollama"
            return "🖥️ Switched to Nila Local (offline). Type 'switch auto' to restore."
        elif cmd == "switch auto":
            self.force_model = None
            return "🤝 Auto mode restored — speed-first routing active."
        elif cmd in {"train", "train model", "train nila"}:
            try:
                trainer = MemoryTrainer()
                count = trainer.build_training_dataset()
                trainer.inject_into_modelfile(count)
                
                # Execute: ollama create nila -f training/Modelfile
                import subprocess, os
                modelfile_path = os.path.join(PROJECT_DIR, "training", "Modelfile")
                
                command = f'ollama create nila -f "{modelfile_path}"'
                result = subprocess.run(
                    command,
                    shell=True,
                    capture_output=True,
                    text=True,
                    timeout=120,
                    cwd=PROJECT_DIR,
                    encoding="utf-8",
                    errors="replace"
                )
                
                if result.returncode == 0:
                    return (
                        f"✅ Local model `nila:latest` trained and updated successfully!\n"
                        f"- Processed: {count} Q&A pairs from memory and course history.\n"
                        f"- Output:\n```\n{result.stdout.strip()}\n```"
                    )
                else:
                    return (
                        f"❌ Training failed. Ollama error:\n"
                        f"```\n{result.stderr.strip() or result.stdout.strip()}\n```"
                    )
            except Exception as e:
                return f"❌ Training error: {str(e)}"
        elif cmd == "clear":
            self.memory.clear_conversations()
            return "🗑️ Conversation history cleared (facts & goals preserved)."
        return None

    def _handle_forced_model(self, user_message: str, lang_instruction: str, lang: str) -> tuple[str, str]:
        """Handle chat when a model is forced."""
        speed = classify_speed(user_message)
        
        # If it's a web search query, use the search chain but forced to this model
        if speed == "needs_web":
            response, route = self.web_chain.search_and_answer(
                user_message,
                self.memory.get_context(),
                history=self.memory.get_history(last_n=10)[:-1],
                force_model=self.force_model,
                lang_instruction=lang_instruction,
                context_chain=self.context_chain.get_chain_prompt(),
            )
            self.last_route = route
            self.router.record(route)
            self.memory.add_message("assistant", response)
            # Track tokens
            tokens_in = self.token_tracker.estimate_tokens(user_message)
            tokens_out = self.token_tracker.estimate_tokens(response)
            if self.force_model == "gemini":
                self.token_tracker.record("gemini", tokens_in, tokens_out)
            elif self.force_model == "groq":
                self.token_tracker.record("groq", tokens_in, tokens_out)
            elif self.force_model == "openrouter":
                self.token_tracker.record("openrouter", tokens_in, tokens_out)
            else:
                self.token_tracker.record("local")
            return response, route

        # Otherwise, standard completions
        if self.force_model == "ollama":
            response = self.local.reply_with_memory(
                user_message,
                self.memory.get_context(),
                history=self.memory.get_history(last_n=10)[:-1],
                language=lang,
                context_chain=self.context_chain.get_chain_prompt(),
            )
            self.last_route = "OFFLINE_LOCAL_LLM"
            self.router.record("OFFLINE_LOCAL")
            self.memory.add_message("assistant", response)
            self.token_tracker.record("local")
            return response, "OFFLINE_LOCAL_LLM"

        elif self.force_model == "gemini":
            try:
                response = self._chat_gemini(user_message, lang_instruction)
                self.last_route = "ONLINE_GEMINI"
                self.router.record("ONLINE_GEMINI")
                self.memory.add_message("assistant", response)
                tokens_in = self.token_tracker.estimate_tokens(user_message)
                tokens_out = self.token_tracker.estimate_tokens(response)
                self.token_tracker.record("gemini", tokens_in, tokens_out)
                return response, "ONLINE_GEMINI"
            except Exception:
                pass

        elif self.force_model == "groq" and self._groq and self._groq.is_available():
            try:
                response = self._groq.chat(
                    user_message,
                    system_prompt=self._build_online_system_prompt(),
                    memory_context=self.memory.get_context(),
                    history=self.memory.get_history(last_n=10)[:-1],
                )
                self.last_route = "ONLINE_GROQ"
                self.router.record("ONLINE_GROQ")
                self.memory.add_message("assistant", response)
                tokens_in = self.token_tracker.estimate_tokens(user_message)
                tokens_out = self.token_tracker.estimate_tokens(response)
                self.token_tracker.record("groq", tokens_in, tokens_out)
                return response, "ONLINE_GROQ"
            except Exception:
                pass

        elif self.force_model == "openrouter" and self._openrouter and self._openrouter.is_available():
            try:
                response = self._openrouter.chat(
                    user_message,
                    system_prompt=self._build_online_system_prompt(),
                    memory_context=self.memory.get_context(),
                    history=self.memory.get_history(last_n=10)[:-1],
                )
                self.last_route = "ONLINE_OPENROUTER"
                self.router.record("ONLINE_OPENROUTER")
                self.memory.add_message("assistant", response)
                tokens_in = self.token_tracker.estimate_tokens(user_message)
                tokens_out = self.token_tracker.estimate_tokens(response)
                self.token_tracker.record("openrouter", tokens_in, tokens_out)
                return response, "ONLINE_OPENROUTER"
            except Exception:
                pass

        # Forced model failed — fall back to auto
        self.force_model = None
        return self.chat(user_message)

    def _build_online_system_prompt(self) -> str:
        """Build system prompt for online providers."""
        chain_prompt = self.context_chain.get_chain_prompt()
        chain_str = f"{chain_prompt}\n\n" if chain_prompt else ""
        return (
            f"{chain_str}"
            "You are Nila — a personal AI life coach in YearZero for Theo.\n"
            "You are part of the Nila Council — a multi-AI collaboration system.\n"
            "Be warm, direct, helpful. Match the user's language.\n"
            "If Theo writes Tamil/Tanglish → respond in Tanglish.\n"
            "If Theo writes English → respond in English.\n"
            f"Current date: {datetime.now().strftime('%A, %B %d, %Y — %I:%M %p')}\n"
        )

    # ------------------------------------------------------------------
    # TERMINAL AGENT -- file system + command execution
    # ------------------------------------------------------------------

    def _resolve_path(self, path_str: str | None) -> str | None:
        if not path_str:
            return path_str
        import os
        full_path = os.path.abspath(path_str)
        if os.path.exists(full_path):
            return full_path
        
        # Sibling search in workspace root
        filename = os.path.basename(path_str)
        import glob
        try:
            matches = glob.glob(os.path.join(WORKSPACE_DIR, "**", filename), recursive=True)
            if matches:
                return matches[0]
        except Exception:
            pass
        return full_path

    def _try_terminal_action(self, user_message: str) -> str | None:
        """Handle all file system operations including AI-generated file creation."""
        import re, os
        msg = user_message.lower().strip()

        # ── HANDLE: PENDING DELETE CONFIRMATION ───────────────────────
        if hasattr(self, '_pending_delete') and self._pending_delete:
            if msg in ("yes", "yes delete", "confirm", "y"):
                path = self._pending_delete
                self._pending_delete = None
                try:
                    if os.path.isdir(path):
                        import shutil
                        shutil.rmtree(path)
                        return f"✅ Deleted folder: `{path}`"
                    else:
                        os.remove(path)
                        return f"✅ Deleted: `{path}`"
                except Exception as e:
                    return f"❌ Delete failed: {str(e)}"
            elif msg in ("no", "cancel", "n"):
                self._pending_delete = None
                return "Cancelled. File not deleted."
            self._pending_delete = None
            return "Cancelled. File not deleted."

        # ── DETECT FOLDER CREATION ────────────────────────────────────
        is_create_folder = any(kw in msg for kw in [
            "create folder", "make folder", "new folder", "create a folder", "make a folder",
            "mkdir", "create directory", "make directory", "new directory", "create a directory",
            "make a directory", "create folders", "make folders"
        ])
        
        if is_create_folder:
            folder_name = None
            named_match = re.search(r'named\s+["\']?([a-zA-Z0-9_-]+)["\']?', user_message, re.I)
            if named_match:
                folder_name = named_match.group(1).strip()
            else:
                folder_match = re.search(r'(?:folder|directory)\s+["\']?([a-zA-Z0-9_-]+)["\']?', user_message, re.I)
                if folder_match:
                    folder_name = folder_match.group(1).strip()
            
            if folder_name:
                parent_dir = WORKSPACE_DIR
                if not any(kw in msg for kw in ["same directory", "samme directory", "sibling directory", "sibling", "same folder"]):
                    extracted_path = self._extract_path_from_message(user_message)
                    if extracted_path:
                        extracted_path = self._resolve_path(extracted_path)
                        if os.path.isdir(extracted_path):
                            parent_dir = extracted_path
                        else:
                            parent_dir = os.path.dirname(extracted_path)
                
                target_folder_path = os.path.join(parent_dir, folder_name)
                result = self.terminal.create_folder(target_folder_path)
                if result["success"]:
                    return f"✅ Created folder: `{target_folder_path}`"
                else:
                    return f"❌ Folder creation failed: {result['error']}"

        has_win_path = bool(re.search(r'[A-Za-z]:\\', user_message))
        has_file_ext = bool(re.search(
            r'\b\w+\.(txt|py|js|html|css|json|md|csv|log|bat|sh|yaml|xml|ts|jsx|vue)\b',
            user_message, re.I
        ))
        
        # ── DETECT TASK TYPE ──────────────────────────────────────────
        create_keywords = [
            "create", "make", "build", "generate", "write",
            "build me", "create me", "make me", "set up", "setup"
        ]
        is_create = any(kw in msg for kw in create_keywords)
        
        app_keywords = [
            "calculator", "web app", "webapp", "website", "application",
            "html", "flask", "django", "react", "script", "program",
            "python script", "javascript", "html file", "page"
        ]
        is_app_creation = any(kw in msg for kw in app_keywords)
        
        read_keywords = ["read", "first line", "last line", "content", 
                        "what's in", "whats in", "show me the", "display", "cat"]
        is_read = any(kw in msg for kw in read_keywords)
        
        rename_keywords = ["rename", "move to", "mv ", "move file"]
        is_rename = any(kw in msg for kw in rename_keywords)
        
        list_keywords = ["list files", "show files", "dir ", 
                        "folder contents", "what files", "what's in the folder"]
        words = msg.split()
        is_list = any(kw in msg for kw in list_keywords) or "ls" in words
        
        run_keywords = ["run ", "execute ", "pip install", "python ", "git "]
        is_run = any(kw in msg for kw in run_keywords)
        
        delete_keywords = ["delete file", "remove file", "delete the file", "delete"]
        is_delete = any(kw in msg for kw in delete_keywords)

        # ── EXTRACT PATH ──────────────────────────────────────────────
        path = self._extract_path_from_message(user_message)
        if path:
            path = self._resolve_path(path)
        
        # ── OPEN/RUN FILE IN OS (browser for HTML, default app for others) ──
        open_keywords = ["open this", "open the file", "run this file", 
                         "run the file", "launch", "open in browser",
                         "run this", "start this", "navigate to", "navigate"]
        is_open = any(kw in msg for kw in open_keywords)

        # Also detect: path + "open", "run", "launch", "start", or "navigate" anywhere
        is_open_with_path = path and any(
            kw in msg for kw in ["open", "run", "launch", "start", "navigate"]
        )

        if (is_open or is_open_with_path) and path and not any(
            k in msg for k in ["first line", "last line", "content", "whats in", 
                               "what's in", "read", "show me the content"]
        ):
            import webbrowser, os
            full_path = os.path.abspath(path)
            
            if not os.path.exists(full_path):
                return f"❌ File not found: `{full_path}`"
            
            ext = os.path.splitext(full_path)[1].lower()
            
            # HTML files → open in browser
            if ext in ['.html', '.htm']:
                browser_path = full_path.replace('\\', '/')
                webbrowser.open(f'file:///{browser_path}')
                return f"🌐 Opened in browser: `{full_path}`"
            
            # Python files → run with python
            elif ext == '.py':
                result = self.terminal.run_command(
                    f'python "{full_path}"',
                    working_dir=os.path.dirname(full_path)
                )
                if result['success']:
                    out = result['output'] or '(no output)'
                    return f"✅ Ran `{os.path.basename(full_path)}`:\n```\n{out[:1500]}\n```"
                return f"❌ Error running `{full_path}`:\n{result['error']}"
            
            # All other files → open with default OS application
            else:
                try:
                    os.startfile(full_path)
                    return f"✅ Opened: `{full_path}`"
                except Exception as e:
                    return f"❌ Could not open: {e}"

        # ── EDIT/MODIFY EXISTING FILE ──────────────────────────────────────
        edit_keywords = [
            "add a css", "add css", "create css", "add style",
            "add a text box", "add textbox", "add input", "add button",
            "modify", "update the file", "edit the file", "change the file",
            "update the html", "edit the html", "change the html",
            "add to the file", "append to", "update calculator",
            "refactor", "improve the", "fix the file", "add a dark background",
            "add background", "change background", "dark background"
        ]
        is_edit = any(kw in msg for kw in edit_keywords)

        if is_edit:
            # Find which file to edit — check last_file_context first
            target_file = path or getattr(self, 'last_file_context', None)
            
            if not target_file or not os.path.exists(str(target_file)):
                return ("❌ Which file should I edit? "
                       "Mention the full path, e.g. `T:\\path\\file.html`")
            
            return self._edit_file_with_ai(user_message, str(target_file))

        # ── HANDLE: AI-GENERATED FILE/APP CREATION ────────────────────
        if is_create and (is_app_creation or has_file_ext or has_win_path):
            return self._create_with_ai(user_message, path)
            
        # ── HANDLE: READ FILE ─────────────────────────────────────────
        if is_read and (has_win_path or has_file_ext) and path:
            result = self.terminal.read_file(path)
            if result["success"]:
                content = result["content"]
                self.last_file_context = path  # remember for follow-up edits
                if "first line" in msg:
                    return f"📄 First line of `{path}`:\n```\n{content.split(chr(10))[0].strip()}\n```"
                elif "last line" in msg:
                    return f"📄 Last line of `{path}`:\n```\n{content.strip().split(chr(10))[-1].strip()}\n```"
                else:
                    preview = content[:3000]
                    more = f"\n_(showing first 3000 of {len(content)} chars)_" if len(content) > 3000 else ""
                    return f"📄 `{result['path']}` ({result['lines']} lines):\n\n```\n{preview}\n```{more}"
            else:
                return f"❌ Cannot read: {result['error']}"
                
        # ── HANDLE: RENAME ────────────────────────────────────────────
        if is_rename and path:
            new_name = self._extract_new_name(user_message)
            if new_name:
                return self._do_rename(path, new_name)
            return f"❌ Tell me the new name. Example: 'rename T:\\path\\file.txt to newname.txt'"
            
        # ── HANDLE: DELETE ────────────────────────────────────────────
        if is_delete and path:
            self._pending_delete = path
            return (f"⚠️ Are you sure you want to delete:\n`{path}`\n\n"
                    f"Type **yes delete** to confirm or **no** to cancel.")
            
        # ── HANDLE: LIST DIRECTORY ────────────────────────────────────
        if is_list:
            list_path = path or "."
            result = self.terminal.list_directory(list_path)
            if result["success"]:
                lines = [f"📁 `{result['path']}` — {result['count']} items\n"]
                for item in result["items"][:30]:
                    icon = "📄" if item["type"] == "file" else "📁"
                    size = f"  ({item['size']:,}b)" if item["type"] == "file" else ""
                    lines.append(f"  {icon} {item['name']}{size}")
                return "\n".join(lines)
            return f"❌ {result['error']}"
            
        # ── HANDLE: RUN COMMAND ───────────────────────────────────────
        if is_run:
            command = self._extract_run_command(user_message)
            if command:
                result = self.terminal.run_command(command)
                if result["success"]:
                    out = result["output"] or "(no output)"
                    return f"✅ `{command}`\n\n```\n{out[:2000]}\n```"
                return f"❌ `{command}`\n\nError: {result['error']}"
                
        # Has path but no clear action keyword -- let's check if it's a file path and read it as fallback
        if (has_win_path or has_file_ext) and path and os.path.exists(path) and os.path.isfile(path):
            result = self.terminal.read_file(path)
            if result["success"]:
                content = result["content"]
                self.last_file_context = path  # remember for follow-up edits
                preview = content[:3000]
                more = f"\n_(showing first 3000 of {len(content)} chars)_" if len(content) > 3000 else ""
                return f"📄 `{result['path']}` ({result['lines']} lines):\n\n```\n{preview}\n```{more}"

        return None

    def _create_with_ai(self, user_message: str, target_path: str) -> str:
        """
        Use an online AI to generate file content, then write files to disk.
        """
        import re, os
        
        # Determine target directory
        if target_path:
            if os.path.isfile(target_path):
                target_dir = os.path.dirname(target_path)
            else:
                target_dir = target_path
        else:
            target_dir = WORKSPACE_DIR
        
        # Ensure directory exists
        os.makedirs(target_dir, exist_ok=True)
        
        # Build generation prompt
        generation_prompt = f"""
You are a code generator. Generate complete, working files for this request:

"{user_message}"

Target directory: {target_dir}

RULES:
1. Generate ALL files needed (HTML, CSS, JS, Python, etc.)
2. Each file must be complete and working
3. Use this EXACT format for each file — no exceptions:

===FILE: filename.ext===
[complete file content here]
===END===

4. Generate multiple files if needed (e.g. index.html + style.css + script.js)
5. Make the code actually work — no placeholders, no TODOs
6. For web apps: use a single HTML file with embedded CSS and JS if possible
7. If it's a web calculator: make it beautiful with a dark theme

Generate the files now:
"""
        
        ai_response = None
        provider_used = ""
        
        # 1. Try Gemini
        if not ai_response and self._gemini_available:
            try:
                resp = self.client.models.generate_content(
                    model=MODEL_NAME,
                    contents=generation_prompt,
                    config=types.GenerateContentConfig(
                        max_output_tokens=4096,
                        temperature=0.3,
                    )
                )
                if resp.text:
                    ai_response = resp.text
                    provider_used = "Gemini"
            except Exception:
                pass
                
        # 2. Try Groq
        if not ai_response and self._groq and self._groq.is_available():
            try:
                resp = self._groq.chat(
                    generation_prompt,
                    system_prompt="You are a code generator. Output file blocks using ===FILE: filename=== and ===END=== format.",
                    memory_context=""
                )
                if resp:
                    ai_response = resp
                    provider_used = "Groq"
            except Exception:
                pass
                
        # 3. Try OpenRouter
        if not ai_response and self._openrouter and self._openrouter.is_available():
            try:
                resp = self._openrouter.chat(
                    generation_prompt,
                    system_prompt="You are a code generator. Output file blocks using ===FILE: filename=== and ===END=== format.",
                    memory_context=""
                )
                if resp:
                    ai_response = resp
                    provider_used = "OpenRouter"
            except Exception:
                pass
                
        if not ai_response:
            ai_response = self._hardcoded_calculator_response(target_dir)
            provider_used = "Built-in template"
            
        # Parse AI response — extract FILE blocks
        files_created = []
        errors = []
        
        # Pattern: ===FILE: filename===\ncontent\n===END===
        file_pattern = re.compile(
            r'===FILE:\s*([^\n=]+)===\n(.*?)===END===',
            re.DOTALL | re.IGNORECASE
        )
        
        matches = file_pattern.findall(ai_response)
        
        # Fallback pattern: ```filename\ncontent\n```
        if not matches:
            code_pattern = re.compile(
                r'```(?:html|python|javascript|css|js)?\s*\n(.*?)```',
                re.DOTALL
            )
            code_matches = code_pattern.findall(ai_response)
            if code_matches:
                # Guess filenames based on content
                for i, content in enumerate(code_matches):
                    if '<html' in content.lower() or '<!DOCTYPE' in content:
                        matches.append(('index.html', content))
                    elif 'def ' in content or 'import ' in content:
                        matches.append((f'app_{i}.py', content))
                    elif 'function ' in content or 'const ' in content:
                        matches.append((f'script_{i}.js', content))
                    elif 'body {' in content or '.class' in content:
                        matches.append((f'style_{i}.css', content))
                    else:
                        matches.append((f'file_{i}.txt', content))
                        
        # Write each file
        for filename, content in matches:
            filename = filename.strip()
            # Security: no path traversal
            filename = os.path.basename(filename)
            if not filename:
                continue
            
            file_path = os.path.join(target_dir, filename)
            try:
                with open(file_path, 'w', encoding='utf-8') as f:
                    f.write(content.strip())
                files_created.append({
                    "name": filename,
                    "path": file_path,
                    "size": len(content),
                    "lines": content.count('\n')
                })
            except Exception as e:
                errors.append(f"{filename}: {str(e)}")
                
        # If nothing was parsed, save raw AI response as reference
        if not files_created and not errors:
            debug_path = os.path.join(target_dir, "nila_generated.md")
            with open(debug_path, 'w', encoding='utf-8') as f:
                f.write(f"# Generated by Nila\nRequest: {user_message}\n\n{ai_response}")
            return (f"⚠️ Created files but couldn't parse the structure.\n"
                   f"Raw output saved to: `{debug_path}`\n\n"
                   f"Try being more specific: 'create a single index.html calculator in {target_dir}'")
                   
        # Build success response
        lines = [f"✅ Created {len(files_created)} file(s) in `{target_dir}` (via {provider_used}):\n"]
        for f in files_created:
            lines.append(f"  📄 {f['name']} ({f['lines']} lines, {f['size']} chars)")
            lines.append(f"     → {f['path']}")
            
        if errors:
            lines.append(f"\n⚠️ Errors:")
            for e in errors:
                lines.append(f"  ❌ {e}")
                
        # Auto-open HTML files in browser
        html_files = [f for f in files_created if f["name"].endswith(".html")]
        if html_files:
            try:
                import webbrowser
                webbrowser.open(f"file:///{html_files[0]['path'].replace(chr(92), '/')}")
                lines.append(f"\n🌐 Opened {html_files[0]['name']} in browser!")
            except Exception:
                lines.append(f"\nOpen in browser: file:///{html_files[0]['path']}")
                
        return "\n".join(lines)

    def _hardcoded_calculator_response(self, target_dir: str) -> str:
        """Fallback: return hardcoded calculator if all AI providers fail."""
        return '''===FILE: index.html===
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>Calculator — Nila</title>
<style>
* { margin: 0; padding: 0; box-sizing: border-box; }
body {
  background: #0a0a0a;
  display: flex;
  justify-content: center;
  align-items: center;
  min-height: 100vh;
  font-family: 'Segoe UI', sans-serif;
}
.calc {
  background: #1a1a1a;
  border-radius: 16px;
  padding: 20px;
  width: 300px;
  box-shadow: 0 20px 60px rgba(0,0,0,0.5);
  border: 1px solid #2a2a2a;
}
.display {
  background: #111;
  border-radius: 10px;
  padding: 16px;
  text-align: right;
  margin-bottom: 16px;
  border: 1px solid #2a2a2a;
}
.expr { color: #888; font-size: 13px; min-height: 18px; }
.result { color: #fff; font-size: 32px; font-weight: 300; word-break: break-all; }
.buttons { display: grid; grid-template-columns: repeat(4, 1fr); gap: 10px; }
button {
  background: #222;
  color: #fff;
  border: none;
  border-radius: 10px;
  padding: 18px;
  font-size: 18px;
  cursor: pointer;
  transition: all 0.15s;
  border: 1px solid #2a2a2a;
}
button:hover { background: #333; transform: translateY(-1px); }
button:active { transform: translateY(0); }
.btn-accent { background: #FF6B35; color: white; border-color: #FF6B35; }
.btn-accent:hover { background: #e55a25; }
.btn-clear { background: #3a1a0a; color: #FF6B35; border-color: #FF6B35; }
.btn-clear:hover { background: #4a2a1a; }
.btn-eq { background: #FF6B35; grid-column: span 2; }
.btn-zero { grid-column: span 2; }
</style>
</head>
<body>
<div class="calc">
  <div class="display">
    <div class="expr" id="expr"></div>
    <div class="result" id="result">0</div>
  </div>
  <div class="buttons">
    <button class="btn-clear" onclick="clearAll()">AC</button>
    <button onclick="toggleSign()">+/-</button>
    <button onclick="percent()">%</button>
    <button class="btn-accent" onclick="op('/')">÷</button>
    <button onclick="num('7')">7</button>
    <button onclick="num('8')">8</button>
    <button onclick="num('9')">9</button>
    <button class="btn-accent" onclick="op('*')">×</button>
    <button onclick="num('4')">4</button>
    <button onclick="num('5')">5</button>
    <button onclick="num('6')">6</button>
    <button class="btn-accent" onclick="op('-')">−</button>
    <button onclick="num('1')">1</button>
    <button onclick="num('2')">2</button>
    <button onclick="num('3')">3</button>
    <button class="btn-accent" onclick="op('+')">+</button>
    <button class="btn-zero" onclick="num('0')">0</button>
    <button onclick="dot()">.</button>
    <button class="btn-eq btn-accent" onclick="equals()">=</button>
  </div>
</div>
<script>
let cur = '0', expr = '', shouldReset = false;
const disp = () => {
  document.getElementById('result').textContent = cur;
  document.getElementById('expr').textContent = expr;
};
const num = n => {
  if (shouldReset) { cur = n; shouldReset = false; }
  else cur = cur === '0' ? n : cur + n;
  disp();
};
const dot = () => {
  if (shouldReset) { cur = '0.'; shouldReset = false; }
  else if (!cur.includes('.')) cur += '.';
  disp();
};
const op = o => {
  expr = cur + ' ' + o; shouldReset = true; disp();
};
const equals = () => {
  try {
    const full = expr + ' ' + cur;
    const res = Function('"use strict"; return (' + full + ')')();
    expr = full + ' =';
    cur = String(parseFloat(res.toFixed(10)));
    shouldReset = true;
  } catch { cur = 'Error'; shouldReset = true; }
  disp();
};
const clearAll = () => { cur = '0'; expr = ''; shouldReset = false; disp(); };
const toggleSign = () => { cur = String(-parseFloat(cur)); disp(); };
const percent = () => { cur = String(parseFloat(cur) / 100); disp(); };
</script>
</body>
</html>
===END==='''

    def _edit_file_with_ai(self, instruction: str, file_path: str) -> str:
        """Read existing file, ask AI to modify it, write result back."""
        import os
        
        # Read current content
        try:
            with open(file_path, 'r', encoding='utf-8') as f:
                current_content = f.read()
        except Exception as e:
            return f"❌ Cannot read `{file_path}`: {str(e)}"
        
        ext = os.path.splitext(file_path)[1]
        
        edit_prompt = f"""You are editing an existing file.

File: {file_path}
Instruction: {instruction}

CURRENT FILE CONTENT:
```{ext.lstrip('.')}
{current_content}
```

Return ONLY the complete updated file content.
No explanation. No markdown fences. No comments about what changed.
Just the raw file content, ready to save directly to disk.
Make sure the file is complete and working after the edit."""
        
        new_content = None
        provider_used = ""
        
        # 1. Try Gemini
        if not new_content and self._gemini_available:
            try:
                resp = self.client.models.generate_content(
                    model=MODEL_NAME,
                    contents=edit_prompt,
                    config=types.GenerateContentConfig(
                        max_output_tokens=4096,
                        temperature=0.3,
                    )
                )
                if resp.text:
                    resp_text = resp.text.strip()
                    # Strip any accidental markdown fences
                    import re
                    cleaned = re.sub(r'^```[\w]*\n?', '', resp_text)
                    cleaned = re.sub(r'\n?```$', '', cleaned)
                    new_content = cleaned.strip()
                    provider_used = "Gemini"
            except Exception:
                pass
                
        # 2. Try Groq
        if not new_content and self.groq and self.groq.is_available():
            try:
                resp = self.groq.chat(
                    edit_prompt,
                    system_prompt="You are editing an existing file. Return only the complete updated raw content with no markdown formatting.",
                    memory_context=""
                )
                if resp and len(resp.strip()) > 50:
                    import re
                    cleaned = re.sub(r'^```[\w]*\n?', '', resp.strip())
                    cleaned = re.sub(r'\n?```$', '', cleaned)
                    new_content = cleaned.strip()
                    provider_used = "Groq"
            except Exception:
                pass
                
        # 3. Try OpenRouter
        if not new_content and self.openrouter and self.openrouter.is_available():
            try:
                resp = self.openrouter.chat(
                    edit_prompt,
                    system_prompt="You are editing an existing file. Return only the complete updated raw content with no markdown formatting.",
                    memory_context=""
                )
                if resp and len(resp.strip()) > 50:
                    import re
                    cleaned = re.sub(r'^```[\w]*\n?', '', resp.strip())
                    cleaned = re.sub(r'\n?```$', '', cleaned)
                    new_content = cleaned.strip()
                    provider_used = "OpenRouter"
            except Exception:
                pass
                
        if not new_content:
            return "❌ All AI providers failed. Cannot edit file right now."
            
        # Backup original
        backup_path = file_path + ".bak"
        try:
            with open(backup_path, 'w', encoding='utf-8') as f:
                f.write(current_content)
        except Exception:
            pass
            
        # Write updated content
        try:
            with open(file_path, 'w', encoding='utf-8') as f:
                f.write(new_content)
        except Exception as e:
            return f"❌ Cannot write to `{file_path}`: {str(e)}"
            
        # Remember this file for context
        self.last_file_context = file_path
        
        lines_before = current_content.count('\n')
        lines_after = new_content.count('\n')
        
        return (f"✅ File updated via {provider_used}: `{file_path}`\n"
               f"Lines: {lines_before} → {lines_after}\n"
               f"Backup saved: `{backup_path}`\n\n"
               f"Type 'open {file_path}' to see the changes.")

    def _extract_path_from_message(self, message: str) -> str | None:
        import re
        win = re.search(r'[A-Za-z]:\\[^\s"\'*?<>|,;!?]+', message)
        if win:
            return win.group().rstrip('.,;:?!')
        quoted = re.search(r'["`\']((?:[A-Za-z]:\\|/)[^"`\']+)["`\']', message)
        if quoted:
            return quoted.group(1)
        rel = re.search(
            r'\b([\w./\\-]+\.(?:txt|py|json|md|csv|log|js|html|css|yaml|xml|bat|sh))\b',
            message, re.I
        )
        if rel:
            return rel.group(1)
        return None

    def _extract_new_name(self, message: str) -> str | None:
        import re
        match = re.search(r'(?:\bto\b|\bas\b|\brename to\b)\s+["\']?([^\s"\']+)["\']?',
                         message, re.I)
        if match:
            return match.group(1).strip('.,;')
        return None

    def _do_rename(self, old_path: str, new_name: str) -> str:
        import os
        try:
            parent = os.path.dirname(old_path)
            new_path = os.path.join(parent, new_name) if parent else new_name
            orig_ext = os.path.splitext(old_path)[1]
            if orig_ext and not os.path.splitext(new_name)[1]:
                new_path += orig_ext
            os.rename(old_path, new_path)
            return f"✅ Renamed:\n`{old_path}` → `{new_path}`"
        except FileNotFoundError:
            return f"❌ File not found: `{old_path}`"
        except Exception as e:
            return f"❌ Rename failed: {str(e)}"

    def _extract_run_command(self, message: str) -> str | None:
        import re
        msg = message.strip()
        for prefix in ["run ", "execute ", "please run ", "can you run "]:
            if msg.lower().startswith(prefix):
                return msg[len(prefix):].strip().strip('"\'`')
        cmd = re.search(
            r'\b(pip install\s+\S+|python\s+\S+|git\s+\w+.*|npm\s+\w+)\b',
            msg, re.I
        )
        if cmd:
            return cmd.group(1)
        return None
    def _handle_terminal_action(self, user_message: str) -> str | None:
        """Execute terminal/file action detected by speed classifier keywords."""
        action = detect_terminal_action(user_message)
        if not action:
            return None

        try:
            if action == "run_command":
                command = extract_command(user_message)
                result = self.terminal.run_command(command)
                return self._format_terminal_result(command, result)

            elif action == "read_file":
                path = extract_path(user_message)
                result = self.terminal.read_file(path)
                if result["success"]:
                    content = result["content"]
                    preview = content[:2000] + ("..." if len(content) > 2000 else "")
                    return (
                        f"\U0001f4c4 **File:** {result['path']}\n"
                        f"Size: {result['size']:,} bytes | {result['lines']} lines\n\n"
                        f"```\n{preview}\n```"
                    )
                return f"\u274c {result['error']}"

            elif action == "create_file":
                path, content = extract_file_content(user_message)
                if not content:
                    content = f"# Created by Nila on {datetime.now().strftime('%Y-%m-%d %H:%M')}\n"
                result = self.terminal.create_file(path, content)
                return f"\u2705 {result['message']}" if result["success"] else f"\u274c {result['error']}"

            elif action == "create_folder":
                path = extract_path(user_message)
                result = self.terminal.create_folder(path)
                return f"\u2705 {result['message']}" if result["success"] else f"\u274c {result['error']}"

            elif action == "list_files":
                path = extract_path(user_message)
                result = self.terminal.list_directory(path)
                if result["success"]:
                    lines = [f"\U0001f4c1 **{result['path']}** ({result['count']} items)\n"]
                    for item in result["items"][:30]:
                        icon = "\U0001f4c4" if item["type"] == "file" else "\U0001f4c1"
                        size = f"  {item['size']:,}b" if item["type"] == "file" else ""
                        lines.append(f"  {icon} {item['name']}{size}  ({item['modified']})")
                    return "\n".join(lines)
                return f"\u274c {result['error']}"

            elif action == "find_file":
                words = user_message.split()
                pattern = words[-1] if words else ""
                path = extract_path(user_message)
                search_dir = path if path != "." else None
                matches = self.terminal.find_files(pattern, search_dir)
                if matches:
                    lines = [f"\U0001f50d Found {len(matches)} file(s):"]
                    for m in matches:
                        lines.append(f"  \U0001f4c4 {m}")
                    return "\n".join(lines)
                return f"\U0001f50d No files found matching '{pattern}'."

            elif action == "open_file":
                path = extract_path(user_message)
                result = self.terminal.open_file(path)
                return f"\u2705 {result['message']}" if result["success"] else f"\u274c {result['error']}"

            elif action == "delete_file":
                path = extract_path(user_message)
                self._pending_delete = path
                return (
                    f"\u26a0\ufe0f Are you sure you want to delete '{path}'?\n"
                    "Type 'yes delete' to confirm, or anything else to cancel."
                )

            else:
                return f"Terminal action '{action}' not recognized. Please be more specific."

        except Exception as e:
            return f"\u274c Terminal error: {str(e)}"

    def _format_terminal_result(self, command: str, result: dict) -> str:
        """Format terminal command result for display."""
        if result["success"]:
            output = result.get("output", "") or "(no output)"
            if len(output) > 3000:
                output = output[:3000] + "\n... (truncated)"
            return (
                f"\u2705 Command ran successfully:\n"
                f"```\n{command}\n```\n"
                f"Output:\n```\n{output}\n```"
            )
        error = result.get("error", "Unknown error")
        return (
            f"\u274c Command failed:\n"
            f"```\n{command}\n```\n"
            f"Error: {error}"
        )

    # ------------------------------------------------------------------
    # GEMINI path -- online, with tools
    # ------------------------------------------------------------------

    def _chat_gemini(self, user_message: str, lang_instruction: str) -> str:
        """Call Gemini API with full tool access."""
        # Build system prompt with fresh memory context
        system_prompt = SYSTEM_PROMPT_TEMPLATE.format(
            current_date=datetime.now().strftime("%A, %B %d, %Y — %I:%M %p"),
            memory_summary=self.memory.get_summary(),
        )

        chain_prompt = self.context_chain.get_chain_prompt()
        if chain_prompt:
            system_prompt = f"{chain_prompt}\n\n{system_prompt}"

        kb_context = self.personal_kb.get_all_context()
        course_context = self.ollama_trainer.inject_knowledge_into_mistral_prompt(user_message)
        if kb_context:
            system_prompt += f"""

YOUR PERSONAL KNOWLEDGE BASE ABOUT THEO:
{kb_context}

This is Theo's personal data. Use it to answer questions about his work.
If Theo asks "what is the location of X" or "what did I say about Y", search this KB first before anything else.
NEVER say you don't know something that's in this KB.
"""

        # Build conversation history
        history = self.memory.get_history(last_n=20)
        messages = []
        for msg in history[:-1]:  # Exclude last message (current one)
            role = "user" if msg["role"] == "user" else "model"
            messages.append(types.Content(
                role=role,
                parts=[types.Part(text=msg["content"])],
            ))

        # Add current user message with language instruction
        augmented_message = f"[{lang_instruction}]\n\nUser: {user_message}"
        messages.append(types.Content(
            role="user",
            parts=[types.Part(text=augmented_message)],
        ))

        # Config with tools
        config = types.GenerateContentConfig(
            system_instruction=system_prompt,
            tools=[types.Tool(function_declarations=TOOL_DECLARATIONS)],
            automatic_function_calling=types.AutomaticFunctionCallingConfig(disable=True),
            max_output_tokens=MAX_TOKENS,
        )

        # ── Agentic tool loop ──
        iteration = 0
        while iteration < self.MAX_TOOL_ITERATIONS:
            iteration += 1

            response = self.client.models.generate_content(
                model=MODEL_NAME,
                contents=messages,
                config=config,
            )

            # Check for function calls
            if not response.candidates or not response.candidates[0].content.parts:
                raise ConnectionError("No response from Gemini")

            parts = response.candidates[0].content.parts
            has_function_call = any(p.function_call for p in parts)

            if has_function_call:
                # Append model's response to conversation
                messages.append(response.candidates[0].content)

                # Execute each function call and build responses
                tool_response_parts = []
                for part in parts:
                    if part.function_call:
                        fn_name = part.function_call.name
                        fn_args = dict(part.function_call.args) if part.function_call.args else {}
                        fn_id = part.function_call.id

                        result = self._execute_tool(fn_name, fn_args)

                        tool_response_parts.append(
                            types.Part.from_function_response(
                                name=fn_name,
                                response={"result": result},
                            )
                        )

                # Send tool results back
                messages.append(types.Content(
                    role="user",
                    parts=tool_response_parts,
                ))
            else:
                # No function calls — extract text
                return self._extract_text(parts)

        raise RuntimeError("Reached tool iteration limit")

    # ------------------------------------------------------------------
    # MISTRAL path — offline fallback, memory-only
    # ------------------------------------------------------------------

    def _chat_mistral(self, user_message: str, lang_instruction: str) -> str:
        """Call local LLM with full context — memory, courses, KB. No tools."""
        facts = self.memory.get_all_facts()
        goals = self.memory.get_goals()
        history = self.memory.get_history(last_n=5)
        kb_context = self.personal_kb.get_all_context()
        course_context = self.ollama_trainer.inject_knowledge_into_mistral_prompt(user_message)

        # Build rich context so local model can answer accurately
        course_summary = self.data_engine.get_course_summary_for_context()

        facts_json = json.dumps(facts, indent=2, ensure_ascii=False) if facts else "{}"

        active_goals = [g for g in goals if g.get("status") == "active"]
        goals_list = (
            "\n".join(f"- {g['goal']}" for g in active_goals)
            if active_goals else "No active goals."
        )

        last_5 = (
            "\n".join(f"{m['role'].upper()}: {m['content'][:150]}" for m in history[-5:])
            if history else "No history yet."
        )

        system_prompt = MISTRAL_SYSTEM_PROMPT.format(
            facts_json=facts_json,
            goals_list=goals_list,
            last_5_messages=last_5,
            current_date=datetime.now().strftime("%A, %B %d, %Y — %I:%M %p"),
        )

        # Inject course data so local model knows about active courses
        if course_summary:
            system_prompt += f"""\n
=== THEO'S CURRENT DATA (use this to answer his questions) ===

{course_summary}

TODAY'S DATE: {datetime.now().strftime("%A, %B %d, %Y")}

=== END OF DATA ===

IMPORTANT:
- When Theo asks about his courses, refer to the ACTIVE COURSES data above.
- Give COMPLETE answers. Never cut off mid-sentence.
- Minimum 3-4 sentences in every response.
- If Theo writes in Tamil/Tanglish, reply in Tanglish.
"""

        if kb_context:
            system_prompt += f"""\n
YOUR PERSONAL KNOWLEDGE BASE ABOUT THEO:
{kb_context}

Use this first for Theo's work/project/location questions. Never say you do not know something that is listed here.
"""
        if course_context:
            system_prompt += f"\n\n{course_context}\nUse this course knowledge to answer offline accurately.\n"

        augmented_message = f"[{lang_instruction}]\n\nUser: {user_message}"

        ollama_messages = [
            {"role": "system", "content": system_prompt},
            {"role": "user", "content": augmented_message},
        ]

        result = self.ollama.chat(
            messages=ollama_messages,
            max_tokens=MAX_LOCAL_TOKENS,
            temperature=LOCAL_LLM_TEMPERATURE,
        )

        if result.startswith("[Error"):
            raise RuntimeError(result)

        return result

    # ------------------------------------------------------------------
    # Tool execution
    # ------------------------------------------------------------------

    def _execute_tool(self, tool_name: str, tool_input: dict) -> str:
        """Route a tool call to the appropriate function."""
        try:
            if tool_name == "search_and_scrape":
                return scrape_web(
                    query=tool_input.get("query", ""),
                    url=tool_input.get("url"),
                )
            elif tool_name == "store_memory":
                return self._handle_store_memory(tool_input)
            elif tool_name == "recall_memory":
                return self._handle_recall_memory(tool_input)
            elif tool_name == "create_action_plan":
                return reflect_and_plan(
                    goal=tool_input.get("goal", ""),
                    history=self.memory.get_history(last_n=10),
                    duration=tool_input.get("duration", "4 weeks"),
                )
            else:
                return f"[Unknown tool: {tool_name}]"
        except Exception as e:
            return f"[Tool error in {tool_name}: {e}]"

    def _handle_store_memory(self, data: dict) -> str:
        mem_type = data.get("memory_type", "note")
        value = data.get("value", "")
        key = data.get("key", "")

        if mem_type == "fact":
            self.memory.store_fact(key or "unnamed_fact", value)
            return f"Stored fact: {key} = {value}"
        elif mem_type == "goal":
            self.memory.add_goal(value)
            return f"Stored goal: {value}"
        elif mem_type == "note":
            self.memory.add_note(value)
            return f"Stored note: {value}"
        return f"[Unknown memory type: {mem_type}]"

    def _handle_recall_memory(self, data: dict) -> str:
        mem_type = data.get("memory_type", "all")
        key = data.get("key")

        if mem_type == "fact":
            if key:
                val = self.memory.get_fact(key)
                return val if val else f"[No fact for key: {key}]"
            return json.dumps(self.memory.get_all_facts(), ensure_ascii=False)
        elif mem_type == "goal":
            goals = self.memory.get_goals()
            return json.dumps(goals, ensure_ascii=False) if goals else "[No goals]"
        elif mem_type == "note":
            notes = self.memory.get_notes()
            return json.dumps(notes, ensure_ascii=False) if notes else "[No notes]"
        elif mem_type == "all":
            return self.memory.get_summary()
        return f"[Unknown memory type: {mem_type}]"

    # ------------------------------------------------------------------
    # System status
    # ------------------------------------------------------------------

    def get_system_status(self) -> dict:
        self._ollama_available = self.local.is_available()
        forced = self.force_model
        if forced:
            mode = f"Forced: {forced.upper()}"
        elif self._ollama_available and self._gemini_available:
            mode = "🤝 Speed Routing (Local + Online)"
        elif self._gemini_available:
            mode = "📡 Online only (Gemini)"
        elif self._ollama_available:
            mode = "🖥️ Offline only (Nila Local)"
        else:
            mode = "⚠️ No models available"

        stats = self.router.get_stats()
        return {
            "ollama_available": self._ollama_available,
            "ollama_model": self.local.model,
            "gemini_available": self._gemini_available,
            "gemini_model": MODEL_NAME,
            "facts_count": len(self.memory.get_all_facts()),
            "goals_count": len(self.memory.get_goals()),
            "notes_count": len(self.memory.get_notes()),
            "conversations_count": len(self.memory.data.get("conversations", [])),
            "routines_count": len(self.memory.data.get("routines", {})),
            "preferences_count": len(self.memory.data.get("preferences", {})),
            "progress_count": len(self.memory.data.get("progress_log", [])),
            "personal_kb_count": self._personal_kb_count(),
            "courses_count": len(self.course_agent.list_courses()),
            "mode": mode,
            "routing_stats": stats,
        }

    # ------------------------------------------------------------------
    # Agent mode actions
    # ------------------------------------------------------------------

    def _handle_agent_action(self, user_message: str) -> str | None:
        action = detect_agent_action(user_message)
        if action == "chat":
            return None
        handlers = {
            "store_knowledge": self._store_knowledge_command,
            "recall_knowledge": self._recall_knowledge_command,
            "create_course": self._create_course_command,
            "mark_complete": self._mark_complete_command,
            "show_notes": self._show_notes_command,
            "show_day": self._show_day_command,
        }
        if action == "show_schedule":
            return self._today_command()
        if action == "list_courses":
            return self._list_courses_command()
        if action == "progress":
            return self._progress_command()
        if action == "quiz":
            return self._quiz_command()
        if action in handlers:
            return handlers[action](user_message)
        return None

    def _store_knowledge_command(self, msg: str) -> str:
        remember = re.search(r"remember this\s*:\s*(.+)", msg, re.IGNORECASE)
        store_as = re.search(r"store this as\s+([^:]+)\s*:\s*(.+)", msg, re.IGNORECASE)
        if store_as:
            key, value = store_as.group(1).strip(), store_as.group(2).strip()
            self.personal_kb.store_custom_fact(key, value)
            return f"Seri Theo, `{key}` save panniten: {value}"

        content = remember.group(1).strip() if remember else msg.strip()
        if "http://" in content or "https://" in content or ":\\" in content or "/" in content:
            name = self._guess_location_name(content)
            self.personal_kb.store_location(name, self._extract_location_value(content), content)
            return f"Seri Theo, store panniten! {name} location save aachi."

        self.personal_kb.store_work_note("Remembered note", content, ["remembered"])
        return "Seri Theo, remember panniten. KB-la save aachi."

    def _recall_knowledge_command(self, msg: str) -> str:
        query = re.sub(
            r"(?i)what do you know about|where is the|where is my|what was|tell me about my|recall|what did i say about|enge iruku|enna sonna|sollu",
            "",
            msg,
        ).strip(" ?:")
        results = self.personal_kb.search_kb(query or msg)
        if not results:
            return f"Theo, `{query or msg}` pathi KB-la direct match kedaikala."

        lines = [f"KB-la `{query or msg}` pathi idhu iruku:"]
        for item in results[:5]:
            entry_type = item["type"]
            entry = item["entry"]
            if entry_type == "location":
                lines.append(f"- {item['name']}: {entry.get('path_or_url')} ({entry.get('description')})")
            elif entry_type == "custom_fact":
                lines.append(f"- {item['key']}: {entry.get('value')}")
            elif entry_type == "work_note":
                lines.append(f"- {entry.get('topic')}: {entry.get('content', '')[:500]}")
            elif entry_type == "project":
                lines.append(f"- {entry.get('name')}: {entry.get('description')}")
            else:
                lines.append(f"- {entry.get('title')}: {entry.get('content', '')[:500]}")
        return "\n".join(lines)

    def _create_course_command(self, msg: str) -> str:
        parsed = extract_course_params(msg, self.client if self._gemini_available else None)
        parsed["original_message"] = msg
        if not parsed["topic"]:
            return (
                "Seri Theo! Course pottu tharren. Konjam details sollu:\n"
                "1. Enna topic/use-case?\n"
                "2. Level? beginner / intermediate / advanced?\n"
                "3. Daily evlo time?\n"
                "4. Evlo days or months-la complete pannanum?"
            )

        course = self.course_agent.create_course(**parsed)
        day1 = self.course_agent.find_day(course, 1)
        resources = "\n".join(f"- {r['type']}: {r['title']} ({r['url']})" for r in day1.get("resources", [])[:3])
        return (
            f"Perfect Theo! Course build panniten.\n\n"
            f"- Topic: {course['topic']}\n"
            f"- Duration: {course['total_days']} days | {course['daily_hours']} hr/day\n"
            f"- Calendar file: {course['calendar_file']}\n"
            f"- Notes folder: {course['notes_folder']}\n\n"
            f"Day 1 ({day1['date']}): {day1['topic']}\n"
            f"Subtopics: {', '.join(day1['subtopics'])}\n\n"
            f"Resources:\n{resources}\n\n"
            f"{day1.get('beginner_friendly_intro', '')}\n\n"
            "Full plan saved in data/courses. Type `today` to see the current lesson."
        )

    def _today_command(self) -> str:
        today = self.progress_tracker.get_today()
        lessons = today.get("lessons", [])
        if not lessons:
            return "Theo, active courses illa. Course create panna `create a course for AI and AI Agents, beginner, 1 hour daily, 3 months` nu sollu."
        return "\n\n".join(self._format_today_box(item["course_data"], item["content"]) for item in lessons)

    def _list_courses_command(self) -> str:
        courses = self.progress_tracker.list_courses()
        if not courses:
            return "No active courses yet."
        return "\n".join(
            f"- {c['topic']}: {c['progress']['completed_days']}/{c['total_days']} days ({c['progress']['completion_percentage']}%)"
            for c in courses
        )

    def _progress_command(self) -> str:
        return self.progress_tracker.get_progress_summary()

    def _mark_complete_command(self, msg: str) -> str:
        match = re.search(r"day\s+(\d+)", msg, re.IGNORECASE)
        latest = self.progress_tracker.latest_course()
        if not latest:
            return "Course illa Theo. First course create pannalaam."
        day_number = int(match.group(1)) if match else latest.get("progress", {}).get("current_day", 1)
        day = self.course_agent.find_day(latest, day_number)
        if not day:
            return f"{latest['topic']} course-la day {day_number} kedaikala."
        if msg.strip().lower() == "done":
            quiz = day.get("end_of_day_quiz", day.get("verification_quiz", []))
            questions = "\n".join(f"Q{i + 1}: {q}" for i, q in enumerate(quiz))
            return (
                f"Seri Theo! Day {day_number} complete pannuvoma? Quiz time.\n\n"
                f"{questions}\n\n"
                "Terminal-la interactive answers collect panna next step simple-a: "
                "`done day {}` nu type pannina complete mark panniduven. "
                "Notes add panna `notes` file-la write pannalaam.".format(day_number)
            )
        result = self.progress_tracker.complete_day(latest["course_id"], day_number)
        course = result.get("course")
        done_day = result.get("completed_day")
        next_day = result.get("next_day")
        if not done_day:
            return f"{course['topic']} course-la day {day_number} kedaikala."
        if next_day:
            return (
                f"Nalla iruku Theo! Day {day_number} complete mark panniten.\n\n"
                f"Streak: {course.get('progress', {}).get('streak', 0)} day(s)\n"
                f"Next: Day {next_day['day']} - {next_day['topic']} on {next_day['date']}"
            )
        return f"Mass Theo! {course['topic']} course complete aagiduchu."

    def _quiz_command(self) -> str:
        latest = self.progress_tracker.latest_course()
        if not latest:
            return "Quiz-ku active course illa Theo."
        day_number = latest.get("progress", {}).get("current_day", 1)
        day = self.course_agent.find_day(latest, day_number)
        if not day:
            return "Current day quiz kedaikala."
        quiz = day.get("end_of_day_quiz", day.get("verification_quiz", []))
        questions = "\n".join(f"Q{i + 1}: {q}" for i, q in enumerate(quiz))
        return f"Quiz time Theo! Day {day_number} - {day['topic']}\n\n{questions}\n\nAnswer pannitu `done day {day_number}` type pannunga."

    def _show_day_command(self, msg: str) -> str:
        match = re.search(r"day\s+(\d+)", msg, re.IGNORECASE)
        day_number = int(match.group(1)) if match else 1
        latest = self.progress_tracker.latest_course()
        if not latest:
            return "Active course illa Theo."
        day = self.course_agent.find_day(latest, day_number)
        if not day:
            return f"Day {day_number} kedaikala."
        return self._format_lesson(latest, day, prefix=f"Day {day_number}")

    def _show_notes_command(self, msg: str) -> str:
        match = re.search(r"notes\s+(.+?)\s+day\s+(\d+)", msg, re.IGNORECASE)
        if not match:
            return "Format: `notes python day 1`"
        topic, day_number = match.group(1).strip(), int(match.group(2))
        courses = [c for c in self.course_agent.list_courses() if topic.lower() in c["topic"].lower()]
        if not courses:
            return f"`{topic}` course notes kedaikala."
        return f"Notes file: {courses[-1]['notes_folder']}\\day_{day_number}.md"

    def _format_lesson(self, course: dict, day: dict, prefix: str = "Lesson") -> str:
        resources = "\n".join(f"- {r['type']}: {r['title']} ({r['url']})" for r in day.get("resources", [])[:4])
        quiz = "\n".join(f"- {q}" for q in day.get("verification_quiz", []))
        return (
            f"{prefix}: {course['topic']} - Day {day['day']}\n"
            f"Date: {day['date']}\n"
            f"Topic: {day['topic']}\n"
            f"Subtopics: {', '.join(day.get('subtopics', []))}\n\n"
            f"Resources:\n{resources}\n\n"
            f"Quiz:\n{quiz}"
        )

    def _format_today_box(self, course: dict, day: dict) -> str:
        breakdown = day.get("daily_time_breakdown", {})
        resources = day.get("resources", [])
        video = next((r for r in resources if r.get("type") in {"video", "course"}), resources[0] if resources else {})
        article = next((r for r in resources if r.get("type") in {"article", "docs"}), resources[1] if len(resources) > 1 else video)
        quiz = day.get("end_of_day_quiz", day.get("verification_quiz", []))
        phase_name = "Foundations"
        phase_number = 1
        for phase in course.get("phases", []):
            if any(d.get("day") == day.get("day") for d in phase.get("days", [])):
                phase_name = phase.get("name", phase_name)
                phase_number = phase.get("phase", phase_number)
                break
        return (
            "TODAY'S LEARNING\n"
            f"Course: {course.get('topic')}\n"
            f"Day {day.get('day')} of {course.get('total_days')} | Week {((day.get('day', 1) - 1) // 7) + 1} | Phase {phase_number}: {phase_name}\n\n"
            f"TOPIC: {day.get('topic')}\n\n"
            f"What you'll learn today:\n{day.get('beginner_friendly_intro') or day.get('what_you_will_learn')}\n\n"
            f"TODAY'S PLAN ({course.get('daily_hours', 1)} hour total):\n"
            f"- Watch: {breakdown.get('watch', '30 mins')} - {video.get('title', 'Intro video')} - {video.get('url', '')}\n"
            f"- Read: {breakdown.get('read', '15 mins')} - {article.get('title', 'Simple article')} - {article.get('url', '')}\n"
            f"- Write: {breakdown.get('think', breakdown.get('practice', '15 mins - Write 3 things you found interesting'))}\n\n"
            "END-OF-DAY QUIZ (type `quiz` when ready):\n"
            + "\n".join(f"Q{i + 1}: {q}" for i, q in enumerate(quiz))
            + "\n\nType `done` when you finish today's session."
        )

    @staticmethod
    def _guess_location_name(content: str) -> str:
        lowered = content.lower()
        if "sap" in lowered and "login" in lowered:
            return "SAP portal login page"
        if "sap" in lowered and "config" in lowered:
            return "SAP portal config"
        if "portal" in lowered:
            return "Portal location"
        return "Saved location"

    @staticmethod
    def _extract_location_value(content: str) -> str:
        match = re.search(r"(https?://\S+|[A-Za-z]:\\[^\n]+|T:\\[^\n]+)", content)
        return match.group(1).strip() if match else content.strip()

    @staticmethod
    def _parse_course_request(msg: str) -> dict:
        return extract_course_params(msg)

    def _personal_kb_count(self) -> int:
        kb = self.personal_kb.kb
        return (
            len(kb.get("projects", []))
            + len(kb.get("work_notes", []))
            + len(kb.get("locations", {}))
            + len(kb.get("technical_docs", []))
            + len(kb.get("custom_facts", {}))
        )

    # ------------------------------------------------------------------
    # Helpers
    # ------------------------------------------------------------------

    def _run_trainer(self, user_message: str, response: str):
        """
        Run trainers silently—never blocks conversation.

        Runs three trainers in background:
        1. SelfTrainer — extracts facts, goals, preferences
        2. ConversationTrainer — learns communication style & effectiveness
        3. LocalModelAdapter — fine-tunes local model every 25 exchanges
        """
        try:
            # 1. Run existing self-trainer (fact extraction)
            self.trainer.extract_and_store(user_message, response)

            # 2. Run conversation trainer (learns from exchange)
            ctx = {
                "last_route": self.last_route,
                "language": "auto",
            }
            train_result = self.conversation_trainer.process_exchange(
                user_message, response, context=ctx
            )

            # 3. If model is ready for retrain, trigger adaptation
            if train_result.get("should_retrain"):
                self._trigger_model_adaptation()

        except Exception:
            # Silently fail — never interrupt conversation
            pass

    def _trigger_model_adaptation(self):
        """Trigger incremental model fine-tuning."""
        try:
            # Get recent training pairs
            batch = self.conversation_trainer.get_training_batch(limit=50)
            if not batch or len(batch) < 5:
                return

            # Adapt the model
            adapt_result = self.model_adapter.adapt_model_from_training_data(batch)

            # Log success
            if adapt_result.get("success"):
                status = self.conversation_trainer.get_adaptation_status()
                print(f"✨ Model adapted! {adapt_result['training_pairs']} personalization pairs")
                print(f"   Adaptation stage: {status['adaptation_strength']:.0f}%")

        except Exception:
            pass

    def get_learning_status(self) -> Dict:
        """Get current learning/adaptation status."""
        try:
            return {
                "self_trainer": self.trainer.get_learning_stats(),
                "adaptation": self.conversation_trainer.get_adaptation_status(),
                "model": self.model_adapter.get_adaptation_metrics(),
            }
        except Exception:
            return {}

    def _format_learning_report(self, status: Dict) -> str:
        """Format learning status for display."""
        st = status.get("self_trainer", {})
        ad = status.get("adaptation", {})

        report = []
        report.append("✨ NILA LEARNING STATUS")
        report.append("─" * 40)

        if st:
            report.append(f"📚 Memory: {st.get('goals_count', 0)} goals, {st.get('preferences_count', 0)} preferences")

        if ad:
            convs = ad.get("conversations_processed", 0)
            pairs = ad.get("training_pairs_accumulated", 0)
            strength = ad.get("adaptation_strength", 0)

            if convs > 0:
                report.append(f"🧠 Learned from {convs} messages")
                report.append(f"  Training pairs: {pairs}")
                report.append(f"  Personalization: {strength:.0f}%")

                next_retrain = ad.get("next_retrain_in", 25)
                if next_retrain <= 3:
                    report.append(f"  🛠️  Model tune-up in {next_retrain} messages!")

        report.append("─" * 40)
        report.append("Every message makes me smarter about your preferences ✦")

        return "\n".join(report)

    @staticmethod
    def _extract_text(parts) -> str:
        """Extract text from response parts."""
        texts = []
        for part in parts:
            if part.text:
                texts.append(part.text)
        return "\n".join(texts) if texts else "[No text in response]"
