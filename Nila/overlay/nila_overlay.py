"""
Nila Desktop Overlay — Modern, animated, borderless HUD for Theo's OS.
Rewritten with full agent wiring, voice integration, and mic device selector.
"""

import tkinter as tk
from tkinter import ttk
import threading
import queue
import sys
import os
import re
import math
import traceback

# ─── Project Root Setup ──────────────────────────────────────────────
# This is THE critical fix — ensures terminal agent, file ops, system
# actions all work with correct working directory.
PROJECT_ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, PROJECT_ROOT)
os.chdir(PROJECT_ROOT)

# ─── Refined Dark-Space Design System ───────────────────────────────
C = {
    "bg":       "#050508",   # Extra deep void black
    "surface":  "#0a0a0f",   # Dark card surface for text
    "input_bg": "#0f0f18",   # Deep input background
    "border":   "#181825",   # Muted outline border
    "accent":   "#8b5cf6",   # Electric neon purple
    "text":     "#e8e8ed",   # Crisp ash white
    "text2":    "#5c5c70",   # Muted slate grey
    "error":    "#f43f5e",   # Red
    "green":    "#10b981",   # Success green
    "amber":    "#f59e0b",   # Amber
}


class NilaOverlay:
    def __init__(self):
        self.root = tk.Tk()
        self.response_queue = queue.Queue()
        self.agent = None
        self.agent_loading = True

        # Dimensions & Sizing
        self.W = 460
        self.H_collapsed = 80
        self.H_expanded = 420

        # Animation & Window States
        self.is_expanded = False
        self.is_minimized = False
        self._dragging_x = 0
        self._dragging_y = 0
        self._animating = False

        # Thinking State (Pulsing Ellipsis)
        self._thinking = False
        self._think_step = 0
        self._think_after_id = None

        # Text Fade-in State
        self._fade_after_id = None

        # Input History
        self.input_history = []
        self.input_hist_idx = -1

        # Voice Integration
        self.is_recording = False
        self.voice_active = True
        self._mic_pulse_id = None
        self._mic_pulse_step = 0
        self._wave_anim_id = None
        self._wave_step = 0

        # Determine platform
        self.is_win = (sys.platform == 'win32')

        # Start background agent loader
        threading.Thread(target=self._async_load_agent, daemon=True).start()

        self._build_ui()
        self._poll_responses()

        # Windows special chrome stripping
        if self.is_win:
            self.root.after(50, self._apply_win32_styling)

        # Setup system tray icon
        self._setup_tray()

    # ─── Agent Loading ────────────────────────────────────────────────
    def _async_load_agent(self):
        """Asynchronously load the Nila agent to prevent startup freeze."""
        try:
            from core.agent import NilaAgent
            self.agent = NilaAgent()

            # Verify terminal agent is loaded
            if not hasattr(self.agent, 'terminal'):
                from agents.terminal_agent import TerminalAgent
                self.agent.terminal = TerminalAgent()

            # Build provider status string
            status_parts = []
            if bool(os.getenv("GOOGLE_API_KEY")):
                status_parts.append("Gemini")
            if self.agent._groq and self.agent._groq.is_available():
                status_parts.append("Groq")
            if self.agent._openrouter and self.agent._openrouter.is_available():
                status_parts.append("OpenRouter")
            if self.agent.local and self.agent.local.is_available():
                status_parts.append("Local")

            self.agent_loading = False

            providers_str = " · ".join(status_parts) if status_parts else "offline"
            self.root.after(0, lambda: self._set_status_label(
                f"✦ ready ({providers_str})", C["green"]
            ))
        except Exception as e:
            self.agent_loading = False
            tb = traceback.format_exc()
            print(f"Agent load error:\n{tb}")
            self.response_queue.put((f"Failed to load agent: {e}", "_error"))
            self.root.after(0, lambda: self._set_status_label(
                f"✦ load failed: {str(e)[:30]}", C["error"]
            ))

    # ─── UI Construction ──────────────────────────────────────────────
    def _build_ui(self):
        """Construct the HUD window using pure Tkinter."""
        r = self.root
        r.title("Nila")
        r.protocol("WM_DELETE_WINDOW", self._minimize)

        # Set top-most and alpha opacity
        r.attributes("-topmost", True)
        r.attributes("-alpha", 0.98)
        r.configure(bg=C["accent"])  # Outside 1px highlight border

        if self.is_win:
            r.withdraw()
        else:
            r.overrideredirect(True)

        # Screen dimensions & position at bottom-right
        sw = r.winfo_screenwidth()
        sh = r.winfo_screenheight()
        x_pos = sw - self.W - 25
        y_pos = sh - self.H_collapsed - 65

        r.geometry(f"{self.W}x{self.H_collapsed}+{x_pos}+{y_pos}")
        r.resizable(False, False)

        # Main inner container
        self.main = tk.Frame(r, bg=C["bg"])
        self.main.pack(fill="both", expand=True, padx=1, pady=1)

        # 1. Header Area (30px)
        self.hdr = tk.Frame(self.main, bg=C["bg"], height=30)
        self.hdr.pack(side="top", fill="x")
        self.hdr.pack_propagate(False)

        # Bind header for dragging
        self.hdr.bind("<ButtonPress-1>", self._drag_start)
        self.hdr.bind("<B1-Motion>", self._drag_move)

        self.logo = tk.Label(
            self.hdr, text="✦ Nila", bg=C["bg"], fg=C["accent"],
            font=("Segoe UI", 10, "bold"), cursor="hand2"
        )
        self.logo.pack(side="left", padx=(14, 0))
        self.logo.bind("<ButtonPress-1>", self._drag_start)
        self.logo.bind("<B1-Motion>", self._drag_move)

        # Status label (shows providers)
        self.status_lbl = tk.Label(
            self.hdr, text="loading...", bg=C["bg"], fg=C["text2"],
            font=("Segoe UI", 8)
        )
        self.status_lbl.pack(side="left", padx=(8, 0))

        # Minimize and Close buttons
        self.close_btn = tk.Label(
            self.hdr, text="✕", bg=C["bg"], fg=C["text2"],
            font=("Segoe UI", 9), cursor="hand2", padx=10
        )
        self.close_btn.pack(side="right", fill="y")
        self.close_btn.bind("<Button-1>", lambda e: self._minimize())
        self.close_btn.bind("<Enter>", lambda e: self.close_btn.configure(fg=C["error"]))
        self.close_btn.bind("<Leave>", lambda e: self.close_btn.configure(fg=C["text2"]))

        self.min_btn = tk.Label(
            self.hdr, text="─", bg=C["bg"], fg=C["text2"],
            font=("Segoe UI", 9), cursor="hand2", padx=10
        )
        self.min_btn.pack(side="right", fill="y")
        self.min_btn.bind("<Button-1>", lambda e: self._minimize())
        self.min_btn.bind("<Enter>", lambda e: self.min_btn.configure(fg=C["text"]))
        self.min_btn.bind("<Leave>", lambda e: self.min_btn.configure(fg=C["text2"]))

        # 2. Text response frame (Expanded state only)
        self.resp_frame = tk.Frame(self.main, bg=C["surface"])

        self.sb = tk.Scrollbar(
            self.resp_frame, bg=C["surface"], troughcolor=C["surface"],
            activebackground=C["border"], width=3, relief="flat"
        )
        self.sb.pack(side="right", fill="y")

        self.resp = tk.Text(
            self.resp_frame, bg=C["surface"], fg=C["text"],
            font=("Segoe UI", 11), wrap="word", relief="flat",
            state="disabled", yscrollcommand=self.sb.set,
            padx=16, pady=16, cursor="arrow",
            spacing1=2, spacing3=4, selectbackground=C["border"],
            borderwidth=0, highlightthickness=0
        )
        self.resp.pack(side="left", fill="both", expand=True)
        self.sb.config(command=self.resp.yview)

        # Style tag configurations
        self.resp.tag_configure("body", foreground=C["text"], font=("Segoe UI", 11))
        self.resp.tag_configure("code", foreground="#a5b4fc", font=("Consolas", 10),
                                background="#0f0f1c", lmargin1=12, lmargin2=12,
                                rmargin=12, spacing1=4, spacing3=4)
        self.resp.tag_configure("thinking", foreground=C["accent"], font=("Segoe UI", 26, "bold"),
                                justify="center", spacing1=100)
        self.resp.tag_configure("error", foreground=C["error"], font=("Segoe UI", 11))
        self.resp.tag_configure("route", foreground=C["text2"], font=("Segoe UI", 9))

        # 3. Input wrapper at the bottom
        self.inp_wrapper = tk.Frame(self.main, bg=C["bg"], pady=6)
        self.inp_wrapper.pack(side="bottom", fill="x")

        # ── Voice waveform indicator (hidden by default) ──
        self.wave_bar_frame = tk.Frame(self.inp_wrapper, bg=C["bg"], height=24)
        # Will be packed above inp_row when recording

        self.wave_label = tk.Label(
            self.wave_bar_frame, text="🎙️ Listening...", bg=C["bg"],
            fg=C["error"], font=("Segoe UI", 9)
        )
        self.wave_label.pack(side="left", padx=(14, 8))

        self.wave_bars = []
        wave_container = tk.Frame(self.wave_bar_frame, bg=C["bg"])
        wave_container.pack(side="left", padx=4, pady=2)
        for i in range(7):
            bar = tk.Frame(wave_container, bg=C["error"], width=4, height=4)
            bar.pack(side="left", padx=1, pady=4)
            self.wave_bars.append(bar)

        self.wave_timer_lbl = tk.Label(
            self.wave_bar_frame, text="7s", bg=C["bg"],
            fg=C["text2"], font=("Segoe UI", 9)
        )
        self.wave_timer_lbl.pack(side="right", padx=(0, 14))

        # ── Mic device selector (hidden by default) ──
        self.mic_selector_frame = tk.Frame(self.inp_wrapper, bg=C["bg"])
        # Will be packed when user clicks settings

        self.mic_device_var = tk.StringVar(value="Default Microphone")
        self._mic_devices = []  # list of (index, name)
        self._refresh_mic_devices()
        try:
            from tools.voice import get_recording_device
            current_idx = get_recording_device()
            if current_idx is not None:
                for idx, name in self._mic_devices:
                    if idx == current_idx:
                        self.mic_device_var.set(name)
                        break
        except Exception:
            pass

        mic_lbl = tk.Label(
            self.mic_selector_frame, text="🎤 Mic:", bg=C["bg"], fg=C["text2"],
            font=("Segoe UI", 9)
        )
        mic_lbl.pack(side="left", padx=(14, 4))

        self.mic_dropdown = ttk.Combobox(
            self.mic_selector_frame,
            textvariable=self.mic_device_var,
            values=[d[1] for d in self._mic_devices],
            state="readonly",
            width=35,
            font=("Segoe UI", 9)
        )
        self.mic_dropdown.pack(side="left", padx=4)
        self.mic_dropdown.bind("<<ComboboxSelected>>", self._on_mic_device_change)

        # Style the combobox for dark theme
        style = ttk.Style()
        style.theme_use('clam')
        style.configure("TCombobox",
                         fieldbackground=C["input_bg"],
                         background=C["border"],
                         foreground=C["text"],
                         selectbackground=C["accent"],
                         selectforeground="white",
                         arrowcolor=C["text2"])

        # ── Model selector row ──
        self.model_row = tk.Frame(self.inp_wrapper, bg=C["bg"])
        # Packed on demand (right-click menu or settings toggle)

        model_lbl = tk.Label(
            self.model_row, text="⚡ Model:", bg=C["bg"], fg=C["text2"],
            font=("Segoe UI", 9)
        )
        model_lbl.pack(side="left", padx=(14, 4))

        self.model_var = tk.StringVar(value="auto")
        self.model_dropdown = ttk.Combobox(
            self.model_row,
            textvariable=self.model_var,
            values=["auto", "gemini", "groq", "openrouter", "ollama"],
            state="readonly",
            width=18,
            font=("Segoe UI", 9)
        )
        self.model_dropdown.pack(side="left", padx=4)
        self.model_dropdown.bind("<<ComboboxSelected>>", self._on_model_change)

        # Route label (shows which model handled last response)
        self.route_lbl = tk.Label(
            self.model_row, text="", bg=C["bg"], fg=C["text2"],
            font=("Segoe UI", 8)
        )
        self.route_lbl.pack(side="right", padx=(0, 14))

        # ── Input row ──
        self.inp_row = tk.Frame(
            self.inp_wrapper, bg=C["input_bg"],
            highlightbackground=C["border"], highlightthickness=1
        )
        self.inp_row.pack(fill="x", padx=12)

        # Mic button
        self.mic_btn = tk.Label(
            self.inp_row, text="🎙️", bg=C["input_bg"], fg=C["text2"],
            font=("Segoe UI", 12), cursor="hand2", padx=4
        )
        self.mic_btn.pack(side="left", fill="y")
        self.mic_btn.bind("<Button-1>", self._toggle_voice_record)
        self.mic_btn.bind("<Enter>", lambda e: self.mic_btn.configure(
            fg=C["accent"] if not self.is_recording else C["error"]
        ))
        self.mic_btn.bind("<Leave>", lambda e: self.mic_btn.configure(
            fg=C["error"] if self.is_recording else C["text2"]
        ))

        # Mic dropdown arrow
        self.mic_arrow_btn = tk.Label(
            self.inp_row, text="▾", bg=C["input_bg"], fg=C["text2"],
            font=("Segoe UI", 9), cursor="hand2", padx=2
        )
        self.mic_arrow_btn.pack(side="left", fill="y")
        self.mic_arrow_btn.bind("<Button-1>", lambda e: self._toggle_mic_selector())
        self.mic_arrow_btn.bind("<Enter>", lambda e: self.mic_arrow_btn.configure(fg=C["accent"]))
        self.mic_arrow_btn.bind("<Leave>", lambda e: self.mic_arrow_btn.configure(fg=C["text2"]))

        # Speaker button
        self.speaker_btn = tk.Label(
            self.inp_row, text="🔊", bg=C["input_bg"], fg=C["accent"],
            font=("Segoe UI", 11), cursor="hand2", padx=8
        )
        self.speaker_btn.pack(side="left", fill="y")
        self.speaker_btn.bind("<Button-1>", self._toggle_speaker)
        self.speaker_btn.bind("<Enter>", lambda e: self.speaker_btn.configure(fg=C["accent"]))
        self.speaker_btn.bind("<Leave>", lambda e: self.speaker_btn.configure(
            fg=C["accent"] if self.voice_active else C["text2"]
        ))

        # Text input
        self.inp_var = tk.StringVar()
        self.inp = tk.Entry(
            self.inp_row, textvariable=self.inp_var,
            bg=C["input_bg"], fg=C["text"],
            insertbackground=C["accent"],
            font=("Segoe UI", 11), relief="flat", bd=0
        )
        self.inp.pack(side="left", fill="x", expand=True, ipady=7, padx=(5, 0))

        self._placeholder_active = True
        self._apply_placeholder()

        # Bind focus and entry events
        self.inp.bind("<FocusIn>", self._focus_in_entry)
        self.inp.bind("<FocusOut>", self._focus_out_entry)
        self.inp.bind("<Return>", self._send_command)
        self.inp.bind("<Escape>", self._handle_escape)
        self.inp.bind("<Up>", self._history_up)
        self.inp.bind("<Down>", self._history_down)

        # Send button
        self.send_btn = tk.Label(
            self.inp_row, text="↑", bg=C["accent"], fg="white",
            font=("Segoe UI", 11, "bold"), padx=12, cursor="hand2"
        )
        self.send_btn.pack(side="right", fill="y")
        self.send_btn.bind("<Button-1>", self._send_command)
        self.send_btn.bind("<Enter>", lambda e: self.send_btn.configure(bg="#7c3aed"))
        self.send_btn.bind("<Leave>", lambda e: self.send_btn.configure(bg=C["accent"]))

        # Click to focus redirects
        self.resp.bind("<Button-1>", lambda e: self.inp.focus_set())
        self.main.bind("<Button-1>", lambda e: self.inp.focus_set())
        self.hdr.bind("<Button-1>", lambda e: self.inp.focus_set(), add="+")

        # Initial focus trigger
        r.after(300, self.inp.focus_set)

        # Right-click context menu
        self.popup_menu = tk.Menu(self.root, tearoff=0, bg=C["surface"], fg=C["text"],
                                  activebackground=C["accent"], activeforeground="white", bd=1)
        self.popup_menu.add_command(label="Clear HUD", command=self._clear_input_and_results)
        self.popup_menu.add_command(label="Restart Nila", command=self._perform_restart)
        self.popup_menu.add_separator()
        self.popup_menu.add_command(label="🎤 Select Mic Device", command=self._toggle_mic_selector)
        self.popup_menu.add_command(label="⚡ Switch Model", command=self._toggle_model_selector)
        self.popup_menu.add_separator()
        self.popup_menu.add_command(label="Minimize", command=self._minimize)
        self.popup_menu.add_command(label="Exit", command=self._exit_from_tray)

        # Bind right-click
        self.root.bind("<Button-3>", self._show_popup_menu)
        self.main.bind("<Button-3>", self._show_popup_menu)
        self.hdr.bind("<Button-3>", self._show_popup_menu)
        self.logo.bind("<Button-3>", self._show_popup_menu)
        self.resp.bind("<Button-3>", self._show_popup_menu)

        # State for settings panels
        self._mic_selector_visible = False
        self._model_selector_visible = False

    # ─── Status Label ─────────────────────────────────────────────────
    def _set_status_label(self, text: str, color: str = C["text2"]):
        self.status_lbl.configure(text=text, fg=color)

    # ─── Placeholder ──────────────────────────────────────────────────
    def _apply_placeholder(self):
        self.inp_var.set("Ask Nila anything...")
        self.inp.configure(fg=C["text2"])
        self._placeholder_active = True

    def _clear_placeholder(self):
        if self._placeholder_active:
            self.inp_var.set("")
            self.inp.configure(fg=C["text"])
            self._placeholder_active = False

    def _focus_in_entry(self, e=None):
        self._clear_placeholder()
        self.inp_row.configure(highlightbackground=C["accent"])

    def _focus_out_entry(self, e=None):
        if not self.inp_var.get().strip():
            self._apply_placeholder()
        self.inp_row.configure(highlightbackground=C["border"])

    # ─── Animation Height Engine ──────────────────────────────────────
    def _animate_height(self, target_h, steps=10, current_step=0, start_h=None):
        """Linearly expand or collapse overlay height upward."""
        if current_step == 0:
            self._animating = True
            start_h = self.root.winfo_height()
            if target_h == self.H_expanded:
                self.resp_frame.pack(side="top", fill="both", expand=True)

        t = current_step / steps
        t = t * t * (3 - 2 * t)  # smoothstep

        h = int(start_h + (target_h - start_h) * t)

        sw = self.root.winfo_screenwidth()
        sh = self.root.winfo_screenheight()
        x = sw - self.W - 25
        y = sh - h - 65

        self.root.geometry(f"{self.W}x{h}+{x}+{y}")

        if current_step < steps:
            self.root.after(10, lambda: self._animate_height(target_h, steps, current_step + 1, start_h))
        else:
            self.root.geometry(f"{self.W}x{target_h}+{x}+{y}")
            self._animating = False
            self.is_expanded = (target_h == self.H_expanded)
            if not self.is_expanded:
                self.resp_frame.pack_forget()
            self.inp.focus_set()

    def _expand(self):
        if self.is_expanded or self._animating:
            return
        self._animate_height(self.H_expanded)

    def _collapse(self):
        if not self.is_expanded or self._animating:
            return
        self._animate_height(self.H_collapsed)

    # ─── Escape Key & Clears ──────────────────────────────────────────
    def _handle_escape(self, event=None):
        if self.is_expanded:
            self._clear_input_and_results()
        else:
            self._minimize()

    def _clear_input_and_results(self):
        self._stop_thinking()
        self._stop_fade_in()
        self._stop_wave_anim()
        try:
            from tools.voice import voice_manager
            voice_manager.stop()
        except Exception:
            pass

        self.resp.configure(state="normal")
        self.resp.delete("1.0", "end")
        self.resp.configure(state="disabled")

        self.inp_var.set("")
        self._apply_placeholder()
        self._collapse()

    # ─── Response Color Fade-in Rendering ─────────────────────────────
    def _display_response(self, text: str, tag: str = "body", route: str = ""):
        """Displays text with code formatting and fades the color in."""
        self._stop_fade_in()
        self._expand()

        self.resp.configure(state="normal")
        self.resp.delete("1.0", "end")

        if tag in ("error", "thinking"):
            self.resp.insert("end", text, tag)
        else:
            # Highlight code blocks
            chunks = re.split(r"(```[\s\S]*?```)", text)
            for chunk in chunks:
                if chunk.startswith("```") and chunk.endswith("```"):
                    code_body = chunk[3:-3]
                    if code_body and '\n' in code_body:
                        first_line, rest = code_body.split('\n', 1)
                        if first_line.strip().isalpha():
                            code_body = rest
                    if not code_body.startswith('\n'):
                        code_body = '\n' + code_body
                    if not code_body.endswith('\n'):
                        code_body += '\n'
                    self.resp.insert("end", code_body, "code")
                else:
                    if chunk:
                        self.resp.insert("end", chunk, "body")

            # Append route label
            if route:
                route_text = self._format_route(route)
                self.resp.insert("end", f"\n\n{route_text}", "route")

        self.resp.configure(state="disabled")
        self.resp.see("1.0")

        # Trigger color interpolation animation
        fade_tags = [tag] if tag == "error" else ["body", "code"]
        self._start_fade_in(fade_tags)

    def _format_route(self, route: str) -> str:
        """Format route label for display."""
        icons = {
            "INSTANT_LOCAL": "⚡ local (instant)",
            "ONLINE_GEMINI": "📡 gemini",
            "ONLINE_GROQ": "⚡ groq",
            "ONLINE_OPENROUTER": "🌐 openrouter",
            "OFFLINE_LOCAL_LLM": "🖥️ local",
            "SYSTEM_ACTION": "⚙️ system",
            "TERMINAL_ACTION": "🖥️ terminal",
            "DATA_QUERY": "📊 data",
            "AGENT_MODE": "🤖 agent",
            "SYSTEM": "⚙️ system",
        }
        return icons.get(route, f"💬 {route.lower()}")

    def _start_fade_in(self, tags):
        self._stop_fade_in()
        targets = {
            "body": C["text"],
            "code": "#a5b4fc",
            "error": C["error"]
        }
        for t in tags:
            if t in targets:
                self.resp.tag_configure(t, foreground=C["bg"])

        steps = 15

        def run_step(step=0):
            if step > steps:
                for t in tags:
                    if t in targets:
                        self.resp.tag_configure(t, foreground=targets[t])
                self._fade_after_id = None
                return
            factor = step / steps
            factor = factor * factor * (3 - 2 * factor)
            for t in tags:
                if t in targets:
                    interp = self._color_interpolate(C["bg"], targets[t], factor)
                    self.resp.tag_configure(t, foreground=interp)
            self._fade_after_id = self.root.after(15, lambda: run_step(step + 1))

        run_step(0)

    def _stop_fade_in(self):
        if self._fade_after_id:
            self.root.after_cancel(self._fade_after_id)
            self._fade_after_id = None

    def _color_interpolate(self, c1: str, c2: str, t: float) -> str:
        try:
            r1, g1, b1 = int(c1[1:3], 16), int(c1[3:5], 16), int(c1[5:7], 16)
            r2, g2, b2 = int(c2[1:3], 16), int(c2[3:5], 16), int(c2[5:7], 16)
            r = int(r1 + (r2 - r1) * t)
            g = int(g1 + (g2 - g1) * t)
            b = int(b1 + (b2 - b1) * t)
            return f"#{r:02x}{g:02x}{b:02x}"
        except Exception:
            return c2

    # ─── Pulsing Thinking Ellipsis Animation ──────────────────────────
    def _start_thinking(self):
        self._thinking = True
        self._think_step = 0
        self._animate_thinking()

    def _animate_thinking(self):
        if not self._thinking:
            return
        self._expand()
        if self._think_step == 0:
            self.resp.configure(state="normal")
            self.resp.delete("1.0", "end")
            self.resp.insert("end", "⋯\n", "thinking")
            self.resp.configure(state="disabled")
        val = (math.sin(self._think_step * 0.15) + 1.0) / 2.0
        color = self._color_interpolate(C["border"], C["accent"], val)
        self.resp.tag_configure("thinking", foreground=color)
        self._think_step += 1
        self._think_after_id = self.root.after(40, self._animate_thinking)

    def _stop_thinking(self):
        self._thinking = False
        if self._think_after_id:
            self.root.after_cancel(self._think_after_id)
            self._think_after_id = None

    # ─── Command Processing Pipeline ──────────────────────────────────
    def _send_command(self, event=None):
        if self._placeholder_active:
            return
        text = self.inp_var.get().strip()
        if not text:
            return

        # Clean input bar and push to history
        self.inp_var.set("")
        self.input_history.append(text)
        self.input_hist_idx = -1

        # Shortcut commands
        if text.lower() in ("clear", "reset", "cls"):
            self._clear_input_and_results()
            return

        # Show animated loader
        self._start_thinking()

        # Process in separate background thread
        threading.Thread(target=self._process_in_thread, args=(text,), daemon=True).start()

    def _process_in_thread(self, query):
        try:
            if self.agent_loading or not self.agent:
                self.response_queue.put(
                    ("Nila is still loading. Please wait...", "_error")
                )
                return

            # Call agent — returns (response_text, route_label)
            result = self.agent.chat(query)

            # Handle both tuple and string returns safely
            if isinstance(result, tuple) and len(result) == 2:
                resp, label = result
            else:
                resp, label = str(result), "Nila"

            self.response_queue.put((str(resp), str(label)))

        except Exception as e:
            tb = traceback.format_exc()
            print(f"Process error:\n{tb}")
            self.response_queue.put((f"Error: {str(e)}", "_error"))

    def _poll_responses(self):
        try:
            while not self.response_queue.empty():
                resp, label = self.response_queue.get_nowait()
                self._stop_thinking()
                if label == "_error":
                    self._display_response(resp, tag="error")
                else:
                    self._display_response(resp, route=label)
                    if self.voice_active:
                        try:
                            from tools.voice import voice_manager
                            voice_manager.speak(resp)
                        except Exception:
                            pass
        except Exception:
            pass
        self.root.after(80, self._poll_responses)

    # ─── Command Entry History (Up/Down) ──────────────────────────────
    def _history_up(self, e):
        if not self.input_history:
            return
        self._clear_placeholder()
        self.input_hist_idx = min(self.input_hist_idx + 1, len(self.input_history) - 1)
        self.inp_var.set(self.input_history[-(self.input_hist_idx + 1)])

    def _history_down(self, e):
        self._clear_placeholder()
        if self.input_hist_idx > 0:
            self.input_hist_idx -= 1
            self.inp_var.set(self.input_history[-(self.input_hist_idx + 1)])
        else:
            self.input_hist_idx = -1
            self.inp_var.set("")

    # ─── Windows Ctypes Focus Hack ────────────────────────────────────
    def _apply_win32_styling(self):
        try:
            from ctypes import windll
            GWL_STYLE = -16
            WS_CAPTION = 0x00C00000
            WS_SYSMENU = 0x00080000
            WS_THICKFRAME = 0x00040000

            hwnd = int(self.root.wm_frame(), 16)
            style = windll.user32.GetWindowLongW(hwnd, GWL_STYLE)
            style &= ~WS_CAPTION
            style &= ~WS_SYSMENU
            style &= ~WS_THICKFRAME

            windll.user32.SetWindowLongW(hwnd, GWL_STYLE, style)
            windll.user32.SetWindowPos(hwnd, 0, 0, 0, 0, 0, 0x0027)

            self.root.deiconify()
            self.root.lift()
            self.root.focus_force()
            self.inp.focus_set()
        except Exception:
            self.root.overrideredirect(True)
            self.root.deiconify()
            self.root.lift()
            self.root.focus_force()
            self.inp.focus_set()

    # ─── Window Operations ───────────────────────────────────────────
    def _minimize(self):
        if self.is_minimized:
            self.is_minimized = False
            self.root.deiconify()
            self.root.lift()
            self.root.focus_force()
            self.inp.focus_set()
        else:
            self.is_minimized = True
            self.root.withdraw()

    def _close(self):
        self._minimize()

    def _setup_tray(self):
        try:
            import pystray
            from PIL import Image

            logo_path = os.path.join(PROJECT_ROOT, "Assets", "Logo_bg.png")
            if os.path.exists(logo_path):
                image = Image.open(logo_path)
            else:
                image = Image.new("RGB", (64, 64), color="#8b5cf6")

            menu = pystray.Menu(
                pystray.MenuItem("Open Nila", self._show_from_tray, default=True),
                pystray.MenuItem("Clear HUD", self._clear_from_tray),
                pystray.MenuItem("Restart Nila", self._restart_from_tray),
                pystray.MenuItem("Exit", self._exit_from_tray)
            )

            self.tray_icon = pystray.Icon(
                "Nila",
                image,
                "✦ Nila AI Assistant",
                menu=menu
            )

            threading.Thread(target=self.tray_icon.run, daemon=True).start()
        except Exception as e:
            print(f"Failed to load system tray icon: {e}")

    def _show_from_tray(self, icon=None, item=None):
        self.root.after(0, self._deiconify_and_focus)

    def _clear_from_tray(self, icon=None, item=None):
        self.root.after(0, self._clear_input_and_results)

    def _exit_from_tray(self, icon=None, item=None):
        try:
            self.tray_icon.stop()
        except Exception:
            pass
        self.root.after(0, self._close_and_destroy)

    def _restart_from_tray(self, icon=None, item=None):
        self.root.after(0, self._perform_restart)

    def _show_popup_menu(self, event):
        self.popup_menu.post(event.x_root, event.y_root)

    # ─── Speaker Toggle ──────────────────────────────────────────────
    def _toggle_speaker(self, event=None):
        self.voice_active = not self.voice_active
        if self.voice_active:
            self.speaker_btn.configure(text="🔊", fg=C["accent"])
        else:
            self.speaker_btn.configure(text="🔇", fg=C["text2"])
            try:
                from tools.voice import voice_manager
                voice_manager.stop()
            except Exception:
                pass

    # ─── Mic Pulse Animation ─────────────────────────────────────────
    def _start_mic_pulse(self):
        self._mic_pulse_step = 0
        self._animate_mic_pulse()

    def _animate_mic_pulse(self):
        if not self.is_recording:
            self.mic_btn.configure(fg=C["text2"])
            self._mic_pulse_id = None
            return
        val = (math.sin(self._mic_pulse_step * 0.2) + 1.0) / 2.0
        color = self._color_interpolate("#5c1a1a", C["error"], val)
        self.mic_btn.configure(fg=color)
        self._mic_pulse_step += 1
        self._mic_pulse_id = self.root.after(50, self._animate_mic_pulse)

    def _stop_mic_pulse(self):
        if self._mic_pulse_id:
            self.root.after_cancel(self._mic_pulse_id)
            self._mic_pulse_id = None
        self.mic_btn.configure(fg=C["text2"])

    # ─── Waveform Bar Animation ──────────────────────────────────────
    def _start_wave_anim(self):
        self._wave_step = 0
        self.wave_bar_frame.pack(fill="x", padx=0, pady=(0, 4), before=self.inp_row)
        self._animate_wave()

    def _animate_wave(self):
        if not self.is_recording:
            self._stop_wave_anim()
            return
        heights = [4, 10, 18, 14, 8, 12, 20, 6, 16, 10, 4, 14, 8]
        for i, bar in enumerate(self.wave_bars):
            h = heights[(self._wave_step + i * 2) % len(heights)]
            bar.configure(height=max(3, h))
        self._wave_step += 1
        self._wave_anim_id = self.root.after(100, self._animate_wave)

    def _stop_wave_anim(self):
        if self._wave_anim_id:
            self.root.after_cancel(self._wave_anim_id)
            self._wave_anim_id = None
        self.wave_bar_frame.pack_forget()
        for bar in self.wave_bars:
            bar.configure(height=4)

    # ─── Mic Device Selection ────────────────────────────────────────
    def _refresh_mic_devices(self):
        """Populate mic device list from sounddevice."""
        try:
            from tools.voice import get_input_devices
            self._mic_devices = get_input_devices()
            if not self._mic_devices:
                self._mic_devices = [(None, "Default Microphone")]
        except Exception:
            self._mic_devices = [(None, "Default Microphone")]

    def _on_mic_device_change(self, event=None):
        """User selected a mic device from dropdown."""
        selected_name = self.mic_device_var.get()
        for idx, name in self._mic_devices:
            if name == selected_name:
                try:
                    from tools.voice import set_recording_device
                    set_recording_device(idx)
                    # If we were prompting to select a mic, guide them to click the mic button
                    if self.inp_var.get() == "Select mic above, then click 🎙️ to record.":
                        self.inp_var.set("Click 🎙️ to start recording!")
                except Exception:
                    pass
                break

    def _toggle_mic_selector(self):
        """Toggle mic device selector visibility."""
        if self._mic_selector_visible:
            self.mic_selector_frame.pack_forget()
            self._mic_selector_visible = False
        else:
            self._refresh_mic_devices()
            self.mic_dropdown.configure(values=[d[1] for d in self._mic_devices])
            self.mic_selector_frame.pack(fill="x", padx=12, pady=(0, 4), before=self.inp_row)
            self._mic_selector_visible = True
            self._expand()

    # ─── Model Selection ─────────────────────────────────────────────
    def _on_model_change(self, event=None):
        """User selected a model from dropdown."""
        m = self.model_var.get()
        if self.agent:
            self.agent.force_model = None if m == "auto" else m
        icons = {"auto": "🔄", "gemini": "📡", "groq": "⚡",
                 "openrouter": "🌐", "ollama": "🖥️"}
        self._set_status_label(f"{icons.get(m, '')} {m}", C["accent"])

    def _toggle_model_selector(self):
        """Toggle model selector visibility."""
        if self._model_selector_visible:
            self.model_row.pack_forget()
            self._model_selector_visible = False
        else:
            # Sync current force_model to dropdown
            if self.agent and self.agent.force_model:
                self.model_var.set(self.agent.force_model)
            else:
                self.model_var.set("auto")
            self.model_row.pack(fill="x", padx=12, pady=(0, 4), before=self.inp_row)
            self._model_selector_visible = True
            self._expand()

    # ─── Voice Recording ─────────────────────────────────────────────
    def _toggle_voice_record(self, event=None):
        if self.is_recording:
            # Stop recording early
            import sounddevice as sd
            sd.stop()
            self.is_recording = False
            self._stop_mic_pulse()
            self._stop_wave_anim()
        else:
            # Check if user has selected a recording device yet
            from tools.voice import get_recording_device
            if get_recording_device() is None:
                # Prompt the user to select the device first!
                if not self._mic_selector_visible:
                    self._toggle_mic_selector()
                self._clear_placeholder()
                self.inp_var.set("Select mic above, then click 🎙️ to record.")
                self.inp.configure(fg=C["accent"])
                return

            # Stop any current speech before recording
            try:
                from tools.voice import voice_manager
                voice_manager.stop()
            except Exception:
                pass
            self.is_recording = True
            self._clear_placeholder()
            self.inp.configure(state="disabled")
            self.inp_var.set("🎙️ Listening...")
            self._start_mic_pulse()
            self._start_wave_anim()
            threading.Thread(target=self._async_record_and_transcribe, daemon=True).start()

    def _async_record_and_transcribe(self):
        import time
        from tools.voice import transcribe_audio, get_recording_device
        import sounddevice as sd
        import wave

        temp_wav = os.path.join(PROJECT_ROOT, "data", "temp_voice.wav")
        os.makedirs(os.path.dirname(temp_wav), exist_ok=True)

        fs = 16000
        duration = 7

        # Use selected device or system default
        device = get_recording_device()

        try:
            myrecording = sd.rec(
                int(duration * fs), samplerate=fs, channels=1,
                dtype='int16', device=device
            )
        except Exception as e:
            print(f"Recording error with device {device}: {e}")
            # Fallback to default device
            myrecording = sd.rec(
                int(duration * fs), samplerate=fs, channels=1, dtype='int16'
            )

        # Poll to allow early stopping
        start_time = time.time()
        while self.is_recording and (time.time() - start_time) < duration:
            elapsed = time.time() - start_time
            remaining = max(0, int(duration - elapsed))
            self.root.after(0, lambda r=remaining: (
                self.inp_var.set(f"🎙️ Listening... ({r}s)"),
                self.wave_timer_lbl.configure(text=f"{r}s")
            ))
            time.sleep(0.1)

        sd.stop()
        self.is_recording = False
        self.root.after(0, self._stop_mic_pulse)
        self.root.after(0, self._stop_wave_anim)
        self.root.after(0, lambda: self.inp_var.set("✦ Processing voice..."))

        # Save WAV file
        transcription = ""
        try:
            actual_frames = int(min(time.time() - start_time, duration) * fs)
            if actual_frames > 1600:
                trimmed_recording = myrecording[:actual_frames]
                with wave.open(temp_wav, 'wb') as wf:
                    wf.setnchannels(1)
                    wf.setsampwidth(2)
                    wf.setframerate(fs)
                    wf.writeframes(trimmed_recording.tobytes())

                transcription = transcribe_audio(temp_wav)
        except Exception as e:
            print(f"Voice processing error: {e}")

        # Cleanup temp file
        if os.path.exists(temp_wav):
            try:
                os.remove(temp_wav)
            except Exception:
                pass

        def _update_ui():
            self.inp.configure(state="normal")
            self.inp.focus_set()
            if transcription:
                self.inp_var.set(transcription)
                # Auto-submit through full agent pipeline
                self._send_command()
            else:
                self._apply_placeholder()
                self._display_response(
                    "Couldn't catch that — try speaking a bit louder or closer to the mic.",
                    tag="error"
                )

        self.root.after(0, _update_ui)

    # ─── Restart Agent ───────────────────────────────────────────────
    def _perform_restart(self):
        self._stop_thinking()
        self._stop_fade_in()
        self._stop_wave_anim()
        try:
            from tools.voice import voice_manager
            voice_manager.stop()
        except Exception:
            pass
        self.agent_loading = True

        self.resp.configure(state="normal")
        self.resp.delete("1.0", "end")
        self.resp.insert("end", "✦ Restarting Nila...\nWarming up agent...", "thinking")
        self.resp.configure(state="disabled")
        self._expand()

        threading.Thread(target=self._async_restart_agent, daemon=True).start()

    def _async_restart_agent(self):
        try:
            import importlib

            # Reload project modules
            modules_to_reload = []
            for mod_name in list(sys.modules.keys()):
                if any(mod_name.startswith(p) for p in ["core.", "llm.", "tools.", "agents.", "training."]):
                    modules_to_reload.append(mod_name)

            if "core.config" in sys.modules:
                try:
                    importlib.reload(sys.modules["core.config"])
                except Exception:
                    pass

            for mod in modules_to_reload:
                if mod != "core.config":
                    try:
                        importlib.reload(sys.modules[mod])
                    except Exception:
                        pass

            from core.agent import NilaAgent
            self.agent = NilaAgent()
            self.agent_loading = False
            self.response_queue.put(("✦ Nila successfully restarted and ready!", "body"))
            self.root.after(0, lambda: self._set_status_label("✦ restarted", C["green"]))
        except Exception as e:
            self.agent_loading = False
            self.response_queue.put((f"Failed to restart Nila: {e}", "_error"))

    def _deiconify_and_focus(self):
        self.is_minimized = False
        self.root.deiconify()
        self.root.lift()
        self.root.focus_force()
        self.inp.focus_set()

    def _close_and_destroy(self):
        self._stop_thinking()
        self._stop_fade_in()
        self._stop_wave_anim()
        try:
            from tools.voice import voice_manager
            voice_manager.stop()
        except Exception:
            pass
        self.root.destroy()
        sys.exit(0)

    def _drag_start(self, e):
        self._dragging_x = e.x_root - self.root.winfo_x()
        self._dragging_y = e.y_root - self.root.winfo_y()

    def _drag_move(self, e):
        self.root.geometry(f"+{e.x_root - self._dragging_x}+{e.y_root - self._dragging_y}")

    def run(self):
        self.root.mainloop()


def launch_overlay():
    NilaOverlay().run()

if __name__ == "__main__":
    launch_overlay()
