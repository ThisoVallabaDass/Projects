"""
DataQueryEngine — Answers data questions directly from JSON files.
No AI needed. Fast. Accurate. Always correct.

This is Priority 1 in the agent pipeline — checked before any AI call.
"""

from __future__ import annotations

import json
import re
from datetime import date
from pathlib import Path

from core.config import DATA_DIR, MEMORY_FILE


# Hard triggers that bypass AI and go straight to the DataQueryEngine
HARD_TRIGGERS = [
    # list_courses
    "how many courses", "what courses", "active courses", "running courses",
    "current courses", "courses i have", "list courses", "show courses",
    "show me all my active courses", "tell the courses", "tell me courses",
    "courses we have", "courses right now", "my courses", "what courses do we have",
    "tell me about courses", "total courses", "how many courses are there",
    "evlo courses", "courses iruka", "enna courses", "courses",
    
    # course_progress
    "progress", "how far", "which day", "completed days", "streak",
    "evlo days panniten", "completion",
    
    # today_lesson
    "today's lesson", "today lesson", "intha vaaram", "enna pananum today",
    "what to do today", "what should i do today", "today",
    
    # list_goals
    "my goals", "what are my goals", "goals list", "en goals", "enna goals",
    "show goals", "goals",
    
    # memory_facts
    "what do you know about me", "my info", "my facts", "enna theriyum unakku",
    "my profile",
    
    # remove_course
    "remove course", "delete course", "cancel course", "remove the", "delete the"
]


class DataQueryEngine:
    """
    Detects data-only questions and answers them directly from local JSON.
    Zero AI calls. Instant response. Always accurate.
    """

    def must_handle(self, user_message: str) -> bool:
        """
        Returns True if the message is a detected data query.
        """
        return self.detect_data_query(user_message) is not None

    QUERY_PATTERNS: dict[str, list[str]] = {
        "list_courses": [
            "how many courses", "what courses", "active courses",
            "running courses", "current courses", "courses i have",
            "list courses", "show courses", "show me all my active courses",
            "tell the courses", "tell me courses", "courses we have",
            "courses right now", "my courses", "what courses do we have",
            "tell me about courses", "total courses", "how many courses are there",
            # Tamil / Tanglish
            "evlo courses", "courses iruka", "enna courses",
        ],
        "course_progress": [
            "progress", "how far", "which day", "completed days",
            "streak", "evlo days panniten", "completion",
        ],
        "today_lesson": [
            "today's lesson", "today lesson", "intha vaaram",
            "enna pananum today", "what to do today", "what should i do today",
        ],
        "list_goals": [
            "my goals", "what are my goals", "goals list",
            "en goals", "enna goals", "show goals",
        ],
        "memory_facts": [
            "what do you know about me", "my info", "my facts",
            "enna theriyum unakku", "my profile",
        ],
        "remove_course": [
            "remove course", "delete course", "cancel course",
            "remove the", "delete the",
        ],
    }

    def __init__(self):
        self.courses_dir = Path(DATA_DIR) / "courses"
        self.courses_dir.mkdir(parents=True, exist_ok=True)

    # ------------------------------------------------------------------
    # Detection
    # ------------------------------------------------------------------

    def detect_data_query(self, user_message: str) -> str | None:
        """
        Returns query type if the message is a pure data query, else None.
        Must be checked BEFORE any AI call.
        """
        msg = user_message.lower().strip()
        words = msg.split()

        # Exact single-word commands
        if msg in {"courses", "progress", "goals", "today"}:
            if msg == "courses":
                return "list_courses"
            if msg == "progress":
                return "course_progress"
            if msg == "goals":
                return "list_goals"
            if msg == "today":
                return "today_lesson"

        for query_type, patterns in self.QUERY_PATTERNS.items():
            for p in patterns:
                # If pattern has no spaces (single word), check for exact word match
                if " " not in p:
                    if p in words:
                        return query_type
                # Otherwise, check substring match in the full message
                else:
                    if p in msg:
                        return query_type
        return None

    # ------------------------------------------------------------------
    # Answers
    # ------------------------------------------------------------------

    def answer(self, query_type: str, user_message: str = "") -> str:
        """Route to the appropriate answer handler."""
        handlers = {
            "list_courses": self._list_courses,
            "course_progress": self._course_progress,
            "today_lesson": self._today_lesson,
            "list_goals": self._list_goals,
            "memory_facts": self._memory_facts,
            "remove_course": lambda: self._remove_course(user_message),
        }
        handler = handlers.get(query_type, lambda: "Unknown data query.")
        return handler()

    # ── Course listing ────────────────────────────────────────────────

    def _list_courses(self) -> str:
        courses = self._load_all_courses()
        if not courses:
            return (
                "Ippo active courses edhuvum illa Theo. "
                "Course create panna `create a course for Python, beginner, 1 hour daily, 3 months` "
                "nu sollu, naan thayaar pannaren! 🎯"
            )

        result = f"📚 Ippo **{len(courses)} course(s)** active-a iruku:\n\n"
        for i, course in enumerate(courses, 1):
            progress = course.get("progress", {})
            completed = progress.get("completed_days", 0)
            total = course.get("total_days", 0)
            streak = progress.get("streak", 0)
            pct = round((completed / total) * 100, 1) if total > 0 else 0
            current_day = progress.get("current_day", 1)

            result += f"**{i}. {course['topic']}**\n"
            result += f"   📅 Duration: {total} days | ✅ Completed: {completed} days ({pct}%)\n"
            result += f"   ⏱️ Daily: {course.get('daily_hours', 1)} hr/day | 📍 Current: Day {current_day}\n"
            if streak > 0:
                result += f"   🔥 Streak: {streak} days\n"
            result += f"   🗓️ Started: {course.get('created_at', 'unknown')}\n\n"

        result += "\nType `today` to see current lesson, or `done day N` to mark complete."
        return result.strip()

    # ── Course progress ───────────────────────────────────────────────

    def _course_progress(self) -> str:
        courses = self._load_all_courses()
        if not courses:
            return "No active courses yet Theo."

        lines = ["📊 **Course Progress:**\n"]
        for course in courses:
            progress = course.get("progress", {})
            completed = progress.get("completed_days", 0)
            total = course.get("total_days", 0)
            pct = progress.get("completion_percentage", 0)
            streak = progress.get("streak", 0)
            current_day = progress.get("current_day", 1)

            # Visual progress bar
            filled = int(pct / 5)
            bar = "█" * filled + "░" * (20 - filled)

            lines.append(f"**{course['topic']}**")
            lines.append(f"  [{bar}] {pct}%")
            lines.append(f"  Day {current_day}/{total} | Streak: {streak} 🔥")
            lines.append("")

        return "\n".join(lines)

    # ── Today's lesson ────────────────────────────────────────────────

    def _today_lesson(self) -> str:
        courses = self._load_all_courses()
        if not courses:
            return "Active courses illa Theo. First course create pannalaam!"

        today_str = date.today().isoformat()
        lessons = []

        for course in courses:
            current_day_num = course.get("progress", {}).get("current_day", 1)
            day = self._find_day(course, current_day_num)
            if day:
                lessons.append((course, day))

        if not lessons:
            return "Today lesson kedaikala. All courses might be complete!"

        parts = []
        for course, day in lessons:
            resources = day.get("resources", [])[:3]
            res_text = "\n".join(f"  - {r.get('type', '?')}: {r.get('title', '?')} ({r.get('url', '')})" for r in resources)
            parts.append(
                f"📖 **{course['topic']}** — Day {day['day']}\n"
                f"Topic: {day.get('topic', '?')}\n"
                f"Subtopics: {', '.join(day.get('subtopics', []))}\n"
                f"Time: {course.get('daily_hours', 1)} hour\n\n"
                f"Resources:\n{res_text}\n\n"
                f"Type `done day {day['day']}` when finished."
            )

        return "\n\n---\n\n".join(parts)

    # ── Goals ─────────────────────────────────────────────────────────

    def _list_goals(self) -> str:
        memory = self._load_memory()
        goals = memory.get("goals", [])
        if not goals:
            return "No goals set yet Theo. Tell me what you want to achieve!"

        active = [g for g in goals if g.get("status") == "active"]
        if not active:
            return "No active goals. All goals may be completed!"

        lines = ["🎯 **Your Active Goals:**\n"]
        for i, g in enumerate(active, 1):
            lines.append(f"{i}. {g['goal']}")
            if g.get("created"):
                lines.append(f"   Added: {g['created'][:10]}")
        return "\n".join(lines)

    # ── Memory facts ──────────────────────────────────────────────────

    def _memory_facts(self) -> str:
        memory = self._load_memory()
        facts = memory.get("facts", {})
        if not facts:
            return "I don't have much info about you yet Theo. Tell me about yourself!"

        lines = ["🧠 **What I know about you:**\n"]
        for key, val in facts.items():
            value = val.get("value", val) if isinstance(val, dict) else val
            lines.append(f"- **{key}**: {value}")

        routines = memory.get("routines", {})
        if routines:
            lines.append("\n**Routines:**")
            for key, val in routines.items():
                lines.append(f"- {val.get('activity', key)}: {val.get('time', '?')}")

        preferences = memory.get("preferences", {})
        if preferences:
            lines.append("\n**Preferences:**")
            for key, val in preferences.items():
                lines.append(f"- {val.get('value', key)}")

        return "\n".join(lines)

    # ── Remove course ─────────────────────────────────────────────────

    def _remove_course(self, user_message: str) -> str:
        courses = self._load_all_courses()
        if not courses:
            return "No courses to remove Theo."

        # Try to find matching course by topic keyword
        msg_lower = user_message.lower()
        # Remove trigger words to extract the topic hint
        for trigger in ["remove course", "delete course", "cancel course", "remove the", "delete the"]:
            msg_lower = msg_lower.replace(trigger, "")
        topic_hint = msg_lower.strip().strip("\"' ")

        if not topic_hint:
            # List courses for user to pick
            course_names = [f"{i+1}. {c['topic']}" for i, c in enumerate(courses)]
            return "Which course should I remove?\n" + "\n".join(course_names) + "\n\nSay `remove course [topic name]`"

        # Find matching course
        for path in sorted(self.courses_dir.glob("*.json"), key=lambda p: p.stat().st_mtime):
            try:
                course = json.loads(path.read_text(encoding="utf-8"))
            except json.JSONDecodeError:
                continue
            if topic_hint in course.get("topic", "").lower() or topic_hint in course.get("course_id", "").lower():
                topic_name = course.get("topic", "Unknown")
                path.unlink()
                return f"✅ Removed course: **{topic_name}**. Course file deleted."

        return f"'{topic_hint}' course kedaikala Theo. Type `courses` to see active courses."

    # ------------------------------------------------------------------
    # Data loaders
    # ------------------------------------------------------------------

    def _load_all_courses(self) -> list[dict]:
        """Load all course JSON files from data/courses/."""
        courses = []
        for path in sorted(self.courses_dir.glob("*.json"), key=lambda p: p.stat().st_mtime):
            try:
                course = json.loads(path.read_text(encoding="utf-8"))
                courses.append(course)
            except json.JSONDecodeError:
                continue
        return courses

    def _load_memory(self) -> dict:
        """Load memory.json."""
        try:
            return json.loads(Path(MEMORY_FILE).read_text(encoding="utf-8"))
        except (json.JSONDecodeError, FileNotFoundError):
            return {}

    @staticmethod
    def _find_day(course: dict, day_number: int) -> dict | None:
        """Find a specific day in a course's phases."""
        for phase in course.get("phases", []):
            for day in phase.get("days", []):
                if int(day.get("day", 0)) == int(day_number):
                    return day
        return None

    def get_course_summary_for_context(self) -> str:
        """
        Build a compact course summary string for injecting into local LLM context.
        Used by agent.py when building Mistral prompts.
        """
        courses = self._load_all_courses()
        if not courses:
            return ""

        lines = [f"ACTIVE COURSES ({len(courses)} total):"]
        for course in courses:
            progress = course.get("progress", {})
            lines.append(
                f"- {course['topic']}: "
                f"Day {progress.get('current_day', 1)}/{course.get('total_days', 0)} "
                f"({progress.get('completion_percentage', 0)}% complete) | "
                f"Streak: {progress.get('streak', 0)} days"
            )
        return "\n".join(lines)
