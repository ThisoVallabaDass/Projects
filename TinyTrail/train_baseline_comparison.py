"""
Enhanced Training Script for Baseline Comparison Model
Specifically designed for Indian Kitchen Hygiene Detection with Anomaly Detection

This script prepares and trains models for:
- Baseline image comparison
- Anomaly detection in Indian kitchen settings
- Feature extraction for similarity comparisons
"""

import argparse
import json
import logging
import os
import random
from pathlib import Path
from datetime import datetime
from typing import Dict, List, Tuple

import cv2
import numpy as np
import torch
import torch.nn as nn
import torchvision.models as models
from torch.optim.lr_scheduler import CosineAnnealingWarmRestarts
from torch.utils.data import DataLoader
from torchvision import transforms
from PIL import Image, ImageEnhance, ImageFilter
from skimage.metrics import structural_similarity as ssim
import albumentations as A
from albumentations.pytorch import ToTensorV2

# Setup logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s',
    handlers=[
        logging.StreamHandler(),
        logging.FileHandler('baseline_training.log', encoding='utf-8')
    ]
)
logger = logging.getLogger(__name__)

class IndianKitchenAugmentation:
    """Specialized augmentation for Indian kitchen environments"""

    def __init__(self, image_size: int = 224):
        # Augmentations that simulate Indian kitchen conditions
        self.transform = A.Compose([
            # Lighting variations (common in Indian kitchens)
            A.RandomBrightnessContrast(brightness_limit=0.3, contrast_limit=0.3, p=0.8),
            A.RandomGamma(gamma_limit=(80, 120), p=0.5),

            # Color variations (different lighting conditions)
            A.HueSaturationValue(hue_shift_limit=20, sat_shift_limit=30, val_shift_limit=20, p=0.7),

            # Simulate steam/moisture effects
            A.GaussianBlur(blur_limit=(3, 7), p=0.3),
            A.MotionBlur(blur_limit=7, p=0.2),

            # Geometric transformations (different camera angles)
            A.ShiftScaleRotate(shift_limit=0.1, scale_limit=0.2, rotate_limit=15, p=0.6),
            A.Perspective(scale=(0.05, 0.1), p=0.3),

            # Noise (sensor noise in mobile cameras)
            A.GaussNoise(var_limit=(10.0, 50.0), p=0.4),
            A.MultiplicativeNoise(multiplier=[0.9, 1.1], p=0.2),

            # Shadows and reflections (stainless steel surfaces)
            A.RandomShadow(shadow_roi=(0, 0.5, 1, 1), num_shadows_lower=1, num_shadows_upper=2, p=0.3),

            # Final resize and normalize
            A.Resize(image_size, image_size),
            A.Normalize(mean=[0.485, 0.456, 0.406], std=[0.229, 0.224, 0.225]),
            ToTensorV2()
        ])

    def __call__(self, image):
        if isinstance(image, Image.Image):
            image = np.array(image)
        return self.transform(image=image)['image']

class BaselineComparisonDataset(torch.utils.data.Dataset):
    """Dataset for training baseline comparison models"""

    def __init__(self, data_dir: Path, split: str = 'train', image_size: int = 224):
        self.data_dir = data_dir
        self.image_size = image_size
        self.split = split

        # Setup transforms
        if split == 'train':
            self.transform = IndianKitchenAugmentation(image_size)
        else:
            self.transform = A.Compose([
                A.Resize(image_size, image_size),
                A.Normalize(mean=[0.485, 0.456, 0.406], std=[0.229, 0.224, 0.225]),
                ToTensorV2()
            ])

        # Load image pairs and labels
        self.samples = self._load_samples()
        logger.info(f"Loaded {len(self.samples)} samples for {split}")

    def _load_samples(self) -> List[Tuple[str, str, int]]:
        """Load image pairs for comparison training"""
        samples = []

        # Expected structure:
        # dataset/
        #   ├── baseline_clean/     # Clean baseline images
        #   ├── clean/              # Similar clean images
        #   ├── dirty/              # Dirty images (different from baseline)
        #   └── moderate/           # Moderately dirty images

        baseline_dir = self.data_dir / "baseline_clean"
        clean_dir = self.data_dir / "clean"
        dirty_dir = self.data_dir / "dirty"
        moderate_dir = self.data_dir / "moderate"

        if not all(d.exists() for d in [baseline_dir, clean_dir, dirty_dir]):
            raise FileNotFoundError("Missing required directories. Please organize data as described.")

        # Get all baseline images
        baseline_images = list(baseline_dir.glob("*.jpg")) + list(baseline_dir.glob("*.png"))
        clean_images = list(clean_dir.glob("*.jpg")) + list(clean_dir.glob("*.png"))
        dirty_images = list(dirty_dir.glob("*.jpg")) + list(dirty_dir.glob("*.png"))
        moderate_images = list(moderate_dir.glob("*.jpg")) + list(moderate_dir.glob("*.png")) if moderate_dir.exists() else []

        # Create positive pairs (baseline vs clean = similar = label 1)
        for baseline_img in baseline_images:
            for clean_img in random.sample(clean_images, min(3, len(clean_images))):
                samples.append((str(baseline_img), str(clean_img), 1))

        # Create negative pairs (baseline vs dirty = different = label 0)
        for baseline_img in baseline_images:
            for dirty_img in random.sample(dirty_images, min(3, len(dirty_images))):
                samples.append((str(baseline_img), str(dirty_img), 0))

            # Add moderate as negative but with less weight
            for moderate_img in random.sample(moderate_images, min(2, len(moderate_images))):
                samples.append((str(baseline_img), str(moderate_img), 0))

        random.shuffle(samples)
        return samples

    def __len__(self):
        return len(self.samples)

    def __getitem__(self, idx):
        img1_path, img2_path, label = self.samples[idx]

        # Load images
        img1 = Image.open(img1_path).convert('RGB')
        img2 = Image.open(img2_path).convert('RGB')

        # Apply transforms
        img1 = self.transform(img1)
        img2 = self.transform(img2)

        return {
            'image1': img1,
            'image2': img2,
            'label': torch.tensor(label, dtype=torch.float32)
        }

class SiameseNetwork(nn.Module):
    """Siamese network for image comparison"""

    def __init__(self, backbone='resnet18', embedding_dim=128):
        super().__init__()

        if backbone == 'resnet18':
            self.backbone = models.resnet18(pretrained=True)
            feat_dim = self.backbone.fc.in_features
            self.backbone.fc = nn.Identity()
        elif backbone == 'efficientnet_b0':
            self.backbone = models.efficientnet_b0(pretrained=True)
            feat_dim = self.backbone.classifier[1].in_features
            self.backbone.classifier = nn.Identity()
        else:
            raise ValueError(f"Unknown backbone: {backbone}")

        # Projection head for embeddings
        self.projection = nn.Sequential(
            nn.Linear(feat_dim, 256),
            nn.ReLU(),
            nn.Dropout(0.3),
            nn.Linear(256, embedding_dim)
        )

        # Comparison head
        self.classifier = nn.Sequential(
            nn.Linear(embedding_dim * 2, 64),
            nn.ReLU(),
            nn.Dropout(0.3),
            nn.Linear(64, 32),
            nn.ReLU(),
            nn.Linear(32, 1),
            nn.Sigmoid()
        )

    def extract_features(self, x):
        """Extract features from backbone"""
        features = self.backbone(x)
        embedding = self.projection(features)
        return nn.functional.normalize(embedding, p=2, dim=1)

    def forward(self, img1, img2):
        """Forward pass for training"""
        emb1 = self.extract_features(img1)
        emb2 = self.extract_features(img2)

        # Combine embeddings
        combined = torch.cat([emb1, emb2], dim=1)
        similarity = self.classifier(combined)

        return similarity.squeeze(), emb1, emb2

def train_baseline_model(
    data_dir: Path,
    output_dir: Path,
    epochs: int = 50,
    batch_size: int = 16,
    learning_rate: float = 0.001,
    backbone: str = 'resnet18'
):
    """Train the baseline comparison model"""

    device = torch.device('cuda' if torch.cuda.is_available() else 'cpu')
    logger.info(f"Using device: {device}")

    # Create datasets
    train_dataset = BaselineComparisonDataset(data_dir, 'train')
    val_dataset = BaselineComparisonDataset(data_dir, 'val')

    train_loader = DataLoader(train_dataset, batch_size=batch_size, shuffle=True, num_workers=4)
    val_loader = DataLoader(val_dataset, batch_size=batch_size, shuffle=False, num_workers=4)

    # Create model
    model = SiameseNetwork(backbone=backbone)
    model.to(device)

    # Optimizer and scheduler
    optimizer = torch.optim.Adam(model.parameters(), lr=learning_rate, weight_decay=1e-4)
    scheduler = CosineAnnealingWarmRestarts(optimizer, T_0=10, T_mult=2)
    criterion = nn.BCELoss()

    # Training loop
    best_val_acc = 0.0
    train_history = []

    for epoch in range(epochs):
        # Training
        model.train()
        train_loss = 0.0
        train_correct = 0
        train_total = 0

        for batch in train_loader:
            img1 = batch['image1'].to(device)
            img2 = batch['image2'].to(device)
            labels = batch['label'].to(device)

            optimizer.zero_grad()

            similarity, _, _ = model(img1, img2)
            loss = criterion(similarity, labels)

            loss.backward()
            optimizer.step()

            train_loss += loss.item()
            predictions = (similarity > 0.5).float()
            train_correct += (predictions == labels).sum().item()
            train_total += labels.size(0)

        # Validation
        model.eval()
        val_loss = 0.0
        val_correct = 0
        val_total = 0

        with torch.no_grad():
            for batch in val_loader:
                img1 = batch['image1'].to(device)
                img2 = batch['image2'].to(device)
                labels = batch['label'].to(device)

                similarity, _, _ = model(img1, img2)
                loss = criterion(similarity, labels)

                val_loss += loss.item()
                predictions = (similarity > 0.5).float()
                val_correct += (predictions == labels).sum().item()
                val_total += labels.size(0)

        train_acc = train_correct / train_total
        val_acc = val_correct / val_total

        scheduler.step()

        logger.info(f"Epoch {epoch+1}/{epochs}")
        logger.info(f"Train Loss: {train_loss/len(train_loader):.4f}, Train Acc: {train_acc:.4f}")
        logger.info(f"Val Loss: {val_loss/len(val_loader):.4f}, Val Acc: {val_acc:.4f}")

        # Save best model
        if val_acc > best_val_acc:
            best_val_acc = val_acc
            torch.save({
                'model_state_dict': model.state_dict(),
                'backbone': backbone,
                'embedding_dim': 128,
                'val_accuracy': val_acc,
                'epoch': epoch
            }, output_dir / 'best_baseline_model.pth')

        train_history.append({
            'epoch': epoch,
            'train_loss': train_loss/len(train_loader),
            'train_acc': train_acc,
            'val_loss': val_loss/len(val_loader),
            'val_acc': val_acc
        })

    # Save training history
    with open(output_dir / 'training_history.json', 'w') as f:
        json.dump(train_history, f, indent=2)

    logger.info(f"Training complete! Best validation accuracy: {best_val_acc:.4f}")
    return model

def main():
    parser = argparse.ArgumentParser(description='Train baseline comparison model for Indian kitchens')
    parser.add_argument('--data-dir', type=str, required=True, help='Path to dataset directory')
    parser.add_argument('--output-dir', type=str, default='./models', help='Output directory for models')
    parser.add_argument('--epochs', type=int, default=50, help='Number of training epochs')
    parser.add_argument('--batch-size', type=int, default=16, help='Batch size')
    parser.add_argument('--lr', type=float, default=0.001, help='Learning rate')
    parser.add_argument('--backbone', type=str, default='resnet18', choices=['resnet18', 'efficientnet_b0'])

    args = parser.parse_args()

    data_dir = Path(args.data_dir)
    output_dir = Path(args.output_dir)
    output_dir.mkdir(exist_ok=True)

    # Train model
    train_baseline_model(
        data_dir=data_dir,
        output_dir=output_dir,
        epochs=args.epochs,
        batch_size=args.batch_size,
        learning_rate=args.lr,
        backbone=args.backbone
    )

if __name__ == '__main__':
    main()