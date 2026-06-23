"""
Nila Council — Shared utilities for the multi-LLM system.
Routing logic has moved to agent.py (speed-first) and web_search_chain.py (provider chain).
This module provides shared memory context building and system prompts.
"""

import json
import glob
import os
from datetime import datetime

from core.config import DATA_DIR


def build_memory_context(memory_store) -> str:
    """Build rich context string from all stored memory. Shared with ALL providers."""
    try:
        facts = memory_store.get_all_facts()
        goals = memory_store.get_goals()
        kb = memory_store.data.get("personal_kb", {})
        courses = _load_courses_summary()

        active_goals = [g for g in goals if g.get("status") == "active"]
        goals_text = "\n".join(f"- {g['goal']}" for g in active_goals) if active_goals else "No active goals"
        facts_text = "\n".join(f"- {k}: {v}" for k, v in facts.items()) if facts else "No facts stored yet"

        kb_projects = kb.get("projects", [])
        kb_locations = kb.get("locations", {})
        kb_custom = kb.get("custom_facts", {})
        kb_notes_count = len(kb.get("work_notes", []))

        kb_text = ""
        if kb_projects:
            kb_text += "Projects:\n" + "\n".join(
                f"  - {p.get('name', '?')}: {p.get('description', '')}"
                for p in kb_projects[:5]
            ) + "\n"
        if kb_locations:
            kb_text += "Locations:\n" + "\n".join(
                f"  - {k}: {v.get('path_or_url', v) if isinstance(v, dict) else v}"
                for k, v in kb_locations.items()
            ) + "\n"
        if kb_custom:
            kb_text += "Custom Facts:\n" + "\n".join(
                f"  - {k}: {v.get('value', v) if isinstance(v, dict) else v}"
                for k, v in kb_custom.items()
            ) + "\n"
        history = memory_store.data.get("conversations", [])[-6:]
        history_text = ""
        if history:
            history_text = "\n".join(f"- {'User' if m['role'] == 'user' else 'Nila'}: {m['content']}" for m in history)
        else:
            history_text = "None"

        context = (
            f"=== THEO'S PERSONAL DATA ===\n"
            f"Date: {datetime.now().strftime('%A, %B %d, %Y %I:%M %p')}\n\n"
            f"KNOWN FACTS:\n{facts_text}\n\n"
            f"ACTIVE GOALS:\n{goals_text}\n\n"
            f"ACTIVE COURSES:\n{courses}\n\n"
            f"PERSONAL KNOWLEDGE BASE:\n{kb_text}\n"
            f"RECENT DIALOGUE HISTORY:\n{history_text}\n"
            f"=== END THEO'S DATA ==="
        )
        return context

    except Exception as e:
        return f"Memory load error: {e}"


def _load_courses_summary() -> str:
    """Load active courses as a summary string."""
    courses_dir = os.path.join(DATA_DIR, "courses")
    if not os.path.exists(courses_dir):
        return "No active courses"

    files = glob.glob(os.path.join(courses_dir, "*.json"))
    if not files:
        return "No active courses"

    summary_lines = []
    for f in files:
        try:
            with open(f, encoding="utf-8") as fp:
                c = json.load(fp)
                done = c.get("progress", {}).get("completed_days", 0)
                total = c.get("total_days", 0)
                pct = round(done / total * 100, 1) if total else 0
                current = c.get("progress", {}).get("current_day", 1)
                streak = c.get("progress", {}).get("streak", 0)
                summary_lines.append(
                    f"- {c.get('topic', 'Unknown')}: Day {current}/{total} "
                    f"({pct}% done) | Streak: {streak}"
                )
        except (json.JSONDecodeError, OSError):
            continue

    return "\n".join(summary_lines) if summary_lines else "No active courses"


class NilaCouncil:
    """Multi-LLM coordination failover logic for test assertions."""
    def __init__(self, providers, token_tracker):
        self.providers = providers
        self.token_tracker = token_tracker

    def _build_system(self, context: str, lang: str) -> str:
        return f"System context: {context}\nLanguage: {lang}"

    def _call_online_chain(self, message: str, context: str, lang: str) -> tuple:
        system = self._build_system(context, lang)
        last_error = ""
        
        for name in ["gemini", "groq", "openrouter"]:
            provider = self.providers.get(name)
            if not provider:
                continue
            if not provider.is_available():
                continue
            if not self.token_tracker.is_provider_quota_ok(name):
                continue
            
            try:
                resp = provider.chat(
                    message,
                    system_prompt=system,
                    max_tokens=1024,
                    timeout=20
                )
                if resp and len(resp.strip()) > 10:
                    tokens_in = self.token_tracker.estimate_tokens(message)
                    tokens_out = self.token_tracker.estimate_tokens(resp)
                    self.token_tracker.record(name, tokens_in, tokens_out)
                    
                    icons = {"gemini": "📡", "groq": "⚡", "openrouter": "🌐"}
                    names = {
                        "gemini": "Gemini 2.5 Flash",
                        "groq": "Groq llama-70b",
                        "openrouter": "OpenRouter"
                    }
                    return resp, f"{icons[name]} {names[name]}"
            
            except Exception as e:
                last_error = f"{name}: {str(e)[:60]}"
                # CONTINUE to next provider — don't break
                continue
        
        # All online failed
        resp = self.providers["local"].reply_with_memory(message, context, lang)
        self.token_tracker.record("local")
        return resp, f"🖥️ Nila Local (all online failed: {last_error})"
