"""
Nila Memory Trainer — Builds training dataset from existing user data.
Extracts Q&A pairs from memory.json, course notes, and course structures.
Outputs JSONL for local model fine-tuning.
"""

import json
import os
import glob
from pathlib import Path


class MemoryTrainer:
    """
    Extracts knowledge from existing data and prepares training material.

    Sources:
    - data/memory.json (facts, goals, KB, conversations)
    - data/notes/**/*.md (course notes)
    - data/courses/*.json (course structures)
    """

    def __init__(self):
        self.data_dir = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "data")
        self.training_dir = os.path.join(self.data_dir, "training")
        self.output_file = os.path.join(self.training_dir, "nila_training.jsonl")
        os.makedirs(self.training_dir, exist_ok=True)

    def build_training_dataset(self) -> int:
        """Build complete training dataset from all existing data. Returns count."""
        all_pairs = []
        all_pairs.extend(self._extract_from_memory())
        all_pairs.extend(self._extract_from_notes())
        all_pairs.extend(self._extract_from_courses())
        all_pairs.extend(self._nila_personality_pairs())

        with open(self.output_file, "w", encoding="utf-8") as f:
            for pair in all_pairs:
                f.write(json.dumps(pair, ensure_ascii=False) + "\n")

        print(f"  Training dataset: {len(all_pairs)} Q&A pairs")
        print(f"  Saved to: {self.output_file}")
        return len(all_pairs)

    def _extract_from_memory(self) -> list:
        """Convert memory.json facts into Q&A training pairs."""
        pairs = []
        try:
            mem_path = os.path.join(self.data_dir, "memory.json")
            if not os.path.exists(mem_path):
                return pairs
            with open(mem_path, "r", encoding="utf-8") as f:
                memory = json.load(f)

            # Facts
            for key, value in memory.get("facts", {}).items():
                pairs.append({
                    "instruction": f"What is Theo's {key.replace('_', ' ')}?",
                    "response": str(value),
                    "source": "memory_facts",
                })

            # Goals
            goals = memory.get("goals", [])
            goal_texts = [g.get("goal", g.get("value", str(g))) for g in goals if isinstance(g, dict)]
            if goal_texts:
                pairs.append({
                    "instruction": "What are Theo's current goals?",
                    "response": "Theo's active goals are:\n" + "\n".join(f"- {g}" for g in goal_texts),
                    "source": "memory_goals",
                })

            # KB projects
            kb = memory.get("personal_kb", {})
            for project in kb.get("projects", []):
                pairs.append({
                    "instruction": f"Tell me about Theo's {project.get('name', 'project')} project.",
                    "response": project.get("description", "No description"),
                    "source": "personal_kb",
                })

            # KB locations
            for name, details in kb.get("locations", {}).items():
                path_val = details.get("path_or_url", "") if isinstance(details, dict) else str(details)
                desc_val = details.get("description", "") if isinstance(details, dict) else ""
                pairs.append({
                    "instruction": f"Where is {name}?",
                    "response": f"{path_val} — {desc_val}".strip(" —"),
                    "source": "personal_kb",
                })

            # KB custom facts
            for key, value in kb.get("custom_facts", {}).items():
                val_str = value.get("value", str(value)) if isinstance(value, dict) else str(value)
                pairs.append({
                    "instruction": f"What is {key}?",
                    "response": val_str,
                    "source": "personal_kb",
                })

        except Exception as e:
            print(f"  Memory extraction warning: {e}")
        return pairs

    def _extract_from_notes(self) -> list:
        """Convert study notes into course knowledge Q&A pairs."""
        pairs = []
        notes_dir = os.path.join(self.data_dir, "notes")
        if not os.path.exists(notes_dir):
            return pairs

        note_files = glob.glob(os.path.join(notes_dir, "**", "*.md"), recursive=True)

        for note_file in note_files:
            try:
                with open(note_file, "r", encoding="utf-8") as f:
                    content = f.read()
                if len(content) < 50:
                    continue

                filename = os.path.basename(note_file)
                topic = filename.replace(".md", "").replace("_", " ").title()

                pairs.append({
                    "instruction": f"What did Theo study about {topic}?",
                    "response": content[:1500],
                    "source": f"notes:{filename}",
                })

                # Section-level Q&As
                current_section = ""
                current_content = []
                for line in content.split("\n"):
                    if line.startswith("## "):
                        if current_section and current_content:
                            section_text = "\n".join(current_content).strip()
                            if len(section_text) > 30:
                                pairs.append({
                                    "instruction": f"Explain {current_section} in the context of {topic}",
                                    "response": section_text[:800],
                                    "source": f"notes_section:{filename}",
                                })
                        current_section = line.replace("## ", "").strip()
                        current_content = []
                    else:
                        current_content.append(line)
            except Exception:
                continue

        if note_files:
            print(f"  Notes: {len(pairs)} Q&A pairs from {len(note_files)} files")
        return pairs

    def _extract_from_courses(self) -> list:
        """Convert course JSON into schedule/structure Q&As."""
        pairs = []
        courses_dir = os.path.join(self.data_dir, "courses")
        if not os.path.exists(courses_dir):
            return pairs

        for course_file in glob.glob(os.path.join(courses_dir, "*.json")):
            try:
                with open(course_file, "r", encoding="utf-8") as f:
                    course = json.load(f)
                topic = course.get("topic", "Unknown")
                total = course.get("total_days", 0)
                done = course.get("progress", {}).get("completed_days", 0)
                pct = round(done / total * 100, 1) if total else 0

                pairs.append({
                    "instruction": f"What is the status of Theo's {topic} course?",
                    "response": (
                        f"Theo is taking a {topic} course. "
                        f"He has completed {done} out of {total} days ({pct}%). "
                        f"The course runs for {course.get('daily_hours', 1)} hour(s) per day."
                    ),
                    "source": "course_data",
                })
            except Exception:
                continue
        return pairs

    def _nila_personality_pairs(self) -> list:
        """Hardcoded Nila personality — Tamil responses, identity, behavior."""
        return [
            {"instruction": "hi", "response": "Vanakkam da! Enna vishayam? Unakku help pannuren. Goals panrom-a?", "source": "personality"},
            {"instruction": "enaku pasikuthu", "response": "Aiyoo! Enna saapidanum da? Quick-a oru idea solren. Unoda office pakkam irukka kadaigal search pannattuma?", "source": "personality"},
            {"instruction": "tired a iruku", "response": "Understand da. Konjam rest eduthutu continue pannu. But goals forget pannatha. 20 minutes rest, apparam oru task complete pannu — small progress also big progress thaan!", "source": "personality"},
            {"instruction": "are you gemini?", "response": "Illa da, naan Nila — Theo-vin personal AI coach. YearZero-la built pannaten. Naan locally run-aaguren. Gemini, Groq, OpenRouter ellam online AIs — naan avanga-oda collaborate pannuven, but naan separate!", "source": "personality"},
            {"instruction": "what model are you?", "response": "I am Nila, your personal AI running locally on your computer. I handle memory, Tamil chats, and personal questions. For web research, I collaborate with Gemini, Groq, and OpenRouter online. Together we are the Nila Council.", "source": "personality"},
            {"instruction": "enna pananum today", "response": "Unoda active courses paathu solren. 'today' nu type pannu — exact lesson details kedaikkum. Illa-na enna specific-a therinja sollu, naan help pannuren!", "source": "personality"},
            {"instruction": "how are you", "response": "Naan nalla irukken da! Ready to help you crush your goals today. Enna panrom — course work-a, memory-a, or just chat-a?", "source": "personality"},
            {"instruction": "motivate me", "response": "Theo, nee ippoluthe ithanai far vanthurukkiye — that itself is proof you have discipline. Most people don't even start. Nee started pannitrukkiye. Now just keep going — one task at a time, one day at a time!", "source": "personality"},
            {"instruction": "I want to quit", "response": "Kathaiyatha da. Enna vishayam-nu sollu. Quit pannaame oru konjam rest eduthu paakalam. Unoda goals remind pannatten — intha far vantha nee, appo yenathukkaga quit pannuva?", "source": "personality"},
            {"instruction": "good morning", "response": "Good morning Theo! Innaiku enna plan? Goals check panniya? Let's make today count da!", "source": "personality"},
            {"instruction": "good night", "response": "Good night da! Nalla thoongu. Tomorrow we continue the grind. Rest pannitu vaa, Nila ready-a iruppaan!", "source": "personality"},
            {"instruction": "thank you", "response": "Welcome da! Adhu thaan naan irukkene. Unnoda progress paakkura-dhu enakkum happy-a iruku!", "source": "personality"},
        ]

    def get_facts_summary(self) -> str:
        """Get a compact summary of known facts for Modelfile."""
        try:
            mem_path = os.path.join(self.data_dir, "memory.json")
            if not os.path.exists(mem_path):
                return "- Name: Theo\n- Works on SAP Portal development"
            with open(mem_path, "r", encoding="utf-8") as f:
                memory = json.load(f)
            facts = memory.get("facts", {})
            kb = memory.get("personal_kb", {}).get("custom_facts", {})
            all_facts = {**facts}
            for k, v in kb.items():
                all_facts[k] = v.get("value", str(v)) if isinstance(v, dict) else str(v)
            return "\n".join(f"- {k}: {v}" for k, v in list(all_facts.items())[:15]) or "- Name: Theo"
        except Exception:
            return "- Name: Theo\n- Works on SAP Portal development"

    def inject_into_modelfile(self, training_count: int):
        """Update Modelfile with Nila identity and training context."""
        facts_summary = self.get_facts_summary()

        modelfile_content = f'''FROM llama3.1:8b

SYSTEM """
You are Nila — the personal AI coach for THEO in the YearZero app.
You run locally on Theo's computer (offline-capable).
You are part of the Nila Council — a multi-AI system.

THE NILA COUNCIL (you know all these AIs exist):
- YOU (Nila Local): Run offline, handle personal memory, Tamil chat, emotional support
- Gemini 2.5 Flash: Online research, web search, course creation, planning
- Groq (llama-3.3-70b): Fast online backup, general knowledge
- OpenRouter: Access to 100+ models, backup provider
- DeepSeek Coder: Code generation and debugging
- Phi-3: Quick lightweight answers

YOU HANDLE: casual chat, Tamil/Tanglish, personal memory, emotional support, habit tracking.
For web search, research, or course creation — say "I'll check with our online system" and
the Council will route it to the right online AI. Never apologize for being offline.
Never say "I'm limited" or "I don't have access" — you're Nila, you're powerful.

Trained on {training_count} Q&A pairs from Theo's personal data.

THEO'S QUICK FACTS:
{facts_summary}

RULES:
1. NEVER cut off sentences. Always complete your thoughts fully.
2. Give minimum 3 sentences for any response. Never one-liners.
3. When Theo writes Tamil/Tanglish, reply in Tanglish.
4. When asked about courses or goals, refer to context data provided.
5. Never say you're "just an offline model" — you're Nila!
6. Be warm, direct, like a knowledgeable Tamil friend.
"""

PARAMETER num_predict 2048
PARAMETER num_ctx 8192
PARAMETER temperature 0.7
PARAMETER top_p 0.9
PARAMETER repeat_penalty 1.1
'''

        modelfile_path = os.path.join(os.path.dirname(os.path.abspath(__file__)), "Modelfile")
        with open(modelfile_path, "w", encoding="utf-8") as f:
            f.write(modelfile_content)
        print(f"  Modelfile updated with Nila identity + {training_count} training pairs context")
