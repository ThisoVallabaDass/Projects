# 🚀 QUICK START: INDIAN KITCHEN MODEL IMPROVEMENT

## ONE-LINE COMMANDS - Copy & Paste

### Phase 1: Data Collection (Do 3-5 times)
```bash
python scrape_images_indian_kitchens.py && python deduplicate_dataset.py && python clean_dataset.py --filter-irrelevant && python stats_dataset.py
```

### Phase 2: Training
```bash
python train_enhanced.py --epochs 30 --batch-size 32 --arch efficientnet_b0 --lr 0.0005 && python evaluate.py
```

### Phase 3: Verify
```bash
python predict.py path/to/test_image.jpg
```

---

## KEY NUMBERS TO REMEMBER

✅ **Target Dataset Size**: 15GB+  
✅ **Target Accuracy**: 95%+  
✅ **Target False Negatives (shouldnt_work)**: <2%  
✅ **Training Epochs**: 30  
✅ **Learning Rate**: 0.0005  
✅ **Batch Size**: 32  
✅ **Model Architecture**: EfficientNet-B0  

---

## FILES YOU NEED

### NEW FILES (Use These)
- `scrape_images_indian_kitchens.py` - Download images
- `deduplicate_dataset.py` - Remove duplicates
- `train_enhanced.py` - Train model
- `IMPROVEMENT_GUIDE.md` - Full documentation

### EXISTING FILES (No Changes)
- `predict.py` - Prediction (works as-is)
- `api_predict.py` - API (works as-is)
- `evaluate.py` - Enhanced metrics
- `config.yaml` - Updated params

---

## EXPECTED RESULTS

| Step | Time | Output |
|------|------|--------|
| Scraping (1 run) | 4-6 hours | +5,000-10,000 images |
| Deduplication | 30 mins | Removes 10-20% duplicates |
| Cleaning | 1 hour | Removes corrupted images |
| Training | 3-4 hours | New model file (~50-100 MB) |
| Evaluation | 30 mins | Accuracy metrics |

---

## SAFETY CHECKS ✅

Before Deployment:
```bash
# 1. Model file exists and is reasonable size
ls -lh models/hygiene_model.pth  # Should be 50-100 MB

# 2. Classes are correct
python -c "import torch; cp = torch.load('models/hygiene_model.pth'); print(cp['idx_to_class'])"
# Should output: {0: 'meets_standard', 1: 'needs_work', 2: 'shouldnt_work'}

# 3. Prediction works
python predict.py any_image.jpg  # Should return one of 3 classes

# 4. Accuracy is good
python evaluate.py  # Should show >90% accuracy
```

---

## IN CASE OF PROBLEMS

**Out of Memory**: Reduce batch size
```bash
python train_enhanced.py --batch-size 16
```

**Dataset Too Small**: Run scraper again
```bash
python scrape_images_indian_kitchens.py
```

**Low Accuracy**: Train longer
```bash
python train_enhanced.py --epochs 50 --patience 10
```

**Model Doesn't Load**: Delete and retrain
```bash
rm models/hygiene_model.pth
python train_enhanced.py
```

---

## WHAT'S COMPATIBLE ✅

Everything works with the existing app:
- ✅ Same output classes
- ✅ Same API
- ✅ Same file path (`models/hygiene_model.pth`)
- ✅ Same prediction format
- ✅ NO code changes in application

Just replace the model file and you're done!

---

## TIMELINE

```
Week 1: Data Collection (Run scraper 3-5 times in parallel/background)
Week 2: Data Cleaning & Stats
Week 3: Training your model
Day 1:  Evaluation & verification
        ↓
        DEPLOY! (Just swap the .pth file)
```

---

## CONTACT NOTES

**Class Names**: MUST BE EXACTLY
- `meets_standard` (clean, safe)
- `needs_work` (moderate issues)
- `shouldnt_work` (unsafe, do not operate)

**DO NOT CHANGE** - These are hard-coded in the application!

---

Generated: March 2026 | Focus: Indian Kitchens | Compatibility: 100%
