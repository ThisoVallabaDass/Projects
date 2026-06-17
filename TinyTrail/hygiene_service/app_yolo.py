"""
TinyTrails Hygiene Service - YOLOv8 Object Detection API
=========================================================
Provides /verify-daily endpoint for hygiene anomaly detection with bounding boxes.

Usage:
    uvicorn app_yolo:app --host 0.0.0.0 --port 9000 --reload

Environment Variables:
    YOLO_WEIGHTS_PATH: Path to custom YOLOv8 weights (default: weights/hygiene_yolov8_best.pt)
    YOLO_CONFIDENCE:   Minimum confidence threshold (default: 0.25)
    YOLO_IOU:          IoU threshold for NMS (default: 0.45)
"""

import io
import os
from pathlib import Path
from typing import Any, Optional

import numpy as np
from fastapi import FastAPI, File, HTTPException, UploadFile, Form
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from PIL import Image

# =============================================================================
# CONFIGURATION
# =============================================================================

SERVICE_DIR = Path(__file__).resolve().parent
DEFAULT_WEIGHTS = SERVICE_DIR / "weights" / "hygiene_yolov8_best.pt"

WEIGHTS_PATH = Path(os.environ.get("YOLO_WEIGHTS_PATH", str(DEFAULT_WEIGHTS)))
CONFIDENCE_THRESHOLD = float(os.environ.get("YOLO_CONFIDENCE", "0.25"))
IOU_THRESHOLD = float(os.environ.get("YOLO_IOU", "0.45"))

# Class names matching data.yaml
CLASS_NAMES = [
    "spill",
    "dirty_utensil",
    "food_waste",
    "grease_buildup",
    "dirty_surface",
    "pest_evidence",
]

# Severity mapping for pass/fail logic
CLASS_SEVERITY = {
    "spill": 2,           # Moderate
    "dirty_utensil": 2,   # Moderate
    "food_waste": 3,      # High
    "grease_buildup": 2,  # Moderate
    "dirty_surface": 1,   # Low
    "pest_evidence": 5,   # Critical - immediate fail
}

# Pass/fail thresholds
MAX_TOTAL_SEVERITY = 5      # Total severity score to fail
CRITICAL_CLASSES = {"pest_evidence"}  # Instant fail if detected


# =============================================================================
# APP SETUP
# =============================================================================

app = FastAPI(
    title="TinyTrails Hygiene Service (YOLOv8)",
    version="2.0.0",
    description="Hygiene anomaly detection with bounding boxes for Indian kitchens/street food karts"
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


# =============================================================================
# MODEL STATE (Lazy Loading)
# =============================================================================

class YOLOModelState:
    """Singleton to hold loaded YOLO model."""

    def __init__(self):
        self._model = None
        self._loaded = False

    def load(self):
        """Load YOLO model lazily on first request."""
        if self._loaded:
            return

        try:
            from ultralytics import YOLO
        except ImportError:
            raise RuntimeError(
                "ultralytics package not installed. Run: pip install ultralytics"
            )

        if not WEIGHTS_PATH.exists():
            raise RuntimeError(
                f"YOLO weights not found at {WEIGHTS_PATH}. "
                f"Train your model first using train_yolo.py"
            )

        print(f"Loading YOLO model from: {WEIGHTS_PATH}")
        self._model = YOLO(str(WEIGHTS_PATH))
        self._loaded = True
        print("YOLO model loaded successfully!")

    @property
    def model(self):
        if not self._loaded:
            self.load()
        return self._model


MODEL_STATE = YOLOModelState()


# =============================================================================
# RESPONSE MODELS
# =============================================================================

class BoundingBox(BaseModel):
    """Single detected anomaly with bounding box."""
    x: int           # Top-left X coordinate (pixels)
    y: int           # Top-left Y coordinate (pixels)
    width: int       # Box width (pixels)
    height: int      # Box height (pixels)
    class_id: int    # Class index (0-5)
    class_name: str  # Human-readable class name
    confidence: float  # Detection confidence (0-1)
    severity: int    # Severity level (1-5)


class VerifyDailyResponse(BaseModel):
    """Response from /verify-daily endpoint."""
    passes_inspection: bool        # True if kitchen passes hygiene check
    hygiene_score: float           # Overall score (0-100)
    total_detections: int          # Number of anomalies found
    total_severity: int            # Sum of all severity scores
    bounding_boxes: list[BoundingBox]  # List of detected anomalies
    feedback: list[str]            # User-friendly feedback messages
    original_width: int            # Input image width
    original_height: int           # Input image height


# =============================================================================
# HELPER FUNCTIONS
# =============================================================================

def load_image(file_bytes: bytes) -> Image.Image:
    """Load image from bytes and convert to RGB."""
    try:
        return Image.open(io.BytesIO(file_bytes)).convert("RGB")
    except Exception as exc:
        raise HTTPException(status_code=400, detail=f"Invalid image: {exc}") from exc


def run_inference(image: Image.Image) -> tuple[list[BoundingBox], int, int]:
    """
    Run YOLO inference on image.

    Returns:
        Tuple of (bounding_boxes, original_width, original_height)
    """
    model = MODEL_STATE.model
    original_width, original_height = image.size

    # Run inference
    results = model.predict(
        source=image,
        conf=CONFIDENCE_THRESHOLD,
        iou=IOU_THRESHOLD,
        verbose=False,
    )

    bounding_boxes = []

    if results and len(results) > 0:
        result = results[0]
        if result.boxes is not None and len(result.boxes) > 0:
            boxes = result.boxes

            for i in range(len(boxes)):
                # Get box coordinates (xyxy format: x1, y1, x2, y2)
                xyxy = boxes.xyxy[i].cpu().numpy()
                x1, y1, x2, y2 = map(int, xyxy)

                # Get class and confidence
                class_id = int(boxes.cls[i].cpu().numpy())
                confidence = float(boxes.conf[i].cpu().numpy())

                # Map to class name
                class_name = CLASS_NAMES[class_id] if class_id < len(CLASS_NAMES) else f"class_{class_id}"
                severity = CLASS_SEVERITY.get(class_name, 1)

                bounding_boxes.append(BoundingBox(
                    x=x1,
                    y=y1,
                    width=x2 - x1,
                    height=y2 - y1,
                    class_id=class_id,
                    class_name=class_name,
                    confidence=round(confidence, 4),
                    severity=severity,
                ))

    return bounding_boxes, original_width, original_height


def calculate_hygiene_score(boxes: list[BoundingBox]) -> tuple[float, bool, int, list[str]]:
    """
    Calculate overall hygiene score and pass/fail status.

    Returns:
        Tuple of (score, passes_inspection, total_severity, feedback_messages)
    """
    feedback = []

    if not boxes:
        return 100.0, True, 0, ["Kitchen looks clean! Great job maintaining hygiene."]

    # Calculate total severity
    total_severity = sum(box.severity for box in boxes)

    # Check for critical issues (instant fail)
    critical_found = any(box.class_name in CRITICAL_CLASSES for box in boxes)

    if critical_found:
        feedback.append("CRITICAL: Pest evidence detected! Immediate action required.")
        return 0.0, False, total_severity, feedback

    # Calculate score: Start at 100, deduct based on severity
    # Each severity point deducts ~10 points
    score = max(0.0, 100.0 - (total_severity * 15))

    # Determine pass/fail
    passes = total_severity <= MAX_TOTAL_SEVERITY and score >= 50

    # Generate feedback messages
    class_counts: dict[str, int] = {}
    for box in boxes:
        class_counts[box.class_name] = class_counts.get(box.class_name, 0) + 1

    for class_name, count in class_counts.items():
        if class_name == "spill":
            feedback.append(f"Found {count} spill(s) - please clean up liquid spills.")
        elif class_name == "dirty_utensil":
            feedback.append(f"Found {count} dirty utensil(s) - wash and sanitize before use.")
        elif class_name == "food_waste":
            feedback.append(f"Found {count} food waste area(s) - dispose properly and clean surface.")
        elif class_name == "grease_buildup":
            feedback.append(f"Found {count} grease buildup area(s) - degrease surfaces.")
        elif class_name == "dirty_surface":
            feedback.append(f"Found {count} dirty surface(s) - wipe down with sanitizer.")

    if passes:
        feedback.insert(0, "Minor issues found but you can start your shift. Please address the items below.")
    else:
        feedback.insert(0, "Kitchen needs cleaning before starting shift. Address the issues below:")

    return round(score, 2), passes, total_severity, feedback


# =============================================================================
# API ENDPOINTS
# =============================================================================

@app.get("/health")
async def health_check():
    """Health check endpoint."""
    model_loaded = MODEL_STATE._loaded
    weights_exist = WEIGHTS_PATH.exists()

    return {
        "status": "healthy" if weights_exist else "waiting_for_model",
        "weights_path": str(WEIGHTS_PATH),
        "weights_exist": weights_exist,
        "model_loaded": model_loaded,
        "confidence_threshold": CONFIDENCE_THRESHOLD,
        "iou_threshold": IOU_THRESHOLD,
    }


@app.post("/verify-daily", response_model=VerifyDailyResponse)
async def verify_daily(
    image: UploadFile = File(..., description="Daily hygiene check image"),
    vendor_id: Optional[str] = Form(None, description="Optional vendor ID for logging"),
):
    """
    Verify daily hygiene status of a kitchen/kart.

    Analyzes the uploaded image for hygiene anomalies and returns:
    - Pass/fail status
    - Hygiene score (0-100)
    - Bounding boxes of detected issues
    - Actionable feedback messages

    The bounding box coordinates are in pixels relative to the original image size.
    Scale them proportionally when displaying on your Flutter widget.
    """
    if not image:
        raise HTTPException(status_code=400, detail="Image file required")

    # Read and load image
    content = await image.read()
    pil_image = load_image(content)

    # Run inference
    try:
        bounding_boxes, original_width, original_height = run_inference(pil_image)
    except Exception as exc:
        raise HTTPException(
            status_code=500,
            detail=f"Inference failed: {exc}"
        ) from exc

    # Calculate scores and feedback
    hygiene_score, passes_inspection, total_severity, feedback = calculate_hygiene_score(bounding_boxes)

    return VerifyDailyResponse(
        passes_inspection=passes_inspection,
        hygiene_score=hygiene_score,
        total_detections=len(bounding_boxes),
        total_severity=total_severity,
        bounding_boxes=bounding_boxes,
        feedback=feedback,
        original_width=original_width,
        original_height=original_height,
    )


@app.post("/detect")
async def detect_anomalies(image: UploadFile = File(...)) -> dict[str, Any]:
    """
    Raw detection endpoint - returns only bounding boxes without scoring.

    Useful for debugging or when you need raw detection data.
    """
    if not image:
        raise HTTPException(status_code=400, detail="Image file required")

    content = await image.read()
    pil_image = load_image(content)

    try:
        bounding_boxes, original_width, original_height = run_inference(pil_image)
    except Exception as exc:
        raise HTTPException(
            status_code=500,
            detail=f"Inference failed: {exc}"
        ) from exc

    return {
        "detections": [box.model_dump() for box in bounding_boxes],
        "count": len(bounding_boxes),
        "image_width": original_width,
        "image_height": original_height,
    }


# =============================================================================
# MAIN
# =============================================================================

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=9000)
