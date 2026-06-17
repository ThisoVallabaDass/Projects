"""Clean dataset by removing corrupted, tiny, and irrelevant images."""

import argparse
import logging
import shutil
from pathlib import Path

import torch
import torchvision.models as models
from PIL import Image, UnidentifiedImageError

from utils import IMAGE_EXTS, resolve_dataset_dir, setup_logging

logger = logging.getLogger(__name__)

RELEVANT_KEYWORDS = {
    "food",
    "kitchen",
    "restaurant",
    "vendor",
    "cart",
    "stall",
    "counter",
    "workstation",
    "workspace",
    "utensil",
    "stainless",
    "steel",
    "chef",
    "cook",
    "cooking",
    "dish",
    "plate",
    "bowl",
    "spoon",
    "fork",
    "knife",
    "pan",
    "pot",
    "kadai",
    "tawa",
    "ladle",
    "burner",
    "stove",
    "gas",
    "oven",
    "microwave",
    "refrigerator",
    "fridge",
    "sink",
    "cabinet",
    "table",
    "dining",
    "tray",
    "apron",
    "glove",
    "hairnet",
    "meat",
    "vegetable",
    "fruit",
    "bread",
    "pizza",
    "burger",
    "egg",
    "soup",
    "salad",
    "dosa",
    "idli",
    "samosa",
    "bajji",
    "tea",
    "juice",
    "hotel",
}

IRRELEVANT_KEYWORDS = {
    "dog",
    "cat",
    "bird",
    "insect",
    "snake",
    "car",
    "truck",
    "bus",
    "airplane",
    "ship",
    "mountain",
    "beach",
    "forest",
    "building",
    "church",
    "stadium",
    "bridge",
    "flower",
    "logo",
    "cartoon",
    "bedroom",
    "landscape",
    "portrait",
}


def is_valid_image(path: Path, min_size: int) -> bool:
    try:
        with Image.open(path) as img:
            img.verify()
        with Image.open(path) as img:
            rgb_img = img.convert("RGB")
            width, height = rgb_img.size
            return width >= min_size and height >= min_size
    except (UnidentifiedImageError, OSError, ValueError):
        return False


def load_relevance_model(device: torch.device):
    try:
        weights = models.ResNet18_Weights.DEFAULT
        model = models.resnet18(weights=weights).to(device)
    except Exception:
        return None, None, None

    model.eval()
    categories = weights.meta.get("categories", [])
    preprocess = weights.transforms()
    return model, categories, preprocess


def keyword_score(labels: list[str], probs: list[float], keywords: set[str]) -> float:
    total = 0.0
    for label, prob in zip(labels, probs):
        lower = label.lower()
        if any(keyword in lower for keyword in keywords):
            total += prob
    return total


def is_relevant_image(
    image_path: Path,
    model,
    categories: list[str],
    preprocess,
    device: torch.device,
    topk: int,
    min_relevant_score: float,
) -> bool:
    with Image.open(image_path) as img:
        image = img.convert("RGB")

    tensor = preprocess(image).unsqueeze(0).to(device)
    with torch.no_grad():
        logits = model(tensor)
        probs = torch.softmax(logits, dim=1)[0]

    k = min(topk, probs.shape[0])
    values, indices = torch.topk(probs, k=k)
    top_labels = [categories[index] for index in indices.tolist()]
    top_probs = values.tolist()

    relevant_score = keyword_score(top_labels, top_probs, RELEVANT_KEYWORDS)
    irrelevant_score = keyword_score(top_labels, top_probs, IRRELEVANT_KEYWORDS)
    return relevant_score >= min_relevant_score or irrelevant_score < 0.55


def move_to_review(file_path: Path, dataset_dir: Path, review_dir_name: str) -> Path:
    relative = file_path.relative_to(dataset_dir)
    target = dataset_dir / review_dir_name / relative
    target.parent.mkdir(parents=True, exist_ok=True)
    shutil.move(str(file_path), str(target))
    return target


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Clean dataset by removing corrupted, tiny, and irrelevant images."
    )
    parser.add_argument("--dataset-dir", type=str, default=None, help="Dataset root directory.")
    parser.add_argument(
        "--min-size",
        type=int,
        default=128,
        help="Minimum width/height in pixels.",
    )
    parser.add_argument(
        "--filter-irrelevant",
        action="store_true",
        help="Enable relevance filtering for non-kitchen/non-food images.",
    )
    parser.add_argument("--topk", type=int, default=5, help="Top-k labels used for scoring.")
    parser.add_argument(
        "--min-relevant-score",
        type=float,
        default=0.08,
        help="Minimum relevance score required to keep an image.",
    )
    parser.add_argument(
        "--review-dir",
        type=str,
        default="_removed_irrelevant",
        help="Folder under dataset root where removed files are moved.",
    )
    parser.add_argument(
        "--delete",
        action="store_true",
        help="Delete files instead of moving them to a review folder.",
    )
    return parser.parse_args()


def main() -> None:
    setup_logging()
    args = parse_args()
    dataset_dir = resolve_dataset_dir(args.dataset_dir)
    logger.info("Dataset directory: %s", dataset_dir)

    class_dirs = [
        directory
        for directory in sorted(dataset_dir.iterdir())
        if directory.is_dir() and directory.name != args.review_dir and not directory.name.startswith(".")
    ]
    if not class_dirs:
        raise RuntimeError(f"No class folders found in: {dataset_dir}")

    device = torch.device("cuda" if torch.cuda.is_available() else "cpu")
    model, categories, preprocess = (None, None, None)

    if args.filter_irrelevant:
        logger.info("Loading relevance model on %s", device)
        model, categories, preprocess = load_relevance_model(device)
        if model is None:
            logger.warning(
                "Could not load pretrained relevance model. Proceeding with corruption and size cleanup only."
            )

    removed_corrupt_or_small = 0
    removed_irrelevant = 0

    for class_dir in class_dirs:
        logger.info("Scanning class: %s", class_dir.name)
        for file_path in class_dir.rglob("*"):
            if not file_path.is_file() or file_path.suffix.lower() not in IMAGE_EXTS:
                continue

            if not is_valid_image(file_path, min_size=args.min_size):
                if args.delete:
                    file_path.unlink(missing_ok=True)
                else:
                    move_to_review(file_path, dataset_dir, args.review_dir)
                removed_corrupt_or_small += 1
                continue

            if args.filter_irrelevant and model is not None:
                try:
                    keep = is_relevant_image(
                        file_path,
                        model,
                        categories,
                        preprocess,
                        device,
                        topk=args.topk,
                        min_relevant_score=args.min_relevant_score,
                    )
                except Exception:
                    keep = False

                if not keep:
                    if args.delete:
                        file_path.unlink(missing_ok=True)
                    else:
                        move_to_review(file_path, dataset_dir, args.review_dir)
                    removed_irrelevant += 1

    print("\nCleaning Summary")
    print(f"Corrupt/small removed: {removed_corrupt_or_small}")
    print(f"Irrelevant removed: {removed_irrelevant}")
    print(f"Total removed: {removed_corrupt_or_small + removed_irrelevant}")


if __name__ == "__main__":
    try:
        main()
    except Exception as exc:
        logger.error("Dataset cleaning failed: %s", exc, exc_info=True)
        raise
