"""
Context Chain — Maintains rolling conversation context for continuity.

Before each model call, produces a condensed chain summary so the model
always reviews prior context before replying. This prevents generic,
out-of-context answers and creates a natural conversational flow.
"""

import time
from typing import Optional


class ContextChain:
    """
    Maintains a rolling chain of conversation exchanges.
    
    Each exchange stores:
    - user message
    - assistant response (truncated for efficiency)
    - timestamp
    - topic hint (extracted keywords)
    
    The chain is used to produce a structured context block that gets
    prepended to the system prompt before every model call.
    """

    def __init__(self, max_pairs: int = 8):
        """
        Args:
            max_pairs: Maximum number of exchange pairs to keep in the chain.
                       Older exchanges are dropped when the limit is exceeded.
        """
        self.chain: list[dict] = []
        self.max_pairs = max_pairs

    def add_exchange(self, user_msg: str, assistant_msg: str):
        """Record a user→assistant exchange in the chain."""
        # Truncate long responses for chain efficiency
        trunc_response = assistant_msg[:300] + "..." if len(assistant_msg) > 300 else assistant_msg
        
        self.chain.append({
            "user": user_msg,
            "assistant": trunc_response,
            "time": time.strftime("%H:%M"),
            "topic": self._extract_topic(user_msg),
        })

        # Keep only the latest N exchanges
        if len(self.chain) > self.max_pairs:
            self.chain = self.chain[-self.max_pairs:]

    def get_chain_prompt(self) -> str:
        """
        Build a structured context block to prepend to the system prompt.
        
        Returns an empty string if there's no conversation history,
        so first messages don't get a useless preamble.
        """
        if not self.chain:
            return ""

        lines = ["CONVERSATION CONTEXT (review this before replying):"]
        
        for i, ex in enumerate(self.chain, 1):
            topic = f" [{ex['topic']}]" if ex['topic'] else ""
            # Compact summary of each exchange
            user_short = ex['user'][:120] + "..." if len(ex['user']) > 120 else ex['user']
            asst_short = ex['assistant'][:150] + "..." if len(ex['assistant']) > 150 else ex['assistant']
            lines.append(f"[{i}] User: {user_short}")
            lines.append(f"    Nila: {asst_short}")

        # Add thread summary
        thread = self._detect_thread()
        if thread:
            lines.append(f"\nCURRENT THREAD: {thread}")
        
        lines.append("Continue naturally from the above context. Do not repeat previous answers.\n")

        return "\n".join(lines)

    def get_last_exchange(self) -> Optional[dict]:
        """Get the most recent exchange, or None if empty."""
        return self.chain[-1] if self.chain else None

    def get_chain_length(self) -> int:
        """How many exchanges are in the chain."""
        return len(self.chain)

    def clear(self):
        """Clear the entire chain (used on 'clear' command)."""
        self.chain.clear()

    def _extract_topic(self, msg: str) -> str:
        """
        Extract a brief topic hint from the user message.
        Returns a short keyword string or empty string.
        """
        msg_lower = msg.lower()
        
        # Topic patterns
        topic_map = {
            "course": "courses/learning",
            "study": "studying",
            "code": "coding",
            "python": "Python",
            "javascript": "JavaScript",
            "html": "web development",
            "css": "web development",
            "file": "file operations",
            "open": "system action",
            "volume": "system control",
            "bluetooth": "system control",
            "brightness": "system control",
            "todo": "tasks",
            "schedule": "schedule",
            "project": "project work",
            "error": "debugging",
            "fix": "debugging",
            "explain": "explanation",
            "how": "learning",
            "what": "question",
            "why": "question",
        }

        for keyword, topic in topic_map.items():
            if keyword in msg_lower:
                return topic
        
        return ""

    def _detect_thread(self) -> str:
        """
        Detect the overall conversation thread from recent exchanges.
        Returns a one-line summary string.
        """
        if not self.chain:
            return ""

        # Collect recent topics
        recent_topics = [ex['topic'] for ex in self.chain[-4:] if ex['topic']]
        
        if not recent_topics:
            return "General conversation"

        # If all recent topics are the same, that's the thread
        unique_topics = list(dict.fromkeys(recent_topics))  # ordered unique
        
        if len(unique_topics) == 1:
            return f"User is focused on {unique_topics[0]}"
        elif len(unique_topics) <= 3:
            return f"User has been discussing: {', '.join(unique_topics)}"
        else:
            return f"Conversation covers: {', '.join(unique_topics[-3:])}"
