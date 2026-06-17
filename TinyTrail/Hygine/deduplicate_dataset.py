"""
Deduplicate dataset by removing near-duplicate and exact duplicate images.
Uses perceptual hashing and image comparison.
"""

import argparse
import hashlib
import logging
from pathlib import Path
from collections import defaultdict
from typing import Set, Tuple

from PIL import Image
from tqdm import tqdm

from utils import setup_logging, IMAGE_EXTS, resolve_dataset_dir

logger = logging.getLogger(__name__)


def get_file_hash(filepath: Path, method: str = "md5") -> str:
    """Get hash of file for exact duplicate detection."""
    hasher = hashlib.new(method)
    with open(filepath, "rb") as f:
        buf = f.read(65536)  # Read in 64kb chunks
        while len(buf) > 0:
            hasher.update(buf)
            buf = f.read(65536)
    return hasher.hexdigest()


def get_image_hash(filepath: Path) -> str:
    """Get perceptual hash of image using PIL histogram."""
    try:
        with Image.open(filepath) as img:
            # Resize to 8x8 and convert to grayscale
            img_small = img.convert("L").resize((8, 8))
            # Create hash from pixel values
            pixels = list(img_small.getdata())
            avg = sum(pixels) / len(pixels)
            # Binary hash: 1 if pixel > avg else 0
            phash = "".join(str(1) if p > avg else 0 for p in pixels)
            return phash
    except Exception as e:
        logger.warning(f"Failed to compute perceptual hash for {filepath}: {e}")
        return None


def hamming_distance(hash1: str, hash2: str) -> int:
    """Calculate Hamming distance between two hashes."""
    if hash1 is None or hash2 is None:
        return float('inf')
    return sum(c1 != c2 for c1, c2 in zip(hash1, hash2))


def deduplicate_exact(dataset_dir: Path) -> Tuple[int, int]:
    """Remove exact duplicates using file hash."""
    logger.info("Finding exact duplicates...")
    
    hash_to_files = defaultdict(list)
    removed_count = 0
    
    # Collect all image hashes
    image_files = [f for f in dataset_dir.rglob("*") if f.is_file() and f.suffix.lower() in IMAGE_EXTS]
    
    print("Scanning for exact duplicates...")
    for filepath in tqdm(image_files, desc="Hashing files"):
        try:
            file_hash = get_file_hash(filepath)
            hash_to_files[file_hash].append(filepath)
        except Exception as e:
            logger.error(f"Error processing {filepath}: {e}")
    
    # Remove duplicates (keep first occurrence)
    print("Removing exact duplicates...")
    for file_hash, filepaths in tqdm(hash_to_files.items(), desc="Processing duplicates"):
        if len(filepaths) > 1:
            # Keep first file, remove others
            for duplicate_path in filepaths[1:]:
                try:
                    logger.info(f"Removing exact duplicate: {duplicate_path}")
                    duplicate_path.unlink()
                    removed_count += 1
                except Exception as e:
                    logger.error(f"Failed to remove {duplicate_path}: {e}")
    
    return len(image_files), removed_count


def deduplicate_similar(dataset_dir: Path, threshold: int = 10) -> Tuple[int, int]:
    """Remove near-duplicate images using perceptual hashing."""
    logger.info(f"Finding similar duplicates (Hamming distance threshold: {threshold})...")
    
    removed_count = 0
    processed_files: Set[Path] = set()
    
    # Collect all images
    image_files = [f for f in dataset_dir.rglob("*") if f.is_file() and f.suffix.lower() in IMAGE_EXTS]
    
    print("Computing perceptual hashes...")
    phashes = {}
    for filepath in tqdm(image_files, desc="Computing hashes"):
        try:
            phash = get_image_hash(filepath)
            if phash:
                phashes[filepath] = phash
        except Exception as e:
            logger.warning(f"Failed to compute hash for {filepath}: {e}")
    
    print("Finding similar images...")
    for filepath1 in tqdm(list(phashes.keys()), desc="Comparing images"):
        if filepath1 in processed_files:
            continue
        
        hash1 = phashes[filepath1]
        
        for filepath2 in phashes.keys():
            if filepath1 >= filepath2 or filepath2 in processed_files:
                continue
            
            hash2 = phashes[filepath2]
            distance = hamming_distance(hash1, hash2)
            
            if distance < threshold:
                # Mark as duplicate and remove
                try:
                    logger.info(
                        f"Removing similar duplicate: {filepath2} "
                        f"(distance: {distance}, original: {filepath1})"
                    )
                    filepath2.unlink()
                    processed_files.add(filepath2)
                    removed_count += 1
                except Exception as e:
                    logger.error(f"Failed to remove {filepath2}: {e}")
    
    return len(image_files), removed_count


def main() -> None:
    parser = argparse.ArgumentParser(description="Remove duplicate images from dataset.")
    parser.add_argument(
        "--dataset-dir",
        type=str,
        help="Path to dataset root directory.",
    )
    parser.add_argument(
        "--exact-only",
        action="store_true",
        help="Only remove exact duplicates.",
    )
    parser.add_argument(
        "--similar-only",
        action="store_true",
        help="Only remove similar duplicates.",
    )
    parser.add_argument(
        "--threshold",
        type=int,
        default=10,
        help="Hamming distance threshold for similar detection (default: 10).",
    )
    
    args = parser.parse_args()
    setup_logging()
    
    try:
        dataset_dir = resolve_dataset_dir(args.dataset_dir)
    except FileNotFoundError as e:
        logger.error(str(e))
        raise
    
    print("=" * 70)
    print("DATASET DEDUPLICATION")
    print("=" * 70)
    print(f"Dataset: {dataset_dir}\n")
    
    total_removed = 0
    
    # Exact duplicates
    if not args.similar_only:
        print("\n1. EXACT DUPLICATES")
        print("-" * 70)
        total_before, removed = deduplicate_exact(dataset_dir)
        print(f"Removed {removed} exact duplicates\n")
        total_removed += removed
    
    # Similar duplicates
    if not args.exact_only:
        print("\n2. SIMILAR DUPLICATES")
        print("-" * 70)
        total_before, removed = deduplicate_similar(dataset_dir, threshold=args.threshold)
        print(f"Removed {removed} similar duplicates (threshold: {args.threshold})\n")
        total_removed += removed
    
    print("\n" + "=" * 70)
    print(f"TOTAL REMOVED: {total_removed} images")
    print("=" * 70 + "\n")
    
    logger.info(f"Deduplication complete. Removed {total_removed} images.")


if __name__ == "__main__":
    try:
        main()
    except Exception as exc:
        logger.error(f"Deduplication failed: {exc}", exc_info=True)
        print(f"\nError: {exc}")
        raise
