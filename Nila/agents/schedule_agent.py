"""Schedule helpers for course tracking."""

from __future__ import annotations

from datetime import date, datetime, timedelta
from pathlib import Path
import json

from core.config import DATA_DIR


class ScheduleAgent:
    """Reads persisted courses and exposes daily/weekly learning schedules."""

    def __init__(self):
        self.courses_dir = Path(DATA_DIR) / "courses"

    def _course_files(self) -> list[Path]:
        self.courses_dir.mkdir(parents=True, exist_ok=True)
        return sorted(self.courses_dir.glob("*.json"))

    def load_courses(self) -> list[dict]:
        courses = []
        for path in self._course_files():
            try:
                courses.append(json.loads(path.read_text(encoding="utf-8")))
            except (OSError, json.JSONDecodeError):
                continue
        return courses

    @staticmethod
    def _iter_days(course: dict):
        for phase in course.get("phases", []):
            for day in phase.get("days", []):
                yield phase, day

    def today_lessons(self) -> list[dict]:
        today = date.today().isoformat()
        lessons = []
        for course in self.load_courses():
            for phase, day in self._iter_days(course):
                if day.get("date") == today:
                    lessons.append({"course": course, "phase": phase, "day": day})
        return lessons

    def week_lessons(self) -> list[dict]:
        start = date.today()
        end = start + timedelta(days=6)
        lessons = []
        for course in self.load_courses():
            for phase, day in self._iter_days(course):
                try:
                    lesson_date = datetime.strptime(day.get("date", ""), "%Y-%m-%d").date()
                except ValueError:
                    continue
                if start <= lesson_date <= end:
                    lessons.append({"course": course, "phase": phase, "day": day})
        return lessons
