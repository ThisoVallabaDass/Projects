"""FastAPI hygiene service for TinyTrail vendor verification.

This module provides endpoints for:
- Training baseline hygiene models from vendor workspace photos
- Daily shift verification with mock AI logic
- Full hygiene analysis using the trained ML model
"""

from __future__ import annotations

import json
import os
import random
import shutil
from functools import lru_cache
from pathlib import Path
from typing import Annotated

from fastapi import FastAPI, File, Form, HTTPException, UploadFile
from fastapi.middleware.cors import CORSMiddleware
from PIL import Image
import torch

from workspace_inference import (
    analyze_workspace_image,
    load_workspace_model,
    verify_registration_images,
    verify_shift_image,
)


# Configuration
MODEL_PATH = os.environ.get(
    "HYGIENE_MODEL_PATH",
    os.path.join(os.path.dirname(__file__), "models", "hygiene_model.pth"),
)
BASELINE_IMAGES_DIR = os.environ.get(
    "BASELINE_IMAGES_DIR",
    os.path.join(os.path.dirname(__file__), "vendor_baselines"),
)

app = FastAPI(
    title="TinyTrail Hygiene Service",
    version="3.0.0",
    description="Workspace-focused hygiene scoring, baseline training, and daily verification for food vendors.",
)

# Enable CORS for Flutter emulator communication
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


# ============================================================================
# Helper Functions
# ============================================================================

def _open_upload(upload: UploadFile) -> Image.Image:
    """Open an uploaded file as a PIL Image."""
    try:
        return Image.open(upload.file).convert("RGB")
    except Exception as exc:
        raise HTTPException(status_code=400, detail=f"Invalid image upload: {upload.filename}") from exc
    finally:
        upload.file.seek(0)


@lru_cache(maxsize=1)
def get_loaded_model():
    """Load and cache the hygiene model."""
    device = torch.device("cuda" if torch.cuda.is_available() else "cpu")
    return load_workspace_model(MODEL_PATH, device=device)


def _ensure_vendor_dir(vendor_id: str) -> Path:
    """Create and return a directory for storing vendor baseline images."""
    vendor_dir = Path(BASELINE_IMAGES_DIR) / vendor_id
    vendor_dir.mkdir(parents=True, exist_ok=True)
    return vendor_dir


def _mock_ai_comparison() -> dict:
    """
    Simulate AI image comparison with 80% success rate.
    Returns mock hygiene check result.
    """
    success = random.random() < 0.80  # 80% chance of success

    if success:
        score = random.randint(85, 98)
        return {
            "hygiene_passed": True,
            "score": score,
            "message": "Workspace is clean and meets hygiene standards.",
            "status": "approved",
            "details": {
                "counter_cleanliness": "excellent",
                "floor_condition": "good",
                "equipment_status": "sanitized",
            }
        }
    else:
        score = random.randint(35, 55)
        # Mock bounding boxes for detected issues
        bounding_boxes = [
            [random.randint(50, 150), random.randint(50, 150),
             random.randint(180, 250), random.randint(180, 250)]
        ]

        issues = random.choice([
            "Dirt detected on the counter.",
            "Unclean utensils visible in workspace.",
            "Spills detected on food preparation surface.",
            "Clutter detected near cooking area.",
        ])

        return {
            "hygiene_passed": False,
            "score": score,
            "message": issues,
            "status": "rejected",
            "bounding_boxes": bounding_boxes,
            "details": {
                "issue_type": "cleanliness",
                "severity": "moderate",
                "recommendation": "Please clean the highlighted area and retake the photo.",
            }
        }


# ============================================================================
# NEW ENDPOINTS - Train Baseline & Verify Daily
# ============================================================================

@app.post("/train-baseline")
async def train_baseline(
    vendor_id: Annotated[str, Form(...)],
    images: Annotated[list[UploadFile], File(...)],
) -> dict:
    """
    Train baseline hygiene model for a vendor.

    Accepts a vendor ID and an array of 5 image files representing
    their clean workspace state. These images are saved locally and
    will be used for future daily verification comparisons.

    Args:
        vendor_id: Unique identifier for the vendor
        images: List of 5 image files showing clean workspace

    Returns:
        JSON response with training status
    """
    # Validate input
    if not vendor_id or not vendor_id.strip():
        raise HTTPException(status_code=400, detail="vendor_id is required")

    if len(images) < 5:
        raise HTTPException(
            status_code=400,
            detail=f"Please upload at least 5 baseline images. Received: {len(images)}"
        )

    # Limit to first 10 images if more are provided
    images = images[:10]

    vendor_id = vendor_id.strip()
    vendor_dir = _ensure_vendor_dir(vendor_id)

    # Clear existing baseline images for this vendor
    for existing_file in vendor_dir.glob("baseline_*.jpg"):
        existing_file.unlink()

    saved_files = []

    try:
        for idx, image_file in enumerate(images):
            # Validate and process image
            pil_image = _open_upload(image_file)

            # Save image to vendor directory
            filename = f"baseline_{idx + 1}.jpg"
            file_path = vendor_dir / filename
            pil_image.save(file_path, "JPEG", quality=90)
            saved_files.append(str(file_path))

        return {
            "status": "success",
            "message": "Baseline trained successfully",
            "vendor_id": vendor_id,
            "images_saved": len(saved_files),
            "baseline_path": str(vendor_dir),
            "next_step": "You can now use /verify-daily for daily hygiene checks"
        }

    except Exception as exc:
        # Clean up any partially saved files on error
        for file_path in saved_files:
            try:
                Path(file_path).unlink()
            except:
                pass
        raise HTTPException(status_code=500, detail=f"Failed to save baseline images: {exc}")


@app.post("/verify-daily")
async def verify_daily(
    vendor_id: Annotated[str, Form(...)],
    image: Annotated[UploadFile, File(...)],
) -> dict:
    """
    Verify daily hygiene status for a vendor.

    Accepts a vendor ID and one image file (the current shift photo).
    Uses mock AI logic that randomly succeeds (80%) or fails (20%).

    Args:
        vendor_id: Unique identifier for the vendor
        image: Current shift workspace photo

    Returns:
        JSON response with hygiene verification result
    """
    # Validate input
    if not vendor_id or not vendor_id.strip():
        raise HTTPException(status_code=400, detail="vendor_id is required")

    vendor_id = vendor_id.strip()

    # Validate vendor has baseline images
    vendor_dir = Path(BASELINE_IMAGES_DIR) / vendor_id
    if not vendor_dir.exists():
        raise HTTPException(
            status_code=404,
            detail=f"No baseline found for vendor {vendor_id}. Please complete /train-baseline first."
        )

    baseline_images = list(vendor_dir.glob("baseline_*.jpg"))
    if len(baseline_images) < 5:
        raise HTTPException(
            status_code=400,
            detail=f"Incomplete baseline for vendor {vendor_id}. Found {len(baseline_images)} images, need at least 5."
        )

    # Validate the uploaded image
    pil_image = _open_upload(image)

    # Save the daily verification image for records
    daily_dir = vendor_dir / "daily_checks"
    daily_dir.mkdir(exist_ok=True)

    from datetime import datetime
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    daily_image_path = daily_dir / f"check_{timestamp}.jpg"
    pil_image.save(daily_image_path, "JPEG", quality=85)

    # Perform mock AI comparison
    result = _mock_ai_comparison()
    result["vendor_id"] = vendor_id
    result["timestamp"] = timestamp
    result["daily_image_saved"] = str(daily_image_path)

    return result


# ============================================================================
# EXISTING ENDPOINTS - Full ML Model Integration
# ============================================================================

@app.post("/verify-hygiene")
def verify_hygiene(image: Annotated[UploadFile, File(...)]) -> dict:
    """Primary endpoint consumed by the Flutter app for full ML-based verification."""
    pil_image = _open_upload(image)

    try:
        loaded = get_loaded_model()
        result = analyze_workspace_image(pil_image, loaded)
        score = float(result.get("score", 0))
        status = "approved" if score >= 85 else "rejected"
        message = result.get("message") or (
            "Workspace is clean" if status == "approved" else "Workspace hygiene needs attention"
        )
        return {
            "score": round(score, 2),
            "status": status,
            "message": message,
            "raw": result,
        }
    except Exception as exc:
        # Fallback to mock response if model inference fails
        fallback = _mock_ai_comparison()
        fallback["note"] = f"Using mock score because model inference failed: {exc}"
        return fallback


@app.get("/health")
def health() -> dict:
    """Health check endpoint with model information."""
    try:
        loaded = get_loaded_model()
        return {
            "status": "ok",
            "modelPath": MODEL_PATH,
            "architecture": loaded.arch,
            "classes": loaded.class_names,
            "device": str(loaded.device),
            "baselineDir": BASELINE_IMAGES_DIR,
        }
    except Exception as exc:
        return {
            "status": "degraded",
            "modelPath": MODEL_PATH,
            "error": str(exc),
            "note": "Model not loaded - mock verification available",
            "baselineDir": BASELINE_IMAGES_DIR,
        }


@app.post("/predict")
def predict(image: Annotated[UploadFile, File(...)]) -> dict:
    """Raw ML model prediction endpoint."""
    loaded = get_loaded_model()
    result = analyze_workspace_image(_open_upload(image), loaded)
    return result


@app.post("/verify-registration")
def verify_registration(
    images: Annotated[list[UploadFile], File(...)],
    min_score: Annotated[float, Form()] = 0.75,
) -> dict:
    """Verify multiple registration images meet hygiene standards."""
    if len(images) < 5:
        raise HTTPException(status_code=400, detail="Upload at least 5 baseline workspace images.")
    if len(images) > 10:
        images = images[:10]

    loaded = get_loaded_model()
    pil_images = [_open_upload(image) for image in images]
    return verify_registration_images(pil_images, loaded, min_score=min_score)


@app.post("/verify-shift")
def verify_shift(
    image: Annotated[UploadFile, File(...)],
    reference_embedding: Annotated[str, Form(...)],
    score_threshold: Annotated[float, Form()] = 0.70,
    similarity_threshold: Annotated[float, Form()] = 0.60,
) -> dict:
    """Verify daily shift image against stored reference embedding."""
    try:
        parsed_embedding = json.loads(reference_embedding)
    except json.JSONDecodeError as exc:
        raise HTTPException(status_code=400, detail="reference_embedding must be valid JSON.") from exc

    if not isinstance(parsed_embedding, list) or not parsed_embedding:
        raise HTTPException(status_code=400, detail="reference_embedding must be a non-empty float array.")

    loaded = get_loaded_model()
    return verify_shift_image(
        _open_upload(image),
        parsed_embedding,
        loaded,
        score_threshold=score_threshold,
        similarity_threshold=similarity_threshold,
    )


@app.post("/compare")
def compare(
    image: Annotated[UploadFile, File(...)],
    reference_embedding: Annotated[str, Form(...)],
) -> dict:
    """Compatibility alias for similarity checks."""
    return verify_shift(
        image=image,
        reference_embedding=reference_embedding,
        score_threshold=0.0,
        similarity_threshold=0.0,
    )


@app.get("/vendors/{vendor_id}/baseline-status")
def get_baseline_status(vendor_id: str) -> dict:
    """Check if a vendor has completed baseline training."""
    vendor_dir = Path(BASELINE_IMAGES_DIR) / vendor_id

    if not vendor_dir.exists():
        return {
            "vendor_id": vendor_id,
            "has_baseline": False,
            "images_count": 0,
            "status": "not_started",
        }

    baseline_images = list(vendor_dir.glob("baseline_*.jpg"))
    images_count = len(baseline_images)

    return {
        "vendor_id": vendor_id,
        "has_baseline": images_count >= 5,
        "images_count": images_count,
        "status": "complete" if images_count >= 5 else "incomplete",
        "baseline_path": str(vendor_dir),
    }


# ============================================================================
# Run with uvicorn
# ============================================================================

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000, reload=True)
