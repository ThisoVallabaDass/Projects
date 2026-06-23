"""
Nila Self-Trainer — Learns User Patterns from Every Conversation Turn

Runs after EVERY exchange. Uses pure Python regex/keyword matching — no AI calls.
Must execute in <10ms since it runs on every single message.

Extracts and stores:
- Name, preferences, goals, routines, progress, personality observations
"""

import re
from datetime import datetime
from knowledge.personal_kb import PersonalKB


class SelfTrainer:
    """Extracts learnable facts from conversation and stores them in memory."""

    def __init__(self, memory_store):
        self.memory = memory_store
        self.personal_kb = PersonalKB(memory_store)
        self._ensure_extended_keys()

    def _ensure_extended_keys(self):
        """Ensure the extended memory keys exist (forward-compatible)."""
        for key, default in [
            ("routines", {}),
            ("preferences", {}),
            ("progress_log", []),
            ("personality_notes", []),
        ]:
            if key not in self.memory.data:
                self.memory.data[key] = default
                self.memory.save()

    # ------------------------------------------------------------------
    # Main entry point — called after every conversation turn
    # ------------------------------------------------------------------

    def extract_and_store(self, user_message: str, assistant_response: str):
        """
        Analyze the user's message for learnable patterns and store them.
        Runs after every exchange. Must be fast (<10ms).
        """
        msg = user_message.strip()
        if not msg:
            return

        self._detect_name(msg)
        self._detect_goal(msg)
        self._detect_preference(msg)
        self._detect_progress(msg)
        self._detect_schedule(msg)
        self._detect_emotion(msg)
        self._detect_work_knowledge(msg)

    # ------------------------------------------------------------------
    # Pattern 1: Name detection
    # ------------------------------------------------------------------

    def _detect_name(self, msg: str):
        """Detect user's name from messages like 'I'm THEO' or 'my name is X'."""
        patterns = [
            r"(?:my\s+name\s+is|i'?m|i\s+am|call\s+me|they\s+call\s+me)\s+([A-Z][a-zA-Z]+)",
            r"(?:this\s+is)\s+([A-Z][a-zA-Z]+)\s+(?:here|speaking)",
        ]
        for pattern in patterns:
            match = re.search(pattern, msg, re.IGNORECASE)
            if match:
                name = match.group(1).strip().title()
                # Don't overwrite with common false-positive words
                skip_words = {
                    "Just", "Here", "Really", "Very", "Not", "Also",
                    "Still", "Going", "Trying", "Working", "Looking",
                    "Happy", "Sad", "Good", "Fine", "Okay", "Sure",
                    "Building", "Learning", "Doing", "Making",
                }
                if name not in skip_words and len(name) >= 2:
                    self.memory.store_fact("user_name", name)
                    return

    # ------------------------------------------------------------------
    # Pattern 2: Goal detection
    # ------------------------------------------------------------------

    def _detect_goal(self, msg: str):
        """Detect goals from 'I want to X', 'my goal is X', etc."""
        patterns = [
            r"(?:i\s+want\s+to|i\s+need\s+to|my\s+goal\s+is\s+to?|i'm\s+trying\s+to|i\s+aim\s+to|i\s+plan\s+to|i\s+wish\s+to)\s+(.{10,80})",
            r"(?:my\s+(?:main\s+)?goal\s+is)\s+(.{10,80})",
            r"(?:i'm\s+working\s+(?:on|towards?))\s+(.{10,80})",
        ]
        for pattern in patterns:
            match = re.search(pattern, msg, re.IGNORECASE)
            if match:
                goal_text = match.group(1).strip().rstrip(".")
                # Avoid duplicates — check existing goals
                existing = [g["goal"].lower() for g in self.memory.get_goals()]
                if goal_text.lower() not in existing:
                    self.memory.add_goal(goal_text)
                    return

    # ------------------------------------------------------------------
    # Pattern 3: Preference detection
    # ------------------------------------------------------------------

    def _detect_preference(self, msg: str):
        """Detect preferences from 'I prefer X', 'I like X', 'I enjoy X'."""
        patterns = [
            r"(?:i\s+(?:prefer|like|love|enjoy|hate|dislike|can't\s+stand))\s+(.{5,60})",
            r"(?:my\s+(?:favorite|favourite|preferred))\s+(\w+)\s+is\s+(.{3,40})",
        ]
        for pattern in patterns:
            match = re.search(pattern, msg, re.IGNORECASE)
            if match:
                if match.lastindex == 2:
                    # "my favorite X is Y" pattern
                    category = match.group(1).strip().lower()
                    value = match.group(2).strip().rstrip(".")
                    key = f"preference_{category}"
                else:
                    # "I like/prefer X" pattern
                    value = match.group(1).strip().rstrip(".")
                    verb = re.match(r"i\s+(\w+)", msg, re.IGNORECASE)
                    sentiment = verb.group(1).lower() if verb else "likes"
                    key = f"preference_{sentiment}"

                self.memory.data.setdefault("preferences", {})
                self.memory.data["preferences"][key] = {
                    "value": value,
                    "updated": datetime.now().isoformat(),
                }
                self.memory.save()
                return

    # ------------------------------------------------------------------
    # Pattern 4: Progress tracking
    # ------------------------------------------------------------------

    def _detect_progress(self, msg: str):
        """Detect completed tasks from 'I completed X', 'I finished X', 'I did X today'."""
        patterns = [
            r"(?:i\s+(?:completed|finished|done|did|accomplished|submitted|deployed|built|pushed|shipped))\s+(.{5,80})",
            r"(?:just\s+(?:completed|finished|done|did|deployed|built|pushed|shipped))\s+(.{5,80})",
        ]
        for pattern in patterns:
            match = re.search(pattern, msg, re.IGNORECASE)
            if match:
                task = match.group(1).strip().rstrip(".")
                self.memory.data.setdefault("progress_log", [])
                self.memory.data["progress_log"].append({
                    "task": task,
                    "timestamp": datetime.now().isoformat(),
                })
                self.memory.save()
                return

    # ------------------------------------------------------------------
    # Pattern 5: Schedule/routine detection
    # ------------------------------------------------------------------

    def _detect_schedule(self, msg: str):
        """Detect time-based routines from 'I gym at 6am', 'I study at night'."""
        patterns = [
            r"i\s+(\w+)\s+(?:at|around|by)\s+(\d{1,2}\s*(?:am|pm|AM|PM))",
            r"i\s+(?:usually|always|normally|typically)\s+(\w+)\s+(?:in\s+the\s+)?(morning|afternoon|evening|night)",
            r"i\s+(\w+)\s+(?:every|each)\s+(morning|evening|night|day|weekday|weekend)",
            r"my\s+(\w+)\s+(?:time|hour|routine)\s+is\s+(.{3,40})",
        ]
        for pattern in patterns:
            match = re.search(pattern, msg, re.IGNORECASE)
            if match:
                activity = match.group(1).strip().lower()
                time_info = match.group(2).strip().lower()
                key = f"routine_{activity}"

                self.memory.data.setdefault("routines", {})
                self.memory.data["routines"][key] = {
                    "activity": activity,
                    "time": time_info,
                    "updated": datetime.now().isoformat(),
                }
                self.memory.save()
                return

    # ------------------------------------------------------------------
    # Pattern 6: Emotion / personality observation
    # ------------------------------------------------------------------

    def _detect_emotion(self, msg: str):
        """Detect emotional states to build personality understanding."""
        emotion_map = {
            r"\b(stressed|overwhelmed|anxious|worried|burnt\s*out)\b": "stressed",
            r"\b(excited|pumped|motivated|energized|hyped)\b": "motivated",
            r"\b(tired|exhausted|drained|sleepy|fatigued)\b": "low_energy",
            r"\b(happy|great|amazing|wonderful|fantastic)\b": "positive",
            r"\b(frustrated|stuck|confused|lost|struggling)\b": "struggling",
            r"\b(bored|unmotivated|lazy|procrastinating)\b": "unmotivated",
        }
        for pattern, emotion in emotion_map.items():
            if re.search(pattern, msg, re.IGNORECASE):
                self.memory.data.setdefault("personality_notes", [])
                self.memory.data["personality_notes"].append({
                    "observation": f"User expressed feeling: {emotion}",
                    "raw_message": msg[:100],
                    "timestamp": datetime.now().isoformat(),
                })
                self.memory.save()
                return

    # ------------------------------------------------------------------
    # Pattern 7: Theo work/project knowledge detection
    # ------------------------------------------------------------------

    def _detect_work_knowledge(self, msg: str):
        """Silently store SAP/work/project details in the personal KB."""
        if "?" in msg or re.search(r"\b(where|what|when|why|how|enge|enna)\b", msg, re.IGNORECASE):
            return
        work_patterns = [
            r"i (am|was) working on (.+)",
            r"my (project|task|work) is (.+)",
            r"the (file|folder|path|location) is (.+)",
            r"i (built|created|developed|made) (.+)",
            r"sap (.+)",
            r"portal (.+)",
            r"the (config|settings|setup) (.+)",
        ]
        for pattern in work_patterns:
            match = re.search(pattern, msg, re.IGNORECASE)
            if not match:
                continue
            captured = match.group(match.lastindex).strip()
            lower = msg.lower()
            if any(word in lower for word in ["file", "folder", "path", "location", " at ", "http://", "https://", ":\\"]):
                name = captured.split(" is ")[0][:80] if " is " in captured else "Work location"
                self.personal_kb.store_location(name, captured, msg)
            elif "project" in lower or "working on" in lower or "built" in lower or "created" in lower or "developed" in lower:
                self.personal_kb.store_project(captured[:80], msg, {"source": "conversation_auto_extract"})
            else:
                self.personal_kb.store_work_note("Auto captured work note", msg, ["auto", "work"])
            return

    # ------------------------------------------------------------------
    # Utility: get learning summary
    # ------------------------------------------------------------------

    def get_learning_stats(self) -> dict:
        """Return stats about what the trainer has learned."""
        return {
            "routines_count": len(self.memory.data.get("routines", {})),
            "preferences_count": len(self.memory.data.get("preferences", {})),
            "progress_entries": len(self.memory.data.get("progress_log", [])),
            "personality_observations": len(self.memory.data.get("personality_notes", [])),
            "facts_count": len(self.memory.get_all_facts()),
            "goals_count": len(self.memory.get_goals()),
        }
