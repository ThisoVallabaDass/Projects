"""
Enhanced training script for hygiene classification with Indian kitchen focus.
Includes: early stopping, class-weighted loss, confusion matrix, per-class metrics.
"""

import argparse
import copy
import json
import logging
import random
from collections import Counter
from pathlib import Path

import numpy as np
import torch
import torch.nn as nn
import torchvision.models as models
from torch.optim.lr_scheduler import ReduceLROnPlateau, CosineAnnealingLR
from torch.utils.data import DataLoader, Subset, WeightedRandomSampler
from torchvision import transforms

from utils import HygieneImageFolder, has_images, resolve_dataset_dir, setup_logging

try:
    from tqdm.auto import tqdm
except Exception:  # pragma: no cover
    def tqdm(iterable, **kwargs):  # type: ignore
        return iterable

logger = logging.getLogger(__name__)

IMAGE_SIZE = 224


def set_seed(seed: int) -> None:
    """Set random seeds for reproducibility."""
    random.seed(seed)
    np.random.seed(seed)
    torch.manual_seed(seed)
    if torch.cuda.is_available():
        torch.cuda.manual_seed_all(seed)


def build_model(num_classes: int, architecture: str) -> nn.Module:
    """Build classification model with pretrained weights."""
    if architecture == "efficientnet_b0":
        try:
            model = models.efficientnet_b0(weights=models.EfficientNet_B0_Weights.DEFAULT)
        except Exception:
            model = models.efficientnet_b0(weights=None)
        in_features = model.classifier[1].in_features
        model.classifier[1] = nn.Linear(in_features, num_classes)
        return model
    
    elif architecture == "efficientnet_b1":
        try:
            model = models.efficientnet_b1(weights=models.EfficientNet_B1_Weights.DEFAULT)
        except Exception:
            model = models.efficientnet_b1(weights=None)
        in_features = model.classifier[1].in_features
        model.classifier[1] = nn.Linear(in_features, num_classes)
        return model

    else:  # resnet18
        try:
            model = models.resnet18(weights=models.ResNet18_Weights.DEFAULT)
        except Exception:
            model = models.resnet18(weights=None)
        in_features = model.fc.in_features
        model.fc = nn.Linear(in_features, num_classes)
        return model


def freeze_backbone(model: nn.Module, architecture: str, freeze: bool) -> None:
    """Freeze/unfreeze backbone weights for transfer learning."""
    for param in model.parameters():
        param.requires_grad = not freeze

    if architecture.startswith("efficientnet"):
        for param in model.classifier.parameters():
            param.requires_grad = True
    else:
        for param in model.fc.parameters():
            param.requires_grad = True


def make_transforms() -> tuple[transforms.Compose, transforms.Compose]:
    """Create data augmentation transforms."""
    train_transform = transforms.Compose([
        # Aggressive crop forces model to learn prep zone (stove/utensils),
        # reducing overfitting to wall/background appearance.
        transforms.RandomResizedCrop(IMAGE_SIZE, scale=(0.55, 1.0), ratio=(0.75, 1.33)),
        transforms.RandomHorizontalFlip(p=0.5),
        transforms.RandomRotation(degrees=20),
        # Additional augmentation for mobile phone variability
        transforms.RandomAffine(degrees=0, shear=10),
        transforms.RandomPerspective(distortion_scale=0.15, p=0.2),
        transforms.ColorJitter(brightness=0.3, contrast=0.3, saturation=0.2, hue=0.1),
        transforms.RandomAutocontrast(p=0.15),
        transforms.GaussianBlur(kernel_size=3, sigma=(0.1, 2.0)),
        transforms.ToTensor(),
        # Randomly mask patch regions so the model does not depend on
        # fixed background cues (tiles/walls/paint).
        transforms.RandomErasing(p=0.25, scale=(0.02, 0.18), ratio=(0.3, 3.3), value='random'),
        transforms.Normalize(mean=[0.485, 0.456, 0.406], std=[0.229, 0.224, 0.225]),
    ])
    
    eval_transform = transforms.Compose([
        transforms.Resize(256),
        transforms.CenterCrop(IMAGE_SIZE),
        transforms.ToTensor(),
        transforms.Normalize(mean=[0.485, 0.456, 0.406], std=[0.229, 0.224, 0.225]),
    ])
    
    return train_transform, eval_transform


def stratified_split(targets: list[int], val_split: float, seed: int) -> tuple[list[int], list[int]]:
    """Create stratified train/validation split."""
    rng = random.Random(seed)
    by_class: dict[int, list[int]] = {}
    
    for index, target in enumerate(targets):
        by_class.setdefault(target, []).append(index)

    train_indices: list[int] = []
    val_indices: list[int] = []
    
    for _, indices in sorted(by_class.items()):
        rng.shuffle(indices)
        val_count = max(1, int(len(indices) * val_split))
        if len(indices) - val_count < 1:
            val_count = max(0, len(indices) - 1)
        val_indices.extend(indices[:val_count])
        train_indices.extend(indices[val_count:])

    if not train_indices or not val_indices:
        raise RuntimeError("Could not create train/validation split. Add more images per class.")

    rng.shuffle(train_indices)
    rng.shuffle(val_indices)
    return train_indices, val_indices


def create_sampler(targets: list[int], indices: list[int]) -> WeightedRandomSampler:
    """Create weighted sampler for balanced training."""
    class_counts = Counter(targets[index] for index in indices)
    sample_weights = [1.0 / class_counts[targets[index]] for index in indices]
    return WeightedRandomSampler(
        weights=torch.DoubleTensor(sample_weights),
        num_samples=len(indices),
        replacement=True,
    )


def evaluate(
    model: nn.Module,
    dataloader: DataLoader,
    criterion: nn.Module,
    device: torch.device,
    class_names: list[str] = None,
) -> dict:
    """Evaluate model and compute metrics."""
    model.eval()
    running_loss = 0.0
    correct = 0
    total = 0
    
    all_preds = []
    all_labels = []

    with torch.no_grad():
        for images, labels in dataloader:
            images, labels = images.to(device), labels.to(device)
            outputs = model(images)
            loss = criterion(outputs, labels)

            running_loss += loss.item() * images.size(0)
            preds = outputs.argmax(dim=1)
            correct += (preds == labels).sum().item()
            total += labels.size(0)
            
            all_preds.extend(preds.cpu().numpy())
            all_labels.extend(labels.cpu().numpy())

    avg_loss = running_loss / max(total, 1)
    accuracy = correct / max(total, 1)
    
    metrics = {
        "loss": avg_loss,
        "accuracy": accuracy,
        "preds": all_preds,
        "labels": all_labels,
    }
    
    # Per-class metrics
    if class_names:
        num_classes = len(class_names)
        for class_idx in range(num_classes):
            mask = np.array(all_labels) == class_idx
            if mask.sum() > 0:
                class_preds = np.array(all_preds)[mask]
                class_acc = (class_preds == class_idx).sum() / mask.sum()
                metrics[f"{class_names[class_idx]}_accuracy"] = class_acc
    
    return metrics


def compute_confusion_matrix(preds: list[int], labels: list[int], num_classes: int) -> np.ndarray:
    """Compute confusion matrix."""
    cm = np.zeros((num_classes, num_classes), dtype=int)
    for pred, label in zip(preds, labels):
        cm[label, pred] += 1
    return cm


def print_metrics_summary(
    metrics: dict,
    class_names: list[str],
    stage: str = "Validation"
) -> None:
    """Print comprehensive metrics summary."""
    print(f"\n{stage} Metrics:")
    print(f"  Loss: {metrics['loss']:.4f}")
    print(f"  Overall Accuracy: {metrics['accuracy']*100:.2f}%")
    
    for class_name in class_names:
        key = f"{class_name}_accuracy"
        if key in metrics:
            print(f"  {class_name} Accuracy: {metrics[key]*100:.2f}%")


def class_recall_from_metrics(metrics: dict, class_names: list[str], target_class: str) -> float:
    if target_class not in class_names:
        return 0.0

    target_idx = class_names.index(target_class)
    labels = np.array(metrics["labels"])
    preds = np.array(metrics["preds"])
    mask = labels == target_idx
    if mask.sum() == 0:
        return 0.0
    return float((preds[mask] == target_idx).sum() / mask.sum())


def selection_score(metrics: dict, class_names: list[str]) -> float:
    """Favor unsafe recall while still rewarding global accuracy."""
    unsafe_recall = class_recall_from_metrics(metrics, class_names, "shouldnt_work")
    review_recall = class_recall_from_metrics(metrics, class_names, "needs_work")
    return (0.55 * unsafe_recall) + (0.30 * metrics["accuracy"]) + (0.15 * review_recall)


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Train hygiene detection classifier for Indian kitchens."
    )
    parser.add_argument("--dataset-dir", type=str, default=None, help="Dataset root directory.")
    parser.add_argument(
        "--output",
        type=str,
        default="models/hygiene_model.pth",
        help="Output checkpoint path.",
    )
    parser.add_argument(
        "--epochs",
        type=int,
        default=35,
        help="Number of training epochs (default: 30 for better Indian kitchen accuracy).",
    )
    parser.add_argument("--batch-size", type=int, default=16, help="Training batch size.")
    parser.add_argument(
        "--lr",
        type=float,
        default=0.0003,
        help="Learning rate (default: 0.0005 for stable fine-tuning).",
    )
    parser.add_argument(
        "--arch",
        type=str,
        default="efficientnet_b0",
        choices=["resnet18", "efficientnet_b0", "efficientnet_b1"],
        help="Backbone architecture (recommended: efficientnet_b0).",
    )
    parser.add_argument("--num-workers", type=int, default=0, help="DataLoader workers.")
    parser.add_argument("--val-split", type=float, default=0.2, help="Validation split ratio.")
    parser.add_argument("--weight-decay", type=float, default=1e-4, help="AdamW weight decay.")
    parser.add_argument("--label-smoothing", type=float, default=0.1, help="Label smoothing.")
    parser.add_argument(
        "--patience",
        type=int,
        default=8,
        help="Early stopping patience (epochs without improvement).",
    )
    parser.add_argument("--seed", type=int, default=42, help="Random seed.")
    parser.add_argument(
        "--freeze-epochs",
        type=int,
        default=4,
        help="Initial epochs with frozen backbone for stable transfer learning.",
    )
    parser.add_argument(
        "--scheduler",
        type=str,
        default="reduce_lr_on_plateau",
        choices=["reduce_lr_on_plateau", "cosine"],
        help="Learning rate scheduler.",
    )
    parser.add_argument(
        "--report-path",
        type=str,
        default="models/training_report.json",
        help="Path to write a JSON training summary.",
    )
    return parser.parse_args()


def main() -> None:
    setup_logging()
    args = parse_args()
    set_seed(args.seed)

    if not 0.0 < args.val_split < 0.5:
        raise ValueError("--val-split must be between 0 and 0.5.")

    device = torch.device("cuda" if torch.cuda.is_available() else "cpu")
    dataset_dir = resolve_dataset_dir(args.dataset_dir)
    
    if not has_images(dataset_dir):
        raise RuntimeError(f"No images found in dataset directory: {dataset_dir}")

    print("\n" + "="*70)
    print("TRAINING HYGIENE DETECTION MODEL - INDIAN KITCHENS")
    print("="*70)
    
    logger.info(f"Using device: {device}")
    logger.info(f"Dataset directory: {dataset_dir}")
    logger.info(f"Architecture: {args.arch}")
    logger.info(f"Learning rate: {args.lr}")
    logger.info(f"Batch size: {args.batch_size}")
    logger.info(f"Epochs: {args.epochs}")

    train_transform, eval_transform = make_transforms()
    base_dataset = HygieneImageFolder(root=str(dataset_dir))
    class_names = base_dataset.classes
    num_classes = len(class_names)
    
    if num_classes < 2:
        raise RuntimeError(f"Need at least 2 classes. Found: {class_names}")

    # Validate required classes
    required_classes = {"meets_standard", "needs_work", "shouldnt_work"}
    actual_classes = set(class_names)
    if not required_classes.issubset(actual_classes):
        logger.warning(
            f"Expected classes {required_classes}, but found {actual_classes}. "
            "Model may not be compatible with existing integration."
        )

    logger.info(f"Classes ({num_classes}): {class_names}")
    
    train_indices, val_indices = stratified_split(
        base_dataset.targets, args.val_split, args.seed
    )
    logger.info(f"Train images: {len(train_indices)} | Validation images: {len(val_indices)}")

    train_dataset = HygieneImageFolder(root=str(dataset_dir), transform=train_transform)
    val_dataset = HygieneImageFolder(root=str(dataset_dir), transform=eval_transform)
    train_subset = Subset(train_dataset, train_indices)
    val_subset = Subset(val_dataset, val_indices)

    sampler = create_sampler(base_dataset.targets, train_indices)
    train_loader = DataLoader(
        train_subset,
        batch_size=args.batch_size,
        sampler=sampler,
        num_workers=args.num_workers,
        pin_memory=torch.cuda.is_available(),
    )
    val_loader = DataLoader(
        val_subset,
        batch_size=args.batch_size,
        shuffle=False,
        num_workers=args.num_workers,
        pin_memory=torch.cuda.is_available(),
    )

    # Class weights for handling imbalance
    class_counts = Counter(base_dataset.targets[index] for index in train_indices)
    class_weights = torch.tensor(
        [len(train_indices) / (num_classes * class_counts[i]) for i in range(num_classes)],
        dtype=torch.float32,
        device=device,
    )
    logger.info(f"Class weights: {class_weights.cpu().tolist()}")

    model = build_model(num_classes=num_classes, architecture=args.arch).to(device)
    freeze_backbone(model, args.arch, freeze=args.freeze_epochs > 0)

    criterion = nn.CrossEntropyLoss(weight=class_weights, label_smoothing=args.label_smoothing)
    optimizer = torch.optim.AdamW(
        filter(lambda p: p.requires_grad, model.parameters()),
        lr=args.lr,
        weight_decay=args.weight_decay,
    )
    
    if args.scheduler == "cosine":
        scheduler = CosineAnnealingLR(optimizer, T_max=args.epochs)
    else:
        scheduler = ReduceLROnPlateau(optimizer, mode="min", factor=0.5, patience=3)

    best_state = copy.deepcopy(model.state_dict())
    best_val_acc = 0.0
    best_val_loss = float("inf")
    best_selection = -1.0
    stale_epochs = 0
    
    print("\nStarting training...\n")

    for epoch in range(args.epochs):
        # Unfreeze backbone after initial epochs
        if epoch == args.freeze_epochs and args.freeze_epochs > 0:
            freeze_backbone(model, args.arch, freeze=False)
            optimizer = torch.optim.AdamW(
                model.parameters(),
                lr=args.lr,
                weight_decay=args.weight_decay,
            )
            logger.info("Unfroze backbone for full fine-tuning.")

        model.train()
        running_loss = 0.0
        correct = 0
        total = 0

        progress = tqdm(train_loader, desc=f"Epoch {epoch + 1}/{args.epochs}", leave=False)
        for images, labels in progress:
            images, labels = images.to(device), labels.to(device)

            optimizer.zero_grad()
            outputs = model(images)
            loss = criterion(outputs, labels)
            loss.backward()
            torch.nn.utils.clip_grad_norm_(model.parameters(), max_norm=1.0)
            optimizer.step()

            running_loss += loss.item() * images.size(0)
            preds = outputs.argmax(dim=1)
            correct += (preds == labels).sum().item()
            total += labels.size(0)

            if hasattr(progress, "set_postfix"):
                progress.set_postfix(
                    train_loss=f"{running_loss / max(total, 1):.4f}",
                    train_acc=f"{(correct / max(total, 1)) * 100:.2f}%",
                )

        train_loss = running_loss / max(total, 1)
        train_acc = correct / max(total, 1)
        
        val_metrics = evaluate(model, val_loader, criterion, device, class_names)
        val_loss = val_metrics["loss"]
        val_acc = val_metrics["accuracy"]
        val_selection = selection_score(val_metrics, class_names)
        val_unsafe_recall = class_recall_from_metrics(val_metrics, class_names, "shouldnt_work")
        
        if args.scheduler == "cosine":
            scheduler.step()
        else:
            scheduler.step(val_loss)
        
        current_lr = optimizer.param_groups[0]["lr"]

        logger.info(
            f"Epoch {epoch + 1}/{args.epochs} | "
            f"train_loss={train_loss:.4f} train_acc={train_acc*100:.2f}% | "
            f"val_loss={val_loss:.4f} val_acc={val_acc*100:.2f}% | "
            f"unsafe_recall={val_unsafe_recall*100:.2f}% | "
            f"selection={val_selection:.4f} | "
            f"lr={current_lr:.6f}"
        )

        # Save best model
        if (
            val_selection > best_selection
            or (
                val_selection == best_selection
                and (val_acc > best_val_acc or (val_acc == best_val_acc and val_loss < best_val_loss))
            )
        ):
            best_selection = val_selection
            best_val_acc = val_acc
            best_val_loss = val_loss
            best_state = copy.deepcopy(model.state_dict())
            stale_epochs = 0
            logger.info(
                "New best model: val_acc=%.2f%% unsafe_recall=%.2f%% selection=%.4f",
                best_val_acc * 100,
                val_unsafe_recall * 100,
                best_selection,
            )
        else:
            stale_epochs += 1
            if stale_epochs >= args.patience:
                logger.info(f"Early stopping: {stale_epochs} epochs without improvement")
                break

    # Load best model
    model.load_state_dict(best_state)
    
    # Compute final metrics
    print("\nComputing final evaluation metrics...")
    final_val_metrics = evaluate(model, val_loader, criterion, device, class_names)
    
    # Save checkpoint
    output_path = Path(args.output)
    output_path.parent.mkdir(parents=True, exist_ok=True)
    
    checkpoint = {
        "arch": args.arch,
        "model_state_dict": model.state_dict(),
        "class_to_idx": base_dataset.class_to_idx,
        "idx_to_class": {v: k for k, v in base_dataset.class_to_idx.items()},
        "image_size": IMAGE_SIZE,
        "best_val_acc": best_val_acc,
        "best_val_loss": best_val_loss,
        "best_selection_score": best_selection,
        "train_size": len(train_indices),
        "val_size": len(val_indices),
        "class_names": class_names,
        "num_classes": num_classes,
    }
    
    torch.save(checkpoint, output_path)
    logger.info(f"Best model saved to: {output_path}")
    
    confusion = compute_confusion_matrix(
        final_val_metrics["preds"],
        final_val_metrics["labels"],
        num_classes,
    )
    report = {
        "arch": args.arch,
        "best_val_acc": best_val_acc,
        "best_val_loss": best_val_loss,
        "best_selection_score": best_selection,
        "train_size": len(train_indices),
        "val_size": len(val_indices),
        "classes": class_names,
        "unsafe_recall": class_recall_from_metrics(final_val_metrics, class_names, "shouldnt_work"),
        "review_recall": class_recall_from_metrics(final_val_metrics, class_names, "needs_work"),
        "confusion_matrix": confusion.tolist(),
        "per_class_accuracy": {
            class_name: final_val_metrics.get(f"{class_name}_accuracy", 0.0)
            for class_name in class_names
        },
    }
    report_path = Path(args.report_path)
    report_path.parent.mkdir(parents=True, exist_ok=True)
    report_path.write_text(json.dumps(report, indent=2))
    logger.info(f"Training report saved to: {report_path}")

    # Print summary
    print("\n" + "="*70)
    print("TRAINING COMPLETE")
    print("="*70)
    print(f"Best validation accuracy: {best_val_acc*100:.2f}%")
    print(f"Best validation loss: {best_val_loss:.4f}")
    print(f"Selection score: {best_selection:.4f}")
    print(f"\nPer-class accuracy:")
    for class_name in class_names:
        key = f"{class_name}_accuracy"
        if key in final_val_metrics:
            acc = final_val_metrics[key]
            print(f"  {class_name}: {acc*100:.2f}%")
    print(f"\nModel saved to: {output_path}")
    print(f"Training report: {report_path}")
    print("="*70 + "\n")


if __name__ == "__main__":
    try:
        main()
    except Exception as exc:
        logger.error(f"Training failed: {exc}", exc_info=True)
        print(f"\nError: {exc}")
        raise
