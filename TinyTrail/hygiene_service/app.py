from fastapi import FastAPI, File, UploadFile, HTTPException
from pydantic import BaseModel
from typing import List
import uvicorn
import numpy as np

app = FastAPI(title="Hygiene Service (Mock)")


class PredictResp(BaseModel):
    score: float
    label: str
    confidence: float
    embedding: List[float] = []


@app.post('/predict', response_model=PredictResp)
async def predict(file: UploadFile = File(...)):
    # TODO: Replace with real model loading and inference
    contents = await file.read()
    if len(contents) < 1000:
        # too small → likely invalid
        raise HTTPException(status_code=400, detail="Image too small or invalid")
    # Mock logic: compute pseudo-random score based on file size
    score = min(0.99, max(0.01, (len(contents) % 1000) / 1000.0))
    label = 'clean' if score > 0.7 else ('moderate' if score > 0.4 else 'unsafe')
    embedding = list(np.random.RandomState(42).rand(128))
    return PredictResp(score=score, label=label, confidence=0.9, embedding=embedding)


if __name__ == '__main__':
    uvicorn.run(app, host='0.0.0.0', port=9000)
import io
import os
from pathlib import Path
from typing import Any, Dict, List, Optional, Tuple

import numpy as np
import torch
import torch.nn as nn
from fastapi import FastAPI, File, HTTPException, UploadFile
from fastapi.middleware.cors import CORSMiddleware
from PIL import Image
from torchvision import transforms
import importlib.util
import sys


REPO_ROOT = Path(__file__).resolve().parents[1]
DEFAULT_MODEL_PATH = REPO_ROOT / "Hygine" / "models" / "hygiene_model.pth"

MODEL_PATH = Path(os.environ.get("HYGIENE_MODEL_PATH", str(DEFAULT_MODEL_PATH)))

DEVICE = torch.device("cuda" if torch.cuda.is_available() else "cpu")


def _load_checkpoint_meta(checkpoint_path: Path, device: torch.device) -> Dict[str, Any]:
    checkpoint = torch.load(checkpoint_path, map_location=device)
    if not isinstance(checkpoint, dict) or "model_state_dict" not in checkpoint:
        raise ValueError("Unsupported checkpoint format. Expected dict with model_state_dict.")
    return checkpoint


def _build_model_from_checkpoint(checkpoint: Dict[str, Any]) -> Tuple[nn.Module, List[str], int, str]:
    # Reuse Hygine/predict.py loader logic (folder is not necessarily a package).
    predict_py = REPO_ROOT / "Hygine" / "predict.py"
    if not predict_py.exists():
        raise RuntimeError(f"Missing predict.py at {predict_py}")

    spec = importlib.util.spec_from_file_location("tinytrails_hygine_predict", str(predict_py))
    if spec is None or spec.loader is None:
        raise RuntimeError("Could not load Hygine/predict.py module")
    # Ensure Hygine folder is importable for its sibling modules (utils.py, etc.)
    hygine_dir = str((REPO_ROOT / "Hygine").resolve())
    if hygine_dir not in sys.path:
        sys.path.insert(0, hygine_dir)

    module = importlib.util.module_from_spec(spec)
    sys.modules["tinytrails_hygine_predict"] = module
    spec.loader.exec_module(module)  # type: ignore[attr-defined]

    load_model = getattr(module, "load_model")

    arch = str(checkpoint.get("arch", "resnet18"))
    idx_to_class = checkpoint.get("idx_to_class", None)
    class_names: List[str]
    if idx_to_class:
        class_names = [idx_to_class[i] for i in sorted(idx_to_class.keys())]
    else:
        # Fallback only; production expects 3 classes
        num_classes = int(checkpoint.get("num_classes", 3))
        class_names = [f"class_{i}" for i in range(num_classes)]

    image_size = int(checkpoint.get("image_size", 224))

    model, _, _ = load_model(MODEL_PATH, DEVICE)
    return model, class_names, image_size, arch


def _extract_features(model: nn.Module, arch: str, image_tensor: torch.Tensor) -> Tuple[torch.Tensor, torch.Tensor]:
    """
    Return (logits, embedding).
    Embedding is a pooled feature vector before the final classifier head.
    """
    model.eval()
    with torch.no_grad():
        if arch.startswith("efficientnet"):
            # EfficientNet: features -> avgpool -> flatten -> classifier
            features = model.features(image_tensor)
            pooled = model.avgpool(features)
            embedding = torch.flatten(pooled, 1)
            logits = model.classifier(embedding)
            return logits, embedding

        # ResNet fallback
        # resnet: conv1..layer4 -> avgpool -> flatten -> fc
        x = model.conv1(image_tensor)
        x = model.bn1(x)
        x = model.relu(x)
        x = model.maxpool(x)
        x = model.layer1(x)
        x = model.layer2(x)
        x = model.layer3(x)
        x = model.layer4(x)
        pooled = model.avgpool(x)
        embedding = torch.flatten(pooled, 1)
        logits = model.fc(embedding)
        return logits, embedding


def cosine_similarity(a: np.ndarray, b: np.ndarray) -> float:
    denom = float(np.linalg.norm(a) * np.linalg.norm(b))
    if denom == 0:
        return 0.0
    return float(np.dot(a, b) / denom)


app = FastAPI(title="TinyTrails Hygiene Service", version="1.0.0")
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


class _ModelState:
    def __init__(self) -> None:
        if not MODEL_PATH.exists():
            raise RuntimeError(f"Model not found at {MODEL_PATH}")
        self.checkpoint = _load_checkpoint_meta(MODEL_PATH, DEVICE)
        self.model, self.class_names, self.image_size, self.arch = _build_model_from_checkpoint(self.checkpoint)
        self.model.to(DEVICE)
        self.model.eval()
        self.preprocess = transforms.Compose(
            [
                transforms.Resize(256),
                transforms.CenterCrop(self.image_size),
                transforms.ToTensor(),
                transforms.Normalize(mean=[0.485, 0.456, 0.406], std=[0.229, 0.224, 0.225]),
            ]
        )


MODEL_STATE: Optional[_ModelState] = None


def get_model_state() -> _ModelState:
    global MODEL_STATE
    if MODEL_STATE is None:
        MODEL_STATE = _ModelState()
    return MODEL_STATE


def load_image(file_bytes: bytes) -> Image.Image:
    try:
        return Image.open(io.BytesIO(file_bytes)).convert("RGB")
    except Exception as exc:
        raise HTTPException(status_code=400, detail=f"Invalid image: {exc}") from exc


@app.post("/predict")
async def predict(image: UploadFile = File(...)) -> Dict[str, Any]:
    if not image:
        raise HTTPException(status_code=400, detail="image file required")

    state = get_model_state()
    content = await image.read()
    pil = load_image(content)
    tensor = state.preprocess(pil).unsqueeze(0).to(DEVICE)

    try:
        logits, embedding = _extract_features(state.model, state.arch, tensor)
        probs = torch.softmax(logits, dim=1)[0].detach().cpu().numpy()
        pred_idx = int(np.argmax(probs))
        confidence = float(probs[pred_idx])
        label = state.class_names[pred_idx] if 0 <= pred_idx < len(state.class_names) else "unknown"

        # Convert to cleanliness score 0..1 (business-friendly)
        # We map the "best" class to higher score and the unsafe class to lower score.
        # Expected labels: meets_standard, needs_work, shouldnt_work
        if label == "meets_standard":
            score = float(0.85 + 0.15 * confidence)
        elif label == "needs_work":
            score = float(0.70 + 0.15 * confidence)
        else:
            score = float(0.10 + 0.55 * (1.0 - confidence))

        emb = embedding[0].detach().cpu().numpy().astype(np.float32)
        emb = emb / (np.linalg.norm(emb) + 1e-8)

        return {
            "score": round(score, 4),
            "label": label,
            "confidence": round(confidence, 4),
            "embedding": emb.tolist(),
        }
    except Exception as exc:
        raise HTTPException(status_code=500, detail=f"Prediction failed: {exc}") from exc


@app.post("/compare")
async def compare(
    new_image: UploadFile = File(...),
    reference_embedding: UploadFile = File(...),
) -> Dict[str, Any]:
    if not new_image or not reference_embedding:
        raise HTTPException(status_code=400, detail="new_image and reference_embedding required")

    state = get_model_state()

    new_bytes = await new_image.read()
    pil = load_image(new_bytes)
    tensor = state.preprocess(pil).unsqueeze(0).to(DEVICE)

    try:
        _, embedding = _extract_features(state.model, state.arch, tensor)
        new_emb = embedding[0].detach().cpu().numpy().astype(np.float32)
        new_emb = new_emb / (np.linalg.norm(new_emb) + 1e-8)

        ref_bytes = await reference_embedding.read()
        ref_arr = np.frombuffer(ref_bytes, dtype=np.float32)
        if ref_arr.ndim != 1:
            raise ValueError("reference_embedding must be a 1D float32 array")

        ref_arr = ref_arr / (np.linalg.norm(ref_arr) + 1e-8)
        sim = cosine_similarity(new_emb, ref_arr)

        return {
            "similarity": round(sim, 4),
            "isSimilar": bool(sim >= float(os.environ.get("HYGIENE_SIMILARITY_THRESHOLD", "0.6"))),
        }
    except Exception as exc:
        raise HTTPException(status_code=500, detail=f"Comparison failed: {exc}") from exc

