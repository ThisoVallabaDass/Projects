"""Predict hygiene class for a single image using trained model."""

import argparse
import logging
from pathlib import Path

import torch
import torch.nn as nn
import torchvision.models as models
from PIL import Image
from torchvision import transforms

from utils import is_valid_class_dir, setup_logging

logger = logging.getLogger(__name__)


def load_model(checkpoint_path: Path, device: torch.device) -> tuple[nn.Module, list[str], int]:
    if not checkpoint_path.exists():
        raise FileNotFoundError(f"Model checkpoint not found: {checkpoint_path}")

    checkpoint = torch.load(checkpoint_path, map_location=device, weights_only=False)

    if isinstance(checkpoint, dict) and "model_state_dict" in checkpoint:
        arch = checkpoint.get("arch", "resnet18")
        idx_to_class = checkpoint.get("idx_to_class", None)
        image_size = int(checkpoint.get("image_size", 224))

        if arch == "efficientnet_b0":
            model = models.efficientnet_b0(weights=None)
            num_classes = model.classifier[1].out_features
        else:
            model = models.resnet18(weights=None)
            num_classes = model.fc.out_features

        if idx_to_class:
            num_classes = len(idx_to_class)

        if arch == "efficientnet_b0":
            in_features = model.classifier[1].in_features
            model.classifier[1] = nn.Linear(in_features, num_classes)
        else:
            in_features = model.fc.in_features
            model.fc = nn.Linear(in_features, num_classes)

        model.load_state_dict(checkpoint["model_state_dict"])

        if idx_to_class:
            class_names = [idx_to_class[i] for i in sorted(idx_to_class.keys())]
        else:
            class_names = [f"class_{i}" for i in range(num_classes)]

        return model, class_names, image_size

    raise ValueError(
        "Unsupported checkpoint format. Re-train using train.py to save class labels and architecture."
    )


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Predict hygiene class for a single image.")
    parser.add_argument("image_path", type=str, help="Path to input image.")
    parser.add_argument(
        "--model-path",
        type=str,
        default="models/hygiene_model.pth",
        help="Path to trained model checkpoint.",
    )
    return parser.parse_args()


def main() -> None:
    setup_logging()
    args = parse_args()
    device = torch.device("cuda" if torch.cuda.is_available() else "cpu")
    logger.info("Using device: %s", device)

    image_path = Path(args.image_path)
    if not image_path.exists():
        raise FileNotFoundError(f"Image not found: {image_path}")

    model_path = Path(args.model_path)
    model, class_names, image_size = load_model(model_path, device)
    model.to(device)
    model.eval()
    logger.info("Loaded model from: %s", model_path)

    invalid_classes = [name for name in class_names if not is_valid_class_dir(name)]
    if invalid_classes:
        print("Warning: this model was trained with helper folders as classes.")
        print(f"Invalid classes found in checkpoint: {', '.join(invalid_classes)}")
        print("Retrain after updating train.py so predictions use only the 3 hygiene labels.\n")

    preprocess = transforms.Compose(
        [
            transforms.Resize(256),
            transforms.CenterCrop(image_size),
            transforms.ToTensor(),
            transforms.Normalize(mean=[0.485, 0.456, 0.406], std=[0.229, 0.224, 0.225]),
        ]
    )

    image = Image.open(image_path).convert("RGB")
    image_tensor = preprocess(image).unsqueeze(0).to(device)

    with torch.no_grad():
        outputs = model(image_tensor)
        probabilities = torch.softmax(outputs, dim=1)[0]
        pred_idx = int(torch.argmax(probabilities).item())
        confidence = float(probabilities[pred_idx].item())

    if pred_idx < 0 or pred_idx >= len(class_names):
        raise RuntimeError("Predicted class index is out of range.")

    prediction = class_names[pred_idx]
    if is_valid_class_dir(prediction):
        print(f"Predicted hygiene class: {prediction}")
        print(f"Model confidence: {confidence:.2%}")
    else:
        print(f"Predicted invalid helper class: {prediction}")
        print(f"Model confidence: {confidence:.2%}")
        print("This checkpoint should not be used. Retrain the model and test again.")

    logger.info("Predicted class: %s (confidence %.2f%%)", prediction, confidence * 100)


if __name__ == "__main__":
    try:
        main()
    except Exception as exc:
        logger.error("Prediction failed: %s", exc, exc_info=True)
        raise
