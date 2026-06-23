"""
Theo's personal knowledge base.

Stores work, projects, locations, technical notes, and custom facts inside
data/memory.json under the "personal_kb" key so it survives restarts.
"""

from __future__ import annotations

import re
from datetime import datetime
from typing import Any

from core.memory import MemoryStore


DEFAULT_PERSONAL_KB = {
    "projects": [],
    "work_notes": [],
    "locations": {},
    "technical_docs": [],
    "custom_facts": {},
}


class PersonalKB:
    """Theo's personal knowledge base - stores work, projects, locations, docs."""

    def __init__(self, memory_store: MemoryStore | None = None):
        self.memory = memory_store or MemoryStore()
        self._ensure_schema()

    def _ensure_schema(self):
        if "personal_kb" not in self.memory.data:
            self.memory.data["personal_kb"] = self._fresh_default()
            self.memory.save()
        else:
            kb = self.memory.data["personal_kb"]
            changed = False
            for key, default in DEFAULT_PERSONAL_KB.items():
                if key not in kb:
                    kb[key] = default.copy() if isinstance(default, dict) else list(default)
                    changed = True
            if changed:
                self.memory.save()

    @staticmethod
    def _fresh_default() -> dict[str, Any]:
        return {
            "projects": [],
            "work_notes": [],
            "locations": {},
            "technical_docs": [],
            "custom_facts": {},
        }

    @property
    def kb(self) -> dict[str, Any]:
        self._ensure_schema()
        return self.memory.data["personal_kb"]

    def store_project(self, name: str, description: str, details: dict):
        """Store a project with all its details."""
        entry = {
            "name": name.strip(),
            "description": description.strip(),
            "details": details or {},
            "updated_at": datetime.now().isoformat(),
        }
        projects = self.kb["projects"]
        for idx, existing in enumerate(projects):
            if existing.get("name", "").lower() == entry["name"].lower():
                projects[idx] = entry
                self.memory.save()
                return
        projects.append(entry)
        self.memory.save()

    def store_location(self, name: str, path_or_url: str, description: str):
        """Store a file path, URL, or location reference."""
        self.kb["locations"][name.strip()] = {
            "path_or_url": path_or_url.strip(),
            "description": description.strip(),
            "updated_at": datetime.now().isoformat(),
        }
        self.memory.save()

    def store_work_note(self, topic: str, content: str, tags: list):
        """Store a technical note about something Theo is working on."""
        self.kb["work_notes"].append({
            "topic": topic.strip(),
            "content": content.strip(),
            "tags": tags or [],
            "created_at": datetime.now().isoformat(),
        })
        self.memory.save()

    def store_custom_fact(self, key: str, value: str):
        """Store any custom fact."""
        self.kb["custom_facts"][key.strip()] = {
            "value": value.strip(),
            "updated_at": datetime.now().isoformat(),
        }
        self.memory.save()

    def store_technical_doc(self, title: str, content: str, source: str = ""):
        """Store a technical document or long reference."""
        self.kb["technical_docs"].append({
            "title": title.strip(),
            "content": content.strip(),
            "source": source.strip(),
            "created_at": datetime.now().isoformat(),
        })
        self.memory.save()

    def search_kb(self, query: str) -> list:
        """Search all KB entries by keyword matching. Returns relevant entries."""
        terms = [t for t in re.findall(r"[a-zA-Z0-9_:/\\.-]+", query.lower()) if len(t) > 1]
        if not terms:
            return []

        results = []

        def score_blob(blob: str) -> int:
            lower = blob.lower()
            return sum(1 for term in terms if term in lower)

        for project in self.kb["projects"]:
            blob = f"{project.get('name', '')} {project.get('description', '')} {project.get('details', '')}"
            score = score_blob(blob)
            if score:
                results.append({"type": "project", "score": score, "entry": project})

        for name, value in self.kb["locations"].items():
            blob = f"{name} {value.get('path_or_url', '')} {value.get('description', '')}"
            score = score_blob(blob)
            if score:
                results.append({"type": "location", "score": score, "name": name, "entry": value})

        for note in self.kb["work_notes"]:
            blob = f"{note.get('topic', '')} {note.get('content', '')} {' '.join(note.get('tags', []))}"
            score = score_blob(blob)
            if score:
                results.append({"type": "work_note", "score": score, "entry": note})

        for doc in self.kb["technical_docs"]:
            blob = f"{doc.get('title', '')} {doc.get('content', '')} {doc.get('source', '')}"
            score = score_blob(blob)
            if score:
                results.append({"type": "technical_doc", "score": score, "entry": doc})

        for key, value in self.kb["custom_facts"].items():
            blob = f"{key} {value.get('value', '')}"
            score = score_blob(blob)
            if score:
                results.append({"type": "custom_fact", "score": score, "key": key, "entry": value})

        return sorted(results, key=lambda item: item["score"], reverse=True)[:10]

    def get_all_context(self) -> str:
        """Return all KB as a formatted string for AI context injection."""
        kb = self.kb
        lines = []

        if kb["locations"]:
            lines.append("Locations:")
            for name, data in kb["locations"].items():
                lines.append(f"- {name}: {data.get('path_or_url')} ({data.get('description')})")

        if kb["custom_facts"]:
            lines.append("Custom facts:")
            for key, data in kb["custom_facts"].items():
                lines.append(f"- {key}: {data.get('value')}")

        if kb["projects"]:
            lines.append("Projects:")
            for project in kb["projects"]:
                lines.append(f"- {project.get('name')}: {project.get('description')} | {project.get('details')}")

        if kb["work_notes"]:
            lines.append("Work notes:")
            for note in kb["work_notes"][-20:]:
                lines.append(f"- {note.get('topic')}: {note.get('content')}")

        if kb["technical_docs"]:
            lines.append("Technical docs:")
            for doc in kb["technical_docs"][-10:]:
                content = doc.get("content", "")
                preview = content[:1500] + ("..." if len(content) > 1500 else "")
                lines.append(f"- {doc.get('title')}: {preview}")

        return "\n".join(lines).strip()
