"""
Nila Reasoner / Planner Tool
Uses Google Gemini (new SDK) directly to generate structured action plans.
"""

from google import genai
from google.genai import types
from core.config import GOOGLE_API_KEY, MODEL_NAME


def reflect_and_plan(goal: str, history: list, duration: str = "4 weeks") -> str:
    """
    Generate a structured action plan with daily/weekly steps.

    Args:
        goal:     The goal to plan for.
        history:  Recent conversation history (list of message dicts).
        duration: Timeframe for the plan (e.g. '3 months', '6 weeks').

    Returns:
        A formatted action plan as text.
    """
    client = genai.Client(api_key=GOOGLE_API_KEY)

    # Build a compact view of recent conversation context
    history_text = ""
    for msg in history[-10:]:
        role = msg.get("role", "unknown")
        content = msg.get("content", "")
        if isinstance(content, str):
            history_text += f"{role}: {content[:200]}\n"

    system_msg = (
        "You are a life coach and strategic planner. "
        "Given a goal and recent conversation context, produce a clear, "
        "structured action plan. Include:\n"
        "1. Goal clarity — restate the goal precisely\n"
        "2. Prerequisites — what's needed before starting\n"
        "3. Phase breakdown — split the timeframe into phases\n"
        "4. Daily/weekly actions — specific, measurable tasks\n"
        "5. Milestones — checkpoints to measure progress\n"
        "6. Potential obstacles and mitigations\n\n"
        "Be specific and actionable. No generic advice."
    )

    user_msg = (
        f"Goal: {goal}\n"
        f"Timeframe: {duration}\n\n"
        f"Recent conversation context:\n{history_text}\n\n"
        f"Create the action plan now."
    )

    try:
        response = client.models.generate_content(
            model=MODEL_NAME,
            contents=user_msg,
            config=types.GenerateContentConfig(
                system_instruction=system_msg,
                max_output_tokens=1500,
            ),
        )
        return response.text or "[No plan generated]"
    except Exception as e:
        return f"[Planning failed: {e}]"
