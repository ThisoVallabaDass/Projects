# Quick Start Guide - TinyTrails Enhanced Hygiene Service

## Your Service is Running! 🎉

Your enhanced hygiene service is now fully operational at: `http://localhost:9000`

## Testing with Real Images

### 1. Create Test Images Directory
```bash
mkdir test_images
```

### 2. Add Test Images
Place these files in the `test_images/` directory:
- `baseline1.jpg` to `baseline5.jpg` - Clean kitchen reference images
- `daily_test.jpg` - A test daily image

### 3. Run Full Tests
```bash
python test_api.py
```

## API Endpoints Ready

### Store Baseline Images
```bash
curl -X POST "http://localhost:9000/train-baseline" \
  -F "vendor_id=test_vendor_001" \
  -F "baseline_images=@test_images/baseline1.jpg" \
  -F "baseline_images=@test_images/baseline2.jpg" \
  -F "baseline_images=@test_images/baseline3.jpg" \
  -F "baseline_images=@test_images/baseline4.jpg" \
  -F "baseline_images=@test_images/baseline5.jpg"
```

### Verify Daily Image
```bash
curl -X POST "http://localhost:9000/verify-daily" \
  -F "vendor_id=test_vendor_001" \
  -F "daily_image=@test_images/daily_test.jpg"
```

## Flutter Integration

Your Flutter app can now make HTTP requests to:
- `POST /train-baseline` - Store vendor's 5 baseline images
- `POST /verify-daily` - Compare daily photo and get bounding boxes
- `GET /vendor/{id}/baselines` - Check vendor baseline status

The response includes:
```json
{
  "hygiene_score": 0.85,
  "passes_inspection": true,
  "bounding_boxes": [[x, y, w, h], ...],
  "feedback": ["[OK] Workspace appears clean..."]
}
```

## Key Features Working

✅ **Baseline Comparison**: Compares daily photos against stored clean references
✅ **Anomaly Detection**: Uses SSIM + computer vision to find differences
✅ **Bounding Box Detection**: Returns exact coordinates of dirty areas
✅ **Indian Kitchen Optimized**: Handles stainless steel, lighting variations
✅ **Multi-Vendor Support**: Each vendor has isolated baseline storage
✅ **Production Ready**: Error handling, logging, CORS support

## Advanced Training (Optional)

To train a specialized Siamese network for even better baseline comparison:
```bash
# Organize training data as described in train_baseline_comparison.py
python train_baseline_comparison.py --data-dir ./dataset --epochs 50
```

Your **TinyTrails AI Gatekeeper** is now ready for production! 🇮🇳