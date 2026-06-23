"""
Display learning/adaptation status in a user-friendly way.
"""

import json
from typing import Dict


class LearningStatusDisplay:
    """Display Nila's learning progress in the overlay."""

    @staticmethod
    def format_status(status: Dict) -> str:
        """Format learning status for display."""
        if not status or not any([
            status.get("self_trainer"),
            status.get("adaptation"),
            status.get("model"),
        ]):
            return "🧠 Learning dormant..."

        display_lines = []

        # Self-trainer stats
        st = status.get("self_trainer", {})
        if st:
            routines = st.get("routines_count", 0)
            prefs = st.get("preferences_count", 0)
            goals = st.get("goals_count", 0)

            if any([routines, prefs, goals]):
                display_lines.append(
                    f"💾 Memory: {routines} routines, {prefs} prefs, {goals} goals"
                )

        # Adaptation stats
        ad = status.get("adaptation", {})
        if ad:
            convs = ad.get("conversations_processed", 0)
            pairs = ad.get("training_pairs_accumulated", 0)
            strength = ad.get("adaptation_strength", 0)
            next_retrain = ad.get("next_retrain_in", 0)

            if convs > 0:
                emoji = "⚡" if strength > 50 else "✨" if strength > 25 else "🌱"
                display_lines.append(
                    f"{emoji} Learned from {convs} messages, {strength:.0f}% adapted"
                )
                if next_retrain <= 5:
                    display_lines.append(f"🛠️  Model tune-up in {next_retrain} messages")

        return "\n".join(display_lines) if display_lines else "🧠 Learning..."

    @staticmethod
    def get_quick_tip(status: Dict) -> str:
        """Get a quick learning tip to display."""
        ad = status.get("adaptation", {})
        convs = ad.get("conversations_processed", 0) if ad else 0

        tips = [
            "🌱 Nila is learning your patterns",
            "💡 Every message helps me understand you better",
            "🎯 I'm studying your preferences",
            "🧠 Building your personalized model",
            "🚀 Getting faster at knowing what you need",
            "📝 Remembering your style and goals",
        ]

        if convs == 0:
            return tips[0]
        elif convs < 10:
            return tips[1]
        elif convs < 25:
            return tips[2]
        elif convs < 50:
            return tips[3]
        else:
            return tips[min(convs // 25, len(tips) - 1)]

    @staticmethod
    def format_full_report(status: Dict) -> str:
        """Format a detailed learning report."""
        report = []
        report.append("╔══════════════════════════════════════════╗")
        report.append("║     NILA LEARNING STATUS REPORT          ║")
        report.append("╚══════════════════════════════════════════╝\n")

        # Self-trainer
        st = status.get("self_trainer", {})
        report.append("📚 MEMORY EXTRACTION:")
        report.append(f"  • Routines learned: {st.get('routines_count', 0)}")
        report.append(f"  • Preferences recorded: {st.get('preferences_count', 0)}")
        report.append(f"  • Progress tracked: {st.get('progress_entries', 0)}")
        report.append(f"  • Personality notes: {st.get('personality_observations', 0)}")
        report.append(f"  • Total facts: {st.get('facts_count', 0)}\n")

        # Adaptation
        ad = status.get("adaptation", {})
        report.append("🧠 PERSONALIZATION:")
        report.append(f"  • Conversations parsed: {ad.get('conversations_processed', 0)}")
        report.append(f"  • Training pairs accumulated: {ad.get('training_pairs_accumulated', 0)}")
        report.append(f"  • Adaptation strength: {ad.get('adaptation_strength', 0):.0f}%")
        report.append(f"  • Next model tune: {ad.get('next_retrain_in', 'N/A')} exchanges\n")

        # Model
        md = status.get("model", {})
        report.append("⚙️  MODEL ADAPTATION:")
        report.append(f"  • Model version: {md.get('model_version', 'N/A')}")
        report.append(f"  • Last trained: {md.get('last_adapted', 'Not yet')}")
        report.append(f"  • Total trainings: {md.get('trainings', 0)}\n")

        report.append("═══════════════════════════════════════════")
        return "\n".join(report)
