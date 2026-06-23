"""
Audio Utilities — Shared helpers for the Nila voice pipeline.

Handles:
- Chime playback (non-blocking WAV via sounddevice)
- Mic stream configuration (reuses existing voice_config.json)
- Programmatic chime generation (sine waves, no external files needed)
"""

import os
import struct
import math
import wave
import threading
import numpy as np

# Paths
_DATA_DIR = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "data")
_CHIME_DIR = os.path.join(_DATA_DIR, "chimes")

CHIME_ACTIVATE = os.path.join(_CHIME_DIR, "chime_activate.wav")
CHIME_DEACTIVATE = os.path.join(_CHIME_DIR, "chime_deactivate.wav")
CHIME_ERROR = os.path.join(_CHIME_DIR, "chime_error.wav")

# Audio constants
SAMPLE_RATE = 16000
FRAME_LENGTH_MS = 30  # ms per audio frame for wake word
FRAME_LENGTH = int(SAMPLE_RATE * FRAME_LENGTH_MS / 1000)  # samples per frame


# ─── Chime Generation ────────────────────────────────────────────────

def _generate_tone(frequency: float, duration_ms: int, sample_rate: int = 44100,
                   amplitude: float = 0.3, fade_ms: int = 20) -> list[int]:
    """Generate a single sine wave tone with fade in/out."""
    num_samples = int(sample_rate * duration_ms / 1000)
    fade_samples = int(sample_rate * fade_ms / 1000)
    samples = []
    for i in range(num_samples):
        t = i / sample_rate
        value = amplitude * math.sin(2 * math.pi * frequency * t)
        # Apply fade in
        if i < fade_samples:
            value *= i / fade_samples
        # Apply fade out
        if i > num_samples - fade_samples:
            value *= (num_samples - i) / fade_samples
        samples.append(int(value * 32767))
    return samples


def _write_wav(filepath: str, samples: list[int], sample_rate: int = 44100):
    """Write samples to a 16-bit mono WAV file."""
    os.makedirs(os.path.dirname(filepath), exist_ok=True)
    with wave.open(filepath, "w") as wf:
        wf.setnchannels(1)
        wf.setsampwidth(2)  # 16-bit
        wf.setframerate(sample_rate)
        raw = struct.pack(f"<{len(samples)}h", *samples)
        wf.writeframes(raw)


def _generate_chime_activate():
    """Generate a soft ascending 2-note chime (A4 → E5)."""
    if os.path.exists(CHIME_ACTIVATE):
        return
    rate = 44100
    # Note 1: A4 (440Hz), 120ms
    tone1 = _generate_tone(440, 120, rate, amplitude=0.25)
    # Short gap: 30ms silence
    gap = [0] * int(rate * 0.03)
    # Note 2: E5 (659Hz), 150ms
    tone2 = _generate_tone(659, 150, rate, amplitude=0.3)
    _write_wav(CHIME_ACTIVATE, tone1 + gap + tone2, rate)


def _generate_chime_deactivate():
    """Generate a soft descending 2-note chime (E5 → A4)."""
    if os.path.exists(CHIME_DEACTIVATE):
        return
    rate = 44100
    tone1 = _generate_tone(659, 120, rate, amplitude=0.25)
    gap = [0] * int(rate * 0.03)
    tone2 = _generate_tone(440, 150, rate, amplitude=0.2)
    _write_wav(CHIME_DEACTIVATE, tone1 + gap + tone2, rate)


def _generate_chime_error():
    """Generate a short low buzz for errors."""
    if os.path.exists(CHIME_ERROR):
        return
    rate = 44100
    tone = _generate_tone(220, 200, rate, amplitude=0.2)
    _write_wav(CHIME_ERROR, tone, rate)


def ensure_chimes():
    """Generate all chime files if they don't exist."""
    _generate_chime_activate()
    _generate_chime_deactivate()
    _generate_chime_error()


# ─── Chime Playback ──────────────────────────────────────────────────

def play_chime(chime_path: str, blocking: bool = False):
    """
    Play a WAV chime file. Non-blocking by default.
    Uses sounddevice for reliable cross-platform playback.
    """
    if not os.path.exists(chime_path):
        ensure_chimes()
        if not os.path.exists(chime_path):
            return

    def _play():
        try:
            import sounddevice as sd
            import soundfile as sf
            data, samplerate = sf.read(chime_path, dtype="float32")
            sd.play(data, samplerate)
            sd.wait()
        except ImportError:
            # Fallback: try pygame
            try:
                import pygame
                if not pygame.mixer.get_init():
                    pygame.mixer.init()
                pygame.mixer.Sound(chime_path).play()
            except Exception:
                pass
        except Exception:
            pass

    if blocking:
        _play()
    else:
        threading.Thread(target=_play, daemon=True).start()


# ─── Microphone Helpers ──────────────────────────────────────────────

def get_mic_device_index() -> int | None:
    """
    Get the configured microphone device index.
    Reuses existing voice_config.json from tools/voice.py.
    Returns None for system default.
    """
    try:
        from tools.voice import get_recording_device
        return get_recording_device()
    except ImportError:
        pass

    # Manual fallback: read config directly
    import json
    config_path = os.path.join(_DATA_DIR, "voice_config.json")
    if os.path.exists(config_path):
        try:
            with open(config_path, "r") as f:
                config = json.load(f)
            device_name = config.get("mic_device_name")
            if device_name:
                import sounddevice as sd
                devices = sd.query_devices()
                for i, d in enumerate(devices):
                    if d["max_input_channels"] > 0:
                        short = d["name"].split(",")[0].strip()
                        if short == device_name:
                            return i
        except Exception:
            pass
    return None


def record_audio_chunk(duration_s: float = 5.0, sample_rate: int = 16000) -> np.ndarray:
    """
    Record a fixed-duration audio chunk from the microphone.
    Returns numpy array of float32 samples.
    """
    import sounddevice as sd
    device = get_mic_device_index()
    audio = sd.rec(
        int(duration_s * sample_rate),
        samplerate=sample_rate,
        channels=1,
        dtype="float32",
        device=device,
    )
    sd.wait()
    return audio.flatten()


def audio_energy(audio: np.ndarray) -> float:
    """Calculate RMS energy of audio. Used for silence/voice detection."""
    return float(np.sqrt(np.mean(audio ** 2)))


# ─── Initialize on import ────────────────────────────────────────────
ensure_chimes()
