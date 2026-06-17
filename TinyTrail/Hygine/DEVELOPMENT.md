# Development Guide

## Quick Reference

### Setup Development Environment

```bash
# Create virtual environment
python -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate

# Install dependencies
pip install -r requirements.txt

# Optional: Install development tools
pip install black pylint pytest jupyter
```

### Project Commands

```bash
# Scrape images
python scrape_images.py

# Clean dataset
python clean_dataset.py --min-size 128 --filter-irrelevant

# View statistics
python stats_dataset.py

# Train model
python train.py --epochs 10 --batch-size 32 --lr 0.001 --arch resnet18

# Make prediction
python predict.py image.jpg --model-path models/hygiene_model.pth

# Evaluate model
python evaluate.py --batch-size 32

# View logs
tail -f hygiene_training.log
```

---

## Common Tasks

### 1. Training with Different Hyperparameters

```bash
# Longer training
python train.py --epochs 30 --batch-size 16 --lr 0.0005

# Faster training (less accurate)
python train.py --epochs 5 --batch-size 64 --lr 0.01

# Using EfficientNet (more accurate, slower)
python train.py --arch efficientnet_b0 --epochs 20
```

### 2. Data Management

```bash
# Count images per class
python stats_dataset.py

# Clean with stricter filtering
python clean_dataset.py --min-size 256 --filter-irrelevant --topk 10

# Move corrupted images to review folder (default)
python clean_dataset.py --min-size 128

# Delete corrupted images directly
python clean_dataset.py --delete
```

### 3. Model Evaluation

```bash
# Full evaluation with confusion matrix
python evaluate.py

# Fast evaluation (small batch)
python evaluate.py --batch-size 8

# On custom dataset
python evaluate.py --dataset-dir path/to/test_data

# Save results to file
python evaluate.py > evaluation_results.txt 2>&1
```

### 4. Batch Prediction

```bash
# Single image
python predict.py test_kitchen.jpg

# Process multiple images manually
for img in test_images/*.jpg; do
    python predict.py "$img"
done
```

---

## Code Organization

### File Structure

```
project/
├── train.py              # Training script
├── predict.py            # Single prediction
├── evaluate.py           # Model evaluation
├── clean_dataset.py      # Data cleaning
├── stats_dataset.py      # Data statistics
├── scrape_images.py      # Web scraping
├── move_dataset.py       # Utility (legacy)
├── utils.py              # Shared functions
├── config.yaml           # Configuration
├── requirements.txt      # Dependencies
├── .gitignore           # Git rules
├── README.md            # Main docs
├── CONTRIBUTING.md      # Dev guide
├── IMPROVEMENTS.md      # Changes made
├── DEVELOPMENT.md       # This file
│
├── AI_Hygiene_Model/
│   ├── dataset/
│   │   ├── meets_standard/
│   │   ├── needs_work/
│   │   ├── shouldnt_work/
│   │   └── _removed_irrelevant/
│   ├── models/
│   └── notebooks/
│
├── models/
│   └── hygiene_model.pth  # Trained model
│
├── logs/
│   └── hygiene_training.log  # Training log
└── .git/                # Version control
```

---

## Adding Features

### 1. Adding a New Script

Create a new file following this template:

```python
"""Brief description of what the script does."""

import logging
from pathlib import Path

from utils import resolve_dataset_dir, setup_logging

logger = logging.getLogger(__name__)


def main() -> None:
    """Main entry point."""
    setup_logging()
    
    # Your code here
    logger.info("Task completed successfully")


if __name__ == "__main__":
    try:
        main()
    except Exception as exc:
        logger.error(f"Task failed: {exc}", exc_info=True)
        raise
```

### 2. Adding a New Utility Function

Add to `utils.py`:

```python
def my_function(param: str) -> int:
    """
    Brief description.
    
    Args:
        param: Parameter description
        
    Returns:
        Return value description
    """
    logger.info(f"Processing: {param}")
    result = len(param)
    return result
```

### 3. Adding Configuration

Add to `config.yaml`:

```yaml
new_section:
  param1: value1
  param2: value2
```

Access in code:

```python
import yaml

with open("config.yaml") as f:
    config = yaml.safe_load(f)
    value = config["new_section"]["param1"]
```

---

## Debugging

### 1. Enable Debug Logging

```python
# In your script
setup_logging(level=logging.DEBUG)
```

Or set environment variable:

```bash
export LOGLEVEL=DEBUG
python train.py
```

### 2. Check Logs

```bash
# View recent logs
tail -20 hygiene_training.log

# Search for errors
grep ERROR hygiene_training.log

# Full log analysis
cat hygiene_training.log | grep "Epoch"
```

### 3. Common Issues

**"No images found in dataset"**
- Check dataset directory path
- Verify subdirectories exist: meets_standard/, needs_work/, shouldnt_work/
- Confirm images have correct extensions (.jpg, .png, etc.)

**OutOfMemoryError**
- Reduce batch size: `--batch-size 16`
- Use ResNet18 instead of EfficientNet
- Use CPU instead of GPU: Set `CUDA_VISIBLE_DEVICES=""`

**Low accuracy**
- Increase dataset size
- Longer training: `--epochs 30`
- Lower learning rate: `--lr 0.0001`
- More augmentation

---

## Testing

### 1. Test Data Pipeline

```bash
# Create small test dataset
mkdir -p test_data/meets_standard test_data/needs_work test_data/shouldnt_work

# Copy a few images
cp dataset/meets_standard/*.jpg test_data/meets_standard/ --max=3
cp dataset/needs_work/*.jpg test_data/needs_work/ --max=3
cp dataset/shouldnt_work/*.jpg test_data/shouldnt_work/ --max=3

# Test cleaning
python clean_dataset.py --dataset-dir test_data --min-size 64

# Test training
python train.py --dataset-dir test_data --epochs 1

# Test evaluation
python evaluate.py --dataset-dir test_data
```

### 2. Single Image Test

```bash
# Test prediction
python predict.py test_data/meets_standard/image.jpg

# Verify output format
python predict.py test_data/needs_work/image.jpg 2>&1 | grep "Prediction:"
```

---

## Performance Tips

### 1. Faster Training

```bash
# GPU acceleration
python train.py --num-workers 4  # Parallel data loading

# Faster model
python train.py --arch resnet18  # vs efficientnet_b0

# Fewer epochs during development
python train.py --epochs 3
```

### 2. Better Accuracy

```bash
# Larger dataset
# Smaller learning rate
python train.py --lr 0.0001 --epochs 50

# Larger batch size (if VRAM allows)
python train.py --batch-size 64

# Larger images (modify config.yaml)
```

### 3. Memory Efficient

```bash
# Reduce batch size
python train.py --batch-size 8

# Reduce workers
python train.py --num-workers 0

# Use CPU
CUDA_VISIBLE_DEVICES="" python train.py
```

---

## Version Control

### Basic Git Workflow

```bash
# Check status
git status

# Commit changes
git add .
git commit -m "Describe what you changed"

# View log
git log --oneline

# Create branch for features
git checkout -b feature/new-feature
```

### What to Commit

✅ DO commit:
- Python source files
- Configuration files
- Documentation

❌ DON'T commit:
- Model files (*.pth) - they're too large
- Dataset images
- Cache files (__pycache__)
- Virtual environment

---

## Troubleshooting

### Issue: Module not found errors

```bash
# Ensure utils.py is in same directory
ls -la utils.py

# Check PYTHONPATH
export PYTHONPATH="${PYTHONPATH}:$(pwd)"
```

### Issue: Logging not showing

```python
# Ensure setup_logging() is called first
import logging
from utils import setup_logging

def main():
    setup_logging()  # Call this first!
    logger = logging.getLogger(__name__)
    logger.info("Now logging works")
```

### Issue: GPU not being used

```bash
# Check CUDA availability
python -c "import torch; print(torch.cuda.is_available())"

# Force CPU
CUDA_VISIBLE_DEVICES="" python train.py

# Check GPU memory
nvidia-smi  # Requires NVIDIA GPU
```

---

## Resources

- PyTorch: https://pytorch.org/docs
- TorchVision: https://pytorch.org/vision
- Python Type Hints: https://docs.python.org/3/library/typing.html
- Google Python Style Guide: https://google.github.io/styleguide/pyguide.html

---

## Getting Help

1. Check error logs: `tail -50 hygiene_training.log`
2. Review README.md troubleshooting section
3. Check function docstrings: `python -c "from predict import load_model; help(load_model)"`
4. Search code: `grep -r "function_name" *.py`
5. Test with simple data first

Good luck with development!
