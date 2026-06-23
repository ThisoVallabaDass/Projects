"""
Continuous Personalization Trainer
Learns from every conversation turn and adapts the local model.

Processes every user ↔ Nila exchange to:
1. Extract learning patterns (what was effective, user style)
2. Build personalized training data
3. Trigger incremental fine-tuning on Ollama model
4. Track adaptation metrics
"""

import json
import os
import re
from datetime import datetime
from pathlib import Path
from typing import Optional, Dict

from core.config import DATA_DIR
from core.memory import MemoryStore


class ConversationTrainer:
    """Learns from every conversation turn and adapts the model."""

    def __init__(self):
        self.training_dir = Path(DATA_DIR) / "training"
        self.training_dir.mkdir(parents=True, exist_ok=True)

        self.adaptive_file = self.training_dir / "adaptive_training.jsonl"
        self.metrics_file = self.training_dir / "adaptation_metrics.json"
        self.conversation_count = 0
        self._load_metrics()

    def _load_metrics(self):
        """Load adaptation progress."""
        if self.metrics_file.exists():
            try:
                with self.metrics_file.open("r", encoding="utf-8") as f:
                    metrics = json.load(f)
                    self.conversation_count = metrics.get("conversation_count", 0)
            except Exception:
                self.conversation_count = 0
        else:
            self.conversation_count = 0

    def _save_metrics(self):
        """Save adaptation progress."""
        metrics = {
            "conversation_count": self.conversation_count,
            "last_updated": datetime.now().isoformat(),
            "model_version": self._get_model_version(),
        }
        with self.metrics_file.open("w", encoding="utf-8") as f:
            json.dump(metrics, f, indent=2)

    def process_exchange(self, user_msg: str, assistant_resp: str, context: Dict = None) -> Dict:
        """
        Process a user-assistant exchange and extract training data.

        Returns: {
            'success': bool,
            'pairs_added': int,
            'should_retrain': bool,
            'adaptation_stage': str,
        }
        """
        if not user_msg.strip() or not assistant_resp.strip():
            return {"success": False, "pairs_added": 0, "should_retrain": False}

        context = context or {}
        pairs = []

        # Extract learning patterns
        pairs.extend(self._extract_style_patterns(user_msg, assistant_resp))
        pairs.extend(self._extract_effective_responses(user_msg, assistant_resp))
        pairs.extend(self._extract_user_preferences(user_msg, assistant_resp))
        pairs.extend(self._extract_domain_knowledge(user_msg, assistant_resp, context))

        # Append to training file
        added = 0
        if pairs:
            with self.adaptive_file.open("a", encoding="utf-8") as f:
                for pair in pairs:
                    f.write(json.dumps(pair, ensure_ascii=False) + "\n")
                    added += 1

        self.conversation_count += 1
        self._save_metrics()

        # Decide if we should retrain
        should_retrain = self.conversation_count % 25 == 0  # Every 25 exchanges

        return {
            "success": True,
            "pairs_added": added,
            "should_retrain": should_retrain,
            "adaptation_stage": f"Learning {self.conversation_count} exchanges",
            "ready_for_finetune": self.conversation_count % 25 == 0,
        }

    # ──────────────────────────────────────────────────────────────────────
    # Pattern extraction methods
    # ──────────────────────────────────────────────────────────────────────

    def _extract_style_patterns(self, user_msg: str, assistant_resp: str) -> list:
        """Extract user's communication style to match in responses."""
        patterns = []

        # Language preference (English, Tamil, Mix)
        tamil_ratio = sum(1 for c in user_msg if '\u0B80' <= c <= '\u0BFF') / max(len(user_msg), 1)

        if tamil_ratio > 0.3:
            patterns.append({
                "instruction": f"User prefers Tamil/Tanglish: {user_msg[:60]}",
                "response": f"Respond in Tamil/Tanglish style: {assistant_resp[:150]}",
                "source": "style_language",
                "strength": "high" if tamil_ratio > 0.6 else "medium",
            })

        # Question vs statement (does user ask questions or make statements?)
        has_question = "?" in user_msg
        if has_question:
            patterns.append({
                "instruction": f"User asks questions: {user_msg[:60]}",
                "response": f"Provide clear, direct answers: {assistant_resp[:150]}",
                "source": "style_question_asker",
            })
        else:
            patterns.append({
                "instruction": f"User makes statements: {user_msg[:60]}",
                "response": f"Acknowledge and expand: {assistant_resp[:150]}",
                "source": "style_statement_maker",
            })

        # Brevity preference (does user like short msgs or long ones?)
        if len(user_msg) < 30:
            patterns.append({
                "instruction": "User prefers concise messages (< 30 chars normally)",
                "response": f"Keep responses brief and actionable: {assistant_resp[:100]}",
                "source": "style_brief_preference",
            })
        elif len(user_msg) > 150:
            patterns.append({
                "instruction": "User writes detailed messages",
                "response": f"Provide thorough, detailed responses: {assistant_resp[:150]}",
                "source": "style_detailed_preference",
            })

        return patterns

    def _extract_effective_responses(self, user_msg: str, assistant_resp: str) -> list:
        """Extract what response patterns work well."""
        patterns = []

        # Responses with success indicators
        success_markers = ["✅", "great", "perfect", "thanks", "helpful", "that's it", "exactly"]
        success = any(m in assistant_resp.lower() for m in success_markers)

        if success:
            resp_len = len(assistant_resp)
            emoji_count = sum(1 for c in assistant_resp if ord(c) > 0x1F300)

            pattern_type = "brief" if resp_len < 100 else "detailed"
            has_emojis = emoji_count > 0

            patterns.append({
                "instruction": f"User query: {user_msg[:80]}",
                "response": f"Effective response ({pattern_type}, emoji={'yes' if has_emojis else 'no'}): {assistant_resp[:200]}",
                "source": "effective_response",
                "pattern": pattern_type,
                "has_structure": any(s in assistant_resp for s in ["1.", "2.", "-", "•"]),
            })

        return patterns

    def _extract_user_preferences(self, user_msg: str, assistant_resp: str) -> list:
        """Extract explicit user preferences mentioned in messages."""
        patterns = []

        # Preference keywords
        pref_patterns = [
            (r"i (?:like|prefer|love|enjoy)\s+([^,.\n]+)", "positive"),
            (r"i (?:dislike|hate|don't like)\s+([^,.\n]+)", "negative"),
            (r"please\s+(\w+)", "request"),
        ]

        for pattern, pref_type in pref_patterns:
            match = re.search(pattern, user_msg, re.IGNORECASE)
            if match:
                pref_item = match.group(1).strip()
                patterns.append({
                    "instruction": f"User {pref_type} preference: {pref_item}",
                    "response": f"Remember this preference for {pref_type} items",
                    "source": f"preference_{pref_type}",
                })

        return patterns

    def _extract_domain_knowledge(self, user_msg: str, assistant_resp: str, context: Dict) -> list:
        """Extract domain-specific knowledge from the exchange."""
        patterns = []

        # If assistant response contains technical terms, structure, or domain knowledge
        technical_markers = ["function", "class", "import", "algorithm", "def ", "code", "data", "query"]
        has_technical = any(m in assistant_resp.lower() for m in technical_markers)

        if has_technical and len(assistant_resp) > 100:
            patterns.append({
                "instruction": f"Technical query: {user_msg[:80]}",
                "response": f"Technical explanation: {assistant_resp[:300]}",
                "source": "domain_technical",
                "complexity": "high",
            })

        # Course/learning context
        if any(w in user_msg.lower() for w in ["course", "day", "topic", "learn", "study", "padika"]):
            course_info = context.get("course_id") or "general"
            patterns.append({
                "instruction": f"Learning: {user_msg[:60]} (course: {course_info})",
                "response": f"Teaching response: {assistant_resp[:150]}",
                "source": "domain_learning",
                "course": course_info,
            })

        return patterns

    # ──────────────────────────────────────────────────────────────────────
    # Training data methods
    # ──────────────────────────────────────────────────────────────────────

    def get_training_batch(self, limit: int = 50) -> list:
        """Get recent training pairs for fine-tuning."""
        if not self.adaptive_file.exists():
            return []

        try:
            with self.adaptive_file.open("r", encoding="utf-8") as f:
                lines = f.readlines()

            # Return last N lines (most recent)
            recent = lines[-limit:] if len(lines) > limit else lines
            return [json.loads(line) for line in recent if line.strip()]
        except Exception:
            return []

    def get_adaptation_status(self) -> Dict:
        """Get current adaptation status."""
        pairs_count = 0
        if self.adaptive_file.exists():
            try:
                pairs_count = sum(1 for _ in self.adaptive_file.open("r", encoding="utf-8"))
            except Exception:
                pairs_count = 0

        return {
            "conversations_processed": self.conversation_count,
            "training_pairs_accumulated": pairs_count,
            "ready_for_retrain": self.conversation_count % 25 == 0,
            "next_retrain_in": 25 - (self.conversation_count % 25),
            "adaptation_strength": min(100, (pairs_count / 5)),  # Rough percentage
        }

    def _get_model_version(self) -> str:
        """Track model version for consistency."""
        return f"nila-v{self.conversation_count // 25 + 1}"

    def clear_adaptive_data(self):
        """Reset adaptation (start fresh learning)."""
        if self.adaptive_file.exists():
            self.adaptive_file.unlink()
        self.conversation_count = 0
        self._save_metrics()

    def export_training_pairs(self) -> str:
        """Export all collected training pairs as JSONL."""
        if not self.adaptive_file.exists():
            return ""

        output_path = self.training_dir / "personalized_nila_training.jsonl"
        # Copy adaptive training file
        with self.adaptive_file.open("r", encoding="utf-8") as src:
            with output_path.open("w", encoding="utf-8") as dst:
                dst.write(src.read())

        return str(output_path)
