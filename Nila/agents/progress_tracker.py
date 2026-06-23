"""Daily course progress tracking for Nila."""

from __future__ import annotations

import json
from datetime import date, datetime, timedelta
from pathlib import Path

from core.config import DATA_DIR


class ProgressTracker:
    """Tracks course day status, quiz answers, notes, streaks, and summaries."""

    def __init__(self):
        self.courses_dir = Path(DATA_DIR) / "courses"
        self.courses_dir.mkdir(parents=True, exist_ok=True)

    def start_day(self, course_id: str, day_number: int) -> dict:
        """Mark a day as started. Return today's full content."""
        course, path = self._load_course(course_id)
        if not course:
            return {}
        day = self._find_day(course, day_number)
        if not day:
            return {}
        day["status"] = "started"
        day["started_at"] = day.get("started_at") or datetime.now().isoformat()
        self._save(path, course)
        return {"course": course, "day": day}

    def complete_day(self, course_id: str, day_number: int, quiz_answers: list | None = None, notes: str | None = None) -> dict:
        """
        Mark day complete, store quiz answers/notes, calculate streak, unlock next day.
        """
        course, path = self._load_course(course_id)
        if not course:
            return {}
        day = self._find_day(course, day_number)
        if not day:
            return {"course": course}

        already_completed = day.get("status") == "completed"
        day["status"] = "completed"
        day["completed_at"] = datetime.now().isoformat()
        day["quiz_answers"] = quiz_answers or day.get("quiz_answers", [])
        day["notes"] = notes or day.get("notes", "")

        progress = course.setdefault("progress", {})
        if not already_completed:
            progress["completed_days"] = min(course.get("total_days", 0), progress.get("completed_days", 0) + 1)
        progress["current_day"] = min(course.get("total_days", day_number), day_number + 1)
        progress["streak"] = self._calculate_streak(course, day)
        progress["last_completed_date"] = date.today().isoformat()
        total_days = max(1, course.get("total_days", 1))
        progress["completion_percentage"] = round(progress.get("completed_days", 0) / total_days * 100, 2)

        next_day = self._find_day(course, day_number + 1)
        if next_day and next_day.get("status") == "locked":
            next_day["status"] = "pending"

        self._save(path, course)
        return {
            "course": course,
            "completed_day": day,
            "next_day": next_day,
            "message": self._completion_message(course, day, next_day),
        }

    def get_today(self, course_id: str | None = None) -> dict:
        """Return today's lesson for all active courses."""
        today = date.today().isoformat()
        lessons = []
        courses = self.list_courses(course_id)
        if course_id is None and courses:
            courses = [courses[-1]]
        for course in courses:
            selected = None
            for _, day in self._iter_days(course):
                if day.get("date") == today and day.get("status") != "completed":
                    selected = day
                    break
            if not selected:
                current_day = course.get("progress", {}).get("current_day", 1)
                selected = self._find_day(course, current_day)
            if selected:
                lessons.append({
                    "course_id": course.get("course_id"),
                    "course": course.get("topic"),
                    "day": selected.get("day"),
                    "topic": selected.get("topic"),
                    "status": selected.get("status", "pending"),
                    "time_required": f"{course.get('daily_hours', 1)} hour",
                    "resources": selected.get("resources", []),
                    "quiz": selected.get("end_of_day_quiz", selected.get("verification_quiz", [])),
                    "content": selected,
                    "course_data": course,
                })
        return {"date": today, "lessons": lessons}

    def get_streak(self, course_id: str) -> int:
        """Return current streak in days."""
        course, _ = self._load_course(course_id)
        if not course:
            return 0
        return int(course.get("progress", {}).get("streak", 0))

    def get_progress_summary(self) -> str:
        """Return formatted progress for all courses."""
        courses = self.list_courses()
        if not courses:
            return "No active courses yet."
        lines = []
        for course in courses:
            progress = course.get("progress", {})
            lines.append(
                f"{course.get('topic')}: Day {progress.get('current_day', 1)}/{course.get('total_days', 0)} "
                f"({progress.get('completion_percentage', 0)}%) | Streak: {progress.get('streak', 0)} days"
            )
        return "\n".join(lines)

    def get_day(self, course_hint: str, day_number: int) -> dict:
        """Return a specific day by course hint."""
        courses = self.list_courses(course_hint)
        if not courses:
            return {}
        course = courses[-1]
        day = self._find_day(course, day_number)
        return {"course": course, "day": day} if day else {}

    def list_courses(self, course_hint: str | None = None) -> list[dict]:
        courses = []
        paths = sorted(self.courses_dir.glob("*.json"), key=lambda p: p.stat().st_mtime)
        for path in paths:
            try:
                course = json.loads(path.read_text(encoding="utf-8"))
                if "notes_folder" in course:
                    old_path = Path(course["notes_folder"])
                    course["notes_folder"] = str(Path(DATA_DIR) / "notes" / old_path.name)
                if "calendar_file" in course and course["calendar_file"]:
                    old_path = Path(course["calendar_file"])
                    course["calendar_file"] = str(Path(DATA_DIR) / "calendars" / old_path.name)
            except Exception:
                continue
            if course_hint:
                hint = course_hint.lower()
                if hint not in course.get("topic", "").lower() and hint not in course.get("course_id", "").lower():
                    continue
            courses.append(course)
        return courses

    def latest_course(self) -> dict | None:
        courses = self.list_courses()
        return courses[-1] if courses else None

    def _load_course(self, course_id: str) -> tuple[dict | None, Path | None]:
        path = self.courses_dir / f"{course_id}.json"
        if not path.exists():
            matches = list(self.courses_dir.glob(f"*{self._slug(course_id)}*.json"))
            path = matches[-1] if matches else path
        if not path.exists():
            return None, None
        try:
            course = json.loads(path.read_text(encoding="utf-8"))
            if "notes_folder" in course:
                old_path = Path(course["notes_folder"])
                course["notes_folder"] = str(Path(DATA_DIR) / "notes" / old_path.name)
            if "calendar_file" in course and course["calendar_file"]:
                old_path = Path(course["calendar_file"])
                course["calendar_file"] = str(Path(DATA_DIR) / "calendars" / old_path.name)
            return course, path
        except Exception:
            return None, None

    @staticmethod
    def _save(path: Path | None, course: dict):
        if path:
            path.write_text(json.dumps(course, indent=2, ensure_ascii=False), encoding="utf-8")

    @staticmethod
    def _iter_days(course: dict):
        for phase in course.get("phases", []):
            for day in phase.get("days", []):
                yield phase, day

    def _find_day(self, course: dict, day_number: int) -> dict | None:
        for _, day in self._iter_days(course):
            if int(day.get("day", 0)) == int(day_number):
                return day
        return None

    @staticmethod
    def _calculate_streak(course: dict, completed_day: dict) -> int:
        progress = course.setdefault("progress", {})
        last = progress.get("last_completed_date")
        today = date.today()
        if not last:
            return 1
        try:
            last_date = datetime.strptime(last, "%Y-%m-%d").date()
        except ValueError:
            return 1
        if last_date == today:
            return max(1, int(progress.get("streak", 0)))
        if last_date == today - timedelta(days=1):
            return int(progress.get("streak", 0)) + 1
        return 1

    @staticmethod
    def _completion_message(course: dict, day: dict, next_day: dict | None) -> str:
        streak = course.get("progress", {}).get("streak", 0)
        if next_day:
            return (
                f"Day {day['day']} complete! Streak: {streak} day(s).\n"
                f"Next: Day {next_day['day']} - {next_day['topic']}"
            )
        return f"{course.get('topic')} course complete! Streak: {streak} day(s)."

    @staticmethod
    def _slug(text: str) -> str:
        import re
        return re.sub(r"[^a-zA-Z0-9]+", "_", text.lower()).strip("_")
