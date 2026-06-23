"""
OpenRouter Client — Access 100+ models (many free) with one API key.
Get free API key: https://openrouter.ai
Free models: google/gemma-2-9b-it:free, meta-llama/llama-3.1-8b-instruct:free
"""

import os
import requests
from typing import Optional


from core.config import OPENROUTER_API_KEY, OPENROUTER_MODEL


class OpenRouterClient:
    """OpenRouter API client for the Nila Council system."""

    BASE_URL = "https://openrouter.ai/api/v1/chat/completions"

    FREE_MODELS = [
        "google/gemma-2-9b-it:free",
        "meta-llama/llama-3.1-8b-instruct:free",
        "mistralai/mistral-7b-instruct:free",
        "microsoft/phi-3-mini-128k-instruct:free",
        "qwen/qwen-2-7b-instruct:free",
    ]

    def __init__(self):
        self.api_key = OPENROUTER_API_KEY
        self.model = OPENROUTER_MODEL
        self.available = bool(self.api_key)

    def is_available(self) -> bool:
        return self.available

    def chat(self, user_message: str, system_prompt: str = "",
             memory_context: str = "", history: list = None,
             max_tokens: int = 2048, temperature: float = 0.7,
             timeout: int = 30) -> str:
        """Send a message to OpenRouter API. Raises on failure."""
        if not self.available:
            raise ConnectionError("OPENROUTER_API_KEY not set")

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
                    "HTTP-Referer": "https://yearzero.local",
                    "X-Title": "YearZero - Nila Agent",
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
                    f"OpenRouter error {response.status_code}: {response.text[:200]}"
                )
        except requests.exceptions.RequestException as e:
            raise ConnectionError(f"OpenRouter connection failed: {e}")
