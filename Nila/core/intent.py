"""
Fast Intent Classifier — Sub-50ms two-stage intent detection for Nila.

Stage 1: Trie/prefix match against ~200 known phrases (< 1ms)
Stage 2: Cosine similarity with pre-computed embeddings (~20ms)
Falls back to existing classify_speed() if no match.

This runs BEFORE the existing routing waterfall to catch common
patterns faster than the multi-pass keyword scanning in router.py.
"""

import time
from typing import Optional


# ─── Known Intents ───────────────────────────────────────────────────

# Intent → list of trigger phrases (aggregated from all existing modules)
INTENT_PHRASES: dict[str, list[str]] = {
    # Instant local responses (< 100ms, no AI)
    "instant_greeting": [
        "hi", "hello", "hey", "vanakkam", "sup", "yo", "hii",
        "good morning", "good night", "good afternoon", "morning", "night",
        "how are you", "how r u", "how are u", "wassup", "what's up",
        "howdy", "ok", "okay", "seri", "seri da", "got it", "understood",
        "thanks", "thank you", "nandri", "bye", "goodbye", "see you",
        "tired", "bored", "happy", "sad", "stressed", "angry",
        "who are you", "what are you", "your name", "nee yaru",
    ],

    # Data queries (instant JSON, no AI)
    "data_query": [
        "courses", "my courses", "how many courses", "what courses",
        "active courses", "list courses", "show courses", "progress",
        "today's lesson", "today lesson", "what to do today", "today",
        "my goals", "what are my goals", "goals list", "goals",
        "my info", "my facts", "what do you know about me",
        "remove course", "delete course",
    ],

    # System actions (instant, no AI)
    "system_action": [
        "volume up", "volume down", "increase volume", "decrease volume",
        "mute", "unmute", "brightness up", "brightness down",
        "lock screen", "take screenshot", "screenshot",
        "play music", "pause music", "next song", "previous song",
        "turn on bluetooth", "turn off bluetooth",
        "turn on wifi", "turn off wifi",
    ],

    # Terminal/file operations
    "terminal_action": [
        "create file", "make file", "new file", "write file",
        "read file", "open file", "show file",
        "create folder", "make folder", "new folder", "mkdir",
        "list files", "show files", "folder contents",
        "delete file", "remove file",
        "run ", "execute ", "pip install", "git ",
    ],

    # Voice commands
    "voice_command": [
        "stop", "stop talking", "shut up", "silence", "quiet",
        "repeat", "say that again", "repeat that",
        "voice mode", "text mode", "voice", "text-mode",
    ],

    # Model switching
    "system_command": [
        "switch gemini", "switch groq", "switch local", "switch auto",
        "switch ollama", "use gemini", "use groq", "use local",
        "status", "memory", "clear", "tokens", "model", "models",
        "train", "train model", "train nila",
        "quit", "exit",
    ],

    # Agent actions (course creation, KB)
    "agent_action": [
        "create a course", "make a course", "i want to learn",
        "help me learn", "teach me", "learning plan",
        "remember this", "store this", "save this", "note this",
        "what do you know about", "tell me about my", "recall",
        "done day", "done",
    ],

    # Web search needed
    "needs_web": [
        "news", "latest", "weather", "price", "stock", "score",
        "restaurant", "hotel", "near me", "near",
        "search for", "find me", "look up",
    ],
}


class IntentClassifier:
    """
    Fast two-stage intent classifier.
    
    Usage:
        classifier = IntentClassifier()
        intent, confidence = classifier.classify("hello there")
        # → ("instant_greeting", 1.0)
    """

    def __init__(self):
        # Build trie from all known phrases
        self._trie: dict = {}
        self._exact_map: dict[str, str] = {}  # exact phrase → intent
        self._prefix_map: list[tuple[str, str]] = []  # (prefix, intent)
        self._build_index()

        # Embedding-based stage 2 (lazy loaded)
        self._embeddings_loaded = False
        self._intent_embeddings = {}

    def _build_index(self):
        """Build lookup structures for Stage 1."""
        for intent, phrases in INTENT_PHRASES.items():
            for phrase in phrases:
                phrase_lower = phrase.lower().strip()
                # Exact match
                self._exact_map[phrase_lower] = intent
                # Prefix match (for phrases ending with space, like "run ")
                if phrase_lower.endswith(" "):
                    self._prefix_map.append((phrase_lower, intent))

        # Sort prefix map by length (longest first) for greedy matching
        self._prefix_map.sort(key=lambda x: len(x[0]), reverse=True)

    def classify(self, message: str) -> tuple[str, float]:
        """
        Classify a message into an intent.

        Returns:
            (intent_name, confidence) where confidence is 0.0-1.0.
            Returns ("unknown", 0.0) if no match found.
        """
        msg = message.lower().strip()

        # ── Stage 1: Exact + Prefix Match (< 1ms) ────────────────────

        # Exact match
        if msg in self._exact_map:
            return self._exact_map[msg], 1.0

        # Prefix match
        for prefix, intent in self._prefix_map:
            if msg.startswith(prefix):
                return intent, 0.95

        # Substring match (check if any known phrase is contained in message)
        # Only for short messages (< 8 words) to avoid false positives
        words = msg.split()
        if len(words) <= 8:
            for phrase, intent in self._exact_map.items():
                # Only match multi-word phrases as substrings
                if " " in phrase and phrase in msg:
                    return intent, 0.85

        # ── Stage 2: Cosine Similarity (< 20ms) ──────────────────────
        # Only attempt if the sentence-transformers model is available
        # (it's already loaded for RAG, so this is essentially free)
        result = self._cosine_classify(msg)
        if result:
            return result

        return "unknown", 0.0

    def _cosine_classify(self, msg: str) -> Optional[tuple[str, float]]:
        """
        Use pre-computed embeddings for semantic intent matching.
        Lazy-loads the embedding model (shared with RAG system).
        """
        if not self._embeddings_loaded:
            try:
                self._load_embeddings()
            except Exception:
                self._embeddings_loaded = True  # don't retry
                return None

        if not self._intent_embeddings:
            return None

        try:
            from sentence_transformers import SentenceTransformer
            import numpy as np

            # Get embedding for user message
            if not hasattr(self, '_embed_model'):
                return None

            msg_embedding = self._embed_model.encode(msg, normalize_embeddings=True)

            best_intent = None
            best_score = 0.0

            for intent, embedding in self._intent_embeddings.items():
                score = float(np.dot(msg_embedding, embedding))
                if score > best_score:
                    best_score = score
                    best_intent = intent

            # Only return if confidence is high enough
            if best_intent and best_score > 0.75:
                return best_intent, best_score

        except Exception:
            pass

        return None

    def _load_embeddings(self):
        """Pre-compute intent category embeddings."""
        self._embeddings_loaded = True

        try:
            from sentence_transformers import SentenceTransformer
            import numpy as np

            # Use the same model as RAG (already likely cached)
            from core.config import EMBEDDING_MODEL
            self._embed_model = SentenceTransformer(EMBEDDING_MODEL)

            # Create a representative sentence for each intent category
            intent_descriptions = {
                "instant_greeting": "greeting hello hi how are you bye thanks",
                "data_query": "courses progress goals facts information today lesson",
                "system_action": "volume brightness bluetooth wifi screenshot mute",
                "terminal_action": "create file folder read write delete run execute",
                "voice_command": "stop talking repeat say again voice mode",
                "system_command": "switch model status memory clear tokens",
                "agent_action": "create course learn remember store recall knowledge",
                "needs_web": "search news weather restaurant find latest current",
            }

            for intent, description in intent_descriptions.items():
                self._intent_embeddings[intent] = self._embed_model.encode(
                    description, normalize_embeddings=True
                )

        except ImportError:
            # sentence-transformers not available
            pass
        except Exception:
            pass


# ─── Singleton ────────────────────────────────────────────────────────

_classifier: Optional[IntentClassifier] = None


def get_classifier() -> IntentClassifier:
    """Get the global intent classifier (lazy-initialized singleton)."""
    global _classifier
    if _classifier is None:
        _classifier = IntentClassifier()
    return _classifier


def fast_classify(message: str) -> tuple[str, float]:
    """
    Convenience function: classify a message using the global classifier.
    Returns (intent, confidence).
    """
    return get_classifier().classify(message)
