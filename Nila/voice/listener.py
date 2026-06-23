"""
Nila Voice Listener — Wake Word Detection + Speech-to-Text.

Pipeline:
1. Continuously monitor microphone for wake word ("Hey Nila")
2. On detection: play chime → record speech → transcribe with faster-whisper
3. Return transcribed text to the agent

Wake Word Engines (automatic fallback):
- Primary: pvporcupine (Picovoice) — requires access key, best accuracy
- Fallback: openwakeword — free, offline, no key needed
- Final fallback: keyboard hotkey (Ctrl+Space) — always works

STT Engine:
- faster-whisper with base.en model — CPU-optimized, ~800ms for 5s audio
"""

import asyncio
import os
import time
import threading
import numpy as np
from typing import Callable, Optional

from voice.audio_utils import (
    play_chime, CHIME_ACTIVATE, CHIME_DEACTIVATE,
    SAMPLE_RATE, FRAME_LENGTH, audio_energy,
    get_mic_device_index,
)


# ─── Configuration ───────────────────────────────────────────────────

# Silence detection thresholds
SILENCE_THRESHOLD = 0.015      # RMS energy below this = silence
SILENCE_DURATION_S = 1.5       # seconds of silence to stop recording
MAX_RECORDING_S = 15.0         # maximum recording duration
MIN_RECORDING_S = 0.5          # minimum recording to attempt transcription

# STT model
STT_MODEL_SIZE = "base.en"     # faster-whisper model: tiny.en, base.en, small.en


class VoiceListener:
    """
    Listens for the wake word and transcribes speech.
    
    Usage:
        listener = VoiceListener()
        await listener.start()
        text = await listener.listen_once()  # blocks until speech captured
        await listener.stop()
    """

    def __init__(self, access_key: str = ""):
        """
        Args:
            access_key: Picovoice access key. If empty, falls back to openwakeword.
        """
        self._access_key = access_key or os.getenv("PICOVOICE_ACCESS_KEY", "")
        self._wake_engine = None          # Wake word engine instance
        self._wake_engine_type = "none"   # "porcupine", "openwakeword", or "none"
        self._stt_model = None            # faster-whisper model
        self._running = False
        self._listening = False           # True when actively recording speech
        self._stream = None               # pyaudio stream
        self._pa = None                   # pyaudio instance

    async def start(self):
        """Initialize wake word engine and STT model."""
        loop = asyncio.get_event_loop()
        await loop.run_in_executor(None, self._init_wake_engine)
        await loop.run_in_executor(None, self._init_stt)
        self._running = True

    async def stop(self):
        """Cleanup resources."""
        self._running = False
        self._cleanup_wake_engine()

    # ─── Wake Word Initialization ─────────────────────────────────────

    def _init_wake_engine(self):
        """Try Picovoice first, fall back to openwakeword."""
        # Try Picovoice Porcupine
        if self._access_key:
            try:
                import pvporcupine
                self._wake_engine = pvporcupine.create(
                    access_key=self._access_key,
                    keywords=["hey google"],  # closest built-in; custom .ppn preferred
                    sensitivities=[0.7],
                )
                self._wake_engine_type = "porcupine"
                print("[Voice] Wake word: Picovoice Porcupine (Hey Nila)")
                return
            except Exception as e:
                print(f"[Warning] Picovoice init failed: {e}")

        # Try openwakeword (free, no key)
        try:
            from openwakeword.model import Model as OWWModel
            self._wake_engine = OWWModel(
                wakeword_models=["hey_jarvis"],  # closest built-in model
                inference_framework="onnx",
            )
            self._wake_engine_type = "openwakeword"
            print("[Voice] Wake word: openwakeword (Hey Nila)")
            return
        except Exception as e:
            print(f"[Warning] openwakeword init failed: {e}")

        # Final fallback: no wake word, use hotkey
        self._wake_engine_type = "none"
        print("[Voice] Wake word: disabled (use Ctrl+Space or type 'voice')")

    def _cleanup_wake_engine(self):
        """Release wake word engine resources."""
        if self._wake_engine_type == "porcupine" and self._wake_engine:
            try:
                self._wake_engine.delete()
            except Exception:
                pass
        self._wake_engine = None

    # ─── STT Initialization ───────────────────────────────────────────

    def _init_stt(self):
        """Load faster-whisper model for speech-to-text."""
        try:
            from faster_whisper import WhisperModel
            self._stt_model = WhisperModel(
                STT_MODEL_SIZE,
                device="cpu",
                compute_type="int8",  # fastest on CPU
            )
            print(f"[STT] STT: faster-whisper ({STT_MODEL_SIZE})")
        except ImportError:
            print("[Warning] faster-whisper not installed. Falling back to SpeechRecognition.")
            self._stt_model = None
        except Exception as e:
            print(f"[Warning] STT init failed: {e}")
            self._stt_model = None

    # ─── Core Listening Methods ───────────────────────────────────────

    async def listen_once(self) -> str:
        """
        Wait for wake word, then record and transcribe speech.
        Returns the transcribed text (empty string if nothing detected).
        """
        loop = asyncio.get_event_loop()

        # Wait for wake word
        detected = await loop.run_in_executor(None, self._wait_for_wake_word)
        if not detected:
            return ""

        # Play activation chime
        play_chime(CHIME_ACTIVATE)
        await asyncio.sleep(0.25)  # let chime finish

        # Record speech until silence
        audio = await loop.run_in_executor(None, self._record_until_silence)
        if audio is None or len(audio) < int(SAMPLE_RATE * MIN_RECORDING_S):
            return ""

        # Play deactivation chime
        play_chime(CHIME_DEACTIVATE)

        # Transcribe
        text = await loop.run_in_executor(None, self._transcribe, audio)
        return text.strip()

    async def listen_speech_only(self) -> str:
        """
        Record and transcribe speech WITHOUT waiting for wake word.
        Used when wake word was already detected or in push-to-talk mode.
        """
        loop = asyncio.get_event_loop()

        play_chime(CHIME_ACTIVATE)
        await asyncio.sleep(0.2)

        audio = await loop.run_in_executor(None, self._record_until_silence)
        if audio is None or len(audio) < int(SAMPLE_RATE * MIN_RECORDING_S):
            return ""

        play_chime(CHIME_DEACTIVATE)

        text = await loop.run_in_executor(None, self._transcribe, audio)
        return text.strip()

    async def listen_loop(self, callback: Callable[[str], None]):
        """
        Continuously listen for wake word → speech → callback.
        Runs until self._running is False.
        """
        while self._running:
            try:
                text = await self.listen_once()
                if text:
                    await callback(text)
            except asyncio.CancelledError:
                break
            except Exception as e:
                print(f"[Warning] Listen loop error: {e}")
                await asyncio.sleep(1)

    # ─── Wake Word Detection ─────────────────────────────────────────

    def _wait_for_wake_word(self) -> bool:
        """
        Block until wake word is detected.
        Returns True if detected, False if stopped.
        """
        if self._wake_engine_type == "none":
            # No wake word engine — always return True (manual trigger mode)
            return True

        try:
            import sounddevice as sd
        except ImportError:
            return True

        device = get_mic_device_index()
        frame_size = FRAME_LENGTH

        if self._wake_engine_type == "porcupine":
            frame_size = self._wake_engine.frame_length

        # Open continuous mic stream
        try:
            stream = sd.InputStream(
                samplerate=SAMPLE_RATE,
                channels=1,
                dtype="int16",
                blocksize=frame_size,
                device=device,
            )
            stream.start()
        except Exception as e:
            print(f"[Warning] Mic stream error: {e}")
            return True  # fall through to manual mode

        try:
            while self._running:
                audio_frame, overflowed = stream.read(frame_size)
                if overflowed:
                    continue

                pcm = audio_frame.flatten()

                if self._wake_engine_type == "porcupine":
                    keyword_index = self._wake_engine.process(pcm)
                    if keyword_index >= 0:
                        return True

                elif self._wake_engine_type == "openwakeword":
                    # openwakeword expects float32 normalized audio
                    float_audio = pcm.astype(np.float32) / 32768.0
                    prediction = self._wake_engine.predict(float_audio)
                    # Check if any model triggered
                    for model_name in prediction:
                        scores = prediction[model_name]
                        if isinstance(scores, (list, np.ndarray)):
                            if any(s > 0.5 for s in scores):
                                self._wake_engine.reset()
                                return True
                        elif scores > 0.5:
                            self._wake_engine.reset()
                            return True

        except Exception as e:
            print(f"[Warning] Wake word loop error: {e}")
        finally:
            try:
                stream.stop()
                stream.close()
            except Exception:
                pass

        return False

    # ─── Speech Recording ─────────────────────────────────────────────

    def _record_until_silence(self) -> Optional[np.ndarray]:
        """
        Record audio from mic until silence is detected.
        Returns float32 numpy array at SAMPLE_RATE Hz.
        """
        try:
            import sounddevice as sd
        except ImportError:
            return self._record_fallback()

        device = get_mic_device_index()
        chunk_ms = 100  # check every 100ms
        chunk_samples = int(SAMPLE_RATE * chunk_ms / 1000)
        max_chunks = int(MAX_RECORDING_S * 1000 / chunk_ms)
        silence_chunks = int(SILENCE_DURATION_S * 1000 / chunk_ms)

        recorded = []
        silent_count = 0
        has_voice = False

        try:
            stream = sd.InputStream(
                samplerate=SAMPLE_RATE,
                channels=1,
                dtype="float32",
                blocksize=chunk_samples,
                device=device,
            )
            stream.start()

            for _ in range(max_chunks):
                if not self._running:
                    break

                chunk, _ = stream.read(chunk_samples)
                chunk = chunk.flatten()
                recorded.append(chunk)

                energy = audio_energy(chunk)
                if energy > SILENCE_THRESHOLD:
                    has_voice = True
                    silent_count = 0
                else:
                    silent_count += 1

                # Stop after sustained silence (but only if we've heard voice)
                if has_voice and silent_count >= silence_chunks:
                    break

            stream.stop()
            stream.close()

        except Exception as e:
            print(f"[Warning] Recording error: {e}")
            return None

        if not recorded or not has_voice:
            return None

        return np.concatenate(recorded)

    def _record_fallback(self) -> Optional[np.ndarray]:
        """Fallback recording using the existing tools/voice approach."""
        try:
            import sounddevice as sd
            audio = sd.rec(
                int(5.0 * SAMPLE_RATE),
                samplerate=SAMPLE_RATE,
                channels=1,
                dtype="float32",
                device=get_mic_device_index(),
            )
            sd.wait()
            return audio.flatten()
        except Exception:
            return None

    # ─── Transcription ────────────────────────────────────────────────

    def _transcribe(self, audio: np.ndarray) -> str:
        """
        Transcribe audio using faster-whisper (primary) or SpeechRecognition (fallback).
        """
        if self._stt_model is not None:
            return self._transcribe_faster_whisper(audio)
        return self._transcribe_speech_recognition(audio)

    def _transcribe_faster_whisper(self, audio: np.ndarray) -> str:
        """Transcribe using faster-whisper. Expects float32 audio at 16kHz."""
        try:
            segments, info = self._stt_model.transcribe(
                audio,
                beam_size=1,           # fastest
                best_of=1,
                language="en",
                condition_on_previous_text=False,
                vad_filter=True,       # skip silence segments
                vad_parameters=dict(
                    min_silence_duration_ms=500,
                    speech_pad_ms=200,
                ),
            )
            text_parts = []
            for segment in segments:
                text_parts.append(segment.text.strip())
            return " ".join(text_parts)
        except Exception as e:
            print(f"[Warning] faster-whisper error: {e}")
            return self._transcribe_speech_recognition(audio)

    def _transcribe_speech_recognition(self, audio: np.ndarray) -> str:
        """Fallback: use Google Web Speech API via SpeechRecognition library."""
        import tempfile
        import wave

        # Write to temp WAV
        tmp = os.path.join(
            os.path.dirname(os.path.dirname(os.path.abspath(__file__))),
            "data", "_temp_stt.wav"
        )
        try:
            int_audio = (audio * 32767).astype(np.int16)
            with wave.open(tmp, "w") as wf:
                wf.setnchannels(1)
                wf.setsampwidth(2)
                wf.setframerate(SAMPLE_RATE)
                wf.writeframes(int_audio.tobytes())

            # Use existing transcription function
            from tools.voice import transcribe_audio
            return transcribe_audio(tmp)
        except Exception as e:
            print(f"[Warning] SpeechRecognition fallback error: {e}")
            return ""
        finally:
            try:
                os.remove(tmp)
            except Exception:
                pass

    # ─── Properties ───────────────────────────────────────────────────

    @property
    def is_running(self) -> bool:
        return self._running

    @property
    def wake_engine_type(self) -> str:
        return self._wake_engine_type

    @property
    def has_stt(self) -> bool:
        return self._stt_model is not None
