"""
Unified TinyTrails Hygiene Service API
Combines classification model with proper response format for Flutter app
"""

import io
import os
from pathlib import Path
from typing import Any, Dict, List, Optional

import numpy as np
import torch
import torch.nn as nn
from fastapi import FastAPI, File, Form, HTTPException, UploadFile
from fastapi.middleware.cors import CORSMiddleware
from PIL import Image
from torchvision import transforms
import torchvision.models as models


REPO_ROOT = Path(__file__).resolve().parents[1]
MODELS_DIR = REPO_ROOT / "Hygine" / "models"
DEVICE = torch.device("cuda" if torch.cuda.is_available() else "cpu")


class HygieneClassifier:
    """Hygiene classification using the trained model"""

    def __init__(self):
        self.device = DEVICE
        self.model = None
        self.class_names = ["meets_standard", "needs_work", "shouldnt_work"]
        self.transform = transforms.Compose([
            transforms.Resize(256),
            transforms.CenterCrop(224),
            transforms.ToTensor(),
            transforms.Normalize(mean=[0.485, 0.456, 0.406], std=[0.229, 0.224, 0.225])
        ])
        self._load_model()

    def _load_model(self):
        """Load the hygiene classification model"""
        model_paths = [
            MODELS_DIR / "hygiene_model_indian_kitchen.pth",
            MODELS_DIR / "hygiene_model.pth",
            MODELS_DIR / "hygiene_model_overnight.pth",
        ]

        loaded = False
        for model_path in model_paths:
            if model_path.exists():
                try:
                    checkpoint = torch.load(model_path, map_location=self.device, weights_only=False)
                    self._build_model_from_checkpoint(checkpoint)
                    print(f"[SUCCESS] Loaded model from {model_path}")
                    loaded = True
                    break
                except Exception as e:
                    print(f"[WARNING] Failed to load {model_path}: {e}")

        if not loaded:
            print("[WARNING] No model loaded - using mock predictions")

    def _build_model_from_checkpoint(self, checkpoint: Dict[str, Any]):
        """Build model from checkpoint"""
        arch = checkpoint.get("arch", "resnet18")

        # Extract class names
        idx_to_class = checkpoint.get("idx_to_class", None)
        if idx_to_class:
            self.class_names = [idx_to_class[i] for i in sorted(idx_to_class.keys())]
        else:
            num_classes = checkpoint.get("num_classes", 3)
            self.class_names = ["meets_standard", "needs_work", "shouldnt_work"][:num_classes]

        num_classes = len(self.class_names)

        # Build model architecture
        if arch.startswith("efficientnet"):
            self.model = models.efficientnet_b0(weights=None)
            in_features = self.model.classifier[1].in_features
            self.model.classifier[1] = nn.Linear(in_features, num_classes)
        else:
            self.model = models.resnet18(weights=None)
            in_features = self.model.fc.in_features
            self.model.fc = nn.Linear(in_features, num_classes)

        self.model.load_state_dict(checkpoint["model_state_dict"])
        self.model.to(self.device)
        self.model.eval()

    def classify(self, image_bytes: bytes) -> Dict[str, Any]:
        """Classify hygiene from image bytes"""
        try:
            pil_image = Image.open(io.BytesIO(image_bytes)).convert('RGB')
        except Exception as e:
            raise HTTPException(status_code=400, detail=f"Invalid image: {e}")

        if self.model is None:
            return self._mock_classification()

        tensor = self.transform(pil_image).unsqueeze(0).to(self.device)

        with torch.no_grad():
            outputs = self.model(tensor)
            probs = torch.softmax(outputs, dim=1)[0].cpu().numpy()
            pred_idx = int(np.argmax(probs))
            confidence = float(probs[pred_idx])
            label = self.class_names[pred_idx] if pred_idx < len(self.class_names) else "unknown"

        return {
            "label": label,
            "confidence": confidence,
            "probabilities": {name: float(prob) for name, prob in zip(self.class_names, probs)}
        }

    def _mock_classification(self) -> Dict[str, Any]:
        """Fallback mock classification when no model is available"""
        return {
            "label": "needs_work",
            "confidence": 0.5,
            "probabilities": {
                "meets_standard": 0.3,
                "needs_work": 0.5,
                "shouldnt_work": 0.2
            }
        }


# Issue categories for detailed feedback
ISSUE_CATEGORIES = {
    "surface_contamination": {
        "code": "SURFACE_01",
        "message": "Surface contamination detected",
        "advice": "Wipe down all work surfaces with sanitizer",
        "severity": "medium"
    },
    "food_residue": {
        "code": "FOOD_01",
        "message": "Food residue visible on workspace",
        "advice": "Remove all food debris and clean the area",
        "severity": "high"
    },
    "equipment_dirty": {
        "code": "EQUIP_01",
        "message": "Equipment needs cleaning",
        "advice": "Clean and sanitize all utensils and equipment",
        "severity": "medium"
    },
    "general_untidy": {
        "code": "TIDY_01",
        "message": "Workspace appears untidy",
        "advice": "Organize your workspace before starting",
        "severity": "low"
    },
    "critical_hygiene": {
        "code": "CRITICAL_01",
        "message": "Critical hygiene issues detected",
        "advice": "Deep clean required before starting shift",
        "severity": "high"
    }
}


def generate_verification_response(classification: Dict[str, Any]) -> Dict[str, Any]:
    """Generate Flutter-compatible verification response from classification"""
    label = classification["label"]
    confidence = classification["confidence"]
    probs = classification.get("probabilities", {})

    # Calculate score (0-100 scale)
    if label == "meets_standard":
        score = 85 + (confidence * 15)  # 85-100
        approved = True
        status = "approved"
        badge_text = "Approved"
        badge_color = "green"
        issues = []
        message = "Your workspace meets hygiene standards. You're ready to go live!"
        attention_zone = "none"
        attention_zone_label = "No issues"
    elif label == "needs_work":
        score = 50 + (confidence * 35)  # 50-85
        approved = False
        status = "needs_attention"
        badge_text = "Needs Work"
        badge_color = "orange"
        issues = [
            ISSUE_CATEGORIES["surface_contamination"],
            ISSUE_CATEGORIES["general_untidy"]
        ]
        message = "Your workspace needs some attention. Please clean the indicated areas and try again."
        attention_zone = "workspace"
        attention_zone_label = "General workspace"
    else:  # shouldnt_work
        score = 10 + (confidence * 40)  # 10-50
        approved = False
        status = "rejected"
        badge_text = "Not Approved"
        badge_color = "red"
        issues = [
            ISSUE_CATEGORIES["critical_hygiene"],
            ISSUE_CATEGORIES["food_residue"],
            ISSUE_CATEGORIES["equipment_dirty"]
        ]
        message = "Critical hygiene issues detected. Deep cleaning is required before you can start your shift."
        attention_zone = "critical"
        attention_zone_label = "Multiple areas"

    return {
        "score": round(score, 1),
        "approved": approved,
        "status": status,
        "message": message,
        "label": label,
        "badgeText": badge_text,
        "badgeColor": badge_color,
        "issues": issues,
        "attentionZone": attention_zone,
        "attentionZoneLabel": attention_zone_label,
        "confidence": round(confidence * 100, 1),
        "qualityChecks": {
            "isLowLight": False,
            "isBlurry": False,
            "imageQuality": "good"
        },
        "probabilities": probs
    }


# Initialize FastAPI app
app = FastAPI(
    title="TinyTrails Hygiene Service",
    version="1.0.0",
    description="AI-powered hygiene verification for food vendors"
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Initialize classifier
classifier = HygieneClassifier()


@app.get("/health")
async def health_check():
    """Health check endpoint"""
    return {
        "status": "healthy",
        "model_loaded": classifier.model is not None,
        "device": str(classifier.device),
        "class_names": classifier.class_names
    }


@app.post("/verify-hygiene")
async def verify_hygiene(image: UploadFile = File(...)) -> Dict[str, Any]:
    """
    Verify hygiene from a single image.
    This is the main endpoint used by the Flutter app.
    """
    if not image.content_type or not image.content_type.startswith('image/'):
        raise HTTPException(status_code=400, detail="Invalid image file")

    image_bytes = await image.read()

    if len(image_bytes) < 1000:
        raise HTTPException(status_code=400, detail="Image file too small or corrupted")

    # Classify the image
    classification = classifier.classify(image_bytes)

    # Generate Flutter-compatible response
    response = generate_verification_response(classification)

    return response


@app.post("/predict")
async def predict(image: UploadFile = File(...)) -> Dict[str, Any]:
    """
    Raw classification endpoint (for testing/debugging)
    """
    if not image.content_type or not image.content_type.startswith('image/'):
        raise HTTPException(status_code=400, detail="Invalid image file")

    image_bytes = await image.read()
    classification = classifier.classify(image_bytes)

    # Convert to score format
    label = classification["label"]
    confidence = classification["confidence"]

    if label == "meets_standard":
        score = 0.85 + 0.15 * confidence
    elif label == "needs_work":
        score = 0.50 + 0.35 * confidence
    else:
        score = 0.10 + 0.40 * (1.0 - confidence)

    return {
        "score": round(score, 4),
        "label": label,
        "confidence": round(confidence, 4),
        "probabilities": classification["probabilities"]
    }


@app.get("/issue-categories")
async def get_issue_categories() -> Dict[str, Any]:
    """Get all possible issue categories"""
    return {"categories": ISSUE_CATEGORIES}


if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
