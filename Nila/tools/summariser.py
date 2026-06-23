"""
Nila Summariser Tool
Uses Google Gemini (new SDK) directly to condense scraped content.
"""

from google import genai
from google.genai import types
from core.config import GOOGLE_API_KEY, MODEL_NAME


def summarise_text(text: str, context: str = "") -> str:
    """
    Produce a clean, concise summary of the given text.

    Args:
        text:    The text to summarise.
        context: Optional context about why we're summarising this.

    Returns:
        A condensed summary string.
    """
    if not text.strip():
        return "[Nothing to summarise — input was empty]"

    client = genai.Client(api_key=GOOGLE_API_KEY)

    system_msg = (
        "You are a concise summariser. Produce a clear, factual summary "
        "of the provided text. Keep it under 300 words. "
        "Preserve key facts, numbers, and actionable details."
    )

    user_msg = "Summarise this text"
    if context:
        user_msg += f" (context: {context})"
    user_msg += f":\n\n{text[:4000]}"

    try:
        response = client.models.generate_content(
            model=MODEL_NAME,
            contents=user_msg,
            config=types.GenerateContentConfig(
                system_instruction=system_msg,
                max_output_tokens=512,
            ),
        )
        return response.text or "[No summary generated]"
    except Exception as e:
        return f"[Summarisation failed: {e}]"
