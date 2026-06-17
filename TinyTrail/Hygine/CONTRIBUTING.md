# Contributing to AI Hygiene Classification Project

## Code Style

- Follow PEP 8 guidelines
- Use type hints for function parameters and return values
- Write docstrings for all functions and classes
- Maximum line length: 100 characters

## Adding New Features

1. Create a new branch: `git checkout -b feature/your-feature-name`
2. Make your changes
3. Add docstrings and type hints
4. Test your changes thoroughly
5. Submit a pull request

## Improving the Model

### Collecting Better Data

- Use more diverse queries in `scrape_images.py`
- Manually curate and clean dataset
- Ensure balanced class distribution

### Training Improvements

- Experiment with different architectures (ResNet, EfficientNet, Vision Transformer)
- Try different learning rates and batch sizes
- Implement learning rate scheduling
- Add early stopping to prevent overfitting
- Use cross-validation for better evaluation

### Evaluation

- Create a proper train/validation/test split
- Compute precision, recall, F1-score per class
- Generate confusion matrix
- Implement k-fold cross-validation

## Code Quality

### Type Hints

Always include type hints:

```python
def process_images(
    image_dir: Path,
    min_size: int,
    output_path: Path,
) -> int:
    """Process all images in directory."""
    pass
```

### Docstrings

Use Google-style docstrings:

```python
def clean_image(image_path: Path, target_size: int) -> np.ndarray:
    """
    Clean and preprocess image for model.
    
    Args:
        image_path: Path to input image file
        target_size: Target image dimension (square)
        
    Returns:
        Preprocessed numpy array
        
    Raises:
        FileNotFoundError: If image file doesn't exist
        ValueError: If image is corrupted
    """
    pass
```

### Logging

Use logging instead of print():

```python
import logging

logger = logging.getLogger(__name__)

logger.info("Training started")
logger.warning("Low GPU memory")
logger.error("Failed to load model", exc_info=True)
```

## Testing

- Test locally before committing
- Verify model training completes successfully
- Check that predictions work on new images
- Validate dataset cleaning doesn't remove good images

## Documentation

- Update README.md if you change usage
- Document new configuration options in config.yaml
- Add comments for complex algorithms
- Include examples for new features

## Performance Optimization Ideas

1. **Model Optimization**
   - Quantization (INT8, FP16)
   - Knowledge distillation
   - Pruning

2. **Data Processing**
   - Use TorchVision transforms more efficiently
   - Implement data prefetching
   - Parallelize image loading

3. **Training**
   - Distributed training across GPUs
   - Mixed precision training
   - Gradient accumulation

## Reporting Issues

When reporting bugs, include:
- Python version and OS
- Full error traceback
- Steps to reproduce
- Expected vs actual behavior

## Thank You!

Your contributions help improve this project for everyone!
