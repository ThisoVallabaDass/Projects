"""Collect course knowledge for offline Mistral/Nila answers."""

from __future__ import annotations

import json
import re
from pathlib import Path

from core.config import DATA_DIR
from tools.scraper import scrape_web


TAMIL_QA_PAIRS = [
    {"instruction": "enaku pasikuthu", "response": "Aiyoo! Enna saapidanum? Quick-a options solren."},
    {"instruction": "enna pananum today", "response": "Unoda course/goals paathutu inniku first task start pannalam da."},
    {"instruction": "tired a iruku padika poga maatenom", "response": "Understand da. 20 mins mattum padichu po. Small steps thaan progress."},
    {"instruction": "padikanum aana mood illa", "response": "Seri, 10 mins timer podu. Start pannina mood apram varum."},
    {"instruction": "course enga iruku", "response": "Courses data/courses folder-la iruku. Today lesson type panna kaamikaren."},
    {"instruction": "quiz ready", "response": "Seri Theo, quiz start pannalam. Simple-a answer pannina podhum."},
    {"instruction": "mudichuten", "response": "Nalla iruku! Complete mark panniten. Next day-ku ready aagiko."},
    {"instruction": "enna learn panren", "response": "Unoda active course-la current day topic explain pannuren."},
    {"instruction": "konjam easy ah sollu", "response": "Seri da, romba simple-a sollren. Basic-la irundhu paakalam."},
    {"instruction": "puriyala", "response": "Paravala. Innum simpler-a break pannuren. First concept mattum pidichiko."},
] + [
    {"instruction": f"tamil learning pattern {i}", "response": "Seri Theo, calm-a one step pannalam. Naan un kooda iruken."}
    for i in range(1, 46)
]


class OllamaTrainer:
    """
    Collects training/context data from course research so Mistral can answer
    course questions offline via prompt injection.
    """

    def __init__(self, gemini_client=None):
        self.gemini_client = gemini_client
        self.training_dir = Path(DATA_DIR) / "training"
        self.training_dir.mkdir(parents=True, exist_ok=True)
        self._write_tamil_pairs()

    def collect_course_knowledge(self, course: dict):
        """Scrape/extract key facts and save JSONL Q&A for the course."""
        course_dir = self.training_dir / course["course_id"]
        course_dir.mkdir(parents=True, exist_ok=True)
        output = course_dir / "knowledge.jsonl"
        qa_pairs = []

        topic = course.get("topic", "")
        research = course.get("research_summary", {})
        qa_pairs.extend(self.generate_qa_pairs(topic, json.dumps(research, ensure_ascii=False)[:8000]))

        seen_topics = set()
        collected = 0
        for phase in course.get("phases", []):
            for day in phase.get("days", []):
                if collected >= 8:
                    break
                day_topic = day.get("topic", "")
                key = day_topic.lower()
                if key in seen_topics:
                    continue
                seen_topics.add(key)
                scraped = ""
                if collected < 2:
                    scraped = self._scrape_topic(day_topic, topic)
                qa_pairs.extend(self.generate_qa_pairs(day_topic, scraped))
                collected += 1
            if collected >= 8:
                break

        with output.open("w", encoding="utf-8") as f:
            for pair in qa_pairs:
                f.write(json.dumps({
                    "instruction": pair["question"],
                    "response": pair["answer"],
                    "course_id": course["course_id"],
                    "topic": topic,
                }, ensure_ascii=False) + "\n")
        return str(output)

    def build_topic_context(self, topic: str) -> str:
        """Return scraped knowledge about a topic as a context string."""
        matches = self._search_pairs(topic, limit=6)
        if not matches:
            return ""
        lines = ["Based on Theo's course materials:"]
        for item in matches:
            lines.append(f"Q: {item['instruction']}\nA: {item['response']}")
        return "\n\n".join(lines)

    def generate_qa_pairs(self, topic: str, scraped_text: str) -> list[dict]:
        """Convert scraped text into beginner-friendly Q&A pairs."""
        if self.gemini_client is not None and scraped_text.strip():
            prompt = (
                f"Convert this text into 10 Q&A pairs about {topic}. "
                "Make questions like a student would ask. Make answers clear and beginner-friendly. "
                "Return JSON array with question and answer keys.\n\n"
                f"TEXT:\n{scraped_text[:6000]}"
            )
            try:
                response = self.gemini_client.models.generate_content(
                    model="gemini-2.5-flash",
                    contents=prompt,
                ).text
                match = re.search(r"\[[\s\S]+\]", response)
                data = json.loads(match.group(0) if match else response)
                return [
                    {"question": item.get("question", item.get("instruction", "")), "answer": item.get("answer", item.get("response", ""))}
                    for item in data if item.get("question") or item.get("instruction")
                ]
            except Exception:
                pass
        return self._fallback_qa(topic, scraped_text)

    def inject_knowledge_into_mistral_prompt(self, user_query: str, course_id: str | None = None) -> str:
        """Find relevant knowledge from training data for Mistral prompt injection."""
        matches = self._search_pairs(user_query, course_id=course_id, limit=5)
        if not matches:
            return ""
        return "OFFLINE COURSE KNOWLEDGE:\n" + "\n\n".join(
            f"- {item['instruction']}\n  {item['response']}" for item in matches
        )

    def answer_from_context(self, user_query: str, course_id: str | None = None) -> str:
        """Return a direct answer from collected course Q&A when no model is available."""
        matches = self._search_pairs(user_query, course_id=course_id, limit=1)
        if not matches:
            return ""
        return matches[0].get("response", "")

    def _scrape_topic(self, day_topic: str, course_topic: str) -> str:
        queries = [
            f"{course_topic} {day_topic} explained simply",
        ]
        chunks = []
        for query in queries:
            try:
                chunks.append(scrape_web(query=query)[:2000])
            except Exception:
                continue
        return "\n\n".join(chunks)

    @staticmethod
    def _fallback_qa(topic: str, scraped_text: str) -> list[dict]:
        lower = topic.lower()
        if "ai agent" in lower or ("ai" in lower and "agent" in lower):
            return [
                {"question": "What is an AI agent?", "answer": "An AI agent is software that can understand a goal, look at its environment or available information, decide what to do next, and take actions using tools or steps. A simple chatbot mostly replies, but an agent can plan, use tools, remember progress, and keep working toward a task."},
                {"question": "How is an AI agent different from a chatbot?", "answer": "A chatbot mainly answers messages. An AI agent can also decide actions, call tools, search, write files, schedule tasks, or complete multi-step goals with less hand-holding."},
                {"question": "What are examples of AI agents?", "answer": "Examples include a coding agent that edits files, a research agent that searches and summarizes sources, a calendar agent that schedules meetings, and a customer support agent that checks order status and replies."},
                {"question": "What are the main parts of an AI agent?", "answer": "The main parts are a goal, a model or reasoning brain, memory or context, tools it can use, and a loop for planning, acting, checking results, and improving the next step."},
            ]
        summary = re.sub(r"\s+", " ", scraped_text).strip()[:600]
        if not summary:
            summary = f"{topic} is the topic of Theo's current course. Start with the definition, examples, core terms, and a small beginner exercise."
        return [
            {"question": f"What is {topic}?", "answer": summary},
            {"question": f"How should a beginner start learning {topic}?", "answer": f"Start by understanding what {topic} solves, learn the key terms, watch one beginner explanation, then do a tiny practice task."},
            {"question": f"What should I remember about {topic}?", "answer": f"Remember the plain-English definition, one real-world example, and one reason {topic} is useful."},
        ]

    def _search_pairs(self, query: str, course_id: str | None = None, limit: int = 5) -> list[dict]:
        terms = [t for t in re.findall(r"[a-zA-Z0-9]+", query.lower()) if len(t) > 2]
        scored = []
        files = []
        if course_id:
            files.extend((self.training_dir / course_id).glob("knowledge.jsonl"))
        files.extend(self.training_dir.glob("*/knowledge.jsonl"))
        for path in files:
            try:
                for line in path.read_text(encoding="utf-8").splitlines():
                    item = json.loads(line)
                    blob = f"{item.get('instruction', '')} {item.get('response', '')} {item.get('topic', '')}".lower()
                    score = sum(1 for term in terms if term in blob)
                    if score:
                        scored.append((score, item))
            except (OSError, json.JSONDecodeError):
                continue
        scored.sort(key=lambda x: x[0], reverse=True)
        return [item for _, item in scored[:limit]]

    def _write_tamil_pairs(self):
        path = self.training_dir / "tamil_interactions.jsonl"
        if path.exists():
            return
        with path.open("w", encoding="utf-8") as f:
            for pair in TAMIL_QA_PAIRS:
                f.write(json.dumps(pair, ensure_ascii=False) + "\n")
