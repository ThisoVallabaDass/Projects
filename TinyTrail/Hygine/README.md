# AI Hygiene Classification System

A deep learning-based image classification system for kitchen hygiene assessment. The model classifies kitchen/food preparation images into three categories:
- **meets_standard**: Clean, properly maintained kitchens
- **needs_work**: Kitchens with moderate hygiene issues
- **shouldnt_work**: Severely unsanitary kitchens

## Features

- 📷 Automated image scraping from the internet
- 🧹 Intelligent dataset cleaning with model-based relevance filtering
- 🤖 Transfer learning with ResNet-18 or EfficientNet-B0
- 📊 Comprehensive dataset statistics
- ⚡ GPU support with automatic fallback to CPU
- 🔍 Single-image prediction pipeline

## Project Structure

```
.
├── train.py                 # Training script
├── predict.py              # Single image prediction
├── clean_dataset.py        # Dataset cleaning and filtering
├── stats_dataset.py        # Dataset statistics
├── scrape_images.py        # Web image scraping
├── move_dataset.py         # Dataset utilities
├── utils.py                # Shared utilities
├── config.yaml             # Configuration file
├── requirements.txt        # Python dependencies
├── AI_Hygiene_Model/
│   └── dataset/
│       ├── meets_standard/
│       ├── needs_work/
│       ├── shouldnt_work/
│       └── _removed_irrelevant/
├── models/
│   └── hygiene_model.pth   # Trained model checkpoint
└── notebooks/              # Jupyter notebooks (optional)
```

## Installation

1. Clone or download this repository
2. Create a virtual environment (recommended):
   ```bash
   python -m venv venv
   source venv/bin/activate  # On Windows: venv\Scripts\activate
   ```

3. Install dependencies:
   ```bash
   pip install -r requirements.txt
   ```

## Usage

### 1. Prepare Dataset

#### Scrape Images
Automatically download images from the web for each class:
```bash
python scrape_images.py
```

#### Clean Dataset
Remove corrupt, small, or irrelevant images:
```bash
python clean_dataset.py --min-size 128 --filter-irrelevant
```

#### View Statistics
Check dataset composition:
```bash
python stats_dataset.py
```

### 2. Train Model

Train the classification model:
```bash
python train.py --epochs 15 --batch-size 32 --arch resnet18 --lr 0.001
```

**Optional arguments:**
- `--dataset-dir`: Path to dataset root
- `--output`: Model save path (default: models/hygiene_model.pth)
- `--epochs`: Number of training epochs
- `--batch-size`: Training batch size
- `--lr`: Learning rate
- `--arch`: Model architecture (resnet18 or efficientnet_b0)
- `--num-workers`: DataLoader worker threads

### 3. Make Predictions

Classify a single image:
```bash
python predict.py path/to/image.jpg --model-path models/hygiene_model.pth
```

**Optional arguments:**
- `--model-path`: Path to trained model checkpoint

## Configuration

Edit `config.yaml` to customize:
- Dataset paths
- Training hyperparameters
- Image preprocessing settings
- Data augmentation parameters
- Cleaning thresholds
- Logging settings

## Model Details

### Supported Architectures
- **ResNet-18**: Lightweight, good for edge deployment
- **EfficientNet-B0**: Better accuracy, slightly slower

### Transfer Learning
Both models use ImageNet pre-trained weights as initialization, then fine-tune on the hygiene dataset.

### Training Features
- Random crop, flip, rotation, and color jitter augmentation
- Cross-entropy loss with Adam optimizer
- GPU acceleration when available
- Progress bars with tqdm

## Dataset Guidelines

### Class Descriptions

**meets_standard**
- Clean, organized commercial kitchens
- Proper use of gloves and hairnets
- Sanitized surfaces and utensils
- HACCP-compliant preparation

**needs_work**
- Cluttered but operational kitchens
- Minor hygiene violations
- Unorganized workspaces
- Inconsistent food safety practices

**shouldnt_work**
- Severely contaminated kitchens
- Visible mold, pests, or rotten food
- Hazardous conditions
- Public health violations

### Recommended Dataset Size
- **Minimum**: 100 images per class (300 total)
- **Good**: 500+ images per class (1,500+ total)
- **Excellent**: 1,000+ images per class (3,000+ total)

## Performance Tips

1. **Larger Datasets**: More diverse images improve generalization
2. **Image Quality**: Use `--filter-irrelevant` to remove off-topic images
3. **Data Augmentation**: Enabled by default in training
4. **GPU Usage**: ~10x faster training with CUDA GPU
5. **Class Balance**: Keep similar image counts across classes

## Troubleshooting

### OutOfMemoryError during training
- Reduce `--batch-size` (try 16 or 8)
- Use `--arch resnet18` instead of EfficientNet

### No images found in dataset
- Check dataset directory path
- Ensure images are in subdirectories matching class names
- Verify image file extensions (.jpg, .png, etc.)

### Model not improving during training
- Increase `--epochs` (try 20-30)
- Reduce `--lr` if loss increases
- Expand dataset with more diverse images
- Check that classes are balanced

### Slow predictions
- Use ResNet-18 instead of EfficientNet-B0
- Predictions should take ~100-500ms per image

## Contributing

To improve this project:
1. Add more diverse training data
2. Experiment with different architectures
3. Fine-tune hyperparameters
4. Implement evaluation metrics (accuracy, precision, recall, F1)
5. Add cross-validation

## Future Enhancements

- [ ] Batch prediction on multiple images
- [ ] Web API with Flask/FastAPI
- [ ] Model evaluation with confusion matrix
- [ ] Cross-validation pipeline
- [ ] Grad-CAM visualization of predictions
- [ ] Real-time webcam inference
- [ ] Multi-GPU training support
- [ ] Model quantization for edge deployment

## License

This project is for educational purposes.

## Notes

- Models are trained from scratch on your dataset (transfer learning)
- ImageNet pre-trained weights are automatically downloaded
- Dataset is stored locally in the project directory
- No images are uploaded to external servers (except during scraping)

## Support

For issues or questions:
1. Check this README for common solutions
2. Review the notes in `AI_Hygiene_Learning_Notes.txt`
3. Check Python error messages for specific guidance
