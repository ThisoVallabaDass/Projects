# TinyTrails Enhanced Hygiene System - Setup Guide

## Installation & Setup

### 1. Install Dependencies
```bash
cd t:/College/Project/TinyTrail
pip install -r requirements_enhanced.txt
```

### 2. Dataset Organization
Create your training dataset with this structure:
```
dataset/
├── baseline_clean/     # Clean reference images (5-10 per kitchen type)
├── clean/              # Additional clean images
├── dirty/              # Dirty/problematic images
└── moderate/           # Moderately dirty (optional)
```

### 3. Train the Enhanced Model (Optional)
If you want to train a new baseline comparison model:
```bash
python train_baseline_comparison.py --data-dir ./dataset --epochs 50 --batch-size 16
```

### 4. Start the Enhanced Service
```bash
cd hygiene_service
python app_enhanced.py
```

## API Endpoints

### Store Vendor Baselines
```
POST /train-baseline
Content-Type: multipart/form-data

vendor_id: "vendor123"
baseline_images: [file1.jpg, file2.jpg, file3.jpg, file4.jpg, file5.jpg]
```

### Daily Verification
```
POST /verify-daily
Content-Type: multipart/form-data

vendor_id: "vendor123"
daily_image: daily_photo.jpg

Response:
{
  "vendor_id": "vendor123",
  "hygiene_score": 0.85,
  "passes_inspection": true,
  "bounding_boxes": [[x, y, w, h], ...],
  "num_anomalies": 1,
  "feedback": ["✅ Workspace appears clean..."]
}
```

## Flutter Integration

The response includes `bounding_boxes` as coordinates you can use to draw red rectangles:
- `[x, y, w, h]` format
- Coordinates are in the resized image space (512x512)
- Scale them to your Flutter image widget size

## What This System Does

1. **Baseline Storage**: Stores 5 clean reference images per vendor
2. **Anomaly Detection**: Uses SSIM and computer vision to find differences
3. **Bounding Boxes**: Returns exact coordinates of dirty areas
4. **Smart Scoring**: Combines multiple methods for accurate results
5. **Indian Kitchen Optimized**: Handles stainless steel, lighting variations, compact spaces