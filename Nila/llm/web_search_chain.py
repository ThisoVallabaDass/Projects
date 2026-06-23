"""
Nila Web Search Chain — Auto-failover across providers.
Scrapes web ONCE, then feeds results to providers in order.
First provider to give a useful answer wins.

Gemini gets native Google Search grounding FIRST (best results).
Falls back to enriched_prompt with scraped content if grounding fails.
"""

import os
from typing import Tuple
from tools.scraper import scrape_web


# System prompt for all online providers when handling web search queries
_WEB_SEARCH_SYSTEM = """You are Nila, a personal AI life coach in YearZero app.
Answer the user's question directly and helpfully using the web search results provided.
If location-based (restaurant, shop, hotel): list specific names, areas, and ratings clearly.
If the search results contain relevant info: use it fully and cite sources.
Speak in the same language as the user (Tamil/Tanglish/English).
Be warm, direct, like a knowledgeable Tamil friend. No corporate speak.
Never say "I couldn't find results" — always provide useful information."""


class WebSearchChain:
    """
    Tries each provider in order for web-search queries.
    Gemini gets native Google Search grounding FIRST (best results).
    Falls back to enriched prompt with scraped content.
    First provider to give a useful answer wins.
    Never shows errors to user — silently switches.
    """

    def __init__(self, gemini_chat_fn, groq_client, openrouter_client, local_model):
        """
        Args:
            gemini_chat_fn: Callable(user_message, lang_instruction) -> str
            groq_client: GroqClient instance (or None)
            openrouter_client: OpenRouterClient instance (or None)
            local_model: LocalModel instance for final fallback
        """
        self.gemini_chat = gemini_chat_fn
        self.groq = groq_client
        self.openrouter = openrouter_client
        self.local = local_model

    def _try_gemini_grounding(self, user_message: str, lang_instruction: str, history: list = None, context_chain: str = "") -> str | None:
        """
        Try Gemini with native Google Search grounding (Method 1 — best results).
        Returns answer string or None if grounding fails.
        """
        try:
            from google import genai
            from google.genai import types

            api_key = os.getenv("GOOGLE_API_KEY")
            if not api_key:
                return None

            client = genai.Client(api_key=api_key)

            messages = []
            if history:
                for msg in history:
                    role = "user" if msg["role"] == "user" else "model"
                    messages.append(types.Content(
                        role=role,
                        parts=[types.Part(text=msg["content"])],
                    ))

            augmented_message = f"[{lang_instruction}]\n\nUser question: {user_message}"
            messages.append(types.Content(
                role="user",
                parts=[types.Part(text=augmented_message)],
            ))

            system_instruction = (
                "You are Nila, a personal AI assistant. "
                "Answer the user's question using real web search results. "
                "Be specific, factual, and complete. "
                "Cite sources when possible. "
                "Speak in the same language as the user."
            )
            if context_chain:
                system_instruction = f"{context_chain}\n\n{system_instruction}"

            response = client.models.generate_content(
                model="gemini-2.5-flash",
                contents=messages,
                config=types.GenerateContentConfig(
                    system_instruction=system_instruction,
                    tools=[types.Tool(google_search=types.GoogleSearch())],
                    max_output_tokens=1024,
                    temperature=0.7,
                )
            )

            result = response.text.strip() if hasattr(response, 'text') else str(response).strip()
            if result and len(result) > 30:
                return result

        except Exception:
            pass  # grounding failed, will try enriched prompt

        return None

    def _try_gemini_enriched(self, enriched_prompt: str) -> str | None:
        """
        Try Gemini with enriched prompt containing scraped web content (Method 2 — fallback).
        Returns answer string or None if fails.
        """
        try:
            # Use the regular gemini_chat function (which has tools)
            response = self.gemini_chat(enriched_prompt, "Respond in the same language as the user.")
            if response and len(response.strip()) > 20:
                return response
        except Exception:
            pass

        return None

    def search_and_answer(self, user_message: str, memory_context: str,
                          history: list = None,
                          force_model: str = None,
                          lang_instruction: str = "Respond in English.",
                          context_chain: str = "") -> Tuple[str, str]:
        """
        Full pipeline:
        1. Scrape web for relevant content (DuckDuckGo)
        2. Build enriched prompt with scraped data
        3. Try providers in order until one succeeds (or try forced model if specified):
           a. Gemini with Google Search grounding (best)
           b. Gemini with enriched prompt (fallback)
           c. Groq with enriched prompt
           d. OpenRouter with enriched prompt
           e. Local with enriched prompt
        4. Return (answer, route_label)
        """
        # Step 1: Scrape web — do this ONCE, share with all providers
        scraped_content = ""
        try:
            scraped_content = scrape_web(query=user_message)
            if scraped_content and "did not return useful results" in scraped_content:
                scraped_content = ""
        except Exception:
            scraped_content = ""

        # Step 2: Build enriched prompt
        if scraped_content:
            enriched_prompt = (
                f'Web search results for: "{user_message}"\n\n'
                f"SCRAPED DATA:\n{scraped_content[:2500]}\n\n"
                f"USER MEMORY:\n{memory_context[:500]}\n\n"
                f"Based on the web search results above, answer the user's question:\n"
                f'"{user_message}"\n\n'
                "Be specific, list actual names, addresses if found. "
                "Speak in the same language the user used."
            )
        else:
            enriched_prompt = user_message

        # Determine web search system prompt with context chain
        web_sys = f"{context_chain}\n\n{_WEB_SEARCH_SYSTEM}" if context_chain else _WEB_SEARCH_SYSTEM

        # ── FORCED MODEL ROUTING ──
        if force_model:
            if force_model == "gemini":
                gemini_grounding_result = self._try_gemini_grounding(user_message, lang_instruction, history=history, context_chain=context_chain)
                if gemini_grounding_result:
                    return gemini_grounding_result, "📡 Gemini 🔍"
                gemini_enriched_result = self._try_gemini_enriched(enriched_prompt)
                if gemini_enriched_result:
                    return gemini_enriched_result, "📡 Gemini 🌐"
                return "Gemini search failed.", "NONE"
                
            elif force_model == "groq":
                if self.groq and self.groq.is_available():
                    try:
                        response = self.groq.chat(
                            enriched_prompt,
                            system_prompt=web_sys,
                            history=history,
                            max_tokens=1024,
                            timeout=15,
                        )
                        if response and len(response.strip()) > 20:
                            return response, "⚡ Groq 🌐"
                    except Exception as e:
                        return f"Groq search failed: {str(e)[:100]}", "NONE"
                return "Groq search unavailable.", "NONE"
                
            elif force_model == "openrouter":
                if self.openrouter and self.openrouter.is_available():
                    try:
                        response = self.openrouter.chat(
                            enriched_prompt,
                            system_prompt=web_sys,
                            history=history,
                            max_tokens=1024,
                            timeout=15,
                        )
                        if response and len(response.strip()) > 20:
                            return response, "🌐 OpenRouter 🌐"
                    except Exception as e:
                        return f"OpenRouter search failed: {str(e)[:100]}", "NONE"
                return "OpenRouter search unavailable.", "NONE"
                
            elif force_model == "ollama":
                if self.local and self.local.is_available():
                    context = memory_context
                    if scraped_content:
                        context = f"WEB SEARCH RESULTS:\n{scraped_content[:1500]}\n\n{memory_context}"
                    fallback = self.local.reply_with_memory(
                        user_message, context, history=history, language="auto", context_chain=context_chain
                    )
                    return fallback, "🖥️ Local"
                return "Local search unavailable.", "NONE"

        # Step 3: Try Gemini with Google Search grounding (BEST METHOD)
        gemini_grounding_result = self._try_gemini_grounding(user_message, lang_instruction, history=history, context_chain=context_chain)
        if gemini_grounding_result:
            return gemini_grounding_result, "📡 Gemini 🔍"

        # Step 4: Try Gemini with enriched prompt (FALLBACK METHOD)
        gemini_enriched_result = self._try_gemini_enriched(enriched_prompt)
        if gemini_enriched_result:
            return gemini_enriched_result, "📡 Gemini 🌐"

        # Step 5: Try Groq with scraped content
        if self.groq and self.groq.is_available():
            try:
                response = self.groq.chat(
                    enriched_prompt,
                    system_prompt=web_sys,
                    history=history,
                    max_tokens=1024,
                    timeout=15,
                )
                if response and len(response.strip()) > 20:
                    return response, "⚡ Groq 🌐"
            except Exception:
                pass

        # Step 6: Try OpenRouter with scraped content
        if self.openrouter and self.openrouter.is_available():
            try:
                response = self.openrouter.chat(
                    enriched_prompt,
                    system_prompt=web_sys,
                    history=history,
                    max_tokens=1024,
                    timeout=15,
                )
                if response and len(response.strip()) > 20:
                    return response, "🌐 OpenRouter 🌐"
            except Exception:
                pass

        # Step 7: All online failed — local model with scraped context
        if self.local and self.local.is_available():
            context = memory_context
            if scraped_content:
                context = f"WEB SEARCH RESULTS:\n{scraped_content[:1500]}\n\n{memory_context}"
            fallback = self.local.reply_with_memory(
                user_message, context, history=history, language="auto", context_chain=context_chain
            )
            return fallback + "\n_(web search unavailable)_", "🖥️ Local"

        return (
            "All providers unavailable. Type `status` to check connections.",
            "NONE",
        )
