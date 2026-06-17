#!/usr/bin/env python3
"""
TinyTrails Dataset Preparation Helper
======================================
Helps prepare your existing classification images for YOLO object detection annotation.

This script:
1. Copies images from your classification folders to YOLO structure
2. Creates empty label files as placeholders
3. Provides instructions for annotation

Usage:
    python prepare_yolo_dataset.py                    # Prepare dataset
    python prepare_yolo_dataset.py --val-split 0.2    # 20% validation split
    python prepare_yolo_dataset.py --dry-run          # Preview without copying
"""

import argparse
import random
import shutil
from pathlib import Path


# =============================================================================
# CONFIGURATION
# =============================================================================

BASE_DIR = Path(__file__).resolve().parent
SOURCE_DATASET = BASE_DIR / "AI_Hygiene_Model" / "dataset"
YOLO_DATASET = BASE_DIR / "yolo_dataset"

# Class mapping for annotation reference
CLASS_MAPPING = """
================================================================================
ANNOTATION CLASS REFERENCE
================================================================================
When annotating with LabelImg/CVAT/Roboflow, use these class IDs:

  0: spill           - Liquid spills on surfaces
  1: dirty_utensil   - Unwashed pots, pans, plates, utensils
  2: food_waste      - Food scraps, leftovers, peels on surfaces
  3: grease_buildup  - Grease accumulation on stove, surfaces
  4: dirty_surface   - General dirt, stains on counters/tables
  5: pest_evidence   - Droppings, insects, rodent signs

ANNOTATION TIPS FOR INDIAN KITCHENS:
- Draw tight boxes around specific issues, not the entire scene
- Include some context (e.g., the spill + a bit of surrounding surface)
- For stainless steel surfaces, focus on actual dirt, not reflections
- Mark obvious issues - don't overthink edge cases

================================================================================
"""


def get_image_extensions():
    """Returns common image file extensions."""
    return {".jpg", ".jpeg", ".png", ".bmp", ".webp"}


def collect_source_images() -> list[Path]:
    """Collect all images from classification folders."""
    images = []
    extensions = get_image_extensions()

    if not SOURCE_DATASET.exists():
        print(f"WARNING: Source dataset not found at {SOURCE_DATASET}")
        return images

    for category in ["needs_work", "shouldnt_work", "meets_standard"]:
        category_dir = SOURCE_DATASET / category
        if category_dir.exists():
            for img_path in category_dir.iterdir():
                if img_path.suffix.lower() in extensions:
                    images.append(img_path)

    return images


def prepare_dataset(val_split: float = 0.2, seed: int = 42, dry_run: bool = False):
    """Prepare YOLO dataset structure from classification images."""

    print("\n" + "=" * 60)
    print("TINYTRAILS DATASET PREPARATION")
    print("=" * 60)

    # Collect images
    images = collect_source_images()
    if not images:
        print("\nNo source images found!")
        print(f"Expected images in: {SOURCE_DATASET}")
        print("Please add images to the classification folders first.")
        return

    print(f"\nFound {len(images)} images in classification dataset")

    # Shuffle and split
    random.seed(seed)
    random.shuffle(images)

    val_count = max(1, int(len(images) * val_split))
    train_count = len(images) - val_count

    val_images = images[:val_count]
    train_images = images[val_count:]

    print(f"  Training:   {train_count} images")
    print(f"  Validation: {val_count} images")

    if dry_run:
        print("\n[DRY RUN] Would create the following structure:")
        print(f"  {YOLO_DATASET}/images/train/  ({train_count} images)")
        print(f"  {YOLO_DATASET}/images/val/    ({val_count} images)")
        print(f"  {YOLO_DATASET}/labels/train/  ({train_count} label files)")
        print(f"  {YOLO_DATASET}/labels/val/    ({val_count} label files)")
        return

    # Create directories
    (YOLO_DATASET / "images" / "train").mkdir(parents=True, exist_ok=True)
    (YOLO_DATASET / "images" / "val").mkdir(parents=True, exist_ok=True)
    (YOLO_DATASET / "labels" / "train").mkdir(parents=True, exist_ok=True)
    (YOLO_DATASET / "labels" / "val").mkdir(parents=True, exist_ok=True)

    # Copy training images
    print("\nCopying training images...")
    for i, img_path in enumerate(train_images):
        # Create unique name to avoid collisions
        new_name = f"train_{i:04d}{img_path.suffix.lower()}"
        dest_img = YOLO_DATASET / "images" / "train" / new_name
        dest_lbl = YOLO_DATASET / "labels" / "train" / f"train_{i:04d}.txt"

        shutil.copy(img_path, dest_img)
        # Create empty label file (to be filled during annotation)
        dest_lbl.touch()

    # Copy validation images
    print("Copying validation images...")
    for i, img_path in enumerate(val_images):
        new_name = f"val_{i:04d}{img_path.suffix.lower()}"
        dest_img = YOLO_DATASET / "images" / "val" / new_name
        dest_lbl = YOLO_DATASET / "labels" / "val" / f"val_{i:04d}.txt"

        shutil.copy(img_path, dest_img)
        dest_lbl.touch()

    print("\n" + "=" * 60)
    print("DATASET PREPARED SUCCESSFULLY!")
    print("=" * 60)

    print(f"\nDataset location: {YOLO_DATASET}")
    print(CLASS_MAPPING)

    print("""
NEXT STEPS:
===========

1. INSTALL LABELIMG (Recommended for Windows):
   pip install labelImg
   labelImg

   - Open Dir: Select yolo_dataset/images/train
   - Change Save Dir: yolo_dataset/labels/train
   - Change format to YOLO (View menu)
   - Draw boxes and assign class IDs (0-5)
   - Repeat for validation set

2. ALTERNATIVE - USE ROBOFLOW (Web-based):
   - Upload images to roboflow.com
   - Annotate online
   - Export in "YOLOv8" format
   - Download and replace yolo_dataset folder

3. AFTER ANNOTATION:
   - Verify label files have content (not empty)
   - Run: python train_yolo.py

LABEL FILE FORMAT (one line per object):
<class_id> <x_center> <y_center> <width> <height>

Example train_0000.txt (two detections):
0 0.45 0.62 0.12 0.08
1 0.78 0.34 0.15 0.20
""")


def main():
    parser = argparse.ArgumentParser(
        description="Prepare YOLO dataset from classification images"
    )
    parser.add_argument(
        "--val-split", type=float, default=0.2,
        help="Validation split ratio (default: 0.2)"
    )
    parser.add_argument(
        "--seed", type=int, default=42,
        help="Random seed for reproducibility"
    )
    parser.add_argument(
        "--dry-run", action="store_true",
        help="Preview changes without copying files"
    )

    args = parser.parse_args()
    prepare_dataset(val_split=args.val_split, seed=args.seed, dry_run=args.dry_run)


if __name__ == "__main__":
    main()
