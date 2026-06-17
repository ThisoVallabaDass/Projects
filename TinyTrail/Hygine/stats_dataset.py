"""Print class-wise dataset image statistics."""

import argparse
import logging

from utils import count_images_in_dir, resolve_dataset_dir, setup_logging

logger = logging.getLogger(__name__)


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Print class-wise dataset image statistics.")
    parser.add_argument(
        "--dataset-dir",
        type=str,
        default=None,
        help="Dataset root directory.",
    )
    return parser.parse_args()


def main() -> None:
    setup_logging()
    args = parse_args()
    dataset_dir = resolve_dataset_dir(args.dataset_dir)
    logger.info("Dataset directory: %s", dataset_dir)

    class_dirs = [directory for directory in sorted(dataset_dir.iterdir()) if directory.is_dir()]
    if not class_dirs:
        raise RuntimeError(f"No class folders found in: {dataset_dir}")

    total = 0
    print("\nDataset Summary")
    print("-" * 40)
    for class_dir in class_dirs:
        count = count_images_in_dir(class_dir)
        total += count
        print(f"{class_dir.name:<25} : {count:>5} images")

    print("-" * 40)
    print(f"{'Total images':<25} : {total:>5}")
    print("-" * 40 + "\n")
    logger.info("Dataset statistics: %s total images across %s classes", total, len(class_dirs))


if __name__ == "__main__":
    try:
        main()
    except Exception as exc:
        logger.error("Failed to get dataset statistics: %s", exc, exc_info=True)
        raise
