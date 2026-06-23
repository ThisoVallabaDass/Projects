"""
Nila Local Memory System
Persistent JSON-based memory — no database, no server.
Stores conversations, facts, goals, and notes on disk.
"""

import json
import os
import shutil
from datetime import datetime

from core.config import DATA_DIR, MEMORY_FILE


# Default empty memory structure
_DEFAULT_MEMORY = {
    "conversations": [],
    "facts": {},
    "goals": [],
    "notes": [],
    "personal_kb": {
        "projects": [],
        "work_notes": [],
        "locations": {},
        "technical_docs": [],
        "custom_facts": {},
    },
}


class MemoryStore:
    """Persistent local memory backed by a single JSON file."""

    def __init__(self, path: str = MEMORY_FILE):
        self.path = path
        self.data: dict = {}
        self.load()

    # ------------------------------------------------------------------
    # Persistence
    # ------------------------------------------------------------------

    def load(self):
        """Load memory from disk. Creates file & directory if missing.
        If the file is corrupted, backs it up and starts fresh."""
        os.makedirs(DATA_DIR, exist_ok=True)

        if not os.path.exists(self.path):
            self.data = json.loads(json.dumps(_DEFAULT_MEMORY))
            self.save()
            return

        try:
            with open(self.path, "r", encoding="utf-8") as f:
                self.data = json.load(f)
            # Ensure all required keys exist (forward-compatibility)
            for key, default in _DEFAULT_MEMORY.items():
                if key not in self.data:
                    self.data[key] = type(default)()
        except (json.JSONDecodeError, ValueError):
            # Corrupted file — backup and reset
            backup = self.path + f".backup_{datetime.now().strftime('%Y%m%d_%H%M%S')}"
            shutil.copy2(self.path, backup)
            print(f"⚠️  Memory file was corrupted. Backed up to {backup}")
            self.data = json.loads(json.dumps(_DEFAULT_MEMORY))
            self.save()

    def save(self):
        """Write current memory to disk."""
        os.makedirs(DATA_DIR, exist_ok=True)
        with open(self.path, "w", encoding="utf-8") as f:
            json.dump(self.data, f, indent=2, ensure_ascii=False)

    # ------------------------------------------------------------------
    # Conversation history
    # ------------------------------------------------------------------

    def add_message(self, role: str, content: str):
        """Append a message to the conversation log and persist."""
        self.data["conversations"].append({
            "role": role,
            "content": content,
            "timestamp": datetime.now().isoformat(),
        })
        self.save()

    def get_history(self, last_n: int = 20) -> list:
        """Return the last N messages in Claude-compatible format."""
        recent = self.data["conversations"][-last_n:]
        return [{"role": m["role"], "content": m["content"]} for m in recent]

    # ------------------------------------------------------------------
    # Facts (key-value pairs about the user)
    # ------------------------------------------------------------------

    def store_fact(self, key: str, value: str):
        """Store a named fact about the user (overwrites if key exists)."""
        self.data["facts"][key] = {
            "value": value,
            "updated": datetime.now().isoformat(),
        }
        self.save()

    def get_fact(self, key: str) -> str | None:
        """Retrieve a stored fact by key."""
        entry = self.data["facts"].get(key)
        return entry["value"] if entry else None

    def get_all_facts(self) -> dict:
        """Return all facts as a simple key→value dict."""
        return {k: v["value"] for k, v in self.data["facts"].items()}

    # ------------------------------------------------------------------
    # Notes (timestamped free-text)
    # ------------------------------------------------------------------

    def add_note(self, text: str):
        """Append a timestamped note."""
        self.data["notes"].append({
            "text": text,
            "timestamp": datetime.now().isoformat(),
        })
        self.save()

    def get_notes(self) -> list:
        """Return all stored notes."""
        return self.data["notes"]

    # ------------------------------------------------------------------
    # Goals (with status tracking)
    # ------------------------------------------------------------------

    def add_goal(self, goal_text: str):
        """Add a new goal with 'active' status."""
        self.data["goals"].append({
            "goal": goal_text,
            "status": "active",
            "created": datetime.now().isoformat(),
        })
        self.save()

    def get_goals(self) -> list:
        """Return all goals."""
        return self.data["goals"]

    # ------------------------------------------------------------------
    # Utilities
    # ------------------------------------------------------------------

    def get_summary(self) -> str:
        """Return a compact JSON summary of facts and goals for the system prompt."""
        summary = {
            "facts": self.get_all_facts(),
            "active_goals": [g["goal"] for g in self.get_goals() if g["status"] == "active"],
            "note_count": len(self.get_notes()),
        }
        return json.dumps(summary, ensure_ascii=False)

    def get_quick_context(self) -> str:
        """Ultra-minimal context for instant local replies. Only name + latest goal."""
        facts = self.get_all_facts()
        goals = self.get_goals()
        name = facts.get("user_name", "Theo")
        latest_goal = ""
        active_goals = [g for g in goals if g.get("status") == "active"]
        if active_goals:
            latest_goal = active_goals[-1].get("goal", "")
        context = f"User: {name}"
        if latest_goal:
            context += f" | Current goal: {latest_goal}"
        return context

    def get_context(self) -> str:
        """Full structured context for detailed responses."""
        facts = self.get_all_facts()
        goals = self.get_goals()
        kb = self.data.get("personal_kb", {})
        history = self.data.get("conversations", [])[-10:]
        active_goals = [g["goal"] for g in goals if g.get("status") == "active"]
        context = "=== NILA MEMORY FOR THEO ===\n"
        context += f"Facts: {json.dumps(facts, ensure_ascii=False)}\n"
        context += f"Goals: {active_goals}\n"
        kb_facts = kb.get("custom_facts", {})
        if kb_facts:
            context += f"KB Facts: {json.dumps(kb_facts, ensure_ascii=False)}\n"
        kb_locations = kb.get("locations", {})
        if kb_locations:
            context += f"KB Locations: {json.dumps(kb_locations, ensure_ascii=False)}\n"
        kb_projects = kb.get("projects", [])
        if kb_projects:
            context += f"Projects: {[p.get('name','') for p in kb_projects[:5]]}\n"
        recent_chat_text = ""
        if history:
            recent_chat_text = "\n".join(f"- {msg['role'].upper()}: {msg['content']}" for msg in history[-6:])
        context += f"Recent Chat History:\n{recent_chat_text}\n"
        context += "=== END MEMORY ===\n"
        return context

    def clear_conversations(self):
        """Wipe conversation history but keep facts, goals, and notes."""
        self.data["conversations"] = []
        self.save()

    def pretty_print(self) -> str:
        """Return a pretty-printed JSON dump of all memory."""
        return json.dumps(self.data, indent=2, ensure_ascii=False)
