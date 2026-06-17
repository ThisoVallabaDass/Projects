"""
Enhanced training script for Indian Kitchen Hygiene Detection.

This script trains a model specifically designed for:
- Indian home kitchens
- Street food carts
- Small hotels/restaurants

Focus areas:
- Stove cleanliness
- Vessel/utensil cleanliness
- Leftover food detection
- General workspace hygiene
"""

import argparse
import copy
import json
import logging
import random
import os
import sys
from collections import Counter
from pathlib import Path
from datetime import datetime

import numpy as np
import torch
import torch.nn as nn
import torchvision.models as models
from torch.optim.lr_scheduler import CosineAnnealingWarmRestarts, OneCycleLR
from torch.utils.data import DataLoader, Subset, WeightedRandomSampler
from torchvision import transforms
from PIL import Image

try:
    from tqdm.auto import tqdm
except ImportError:
    def tqdm(iterable, **kwargs):
        return iterable

# Setup logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s',
    handlers=[
        logging.StreamHandler(sys.stdout),
        logging.FileHandler('training_indian_kitchen.log', encoding='utf-8')
    ]
)
logger = logging.getLogger(__name__)

IMAGE_SIZE = 224

# Issue categories for detailed feedback
ISSUE_CATEGORIES = {
    'dirty_vessels': 'Dirty or unwashed vessels/utensils detected',
    'unclean_stove': 'Stove area needs cleaning (grease/burnt residue)',
    'leftover_food': 'Leftover food particles or waste visible',
    'cluttered_workspace': 'Workspace is cluttered and disorganized',
    'grease_stains': 'Oil/grease stains on surfaces',
    'poor_lighting': 'Image taken in poor lighting conditions',
    'general_uncleanliness': 'General hygiene standards not met',
}


class HygieneImageFolder(torch.utils.data.Dataset):
    """Custom dataset for hygiene images with proper error handling."""

    def __init__(self, root, transform=None):
        self.root = Path(root)
        self.transform = transform
        self.samples = []
        self.targets = []
        self.classes = []
        self.class_to_idx = {}

        # Find all class directories
        class_dirs = sorted([
            d for d in self.root.iterdir()
            if d.is_dir() and not d.name.startswith('_')
        ])

        self.classes = [d.name for d in class_dirs]
        self.class_to_idx = {cls: idx for idx, cls in enumerate(self.classes)}

        # Collect all images
        valid_extensions = {'.jpg', '.jpeg', '.png', '.bmp', '.webp'}

        for class_dir in class_dirs:
            class_idx = self.class_to_idx[class_dir.name]
            for img_path in class_dir.iterdir():
                if img_path.suffix.lower() in valid_extensions:
                    self.samples.append((str(img_path), class_idx))
                    self.targets.append(class_idx)

        logger.info(f"Loaded {len(self.samples)} images from {len(self.classes)} classes")
        for cls, idx in self.class_to_idx.items():
            count = sum(1 for _, c in self.samples if c == idx)
            logger.info(f"  {cls}: {count} images")

    def __len__(self):
        return len(self.samples)

    def __getitem__(self, idx):
        img_path, target = self.samples[idx]
        try:
            image = Image.open(img_path).convert('RGB')
            if self.transform:
                image = self.transform(image)
            return image, target
        except Exception as e:
            logger.warning(f"Error loading {img_path}: {e}")
            # Return a random valid image instead
            new_idx = random.randint(0, len(self.samples) - 1)
            return self.__getitem__(new_idx)


def set_seed(seed):
    """Set all random seeds for reproducibility."""
    random.seed(seed)
    np.random.seed(seed)
    torch.manual_seed(seed)
    if torch.cuda.is_available():
        torch.cuda.manual_seed_all(seed)
        torch.backends.cudnn.deterministic = True
        torch.backends.cudnn.benchmark = False


def get_train_transforms():
    """Create aggressive data augmentation for training."""
    return transforms.Compose([
        # Random crop focusing on prep area (stove, vessels)
        transforms.RandomResizedCrop(
            IMAGE_SIZE,
            scale=(0.5, 1.0),  # More aggressive cropping
            ratio=(0.75, 1.33)
        ),
        transforms.RandomHorizontalFlip(p=0.5),
        transforms.RandomRotation(degrees=15),
        # Perspective transforms for mobile phone angles
        transforms.RandomPerspective(distortion_scale=0.2, p=0.3),
        transforms.RandomAffine(
            degrees=0,
            translate=(0.1, 0.1),
            shear=10
        ),
        # Color augmentation for varying kitchen lighting
        transforms.ColorJitter(
            brightness=0.4,
            contrast=0.4,
            saturation=0.3,
            hue=0.1
        ),
        # Random adjustments
        transforms.RandomAutocontrast(p=0.2),
        transforms.RandomEqualize(p=0.1),
        transforms.GaussianBlur(kernel_size=3, sigma=(0.1, 2.0)),
        transforms.ToTensor(),
        # Random erasing to prevent overfitting to specific patterns
        transforms.RandomErasing(
            p=0.3,
            scale=(0.02, 0.2),
            ratio=(0.3, 3.3),
            value='random'
        ),
        transforms.Normalize(
            mean=[0.485, 0.456, 0.406],
            std=[0.229, 0.224, 0.225]
        ),
    ])


def get_eval_transforms():
    """Create evaluation transforms."""
    return transforms.Compose([
        transforms.Resize(256),
        transforms.CenterCrop(IMAGE_SIZE),
        transforms.ToTensor(),
        transforms.Normalize(
            mean=[0.485, 0.456, 0.406],
            std=[0.229, 0.224, 0.225]
        ),
    ])


def build_model(num_classes, architecture='efficientnet_b0', dropout=0.3):
    """Build classification model with pretrained weights and custom head."""

    if architecture == 'efficientnet_b2':
        try:
            model = models.efficientnet_b2(weights=models.EfficientNet_B2_Weights.DEFAULT)
        except:
            model = models.efficientnet_b2(weights=None)
        in_features = model.classifier[1].in_features
        model.classifier = nn.Sequential(
            nn.Dropout(p=dropout),
            nn.Linear(in_features, 512),
            nn.ReLU(inplace=True),
            nn.Dropout(p=dropout * 0.5),
            nn.Linear(512, num_classes)
        )
    elif architecture == 'efficientnet_b1':
        try:
            model = models.efficientnet_b1(weights=models.EfficientNet_B1_Weights.DEFAULT)
        except:
            model = models.efficientnet_b1(weights=None)
        in_features = model.classifier[1].in_features
        model.classifier = nn.Sequential(
            nn.Dropout(p=dropout),
            nn.Linear(in_features, 256),
            nn.ReLU(inplace=True),
            nn.Dropout(p=dropout * 0.5),
            nn.Linear(256, num_classes)
        )
    elif architecture == 'efficientnet_b0':
        try:
            model = models.efficientnet_b0(weights=models.EfficientNet_B0_Weights.DEFAULT)
        except:
            model = models.efficientnet_b0(weights=None)
        in_features = model.classifier[1].in_features
        model.classifier = nn.Sequential(
            nn.Dropout(p=dropout),
            nn.Linear(in_features, num_classes)
        )
    else:  # resnet18
        try:
            model = models.resnet18(weights=models.ResNet18_Weights.DEFAULT)
        except:
            model = models.resnet18(weights=None)
        in_features = model.fc.in_features
        model.fc = nn.Sequential(
            nn.Dropout(p=dropout),
            nn.Linear(in_features, num_classes)
        )

    return model


def freeze_backbone(model, architecture, freeze=True):
    """Freeze/unfreeze backbone for transfer learning."""
    for param in model.parameters():
        param.requires_grad = not freeze

    # Always keep classifier trainable
    if architecture.startswith('efficientnet'):
        for param in model.classifier.parameters():
            param.requires_grad = True
    else:
        for param in model.fc.parameters():
            param.requires_grad = True


def stratified_split(targets, val_split=0.2, seed=42):
    """Create stratified train/validation split."""
    rng = random.Random(seed)
    by_class = {}

    for idx, target in enumerate(targets):
        by_class.setdefault(target, []).append(idx)

    train_indices = []
    val_indices = []

    for _, indices in sorted(by_class.items()):
        rng.shuffle(indices)
        val_count = max(1, int(len(indices) * val_split))
        val_indices.extend(indices[:val_count])
        train_indices.extend(indices[val_count:])

    rng.shuffle(train_indices)
    rng.shuffle(val_indices)

    return train_indices, val_indices


def create_weighted_sampler(targets, indices):
    """Create weighted sampler for balanced training."""
    class_counts = Counter(targets[idx] for idx in indices)
    weights = [1.0 / class_counts[targets[idx]] for idx in indices]
    return WeightedRandomSampler(
        weights=torch.DoubleTensor(weights),
        num_samples=len(indices),
        replacement=True
    )


def compute_class_weights(targets, indices, num_classes, device):
    """Compute class weights for loss function."""
    class_counts = Counter(targets[idx] for idx in indices)
    total = len(indices)

    # Use inverse frequency with smoothing
    weights = []
    for i in range(num_classes):
        count = class_counts.get(i, 1)
        weight = total / (num_classes * count)
        weights.append(weight)

    # Boost weight for unsafe class (more important to catch)
    weights[-1] *= 1.3  # shouldnt_work gets higher weight

    return torch.tensor(weights, dtype=torch.float32, device=device)


def evaluate(model, dataloader, criterion, device, class_names):
    """Evaluate model and compute detailed metrics."""
    model.eval()
    running_loss = 0.0
    correct = 0
    total = 0
    all_preds = []
    all_labels = []

    with torch.no_grad():
        for images, labels in dataloader:
            images = images.to(device)
            labels = labels.to(device)

            outputs = model(images)
            loss = criterion(outputs, labels)

            running_loss += loss.item() * images.size(0)
            preds = outputs.argmax(dim=1)
            correct += (preds == labels).sum().item()
            total += labels.size(0)

            all_preds.extend(preds.cpu().numpy())
            all_labels.extend(labels.cpu().numpy())

    metrics = {
        'loss': running_loss / max(total, 1),
        'accuracy': correct / max(total, 1),
        'preds': all_preds,
        'labels': all_labels,
    }

    # Per-class accuracy (recall)
    for idx, class_name in enumerate(class_names):
        mask = np.array(all_labels) == idx
        if mask.sum() > 0:
            class_preds = np.array(all_preds)[mask]
            recall = (class_preds == idx).sum() / mask.sum()
            metrics[f'{class_name}_recall'] = recall

    # Per-class precision
    for idx, class_name in enumerate(class_names):
        pred_mask = np.array(all_preds) == idx
        if pred_mask.sum() > 0:
            correct_preds = (np.array(all_labels)[pred_mask] == idx).sum()
            precision = correct_preds / pred_mask.sum()
            metrics[f'{class_name}_precision'] = precision

    return metrics


def compute_selection_score(metrics, class_names):
    """Compute weighted selection score prioritizing unsafe detection."""
    unsafe_recall = metrics.get('shouldnt_work_recall', 0.0)
    review_recall = metrics.get('needs_work_recall', 0.0)
    safe_recall = metrics.get('meets_standard_recall', 0.0)
    accuracy = metrics.get('accuracy', 0.0)

    # Weight unsafe recall heavily (most important for food safety)
    return (0.45 * unsafe_recall) + (0.25 * review_recall) + (0.15 * safe_recall) + (0.15 * accuracy)


def train_epoch(model, dataloader, criterion, optimizer, device, epoch, total_epochs):
    """Train for one epoch."""
    model.train()
    running_loss = 0.0
    correct = 0
    total = 0

    progress = tqdm(dataloader, desc=f'Epoch {epoch+1}/{total_epochs}', leave=False)

    for images, labels in progress:
        images = images.to(device)
        labels = labels.to(device)

        optimizer.zero_grad()
        outputs = model(images)
        loss = criterion(outputs, labels)
        loss.backward()

        # Gradient clipping
        torch.nn.utils.clip_grad_norm_(model.parameters(), max_norm=1.0)

        optimizer.step()

        running_loss += loss.item() * images.size(0)
        preds = outputs.argmax(dim=1)
        correct += (preds == labels).sum().item()
        total += labels.size(0)

        if hasattr(progress, 'set_postfix'):
            progress.set_postfix(
                loss=f'{running_loss/max(total,1):.4f}',
                acc=f'{100*correct/max(total,1):.2f}%'
            )

    return running_loss / max(total, 1), correct / max(total, 1)


def main():
    parser = argparse.ArgumentParser(
        description='Train Indian Kitchen Hygiene Detection Model'
    )
    parser.add_argument(
        '--dataset-dir',
        type=str,
        default='AI_Hygiene_Model/dataset',
        help='Dataset directory path'
    )
    parser.add_argument(
        '--output',
        type=str,
        default='models/hygiene_model_indian_kitchen.pth',
        help='Output model path'
    )
    parser.add_argument('--epochs', type=int, default=50, help='Training epochs')
    parser.add_argument('--batch-size', type=int, default=32, help='Batch size')
    parser.add_argument('--lr', type=float, default=3e-4, help='Learning rate')
    parser.add_argument(
        '--arch',
        type=str,
        default='efficientnet_b0',
        choices=['efficientnet_b0', 'efficientnet_b1', 'efficientnet_b2', 'resnet18'],
        help='Model architecture'
    )
    parser.add_argument('--val-split', type=float, default=0.2, help='Validation split')
    parser.add_argument('--weight-decay', type=float, default=1e-4, help='Weight decay')
    parser.add_argument('--dropout', type=float, default=0.3, help='Dropout rate')
    parser.add_argument('--patience', type=int, default=10, help='Early stopping patience')
    parser.add_argument('--seed', type=int, default=42, help='Random seed')
    parser.add_argument('--freeze-epochs', type=int, default=5, help='Epochs with frozen backbone')
    parser.add_argument('--num-workers', type=int, default=0, help='DataLoader workers')
    parser.add_argument('--label-smoothing', type=float, default=0.1, help='Label smoothing')

    args = parser.parse_args()

    # Set seed
    set_seed(args.seed)

    # Device
    device = torch.device('cuda' if torch.cuda.is_available() else 'cpu')
    logger.info(f'Using device: {device}')

    # Resolve dataset directory
    script_dir = Path(__file__).parent
    dataset_dir = script_dir / args.dataset_dir
    if not dataset_dir.exists():
        dataset_dir = Path(args.dataset_dir)
    if not dataset_dir.exists():
        raise FileNotFoundError(f"Dataset directory not found: {dataset_dir}")

    logger.info(f'Dataset directory: {dataset_dir}')

    print("\n" + "="*70)
    print("TRAINING INDIAN KITCHEN HYGIENE DETECTION MODEL")
    print("Focus: Stove, Vessels, Cleanliness, Leftover Food")
    print("="*70 + "\n")

    # Load dataset
    train_transform = get_train_transforms()
    eval_transform = get_eval_transforms()

    base_dataset = HygieneImageFolder(dataset_dir)
    class_names = base_dataset.classes
    num_classes = len(class_names)

    if num_classes < 2:
        raise RuntimeError(f"Need at least 2 classes. Found: {class_names}")

    logger.info(f'Classes: {class_names}')

    # Split dataset
    train_indices, val_indices = stratified_split(
        base_dataset.targets,
        args.val_split,
        args.seed
    )
    logger.info(f'Train: {len(train_indices)} | Validation: {len(val_indices)}')

    # Create datasets
    train_dataset = HygieneImageFolder(dataset_dir, transform=train_transform)
    val_dataset = HygieneImageFolder(dataset_dir, transform=eval_transform)
    train_subset = Subset(train_dataset, train_indices)
    val_subset = Subset(val_dataset, val_indices)

    # Create dataloaders
    sampler = create_weighted_sampler(base_dataset.targets, train_indices)
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

    # Class weights
    class_weights = compute_class_weights(
        base_dataset.targets,
        train_indices,
        num_classes,
        device
    )
    logger.info(f'Class weights: {class_weights.tolist()}')

    # Build model
    model = build_model(num_classes, args.arch, args.dropout)
    model = model.to(device)

    # Freeze backbone initially
    if args.freeze_epochs > 0:
        freeze_backbone(model, args.arch, freeze=True)
        logger.info('Backbone frozen for initial training')

    # Loss and optimizer
    criterion = nn.CrossEntropyLoss(
        weight=class_weights,
        label_smoothing=args.label_smoothing
    )
    optimizer = torch.optim.AdamW(
        filter(lambda p: p.requires_grad, model.parameters()),
        lr=args.lr,
        weight_decay=args.weight_decay,
    )

    # Scheduler
    scheduler = CosineAnnealingWarmRestarts(
        optimizer,
        T_0=10,
        T_mult=2,
        eta_min=1e-6
    )

    # Training loop
    best_state = copy.deepcopy(model.state_dict())
    best_score = -1.0
    best_val_acc = 0.0
    best_epoch = 0
    stale_epochs = 0

    print("Starting training...\n")

    for epoch in range(args.epochs):
        # Unfreeze backbone after initial epochs
        if epoch == args.freeze_epochs and args.freeze_epochs > 0:
            freeze_backbone(model, args.arch, freeze=False)
            optimizer = torch.optim.AdamW(
                model.parameters(),
                lr=args.lr * 0.5,  # Lower LR for fine-tuning
                weight_decay=args.weight_decay,
            )
            scheduler = CosineAnnealingWarmRestarts(
                optimizer,
                T_0=10,
                T_mult=2,
                eta_min=1e-6
            )
            logger.info('Backbone unfrozen for fine-tuning')

        # Train
        train_loss, train_acc = train_epoch(
            model, train_loader, criterion, optimizer, device, epoch, args.epochs
        )

        # Validate
        val_metrics = evaluate(model, val_loader, criterion, device, class_names)
        val_loss = val_metrics['loss']
        val_acc = val_metrics['accuracy']
        selection_score = compute_selection_score(val_metrics, class_names)

        scheduler.step()

        # Logging
        unsafe_recall = val_metrics.get('shouldnt_work_recall', 0)
        review_recall = val_metrics.get('needs_work_recall', 0)
        safe_recall = val_metrics.get('meets_standard_recall', 0)

        logger.info(
            f'Epoch {epoch+1}/{args.epochs} | '
            f'Train: loss={train_loss:.4f} acc={train_acc*100:.2f}% | '
            f'Val: loss={val_loss:.4f} acc={val_acc*100:.2f}% | '
            f'Unsafe={unsafe_recall*100:.1f}% Review={review_recall*100:.1f}% Safe={safe_recall*100:.1f}% | '
            f'Score={selection_score:.4f}'
        )

        # Save best model
        if selection_score > best_score or (selection_score == best_score and val_acc > best_val_acc):
            best_score = selection_score
            best_val_acc = val_acc
            best_epoch = epoch + 1
            best_state = copy.deepcopy(model.state_dict())
            stale_epochs = 0
            logger.info(f'  -> New best model! Score={best_score:.4f}')
        else:
            stale_epochs += 1
            if stale_epochs >= args.patience:
                logger.info(f'Early stopping at epoch {epoch+1}')
                break

    # Load best model
    model.load_state_dict(best_state)

    # Final evaluation
    final_metrics = evaluate(model, val_loader, criterion, device, class_names)

    # Save checkpoint
    output_path = Path(args.output)
    output_path.parent.mkdir(parents=True, exist_ok=True)

    checkpoint = {
        'arch': args.arch,
        'model_state_dict': model.state_dict(),
        'class_to_idx': base_dataset.class_to_idx,
        'idx_to_class': {v: k for k, v in base_dataset.class_to_idx.items()},
        'class_names': class_names,
        'num_classes': num_classes,
        'image_size': IMAGE_SIZE,
        'best_val_acc': best_val_acc,
        'best_selection_score': best_score,
        'best_epoch': best_epoch,
        'train_size': len(train_indices),
        'val_size': len(val_indices),
        'issue_categories': ISSUE_CATEGORIES,
        'trained_at': datetime.now().isoformat(),
    }

    torch.save(checkpoint, output_path)
    logger.info(f'Model saved to: {output_path}')

    # Also save as the default model
    default_path = output_path.parent / 'hygiene_model.pth'
    torch.save(checkpoint, default_path)
    logger.info(f'Also saved to: {default_path}')

    # Save training report
    report = {
        'arch': args.arch,
        'best_val_acc': best_val_acc,
        'best_selection_score': best_score,
        'best_epoch': best_epoch,
        'classes': class_names,
        'train_size': len(train_indices),
        'val_size': len(val_indices),
        'final_metrics': {
            'accuracy': final_metrics['accuracy'],
            'loss': final_metrics['loss'],
        },
        'per_class_recall': {
            name: final_metrics.get(f'{name}_recall', 0.0)
            for name in class_names
        },
        'per_class_precision': {
            name: final_metrics.get(f'{name}_precision', 0.0)
            for name in class_names
        },
        'trained_at': datetime.now().isoformat(),
    }

    report_path = output_path.parent / 'training_report_indian_kitchen.json'
    report_path.write_text(json.dumps(report, indent=2))
    logger.info(f'Report saved to: {report_path}')

    # Print summary
    print("\n" + "="*70)
    print("TRAINING COMPLETE")
    print("="*70)
    print(f"Best Epoch: {best_epoch}")
    print(f"Best Validation Accuracy: {best_val_acc*100:.2f}%")
    print(f"Best Selection Score: {best_score:.4f}")
    print(f"\nPer-class Recall:")
    for name in class_names:
        recall = final_metrics.get(f'{name}_recall', 0)
        precision = final_metrics.get(f'{name}_precision', 0)
        print(f"  {name}: Recall={recall*100:.1f}% Precision={precision*100:.1f}%")
    print(f"\nModel saved to: {output_path}")
    print("="*70 + "\n")


if __name__ == '__main__':
    main()
