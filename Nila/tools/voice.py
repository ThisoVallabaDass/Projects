"""
Nila Voice Engine — Handles Speech-to-Text and Text-to-Speech operations.

Uses edge-tts (Microsoft Neural TTS) for premium Indian female voice (Neerja)
and pygame for non-blocking audio playback. Falls back to pyttsx3 if offline.
"""

import threading
import queue
import re
import os
import wave
import time
import asyncio
import json
import sounddevice as sd
import speech_recognition as sr


# ─── Global Recording Device Selection ────────────────────────────────

_selected_device_index = None   # None = system default
VOICE_CONFIG_FILE = os.path.join(
    os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "data", "voice_config.json"
)


def load_voice_config() -> str | None:
    """Load the voice config and set _selected_device_index accordingly."""
    global _selected_device_index
    if os.path.exists(VOICE_CONFIG_FILE):
        try:
            with open(VOICE_CONFIG_FILE, "r") as f:
                config = json.load(f)
                device_name = config.get("mic_device_name")
                if device_name:
                    # Find index for device_name
                    devices = sd.query_devices()
                    for i, d in enumerate(devices):
                        if d["max_input_channels"] > 0:
                            short = d["name"].split(",")[0].strip()
                            if short == device_name:
                                _selected_device_index = i
                                return device_name
        except Exception as e:
            print(f"Error loading voice config: {e}")
    return None


def save_voice_config(device_name: str):
    """Save the microphone device name to voice_config.json."""
    os.makedirs(os.path.dirname(VOICE_CONFIG_FILE), exist_ok=True)
    try:
        with open(VOICE_CONFIG_FILE, "w") as f:
            json.dump({"mic_device_name": device_name}, f)
    except Exception as e:
        print(f"Error saving voice config: {e}")


# Run initial config load to restore saved mic device
load_voice_config()


def get_input_devices() -> list[tuple[int, str]]:
    """
    Return a list of (device_index, device_name) for all input-capable
    audio devices.  Filters to only MME devices (most reliable on Windows)
    and deduplicates by short name for a clean dropdown.
    """
    devices = sd.query_devices()
    hostapis = sd.query_hostapis()

    # Find MME hostapi index
    mme_idx = None
    for i, h in enumerate(hostapis):
        if "MME" in h.get("name", ""):
            mme_idx = i
            break

    result = []
    seen = set()
    for i, d in enumerate(devices):
        if d["max_input_channels"] > 0:
            # Only include MME devices if available (otherwise include all)
            if mme_idx is not None and d.get("hostapi") != mme_idx:
                continue
            name = d["name"]
            short = name.split(",")[0].strip()
            if short not in seen:
                seen.add(short)
                result.append((i, short))
    return result



def set_recording_device(device_index: int | None):
    """Set the device index used for sd.rec().  None = system default."""
    global _selected_device_index
    _selected_device_index = device_index
    if device_index is not None:
        try:
            devices = sd.query_devices()
            if device_index < len(devices):
                name = devices[device_index]["name"]
                short = name.split(",")[0].strip()
                save_voice_config(short)
        except Exception as e:
            print(f"Error saving mic device to config: {e}")
    else:
        save_voice_config("")


def get_recording_device() -> int | None:
    """Get the currently selected recording device index."""
    return _selected_device_index


# ─── Text Cleaning ────────────────────────────────────────────────────

def clean_text_for_speech(text: str) -> str:
    """Remove code blocks, markdown, emojis for smooth pronunciation."""
    # Remove code blocks
    text = re.sub(r'```[\s\S]*?```', '', text)
    # Remove inline code
    text = re.sub(r'`(.*?)`', r'\1', text)
    # Remove markdown bold/italics
    text = re.sub(r'\*\*(.*?)\*\*', r'\1', text)
    text = re.sub(r'\*(.*?)\*', r'\1', text)
    text = re.sub(r'_(.*?)_', r'\1', text)
    # Remove markdown links — keep the link text
    text = re.sub(r'\[(.*?)\]\(.*?\)', r'\1', text)
    # Remove HTML tags
    text = re.sub(r'<[^>]+>', '', text)
    # Remove markdown headers
    text = re.sub(r'^#+\s*', '', text, flags=re.MULTILINE)
    # Remove bullet markers
    text = re.sub(r'^\s*[-*•]\s+', '', text, flags=re.MULTILINE)
    # Remove emojis and symbols that sound robotic (keep Tamil/Unicode letters)
    text = re.sub(r'[^\w\s.,!?;:\'\"\-\u0B80-\u0BFF]', '', text)
    # Collapse whitespace
    text = re.sub(r'\s+', ' ', text)
    return text.strip()


# ─── Voice Manager (Background TTS) ──────────────────────────────────

class VoiceManager:
    """
    Background TTS using edge-tts (Indian female voice: Neerja Neural).
    Falls back to pyttsx3 (Zira) when offline.
    Uses pygame.mixer for non-blocking MP3 playback.
    """

    # Indian English female — warm, natural, accent-friendly
    EDGE_VOICE = "en-IN-NeerjaNeural"
    # Fallback alternative voices to try
    EDGE_FALLBACKS = ["en-IN-NeerjaExpressiveNeural", "en-IN-PrabhatNeural"]

    def __init__(self):
        self._speech_queue = queue.Queue()
        self._stop_flag = False
        self._thread = None
        self._mixer_ready = False
        self._temp_dir = ""

    def start(self, temp_dir: str = ""):
        """Start the background speech processing thread."""
        self._temp_dir = temp_dir or os.path.join(
            os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "data"
        )
        os.makedirs(self._temp_dir, exist_ok=True)

        # Initialize pygame mixer eagerly
        self._init_mixer()

        if not self._thread:
            self._thread = threading.Thread(target=self._loop, daemon=True)
            self._thread.start()

    def speak(self, text: str):
        """Enqueue text. Cancels any previous speech first."""
        self._stop_flag = True
        # Stop pygame playback immediately
        self._stop_playback()
        # Clear pending queue
        while not self._speech_queue.empty():
            try:
                self._speech_queue.get_nowait()
            except queue.Empty:
                break
        self._stop_flag = False
        self._speech_queue.put(text)

    def stop(self):
        """Immediately silence everything."""
        self._stop_flag = True
        self._stop_playback()

    def _stop_playback(self):
        """Stop pygame mixer if playing."""
        try:
            import pygame
            if pygame.mixer.get_init():
                pygame.mixer.music.stop()
                pygame.mixer.music.unload()
        except Exception:
            pass

    def _init_mixer(self):
        """Initialize pygame mixer once."""
        if self._mixer_ready:
            return
        try:
            import pygame
            pygame.mixer.init()
            self._mixer_ready = True
        except Exception:
            pass

    def _loop(self):
        """Main speech processing loop — runs in daemon thread."""
        self._init_mixer()

        while True:
            try:
                text = self._speech_queue.get(timeout=0.2)
                if self._stop_flag:
                    continue

                clean = clean_text_for_speech(text)
                if not clean or len(clean) < 3:
                    continue

                # Try edge-tts first (premium Indian voice)
                success = False
                if not self._stop_flag:
                    success = self._speak_edge(clean)

                # Fallback to pyttsx3 if edge-tts fails
                if not success and not self._stop_flag:
                    self._speak_pyttsx3(clean)

            except queue.Empty:
                continue
            except Exception as e:
                print(f"Voice loop error: {e}")

    def _speak_edge(self, text: str) -> bool:
        """Generate speech using edge-tts and play via pygame."""
        try:
            import edge_tts
            import pygame

            mp3_path = os.path.join(self._temp_dir, "nila_speech.mp3")

            # Generate speech async
            loop = asyncio.new_event_loop()
            try:
                communicate = edge_tts.Communicate(text, self.EDGE_VOICE)
                loop.run_until_complete(communicate.save(mp3_path))
            finally:
                loop.close()

            if self._stop_flag:
                return True

            # Play via pygame
            self._init_mixer()
            pygame.mixer.music.load(mp3_path)
            pygame.mixer.music.play()

            # Wait for playback to finish (poll so we can stop early)
            while pygame.mixer.music.get_busy():
                if self._stop_flag:
                    pygame.mixer.music.stop()
                    pygame.mixer.music.unload()
                    return True
                time.sleep(0.05)

            # Cleanup
            try:
                pygame.mixer.music.unload()
                os.remove(mp3_path)
            except Exception:
                pass

            return True

        except Exception as e:
            print(f"Edge-TTS error: {e}")
            return False

    def _speak_pyttsx3(self, text: str):
        """Offline fallback using Windows SAPI5 (Zira female voice)."""
        try:
            import pyttsx3
            engine = pyttsx3.init()
            engine.setProperty('rate', 175)
            engine.setProperty('volume', 1.0)

            # Select female voice
            voices = engine.getProperty('voices')
            for v in voices:
                if "zira" in v.name.lower():
                    engine.setProperty('voice', v.id)
                    break

            # Split into sentences so we can stop mid-speech
            sentences = re.split(r'(?<=[.!?])\s+', text)
            for sentence in sentences:
                if self._stop_flag:
                    break
                if sentence.strip():
                    engine.say(sentence)
                    engine.runAndWait()
        except Exception as e:
            print(f"pyttsx3 fallback error: {e}")


# ─── Singleton Instance ──────────────────────────────────────────────
voice_manager = VoiceManager()
voice_manager.start()


# ─── Recording & Transcription ───────────────────────────────────────

def transcribe_audio(filename: str) -> str:
    """Transcribe a WAV audio file using Google Web Speech API."""
    r = sr.Recognizer()
    try:
        with sr.AudioFile(filename) as source:
            audio_data = r.record(source)

        # Try Indian English first (handles Tamil-accented English well)
        try:
            return r.recognize_google(audio_data, language="en-IN").strip()
        except sr.UnknownValueError:
            pass

        # Try standard English
        try:
            return r.recognize_google(audio_data, language="en-US").strip()
        except sr.UnknownValueError:
            pass

        return ""
    except Exception as e:
        print(f"Transcription error: {e}")
        return ""
