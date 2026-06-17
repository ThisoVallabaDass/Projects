"""
Indian Kitchen Hygiene Inference System.

This module provides detailed hygiene analysis with specific issue detection:
- Dirty vessels/utensils
- Unclean stove (grease, burnt residue)
- Leftover food particles
- Cluttered workspace
- Oil/grease stains
- Poor lighting conditions
"""

from __future__ import annotations

import math
import random
from dataclasses import dataclass
from pathlib import Path
from typing import Iterable, Optional

import numpy as np
import torch
import torch.nn as nn
import torchvision.models as models
from PIL import Image, ImageFilter, ImageStat
from torchvision import transforms


# Class labels
CLASS_SAFE = "meets_standard"
CLASS_REVIEW = "needs_work"
CLASS_UNSAFE = "shouldnt_work"

# Zone labels for Indian kitchens
ZONE_LABELS = {
    "stove_area": "gas stove and burner area",
    "vessel_rack": "vessel/utensil storage area",
    "prep_counter": "food preparation counter",
    "sink_area": "sink and washing area",
    "left_counter": "left side counter",
    "right_counter": "right side counter",
    "center_zone": "main cooking area",
    "overall": "overall workspace",
}

# Issue categories with descriptions
ISSUE_CATEGORIES = {
    "dirty_vessels": {
        "message": "Dirty or unwashed vessels/utensils visible",
        "advice": "Please wash and dry all vessels before going live",
        "severity": "high",
    },
    "unclean_stove": {
        "message": "Stove area has grease or burnt residue",
        "advice": "Clean the gas stove and remove any burnt food residue",
        "severity": "high",
    },
    "leftover_food": {
        "message": "Leftover food particles or waste visible",
        "advice": "Remove all leftover food and clean the surfaces",
        "severity": "high",
    },
    "cluttered_workspace": {
        "message": "Workspace is cluttered and disorganized",
        "advice": "Organize your workspace and remove unnecessary items",
        "severity": "medium",
    },
    "grease_stains": {
        "message": "Oil/grease stains visible on surfaces",
        "advice": "Wipe down all surfaces with a degreaser",
        "severity": "medium",
    },
    "water_stains": {
        "message": "Water stains or wet surfaces detected",
        "advice": "Dry all wet surfaces before taking the photo",
        "severity": "low",
    },
    "poor_lighting": {
        "message": "Photo taken in poor lighting conditions",
        "advice": "Retake the photo with better lighting",
        "severity": "low",
    },
    "blurry_image": {
        "message": "Photo is blurry or out of focus",
        "advice": "Hold the camera steady and retake the photo",
        "severity": "low",
    },
    "general_uncleanliness": {
        "message": "General hygiene standards not met",
        "advice": "Clean the entire workspace thoroughly before going live",
        "severity": "high",
    },
}

# Badge mapping
BADGE_MAP = {
    CLASS_SAFE: {"text": "Clean & Safe", "color": "green"},
    CLASS_REVIEW: {"text": "Needs Attention", "color": "orange"},
    CLASS_UNSAFE: {"text": "Not Approved", "color": "red"},
}


@dataclass
class LoadedWorkspaceModel:
    """Container for loaded model and metadata."""
    model: nn.Module
    class_names: list[str]
    image_size: int
    arch: str
    device: torch.device


def load_workspace_model(
    checkpoint_path: str | Path,
    device: torch.device | None = None,
) -> LoadedWorkspaceModel:
    """Load the trained hygiene model."""
    checkpoint_path = Path(checkpoint_path)
    if not checkpoint_path.exists():
        raise FileNotFoundError(f"Model checkpoint not found: {checkpoint_path}")

    device = device or torch.device("cuda" if torch.cuda.is_available() else "cpu")
    checkpoint = torch.load(checkpoint_path, map_location=device, weights_only=False)

    if not isinstance(checkpoint, dict) or "model_state_dict" not in checkpoint:
        raise ValueError("Invalid checkpoint format")

    arch = str(checkpoint.get("arch", "efficientnet_b0"))
    idx_to_class = checkpoint.get("idx_to_class", {})
    image_size = int(checkpoint.get("image_size", 224))
    num_classes = max(1, len(idx_to_class))

    # Build model architecture
    if arch == "efficientnet_b2":
        model = models.efficientnet_b2(weights=None)
        in_features = model.classifier[1].in_features
        model.classifier = nn.Sequential(
            nn.Dropout(p=0.3),
            nn.Linear(in_features, 512),
            nn.ReLU(inplace=True),
            nn.Dropout(p=0.15),
            nn.Linear(512, num_classes)
        )
    elif arch == "efficientnet_b1":
        model = models.efficientnet_b1(weights=None)
        in_features = model.classifier[1].in_features
        model.classifier = nn.Sequential(
            nn.Dropout(p=0.3),
            nn.Linear(in_features, 256),
            nn.ReLU(inplace=True),
            nn.Dropout(p=0.15),
            nn.Linear(256, num_classes)
        )
    elif arch == "efficientnet_b0":
        model = models.efficientnet_b0(weights=None)
        in_features = model.classifier[1].in_features
        # Check if checkpoint has custom classifier
        state_dict = checkpoint["model_state_dict"]
        if any("classifier.1.weight" in k for k in state_dict.keys()):
            # Simple classifier
            model.classifier[1] = nn.Linear(in_features, num_classes)
        else:
            model.classifier = nn.Sequential(
                nn.Dropout(p=0.3),
                nn.Linear(in_features, num_classes)
            )
    else:  # resnet18
        model = models.resnet18(weights=None)
        in_features = model.fc.in_features
        model.fc = nn.Sequential(
            nn.Dropout(p=0.3),
            nn.Linear(in_features, num_classes)
        )

    model.load_state_dict(checkpoint["model_state_dict"])
    model.to(device)
    model.eval()

    class_names = [idx_to_class[i] for i in sorted(idx_to_class.keys())] if idx_to_class else []
    if not class_names:
        raise ValueError("Checkpoint missing class labels")

    return LoadedWorkspaceModel(
        model=model,
        class_names=class_names,
        image_size=image_size,
        arch=arch,
        device=device,
    )


def build_eval_transform(image_size: int) -> transforms.Compose:
    """Build evaluation transform pipeline."""
    return transforms.Compose([
        transforms.Resize(256),
        transforms.CenterCrop(image_size),
        transforms.ToTensor(),
        transforms.Normalize(
            mean=[0.485, 0.456, 0.406],
            std=[0.229, 0.224, 0.225]
        ),
    ])


def open_image(image_input: str | Path | Image.Image) -> Image.Image:
    """Open and convert image to RGB."""
    if isinstance(image_input, Image.Image):
        return image_input.convert("RGB")
    return Image.open(image_input).convert("RGB")


def _crop_relative(
    image: Image.Image,
    left: float, top: float, right: float, bottom: float
) -> Image.Image:
    """Crop image using relative coordinates."""
    w, h = image.size
    return image.crop((
        max(0, int(w * left)),
        max(0, int(h * top)),
        min(w, int(w * right)),
        min(h, int(h * bottom)),
    ))


def get_context_crops(image: Image.Image) -> list[tuple[str, Image.Image]]:
    """Get context-aware crops for Indian kitchen analysis."""
    return [
        ("full", image),
        ("stove_area", _crop_relative(image, 0.2, 0.4, 0.8, 1.0)),
        ("prep_zone", _crop_relative(image, 0.1, 0.2, 0.9, 0.85)),
        ("center", _crop_relative(image, 0.15, 0.15, 0.85, 0.85)),
    ]


def get_zone_crops(image: Image.Image) -> list[tuple[str, Image.Image]]:
    """Get specific zone crops for detailed analysis."""
    return [
        ("stove_area", _crop_relative(image, 0.2, 0.5, 0.8, 1.0)),
        ("vessel_rack", _crop_relative(image, 0.0, 0.0, 0.4, 0.6)),
        ("prep_counter", _crop_relative(image, 0.1, 0.3, 0.9, 0.7)),
        ("left_counter", _crop_relative(image, 0.0, 0.2, 0.4, 0.9)),
        ("right_counter", _crop_relative(image, 0.6, 0.2, 1.0, 0.9)),
        ("sink_area", _crop_relative(image, 0.6, 0.0, 1.0, 0.5)),
    ]


def analyze_image_quality(image: Image.Image) -> dict:
    """Analyze image quality metrics."""
    gray = np.asarray(image.convert("L"), dtype=np.float32)

    # Brightness
    brightness = float(gray.mean() / 255.0)

    # Sharpness (edge detection variance)
    edges = np.asarray(
        image.convert("L").filter(ImageFilter.FIND_EDGES),
        dtype=np.float32
    )
    sharpness = float(edges.var())

    # Contrast
    contrast = float(gray.std() / 128.0)

    # Color analysis
    stat = ImageStat.Stat(image)
    color_variance = float(np.mean([s ** 2 for s in stat.stddev]))

    # Detect issues
    is_low_light = brightness < 0.20
    is_blurry = sharpness < 50.0
    is_low_contrast = contrast < 0.15
    is_overexposed = brightness > 0.85

    return {
        "brightness": round(brightness, 4),
        "sharpness": round(sharpness, 2),
        "contrast": round(contrast, 4),
        "colorVariance": round(color_variance, 2),
        "isLowLight": is_low_light,
        "isBlurry": is_blurry,
        "isLowContrast": is_low_contrast,
        "isOverexposed": is_overexposed,
    }


def _forward_with_embedding(
    loaded: LoadedWorkspaceModel,
    batch: torch.Tensor,
) -> tuple[torch.Tensor, torch.Tensor]:
    """Forward pass returning both logits and embeddings."""
    model = loaded.model

    if loaded.arch.startswith("efficientnet"):
        features = model.features(batch)
        pooled = model.avgpool(features)
        embedding = torch.flatten(pooled, 1)
        logits = model.classifier(embedding)
        return logits, embedding

    # ResNet
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
    """Normalize embedding vector."""
    norm = torch.linalg.norm(embedding)
    if float(norm.item()) == 0.0:
        return embedding.detach().cpu().tolist()
    return (embedding / norm).detach().cpu().tolist()


def compute_hygiene_score(prob_map: dict[str, float]) -> float:
    """Compute weighted hygiene score."""
    safe_prob = prob_map.get(CLASS_SAFE, 0.0)
    review_prob = prob_map.get(CLASS_REVIEW, 0.0)
    unsafe_prob = prob_map.get(CLASS_UNSAFE, 0.0)

    # Weighted score formula
    score = safe_prob * 1.0 + review_prob * 0.6 + unsafe_prob * 0.15

    return max(0.0, min(1.0, score))


def compute_zone_risk(prob_map: dict[str, float]) -> float:
    """Compute risk score for a zone."""
    return (
        prob_map.get(CLASS_UNSAFE, 0.0) +
        0.5 * prob_map.get(CLASS_REVIEW, 0.0)
    )


def detect_issues(
    label: str,
    score: float,
    confidence: float,
    attention_zone: str,
    quality: dict,
    prob_map: dict[str, float],
) -> list[dict]:
    """Detect specific issues based on model prediction and image analysis."""
    issues = []

    # Quality issues
    if quality["isLowLight"]:
        issues.append({
            "code": "poor_lighting",
            **ISSUE_CATEGORIES["poor_lighting"]
        })

    if quality["isBlurry"]:
        issues.append({
            "code": "blurry_image",
            **ISSUE_CATEGORIES["blurry_image"]
        })

    # Cleanliness issues based on classification
    if label == CLASS_UNSAFE:
        # Determine specific issue based on attention zone and probabilities
        unsafe_prob = prob_map.get(CLASS_UNSAFE, 0.0)

        if attention_zone in ["stove_area"]:
            issues.append({
                "code": "unclean_stove",
                **ISSUE_CATEGORIES["unclean_stove"]
            })
        elif attention_zone in ["vessel_rack", "sink_area"]:
            issues.append({
                "code": "dirty_vessels",
                **ISSUE_CATEGORIES["dirty_vessels"]
            })
        elif attention_zone in ["prep_counter", "left_counter", "right_counter"]:
            issues.append({
                "code": "leftover_food",
                **ISSUE_CATEGORIES["leftover_food"]
            })
        else:
            issues.append({
                "code": "general_uncleanliness",
                **ISSUE_CATEGORIES["general_uncleanliness"]
            })

        # Add secondary issues for high unsafe probability
        if unsafe_prob > 0.7 and len(issues) < 3:
            if "dirty_vessels" not in [i["code"] for i in issues]:
                issues.append({
                    "code": "dirty_vessels",
                    **ISSUE_CATEGORIES["dirty_vessels"]
                })

    elif label == CLASS_REVIEW:
        # Minor issues
        review_prob = prob_map.get(CLASS_REVIEW, 0.0)

        if attention_zone in ["stove_area"]:
            issues.append({
                "code": "grease_stains",
                **ISSUE_CATEGORIES["grease_stains"]
            })
        elif attention_zone in ["vessel_rack", "sink_area"]:
            issues.append({
                "code": "water_stains",
                **ISSUE_CATEGORIES["water_stains"]
            })
        else:
            issues.append({
                "code": "cluttered_workspace",
                **ISSUE_CATEGORIES["cluttered_workspace"]
            })

    return issues


def find_worst_zone(
    image: Image.Image,
    loaded: LoadedWorkspaceModel,
) -> tuple[str, float]:
    """Find the zone with highest risk."""
    transform = build_eval_transform(loaded.image_size)
    worst_zone = "overall"
    worst_risk = 0.0

    for zone_name, crop in get_zone_crops(image):
        batch = transform(crop).unsqueeze(0).to(loaded.device)

        with torch.no_grad():
            logits, _ = _forward_with_embedding(loaded, batch)
            probs = torch.softmax(logits, dim=1)[0]

        prob_map = {
            loaded.class_names[i]: float(probs[i].item())
            for i in range(len(loaded.class_names))
        }
        risk = compute_zone_risk(prob_map)

        if risk > worst_risk:
            worst_risk = risk
            worst_zone = zone_name

    return worst_zone, worst_risk


def generate_advice(
    label: str,
    score: float,
    issues: list[dict],
    attention_zone: str,
) -> str:
    """Generate actionable advice based on issues detected."""
    if not issues:
        return "Your workspace looks clean and ready for service!"

    # Get highest severity issue
    severity_order = {"high": 0, "medium": 1, "low": 2}
    sorted_issues = sorted(issues, key=lambda x: severity_order.get(x.get("severity", "low"), 2))

    primary_issue = sorted_issues[0]
    zone_label = ZONE_LABELS.get(attention_zone, "workspace")

    if primary_issue["severity"] == "high":
        return f"Please clean the {zone_label}. {primary_issue['advice']}"
    elif primary_issue["severity"] == "medium":
        return f"Minor issues detected in {zone_label}. {primary_issue['advice']}"
    else:
        return primary_issue["advice"]


def analyze_workspace_image(
    image_input: str | Path | Image.Image,
    loaded: LoadedWorkspaceModel,
) -> dict:
    """
    Analyze a workspace image for hygiene compliance.

    Returns detailed analysis including:
    - Hygiene score (0-1)
    - Classification label
    - Detected issues with specific reasons
    - Attention zone
    - Actionable advice
    """
    image = open_image(image_input)
    quality = analyze_image_quality(image)

    # Get context crops
    transform = build_eval_transform(loaded.image_size)
    context_crops = get_context_crops(image)
    batch = torch.stack([
        transform(crop) for _, crop in context_crops
    ]).to(loaded.device)

    # Forward pass
    with torch.no_grad():
        logits, embeddings = _forward_with_embedding(loaded, batch)
        probs = torch.softmax(logits, dim=1)

    # Average probabilities across crops
    mean_probs = probs.mean(dim=0)
    mean_embedding = embeddings.mean(dim=0)

    # Get prediction
    predicted_idx = int(torch.argmax(mean_probs).item())
    label = loaded.class_names[predicted_idx]
    confidence = float(mean_probs[predicted_idx].item())

    # Build probability map
    prob_map = {
        loaded.class_names[i]: float(mean_probs[i].item())
        for i in range(len(loaded.class_names))
    }

    # Calculate score
    score = compute_hygiene_score(prob_map)

    # Find attention zone
    attention_zone, zone_risk = find_worst_zone(image, loaded)

    # Detect issues
    issues = detect_issues(
        label, score, confidence, attention_zone, quality, prob_map
    )

    # Generate advice
    advice = generate_advice(label, score, issues, attention_zone)

    # Badge info
    badge = BADGE_MAP.get(label, {"text": "Review", "color": "orange"})

    # Determine if approved
    approved = (
        label == CLASS_SAFE and
        score >= 0.75 and
        not quality["isLowLight"] and
        not quality["isBlurry"]
    )

    return {
        "score": round(score * 100, 1),  # Return as percentage
        "scoreRaw": round(score, 4),
        "label": label,
        "confidence": round(confidence, 4),
        "approved": approved,
        "badgeText": badge["text"],
        "badgeColor": badge["color"],
        "attentionZone": attention_zone,
        "attentionZoneLabel": ZONE_LABELS.get(attention_zone, "overall workspace"),
        "zoneRisk": round(zone_risk, 4),
        "issues": issues,
        "issueCount": len(issues),
        "advice": advice,
        "qualityChecks": quality,
        "classProbabilities": {k: round(v, 4) for k, v in prob_map.items()},
        "embedding": _normalize_embedding(mean_embedding),
    }


def cosine_similarity(left: Iterable[float], right: Iterable[float]) -> float:
    """Compute cosine similarity between two vectors."""
    left_vec = np.asarray(list(left), dtype=np.float32)
    right_vec = np.asarray(list(right), dtype=np.float32)

    if left_vec.size == 0 or right_vec.size == 0:
        return 0.0
    if left_vec.shape != right_vec.shape:
        return 0.0

    denom = float(np.linalg.norm(left_vec) * np.linalg.norm(right_vec))
    if denom == 0.0:
        return 0.0

    return float(np.dot(left_vec, right_vec) / denom)


def average_embeddings(embeddings: list[list[float]]) -> Optional[list[float]]:
    """Average multiple embeddings."""
    if not embeddings:
        return None

    stacked = np.asarray(embeddings, dtype=np.float32)
    mean_emb = stacked.mean(axis=0)
    norm = np.linalg.norm(mean_emb)

    if float(norm) == 0.0:
        return mean_emb.tolist()
    return (mean_emb / norm).tolist()


def verify_registration_images(
    image_inputs: list[str | Path | Image.Image],
    loaded: LoadedWorkspaceModel,
    min_score: float = 0.70,
) -> dict:
    """Verify registration images for baseline training."""
    analyses = [analyze_workspace_image(img, loaded) for img in image_inputs]

    # Sort by score
    sorted_results = sorted(analyses, key=lambda x: x["scoreRaw"], reverse=True)
    all_scores = [r["scoreRaw"] for r in analyses]

    # Find clean images
    clean_images = [
        r for r in sorted_results
        if r["scoreRaw"] >= min_score
        and not r["qualityChecks"]["isLowLight"]
        and not r["qualityChecks"]["isBlurry"]
    ]

    min_required = max(3, int(len(analyses) * 0.6))
    avg_score = sum(all_scores) / max(len(all_scores), 1)
    median_score = float(np.median(all_scores)) if all_scores else 0.0
    unsafe_count = sum(1 for r in analyses if r["label"] == CLASS_UNSAFE)

    # Get reference embedding
    reference_source = clean_images[:5] if clean_images else sorted_results[:3]
    reference_embedding = average_embeddings([r["embedding"] for r in reference_source])
    ref_avg_score = sum(r["scoreRaw"] for r in reference_source) / max(len(reference_source), 1)

    # Determine approval
    approved = (
        len(clean_images) >= min_required and
        ref_avg_score >= min_score and
        median_score >= (min_score * 0.85) and
        unsafe_count <= max(1, len(analyses) // 3) and
        reference_embedding is not None
    )

    # Collect all issues
    all_issues = []
    for r in analyses:
        all_issues.extend(r["issues"])

    # Count issue types
    issue_counts = {}
    for issue in all_issues:
        code = issue["code"]
        issue_counts[code] = issue_counts.get(code, 0) + 1

    # Reasons for rejection
    reasons = []
    if len(clean_images) < min_required:
        reasons.append(f"Only {len(clean_images)} clean images, need at least {min_required}")
    if ref_avg_score < min_score:
        reasons.append("Best images still below hygiene threshold")
    if unsafe_count > max(1, len(analyses) // 3):
        reasons.append("Too many images show unsafe conditions")

    if not reasons:
        reasons.append("Baseline accepted - your workspace meets hygiene standards")

    return {
        "approved": approved,
        "averageScore": round(avg_score * 100, 1),
        "medianScore": round(median_score * 100, 1),
        "bestScore": round(sorted_results[0]["scoreRaw"] * 100, 1) if sorted_results else 0.0,
        "cleanImagesCount": len(clean_images),
        "minRequiredImages": min_required,
        "totalImages": len(analyses),
        "unsafeImagesCount": unsafe_count,
        "issueCounts": issue_counts,
        "referenceEmbedding": reference_embedding,
        "reasons": reasons,
        "results": analyses,
    }


def verify_shift_image(
    image_input: str | Path | Image.Image,
    reference_embedding: list[float],
    loaded: LoadedWorkspaceModel,
    score_threshold: float = 0.65,
    similarity_threshold: float = 0.55,
) -> dict:
    """Verify daily shift image against baseline."""
    result = analyze_workspace_image(image_input, loaded)

    # Compute similarity
    similarity = cosine_similarity(result["embedding"], reference_embedding)

    quality = result["qualityChecks"]
    score_ok = result["scoreRaw"] >= score_threshold
    similarity_ok = similarity >= similarity_threshold
    quality_ok = not quality["isLowLight"] and not quality["isBlurry"]

    allowed = score_ok and similarity_ok and quality_ok

    # Generate reason
    if quality["isLowLight"]:
        reason = "Please retake the photo with better lighting"
    elif quality["isBlurry"]:
        reason = "Photo is blurry - hold camera steady and retake"
    elif not score_ok:
        reason = result["advice"]
    elif not similarity_ok:
        zone_label = result["attentionZoneLabel"]
        reason = f"Workspace looks different from your baseline. Ensure {zone_label} is clearly visible."
    else:
        reason = "Hygiene check passed! You can start your shift."

    return {
        **result,
        "similarity": round(similarity, 4),
        "similarityPercent": round(similarity * 100, 1),
        "allowed": allowed,
        "scoreThreshold": score_threshold,
        "similarityThreshold": similarity_threshold,
        "reason": reason,
    }
