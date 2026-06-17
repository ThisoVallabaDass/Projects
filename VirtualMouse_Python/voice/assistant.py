# voice/assistant.py
import speech_recognition as sr
import pyttsx3
import webbrowser
import datetime
import pyautogui
import threading
from gesture.controller import GestureController

class VoiceAssistant:
    def __init__(self, shared_state=None):
        self.shared_state = shared_state
        self.engine = pyttsx3.init()
        voices = self.engine.getProperty("voices")
        if voices:
            self.engine.setProperty("voice", voices[0].id)
        self.recognizer = sr.Recognizer()
        self.running = True

    def speak(self, text):
        print(f"[Assistant]: {text}")
        # pyttsx3 might raise errors if engine is called concurrently, but voice assistant runs sequentially.
        try:
            self.engine.say(text)
            self.engine.runAndWait()
        except Exception as e:
            print(f"Text-to-speech error: {e}")

    def listen(self):
        try:
            with sr.Microphone() as source:
                print("Listening...")
                self.recognizer.adjust_for_ambient_noise(source, duration=0.5)
                # Set phrase_time_limit so that it periodically times out to check shutdown flags
                audio = self.recognizer.listen(source, timeout=3, phrase_time_limit=5)
        except sr.WaitTimeoutError:
            # Silence timeout, just returning to check flags in the loop
            return ""
        except Exception as e:
            print(f"Microphone error: {e}")
            time_to_wait = 2
            # Wait a bit if error to avoid infinite fast-failing loops
            import time
            time.sleep(time_to_wait)
            return ""

        try:
            query = self.recognizer.recognize_google(audio)
            print("You said:", query)
            return query.lower()
        except sr.UnknownValueError:
            return ""
        except sr.RequestError:
            self.speak("Speech recognition service connection error.")
            return ""

    def handle_command(self, command):
        if "open youtube" in command:
            self.speak("Opening YouTube")
            webbrowser.open("https://www.youtube.com")
        elif "open google" in command:
            self.speak("Opening Google")
            webbrowser.open("https://www.google.com")
        elif "what time" in command:
            now = datetime.datetime.now().strftime("%I:%M %p")
            self.speak(f"The time is {now}")
        elif "scroll down" in command:
            self.speak("Scrolling down")
            pyautogui.scroll(-300)
        elif "scroll up" in command:
            self.speak("Scrolling up")
            pyautogui.scroll(300)
        elif "double click" in command:
            self.speak("Double clicking")
            pyautogui.doubleClick()
        elif "right click" in command:
            self.speak("Right clicking")
            pyautogui.rightClick()
        elif "click" in command:
            self.speak("Clicking")
            pyautogui.click()
        elif command.startswith("type "):
            text_to_type = command[5:]
            self.speak(f"Typing text: {text_to_type}")
            pyautogui.write(text_to_type)
        elif "launch gesture" in command:
            if self.shared_state:
                if self.shared_state.gesture_active:
                    self.speak("Gesture control is already running.")
                else:
                    self.speak("Launching gesture control.")
                    self.shared_state.gesture_active = True
            else:
                self.speak("Starting gesture control in a separate window.")
                t = threading.Thread(target=GestureController().start)
                t.start()
        elif "stop gesture" in command or "close gesture" in command:
            if self.shared_state:
                if self.shared_state.gesture_active:
                    self.speak("Stopping gesture control.")
                    self.shared_state.gesture_active = False
                else:
                    self.speak("Gesture control is not currently running.")
            else:
                self.speak("Coordinated state inactive. Cannot stop gesture controller.")
        elif "exit" in command or "stop listening" in command or "shut down" in command:
            self.speak("Voice assistant shutting down. Goodbye.")
            self.running = False
            if self.shared_state:
                self.shared_state.running = False
        elif "help" in command or "commands" in command:
            self.speak("Available commands: open youtube, open google, what time, scroll up, scroll down, click, double click, right click, type [text], launch gesture, stop gesture, exit.")
        else:
            self.speak("I didn't catch that. Say help to hear the commands list.")

    def start(self):
        self.speak("Voice Assistant is now active.")
        if self.shared_state:
            self.shared_state.voice_active = True
        try:
            while self.running:
                if self.shared_state and not self.shared_state.running:
                    break
                command = self.listen()
                if command:
                    self.handle_command(command)
        finally:
            if self.shared_state:
                self.shared_state.voice_active = False
                if not self.running:
                    self.shared_state.running = False
            print("Voice Assistant Stopped.")
