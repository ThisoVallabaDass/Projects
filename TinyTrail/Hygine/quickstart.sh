#!/bin/bash
# Quick start script for the Hygiene Classification Project
# Run this after installing dependencies: pip install -r requirements.txt

echo "========================================"
echo "AI Hygiene Classification - Quick Start"
echo "========================================"
echo ""

# Step 1: Scrape images
echo "[1/4] Scraping images from the web..."
python scrape_images.py
if [ $? -ne 0 ]; then
    echo "Error during image scraping. Exiting."
    exit 1
fi
echo ""

# Step 2: Clean dataset
echo "[2/4] Cleaning dataset..."
python clean_dataset.py --filter-irrelevant
if [ $? -ne 0 ]; then
    echo "Error during dataset cleaning. Exiting."
    exit 1
fi
echo ""

# Step 3: Show statistics
echo "[3/4] Dataset statistics..."
python stats_dataset.py
echo ""

# Step 4: Train model
echo "[4/4] Training model..."
python train.py --epochs 15 --batch-size 32
if [ $? -ne 0 ]; then
    echo "Error during training. Exiting."
    exit 1
fi
echo ""

echo "========================================"
echo "Training complete!"
echo "========================================"
echo ""
echo "You can now make predictions with:"
echo "  python predict.py path/to/image.jpg"
echo ""
echo "Or evaluate on a test set with:"
echo "  python evaluate.py --batch-size 32"
echo ""
