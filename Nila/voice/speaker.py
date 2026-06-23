"""
Nila Voice Speaker — Async Streaming TTS with sentence-level chunking.

Pipeline:
1. Receive text (or async stream of text chunks)
2. Split into sentences at natural boundaries (. ! ? ;)
3. Push sentences into a thread-safe Queue
4. Background daemon thread synthesizes and plays audio sequentially
5. On stop event, clear queue and interrupt active playback instantly
"""

import asyncio
import os
import re
import time
import queue
import threading
from typing import AsyncIterator, Optional

# Reuse the existing text cleaning from tools/voice.py
from tools.voice import clean_text_for_speech

# ─── Configuration ───────────────────────────────────────────────────
EDGE_VOICE = "en-IN-NeerjaNeural"
EDGE_FALLBACKS = ["en-IN-NeerjaExpressiveNeural", "en-IN-PrabhatNeural", "en-US-JennyNeural"]

_SENTENCE_SPLIT = re.compile(r'(?<=[.!?;])\s+')
_DATA_DIR = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "data")


class Speaker:
    """
    Async streaming TTS speaker using a daemon worker thread and thread-safe queue.
    """

    def __init__(self):
        self._stop_event = threading.Event()
        self._speaking = False
        self._mixer_ready = False
        self._last_spoken_text = ""
        self._queue = queue.Queue()
        self._worker_thread = None
        self._ensure_worker_running()

    def _ensure_worker_running(self):
        """Ensure the background playback daemon thread is running."""
        if self._worker_thread is None or not self._worker_thread.is_alive():
            # If the stop event was set from a previous run, clear it
            self._stop_event.clear()
            self._worker_thread = threading.Thread(target=self._worker_loop, daemon=True)
            self._worker_thread.start()

    def _queue_clear(self):
        """Clear all pending sentences from the queue."""
        while not self._queue.empty():
            try:
                self._queue.get_nowait()
                self._queue.task_done()
            except queue.Empty:
                break

    def _worker_loop(self):
        """Background worker thread loop running a dedicated asyncio loop for TTS synthesis."""
        loop = asyncio.new_event_loop()
        asyncio.set_event_loop(loop)

        while True:
            try:
                # Retrieve next sentence with timeout so we check exit/stop conditions
                sentence = self._queue.get(timeout=0.1)
            except queue.Empty:
                continue

            if sentence is None:  # Sentinel to stop thread
                break

            if self._stop_event.is_set():
                self._queue_clear()
                self._queue.task_done()
                continue

            # Synthesize and play
            try:
                loop.run_until_complete(self._speak_sentence_sync(sentence))
            except Exception as e:
                pass
            finally:
                self._queue.task_done()

        loop.close()

    async def _speak_sentence_sync(self, sentence: str):
        """Speak a single sentence in the worker thread. Tries edge-tts first, then pyttsx3."""
        if self._stop_event.is_set():
            return

        success = await self._speak_edge_async(sentence)
        if success:
            return

        # Fallback to pyttsx3 (blocking synchronous SAPI5 call)
        if not self._stop_event.is_set():
            self._speak_pyttsx3(sentence)

    async def _speak_edge_async(self, text: str) -> bool:
        """Generate speech with edge-tts and play it."""
        try:
            import edge_tts
        except ImportError:
            return False

        # Create unique temp file for this synthesis to avoid collision
        os.makedirs(_DATA_DIR, exist_ok=True)
        mp3_path = os.path.join(_DATA_DIR, f"nila_voice_{id(self) % 10000}_{int(time.time() * 1000) % 1000}.mp3")

        try:
            communicate = edge_tts.Communicate(text, EDGE_VOICE)
            await communicate.save(mp3_path)

            if self._stop_event.is_set():
                self._safe_remove(mp3_path)
                return True

            self._play_mp3(mp3_path)
            return True

        except Exception:
            # Fallbacks
            for voice in EDGE_FALLBACKS:
                if self._stop_event.is_set():
                    self._safe_remove(mp3_path)
                    return True
                try:
                    communicate = edge_tts.Communicate(text, voice)
                    await communicate.save(mp3_path)
                    if not self._stop_event.is_set():
                        self._play_mp3(mp3_path)
                    return True
                except Exception:
                    continue
            self._safe_remove(mp3_path)
            return False

    def _play_mp3(self, mp3_path: str):
        """Play an MP3 file using pygame.mixer or sounddevice, checking stop_event."""
        try:
            import pygame

            if not pygame.mixer.get_init():
                pygame.mixer.init()

            pygame.mixer.music.load(mp3_path)
            pygame.mixer.music.play()

            # Poll busy status, interrupt if stop event is set
            while pygame.mixer.music.get_busy():
                if self._stop_event.is_set():
                    pygame.mixer.music.stop()
                    break
                time.sleep(0.02)

            try:
                pygame.mixer.music.unload()
            except Exception:
                pass

        except Exception:
            # Fallback to sounddevice + soundfile if pygame fails
            try:
                import soundfile as sf
                import sounddevice as sd
                data, samplerate = sf.read(mp3_path, dtype="float32")
                sd.play(data, samplerate)
                while sd.get_stream().active:
                    if self._stop_event.is_set():
                        sd.stop()
                        break
                    time.sleep(0.02)
                sd.wait()
            except Exception:
                pass

        finally:
            self._safe_remove(mp3_path)

    def _speak_pyttsx3(self, text: str):
        """Offline fallback using Windows SAPI5 (Zira voice)."""
        try:
            import pyttsx3
            engine = pyttsx3.init()
            engine.setProperty('rate', 175)
            engine.setProperty('volume', 1.0)

            voices = engine.getProperty('voices')
            for v in voices:
                if "zira" in v.name.lower():
                    engine.setProperty('voice', v.id)
                    break

            if not self._stop_event.is_set():
                engine.say(text)
                engine.runAndWait()
        except Exception:
            pass

    def _stop_playback(self):
        """Force-stop active hardware playbacks."""
        try:
            import pygame
            if pygame.mixer.get_init():
                pygame.mixer.music.stop()
                try:
                    pygame.mixer.music.unload()
                except Exception:
                    pass
        except Exception:
            pass
        try:
            import sounddevice as sd
            sd.stop()
        except Exception:
            pass

    def _safe_remove(self, path: str):
        try:
            if os.path.exists(path):
                os.remove(path)
        except Exception:
            pass

    # ─── Public API ───────────────────────────────────────────────────

    async def speak(self, text: str):
        """Speak a complete text. Splits into sentences and queues them."""
        self._stop_event.clear()
        self._ensure_worker_running()
        self._speaking = True
        self._last_spoken_text = text

        clean = clean_text_for_speech(text)
        if not clean or len(clean) < 3:
            self._speaking = False
            return

        sentences = self._split_sentences(clean)
        for sentence in sentences:
            if self._stop_event.is_set():
                break
            self._queue.put(sentence)

        # Wait until current playback tasks finish
        while self._speaking and not self._queue.empty() and not self._stop_event.is_set():
            await asyncio.sleep(0.05)

        self._speaking = False

    async def speak_stream(self, token_stream: AsyncIterator[str]):
        """
        Speak from a stream of text tokens (from streaming LLM).
        Buffers tokens, splits on sentence boundaries, and queues
        each sentence immediately to background worker.
        """
        self._stop_event.clear()
        self._ensure_worker_running()
        self._speaking = True

        buffer = ""
        spoken_parts = []

        try:
            async for token in token_stream:
                if self._stop_event.is_set():
                    break

                buffer += token

                # Extract sentences on the fly
                while True:
                    match = _SENTENCE_SPLIT.search(buffer)
                    if not match:
                        break

                    split_pos = match.start()
                    sentence = buffer[:split_pos + 1].strip()
                    buffer = buffer[match.end():]

                    if sentence and len(sentence) > 2:
                        clean = clean_text_for_speech(sentence)
                        if clean:
                            spoken_parts.append(clean)
                            self._queue.put(clean)

                    if self._stop_event.is_set():
                        break

            # Process remaining text in buffer
            if buffer.strip() and not self._stop_event.is_set():
                clean = clean_text_for_speech(buffer.strip())
                if clean and len(clean) > 2:
                    spoken_parts.append(clean)
                    self._queue.put(clean)

            self._last_spoken_text = " ".join(spoken_parts)

            # Wait for background thread to finish playing queued items
            while self._speaking and not self._queue.empty() and not self._stop_event.is_set():
                await asyncio.sleep(0.05)

        except asyncio.CancelledError:
            pass
        finally:
            self._speaking = False

    def stop(self):
        """Immediately stop all speech and clear the queue."""
        self._stop_event.set()
        self._stop_playback()
        self._queue_clear()
        self._speaking = False

    async def repeat(self):
        """Re-speak the last spoken text."""
        if self._last_spoken_text:
            await self.speak(self._last_spoken_text)

    @property
    def is_speaking(self) -> bool:
        # Check if the queue still has items or active synthesis is occurring
        return self._speaking or not self._queue.empty()

    @property
    def last_text(self) -> str:
        return self._last_spoken_text

    def _split_sentences(self, text: str) -> list[str]:
        """Split text into sentences for sequential TTS."""
        sentences = _SENTENCE_SPLIT.split(text)
        return [s.strip() for s in sentences if s.strip() and len(s.strip()) > 2]
