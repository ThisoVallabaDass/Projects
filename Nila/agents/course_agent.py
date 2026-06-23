"""
Course creation agent for Nila.

Builds topic-specific beginner-friendly courses, persists JSON + Markdown notes,
exports ICS calendars, and collects offline course knowledge for Mistral.
"""

from __future__ import annotations

import json
import re
from datetime import date, datetime, timedelta
from pathlib import Path
from urllib.parse import quote_plus, unquote

from core.config import DATA_DIR
from tools.scraper import scrape_web


DAY_1_TEMPLATE = {
    "day": 1,
    "subtopics": [
        "What problem does this solve?",
        "Real world examples you already know",
        "Key terms explained simply",
        "Why this is worth learning",
        "What you will build by the end",
    ],
    "daily_time_breakdown": {
        "watch": "30 mins - Watch one intro video",
        "read": "15 mins - Read a simple article",
        "think": "15 mins - Write 3 things you found interesting",
    },
    "no_code_today": True,
}


def extract_clean_topic(user_message: str, gemini_client=None) -> str:
    """
    Extract a clean 2-5 word course topic from messy user input.

    Uses Gemini when available, with deterministic cleanup fallback so course
    creation still works during quota/offline moments.
    """
    prompt = f"""Extract only the clean course topic from this user message.
Return ONLY the topic name, nothing else. 2-5 words maximum. Title case.

User message: "{user_message}"

Examples:
"help me learn python" -> Python Programming
"ai and ai agents course" -> AI and AI Agents
"i want flutter development 6 months" -> Flutter Mobile Development
"deep learning neural networks" -> Deep Learning and Neural Networks

Topic:"""
    if gemini_client is not None:
        try:
            if hasattr(gemini_client, "generate"):
                response = gemini_client.generate(prompt, max_tokens=20)
            else:
                response = gemini_client.models.generate_content(
                    model="gemini-2.5-flash",
                    contents=prompt,
                ).text
            cleaned = _sanitize_topic(response)
            if cleaned:
                return cleaned
        except Exception:
            pass
    return _sanitize_topic(user_message)


def extract_course_params(user_message: str, gemini_client=None) -> dict:
    """Extract topic, duration, daily hours, skill level, and focus."""
    lower = user_message.lower()
    day_match = re.search(r"(\d+)\s*days?", lower)
    month_match = re.search(r"(\d+)\s*months?", lower)
    hour_match = re.search(r"(\d+(?:\.\d+)?)\s*(?:hours?|hrs?)", lower)
    minute_match = re.search(r"(\d+)\s*(?:mins?|minutes?)", lower)

    skill_level = "beginner"
    for level in ["complete beginner", "beginner", "intermediate", "advanced"]:
        if level in lower:
            skill_level = level.replace("complete ", "")
            break

    daily_hours = float(hour_match.group(1)) if hour_match else 1.0
    if minute_match:
        daily_hours = int(minute_match.group(1)) / 60

    topic = extract_clean_topic(user_message, gemini_client)
    focus = ""
    focus_match = re.search(r"(?:in depth|deep|advanced|focus(?:ed)? on|about)\s+(.+)", user_message, re.IGNORECASE)
    if focus_match:
        focus = _sanitize_topic(focus_match.group(1))

    return {
        "topic": topic,
        "duration_months": int(month_match.group(1)) if month_match else (None if day_match else 3),
        "duration_days": int(day_match.group(1)) if day_match else None,
        "daily_hours": daily_hours,
        "skill_level": skill_level,
        "goal": focus or "general",
        "specific_focus": focus,
    }


class CourseAgent:
    """Creates complete learning courses with schedules, resources, notes, and ICS."""

    def __init__(self, gemini_client=None):
        self.gemini_client = gemini_client
        self.data_dir = Path(DATA_DIR)
        self.courses_dir = self.data_dir / "courses"
        self.notes_dir = self.data_dir / "notes"
        self.calendars_dir = self.data_dir / "calendars"
        for folder in [self.courses_dir, self.notes_dir, self.calendars_dir]:
            folder.mkdir(parents=True, exist_ok=True)

    def create_course(
        self,
        topic: str,
        duration_months: int | None = None,
        daily_hours: float = 1.0,
        skill_level: str = "beginner",
        duration_days: int | None = None,
        goal: str = "general",
        specific_focus: str = "",
        original_message: str = "",
    ) -> dict:
        """Full course creation pipeline."""
        if original_message:
            params = extract_course_params(original_message, self.gemini_client)
            topic = params["topic"] or topic
            duration_months = params["duration_months"] if duration_months is None else duration_months
            duration_days = params["duration_days"] if duration_days is None else duration_days
            daily_hours = params["daily_hours"] or daily_hours
            skill_level = params["skill_level"] or skill_level
            specific_focus = params["specific_focus"] or specific_focus

        topic = _sanitize_topic(topic) or "Learning"
        total_days = duration_days or max(1, int((duration_months or 3) * 30))
        duration_months = duration_months or max(1, round(total_days / 30))
        daily_hours = max(0.25, float(daily_hours or 1.0))

        research = self.research_topic(topic, skill_level)
        course_id = f"{self._slug(topic)}_{date.today().strftime('%Y_%m_%d')}"
        notes_folder = self.notes_dir / self._slug(topic)
        notes_folder.mkdir(parents=True, exist_ok=True)

        days = self._build_day_schedule(topic, goal, total_days, daily_hours, skill_level, research)
        phases = self._group_into_phases(days, skill_level)
        course = {
            "course_id": course_id,
            "topic": topic,
            "goal": goal,
            "specific_focus": specific_focus,
            "created_at": date.today().isoformat(),
            "duration_months": duration_months,
            "total_days": total_days,
            "daily_hours": daily_hours,
            "skill_level": skill_level,
            "research_summary": research,
            "phases": phases,
            "calendar_file": "",
            "notes_folder": str(notes_folder),
            "progress": {
                "completed_days": 0,
                "current_day": 1,
                "streak": 0,
                "completion_percentage": 0,
                "last_completed_date": None,
            },
        }
        course["calendar_file"] = self.export_to_calendar(course)
        self._write_course(course)
        self._write_notes_templates(course)

        try:
            from training.ollama_trainer import OllamaTrainer
            OllamaTrainer(gemini_client=self.gemini_client).collect_course_knowledge(course)
        except Exception:
            pass

        return course

    def research_topic(self, topic: str, skill_level: str = "beginner") -> dict:
        """Scrape real data for the course and return structured research."""
        searches = [
            f"best way to learn {topic} from scratch 2025 2026",
            f"{topic} complete roadmap beginner to advanced",
            f"best free {topic} courses YouTube tutorials",
            f"{topic} official documentation getting started",
            f"{topic} practice projects for beginners",
            f"how long to learn {topic} realistically",
        ]
        results = []
        scraped_text_parts = []
        for query in searches:
            try:
                text = scrape_web(query=query)
            except Exception as exc:
                text = f"Search failed: {exc}"
            results.append({"query": query, "result": text[:2500]})
            scraped_text_parts.append(f"QUERY: {query}\n{text[:2500]}")

        found_resources = self._extract_researched_resources(topic, results)
        return {
            "topic": topic,
            "skill_level": skill_level,
            "searched_at": datetime.now().isoformat(),
            "queries": searches,
            "results": results,
            "research_summary": "\n\n".join(scraped_text_parts)[:10000],
            "found_resources": found_resources,
            "resources": found_resources,
        }

    def export_to_calendar(self, course: dict) -> str:
        """Generate ICS file that can be imported into calendar apps."""
        filepath = self.calendars_dir / f"{course['course_id']}.ics"
        lines = [
            "BEGIN:VCALENDAR",
            "VERSION:2.0",
            "PRODID:-//Nila//YearZero//EN",
            "CALSCALE:GREGORIAN",
            "METHOD:PUBLISH",
        ]
        minutes = int(float(course.get("daily_hours", 1)) * 60)
        for phase in course["phases"]:
            for day in phase["days"]:
                start = f"{day['date'].replace('-', '')}T080000"
                dt = datetime.strptime(day["date"] + " 08:00", "%Y-%m-%d %H:%M")
                end = (dt + timedelta(minutes=minutes)).strftime("%Y%m%dT%H%M%S")
                uid = f"{course['course_id']}-day-{day['day']}@nila"
                description = self._ics_escape(
                    f"{day.get('what_you_will_learn', '')}\\nResources: {len(day['resources'])} items"
                )
                lines.extend([
                    "BEGIN:VEVENT",
                    f"UID:{uid}",
                    f"DTSTAMP:{datetime.utcnow().strftime('%Y%m%dT%H%M%SZ')}",
                    f"DTSTART:{start}",
                    f"DTEND:{end}",
                    f"SUMMARY:{self._ics_escape(course['topic'] + ' - Day ' + str(day['day']) + ': ' + day['topic'])}",
                    f"DESCRIPTION:{description}",
                    "CATEGORIES:YearZero,Learning",
                    "STATUS:CONFIRMED",
                    "END:VEVENT",
                ])
        lines.append("END:VCALENDAR")
        filepath.write_text("\n".join(lines) + "\n", encoding="utf-8")
        return str(filepath)

    def generate_day_notes(self, course_id: str, day_number: int, user_summary: str) -> str:
        """Generate structured markdown notes from the day's topic and user summary."""
        course = self.load_course(course_id)
        if not course:
            return ""
        day = self.find_day(course, day_number)
        if not day:
            return ""
        folder = Path(course["notes_folder"])
        folder.mkdir(parents=True, exist_ok=True)
        content = (
            f"# Day {day_number}: {day['topic']}\n\n"
            f"## What I studied\n{user_summary.strip()}\n\n"
            f"## What I was supposed to learn\n{day.get('what_you_will_learn', '')}\n\n"
            "## Key concepts\n"
            + "\n".join(f"- {item}" for item in day.get("subtopics", []))
            + "\n\n## Quiz answers\n"
            + "\n".join(f"- {q}" for q in day.get("end_of_day_quiz", day.get("verification_quiz", [])))
            + "\n"
        )
        path = folder / f"day_{day_number}.md"
        path.write_text(content, encoding="utf-8")
        return str(path)

    def load_course(self, course_id: str) -> dict | None:
        path = self.courses_dir / f"{course_id}.json"
        if not path.exists():
            matches = list(self.courses_dir.glob(f"*{self._slug(course_id)}*.json"))
            path = matches[-1] if matches else path
        if not path.exists():
            return None
        try:
            course = json.loads(path.read_text(encoding="utf-8"))
            if "notes_folder" in course:
                old_path = Path(course["notes_folder"])
                course["notes_folder"] = str(self.notes_dir / old_path.name)
            if "calendar_file" in course and course["calendar_file"]:
                old_path = Path(course["calendar_file"])
                course["calendar_file"] = str(self.calendars_dir / old_path.name)
            return course
        except Exception:
            return None

    def list_courses(self) -> list[dict]:
        courses = []
        for path in sorted(self.courses_dir.glob("*.json")):
            try:
                course = json.loads(path.read_text(encoding="utf-8"))
                if "notes_folder" in course:
                    old_path = Path(course["notes_folder"])
                    course["notes_folder"] = str(self.notes_dir / old_path.name)
                if "calendar_file" in course and course["calendar_file"]:
                    old_path = Path(course["calendar_file"])
                    course["calendar_file"] = str(self.calendars_dir / old_path.name)
                courses.append(course)
            except Exception:
                continue
        return courses

    def generate_daily_todo(self, course_id: str = None) -> str:
        """
        Generate today's to-do list from all active courses.
        Shows what to do, time estimates, and links/resources.
        """
        courses = self.list_courses()

        if not courses:
            return "📝 No active courses. Create one with 'create a course for [topic]'."

        today = datetime.now().strftime("%A, %B %d, %Y")
        todos = []

        # Collect all active lessons for today
        for course in courses:
            progress = course.get("progress", {})
            completed_days = progress.get("completed_days", 0)
            current_day = completed_days + 1
            total_days = course.get("total_days", 90)

            # Skip if course is complete
            if current_day > total_days:
                continue

            # Find today's lesson
            today_lesson = self.find_day(course, current_day)

            if today_lesson:
                todos.append({
                    "course": course["topic"],
                    "course_id": course["course_id"],
                    "day": current_day,
                    "total": total_days,
                    "topic": today_lesson.get("topic", "Untitled"),
                    "subtopics": today_lesson.get("subtopics", []),
                    "resources": today_lesson.get("resources", []),
                    "duration_minutes": int(course.get("daily_hours", 1) * 60),
                    "quiz": today_lesson.get("end_of_day_quiz", today_lesson.get("verification_quiz", [])),
                    "date": today_lesson.get("date", today),
                })

        if not todos:
            return "✅ All courses complete or no lessons scheduled for today!"

        # Format as clean to-do list
        output = [f"📋 TODAY'S TO-DO LIST — {today}\n"]
        output.append("=" * 65)

        total_minutes = 0
        for i, todo in enumerate(todos, 1):
            output.append(f"\n✅ TASK {i}: {todo['course']}")
            output.append(f"   📚 Day {todo['day']}/{todo['total']}")
            output.append(f"   📖 Topic: {todo['topic']}")
            output.append(f"   ⏱️  Duration: {todo['duration_minutes']} minutes")
            total_minutes += todo['duration_minutes']

            if todo["subtopics"]:
                output.append(f"   🎯 Today covers:")
                for sub in todo["subtopics"][:4]:
                    output.append(f"      • {sub}")

            if todo["resources"]:
                output.append(f"   🔗 Resources:")
                for res in todo["resources"][:2]:
                    if isinstance(res, dict):
                        title = res.get('title', 'Resource')
                        res_type = res.get('type', 'link').upper()
                        output.append(f"      [{res_type}] {title}")
                        if res.get("url"):
                            output.append(f"      → {res.get('url', '')[:70]}")

            if todo["quiz"]:
                output.append(f"   🧠 Quiz: {len(todo['quiz'])} questions at end of day")

        output.append("\n" + "=" * 65)
        output.append(f"\n📊 Total study time today: {total_minutes} minutes")
        output.append("\n💡 Type 'done' when you finish a task!")

        return "\n".join(output)

    def find_day(self, course: dict, day_number: int) -> dict | None:
        for phase in course.get("phases", []):
            for day in phase.get("days", []):
                if int(day.get("day", 0)) == int(day_number):
                    return day
        return None

    def mark_complete(self, day_number: int, course_hint: str = "") -> tuple[dict | None, dict | None, dict | None]:
        from agents.progress_tracker import ProgressTracker

        tracker = ProgressTracker()
        courses = tracker.list_courses(course_hint)
        if not courses:
            return None, None, None
        course = courses[-1]
        result = tracker.complete_day(course["course_id"], day_number)
        return result.get("course"), result.get("completed_day"), result.get("next_day")

    def _build_day_schedule(self, topic: str, goal: str, total_days: int, daily_hours: float, skill_level: str, research: dict) -> list[dict]:
        generated = self._try_gemini_schedule(topic, total_days, daily_hours, skill_level, research)
        if generated:
            return self._normalize_generated_days(generated, topic, total_days, daily_hours, research)

        days = []
        start_date = date.today() + timedelta(days=1)
        for day_number in range(1, total_days + 1):
            lesson_date = start_date + timedelta(days=day_number - 1)
            day = self._make_day(topic, goal, day_number, total_days, daily_hours, research)
            day["date"] = lesson_date.isoformat()
            days.append(day)
        return days

    def _try_gemini_schedule(self, topic: str, total_days: int, daily_hours: float, skill_level: str, research: dict) -> list[dict]:
        if self.gemini_client is None or total_days > 30:
            return []
        schedule_prompt = f"""
You are building a complete learning course for: {topic}
Skill level: {skill_level}
Duration: {total_days} days
Daily time: {daily_hours} hours

Research data gathered from the web:
{research.get('research_summary', '')[:6000]}

Create a detailed day-by-day curriculum. Follow these rules:
- Day 1 MUST be: "What is {topic}? - Complete Beginner Introduction"
- Day 2 MUST be: "Setting up your environment / tools"
- Days 1-7: Only concepts, no complex code or math
- Days 8-30: Fundamentals with hands-on exercises
- Days 31-60: Intermediate projects
- Days 61-90: Advanced topics and real projects

For each day return: day, topic, subtopics, what_you_will_learn,
beginner_friendly_intro, resources, end_of_day_quiz, success_metric.
Return ONLY a JSON array of all {total_days} days.
"""
        try:
            response = self.gemini_client.models.generate_content(
                model="gemini-2.5-flash",
                contents=schedule_prompt,
            ).text
            match = re.search(r"\[[\s\S]+\]", response)
            return json.loads(match.group(0) if match else response)
        except Exception:
            return []

    def _normalize_generated_days(self, generated: list[dict], topic: str, total_days: int, daily_hours: float, research: dict) -> list[dict]:
        days = []
        start_date = date.today() + timedelta(days=1)
        for idx in range(total_days):
            raw = generated[idx] if idx < len(generated) else {}
            day_number = idx + 1
            day = self._make_day(topic, "general", day_number, total_days, daily_hours, research)
            day.update({k: v for k, v in raw.items() if v})
            day["day"] = day_number
            day["date"] = (start_date + timedelta(days=idx)).isoformat()
            if day_number == 1:
                day.update(self._day_1(topic, daily_hours, research))
            day["resources"] = self.find_real_resources(day["topic"], topic, research)
            days.append(day)
        return days

    def _make_day(self, topic: str, goal: str, day_number: int, total_days: int, daily_hours: float, research: dict) -> dict:
        if day_number == 1:
            return self._day_1(topic, daily_hours, research)
        phase = self._phase_for_day(day_number)
        lesson_topic = self._lesson_topic(topic, goal, day_number, total_days, phase)
        subtopics = self._subtopics(topic, lesson_topic, phase)
        return {
            "day": day_number,
            "topic": lesson_topic,
            "subtopics": subtopics,
            "what_you_will_learn": f"You will understand {lesson_topic.lower()} and do one small practical step.",
            "beginner_friendly_intro": self._beginner_intro(topic, lesson_topic, day_number),
            "daily_time_breakdown": self._time_breakdown(daily_hours),
            "duration_minutes": int(daily_hours * 60),
            "resources": self.find_real_resources(lesson_topic, topic, research),
            "notes_template": self._notes_template(day_number, lesson_topic),
            "end_of_day_quiz": self._quiz(topic, lesson_topic, subtopics),
            "verification_quiz": self._quiz(topic, lesson_topic, subtopics),
            "success_metric": f"You can explain {lesson_topic.lower()} in 3 simple sentences and give one example.",
            "status": "pending",
            "started_at": None,
            "completed_at": None,
            "quiz_answers": [],
            "notes": "",
            "score": None,
        }

    def _day_1(self, topic: str, daily_hours: float, research: dict) -> dict:
        day = dict(DAY_1_TEMPLATE)
        day.update({
            "topic": f"What is {topic}? - The Big Picture",
            "what_you_will_learn": f"You will understand what {topic} means, why people use it, and what you can build later.",
            "beginner_friendly_intro": (
                f"Before writing any code or doing any exercises, today is just about understanding what {topic} is. "
                "Think of it like watching a movie trailer before the actual movie. No stress, no pressure."
            ),
            "duration_minutes": int(daily_hours * 60),
            "resources": self.find_real_resources(f"What is {topic}", topic, research),
            "notes_template": self._notes_template(1, f"What is {topic}? - The Big Picture"),
            "end_of_day_quiz": [
                f"In your own words, what is {topic}?",
                "Give one real-world example of it being used",
                "What are you most curious about learning?",
            ],
            "verification_quiz": [
                f"In your own words, what is {topic}?",
                "Give one real-world example of it being used",
                "What are you most curious about learning?",
            ],
            "success_metric": f"You can explain {topic} to a friend without using jargon.",
            "status": "pending",
            "started_at": None,
            "completed_at": None,
            "quiz_answers": [],
            "notes": "",
            "score": None,
        })
        return day

    def find_real_resources(self, day_topic: str, course_topic: str, research: dict | None = None) -> list[dict]:
        """Find actual useful URLs for this day's topic."""
        resources = []
        pool = list((research or {}).get("found_resources", []))
        lower_day = day_topic.lower()
        lower_course = course_topic.lower()

        for item in pool:
            blob = f"{item.get('title', '')} {item.get('url', '')}".lower()
            if any(term in blob for term in _keywords(lower_course)) or any(term in blob for term in _keywords(lower_day)):
                resources.append(item)
            if len(resources) >= 3:
                break

        curated = self._curated_resources(course_topic)
        for item in curated:
            if item["url"] not in {r["url"] for r in resources}:
                resources.append(item)
            if len(resources) >= 3:
                break

        encoded = quote_plus(f"{course_topic} {day_topic} tutorial beginner")
        resources.append({
            "type": "video",
            "title": f"YouTube search: {day_topic}",
            "url": f"https://www.youtube.com/results?search_query={encoded}",
            "why": "Use this to pick a beginner-friendly video for today's exact topic.",
        })
        return resources[:4]

    def _group_into_phases(self, days: list[dict], skill_level: str) -> list[dict]:
        phase_names = self._phase_names(skill_level)
        phase_count = min(4, max(1, len(days)))
        phase_size = max(1, len(days) // phase_count)
        phases = []
        for idx in range(phase_count):
            start = idx * phase_size
            end = (idx + 1) * phase_size if idx < phase_count - 1 else len(days)
            phase_days = days[start:end]
            phases.append({
                "phase": idx + 1,
                "name": phase_names[idx],
                "duration_weeks": max(1, round(len(phase_days) / 7)),
                "days": phase_days,
            })
        return phases

    def _write_course(self, course: dict):
        path = self.courses_dir / f"{course['course_id']}.json"
        path.write_text(json.dumps(course, indent=2, ensure_ascii=False), encoding="utf-8")

    def _write_notes_templates(self, course: dict):
        folder = Path(course["notes_folder"])
        folder.mkdir(parents=True, exist_ok=True)
        for phase in course["phases"]:
            for day in phase["days"]:
                path = folder / f"day_{day['day']}.md"
                if not path.exists():
                    path.write_text(day["notes_template"], encoding="utf-8")

    @staticmethod
    def _slug(text: str) -> str:
        slug = re.sub(r"[^a-zA-Z0-9]+", "_", text.lower()).strip("_")
        return slug or "course"

    @staticmethod
    def _ics_escape(text: str) -> str:
        return text.replace("\\", "\\\\").replace(",", "\\,").replace(";", "\\;").replace("\n", "\\n")

    @staticmethod
    def _phase_names(skill_level: str) -> list[str]:
        if "intermediate" in skill_level.lower():
            return ["Refresh", "Applied Practice", "Projects", "Mastery"]
        return ["Foundations", "Core Skills", "Applied Practice", "Projects and Review"]

    @staticmethod
    def _phase_for_day(day_number: int) -> int:
        if day_number <= 7:
            return 0
        if day_number <= 30:
            return 1
        if day_number <= 60:
            return 2
        return 3

    @staticmethod
    def _lesson_topic(topic: str, goal: str, day: int, total_days: int, phase_idx: int) -> str:
        if day == 2:
            return f"Setting up your {topic} learning environment and tools"
        early = [
            "Key terms and mental models",
            "Real-world use cases",
            "How the main workflow works",
            "Common myths and mistakes",
            "Simple hands-on exploration",
            "Week 1 recap and mini reflection",
        ]
        if 3 <= day <= 7:
            return f"{topic}: {early[day - 3]}"
        if phase_idx == 1:
            concepts = ["core building blocks", "basic workflow", "hands-on exercise", "guided mini project", "debugging and review"]
            return f"{topic} {concepts[(day - 8) % len(concepts)]}"
        if phase_idx == 2:
            projects = ["intermediate project planning", "building a practical project", "evaluation and improvement", "tool usage", "case study"]
            return f"{topic} {projects[(day - 31) % len(projects)]}"
        advanced = ["advanced architecture", "real-world project", "deployment thinking", "best practices", "portfolio polish"]
        return f"{topic} {advanced[(day - 61) % len(advanced)]}"

    @staticmethod
    def _subtopics(topic: str, lesson_topic: str, phase_idx: int) -> list[str]:
        generic = [
            ["plain-English definition", "real examples", "important vocabulary"],
            ["core idea", "simple exercise", "common beginner mistake"],
            ["project goal", "step-by-step plan", "testing your result"],
            ["advanced pattern", "tradeoffs", "real-world usage"],
        ]
        return generic[min(phase_idx, len(generic) - 1)]

    @staticmethod
    def _beginner_intro(topic: str, lesson_topic: str, day_number: int) -> str:
        if day_number <= 7:
            return f"Today is still concept-first. Imagine {topic} as a new tool you are learning to recognize before you start building with it."
        return f"Today you will take one small practical step with {lesson_topic}. Keep it simple and focus on understanding the idea."

    @staticmethod
    def _time_breakdown(daily_hours: float) -> dict:
        minutes = int(daily_hours * 60)
        watch = max(10, round(minutes * 0.5))
        read = max(5, round(minutes * 0.25))
        practice = max(5, minutes - watch - read)
        return {
            "watch": f"{watch} mins - Watch one focused lesson",
            "read": f"{read} mins - Read or skim one simple explanation",
            "practice": f"{practice} mins - Do the tiny task or write notes",
        }

    def _extract_researched_resources(self, topic: str, results: list[dict]) -> list[dict]:
        resources = []
        seen = set()
        known_platforms = {
            "video": ["youtube.com/watch", "youtu.be", "youtube.com/@"],
            "course": ["coursera.org", "udemy.com", "edx.org", "freecodecamp.org"],
            "docs": ["docs.", "documentation", "official", "developers.google.com", "openai.com"],
            "practice": ["leetcode.com", "hackerrank.com", "kaggle.com", "replit.com"],
            "article": ["medium.com", "towardsdatascience.com", "dev.to", "ibm.com", "nvidia.com", "microsoft.com"],
        }
        for item in results:
            text = item.get("result", "")
            blocks = re.split(r"\n\s*\n", text)
            for block in blocks:
                title_match = re.search(r"###\s*(.+)", block)
                url_match = re.search(r"URL:\s*(\S+)", block)
                if not url_match:
                    continue
                url = _unwrap_url(url_match.group(1).strip())
                if url in seen or "duckduckgo.com" in url:
                    continue
                title = title_match.group(1).strip() if title_match else f"{topic} resource"
                kind = "article"
                lower = f"{title} {url}".lower()
                for platform_kind, patterns in known_platforms.items():
                    if any(pattern in lower for pattern in patterns):
                        kind = platform_kind
                        break
                seen.add(url)
                resources.append({"type": kind, "title": title, "url": url, "why": f"Useful for learning {topic}."})
                if len(resources) >= 10:
                    break
            if len(resources) >= 10:
                break
        return resources or self._curated_resources(topic) or self._generic_resources(topic)

    def _generic_resources(self, topic: str) -> list[dict]:
        q = quote_plus(topic)
        return [
            {"type": "video", "title": f"{topic} tutorials on YouTube", "url": f"https://www.youtube.com/results?search_query={q}+beginner+tutorial", "why": "Find a beginner video."},
            {"type": "article", "title": f"{topic} beginner guide", "url": f"https://www.google.com/search?q={q}+beginner+guide", "why": "Read a beginner explanation."},
            {"type": "practice", "title": f"{topic} beginner practice", "url": f"https://www.google.com/search?q={q}+beginner+practice+project", "why": "Try a small practice task."},
        ]

    @staticmethod
    def _curated_resources(topic: str) -> list[dict]:
        lower = topic.lower()
        if "agent" in lower and "ai" in lower:
            return [
                {"type": "article", "title": "OpenAI Agents SDK Documentation", "url": "https://openai.github.io/openai-agents-python/", "why": "Official agent-building docs."},
                {"type": "article", "title": "OpenAI Guide to Building Agents", "url": "https://platform.openai.com/docs/guides/agents", "why": "Practical agent concepts and patterns."},
                {"type": "article", "title": "Google Agents Whitepaper", "url": "https://www.kaggle.com/whitepaper-agents", "why": "Clear conceptual overview of AI agents."},
                {"type": "video", "title": "YouTube: AI Agents Beginner Tutorials", "url": "https://www.youtube.com/results?search_query=AI+agents+explained+for+beginners", "why": "Pick a beginner-friendly visual explanation."},
                {"type": "practice", "title": "LangChain Agents Documentation", "url": "https://python.langchain.com/docs/concepts/agents/", "why": "Hands-on agent framework concepts."},
            ]
        if "python" in lower and ("data" in lower or "science" in lower):
            return [
                {"type": "video", "title": "freeCodeCamp Python for Data Science", "url": "https://www.youtube.com/@freecodecamp/search?query=python%20data%20science", "why": "Long beginner-friendly course videos."},
                {"type": "article", "title": "Python Official Tutorial", "url": "https://docs.python.org/3/tutorial/", "why": "Official Python foundation."},
                {"type": "article", "title": "pandas User Guide", "url": "https://pandas.pydata.org/docs/user_guide/", "why": "Core data analysis library."},
                {"type": "practice", "title": "Kaggle Learn", "url": "https://www.kaggle.com/learn", "why": "Practical notebook exercises."},
            ]
        if "english" in lower or "grammar" in lower or "parts of speech" in lower:
            return [
                {"type": "video", "title": "Khan Academy Grammar", "url": "https://www.khanacademy.org/humanities/grammar", "why": "Beginner grammar lessons."},
                {"type": "article", "title": "Purdue OWL Grammar", "url": "https://owl.purdue.edu/owl/general_writing/grammar/index.html", "why": "Reliable grammar reference."},
                {"type": "practice", "title": "Perfect English Grammar Exercises", "url": "https://www.perfect-english-grammar.com/grammar-exercises.html", "why": "Practice questions."},
            ]
        if "sap" in lower:
            return [
                {"type": "article", "title": "SAP Help Portal", "url": "https://help.sap.com/", "why": "Official SAP documentation."},
                {"type": "article", "title": "SAP Community", "url": "https://community.sap.com/", "why": "Real SAP examples and fixes."},
                {"type": "practice", "title": "SAP Tutorials", "url": "https://developers.sap.com/tutorials.html", "why": "Hands-on SAP tutorials."},
            ]
        return []

    @staticmethod
    def _notes_template(day: int, lesson_topic: str) -> str:
        return (
            f"## Day {day}: {lesson_topic}\n\n"
            "### Key concepts\n- \n\n"
            "### What I understood\n- \n\n"
            "### Examples\n```\n\n```\n\n"
            "### Questions I have\n- \n"
        )

    @staticmethod
    def _quiz(topic: str, lesson_topic: str, subtopics: list[str]) -> list[str]:
        first = subtopics[0] if subtopics else "the main idea"
        return [
            f"What does {first} mean in {topic}?",
            f"Explain {lesson_topic} in your own words.",
            f"What is one real-world example of today's idea?",
        ]


def _sanitize_topic(text: str) -> str:
    raw = (text or "").strip().strip('"').strip("'")
    raw = re.sub(r"(?i)\b(no not|not|instead|actually|its|it's|i wanna|i want to|i want|i need to|can you|course|learn|learning|teach me|help me|in depth|about them|about it|for me|for\?)\b", " ", raw)
    raw = re.sub(r"(?i)\b(beginner|intermediate|advanced|complete beginner|daily|per day|every day|months?|days?|hours?|hrs?|minutes?|mins?)\b", " ", raw)
    raw = re.sub(r"\d+(?:\.\d+)?", " ", raw)
    raw = re.sub(r"[^a-zA-Z0-9+#.\s&-]", " ", raw)
    raw = re.sub(r"\s+", " ", raw).strip(" -")
    lower = raw.lower()
    if ("ai" in lower or "artificial intelligence" in lower) and "agent" in lower:
        return "AI and AI Agents"
    if "flutter" in lower and "mobile" in lower:
        return "Flutter Mobile Development"
    if "aws" in lower or ("cloud" in lower and "comput" in lower):
        return "AWS Cloud Computing" if "aws" in lower else "Cloud Computing"
    if "deep learning" in lower or "neural" in lower:
        return "Deep Learning and Neural Networks"
    if "python" in lower and ("data" in lower or "science" in lower):
        return "Python for Data Science"
    if lower == "python":
        return "Python Programming"
    if not raw:
        return ""
    words = raw.split()
    topic = " ".join(words[:5])
    return _smart_title(topic)


def _smart_title(text: str) -> str:
    acronyms = {"ai": "AI", "ml": "ML", "api": "API", "aws": "AWS", "sap": "SAP", "ui5": "UI5"}
    titled = []
    for word in text.split():
        key = word.lower().strip()
        titled.append(acronyms.get(key, word[:1].upper() + word[1:].lower()))
    return " ".join(titled)


def _keywords(text: str) -> list[str]:
    return [w for w in re.findall(r"[a-zA-Z0-9]+", text.lower()) if len(w) > 2]


def _unwrap_url(url: str) -> str:
    if "uddg=" in url:
        match = re.search(r"uddg=([^&]+)", url)
        if match:
            return unquote(match.group(1))
    return url
