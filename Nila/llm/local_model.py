"""
Nila Local Model — Pre-warmed Ollama interface for instant responses.
Pre-warms model on startup so first response is fast.
Provides quick_reply (instant, minimal context) and
reply_with_memory (full context, personal questions).
"""

import os
import threading
import requests
import json


class LocalModel:
    """
    Manages local Ollama model.
    Pre-warms on startup so first response is fast.
    """

    def __init__(self, host: str = "http://localhost:11434"):
        self.host = host
        self.api_generate_url = f"{host}/api/generate"
        self.api_chat_url = f"{host}/api/chat"
        from core.config import LOCAL_MODEL, LOCAL_MODEL_FALLBACK
        self.model = LOCAL_MODEL
        self.fallback_model = LOCAL_MODEL_FALLBACK
        self._warmed = False
        self._available = False

        # Auto-detect best model
        self._detect_model()

        # Pre-warm in background (skip in evaluation mode)
        if self._available and os.getenv("EVAL_MODE", "false").lower() != "true":
            threading.Thread(target=self._prewarm, daemon=True).start()

    def _detect_model(self):
        """Auto-detect best available local model."""
        try:
            resp = requests.get(f"{self.host}/api/tags", timeout=3)
            if resp.status_code != 200:
                return
            models = resp.json().get("models", [])
            names = {m.get("name", "").split(":")[0] for m in models}
            full_names = {m.get("name", "") for m in models}
            self._available = True

            configured_base = self.model.split(":")[0]
            fallback_base = self.fallback_model.split(":")[0]

            if self.model in full_names or configured_base in names:
                # Configuration model is available, use it!
                pass
            elif self.fallback_model in full_names or fallback_base in names:
                self.model = self.fallback_model
            elif "nila" in names:
                self.model = "nila:latest" if "nila:latest" in full_names else "nila"
            elif "llama3.1" in names:
                self.model = "llama3.1:8b" if "llama3.1:8b" in full_names else "llama3.1"
            elif "mistral" in names:
                self.model = "mistral:latest" if "mistral:latest" in full_names else "mistral"
        except Exception:
            pass

    def _prewarm(self):
        """Send a dummy request on startup to load model into RAM."""
        try:
            payload = {"model": self.model}
            requests.post(self.api_generate_url, json=payload, timeout=180)
            self._warmed = True
        except Exception:
            try:
                # Just attempt to warm the fallback model but don't overwrite self.model
                payload = {"model": self.fallback_model}
                requests.post(self.api_generate_url, json=payload, timeout=180)
            except Exception:
                pass

    def quick_reply(self, user_message: str, quick_context: str,
                    history: list = None, language: str = "auto", context_chain: str = "") -> str:
        """
        Fast response for simple queries.
        Uses minimal context for speed.
        Max 3 sentences output.
        """
        lang_instruction = {
            "tanglish": "Reply in Tanglish (Tamil words in English letters). Casual, warm, short.",
            "tamil_script": "Reply in Tamil script. Warm and natural.",
            "english": "Reply in English. Casual and warm.",
        }.get(language, "Reply in the same language the user used.")

        system = (f"{context_chain}\n\n" if context_chain else "") + (
            f"You are Nila, a personal AI companion. {lang_instruction}\n"
            "Keep response to 2-3 sentences maximum. Be warm and natural.\n"
            "Never say you are an AI or language model. You are Nila.\n"
            f"User context: {quick_context}"
        )

        try:
            messages = []
            messages.append({"role": "system", "content": system})
            if history:
                for msg in history:
                    role = "assistant" if msg["role"] == "model" else msg["role"]
                    messages.append({"role": role, "content": msg["content"]})
            messages.append({"role": "user", "content": user_message})
            payload = {
                "model": self.model,
                "messages": messages,
                "stream": False,
                "options": {
                    "num_predict": 150,
                    "num_ctx": 1024,
                    "temperature": 0.8,
                    "top_p": 0.9,
                    "num_thread": 6,
                    "stop": ["User:", "\nUser:", "Human:"],
                },
            }
            response = requests.post(self.api_chat_url, json=payload, timeout=30)
            response.raise_for_status()
            data = response.json()
            result = data.get("message", {}).get("content", "").strip()
            if result:
                return result
            return self._fallback_reply(user_message, language)
        except Exception:
            return self._fallback_reply(user_message, language)

    def reply_with_memory(self, user_message: str, full_context: str,
                          history: list = None, language: str = "auto", context_chain: str = "") -> str:
        """
        Slower response with full memory context.
        For personal/memory questions that need more detail.
        """
        lang_map = {
            "tanglish": "Reply in Tanglish. Be natural like a Tamil friend.",
            "tamil_script": "Reply in Tamil script.",
            "english": "Reply in English.",
        }
        lang_instruction = lang_map.get(language, "Reply in the same language as the user.")

        system = (f"{context_chain}\n\n" if context_chain else "") + (
            f"You are Nila, Theo's personal AI coach in YearZero.\n"
            f"{lang_instruction}\n"
            "Give complete answers. Minimum 3 sentences. Never cut off.\n"
            "Never say you're \"in offline mode\" or \"limited\" — you ARE Nila, always capable.\n"
            "You are part of the Nila Council — a multi-AI system. You handle personal memory, "
            "Tamil chat, emotional support. For web search, the Council routes to online AIs.\n\n"
            f"{full_context}"
        )

        try:
            messages = []
            messages.append({"role": "system", "content": system})
            if history:
                for msg in history:
                    role = "assistant" if msg["role"] == "model" else msg["role"]
                    messages.append({"role": role, "content": msg["content"]})
            messages.append({"role": "user", "content": user_message})
            payload = {
                "model": self.model,
                "messages": messages,
                "stream": False,
                "options": {
                    "num_predict": 1024,
                    "num_ctx": 2048,
                    "temperature": 0.7,
                    "top_p": 0.9,
                    "repeat_penalty": 1.1,
                    "num_thread": 6,
                    "stop": ["User:", "\nUser:", "Human:"],
                },
            }
            response = requests.post(self.api_chat_url, json=payload, timeout=180)
            response.raise_for_status()
            data = response.json()
            result = data.get("message", {}).get("content", "").strip()
            if result:
                return result
            return "Konjam problem iruku da. Retry pannu."
        except Exception:
            return "Konjam problem iruku da. Retry pannu."

    def _fallback_reply(self, message: str, language: str) -> str:
        """Ultra-fast hardcoded fallback for pure instant responses."""
        msg = message.lower().strip()

        tanglish_replies = {
            "hi": "Vanakkam da! Enna vishayam?",
            "hello": "Hello da! Enna panrom today?",
            "hey": "Hey! Enna da news?",
            "good morning": "Good morning da! Nalla day-a irukattum!",
            "good night": "Good night da! Nalla thoonghu!",
            "good afternoon": "Good afternoon! Lunch saapita?",
            "how are you": "Nalla irukken da! Nee epdi irukka?",
            "how r u": "Super-a irukken! Nee?",
            "thanks": "Welcome da! Vera enna venum?",
            "thank you": "No problem da! Anytime.",
            "bye": "Bye da! Take care!",
            "ok": "Seri da!",
            "okay": "Okay da!",
            "seri": "Seri!",
            "tired": "Rest eduthutu vaaa da. Oru konjam break-a?",
            "bored": "Aiyoo bore-a? Padikaalam-a? Or just talk panrom?",
            "sup": "Enna da! Tell me.",
            "yo": "Yo! Enna scene?",
        }

        english_replies = {
            "hi": "Hey! What's up?",
            "hello": "Hello! How can I help?",
            "hey": "Hey there! What's on your mind?",
            "good morning": "Good morning! Ready to crush some goals today?",
            "good afternoon": "Good afternoon! How's the day going?",
            "good night": "Good night! Rest well.",
            "how are you": "I'm doing great! What about you?",
            "how r u": "Doing well! How about you?",
            "thanks": "You're welcome! Anything else?",
            "thank you": "No problem! Happy to help.",
            "bye": "Bye! Take care!",
            "ok": "Got it!",
            "okay": "Sure thing!",
            "tired": "Take a break — you deserve it. Come back refreshed!",
            "bored": "Let's do something! Want to study or just chat?",
        }

        replies = tanglish_replies if language in ["tanglish", "tamil_script"] else english_replies

        for trigger, reply in replies.items():
            if trigger in msg:
                return reply

        if language in ["tanglish", "tamil_script"]:
            return "Seri da! Enna pannanumnu sollu."
        return "Sure! What would you like to do?"

    def is_available(self) -> bool:
        """Check if local model is available."""
        try:
            resp = requests.get(f"{self.host}/api/tags", timeout=3)
            return resp.status_code == 200
        except Exception:
            return False
