"""
Stream Manager — Multi-provider async streaming orchestrator for Nila.

Routes streaming LLM requests to the appropriate provider:
- Ollama (local, streaming via /api/chat with stream=True)
- Groq (online, streaming via OpenAI-compatible SSE)
- Gemini (online, streaming via google.genai SDK)

Used by voice mode to pipe tokens directly to TTS as they arrive.
"""

import asyncio
import json
from typing import AsyncIterator, Optional


class StreamManager:
    """
    Orchestrates streaming responses across all LLM providers.
    
    Usage:
        sm = StreamManager(ollama_host, groq_key, gemini_client)
        async for token in sm.stream("Tell me a joke", provider="ollama"):
            print(token, end="", flush=True)
    """

    def __init__(self, ollama_host: str = "http://localhost:11434",
                 ollama_model: str = "llama3.1:8b",
                 groq_api_key: str = "",
                 groq_model: str = "llama-3.3-70b-versatile",
                 gemini_client=None):
        self._ollama_host = ollama_host
        self._ollama_model = ollama_model
        self._groq_key = groq_api_key
        self._groq_model = groq_model
        self._gemini_client = gemini_client

    async def stream(self, user_message: str,
                     system_prompt: str = "",
                     history: list = None,
                     provider: str = "ollama",
                     max_tokens: int = 1024,
                     temperature: float = 0.7) -> AsyncIterator[str]:
        """
        Stream tokens from the specified provider.
        
        Args:
            user_message: The user's input
            system_prompt: System prompt to prepend
            history: Conversation history in [{role, content}] format
            provider: "ollama", "groq", "gemini", or "auto"
            max_tokens: Maximum tokens to generate
            temperature: Sampling temperature
            
        Yields:
            Text tokens as they arrive from the LLM.
        """
        if provider == "auto":
            # Try providers in order
            for p in ["ollama", "groq", "gemini"]:
                try:
                    collected = []
                    async for token in self._stream_provider(
                        p, user_message, system_prompt, history, max_tokens, temperature
                    ):
                        collected.append(token)
                        yield token
                    if collected:
                        return
                except Exception:
                    continue
        else:
            async for token in self._stream_provider(
                provider, user_message, system_prompt, history, max_tokens, temperature
            ):
                yield token

    async def _stream_provider(self, provider: str, user_message: str,
                               system_prompt: str, history: list,
                               max_tokens: int, temperature: float) -> AsyncIterator[str]:
        """Route to the correct provider's streaming method."""
        if provider == "ollama":
            async for token in self._stream_ollama(
                user_message, system_prompt, history, max_tokens, temperature
            ):
                yield token
        elif provider == "groq":
            async for token in self._stream_groq(
                user_message, system_prompt, history, max_tokens, temperature
            ):
                yield token
        elif provider == "gemini":
            async for token in self._stream_gemini(
                user_message, system_prompt, history, max_tokens, temperature
            ):
                yield token

    # ─── Ollama Streaming ─────────────────────────────────────────────

    async def _stream_ollama(self, user_message: str, system_prompt: str,
                             history: list, max_tokens: int,
                             temperature: float) -> AsyncIterator[str]:
        """Stream from local Ollama via HTTP chunked response."""
        try:
            import aiohttp
        except ImportError:
            # Fallback: sync request in executor
            loop = asyncio.get_event_loop()
            result = await loop.run_in_executor(
                None, self._sync_ollama, user_message, system_prompt, history
            )
            if result:
                yield result
            return

        messages = []
        if system_prompt:
            messages.append({"role": "system", "content": system_prompt})
        if history:
            for msg in history:
                role = "assistant" if msg["role"] == "model" else msg["role"]
                messages.append({"role": role, "content": msg["content"]})
        messages.append({"role": "user", "content": user_message})

        payload = {
            "model": self._ollama_model,
            "messages": messages,
            "stream": True,
            "options": {
                "num_predict": max_tokens,
                "num_ctx": 2048,
                "temperature": temperature,
                "top_p": 0.9,
                "num_thread": 6,
                "stop": ["User:", "\nUser:", "Human:"],
            },
        }

        url = f"{self._ollama_host}/api/chat"

        try:
            async with aiohttp.ClientSession() as session:
                async with session.post(url, json=payload, timeout=aiohttp.ClientTimeout(total=180)) as resp:
                    async for line in resp.content:
                        if not line:
                            continue
                        try:
                            data = json.loads(line.decode("utf-8").strip())
                            token = data.get("message", {}).get("content", "")
                            if token:
                                yield token
                            if data.get("done", False):
                                return
                        except json.JSONDecodeError:
                            continue
        except Exception as e:
            # Fallback to sync
            loop = asyncio.get_event_loop()
            result = await loop.run_in_executor(
                None, self._sync_ollama, user_message, system_prompt, history
            )
            if result:
                yield result

    def _sync_ollama(self, user_message: str, system_prompt: str, history: list) -> str:
        """Synchronous Ollama fallback."""
        import requests
        messages = []
        if system_prompt:
            messages.append({"role": "system", "content": system_prompt})
        if history:
            for msg in history:
                role = "assistant" if msg["role"] == "model" else msg["role"]
                messages.append({"role": role, "content": msg["content"]})
        messages.append({"role": "user", "content": user_message})

        try:
            resp = requests.post(
                f"{self._ollama_host}/api/chat",
                json={
                    "model": self._ollama_model,
                    "messages": messages,
                    "stream": False,
                    "options": {"num_predict": 1024, "temperature": 0.7},
                },
                timeout=180,
            )
            return resp.json().get("message", {}).get("content", "")
        except Exception:
            return ""

    # ─── Groq Streaming ──────────────────────────────────────────────

    async def _stream_groq(self, user_message: str, system_prompt: str,
                           history: list, max_tokens: int,
                           temperature: float) -> AsyncIterator[str]:
        """Stream from Groq via OpenAI-compatible SSE endpoint."""
        if not self._groq_key:
            return

        try:
            import aiohttp
        except ImportError:
            return

        messages = []
        if system_prompt:
            messages.append({"role": "system", "content": system_prompt})
        if history:
            for msg in history:
                role = "assistant" if msg["role"] == "model" else msg["role"]
                messages.append({"role": role, "content": msg["content"]})
        messages.append({"role": "user", "content": user_message})

        url = "https://api.groq.com/openai/v1/chat/completions"
        headers = {
            "Authorization": f"Bearer {self._groq_key}",
            "Content-Type": "application/json",
        }
        payload = {
            "model": self._groq_model,
            "messages": messages,
            "max_tokens": max_tokens,
            "temperature": temperature,
            "stream": True,
        }

        try:
            async with aiohttp.ClientSession() as session:
                async with session.post(url, json=payload, headers=headers,
                                       timeout=aiohttp.ClientTimeout(total=30)) as resp:
                    async for line in resp.content:
                        line_str = line.decode("utf-8").strip()
                        if not line_str or not line_str.startswith("data: "):
                            continue
                        data_str = line_str[6:]  # remove "data: "
                        if data_str == "[DONE]":
                            return
                        try:
                            data = json.loads(data_str)
                            delta = data.get("choices", [{}])[0].get("delta", {})
                            token = delta.get("content", "")
                            if token:
                                yield token
                        except json.JSONDecodeError:
                            continue
        except Exception:
            pass

    # ─── Gemini Streaming ─────────────────────────────────────────────

    async def _stream_gemini(self, user_message: str, system_prompt: str,
                             history: list, max_tokens: int,
                             temperature: float) -> AsyncIterator[str]:
        """Stream from Gemini using the google.genai SDK."""
        if not self._gemini_client:
            return

        loop = asyncio.get_event_loop()

        try:
            from google.genai import types

            # Build contents
            contents = []
            if history:
                for msg in history:
                    role = "user" if msg["role"] == "user" else "model"
                    contents.append(types.Content(
                        role=role,
                        parts=[types.Part(text=msg["content"])],
                    ))
            contents.append(types.Content(
                role="user",
                parts=[types.Part(text=user_message)],
            ))

            # Generate with streaming (sync generator, wrap in executor)
            def _generate():
                return self._gemini_client.models.generate_content_stream(
                    model="gemini-2.5-flash",
                    contents=contents,
                    config=types.GenerateContentConfig(
                        system_instruction=system_prompt or "You are Nila, a personal AI assistant.",
                        max_output_tokens=max_tokens,
                        temperature=temperature,
                    ),
                )

            # Run the generator setup in executor
            stream = await loop.run_in_executor(None, _generate)

            # Iterate over the stream
            def _next_chunk(stream_iter):
                try:
                    return next(stream_iter)
                except StopIteration:
                    return None

            while True:
                chunk = await loop.run_in_executor(None, _next_chunk, stream)
                if chunk is None:
                    break
                if hasattr(chunk, 'text') and chunk.text:
                    yield chunk.text

        except Exception as e:
            # Gemini streaming failed
            pass
