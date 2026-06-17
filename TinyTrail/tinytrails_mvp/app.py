"""TinyTrails hygiene backend integrated with Hygine model pipeline."""

from __future__ import annotations

import os
import sys
from pathlib import Path
from typing import Any

from fastapi import FastAPI, File, Form, HTTPException, UploadFile
from fastapi.middleware.cors import CORSMiddleware
from PIL import Image
import torch


PROJECT_ROOT = Path(__file__).resolve().parent
HYGINE_ROOT = Path(r"T:\College\Project\TinyTrail\Hygine").resolve()
if str(HYGINE_ROOT) not in sys.path:
    sys.path.insert(0, str(HYGINE_ROOT))

from workspace_inference import (  # noqa: E402
    load_workspace_model,
    verify_registration_images,
    verify_shift_image,
)


MODEL_PATH = os.environ.get(
    "HYGIENE_MODEL_PATH",
    str(HYGINE_ROOT / "models" / "hygiene_model.pth"),
)

app = FastAPI(
    title="TinyTrails Hygiene Service",
    version="3.0.0",
    description="Food-vendor baseline training and daily hygiene verification.",
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

_cached_model = None


def _open_upload(upload: UploadFile) -> Image.Image:
    try:
        return Image.open(upload.file).convert("RGB")
    except Exception as exc:  # pragma: no cover
        raise HTTPException(status_code=400, detail=f"Invalid image: {upload.filename}") from exc
    finally:
        upload.file.seek(0)


def _loaded_model():
    global _cached_model
    if _cached_model is None:
        device = torch.device("cuda" if torch.cuda.is_available() else "cpu")
        _cached_model = load_workspace_model(MODEL_PATH, device=device)
    return _cached_model


@app.get("/health")
def health() -> dict[str, Any]:
    loaded = _loaded_model()
    return {
        "status": "ok",
        "modelPath": MODEL_PATH,
        "arch": loaded.arch,
        "classes": loaded.class_names,
        "device": str(loaded.device),
    }


@app.post("/train-baseline")
def train_baseline(images: list[UploadFile] = File(...)) -> dict[str, Any]:
    if len(images) != 5:
        raise HTTPException(status_code=400, detail=f"Expected 5 images, got {len(images)}")

    loaded = _loaded_model()
    pil_images = [_open_upload(image) for image in images]
    verification = verify_registration_images(
        pil_images,
        loaded,
        min_score=0.75,
    )

    if not verification["approved"]:
        return {
            "status": "baseline_rejected",
            "message": "Workspace baseline did not meet cleanliness standards.",
            "reasons": verification["reasons"],
            "results": verification["results"],
        }

    return {
        "status": "baseline_saved",
        "message": "Baseline accepted and reference embedding generated.",
        "referenceEmbedding": verification["referenceEmbedding"],
        "results": verification["results"],
    }


@app.post("/verify-daily")
def verify_daily(
    image: UploadFile = File(...),
    reference_embedding: str = Form(default=""),
) -> dict[str, Any]:
    if not reference_embedding:
        raise HTTPException(status_code=400, detail="reference_embedding is required for daily verification.")

    try:
        import json

        parsed_embedding = json.loads(reference_embedding)
    except Exception as exc:
        raise HTTPException(status_code=400, detail="reference_embedding must be valid JSON array.") from exc

    if not isinstance(parsed_embedding, list) or not parsed_embedding:
        raise HTTPException(status_code=400, detail="reference_embedding must be a non-empty float array.")

    loaded = _loaded_model()
    result = verify_shift_image(
        _open_upload(image),
        parsed_embedding,
        loaded,
        score_threshold=0.70,
        similarity_threshold=0.60,
    )

    if result["allowed"]:
        return {
            "status": "passed",
            "message": "Daily hygiene verified. Shift can start.",
            "score": result["score"],
            "similarity": result["similarity"],
            "attentionZone": result["attentionZone"],
            "issues": result["issues"],
        }

    # Convert attention zone into an approximate normalized bounding box.
    zone = result.get("attentionZone", "overall_workspace")
    zone_boxes: dict[str, list[float]] = {
        "left_counter": [0.03, 0.32, 0.45, 0.58],
        "center_prep_zone": [0.20, 0.25, 0.60, 0.60],
        "right_counter": [0.52, 0.32, 0.45, 0.58],
        "stove_band": [0.14, 0.45, 0.72, 0.48],
        "overall_workspace": [0.08, 0.20, 0.84, 0.72],
    }
    box = zone_boxes.get(zone, zone_boxes["overall_workspace"])

    return {
        "status": "failed",
        "message": "Hygiene failed. Please clean the highlighted area and retry.",
        "score": result["score"],
        "similarity": result["similarity"],
        "reason": result["reason"],
        "anomalies": [
            {
                "issue": result["reason"],
                "box": box,
            }
        ],
        "attentionZone": zone,
        "issues": result.get("issues", []),
    }


@app.post("/verify-daily-batch")
def verify_daily_batch(
    images: list[UploadFile] = File(...),
    reference_embedding: str = Form(default=""),
) -> dict[str, Any]:
    """Best-of-3 daily verification for food vendors."""
    if not images:
        raise HTTPException(status_code=400, detail="At least one image is required.")
    if len(images) > 3:
        raise HTTPException(status_code=400, detail="Maximum 3 images are allowed.")
    if not reference_embedding:
        raise HTTPException(status_code=400, detail="reference_embedding is required for daily verification.")

    try:
        import json

        parsed_embedding = json.loads(reference_embedding)
    except Exception as exc:
        raise HTTPException(status_code=400, detail="reference_embedding must be valid JSON array.") from exc

    if not isinstance(parsed_embedding, list) or not parsed_embedding:
        raise HTTPException(status_code=400, detail="reference_embedding must be a non-empty float array.")

    loaded = _loaded_model()
    attempts: list[dict[str, Any]] = []
    for image in images:
        attempts.append(
            verify_shift_image(
                _open_upload(image),
                parsed_embedding,
                loaded,
                score_threshold=0.70,
                similarity_threshold=0.60,
            )
        )

    passed_attempts = [a for a in attempts if a.get("allowed") is True]
    best_attempt = max(
        attempts,
        key=lambda a: (float(a.get("score", 0.0)), float(a.get("similarity", 0.0))),
    )

    if passed_attempts:
        winner = max(
            passed_attempts,
            key=lambda a: (float(a.get("score", 0.0)), float(a.get("similarity", 0.0))),
        )
        return {
            "status": "passed",
            "message": "Daily hygiene verified. Shift can start.",
            "score": winner["score"],
            "similarity": winner["similarity"],
            "attentionZone": winner["attentionZone"],
            "issues": winner["issues"],
            "bestAttemptIndex": attempts.index(winner),
            "attempts": attempts,
        }

    zone = best_attempt.get("attentionZone", "overall_workspace")
    zone_boxes: dict[str, list[float]] = {
        "left_counter": [0.03, 0.32, 0.45, 0.58],
        "center_prep_zone": [0.20, 0.25, 0.60, 0.60],
        "right_counter": [0.52, 0.32, 0.45, 0.58],
        "stove_band": [0.14, 0.45, 0.72, 0.48],
        "overall_workspace": [0.08, 0.20, 0.84, 0.72],
    }
    box = zone_boxes.get(zone, zone_boxes["overall_workspace"])

    return {
        "status": "failed",
        "message": "Hygiene failed. Please clean the highlighted area and retry.",
        "score": best_attempt["score"],
        "similarity": best_attempt["similarity"],
        "reason": best_attempt["reason"],
        "anomalies": [{"issue": best_attempt["reason"], "box": box}],
        "attentionZone": zone,
        "issues": best_attempt.get("issues", []),
        "bestAttemptIndex": attempts.index(best_attempt),
        "attempts": attempts,
    }
