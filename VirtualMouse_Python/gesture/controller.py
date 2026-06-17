# gesture/controller.py
import cv2
import mediapipe as mp
import pyautogui
import json
import os
import time

# Optimize PyAutoGUI responsiveness
pyautogui.PAUSE = 0
pyautogui.FAILSAFE = False

# Load config
CONFIG_PATH = os.path.join(os.path.dirname(__file__), '..', 'config.json')
try:
    with open(CONFIG_PATH, 'r') as f:
        CONFIG = json.load(f)
except Exception as e:
    print(f"Error loading config: {e}. Using default values.")
    CONFIG = {}

class GestureType:
    NONE = "none"
    FIST = "fist"
    PALM = "palm"
    INDEX = "index"
    V_SIGN = "v_sign"

class GestureController:
    def __init__(self):
        self.cap = None
        self.hands = mp.solutions.hands.Hands(
            max_num_hands=1,
            min_detection_confidence=0.7,
            min_tracking_confidence=0.7
        )
        self.draw = mp.solutions.drawing_utils
        self.prev_gesture = GestureType.NONE
        self.frame_count = 0
        self.gesture_hold_frames = 5
        self.prev_mouse = None
        self.current_gesture_name = ""
        self.prev_time = time.time()
        self.fps = 0
        self.mouse_is_down = False
        self.click_executed = False

    def detect_gesture(self, lm_list):
        if len(lm_list) < 21:
            return GestureType.NONE

        # Self-calibrating thumb detection based on hand orientation
        # Index MCP is landmark 5, Pinky MCP is landmark 17
        thumb_is_left = lm_list[5][0] < lm_list[17][0]
        if thumb_is_left:
            thumb_extended = lm_list[4][0] < lm_list[3][0]
        else:
            thumb_extended = lm_list[4][0] > lm_list[3][0]

        fingers = [thumb_extended]

        # Other 4 fingers (Index, Middle, Ring, Pinky)
        # tip_id: 8, 12, 16, 20
        # PIP joint: tip_id - 2 (6, 10, 14, 18)
        for tip_id in [8, 12, 16, 20]:
            fingers.append(lm_list[tip_id][1] < lm_list[tip_id - 2][1])

        if fingers == [False, False, False, False, False]:
            return GestureType.FIST
        elif fingers == [True, True, True, True, True]:
            return GestureType.PALM
        elif fingers == [False, True, False, False, False]:
            return GestureType.INDEX
        elif fingers == [False, True, True, False, False]:
            return GestureType.V_SIGN
        else:
            return GestureType.NONE

    def move_cursor(self, x, y):
        active_reg = CONFIG.get("active_region", {"x_min": 0.2, "x_max": 0.8, "y_min": 0.2, "y_max": 0.8})
        x_min = active_reg.get("x_min", 0.2)
        x_max = active_reg.get("x_max", 0.8)
        y_min = active_reg.get("y_min", 0.2)
        y_max = active_reg.get("y_max", 0.8)

        # Scale coordinate using active region
        norm_x = (x - x_min) / (x_max - x_min)
        norm_y = (y - y_min) / (y_max - y_min)

        # Clamp values between 0.0 and 1.0
        norm_x = max(0.0, min(1.0, norm_x))
        norm_y = max(0.0, min(1.0, norm_y))

        screen_w, screen_h = pyautogui.size()
        target_x = int(norm_x * screen_w)
        target_y = int(norm_y * screen_h)

        smoothing = CONFIG.get("cursor_smoothing", 5)

        if self.prev_mouse is None:
            self.prev_mouse = (float(target_x), float(target_y))

        # Exponential Moving Average using floats to avoid pixel truncation lock-ups
        smooth_x = self.prev_mouse[0] + (target_x - self.prev_mouse[0]) / smoothing
        smooth_y = self.prev_mouse[1] + (target_y - self.prev_mouse[1]) / smoothing

        pyautogui.moveTo(int(smooth_x), int(smooth_y))
        self.prev_mouse = (smooth_x, smooth_y)

    def handle_gesture(self, gesture):
        action = CONFIG.get("gesture_actions", {}).get(gesture, None)
        scroll_amt = CONFIG.get("scroll_amount", 300)

        if gesture == self.prev_gesture:
            self.frame_count += 1
        else:
            self.frame_count = 0
            self.prev_gesture = gesture
            self.click_executed = False  # Reset click lock on gesture change

        if self.frame_count < self.gesture_hold_frames:
            return

        self.current_gesture_name = gesture.upper()

        # Drag release fallback
        if self.mouse_is_down and action != "mouse_down":
            pyautogui.mouseUp()
            self.mouse_is_down = False
            print("[Gesture] Mouse released (drag end safety release)")

        if action == "mouse_down":
            if not self.mouse_is_down:
                pyautogui.mouseDown()
                self.mouse_is_down = True
                print("[Gesture] Mouse pressed (drag start)")
        elif action == "mouse_up":
            if self.mouse_is_down:
                pyautogui.mouseUp()
                self.mouse_is_down = False
                print("[Gesture] Mouse released")
        elif action == "click":
            if not self.click_executed:
                pyautogui.click()
                self.click_executed = True
                print("[Gesture] Single click executed")
        elif action == "scroll_down":
            pyautogui.scroll(-scroll_amt)
            self.frame_count = 0  # Throttle scroll speed
        elif action == "scroll_up":
            pyautogui.scroll(scroll_amt)
            self.frame_count = 0  # Throttle scroll speed

    def update_fps(self):
        curr_time = time.time()
        self.fps = 1 / (curr_time - self.prev_time)
        self.prev_time = curr_time

    def draw_hud(self, img):
        # Draw FPS
        cv2.putText(img, f"FPS: {int(self.fps)}", (10, 30),
                    cv2.FONT_HERSHEY_SIMPLEX, 0.9, (0, 255, 0), 2)

        # Draw current gesture
        if self.current_gesture_name:
            cv2.putText(img, f"Gesture: {self.current_gesture_name}", (10, 65),
                        cv2.FONT_HERSHEY_SIMPLEX, 0.8, (255, 255, 0), 2)

    def start(self, shared_state=None):
        self.cap = cv2.VideoCapture(0)
        if not self.cap.isOpened():
            print("Error: Could not open camera.")
            if shared_state:
                shared_state.gesture_active = False
            return

        print("Gesture Control Started. Press ESC to exit.")
        if shared_state:
            shared_state.gesture_active = True

        try:
            while self.cap.isOpened():
                if shared_state and (not shared_state.running or not shared_state.gesture_active):
                    break

                success, img = self.cap.read()
                if not success:
                    continue

                img = cv2.flip(img, 1)
                rgb_img = cv2.cvtColor(img, cv2.COLOR_BGR2RGB)
                result = self.hands.process(rgb_img)

                self.current_gesture_name = ""

                if result.multi_hand_landmarks:
                    for hand_landmarks in result.multi_hand_landmarks:
                        lm_list = []
                        for lm in hand_landmarks.landmark:
                            lm_list.append((lm.x, lm.y))

                        self.move_cursor(*lm_list[9])  # Palm center MCP
                        gesture = self.detect_gesture(lm_list)
                        self.handle_gesture(gesture)
                        self.draw.draw_landmarks(img, hand_landmarks, mp.solutions.hands.HAND_CONNECTIONS)
                else:
                    # Clear drag if hand leaves camera view
                    if self.mouse_is_down:
                        pyautogui.mouseUp()
                        self.mouse_is_down = False
                        print("[Gesture] Mouse released (hand lost safety release)")

                self.update_fps()
                self.draw_hud(img)

                cv2.imshow("Gesture Control", img)
                if cv2.waitKey(1) & 0xFF == 27:
                    break
        finally:
            self.cap.release()
            cv2.destroyAllWindows()
            if self.mouse_is_down:
                pyautogui.mouseUp()
            if shared_state:
                shared_state.gesture_active = False
            print("Gesture Control Stopped.")
