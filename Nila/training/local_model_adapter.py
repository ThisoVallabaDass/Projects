"""
Local Model Adapter — Fine-tunes the local Ollama model with user data.

Periodically updates the model with personalized training pairs.
Uses Ollama's API to rebuild the model with adapted context.
"""

import json
import os
import subprocess
from pathlib import Path
from typing import Optional, Dict
import time

from core.config import DATA_DIR, OLLAMA_HOST, OLLAMA_MODEL
from training.memory_trainer import MemoryTrainer


class LocalModelAdapter:
    """Manages incremental fine-tuning of local Ollama model."""

    def __init__(self, ollama_host: str = OLLAMA_HOST, model_name: str = OLLAMA_MODEL):
        self.ollama_host = ollama_host
        self.model_name = model_name
        self.training_dir = Path(DATA_DIR) / "training"
        self.training_dir.mkdir(parents=True, exist_ok=True)
        self.modelfile_path = self.training_dir / "PersonalizedModelfile"
        self.backup_dir = self.training_dir / "model_backups"
        self.backup_dir.mkdir(parents=True, exist_ok=True)

    def adapt_model_from_training_data(self, training_pairs: list) -> Dict:
        """
        Adapt the local model with new personalized training data.

        Process:
        1. Build personalized context from training pairs
        2. Update Modelfile with context
        3. Rebuild model with `ollama create`
        4. Backup previous version
        5. Swap new model into use

        Returns status dict with success/error info.
        """
        if not training_pairs or len(training_pairs) < 5:
            return {
                "success": False,
                "reason": "Not enough training pairs (need at least 5 for adaptation)",
            }

        try:
            # Step 1: Build context from training pairs
            context = self._build_personalized_context(training_pairs)

            # Step 2: Create Modelfile with context
            modelfile_path = self._create_personalized_modelfile(context)

            # Step 3: Build the model
            build_result = self._build_model(modelfile_path)
            if not build_result["success"]:
                return build_result

            # Step 4: Verify model works
            test_result = self._test_model()

            return {
                "success": True,
                "message": f"Model adapted with {len(training_pairs)} personalization pairs",
                "training_pairs": len(training_pairs),
                "model_version": self._get_current_version(),
                "context_size": len(context),
            }

        except Exception as e:
            return {
                "success": False,
                "reason": f"Adaptation failed: {str(e)[:100]}",
            }

    def _build_personalized_context(self, training_pairs: list) -> str:
        """Build personalization context from training data."""
        context_lines = [
            "PERSONALIZATION CONTEXT",
            "=" * 50,
            "",
        ]

        # Group by source
        by_source = {}
        for pair in training_pairs:
            source = pair.get("source", "unknown")
            if source not in by_source:
                by_source[source] = []
            by_source[source].append(pair)

        # Add language preferences
        if by_source.get("style_language"):
            context_lines.append("## User Communication Style")
            for pair in by_source["style_language"][:2]:
                context_lines.append(f"- {pair.get('instruction', '')}")

        # Add response patterns
        if by_source.get("effective_response"):
            context_lines.append("\n## What works well")
            for pair in by_source["effective_response"][:3]:
                pattern = pair.get("pattern", "")
                context_lines.append(f"- {pattern} responses are effective")

        # Add user preferences
        if by_source.get("preference_positive") or by_source.get("preference_negative"):
            context_lines.append("\n## User Preferences")
            positive = by_source.get("preference_positive", [])
            negative = by_source.get("preference_negative", [])
            for p in positive[:2]:
                context_lines.append(f"- User likes: {p.get('instruction', '')[:60]}")
            for n in negative[:2]:
                context_lines.append(f"- User dislikes: {n.get('instruction', '')[:60]}")

        # Add domain knowledge
        if by_source.get("domain_learning"):
            context_lines.append("\n## Learning Context")
            for pair in by_source["domain_learning"][:3]:
                context_lines.append(f"- Teaching about: {pair.get('instruction', '')[:60]}")

        # Get base facts
        context_lines.append("\n## User Facts")
        memory_trainer = MemoryTrainer()
        facts = memory_trainer.get_facts_summary()
        for fact in facts.split("\n")[:5]:
            context_lines.append(fact)

        return "\n".join(context_lines)

    def _create_personalized_modelfile(self, personalization_context: str) -> Path:
        """Create a Modelfile with personalization context."""
        memory_trainer = MemoryTrainer()
        facts = memory_trainer.get_facts_summary()

        modelfile_content = f'''FROM {self.model_name}

# Personalized Modelfile for Nila local model
# Generated: {time.strftime('%Y-%m-%d %H:%M:%S')}

SYSTEM """
You are Nila — Theo's personal AI coach in YearZero.
You run locally on Theo's computer.

=== PERSONALIZATION (Generated from {len(personalization_context)} learning exchanges) ===

{personalization_context[:2000]}

=== BASE IDENTITY ===

Standard Nila identity:
- Part of multi-AI council (Gemini, Groq, OpenRouter, Local Nila)
- Handle personal memory, Tamil/Tanglish, emotional support
- Offline-first, privacy-focused, always-on local model
- Track habits, manage learning, provide accountability

THEO'S PROFILE:
{facts}

COMMUNICATION RULES:
1. Match user's language preference (Tamil/Tanglish/English detected from above)
2. Use response length and structure preferences detected during learning
3. Remember all preferences encoded above
4. Never cut off. Always complete thoughts.
5. Respond with warmth, directness, like a Tamil-speaking friend.
6. If from web involved, coordinate with online AI council.
"""

PARAMETER temperature 0.7
PARAMETER top_p 0.95
PARAMETER repeat_penalty 1.1
'''

        with self.modelfile_path.open("w", encoding="utf-8") as f:
            f.write(modelfile_content)

        return self.modelfile_path

    def _build_model(self, modelfile_path: Path) -> Dict:
        """Build the model using ollama create."""
        try:
            # Create a personalized model name
            model_name = f"nila-personal:latest"

            cmd = [
                "ollama",
                "create",
                model_name,
                "-f",
                str(modelfile_path),
            ]

            result = subprocess.run(
                cmd,
                capture_output=True,
                text=True,
                timeout=60,
            )

            if result.returncode != 0:
                return {
                    "success": False,
                    "reason": f"Ollama build failed: {result.stderr[:100]}",
                }

            return {
                "success": True,
                "model": model_name,
                "message": "Model built successfully",
            }

        except subprocess.TimeoutExpired:
            return {"success": False, "reason": "Model build timed out (>60s)"}
        except FileNotFoundError:
            return {
                "success": False,
                "reason": "Ollama not found. Is it installed and in PATH?",
            }
        except Exception as e:
            return {"success": False, "reason": f"Build error: {str(e)[:100]}"}

    def _test_model(self) -> Dict:
        """Test the newly built model."""
        try:
            import requests

            test_prompt = "What is your name?"
            payload = {
                "model": f"nila-personal:latest",
                "prompt": test_prompt,
                "stream": False,
            }

            response = requests.post(
                f"{self.ollama_host}/api/generate",
                json=payload,
                timeout=30,
            )

            if response.status_code == 200:
                result = response.json()
                if result.get("response", "").strip():
                    return {"success": True, "message": "Model test passed"}

            return {"success": False, "reason": "Model test failed"}

        except Exception as e:
            return {"success": False, "reason": f"Test error: {str(e)[:100]}"}

    def _get_current_version(self) -> str:
        """Get current model version."""
        try:
            import requests

            response = requests.get(f"{self.ollama_host}/api/tags", timeout=10)
            if response.status_code == 200:
                models = response.json().get("models", [])
                for model in models:
                    if "nila-personal" in model.get("name", ""):
                        return model.get("name", "unknown")
        except Exception:
            pass
        return "nila-personal:latest"

    def get_adaptation_metrics(self) -> Dict:
        """Get model adaptation metrics."""
        metrics_file = self.training_dir / "adaptation_metrics.json"
        if metrics_file.exists():
            try:
                with metrics_file.open("r", encoding="utf-8") as f:
                    return json.load(f)
            except Exception:
                pass

        return {
            "conversations": 0,
            "trainings": 0,
            "last_adapted": None,
        }

    def export_model_snapshot(self, label: str) -> Optional[str]:
        """Export current model config as snapshot."""
        try:
            snapshot_dir = self.backup_dir / label
            snapshot_dir.mkdir(parents=True, exist_ok=True)

            # Copy Modelfile
            if self.modelfile_path.exists():
                import shutil

                shutil.copy2(
                    self.modelfile_path,
                    snapshot_dir / "Modelfile",
                )

            return str(snapshot_dir)
        except Exception:
            return None
