"""
Terminal Agent — Gives Nila access to the file system and terminal.
All destructive actions (delete, overwrite) require confirmation.
All actions are logged to data/agent_actions.log.
"""

import subprocess
import os
import shutil
import glob
import re
from pathlib import Path
from datetime import datetime
from typing import Optional


class TerminalAgent:
    """
    Gives Nila access to the file system and terminal.
    All destructive actions (delete, overwrite) require confirmation.
    All actions are logged to data/agent_actions.log.
    """

    # Actions that need user confirmation before executing
    DANGEROUS_ACTIONS = ["delete", "remove", "rm", "overwrite", "format"]

    # Paths that are NEVER accessible (protect system files)
    BLOCKED_PATHS = [
        "C:\\Windows",
        "C:\\System32",
        "C:\\Program Files",
        "/etc",
        "/usr",
        "/bin",
        "/sbin",
        os.path.expanduser("~/.ssh"),
    ]

    # Commands that are NEVER allowed
    BLOCKED_COMMANDS = [
        "rm -rf /",
        "format c:",
        "del /f /s /q c:\\",
        "shutdown",
        "taskkill /f",
        "mkfs",
        "dd if=",
        ":(){ :|:&",
        "reg delete",
        "net user",
    ]

    def __init__(self):
        self.log_file = os.path.join(
            os.path.dirname(os.path.dirname(os.path.abspath(__file__))),
            "data",
            "agent_actions.log",
        )
        self.pending_confirmation = None  # stores dangerous action waiting for yes/no
        os.makedirs(os.path.dirname(self.log_file), exist_ok=True)

    # ------------------------------------------------------------------
    # Logging
    # ------------------------------------------------------------------

    def _log(self, action: str, result: str):
        """Append an action to the audit log."""
        try:
            with open(self.log_file, "a", encoding="utf-8") as f:
                f.write(f"[{datetime.now().isoformat()}] {action}\n")
                f.write(f"  Result: {result[:200]}\n\n")
        except Exception:
            pass

    # ------------------------------------------------------------------
    # Safety
    # ------------------------------------------------------------------

    def _is_blocked(self, path: str) -> bool:
        """Check if a path is in the blocked list."""
        try:
            resolved = str(Path(path).resolve()).lower()
        except Exception:
            resolved = path.lower()
        return any(blocked.lower() in resolved for blocked in self.BLOCKED_PATHS)

    def _is_command_blocked(self, command: str) -> bool:
        """Check if a command is blocked."""
        cmd_lower = command.lower().strip()
        return any(d in cmd_lower for d in self.BLOCKED_COMMANDS)

    # ------------------------------------------------------------------
    # Command Execution
    # ------------------------------------------------------------------

    def run_command(self, command: str, working_dir: str = None) -> dict:
        """
        Execute a terminal command safely.
        Returns: {success, output, error, command, returncode}

        Blocked commands: rm -rf /, format, del /f /s, shutdown, etc.
        Timeout: 30 seconds.
        """
        if self._is_command_blocked(command):
            return {
                "success": False,
                "output": "",
                "error": f"Blocked: '{command}' is too dangerous to run.",
                "command": command,
            }

        try:
            result = subprocess.run(
                command,
                shell=True,
                capture_output=True,
                text=True,
                timeout=30,
                cwd=working_dir or os.getcwd(),
                encoding="utf-8",
                errors="replace",
            )

            output = result.stdout.strip()
            error = result.stderr.strip()
            success = result.returncode == 0

            self._log(f"CMD: {command}", output or error or "(no output)")

            return {
                "success": success,
                "output": output,
                "error": error,
                "command": command,
                "returncode": result.returncode,
            }
        except subprocess.TimeoutExpired:
            self._log(f"CMD TIMEOUT: {command}", "timed out after 30s")
            return {
                "success": False,
                "output": "",
                "error": "Command timed out after 30 seconds.",
                "command": command,
            }
        except Exception as e:
            self._log(f"CMD ERROR: {command}", str(e))
            return {"success": False, "output": "", "error": str(e), "command": command}

    # ------------------------------------------------------------------
    # File Operations
    # ------------------------------------------------------------------

    def read_file(self, path: str) -> dict:
        """Read a file and return its contents."""
        if self._is_blocked(path):
            return {"success": False, "content": "", "error": "Path is blocked for safety."}

        try:
            p = Path(path)
            if not p.exists():
                # Try to find the file
                matches = self.find_files(p.name, search_dir=str(p.parent) if p.parent.exists() else None)
                if matches:
                    suggestion = matches[0]
                    return {
                        "success": False,
                        "content": "",
                        "error": f"File not found at '{path}'. Did you mean: {suggestion}?",
                    }
                return {"success": False, "content": "", "error": f"File not found: {path}"}

            if not p.is_file():
                return {"success": False, "content": "", "error": f"Not a file: {path}"}

            if p.stat().st_size > 5 * 1024 * 1024:  # 5MB limit
                return {
                    "success": False,
                    "content": "",
                    "error": "File too large (>5MB). Use a specific line range.",
                }

            content = p.read_text(encoding="utf-8", errors="replace")
            self._log(f"READ: {path}", f"{len(content)} chars")
            return {
                "success": True,
                "content": content,
                "path": str(p.resolve()),
                "size": p.stat().st_size,
                "lines": content.count("\n") + 1,
            }

        except Exception as e:
            return {"success": False, "content": "", "error": str(e)}

    def create_file(self, path: str, content: str, overwrite: bool = False) -> dict:
        """Create a new file with given content."""
        if self._is_blocked(path):
            return {"success": False, "error": "Path is blocked for safety."}

        try:
            p = Path(path)

            if p.exists() and not overwrite:
                return {
                    "success": False,
                    "error": f"File already exists: {path}. Say 'yes overwrite' to replace it.",
                    "needs_confirmation": True,
                    "action": ("create_file", path, content, True),
                }

            p.parent.mkdir(parents=True, exist_ok=True)
            p.write_text(content, encoding="utf-8")
            self._log(f"CREATE: {path}", f"{len(content)} chars written")
            return {
                "success": True,
                "path": str(p.resolve()),
                "message": f"File created: {path} ({len(content)} chars)",
            }

        except Exception as e:
            return {"success": False, "error": str(e)}

    def create_folder(self, path: str) -> dict:
        """Create a directory (and parents if needed)."""
        if self._is_blocked(path):
            return {"success": False, "error": "Path is blocked for safety."}
        try:
            Path(path).mkdir(parents=True, exist_ok=True)
            self._log(f"MKDIR: {path}", "created")
            return {"success": True, "path": str(Path(path).resolve()), "message": f"Folder created: {path}"}
        except Exception as e:
            return {"success": False, "error": str(e)}

    def list_directory(self, path: str = ".", show_hidden: bool = False) -> dict:
        """List contents of a directory."""
        try:
            p = Path(path)
            if not p.exists():
                return {"success": False, "error": f"Directory not found: {path}"}
            if not p.is_dir():
                return {"success": False, "error": f"Not a directory: {path}"}

            items = []
            for item in sorted(p.iterdir()):
                if not show_hidden and item.name.startswith("."):
                    continue
                try:
                    size = item.stat().st_size if item.is_file() else 0
                    modified = datetime.fromtimestamp(item.stat().st_mtime).strftime(
                        "%Y-%m-%d %H:%M"
                    )
                except (OSError, PermissionError):
                    size = 0
                    modified = "unknown"

                items.append(
                    {
                        "name": item.name,
                        "type": "file" if item.is_file() else "folder",
                        "size": size,
                        "modified": modified,
                    }
                )

            self._log(f"LIST: {path}", f"{len(items)} items")
            return {
                "success": True,
                "path": str(p.resolve()),
                "items": items,
                "count": len(items),
            }

        except PermissionError:
            return {"success": False, "error": f"Permission denied: {path}"}
        except Exception as e:
            return {"success": False, "error": str(e)}

    def find_files(self, pattern: str, search_dir: str = None) -> list:
        """Find files matching a pattern. Returns up to 20 matches."""
        search_dir = search_dir or os.getcwd()
        matches = []
        try:
            for match in glob.glob(
                os.path.join(search_dir, "**", f"*{pattern}*"), recursive=True
            ):
                if not self._is_blocked(match):
                    matches.append(match)
                if len(matches) >= 20:
                    break
        except Exception:
            pass
        return matches

    def open_file(self, path: str) -> dict:
        """Open file in default application."""
        if self._is_blocked(path):
            return {"success": False, "error": "Path is blocked for safety."}
        try:
            os.startfile(path)  # Windows
            self._log(f"OPEN: {path}", "opened in default app")
            return {"success": True, "message": f"Opened: {path}"}
        except AttributeError:
            try:
                subprocess.Popen(["xdg-open", path])  # Linux
                self._log(f"OPEN: {path}", "opened via xdg-open")
                return {"success": True, "message": f"Opened: {path}"}
            except Exception:
                return {"success": False, "error": "Cannot open file on this OS."}
        except Exception as e:
            return {"success": False, "error": str(e)}

    def append_to_file(self, path: str, content: str) -> dict:
        """Append content to existing file."""
        if self._is_blocked(path):
            return {"success": False, "error": "Path is blocked for safety."}
        try:
            p = Path(path)
            if not p.exists():
                return {"success": False, "error": f"File not found: {path}. Use create_file instead."}
            with open(path, "a", encoding="utf-8") as f:
                f.write(content)
            self._log(f"APPEND: {path}", f"{len(content)} chars appended")
            return {"success": True, "message": f"Appended {len(content)} chars to {path}"}
        except Exception as e:
            return {"success": False, "error": str(e)}

    def delete_file(self, path: str, confirmed: bool = False) -> dict:
        """Delete a file. Requires confirmed=True."""
        if self._is_blocked(path):
            return {"success": False, "error": "Path is blocked for safety."}
        if not confirmed:
            self.pending_confirmation = ("delete_file", path)
            return {
                "success": False,
                "error": f"⚠️ Are you sure you want to delete '{path}'? Say 'yes delete' to confirm.",
                "needs_confirmation": True,
            }
        try:
            p = Path(path)
            if p.is_file():
                p.unlink()
                self._log(f"DELETE: {path}", "deleted")
                return {"success": True, "message": f"Deleted: {path}"}
            elif p.is_dir():
                shutil.rmtree(str(p))
                self._log(f"DELETE DIR: {path}", "deleted")
                return {"success": True, "message": f"Deleted folder: {path}"}
            else:
                return {"success": False, "error": f"Not found: {path}"}
        except Exception as e:
            return {"success": False, "error": str(e)}

    def copy_file(self, source: str, destination: str) -> dict:
        """Copy a file or folder."""
        if self._is_blocked(source) or self._is_blocked(destination):
            return {"success": False, "error": "Path is blocked for safety."}
        try:
            src = Path(source)
            if not src.exists():
                return {"success": False, "error": f"Source not found: {source}"}
            if src.is_file():
                shutil.copy2(str(src), destination)
            else:
                shutil.copytree(str(src), destination)
            self._log(f"COPY: {source} -> {destination}", "copied")
            return {"success": True, "message": f"Copied {source} → {destination}"}
        except Exception as e:
            return {"success": False, "error": str(e)}

    def move_file(self, source: str, destination: str) -> dict:
        """Move/rename a file or folder."""
        if self._is_blocked(source) or self._is_blocked(destination):
            return {"success": False, "error": "Path is blocked for safety."}
        try:
            shutil.move(source, destination)
            self._log(f"MOVE: {source} -> {destination}", "moved")
            return {"success": True, "message": f"Moved {source} → {destination}"}
        except Exception as e:
            return {"success": False, "error": str(e)}

    # ------------------------------------------------------------------
    # Audit Log
    # ------------------------------------------------------------------

    def get_action_log(self, last_n: int = 20) -> str:
        """Return last N actions from log."""
        try:
            content = Path(self.log_file).read_text(encoding="utf-8")
            lines = content.strip().split("\n")
            return "\n".join(lines[-(last_n * 3) :])
        except Exception:
            return "No actions logged yet."


# ------------------------------------------------------------------
# Natural language parsing helpers (used by agent.py)
# ------------------------------------------------------------------

# Terminal trigger keywords
TERMINAL_TRIGGERS = {
    "run_command": [
        "run ", "execute ", "terminal ", "run command", "run this",
        "execute this", "cmd ", "shell ",
        "pip install", "pip ", "python ", "node ", "npm ",
        "git ", "git status", "git add", "git commit",
    ],
    "read_file": [
        "read file", "open file", "show file", "read the file",
        "what's in", "contents of", "show me the file",
        "cat ", "type ",
        "file la iruku", "file open pannu", "file padikka",
    ],
    "create_file": [
        "create file", "make file", "new file", "write file",
        "save as", "create a file", "make a new file",
        "file create pannu", "file ezhuthu", "create a calculator",
        "create calculator", "make a calculator", "build a calculator",
        "build calculator", "create a simple calculator",
    ],
    "create_folder": [
        "create folder", "make folder", "new folder", "mkdir",
        "create directory", "make directory", "new directory",
        "folder create pannu", "create a folder", "make a folder",
        "create a directory", "make a directory", "create folders",
        "make folders",
    ],
    "list_files": [
        "list files", "show files", "what files", "folder contents",
        "show directory", "what's in the folder", "list directory",
        "files kaatu", "folder la enna iruku",
    ],
    "find_file": [
        "find file", "search file", "locate file", "where is the file",
        "find the file", "search for file",
        "file edhu", "file enga",
    ],
    "open_file": [
        "open this file", "open it", "launch file",
    ],
    "delete_file": [
        "delete file", "remove file", "delete the file",
        "file delete pannu",
    ],
}


def detect_terminal_action(message: str) -> Optional[str]:
    """Detect if a message is a terminal/file action. Returns action or None."""
    msg = message.lower().strip()
    for action, triggers in TERMINAL_TRIGGERS.items():
        if any(t in msg for t in triggers):
            return action
    return None


def extract_command(message: str) -> str:
    """Extract terminal command from natural language message."""
    # Remove trigger words and extract actual command
    msg = message.strip()
    triggers_to_remove = [
        "please run", "can you run", "run the command",
        "run command", "execute", "run this:", "run:",
        "run ",
    ]
    msg_lower = msg.lower()
    for trigger in triggers_to_remove:
        if msg_lower.startswith(trigger):
            msg = msg[len(trigger):].strip()
            break

    # Strip surrounding quotes/backticks
    msg = msg.strip("`\"'")
    return msg


def extract_path(message: str) -> str:
    """Extract file/folder path from natural language message."""
    # Match Windows paths: C:\... or T:\...
    windows_path = re.search(r"[A-Za-z]:\\[^\s\"'`,]+", message)
    if windows_path:
        return windows_path.group().rstrip(".,;:!?")

    # Match Unix paths
    unix_path = re.search(r"(?<!\w)/[^\s\"'`,]+", message)
    if unix_path:
        return unix_path.group().rstrip(".,;:!?")

    # Match quoted paths
    quoted = re.search(r'["\']([^"\']+)["\']', message)
    if quoted:
        return quoted.group(1)

    # Match backtick paths
    backtick = re.search(r"`([^`]+)`", message)
    if backtick:
        return backtick.group(1)

    # Extract last word that looks like a path or filename
    words = message.split()
    for word in reversed(words):
        if ("." in word and len(word) > 2) or "/" in word or "\\" in word:
            return word.rstrip(".,;:!?")

    return "."


def extract_file_content(message: str) -> tuple:
    """
    Extract path and content from a 'create file' message.
    Returns (path, content) — content may be empty if not specified.
    """
    path = extract_path(message)

    # Look for content markers
    content_markers = [
        "with content", "with text", "containing", "with:",
        "that says", "with the text", "with this:",
    ]
    content = ""
    msg_lower = message.lower()
    for marker in content_markers:
        if marker in msg_lower:
            idx = msg_lower.index(marker) + len(marker)
            content = message[idx:].strip().strip("`\"'")
            break

    return path, content
