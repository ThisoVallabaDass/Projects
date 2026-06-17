"""
Comprehensive evaluation script for hygiene detection model.
Generates confusion matrix, per-class metrics, and analysis.
Focuses on identifying false positives (safety risk).
"""

import argparse
import logging
from pathlib import Path

import numpy as np
import torch
import torch.nn as nn
import torchvision.models as models
from torch.utils.data import DataLoader
from torchvision import transforms

from utils import HygieneImageFolder, resolve_dataset_dir, setup_logging

logger = logging.getLogger(__name__)

IMAGE_SIZE = 224


def load_model(checkpoint_path: Path, device: torch.device):
    """Load trained model from checkpoint."""
    if not checkpoint_path.exists():
        raise FileNotFoundError(f"Model not found: {checkpoint_path}")

    checkpoint = torch.load(checkpoint_path, map_location=device, weights_only=False)

    if isinstance(checkpoint, dict) and "model_state_dict" in checkpoint:
        arch = checkpoint.get("arch", "resnet18")
        idx_to_class = checkpoint.get("idx_to_class", {})
        image_size = int(checkpoint.get("image_size", 224))

        if arch.startswith("efficientnet"):
            if arch == "efficientnet_b1":
                model = models.efficientnet_b1(weights=None)
            else:
                model = models.efficientnet_b0(weights=None)
            num_classes = len(idx_to_class) if idx_to_class else model.classifier[1].out_features
            in_features = model.classifier[1].in_features
            model.classifier[1] = nn.Linear(in_features, num_classes)
        else:
            model = models.resnet18(weights=None)
            num_classes = len(idx_to_class) if idx_to_class else model.fc.out_features
            in_features = model.fc.in_features
            model.fc = nn.Linear(in_features, num_classes)

        model.load_state_dict(checkpoint["model_state_dict"])

        if idx_to_class:
            class_names = [idx_to_class[i] for i in sorted(idx_to_class.keys())]
        else:
            class_names = [f"class_{i}" for i in range(num_classes)]

        return model, class_names, image_size

    raise ValueError("Unsupported checkpoint format. Need model_state_dict in checkpoint.")


def evaluate_dataset(
    model: nn.Module,
    dataloader: DataLoader,
    class_names: list[str],
    device: torch.device,
) -> dict:
    """Evaluate model on dataset and compute metrics."""
    model.eval()
    num_classes = len(class_names)
    
    all_preds = []
    all_labels = []
    all_probs = []
    correct = 0
    total = 0

    print("Evaluating model...")
    with torch.no_grad():
        for images, labels in dataloader:
            images, labels = images.to(device), labels.to(device)
            outputs = model(images)
            probs = torch.softmax(outputs, dim=1)
            preds = outputs.argmax(dim=1)

            correct += (preds == labels).sum().item()
            total += labels.size(0)

            all_preds.extend(preds.cpu().numpy())
            all_labels.extend(labels.cpu().numpy())
            all_probs.extend(probs.cpu().numpy())

    all_preds = np.array(all_preds)
    all_labels = np.array(all_labels)
    all_probs = np.array(all_probs)

    # Compute confusion matrix
    cm = np.zeros((num_classes, num_classes), dtype=int)
    for pred, label in zip(all_preds, all_labels):
        cm[label, pred] += 1

    # Compute per-class metrics
    per_class_metrics = {}
    for i in range(num_classes):
        tp = cm[i, i]
        fp = cm[:, i].sum() - tp
        fn = cm[i, :].sum() - tp
        tn = cm.sum() - tp - fp - fn

        accuracy = (tp + tn) / (tp + tn + fp + fn) if (tp + tn + fp + fn) > 0 else 0
        precision = tp / (tp + fp) if (tp + fp) > 0 else 0
        recall = tp / (tp + fn) if (tp + fn) > 0 else 0
        f1 = 2 * (precision * recall) / (precision + recall) if (precision + recall) > 0 else 0
        specificity = tn / (tn + fp) if (tn + fp) > 0 else 0

        per_class_metrics[class_names[i]] = {
            "accuracy": accuracy,
            "precision": precision,
            "recall": recall,
            "f1": f1,
            "specificity": specificity,
            "support": (all_labels == i).sum(),
        }

    return {
        "overall_accuracy": correct / total,
        "confusion_matrix": cm,
        "per_class_metrics": per_class_metrics,
        "predictions": all_preds,
        "labels": all_labels,
        "probabilities": all_probs,
    }


def print_confusion_matrix(cm: np.ndarray, class_names: list[str]) -> None:
    """Print formatted confusion matrix."""
    print("\nConfusion Matrix:")
    print("=" * (12 + len(class_names) * 12))
    
    # Header
    print(f"{'':15}", end="")
    for class_name in class_names:
        print(f"{class_name:>12}", end="")
    print()
    
    print("-" * (12 + len(class_names) * 12))
    
    # Rows
    for i, row in enumerate(cm):
        print(f"{class_names[i]:<15}", end="")
        for val in row:
            print(f"{val:>12}", end="")
        print()
    
    print("=" * (12 + len(class_names) * 12))


def print_per_class_metrics(metrics: dict) -> None:
    """Print per-class metrics."""
    print("\nPer-Class Metrics:")
    print("=" * 100)
    print(
        f"{'Class':<20} {'Accuracy':<12} {'Precision':<12} {'Recall':<12} "
        f"{'F1':<12} {'Specificity':<12} {'Support':<10}"
    )
    print("-" * 100)
    
    for class_name, class_metrics in metrics.items():
        print(
            f"{class_name:<20} "
            f"{class_metrics['accuracy']:<12.4f} "
            f"{class_metrics['precision']:<12.4f} "
            f"{class_metrics['recall']:<12.4f} "
            f"{class_metrics['f1']:<12.4f} "
            f"{class_metrics['specificity']:<12.4f} "
            f"{int(class_metrics['support']):<10}"
        )
    
    print("=" * 100)


def analyze_false_positives(
    metrics: dict,
    class_names: list[str],
) -> None:
    """Analyze false positives (critical for safety)."""
    print("\nFalse Positive Analysis (Safety Concern):")
    print("=" * 70)
    
    cm = metrics["confusion_matrix"]
    
    # For safety-critical applications, focus on false negatives for 'shouldnt_work'
    if "shouldnt_work" in class_names:
        shouldnt_work_idx = class_names.index("shouldnt_work")
        
        # False negatives for shouldnt_work (classified as safe when unsafe)
        fn = cm[shouldnt_work_idx, :].sum() - cm[shouldnt_work_idx, shouldnt_work_idx]
        total_shouldnt_work = cm[shouldnt_work_idx, :].sum()
        
        if total_shouldnt_work > 0:
            fn_rate = fn / total_shouldnt_work
            print("\nWARNING: CRITICAL 'shouldnt_work' false negatives (unsafe classified as safe):")
            print(f"   False Negatives: {fn} / {total_shouldnt_work}")
            print(f"   False Negative Rate: {fn_rate*100:.2f}%")
            print(f"   (Lower is better for safety - ideally <5%)")
            
            # Show where they were classified
            for j, target_class in enumerate(class_names):
                if j != shouldnt_work_idx and cm[shouldnt_work_idx, j] > 0:
                    count = cm[shouldnt_work_idx, j]
                    print(
                        f"   -> {count} classified as '{target_class}' "
                        f"({count/total_shouldnt_work*100:.1f}%)"
                    )
    
    # False positives for 'meets_standard'
    if "meets_standard" in class_names:
        meets_standard_idx = class_names.index("meets_standard")
        
        fp = 0
        total_meets = cm[meets_standard_idx, :].sum()
        
        # Count misclassifications FROM other classes TO meets_standard
        for i in range(len(class_names)):
            if i != meets_standard_idx:
                fp += cm[i, meets_standard_idx]
        
        if total_meets > 0:
            fp_rate = fp / total_meets
            print("\nWARNING: False positives for 'meets_standard':")
            print(f"   False Positives: {fp} / {total_meets}")
            print(f"   False Positive Rate: {fp_rate*100:.2f}%")


def evaluate_model(
    model: nn.Module,
    dataloader,
    device: torch.device,
    class_names: list[str],
) -> dict:
    """
    Evaluate model on dataset.
    
    Returns:
        Dictionary with metrics: accuracy, precision, recall, f1, confusion_matrix
    """
    return evaluate_dataset(model, dataloader, class_names, device)


def print_metrics(metrics: dict) -> None:
    """Pretty print evaluation metrics - compatible wrapper."""
    print("\n" + "=" * 60)
    print("MODEL EVALUATION RESULTS")
    print("=" * 60)
    
    cm = metrics["confusion_matrix"]
    class_names = list(metrics["per_class_metrics"].keys())
    
    print(f"\nOverall Accuracy: {metrics['overall_accuracy']:.4f}")
    
    print_confusion_matrix(cm, class_names)
    print_per_class_metrics(metrics["per_class_metrics"])
    analyze_false_positives(metrics, class_names)


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Evaluate trained hygiene detection model."
    )
    parser.add_argument(
        "--model-path",
        type=str,
        default="models/hygiene_model.pth",
        help="Path to trained model checkpoint.",
    )
    parser.add_argument(
        "--dataset-dir",
        type=str,
        default=None,
        help="Dataset root directory for evaluation.",
    )
    parser.add_argument(
        "--batch-size",
        type=int,
        default=32,
        help="Batch size for evaluation.",
    )
    parser.add_argument(
        "--num-workers",
        type=int,
        default=0,
        help="Number of data loading workers.",
    )
    return parser.parse_args()


def main() -> None:
    setup_logging()
    args = parse_args()
    
    device = torch.device("cuda" if torch.cuda.is_available() else "cpu")
    logger.info(f"Using device: {device}")
    
    # Load model
    model_path = Path(args.model_path)
    model, class_names, image_size = load_model(model_path, device)
    logger.info(f"Loaded model from: {model_path}")
    logger.info(f"Architecture: {model.__class__.__name__}")
    logger.info(f"Classes: {class_names}")
    
    # Load dataset
    dataset_dir = resolve_dataset_dir(args.dataset_dir)
    eval_transform = transforms.Compose([
        transforms.Resize(256),
        transforms.CenterCrop(image_size),
        transforms.ToTensor(),
        transforms.Normalize(mean=[0.485, 0.456, 0.406], std=[0.229, 0.224, 0.225]),
    ])
    
    dataset = HygieneImageFolder(root=str(dataset_dir), transform=eval_transform)
    dataloader = DataLoader(
        dataset,
        batch_size=args.batch_size,
        shuffle=False,
        num_workers=args.num_workers,
        pin_memory=torch.cuda.is_available(),
    )
    
    logger.info(f"Total evaluation images: {len(dataset)}")
    
    # Evaluate
    print("\n" + "="*70)
    print("MODEL EVALUATION - INDIAN KITCHEN HYGIENE DETECTION")
    print("="*70)
    
    metrics = evaluate_dataset(model, dataloader, class_names, device)
    
    # Print results
    print(f"\nOverall Accuracy: {metrics['overall_accuracy']*100:.2f}%")
    
    print_confusion_matrix(metrics["confusion_matrix"], class_names)
    print_per_class_metrics(metrics["per_class_metrics"])
    analyze_false_positives(metrics, class_names)
    
    print("\n" + "="*70)
    print("Evaluation complete!")
    print("="*70 + "\n")
    
    logger.info("Evaluation complete.")


if __name__ == "__main__":
    try:
        main()
    except Exception as exc:
        logger.error(f"Evaluation failed: {exc}", exc_info=True)
        print(f"\nError: {exc}")
        raise
