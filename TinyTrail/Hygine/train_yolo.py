#!/usr/bin/env python3
"""
TinyTrails YOLOv8 Hygiene Anomaly Detection Training Script
============================================================
Trains a custom YOLOv8 model to detect hygiene issues in Indian kitchens/street food karts.

Usage:
    python train_yolo.py                    # Train with defaults
    python train_yolo.py --epochs 150       # Custom epochs
    python train_yolo.py --device cuda:0    # Use specific GPU

Output:
    Best weights saved to: hygiene_service/weights/hygiene_yolov8_best.pt
"""

import argparse
import shutil
from pathlib import Path


# =============================================================================
# CONFIGURATION
# =============================================================================

BASE_DIR = Path(__file__).resolve().parent
DATASET_DIR = BASE_DIR / "yolo_dataset"
DATA_YAML = DATASET_DIR / "data.yaml"

# Output directories
OUTPUT_DIR = BASE_DIR.parent / "hygiene_service" / "weights"
RUNS_DIR = BASE_DIR / "runs"

# Local pretrained weights directory (for offline use)
WEIGHTS_DIR = BASE_DIR / "pretrained_weights"
YOLO_WEIGHTS_URL = "https://github.com/ultralytics/assets/releases/download/v8.3.0/yolov8n.pt"

# Default training parameters optimized for Indian kitchen scenarios
DEFAULT_CONFIG = {
    "epochs": 100,
    "imgsz": 640,                 # Standard YOLO input size
    "batch": 16,                  # Reduce if OOM errors occur
    "patience": 20,               # Early stopping patience
    "device": "",                 # Auto-detect (cuda if available, else cpu)
    "workers": 4,                 # DataLoader workers (reduce on Windows if issues)
    "project": str(RUNS_DIR),
    "name": "hygiene_detector",
    "exist_ok": True,
    "pretrained": True,
    "optimizer": "AdamW",
    "lr0": 0.01,                  # Initial learning rate
    "lrf": 0.01,                  # Final learning rate factor
    "momentum": 0.937,
    "weight_decay": 0.0005,
    "warmup_epochs": 3.0,
    "warmup_momentum": 0.8,
    "box": 7.5,                   # Box loss gain
    "cls": 0.5,                   # Classification loss gain
    "dfl": 1.5,                   # Distribution focal loss gain

    # =======================================================================
    # DATA AUGMENTATION (Critical for Indian kitchen variability)
    # =======================================================================
    # These simulate real-world mobile phone camera conditions:
    # - Variable lighting (dim kitchens, harsh sunlight on street karts)
    # - Motion blur from shaky hands
    # - Different angles and distances

    "hsv_h": 0.015,               # HSV-Hue augmentation (fraction)
    "hsv_s": 0.7,                 # HSV-Saturation augmentation
    "hsv_v": 0.4,                 # HSV-Value (brightness) augmentation
    "degrees": 10.0,              # Rotation (+/- degrees)
    "translate": 0.1,             # Translation (+/- fraction)
    "scale": 0.5,                 # Scale (+/- gain)
    "shear": 5.0,                 # Shear (+/- degrees)
    "perspective": 0.0005,        # Perspective transform
    "flipud": 0.0,                # Vertical flip probability (0 for kitchen scenes)
    "fliplr": 0.5,                # Horizontal flip probability
    "mosaic": 1.0,                # Mosaic augmentation probability
    "mixup": 0.1,                 # MixUp augmentation probability
    "copy_paste": 0.1,            # Copy-paste augmentation probability
    "auto_augment": "randaugment", # Auto augmentation policy
    "erasing": 0.4,               # Random erasing probability
    "crop_fraction": 1.0,         # Image crop fraction for classification
}


def validate_dataset():
    """Check dataset structure and provide helpful feedback."""
    print("\n" + "=" * 60)
    print("DATASET VALIDATION")
    print("=" * 60)

    if not DATA_YAML.exists():
        raise FileNotFoundError(f"data.yaml not found at {DATA_YAML}")

    train_images = DATASET_DIR / "images" / "train"
    val_images = DATASET_DIR / "images" / "val"
    train_labels = DATASET_DIR / "labels" / "train"
    val_labels = DATASET_DIR / "labels" / "val"

    train_img_count = len(list(train_images.glob("*.[jJ][pP][gG]")) +
                         list(train_images.glob("*.[jJ][pP][eE][gG]")) +
                         list(train_images.glob("*.[pP][nN][gG]")))
    val_img_count = len(list(val_images.glob("*.[jJ][pP][gG]")) +
                       list(val_images.glob("*.[jJ][pP][eE][gG]")) +
                       list(val_images.glob("*.[pP][nN][gG]")))
    train_lbl_count = len(list(train_labels.glob("*.txt")))
    val_lbl_count = len(list(val_labels.glob("*.txt")))

    print(f"Training images:     {train_img_count}")
    print(f"Training labels:     {train_lbl_count}")
    print(f"Validation images:   {val_img_count}")
    print(f"Validation labels:   {val_lbl_count}")

    if train_img_count == 0:
        print("\n" + "!" * 60)
        print("WARNING: No training images found!")
        print("!" * 60)
        print("""
To prepare your dataset:

1. ANNOTATE YOUR IMAGES using one of these tools:
   - LabelImg (desktop): https://github.com/HumanSignal/labelImg
   - CVAT (web-based):   https://cvat.ai
   - Roboflow (cloud):   https://roboflow.com

2. EXPORT in YOLO format (class_id x_center y_center width height)
   Each .txt label file corresponds to an image with same base name.

3. ORGANIZE files:
   yolo_dataset/
   +-- images/
   |   +-- train/    <- 80% of your annotated images
   |   +-- val/      <- 20% of your annotated images
   +-- labels/
       +-- train/    <- Matching .txt files for train images
       +-- val/      <- Matching .txt files for val images

4. LABEL FORMAT (normalized 0-1 coordinates):
   <class_id> <x_center> <y_center> <width> <height>

   Example (spill at center covering 20% of image):
   0 0.5 0.5 0.2 0.2

5. CLASS IDs:
   0: spill
   1: dirty_utensil
   2: food_waste
   3: grease_buildup
   4: dirty_surface
   5: pest_evidence
""")
        return False

    if train_img_count != train_lbl_count:
        print(f"\nWARNING: Mismatch between images ({train_img_count}) and labels ({train_lbl_count})")
        print("Each image needs a corresponding .txt label file with the same name.")

    print("\nDataset validation passed!")
    return True


def download_weights():
    """Download pretrained weights with better error handling."""
    import urllib.request
    import ssl

    WEIGHTS_DIR.mkdir(parents=True, exist_ok=True)
    local_weights = WEIGHTS_DIR / "yolov8n.pt"

    if local_weights.exists():
        print(f"Using cached weights: {local_weights}")
        return str(local_weights)

    print(f"\nDownloading YOLOv8n pretrained weights...")
    print(f"URL: {YOLO_WEIGHTS_URL}")
    print(f"Destination: {local_weights}")

    try:
        # Create SSL context that doesn't verify (for corporate proxies)
        ctx = ssl.create_default_context()
        ctx.check_hostname = False
        ctx.verify_mode = ssl.CERT_NONE

        with urllib.request.urlopen(YOLO_WEIGHTS_URL, timeout=60, context=ctx) as response:
            with open(local_weights, 'wb') as f:
                f.write(response.read())
        print("Download complete!")
        return str(local_weights)

    except Exception as e:
        print(f"\nFailed to download weights: {e}")
        print("\n" + "=" * 60)
        print("MANUAL DOWNLOAD REQUIRED (You appear to be offline)")
        print("=" * 60)
        print(f"""
1. Download the weights file manually from:
   {YOLO_WEIGHTS_URL}

2. Save it to:
   {local_weights}

3. Re-run this script.

ALTERNATIVE: If you have internet access on another machine:
   - Download yolov8n.pt from the URL above
   - Copy it to: {WEIGHTS_DIR}
""")
        return None


def train(args):
    """Run the YOLOv8 training loop."""
    # Import here to catch import errors early with helpful message
    try:
        from ultralytics import YOLO
    except ImportError:
        print("\nERROR: ultralytics package not installed!")
        print("Run: pip install ultralytics")
        return None

    print("\n" + "=" * 60)
    print("TINYTRAILS HYGIENE DETECTOR TRAINING")
    print("=" * 60)

    # Merge CLI args with defaults
    config = DEFAULT_CONFIG.copy()
    if args.epochs:
        config["epochs"] = args.epochs
    if args.batch:
        config["batch"] = args.batch
    if args.device:
        config["device"] = args.device
    if args.imgsz:
        config["imgsz"] = args.imgsz

    model_name = args.model if args.model else "yolov8n.pt"

    # Check if we need to handle offline mode for default weights
    if model_name == "yolov8n.pt":
        local_weights = WEIGHTS_DIR / "yolov8n.pt"
        if local_weights.exists():
            model_name = str(local_weights)
            print(f"  Using local weights: {model_name}")
        else:
            # Try to download
            downloaded = download_weights()
            if downloaded:
                model_name = downloaded
            else:
                print("\nCannot proceed without pretrained weights.")
                return None

    print(f"\nConfiguration:")
    print(f"  Base model:    {model_name}")
    print(f"  Epochs:        {config['epochs']}")
    print(f"  Batch size:    {config['batch']}")
    print(f"  Image size:    {config['imgsz']}")
    print(f"  Device:        {config['device'] or 'auto'}")
    print(f"  Dataset:       {DATA_YAML}")

    # Initialize model
    model = YOLO(model_name)

    # Train
    print("\nStarting training...")
    results = model.train(
        data=str(DATA_YAML),
        **config
    )

    # Copy best weights to hygiene_service
    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
    best_weights = RUNS_DIR / "hygiene_detector" / "weights" / "best.pt"
    dest_path = OUTPUT_DIR / "hygiene_yolov8_best.pt"

    if best_weights.exists():
        shutil.copy(best_weights, dest_path)
        print(f"\nBest weights saved to: {dest_path}")
    else:
        print(f"\nWARNING: Could not find best.pt at {best_weights}")

    # Also copy last weights as backup
    last_weights = RUNS_DIR / "hygiene_detector" / "weights" / "last.pt"
    if last_weights.exists():
        shutil.copy(last_weights, OUTPUT_DIR / "hygiene_yolov8_last.pt")

    print("\n" + "=" * 60)
    print("TRAINING COMPLETE")
    print("=" * 60)
    print(f"\nResults saved to: {RUNS_DIR / 'hygiene_detector'}")
    print(f"Production weights: {dest_path}")

    return results


def main():
    parser = argparse.ArgumentParser(
        description="Train YOLOv8 hygiene anomaly detector for TinyTrails"
    )
    parser.add_argument(
        "--epochs", type=int, default=None,
        help="Number of training epochs (default: 100)"
    )
    parser.add_argument(
        "--batch", type=int, default=None,
        help="Batch size (default: 16, reduce if OOM)"
    )
    parser.add_argument(
        "--device", type=str, default=None,
        help="Device to use: 'cpu', 'cuda', 'cuda:0', etc. (default: auto)"
    )
    parser.add_argument(
        "--imgsz", type=int, default=None,
        help="Image size for training (default: 640)"
    )
    parser.add_argument(
        "--model", type=str, default=None,
        help="Base model: yolov8n.pt, yolov8s.pt, yolov8m.pt (default: yolov8n.pt)"
    )
    parser.add_argument(
        "--skip-validation", action="store_true",
        help="Skip dataset validation check"
    )
    parser.add_argument(
        "--download-weights", action="store_true",
        help="Only download pretrained weights (for offline preparation)"
    )

    args = parser.parse_args()

    # Download-only mode
    if args.download_weights:
        print("Downloading pretrained weights...")
        result = download_weights()
        if result:
            print(f"\nWeights ready at: {result}")
            print("You can now run training offline.")
        return

    # Validate dataset unless skipped
    if not args.skip_validation:
        if not validate_dataset():
            print("\nRun with --skip-validation to train anyway (not recommended)")
            return

    # Run training
    train(args)


if __name__ == "__main__":
    main()
