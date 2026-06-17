"""Workspace-focused hygiene inference helpers for TinyTrail.

This module is designed for Indian home kitchens, street-food carts, and
small hotel prep areas where the immediate prep zone matters far more than
the wall color or room finish.
"""

from __future__ import annotations

import math
from dataclasses import dataclass
from pathlib import Path
from typing import Iterable

import numpy as np
import torch
import torch.nn as nn
import torchvision.models as models
from PIL import Image, ImageFilter
from torchvision import transforms


CLASS_SAFE = "meets_standard"
CLASS_REVIEW = "needs_work"
CLASS_UNSAFE = "shouldnt_work"

ZONE_LABELS = {
    "left_counter": "left-side counter",
    "center_prep_zone": "center prep zone",
    "right_counter": "right-side counter",
    "stove_band": "stove and utensil area",
    "overall_workspace": "overall workspace",
}

BADGE_MAP = {
    CLASS_SAFE: "Safe",
    CLASS_REVIEW: "Needs Attention",
    CLASS_UNSAFE: "Unsafe",
}


@dataclass
class LoadedWorkspaceModel:
    model: nn.Module
    class_names: list[str]
    image_size: int
    arch: str
    device: torch.device


def load_workspace_model(
    checkpoint_path: str | Path,
    device: torch.device | None = None,
) -> LoadedWorkspaceModel:
    checkpoint_path = Path(checkpoint_path)
    if not checkpoint_path.exists():
        raise FileNotFoundError(f"Model checkpoint not found: {checkpoint_path}")

    device = device or torch.device("cuda" if torch.cuda.is_available() else "cpu")
    checkpoint = torch.load(checkpoint_path, map_location=device, weights_only=False)

    if not isinstance(checkpoint, dict) or "model_state_dict" not in checkpoint:
        raise ValueError("Unsupported checkpoint format. Expected model_state_dict.")

    arch = str(checkpoint.get("arch", "efficientnet_b0"))
    idx_to_class = checkpoint.get("idx_to_class", {})
    image_size = int(checkpoint.get("image_size", 224))
    num_classes = max(1, len(idx_to_class))

    if arch == "efficientnet_b1":
        model = models.efficientnet_b1(weights=None)
        in_features = model.classifier[1].in_features
        model.classifier[1] = nn.Linear(in_features, num_classes)
    elif arch == "efficientnet_b0":
        model = models.efficientnet_b0(weights=None)
        in_features = model.classifier[1].in_features
        model.classifier[1] = nn.Linear(in_features, num_classes)
    else:
        model = models.resnet18(weights=None)
        in_features = model.fc.in_features
        model.fc = nn.Linear(in_features, num_classes)

    model.load_state_dict(checkpoint["model_state_dict"])
    model.to(device)
    model.eval()

    class_names = [idx_to_class[i] for i in sorted(idx_to_class.keys())] if idx_to_class else []
    if not class_names:
        raise ValueError("Checkpoint is missing class labels.")

    return LoadedWorkspaceModel(
        model=model,
        class_names=class_names,
        image_size=image_size,
        arch=arch,
        device=device,
    )


def build_eval_transform(image_size: int) -> transforms.Compose:
    return transforms.Compose(
        [
            transforms.Resize(256),
            transforms.CenterCrop(image_size),
            transforms.ToTensor(),
            transforms.Normalize(mean=[0.485, 0.456, 0.406], std=[0.229, 0.224, 0.225]),
        ]
    )


def open_workspace_image(image_input: str | Path | Image.Image) -> Image.Image:
    if isinstance(image_input, Image.Image):
        return image_input.convert("RGB")
    return Image.open(image_input).convert("RGB")


def _crop_relative(
    image: Image.Image,
    left: float,
    top: float,
    right: float,
    bottom: float,
) -> Image.Image:
    width, height = image.size
    box = (
        max(0, int(width * left)),
        max(0, int(height * top)),
        min(width, int(width * right)),
        min(height, int(height * bottom)),
    )
    return image.crop(box)


def workspace_context_views(image: Image.Image) -> list[tuple[str, Image.Image]]:
    """Return global crops that emphasise the prep area over the wall/background."""
    return [
        ("full_frame", image),
        ("prep_focus", _crop_relative(image, 0.06, 0.18, 0.94, 0.98)),
        ("stove_band", _crop_relative(image, 0.12, 0.32, 0.88, 0.98)),
        ("center_counter", _crop_relative(image, 0.18, 0.20, 0.82, 0.88)),
    ]


def workspace_zone_views(image: Image.Image) -> list[tuple[str, Image.Image]]:
    """Return localized crops so we can point out the dirtiest visible zone."""
    return [
        ("left_counter", _crop_relative(image, 0.00, 0.28, 0.55, 0.96)),
        ("center_prep_zone", _crop_relative(image, 0.18, 0.24, 0.82, 0.96)),
        ("right_counter", _crop_relative(image, 0.45, 0.28, 1.00, 0.96)),
        ("stove_band", _crop_relative(image, 0.14, 0.42, 0.86, 1.00)),
    ]


def _forward_with_embedding(
    loaded: LoadedWorkspaceModel,
    batch: torch.Tensor,
) -> tuple[torch.Tensor, torch.Tensor]:
    model = loaded.model

    if loaded.arch.startswith("efficientnet"):
        features = model.features(batch)
        pooled = model.avgpool(features)
        embedding = torch.flatten(pooled, 1)
        logits = model.classifier(embedding)
        return logits, embedding

    x = model.conv1(batch)
    x = model.bn1(x)
    x = model.relu(x)
    x = model.maxpool(x)
    x = model.layer1(x)
    x = model.layer2(x)
    x = model.layer3(x)
    x = model.layer4(x)
    x = model.avgpool(x)
    embedding = torch.flatten(x, 1)
    logits = model.fc(embedding)
    return logits, embedding


def _normalize_embedding(embedding: torch.Tensor) -> list[float]:
    norm = torch.linalg.norm(embedding)
    if float(norm.item()) == 0.0:
        return embedding.detach().cpu().tolist()
    return (embedding / norm).detach().cpu().tolist()


def _quality_checks(image: Image.Image) -> dict:
    gray = np.asarray(image.convert("L"), dtype=np.float32)
    brightness = float(gray.mean() / 255.0)
    edges = np.asarray(image.convert("L").filter(ImageFilter.FIND_EDGES), dtype=np.float32)
    sharpness = float(edges.var())

    low_light = brightness < 0.18
    blurry = sharpness < 65.0

    return {
        "brightness": round(brightness, 4),
        "sharpness": round(sharpness, 2),
        "lowLight": low_light,
        "blurry": blurry,
    }


def _class_probabilities(class_names: list[str], probs: torch.Tensor) -> dict[str, float]:
    return {
        class_names[index]: float(probs[index].item())
        for index in range(len(class_names))
    }


def _workspace_score(prob_map: dict[str, float]) -> float:
    return max(
        0.0,
        min(
            1.0,
            prob_map.get(CLASS_SAFE, 0.0)
            + (0.65 * prob_map.get(CLASS_REVIEW, 0.0))
            + (0.20 * prob_map.get(CLASS_UNSAFE, 0.0)),
        ),
    )


def _zone_risk(prob_map: dict[str, float]) -> float:
    return prob_map.get(CLASS_UNSAFE, 0.0) + (0.45 * prob_map.get(CLASS_REVIEW, 0.0))


def _best_attention_zone(image: Image.Image, loaded: LoadedWorkspaceModel) -> str:
    transform = build_eval_transform(loaded.image_size)
    best_zone = "overall_workspace"
    best_risk = -1.0

    for zone_name, crop in workspace_zone_views(image):
        batch = transform(crop).unsqueeze(0).to(loaded.device)
        with torch.no_grad():
            logits, _ = _forward_with_embedding(loaded, batch)
            probs = torch.softmax(logits, dim=1)[0]
        risk = _zone_risk(_class_probabilities(loaded.class_names, probs))
        if risk > best_risk:
            best_risk = risk
            best_zone = zone_name

    return best_zone if best_risk >= 0.28 else "overall_workspace"


def _issues_and_advice(
    label: str,
    score: float,
    confidence: float,
    attention_zone: str,
    quality: dict,
) -> tuple[list[str], str]:
    issues: list[str] = []

    if quality["lowLight"]:
        issues.append("low_light")
    if quality["blurry"]:
        issues.append("blurry")

    if label == CLASS_UNSAFE or score < 0.60:
        issues.append("workspace_unclean")
    elif label == CLASS_REVIEW or score < 0.78:
        issues.append("workspace_needs_attention")

    zone_label = ZONE_LABELS.get(attention_zone, "workspace")
    if quality["lowLight"]:
        advice = "Retake the photo in better lighting so the stove and utensils are clearly visible."
    elif quality["blurry"]:
        advice = "Hold the camera steady and retake the photo so the prep zone is sharp."
    elif label == CLASS_UNSAFE or score < 0.60:
        advice = f"Clean the {zone_label} and retake the photo before going live."
    elif label == CLASS_REVIEW or score < 0.78:
        advice = f"Clean the {zone_label}, wipe visible spills, and keep the utensils clearer."
    elif confidence < 0.55:
        advice = "Move closer to the cooking area so the prep zone fills the frame."
    else:
        advice = "Workspace looks clean and usable for service."

    return issues, advice


def analyze_workspace_image(
    image_input: str | Path | Image.Image,
    loaded: LoadedWorkspaceModel,
) -> dict:
    image = open_workspace_image(image_input)
    quality = _quality_checks(image)
    transform = build_eval_transform(loaded.image_size)
    context_views = workspace_context_views(image)
    batch = torch.stack([transform(crop) for _, crop in context_views]).to(loaded.device)

    with torch.no_grad():
        logits, embeddings = _forward_with_embedding(loaded, batch)
        probs = torch.softmax(logits, dim=1)

    mean_probs = probs.mean(dim=0)
    mean_embedding = embeddings.mean(dim=0)
    predicted_index = int(torch.argmax(mean_probs).item())
    label = loaded.class_names[predicted_index]
    confidence = float(mean_probs[predicted_index].item())
    prob_map = _class_probabilities(loaded.class_names, mean_probs)
    score = _workspace_score(prob_map)
    attention_zone = _best_attention_zone(image, loaded)
    issues, advice = _issues_and_advice(label, score, confidence, attention_zone, quality)

    return {
        "score": round(score, 4),
        "label": label,
        "confidence": round(confidence, 4),
        "embedding": _normalize_embedding(mean_embedding),
        "badgeText": BADGE_MAP.get(label, "Review"),
        "attentionZone": attention_zone,
        "attentionZoneLabel": ZONE_LABELS.get(attention_zone, "overall workspace"),
        "qualityChecks": quality,
        "issues": issues,
        "advice": advice,
        "classProbabilities": {key: round(value, 4) for key, value in prob_map.items()},
    }


def cosine_similarity(left: Iterable[float], right: Iterable[float]) -> float:
    left_vec = np.asarray(list(left), dtype=np.float32)
    right_vec = np.asarray(list(right), dtype=np.float32)
    if left_vec.size == 0 or right_vec.size == 0 or left_vec.shape != right_vec.shape:
        return 0.0

    denominator = float(np.linalg.norm(left_vec) * np.linalg.norm(right_vec))
    if denominator == 0.0:
        return 0.0

    return float(np.dot(left_vec, right_vec) / denominator)


def average_embeddings(embeddings: list[list[float]]) -> list[float] | None:
    if not embeddings:
        return None
    stacked = np.asarray(embeddings, dtype=np.float32)
    mean_embedding = stacked.mean(axis=0)
    denominator = np.linalg.norm(mean_embedding)
    if float(denominator) == 0.0:
        return mean_embedding.tolist()
    return (mean_embedding / denominator).tolist()


def verify_registration_images(
    image_inputs: list[str | Path | Image.Image],
    loaded: LoadedWorkspaceModel,
    min_score: float = 0.75,
) -> dict:
    analyses = [analyze_workspace_image(image_input, loaded) for image_input in image_inputs]
    sorted_results = sorted(analyses, key=lambda item: item["score"], reverse=True)
    all_scores = [float(item["score"]) for item in analyses]

    clean_candidates = [
        item
        for item in sorted_results
        if item["score"] >= min_score
        and not item["qualityChecks"]["lowLight"]
        and not item["qualityChecks"]["blurry"]
    ]

    minimum_clean_images = max(3, math.ceil(len(analyses) * 0.6))
    average_score = sum(item["score"] for item in analyses) / max(len(analyses), 1)
    median_score = float(np.median(all_scores)) if all_scores else 0.0
    unsafe_count = sum(1 for item in analyses if item["label"] == CLASS_UNSAFE)
    reference_source = clean_candidates[:5] if clean_candidates else sorted_results[:3]
    reference_embedding = average_embeddings([item["embedding"] for item in reference_source])
    reference_average_score = (
        sum(float(item["score"]) for item in reference_source) / max(len(reference_source), 1)
    )

    approved = bool(
        len(clean_candidates) >= minimum_clean_images
        and reference_average_score >= min_score
        and median_score >= (min_score * 0.9)
        and unsafe_count <= max(1, len(analyses) // 4)
        and reference_embedding is not None
    )

    dominant_attention_zone = "overall_workspace"
    if analyses:
        zone_counts: dict[str, int] = {}
        for item in analyses:
            zone = item["attentionZone"]
            zone_counts[zone] = zone_counts.get(zone, 0) + 1
        dominant_attention_zone = max(zone_counts.items(), key=lambda pair: pair[1])[0]

    reasons = []
    if len(clean_candidates) < minimum_clean_images:
        reasons.append("Not enough clean baseline images were captured.")
    if reference_average_score < min_score:
        reasons.append("The best baseline images are still below the clean-workspace threshold.")
    if median_score < (min_score * 0.9):
        reasons.append("Too many uploaded views still need cleanup before approval.")
    if unsafe_count > max(1, len(analyses) // 4):
        reasons.append("Too many uploaded images show an unsafe prep area.")
    if reference_embedding is None:
        reasons.append("Could not build a stable reference embedding from the uploaded images.")

    if not reasons:
        reasons.append("Baseline workspace accepted.")

    return {
        "approved": approved,
        "averageScore": round(average_score, 4),
        "medianScore": round(median_score, 4),
        "referenceAverageScore": round(reference_average_score, 4),
        "bestScore": round(sorted_results[0]["score"], 4) if sorted_results else 0.0,
        "minimumCleanImages": minimum_clean_images,
        "cleanImagesAccepted": len(clean_candidates),
        "dominantAttentionZone": dominant_attention_zone,
        "referenceEmbedding": reference_embedding,
        "results": analyses,
        "reasons": reasons,
    }


def verify_shift_image(
    image_input: str | Path | Image.Image,
    reference_embedding: list[float],
    loaded: LoadedWorkspaceModel,
    score_threshold: float = 0.70,
    similarity_threshold: float = 0.60,
) -> dict:
    result = analyze_workspace_image(image_input, loaded)
    similarity = cosine_similarity(result["embedding"], reference_embedding)

    quality = result["qualityChecks"]
    score_ok = result["score"] >= score_threshold
    similarity_ok = similarity >= similarity_threshold
    quality_ok = not quality["lowLight"] and not quality["blurry"]
    allowed = bool(score_ok and similarity_ok and quality_ok)

    if quality["lowLight"]:
        reason = "Retake the photo in better lighting."
    elif quality["blurry"]:
        reason = "Retake the photo with a steadier camera."
    elif not score_ok:
        reason = result["advice"]
    elif not similarity_ok:
        reason = (
            "Workspace differs from the approved cooking setup. "
            f"Please clean and frame the {result['attentionZoneLabel']} more clearly."
        )
    else:
        reason = "Workspace verified."

    return {
        **result,
        "similarity": round(similarity, 4),
        "allowed": allowed,
        "scoreThreshold": score_threshold,
        "similarityThreshold": similarity_threshold,
        "reason": reason,
    }
