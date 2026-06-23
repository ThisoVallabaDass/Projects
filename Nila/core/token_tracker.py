"""
Token Usage Tracker for Nila Council system.
Tracks API usage across all online providers.
Estimates remaining free tier quota.
Saves to data/token_usage.json
"""

import json
import os
from datetime import datetime, date


class TokenTracker:
    """
    Tracks API usage for all providers.
    Estimates remaining free tier quota.
    Saves to data/token_usage.json.
    """

    # Free tier limits (approximate, as of 2026)
    FREE_LIMITS = {
        "gemini": {
            "requests_per_minute": 15,
            "requests_per_day": 1500,
            "tokens_per_minute": 1000000,
        },
        "groq": {
            "requests_per_minute": 30,
            "requests_per_day": 14400,
            "tokens_per_day": 500000,
        },
        "openrouter": {
            "credits": 1.0,  # $1 free credit
            "cost_per_1k_tokens": 0.0001,  # approx for free models
        }
    }

    def __init__(self):
        self.data_file = os.path.join(
            os.path.dirname(__file__), '..', 'data', 'token_usage.json'
        )
        self.usage = self._load()
        self._reset_if_new_day()

    def _load(self) -> dict:
        """Load existing usage data or return fresh structure."""
        try:
            with open(self.data_file, 'r') as f:
                return json.load(f)
        except (FileNotFoundError, json.JSONDecodeError):
            return {
                "gemini": {"today": {"requests": 0, "tokens_in": 0, "tokens_out": 0}, "total": {}},
                "groq": {"today": {"requests": 0, "tokens_in": 0, "tokens_out": 0}, "total": {}},
                "openrouter": {"today": {"requests": 0, "tokens_in": 0, "tokens_out": 0}, "total": {}},
                "local": {"today": {"requests": 0}, "total": {}},
                "last_reset": str(date.today())
            }

    def _save(self):
        """Save usage data to JSON file."""
        os.makedirs(os.path.dirname(self.data_file), exist_ok=True)
        with open(self.data_file, 'w') as f:
            json.dump(self.usage, f, indent=2)

    def _reset_if_new_day(self):
        """Archive yesterday's data and reset today's counter if day changed."""
        today = str(date.today())
        if self.usage.get("last_reset") != today:
            for provider in ["gemini", "groq", "openrouter", "local"]:
                # Archive yesterday
                yesterday_data = self.usage[provider].get("today", {})
                if yesterday_data and any(yesterday_data.values()):
                    prev_date = self.usage["last_reset"]
                    self.usage[provider]["total"][prev_date] = yesterday_data

                # Reset today
                self.usage[provider]["today"] = {"requests": 0, "tokens_in": 0, "tokens_out": 0}

            self.usage["last_reset"] = today
            self._save()

    def record(self, provider: str, tokens_in: int = 0, tokens_out: int = 0):
        """Call this after every API request to update usage stats."""
        self._reset_if_new_day()
        if provider not in self.usage:
            return

        self.usage[provider]["today"]["requests"] = \
            self.usage[provider]["today"].get("requests", 0) + 1
        self.usage[provider]["today"]["tokens_in"] = \
            self.usage[provider]["today"].get("tokens_in", 0) + tokens_in
        self.usage[provider]["today"]["tokens_out"] = \
            self.usage[provider]["today"].get("tokens_out", 0) + tokens_out

        self._save()

    @staticmethod
    def estimate_tokens(text: str) -> int:
        """Rough estimate: 1 token ≈ 4 characters."""
        if not text:
            return 0
        return max(1, len(text) // 4)

    def get_status_report(self) -> str:
        """Returns formatted usage report for 'tokens' command."""
        self._reset_if_new_day()
        today = str(date.today())

        lines = [f"📊 API Usage Report — {today}\n"]
        lines.append("=" * 60)

        # Gemini
        g = self.usage["gemini"]["today"]
        g_limit = self.FREE_LIMITS["gemini"]["requests_per_day"]
        g_used = g.get("requests", 0)
        g_pct = round((g_used / g_limit) * 100, 1) if g_limit > 0 else 0
        g_bar = "█" * int(g_pct / 5) + "░" * (20 - int(g_pct / 5))
        lines.append(f"\n📡 Gemini Free Tier:")
        lines.append(f"   [{g_bar}] {g_pct}%")
        lines.append(f"   {g_used}/{g_limit} requests today")
        lines.append(f"   ~{g.get('tokens_in', 0) + g.get('tokens_out', 0):,} tokens used")
        if g_pct > 80:
            lines.append("   ⚠️  WARNING: Quota almost full!")

        # Groq
        gr = self.usage["groq"]["today"]
        gr_limit = self.FREE_LIMITS["groq"]["requests_per_day"]
        gr_used = gr.get("requests", 0)
        gr_pct = round((gr_used / gr_limit) * 100, 1) if gr_limit > 0 else 0
        gr_bar = "█" * int(gr_pct / 5) + "░" * (20 - int(gr_pct / 5))
        lines.append(f"\n⚡ Groq Free Tier:")
        lines.append(f"   [{gr_bar}] {gr_pct}%")
        lines.append(f"   {gr_used}/{gr_limit} requests today")
        lines.append(f"   ~{gr.get('tokens_in', 0) + gr.get('tokens_out', 0):,} tokens used")
        if gr_pct > 80:
            lines.append("   ⚠️  WARNING: Quota almost full!")

        # OpenRouter
        or_ = self.usage["openrouter"]["today"]
        lines.append(f"\n🌐 OpenRouter:")
        lines.append(f"   {or_.get('requests', 0)} requests today")
        lines.append(f"   ~{or_.get('tokens_in', 0) + or_.get('tokens_out', 0):,} tokens used")

        # Local
        lc = self.usage["local"]["today"]
        lines.append(f"\n🖥️  Nila Local (Ollama):")
        lines.append(f"   {lc.get('requests', 0)} requests today")
        lines.append(f"   (Free — no quota limits)\n")

        # Smart recommendations
        lines.append("=" * 60)
        if g_pct > 80 and gr_pct < 50:
            lines.append("💡 Suggestion: Gemini quota full. Switch to Groq with: switch groq")
        elif gr_pct > 80:
            lines.append("💡 Suggestion: Both Gemini & Groq near limit. Use local: switch local")

        return "\n".join(lines)

    def is_provider_quota_ok(self, provider: str) -> bool:
        """Returns False if provider is near quota limit."""
        self._reset_if_new_day()
        today_data = self.usage.get(provider, {}).get("today", {})
        requests_today = today_data.get("requests", 0)

        # Conservative limits (80% of actual free tier to avoid overages)
        limits = {
            "gemini": 1200,   # 80% of 1500
            "groq": 11000,    # 80% of 14400
        }

        if provider in limits:
            return requests_today < limits[provider]
        return True

    def get_provider_recommendation(self) -> str:
        """Returns the recommended provider based on current quota usage."""
        self._reset_if_new_day()

        # Check each provider and return first available
        if self.is_provider_quota_ok("gemini"):
            return "gemini"
        elif self.is_provider_quota_ok("groq"):
            return "groq"
        elif self.is_provider_quota_ok("openrouter"):
            return "openrouter"
        else:
            return "local"
