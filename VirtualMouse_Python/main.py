# main.py
import threading
import time
import sys
from gesture.controller import GestureController
from voice.assistant import VoiceAssistant

class SharedState:
    def __init__(self):
        self.gesture_active = False
        self.voice_active = False
        self.running = True

if __name__ == "__main__":
    print("=========================================================")
    print("      Refined Virtual Mouse & Voice Assistant System")
    print("=========================================================")
    print("Select running mode:")
    print("1. Gesture Control Only (Computer Vision Mouse)")
    print("2. Voice Assistant Only")
    print("3. Coordinated Dual Mode (Both active with safe threading)")
    print("=========================================================")

    try:
        choice = input("Enter choice (1/2/3): ").strip()
    except (KeyboardInterrupt, EOFError):
        print("\nExiting...")
        sys.exit(0)

    if choice == "1":
        print("\nStarting Gesture Control...")
        controller = GestureController()
        controller.start()

    elif choice == "2":
        print("\nStarting Voice Assistant...")
        assistant = VoiceAssistant()
        try:
            assistant.start()
        except KeyboardInterrupt:
            print("\nShutting down Voice Assistant...")

    elif choice == "3":
        print("\nStarting Coordinated Dual Mode...")
        state = SharedState()
        assistant = VoiceAssistant(shared_state=state)
        
        # Start the Voice Assistant in a background daemon thread
        assistant_thread = threading.Thread(target=assistant.start, daemon=True)
        assistant_thread.start()
        
        # Give the voice engine a brief moment to initialize
        time.sleep(0.5)

        # Set initial state to start gesture controller immediately
        state.gesture_active = True
        
        print("\n[System] Coordinated Mode initialized.")
        print("[System] Say 'launch gesture' or 'stop gesture' to toggle camera control.")
        print("[System] Press Ctrl+C in this terminal to exit the application.\n")
        
        try:
            while state.running:
                if state.gesture_active:
                    # Run OpenCV GUI loop exclusively on the main thread
                    controller = GestureController()
                    controller.start(shared_state=state)
                else:
                    # Sleep to prevent high CPU utilization while waiting for commands
                    time.sleep(0.2)
        except KeyboardInterrupt:
            print("\n[System] Shutdown requested via console.")
        finally:
            state.running = False
            state.gesture_active = False
            print("[System] Stopping all services...")
            # Allow background thread to clean up speech engine
            time.sleep(0.5)
            print("[System] Application terminated safely.")

    else:
        print("Invalid choice. Exiting.")
