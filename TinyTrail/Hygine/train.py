"""Train a hygiene classification model using transfer learning."""

import argparse
import copy
import logging
import random
from collections import Counter
from pathlib import Path

import torch
import torch.nn as nn
import torchvision.models as models
from torch.optim.lr_scheduler import ReduceLROnPlateau
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
    random.seed(seed)
    torch.manual_seed(seed)
    if torch.cuda.is_available():
        torch.cuda.manual_seed_all(seed)


def build_model(num_classes: int, architecture: str) -> nn.Module:
    if architecture == "efficientnet_b0":
        try:
            model = models.efficientnet_b0(weights=models.EfficientNet_B0_Weights.DEFAULT)
        except Exception:
            model = models.efficientnet_b0(weights=None)
        in_features = model.classifier[1].in_features
        model.classifier[1] = nn.Linear(in_features, num_classes)
        return model

    try:
        model = models.resnet18(weights=models.ResNet18_Weights.DEFAULT)
    except Exception:
        model = models.resnet18(weights=None)
    in_features = model.fc.in_features
    model.fc = nn.Linear(in_features, num_classes)
    return model


def freeze_backbone(model: nn.Module, architecture: str, freeze: bool) -> None:
    for param in model.parameters():
        param.requires_grad = not freeze

    if architecture == "efficientnet_b0":
        for param in model.classifier.parameters():
            param.requires_grad = True
    else:
        for param in model.fc.parameters():
            param.requires_grad = True


def make_transforms() -> tuple[transforms.Compose, transforms.Compose]:
    train_transform = transforms.Compose(
        [
            transforms.RandomResizedCrop(IMAGE_SIZE, scale=(0.7, 1.0)),
            transforms.RandomHorizontalFlip(p=0.5),
            transforms.RandomRotation(degrees=15),
            transforms.ColorJitter(brightness=0.2, contrast=0.2, saturation=0.2, hue=0.05),
            transforms.ToTensor(),
            transforms.Normalize(mean=[0.485, 0.456, 0.406], std=[0.229, 0.224, 0.225]),
        ]
    )
    eval_transform = transforms.Compose(
        [
            transforms.Resize(256),
            transforms.CenterCrop(IMAGE_SIZE),
            transforms.ToTensor(),
            transforms.Normalize(mean=[0.485, 0.456, 0.406], std=[0.229, 0.224, 0.225]),
        ]
    )
    return train_transform, eval_transform


def stratified_split(targets: list[int], val_split: float, seed: int) -> tuple[list[int], list[int]]:
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
) -> tuple[float, float]:
    model.eval()
    running_loss = 0.0
    correct = 0
    total = 0

    with torch.no_grad():
        for images, labels in dataloader:
            images, labels = images.to(device), labels.to(device)
            outputs = model(images)
            loss = criterion(outputs, labels)

            running_loss += loss.item() * images.size(0)
            preds = outputs.argmax(dim=1)
            correct += (preds == labels).sum().item()
            total += labels.size(0)

    return running_loss / max(total, 1), correct / max(total, 1)


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Train hygiene detection classifier.")
    parser.add_argument("--dataset-dir", type=str, default=None, help="Dataset root directory.")
    parser.add_argument(
        "--output",
        type=str,
        default="models/hygiene_model.pth",
        help="Output checkpoint path.",
    )
    parser.add_argument("--epochs", type=int, default=20, help="Number of training epochs.")
    parser.add_argument("--batch-size", type=int, default=32, help="Training batch size.")
    parser.add_argument("--lr", type=float, default=3e-4, help="Learning rate.")
    parser.add_argument(
        "--arch",
        type=str,
        default="resnet18",
        choices=["resnet18", "efficientnet_b0"],
        help="Backbone architecture.",
    )
    parser.add_argument("--num-workers", type=int, default=0, help="DataLoader workers.")
    parser.add_argument("--val-split", type=float, default=0.2, help="Validation split ratio.")
    parser.add_argument("--weight-decay", type=float, default=1e-4, help="Adam weight decay.")
    parser.add_argument("--label-smoothing", type=float, default=0.1, help="Label smoothing.")
    parser.add_argument("--patience", type=int, default=5, help="Early stopping patience.")
    parser.add_argument("--seed", type=int, default=42, help="Random seed.")
    parser.add_argument(
        "--freeze-epochs",
        type=int,
        default=1,
        help="Initial epochs with frozen backbone to stabilize transfer learning.",
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

    logger.info("Using device: %s", device)
    logger.info("Dataset directory: %s", dataset_dir)

    train_transform, eval_transform = make_transforms()
    base_dataset = HygieneImageFolder(root=str(dataset_dir))
    class_names = base_dataset.classes
    num_classes = len(class_names)
    if num_classes < 2:
        raise RuntimeError(f"Need at least 2 classes to train. Found: {class_names}")

    logger.info("Classes (%s): %s", num_classes, class_names)
    train_indices, val_indices = stratified_split(base_dataset.targets, args.val_split, args.seed)
    logger.info("Train images: %s | Validation images: %s", len(train_indices), len(val_indices))

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

    class_counts = Counter(base_dataset.targets[index] for index in train_indices)
    class_weights = torch.tensor(
        [len(train_indices) / (num_classes * class_counts[i]) for i in range(num_classes)],
        dtype=torch.float32,
        device=device,
    )

    model = build_model(num_classes=num_classes, architecture=args.arch).to(device)
    freeze_backbone(model, args.arch, freeze=args.freeze_epochs > 0)

    criterion = nn.CrossEntropyLoss(weight=class_weights, label_smoothing=args.label_smoothing)
    optimizer = torch.optim.AdamW(
        filter(lambda p: p.requires_grad, model.parameters()),
        lr=args.lr,
        weight_decay=args.weight_decay,
    )
    scheduler = ReduceLROnPlateau(optimizer, mode="min", factor=0.5, patience=2)

    best_state = copy.deepcopy(model.state_dict())
    best_val_acc = 0.0
    best_val_loss = float("inf")
    stale_epochs = 0

    for epoch in range(args.epochs):
        if epoch == args.freeze_epochs:
            freeze_backbone(model, args.arch, freeze=False)
            optimizer = torch.optim.AdamW(model.parameters(), lr=args.lr, weight_decay=args.weight_decay)
            scheduler = ReduceLROnPlateau(optimizer, mode="min", factor=0.5, patience=2)
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
        val_loss, val_acc = evaluate(model, val_loader, criterion, device)
        scheduler.step(val_loss)
        current_lr = optimizer.param_groups[0]["lr"]

        logger.info(
            "Epoch %s/%s | train_loss=%.4f train_acc=%.2f%% | val_loss=%.4f val_acc=%.2f%% | lr=%.6f",
            epoch + 1,
            args.epochs,
            train_loss,
            train_acc * 100,
            val_loss,
            val_acc * 100,
            current_lr,
        )

        if val_acc > best_val_acc or (val_acc == best_val_acc and val_loss < best_val_loss):
            best_val_acc = val_acc
            best_val_loss = val_loss
            best_state = copy.deepcopy(model.state_dict())
            stale_epochs = 0
        else:
            stale_epochs += 1
            if stale_epochs >= args.patience:
                logger.info("Early stopping triggered after %s stale epochs.", stale_epochs)
                break

    model.load_state_dict(best_state)
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
        "train_size": len(train_indices),
        "val_size": len(val_indices),
    }
    torch.save(checkpoint, output_path)
    logger.info("Best model saved to: %s", output_path)
    logger.info("Best validation accuracy: %.2f%%", best_val_acc * 100)


if __name__ == "__main__":
    try:
        main()
    except Exception as exc:
        logger.error("Training failed: %s", exc, exc_info=True)
        raise

