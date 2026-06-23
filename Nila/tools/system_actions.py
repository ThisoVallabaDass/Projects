"""
Offline System Actions — Maps natural language to OS-level commands.
No AI inference needed. Works 100% offline via subprocess/PowerShell.
"""

import os
import re
import subprocess
import webbrowser
import difflib
import urllib.parse
from typing import Optional


class SystemActions:
    """
    Keyword-based dispatcher that maps user intents to system commands.
    Runs BEFORE any LLM call, so it's instant and fully offline.
    """

    # ── Common URLs ──────────────────────────────────────────────────
    URL_MAP = {
        "youtube":   "https://www.youtube.com",
        "google":    "https://www.google.com",
        "gmail":     "https://mail.google.com",
        "github":    "https://github.com",
        "chatgpt":   "https://chatgpt.com",
        "claude":    "https://claude.ai",
        "reddit":    "https://www.reddit.com",
        "twitter":   "https://twitter.com",
        "x":         "https://x.com",
        "instagram": "https://www.instagram.com",
        "whatsapp":  "https://web.whatsapp.com",
        "linkedin":  "https://www.linkedin.com",
        "spotify":   "https://open.spotify.com",
        "netflix":   "https://www.netflix.com",
        "amazon":    "https://www.amazon.in",
        "amazon prime": "https://www.primevideo.com",
        "prime video": "https://www.primevideo.com",
        "hotstar":   "https://www.hotstar.com",
        "wallpaper sites": "https://wallhaven.cc",
        "wallpapers": "https://wallhaven.cc",
        "stackoverflow": "https://stackoverflow.com",
        "wikipedia": "https://www.wikipedia.org",
        "facebook":  "https://www.facebook.com",
    }

    # ── Common apps ──────────────────────────────────────────────────
    APP_MAP = {
        "notepad":    "notepad",
        "calculator": "calc",
        "calc":       "calc",
        "paint":      "mspaint",
        "wordpad":    "write",
        "explorer":   "explorer",
        "file explorer": "explorer",
        "task manager": "taskmgr",
        "settings":   "ms-settings:",
        "control panel": "control",
        "cmd":        "cmd",
        "terminal":   "wt",
        "powershell": "powershell",
        "vscode":     "code",
        "vs code":    "code",
        "chrome":     "chrome",
        "google chrome": "chrome",
        "edge":       "msedge",
        "microsoft edge": "msedge",
        "firefox":    "firefox",
        "brave":      "brave",
        "brave browser": "brave",
        "snipping tool": "SnippingTool",
    }

    # ── Browser executables ──────────────────────────────────────────
    BROWSER_MAP = {
        "chrome":  "chrome",
        "google chrome": "chrome",
        "edge":    "msedge",
        "microsoft edge": "msedge",
        "firefox": "firefox",
        "brave":   "brave",
    }

    def try_system_action(self, user_message: str) -> tuple:
        """
        Attempt to match user_message to a system action.
        Returns (handled: bool, response: str).
        If handled is False, the message should be passed to the LLM.
        """
        msg = user_message.lower().strip()

        # Priority order — check each action type
        checks = [
            self._check_volume,
            self._check_mute,
            self._check_brightness,
            self._check_bluetooth,
            self._check_wifi,
            self._check_wifi_name,
            self._check_play_or_search,
            self._check_open_url,
            self._check_open_app,
            self._check_lock_screen,
            self._check_screenshot,
            self._check_media_control,
            self._check_shutdown_restart,
        ]

        for check in checks:
            handled, response = check(msg)
            if handled:
                return True, response

        return False, ""

    # ══════════════════════════════════════════════════════════════════
    # Volume
    # ══════════════════════════════════════════════════════════════════

    def _check_volume(self, msg: str) -> tuple:
        up_kw = ["volume up", "increase volume", "louder", "raise volume",
                 "turn up volume", "turn up the volume", "volume increase"]
        down_kw = ["volume down", "decrease volume", "reduce volume", "lower volume",
                   "quieter", "turn down volume", "turn down the volume", "volume decrease",
                   "volume reduce", "volume lower"]

        if any(kw in msg for kw in up_kw):
            return self._set_volume("up")
        if any(kw in msg for kw in down_kw):
            return self._set_volume("down")

        # "set volume to 50" / "volume 30%"
        vol_match = re.search(r'(?:set\s+)?volume\s+(?:to\s+)?(\d+)\s*%?', msg)
        if vol_match:
            level = min(100, max(0, int(vol_match.group(1))))
            return self._set_volume_level(level)

        return False, ""

    def _set_volume(self, direction: str) -> tuple:
        try:
            # Use PowerShell with WScript.Shell SendKeys for volume keys
            if direction == "up":
                # Volume Up key = 0xAF = 175
                ps = '(New-Object -ComObject WScript.Shell).SendKeys([char]175)'
                label = "🔊 Volume increased"
            else:
                # Volume Down key = 0xAE = 174
                ps = '(New-Object -ComObject WScript.Shell).SendKeys([char]174)'
                label = "🔉 Volume decreased"

            # Send key multiple times for a noticeable change
            for _ in range(5):
                subprocess.run(
                    ["powershell", "-NoProfile", "-Command", ps],
                    capture_output=True, timeout=5
                )
            return True, label
        except Exception as e:
            return True, f"⚠️ Volume control failed: {e}"

    def _set_volume_level(self, level: int) -> tuple:
        try:
            # Use PowerShell + AudioDeviceCmdlets or nircmd approach
            ps = f"""
Add-Type -TypeDefinition @'
using System.Runtime.InteropServices;
[Guid("5CDF2C82-841E-4546-9722-0CF74078229A"), InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
interface IAudioEndpointVolume {{
    int _0(); int _1(); int _2(); int _3();
    int SetMasterVolumeLevelScalar(float fLevel, System.Guid pguidEventContext);
    int GetMasterVolumeLevelScalar(out float pfLevel);
}}
[Guid("D666063F-1587-4E43-81F1-B948E807363F"), InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
interface IMMDevice {{ int Activate(ref System.Guid id, int clsCtx, int activationParams, out IAudioEndpointVolume aev); }}
[Guid("A95664D2-9614-4F35-A746-DE8DB63617E6"), InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
interface IMMDeviceEnumerator {{ int GetDefaultAudioEndpoint(int dataFlow, int role, out IMMDevice endpoint); }}
[ComImport, Guid("BCDE0395-E52F-467C-8E3D-C4579291692E")] class MMDeviceEnumeratorComObject {{ }}
'@
$de = New-Object MMDeviceEnumeratorComObject
$enum = [IMMDeviceEnumerator]$de
$dev = $null; $enum.GetDefaultAudioEndpoint(0, 1, [ref]$dev)
$guid = [Guid]'5CDF2C82-841E-4546-9722-0CF74078229A'
$aev = $null; $dev.Activate([ref]$guid, 1, 0, [ref]$aev)
$aev.SetMasterVolumeLevelScalar({level/100.0}, [Guid]::Empty)
"""
            subprocess.run(
                ["powershell", "-NoProfile", "-Command", ps],
                capture_output=True, timeout=10
            )
            return True, f"🔊 Volume set to {level}%"
        except Exception as e:
            # Fallback: use nircmd if available
            try:
                # nircmd uses 0-65535 range
                nircmd_level = int(level / 100 * 65535)
                subprocess.run(
                    ["nircmd", "setsysvolume", str(nircmd_level)],
                    capture_output=True, timeout=5
                )
                return True, f"🔊 Volume set to {level}%"
            except Exception:
                return True, f"⚠️ Could not set volume to {level}%: {e}"

    # ══════════════════════════════════════════════════════════════════
    # Mute
    # ══════════════════════════════════════════════════════════════════

    def _check_mute(self, msg: str) -> tuple:
        mute_kw = ["mute", "unmute", "toggle mute", "mute toggle", "silence"]
        if any(kw in msg for kw in mute_kw):
            try:
                # Mute toggle key = 0xAD = 173
                ps = '(New-Object -ComObject WScript.Shell).SendKeys([char]173)'
                subprocess.run(
                    ["powershell", "-NoProfile", "-Command", ps],
                    capture_output=True, timeout=5
                )
                return True, "🔇 Mute toggled"
            except Exception as e:
                return True, f"⚠️ Mute toggle failed: {e}"
        return False, ""

    # ══════════════════════════════════════════════════════════════════
    # Brightness
    # ══════════════════════════════════════════════════════════════════

    def _check_brightness(self, msg: str) -> tuple:
        up_kw = ["brightness up", "increase brightness", "brighter", "screen brighter"]
        down_kw = ["brightness down", "decrease brightness", "dimmer", "screen dimmer",
                   "reduce brightness", "lower brightness"]

        if any(kw in msg for kw in up_kw):
            return self._adjust_brightness(+20)
        if any(kw in msg for kw in down_kw):
            return self._adjust_brightness(-20)

        # "set brightness to 80"
        br_match = re.search(r'(?:set\s+)?brightness\s+(?:to\s+)?(\d+)\s*%?', msg)
        if br_match:
            level = min(100, max(0, int(br_match.group(1))))
            return self._set_brightness(level)

        return False, ""

    def _adjust_brightness(self, delta: int) -> tuple:
        try:
            ps = f"""
$current = (Get-CimInstance -Namespace root/WMI -ClassName WmiMonitorBrightness).CurrentBrightness
$new = [math]::Max(0, [math]::Min(100, $current + {delta}))
$instance = Get-CimInstance -Namespace root/WMI -ClassName WmiMonitorBrightnessMethods
$instance | Invoke-CimMethod -MethodName WmiSetBrightness -Arguments @{{Timeout=1; Brightness=$new}}
Write-Output $new
"""
            result = subprocess.run(
                ["powershell", "-NoProfile", "-Command", ps],
                capture_output=True, text=True, timeout=10
            )
            label = "☀️ Brightness increased" if delta > 0 else "🌙 Brightness decreased"
            return True, label
        except Exception as e:
            return True, f"⚠️ Brightness control failed: {e}"

    def _set_brightness(self, level: int) -> tuple:
        try:
            ps = f"""
$instance = Get-CimInstance -Namespace root/WMI -ClassName WmiMonitorBrightnessMethods
$instance | Invoke-CimMethod -MethodName WmiSetBrightness -Arguments @{{Timeout=1; Brightness={level}}}
"""
            subprocess.run(
                ["powershell", "-NoProfile", "-Command", ps],
                capture_output=True, timeout=10
            )
            return True, f"☀️ Brightness set to {level}%"
        except Exception as e:
            return True, f"⚠️ Could not set brightness: {e}"

    # ══════════════════════════════════════════════════════════════════
    # Bluetooth
    # ══════════════════════════════════════════════════════════════════

    def _check_bluetooth(self, msg: str) -> tuple:
        on_kw = ["turn on bluetooth", "enable bluetooth", "bluetooth on",
                 "start bluetooth", "activate bluetooth"]
        off_kw = ["turn off bluetooth", "disable bluetooth", "bluetooth off",
                  "stop bluetooth", "deactivate bluetooth"]

        if any(kw in msg for kw in on_kw):
            return self._toggle_bluetooth(True)
        if any(kw in msg for kw in off_kw):
            return self._toggle_bluetooth(False)
        return False, ""

    def _toggle_bluetooth(self, enable: bool) -> tuple:
        try:
            if enable:
                ps = "Start-Service bthserv -ErrorAction SilentlyContinue"
                label = "📶 Bluetooth enabled"
            else:
                ps = "Stop-Service bthserv -Force -ErrorAction SilentlyContinue"
                label = "📴 Bluetooth disabled"
            subprocess.run(
                ["powershell", "-NoProfile", "-Command", ps],
                capture_output=True, timeout=10
            )
            return True, label
        except Exception as e:
            return True, f"⚠️ Bluetooth toggle failed: {e}"

    # ══════════════════════════════════════════════════════════════════
    # WiFi
    # ══════════════════════════════════════════════════════════════════

    def _check_wifi(self, msg: str) -> tuple:
        on_kw = ["turn on wifi", "enable wifi", "wifi on", "connect wifi",
                 "turn on wi-fi", "enable wi-fi"]
        off_kw = ["turn off wifi", "disable wifi", "wifi off", "disconnect wifi",
                  "turn off wi-fi", "disable wi-fi"]

        if any(kw in msg for kw in on_kw):
            return self._toggle_wifi(True)
        if any(kw in msg for kw in off_kw):
            return self._toggle_wifi(False)
        return False, ""

    def _toggle_wifi(self, enable: bool) -> tuple:
        try:
            action = "enable" if enable else "disable"
            # Try common adapter names
            ps = f'netsh interface set interface "Wi-Fi" {action}'
            subprocess.run(ps, shell=True, capture_output=True, timeout=10)
            label = "📡 Wi-Fi enabled" if enable else "📴 Wi-Fi disabled"
            return True, label
        except Exception as e:
            return True, f"⚠️ Wi-Fi toggle failed: {e}"

    def _check_wifi_name(self, msg: str) -> tuple:
        wifi_queries = ["wifi name", "wifi connected", "name of wifi", "wifi ssid", 
                        "what wifi", "connected wifi", "network name"]
        if any(q in msg for q in wifi_queries):
            try:
                result = subprocess.run(
                    ["powershell", "-NoProfile", "-Command", "netsh wlan show interfaces"],
                    capture_output=True, text=True, timeout=5
                )
                if result.returncode == 0:
                    for line in result.stdout.splitlines():
                        if "SSID" in line and "BSSID" not in line:
                            parts = line.split(":")
                            if len(parts) > 1:
                                ssid = parts[1].strip()
                                return True, f"📶 Connected to Wi-Fi: **{ssid}**"
                return True, "📶 Wi-Fi is on, but no active network is connected."
            except Exception as e:
                return True, f"⚠️ Could not check Wi-Fi name: {e}"
        return False, ""

    # ══════════════════════════════════════════════════════════════════
    # Play or Search (YouTube, Spotify, Google)
    # ══════════════════════════════════════════════════════════════════

    def _check_play_or_search(self, msg: str) -> tuple:
        # Avoid intercepting standard media controls
        media_kws = ["play music", "resume music", "pause music", "play pause", "play/pause", "media play", "media pause", "play", "pause", "resume"]
        if msg in media_kws:
            return False, ""

        # Verbs and platform triggers
        verbs = r'(?:play|search|find|listen\s+to|search\s+for|look\s+up|googl\w*|google)'
        platforms = r'(?:on|in|using|with|via)\s+(youtube|spotify|google|yt)'
        
        # Check if browser is specified at the end, e.g., "... in chrome"
        browser_match = re.search(r'\s+(?:in|using|with|on|via)\s+(chrome|google chrome|edge|microsoft edge|firefox|brave)$', msg)
        browser = None
        clean_msg = msg
        if browser_match:
            browser = browser_match.group(1).strip()
            clean_msg = msg[:browser_match.start()].strip()

        # Pattern 1a: play <query> on/in <platform>
        m = re.search(fr'^{verbs}\s+(.+?)\s+{platforms}$', clean_msg)
        if m:
            query = m.group(1).strip()
            platform = m.group(2).strip().lower()
            return self._execute_play_or_search(query, platform, browser)

        # Pattern 1b: play on/in <platform> <query>
        m = re.search(fr'^{verbs}\s+{platforms}\s+(.+)$', clean_msg)
        if m:
            platform = m.group(1).strip().lower()
            query = m.group(2).strip()
            return self._execute_play_or_search(query, platform, browser)

        # Pattern 1c: <platform> play <query>
        m = re.search(fr'^(youtube|spotify|google|yt)\s+{verbs}\s+(.+)$', clean_msg)
        if m:
            platform = m.group(1).strip().lower()
            query = m.group(2).strip()
            return self._execute_play_or_search(query, platform, browser)

        # Pattern 1d: play/listen to <query> (default to YouTube search)
        m = re.search(fr'^(?:play|listen\s+to)\s+(.+)$', clean_msg)
        if m:
            query = m.group(1).strip()
            return self._execute_play_or_search(query, "youtube", browser)

        # Pattern 1e: search/find/google <query> (default to Google search)
        m = re.search(fr'^(?:search|find|google|look\s+up)\s+(.+)$', clean_msg)
        if m:
            query = m.group(1).strip()
            return self._execute_play_or_search(query, "google", browser)

        return False, ""

    def _execute_play_or_search(self, query: str, platform: str, browser: Optional[str]) -> tuple:
        encoded_query = urllib.parse.quote_plus(query)
        
        if platform in ("youtube", "yt"):
            url = f"https://www.youtube.com/results?search_query={encoded_query}"
            label = f"🎵 Playing **{query}** on YouTube (searching results)"
        elif platform == "spotify":
            url = f"https://open.spotify.com/search/{encoded_query}"
            label = f"🎵 Playing **{query}** on Spotify (searching results)"
        elif platform == "google":
            url = f"https://www.google.com/search?q={encoded_query}"
            label = f"🔍 Searching Google for: **{query}**"
        else:
            url = f"https://www.google.com/search?q={encoded_query}"
            label = f"🔍 Searching for: **{query}**"

        # Reuse browser open logic
        handled, resp = self._open_url_in_browser(url, browser)
        if handled:
            # Customize the response message to be clear
            if browser:
                return True, f"{label} (in {browser.title()})"
            return True, label
            
        return False, ""

    # ══════════════════════════════════════════════════════════════════
    # Open URL (in specific browser or default)
    # ══════════════════════════════════════════════════════════════════

    def _check_open_url(self, msg: str) -> tuple:
        # Match pattern: open/watch/play <site> in/on/using <browser>
        # e.g., "opne youtube in chrome", "watch amazon prime in brave", "open insgram in edge"
        action_verb_pattern = r'(?:open|opne|opn|oppen|openn|launch|lauch|start|run|runn|watch|play|go\s+to|goto)'
        
        # 1. Match site with browser specification
        m = re.search(
            fr'{action_verb_pattern}\s+(.+?)\s+(?:in|using|with|on|from|via)\s+(chrome|google chrome|edge|microsoft edge|firefox|brave|browser)',
            msg
        )
        if m:
            site_input = m.group(1).strip()
            browser_input = m.group(2).strip()
            
            # Resolve site name
            resolved_site = self._find_closest_match(site_input, list(self.URL_MAP.keys()))
            if resolved_site:
                return self._open_url_in_browser(resolved_site, browser_input)
            else:
                # If we couldn't match, try to open site_input as direct URL or search term
                return self._open_url_in_browser(site_input, browser_input)

        # 2. Match site alone (without browser specification)
        # e.g., "opne utube", "go to instagram", "open amazon"
        m = re.search(fr'{action_verb_pattern}\s+([\w\s.]+)', msg)
        if m:
            site_input = m.group(1).strip()
            resolved_app = self._find_closest_match(site_input, list(self.APP_MAP.keys()), cutoff=0.7)
            resolved_site = self._find_closest_match(site_input, list(self.URL_MAP.keys()), cutoff=0.6)
            
            # Prioritize site URL matching
            if resolved_site:
                return self._open_url_in_browser(resolved_site, None)
            elif resolved_app:
                return self._launch_app(resolved_app)
            elif '.' in site_input:
                url = site_input if site_input.startswith('http') else f"https://{site_input}"
                try:
                    webbrowser.open(url)
                    return True, f"🌐 Opened {url}"
                except Exception as e:
                    return True, f"⚠️ Could not open {url}: {e}"

        # 3. Match: search/play/find <query> on youtube
        m = re.search(r'(?:search|play|find)\s+(?:for\s+)?(.+?)\s+on\s+youtube', msg)
        if m:
            query = m.group(1).strip().replace(' ', '+')
            url = f"https://www.youtube.com/results?search_query={query}"
            try:
                webbrowser.open(url)
                return True, f"🔍 Searching YouTube for: {m.group(1).strip()}"
            except Exception as e:
                return True, f"⚠️ Could not open YouTube search: {e}"

        return False, ""

    def _open_url_in_browser(self, site: str, browser: Optional[str]) -> tuple:
        # Resolve site name to URL
        url = self.URL_MAP.get(site, site)
        if not url.startswith('http'):
            if '.' in url:
                url = f"https://{url}"
            else:
                url = f"https://www.google.com/search?q={url}"

        try:
            if browser:
                browser_clean = browser.lower().strip()
                if "edge" in browser_clean:
                    os.startfile(f"microsoft-edge:{url}")
                    return True, f"🌐 Opened {site} in Edge → {url}"
                
                browser_path = self._find_browser_path(browser_clean)
                if browser_path and os.path.exists(browser_path):
                    subprocess.Popen(
                        [browser_path, url],
                        stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL
                    )
                    return True, f"🌐 Opened {site} in {browser_clean.title()} → {url}"
                else:
                    webbrowser.open(url)
                    return True, f"🌐 Opened {site} → {url} (in default browser)"
            else:
                webbrowser.open(url)
                return True, f"🌐 Opened {site} → {url}"
        except Exception as e:
            try:
                webbrowser.open(url)
                return True, f"🌐 Opened {site} → {url} (fallback)"
            except Exception as ex:
                return True, f"⚠️ Could not open {url}: {ex}"

    # ══════════════════════════════════════════════════════════════════
    # Open App
    # ══════════════════════════════════════════════════════════════════

    def _check_open_app(self, msg: str) -> tuple:
        action_verb_pattern = r'(?:open|opne|opn|oppen|openn|launch|lauch|start|run|runn)'
        m = re.search(fr'{action_verb_pattern}\s+([\w\s]+?)(?:\s*$|\s+(?:app|application|program|browser))', msg)
        if m:
            app_input = m.group(1).strip()
            resolved_app = self._find_closest_match(app_input, list(self.APP_MAP.keys()), cutoff=0.6)
            if resolved_app:
                return self._launch_app(resolved_app)
        return False, ""

    def _launch_app(self, app_key: str) -> tuple:
        cmd = self.APP_MAP[app_key]
        try:
            if app_key == "edge":
                os.startfile("microsoft-edge:")
                return True, "🚀 Opened Microsoft Edge"
            elif app_key == "chrome" or app_key == "google chrome":
                chrome_path = self._find_browser_path("chrome")
                subprocess.Popen([chrome_path], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
                return True, "🚀 Opened Google Chrome"
            elif app_key == "firefox":
                firefox_path = self._find_browser_path("firefox")
                subprocess.Popen([firefox_path], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
                return True, "🚀 Opened Firefox"
            elif app_key == "brave" or app_key == "brave browser":
                brave_path = self._find_browser_path("brave")
                subprocess.Popen([brave_path], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
                return True, "🚀 Opened Brave Browser"
            elif cmd.startswith("ms-"):
                os.startfile(cmd)
                return True, f"🚀 Opened {app_key}"
            else:
                subprocess.Popen([cmd], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
                return True, f"🚀 Opened {app_key}"
        except Exception as e:
            return True, f"⚠️ Could not open {app_key}: {e}"

    # ══════════════════════════════════════════════════════════════════
    # Lock Screen
    # ══════════════════════════════════════════════════════════════════

    def _check_lock_screen(self, msg: str) -> tuple:
        kw = ["lock screen", "lock computer", "lock pc", "lock my pc",
              "lock my computer", "lock the screen"]
        if any(kw_ in msg for kw_ in kw):
            try:
                subprocess.run(
                    ["rundll32.exe", "user32.dll,LockWorkStation"],
                    capture_output=True, timeout=5
                )
                return True, "🔒 Screen locked"
            except Exception as e:
                return True, f"⚠️ Lock screen failed: {e}"
        return False, ""

    # ══════════════════════════════════════════════════════════════════
    # Screenshot
    # ══════════════════════════════════════════════════════════════════

    def _check_screenshot(self, msg: str) -> tuple:
        kw = ["take screenshot", "screenshot", "capture screen", "screen capture",
              "take a screenshot", "grab screen"]
        if any(kw_ in msg for kw_ in kw):
            try:
                # Use Snipping Tool or Win+PrintScreen
                subprocess.Popen(
                    ["SnippingTool", "/clip"],
                    stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL
                )
                return True, "📸 Screenshot tool opened — drag to capture"
            except Exception:
                try:
                    # Fallback: use snippingtool
                    subprocess.Popen(
                        ["snippingtool"],
                        stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL
                    )
                    return True, "📸 Snipping tool opened"
                except Exception as e:
                    return True, f"⚠️ Screenshot failed: {e}"
        return False, ""

    # ══════════════════════════════════════════════════════════════════
    # Media Control (play/pause/next/prev)
    # ══════════════════════════════════════════════════════════════════

    def _check_media_control(self, msg: str) -> tuple:
        play_kw = ["play music", "resume music", "pause music", "play pause",
                   "play/pause", "media play", "media pause"]
        next_kw = ["next song", "next track", "skip song", "skip track", "media next"]
        prev_kw = ["previous song", "previous track", "prev song", "media previous"]

        if any(kw in msg for kw in play_kw):
            # Play/Pause key = 0xB3 = 179
            ps = '(New-Object -ComObject WScript.Shell).SendKeys([char]179)'
            subprocess.run(["powershell", "-NoProfile", "-Command", ps],
                           capture_output=True, timeout=5)
            return True, "⏯️ Play/Pause toggled"

        if any(kw in msg for kw in next_kw):
            # Next Track key = 0xB0 = 176
            ps = '(New-Object -ComObject WScript.Shell).SendKeys([char]176)'
            subprocess.run(["powershell", "-NoProfile", "-Command", ps],
                           capture_output=True, timeout=5)
            return True, "⏭️ Next track"

        if any(kw in msg for kw in prev_kw):
            # Previous Track key = 0xB1 = 177
            ps = '(New-Object -ComObject WScript.Shell).SendKeys([char]177)'
            subprocess.run(["powershell", "-NoProfile", "-Command", ps],
                           capture_output=True, timeout=5)
            return True, "⏮️ Previous track"

        return False, ""

    # ══════════════════════════════════════════════════════════════════
    # Shutdown / Restart (with safety)
    # ══════════════════════════════════════════════════════════════════

    def _check_shutdown_restart(self, msg: str) -> tuple:
        if any(kw in msg for kw in ["shutdown computer", "shut down", "turn off pc",
                                     "turn off computer"]):
            return True, "⚠️ To shutdown, run: `shutdown /s /t 60` in terminal (60s delay to cancel with `shutdown /a`)"
        if any(kw in msg for kw in ["restart computer", "restart pc", "reboot"]):
            return True, "⚠️ To restart, run: `shutdown /r /t 60` in terminal (60s delay to cancel with `shutdown /a`)"
        return False, ""

    # ── Helpers for fuzzy matching and browser resolving ──────────────

    def _find_closest_match(self, name: str, choices: list, cutoff: float = 0.6) -> Optional[str]:
        """Fuzzy find closest matching website/app key."""
        name_clean = name.strip().lower()
        
        # Clean common suffixes to improve exact matches
        suffixes = [" browser", " app", " application", " program", " website", " site"]
        for suffix in suffixes:
            if name_clean.endswith(suffix):
                name_clean = name_clean[:-len(suffix)].strip()
                
        if name_clean in choices:
            return name_clean
            
        matches = difflib.get_close_matches(name_clean, choices, n=1, cutoff=cutoff)
        if matches:
            return matches[0]
            
        for choice in choices:
            if name_clean in choice or choice in name_clean:
                return choice
        return None

    def _find_browser_path(self, browser_name: str) -> Optional[str]:
        """Find the executable path of a browser on Windows."""
        name = browser_name.lower().strip()
        
        exe_names = {
            "chrome": ["chrome.exe"],
            "google chrome": ["chrome.exe"],
            "edge": ["msedge.exe"],
            "microsoft edge": ["msedge.exe"],
            "firefox": ["firefox.exe"],
            "brave": ["brave.exe"],
        }
        
        target_exes = exe_names.get(name, [f"{name}.exe"])
        
        # Check standard location dirs on Windows
        search_dirs = [
            os.environ.get("ProgramFiles", "C:\\Program Files"),
            os.environ.get("ProgramFiles(x86)", "C:\\Program Files (x86)"),
            os.environ.get("LocalAppData", "C:\\Users\\default\\AppData\\Local"),
        ]
        
        subpaths = [
            "Google\\Chrome\\Application",
            "Microsoft\\Edge\\Application",
            "BraveSoftware\\Brave-Browser\\Application",
            "Mozilla Firefox",
        ]
        
        for d in search_dirs:
            if not d:
                continue
            for sp in subpaths:
                for target in target_exes:
                    full_path = os.path.join(d, sp, target)
                    if os.path.exists(full_path):
                        return full_path
                        
        # Fallback to App Paths in Registry
        try:
            import winreg
            for target in target_exes:
                for root_key in (winreg.HKEY_LOCAL_MACHINE, winreg.HKEY_CURRENT_USER):
                    try:
                        key_path = f"SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\App Paths\\{target}"
                        with winreg.OpenKey(root_key, key_path) as key:
                            path, _ = winreg.QueryValue(key, None)
                            if os.path.exists(path):
                                return path
                    except Exception:
                        pass
        except Exception:
            pass
                    
        return target_exes[0]
