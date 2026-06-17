"""CLI JSON prediction wrapper for backend integrations."""

from __future__ import annotations

import argparse
import json
from pathlib import Path

import torch

from workspace_inference import (
    BADGE_MAP,
    CLASS_REVIEW,
    CLASS_SAFE,
    analyze_workspace_image,
    load_workspace_model,
)


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Predict hygiene score as JSON.")
    parser.add_argument("image_path", type=str, help="Path to the uploaded image.")
    parser.add_argument("--model-path", type=str, required=True, help="Path to the trained model.")
    return parser.parse_args()


def go_live_allowed(result: dict) -> bool:
    if result["qualityChecks"]["lowLight"] or result["qualityChecks"]["blurry"]:
        return False
    if result["label"] == CLASS_SAFE:
        return True
    if result["label"] == CLASS_REVIEW and result["score"] >= 0.72:
        return True
    return False


def main() -> None:
    args = parse_args()
    image_path = Path(args.image_path)
    model_path = Path(args.model_path)

    if not image_path.exists():
        raise FileNotFoundError(f"Image not found: {image_path}")
    if not model_path.exists():
        raise FileNotFoundError(f"Model not found: {model_path}")

    device = torch.device("cuda" if torch.cuda.is_available() else "cpu")
    loaded = load_workspace_model(model_path, device=device)
    result = analyze_workspace_image(image_path, loaded)

    output = {
        "predicted_class": result["label"],
        "confidence": result["confidence"],
        "hygiene_score": int(round(result["score"] * 100)),
        "cleanliness_score": result["score"],
        "badge_text": BADGE_MAP.get(result["label"], "Review"),
        "go_live_allowed": go_live_allowed(result),
        "reason": result["advice"],
        "attention_zone": result["attentionZone"],
        "issues": result["issues"],
        "quality_checks": result["qualityChecks"],
        "policy": "tinytrail_indian_workspace_v2",
    }

    print(json.dumps(output))


if __name__ == "__main__":
    main()
