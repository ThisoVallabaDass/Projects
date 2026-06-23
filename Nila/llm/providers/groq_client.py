"""
Groq Client — Free, extremely fast LLM API (200+ tokens/sec)
Get free API key: https://console.groq.com
Models: llama-3.1-70b-versatile, mixtral-8x7b-32768, gemma2-9b-it
"""

import os
import requests
from typing import Optional


from core.config import GROQ_API_KEY, GROQ_MODEL


class GroqClient:
    """Groq API client for the Nila Council system."""

    BASE_URL = "https://api.groq.com/openai/v1/chat/completions"

    def __init__(self):
        self.api_key = GROQ_API_KEY
        self.model = GROQ_MODEL
        self.available = bool(self.api_key)

    def is_available(self) -> bool:
        return self.available

    def chat(self, user_message: str, system_prompt: str = "",
             memory_context: str = "", history: list = None,
             max_tokens: int = 2048, temperature: float = 0.7,
             timeout: int = 30) -> str:
        """Send a message to Groq API. Raises on failure."""
        if not self.available:
            raise ConnectionError("GROQ_API_KEY not set")

        messages = []
        combined_system = ""
        if system_prompt:
            combined_system += system_prompt
        if memory_context:
            combined_system += f"\n\n{memory_context}"
        if combined_system.strip():
            messages.append({"role": "system", "content": combined_system.strip()})

        if history:
            for msg in history:
                role = "assistant" if msg["role"] == "model" else msg["role"]
                messages.append({"role": role, "content": msg["content"]})

        messages.append({"role": "user", "content": user_message})

        try:
            response = requests.post(
                self.BASE_URL,
                headers={
                    "Authorization": f"Bearer {self.api_key}",
                    "Content-Type": "application/json",
                },
                json={
                    "model": self.model,
                    "messages": messages,
                    "max_tokens": max_tokens,
                    "temperature": temperature,
                },
                timeout=timeout,
            )

            if response.status_code == 200:
                return response.json()["choices"][0]["message"]["content"].strip()
            else:
                raise ConnectionError(
                    f"Groq API error {response.status_code}: {response.text[:200]}"
                )
        except requests.exceptions.RequestException as e:
            raise ConnectionError(f"Groq connection failed: {e}")
