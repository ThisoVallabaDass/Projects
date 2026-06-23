"""
Ollama Client — Interface to local LLM running via Ollama.
Supports both legacy API (requests) and new council methods.
"""

import requests
import json
from typing import Optional

from core.config import LOCAL_MODEL_CONTEXT_LENGTH


class OllamaClient:
    """
    Client to interact with a local LLM running via Ollama.

    Setup:
    1. Download Ollama from https://ollama.ai
    2. Run: ollama pull llama3.1:8b
    3. Start Ollama server (default: http://localhost:11434)
    """

    def __init__(self, host: str = "http://localhost:11434", model: str = "llama3.1:8b"):
        self.host = host
        self.model = model
        self.api_generate_url = f"{host}/api/generate"
        self.api_chat_url = f"{host}/api/chat"

    def is_available(self) -> bool:
        """Check if Ollama server is running and has the requested model."""
        try:
            response = requests.get(f"{self.host}/api/tags", timeout=3)
            return response.status_code == 200
        except Exception:
            return False

    # ------------------------------------------------------------------
    # Legacy methods (used by agent.py _chat_mistral)
    # ------------------------------------------------------------------

    def generate(self, prompt: str = None, max_tokens: int = 2048,
                 temperature: float = 0.7, stream: bool = False,
                 *, system_prompt: str = None, user_message: str = None) -> str:
        """
        Call local LLM to generate text.
        
        Supports two calling conventions:
        1. Legacy: generate(prompt="...") — raw prompt
        2. Council: generate(system_prompt="...", user_message="...") — structured
        """
        # Council-style call: system_prompt + user_message
        if system_prompt is not None and user_message is not None:
            return self._generate_with_system(system_prompt, user_message, max_tokens, temperature)
        
        # Legacy-style call: raw prompt
        if prompt is None:
            return "[Error: No prompt provided]"
            
        payload = {
            "model": self.model,
            "prompt": prompt,
            "stream": stream,
            "options": {
                "num_predict": max_tokens,
                "num_ctx": LOCAL_MODEL_CONTEXT_LENGTH,
                "temperature": temperature,
                "top_p": 0.9,
                "repeat_penalty": 1.1,
                "num_thread": 6,
            },
        }

        try:
            response = requests.post(self.api_generate_url, json=payload, timeout=180)
            response.raise_for_status()

            if stream:
                full_response = ""
                for line in response.iter_lines():
                    if line:
                        data = json.loads(line)
                        full_response += data.get("response", "")
                return full_response.strip()
            else:
                data = response.json()
                return data.get("response", "").strip()

        except requests.exceptions.RequestException as e:
            return f"[Error calling Ollama: {e}]"

    def chat(self, messages: list, max_tokens: int = 2048,
             temperature: float = 0.7) -> str:
        """
        Chat interface (keeps conversation history).
        """
        payload = {
            "model": self.model,
            "messages": messages,
            "stream": False,
            "options": {
                "num_predict": max_tokens,
                "num_ctx": LOCAL_MODEL_CONTEXT_LENGTH,
                "temperature": temperature,
                "top_p": 0.9,
                "repeat_penalty": 1.1,
                "num_thread": 6,
            },
        }

        try:
            response = requests.post(self.api_chat_url, json=payload, timeout=180)
            response.raise_for_status()
            data = response.json()
            return data.get("message", {}).get("content", "").strip()

        except requests.exceptions.RequestException as e:
            return f"[Error calling Ollama: {e}]"

    # ------------------------------------------------------------------
    # Council methods (new — used by llm/council.py)
    # ------------------------------------------------------------------

    def _generate_with_system(self, system_prompt: str, user_message: str,
                               max_tokens: int = 1024, temperature: float = 0.7) -> str:
        """
        Generate with system prompt + user message via chat API.
        Used by the council for mode-specific prompts.
        """
        messages = [
            {"role": "system", "content": system_prompt},
            {"role": "user", "content": user_message},
        ]
        payload = {
            "model": self.model,
            "messages": messages,
            "stream": False,
            "options": {
                "num_predict": max_tokens,
                "num_ctx": LOCAL_MODEL_CONTEXT_LENGTH,
                "temperature": temperature,
                "top_p": 0.9,
                "repeat_penalty": 1.1,
                "num_thread": 6,
                "stop": ["User:", "\nUser:", "Human:"],
            },
        }

        try:
            response = requests.post(self.api_chat_url, json=payload, timeout=180)
            response.raise_for_status()
            data = response.json()
            return data.get("message", {}).get("content", "").strip()
        except requests.exceptions.RequestException as e:
            return f"[Error calling Ollama: {e}]"

    def generate_raw(self, prompt: str, max_tokens: int = 512) -> str:
        """
        Generate from raw prompt with no persona wrapping.
        Used by council for context extraction between models.
        """
        payload = {
            "model": self.model,
            "prompt": prompt,
            "stream": False,
            "options": {
                "num_predict": max_tokens,
                "num_ctx": 4096,
                "temperature": 0.5,
                "top_p": 0.9,
                "repeat_penalty": 1.1,
                "num_thread": 6,
            },
        }

        try:
            response = requests.post(self.api_generate_url, json=payload, timeout=120)
            response.raise_for_status()
            data = response.json()
            return data.get("response", "").strip()
        except requests.exceptions.RequestException as e:
            return f"[Error calling Ollama: {e}]"

    # ------------------------------------------------------------------
    # Model management
    # ------------------------------------------------------------------

    def warmup(self) -> None:
        """Warm up the model asynchronously by sending a load request to Ollama."""
        import threading
        def load():
            try:
                # Omit prompt to load the model into memory
                payload = {"model": self.model}
                requests.post(self.api_generate_url, json=payload, timeout=180)
            except Exception:
                pass
        threading.Thread(target=load, daemon=True).start()

    def pull_model(self) -> bool:
        """Download the model if not already available."""
        try:
            payload = {"name": self.model}
            response = requests.post(f"{self.host}/api/pull", json=payload, timeout=300)
            return response.status_code == 200
        except Exception as e:
            print(f"Error pulling model: {e}")
            return False

    def get_model_info(self) -> Optional[dict]:
        """Get info about available models."""
        try:
            response = requests.get(f"{self.host}/api/tags", timeout=5)
            if response.status_code == 200:
                return response.json()
            return None
        except Exception:
            return None

    def list_models(self) -> list:
        """Return list of model names available on Ollama."""
        try:
            info = self.get_model_info()
            if info:
                return [m.get("name", "") for m in info.get("models", [])]
            return []
        except Exception:
            return []
