"""Shared utilities for the Hygiene Classification project."""

import logging
from pathlib import Path
from typing import Optional

from torchvision.datasets import ImageFolder

logger = logging.getLogger(__name__)

IMAGE_EXTS = {".jpg", ".jpeg", ".png", ".bmp", ".webp"}
DEFAULT_IMAGE_SIZE = 224
DEFAULT_BATCH_SIZE = 32
DEFAULT_EPOCHS = 10
DEFAULT_LEARNING_RATE = 1e-3
IGNORED_CLASS_PREFIXES = ("_", ".")


def setup_logging(level: int = logging.INFO) -> None:
    """Configure logging for all modules."""
    logging.basicConfig(
        level=level,
        format="%(asctime)s - %(name)s - %(levelname)s - %(message)s",
        handlers=[
            logging.StreamHandler(),
            logging.FileHandler("hygiene_training.log"),
        ],
    )


def resolve_dataset_dir(dataset_dir: Optional[str] = None) -> Path:
    """Resolve the dataset directory path."""
    if dataset_dir:
        path = Path(dataset_dir)
        if path.exists():
            return path
        raise FileNotFoundError(f"Dataset path not found: {path}")

    candidates = [Path("dataset"), Path("AI_Hygiene_Model/dataset")]
    for candidate in candidates:
        if candidate.exists():
            return candidate

    raise FileNotFoundError(
        "Could not find dataset directory. Checked: dataset and AI_Hygiene_Model/dataset"
    )


def count_images_in_dir(folder: Path) -> int:
    """Count all images in a directory recursively."""
    return sum(1 for p in folder.rglob("*") if p.is_file() and p.suffix.lower() in IMAGE_EXTS)


def has_images(path: Path) -> bool:
    """Check if a directory contains any images."""
    return any(p.suffix.lower() in IMAGE_EXTS for p in path.rglob("*") if p.is_file())


def is_valid_class_dir(name: str) -> bool:
    """Return True for real dataset classes and False for helper folders."""
    return bool(name) and not name.startswith(IGNORED_CLASS_PREFIXES)


class HygieneImageFolder(ImageFolder):
    """ImageFolder variant that ignores helper folders like `_removed_irrelevant`."""

    def find_classes(self, directory: str):
        classes = [
            entry.name
            for entry in Path(directory).iterdir()
            if entry.is_dir() and is_valid_class_dir(entry.name)
        ]
        classes.sort()
        if not classes:
            raise FileNotFoundError(f"Couldn't find any class folder in {directory}.")
        class_to_idx = {class_name: index for index, class_name in enumerate(classes)}
        return classes, class_to_idx
