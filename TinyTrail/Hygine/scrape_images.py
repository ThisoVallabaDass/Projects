"""Scrape images from the web for hygiene dataset using Bing Image Search."""

import logging
from pathlib import Path

from icrawler.builtin import BingImageCrawler

from utils import setup_logging, IMAGE_EXTS

logger = logging.getLogger(__name__)

# More focused, class-specific search queries improve label quality.
CLASS_QUERIES = {
    "meets_standard": [
        "clean commercial kitchen stainless steel sanitized surfaces food prep",
        "restaurant kitchen staff wearing gloves hairnet food safety",
        "haccp compliant food preparation kitchen clean workstation",
        "sanitary food production kitchen clean utensils organized",
        "chef preparing food with gloves and hairnet in clean kitchen",
    ],
    "needs_work": [
        "restaurant kitchen cluttered workspace minor hygiene issues",
        "food prep area messy counter unorganized kitchen",
        "kitchen staff without gloves during food preparation",
        "restaurant prep station moderate cleanliness problems",
        "commercial kitchen untidy but operational food prep",
    ],
    "shouldnt_work": [
        "unsanitary commercial kitchen severe contamination",
        "restaurant kitchen mold dirty surfaces pest infestation",
        "rotten food in kitchen unsafe food handling",
        "cockroaches in restaurant kitchen food safety violation",
        "extremely dirty food preparation area public health violation",
    ],
}


def resolve_dataset_root() -> Path:
    candidates = [Path("dataset"), Path("AI_Hygiene_Model/dataset")]
    for path in candidates:
        if path.exists():
            return path
    # If none exists, default to local dataset folder and create it.
    return Path("dataset")


def existing_image_count(folder: Path) -> int:
    """Count existing images in folder without recreating set."""
    return sum(1 for p in folder.rglob("*") if p.is_file() and p.suffix.lower() in IMAGE_EXTS)


def download_images(keyword: str, folder: Path, limit: int, min_size: tuple[int, int]) -> int:
    """Download images for a keyword and return number downloaded."""

    # Use offset so re-runs append images instead of overwriting existing ones.
    offset = existing_image_count(folder)

    crawler = BingImageCrawler(
        parser_threads=2,
        downloader_threads=4,
        storage={"root_dir": str(folder)},
    )

    crawler.crawl(
        keyword=keyword,
        max_num=limit,
        min_size=min_size,
        file_idx_offset=offset,
    )

    return existing_image_count(folder) - offset


def main() -> None:
    """Main function: scrape images for each class."""
    setup_logging()
    dataset_root = resolve_dataset_root()

    # You can tune these values based on your internet speed and storage.
    per_query_limit = 200
    min_size = (512, 512)

    logger.info(f"Dataset root: {dataset_root}")
    print(f"\nDataset root: {dataset_root}")
    print(f"Downloading up to {per_query_limit} images per query (min size: {min_size[0]}x{min_size[1]})")

    for class_name, queries in CLASS_QUERIES.items():
        class_dir = dataset_root / class_name
        class_dir.mkdir(parents=True, exist_ok=True)

        logger.info(f"Starting downloads for class: {class_name}")
        print(f"\nClass: {class_name}")
        total_new = 0

        for i, query in enumerate(queries, start=1):
            logger.info(f"Downloading query {i}/{len(queries)}: {query}")
            print(f"  [{i}/{len(queries)}] Query: {query}")
            downloaded = download_images(
                keyword=query,
                folder=class_dir,
                limit=per_query_limit,
                min_size=min_size,
            )
            total_new += max(downloaded, 0)
            print(f"      Added images (approx): {downloaded}")

        logger.info(f"Total new images for {class_name}: {total_new}")
        print(f"  Total new images for {class_name}: {total_new}")

    print("\n" + "=" * 60)
    print("Download complete. Next steps:")
    print("  1) python clean_dataset.py --filter-irrelevant")
    print("  2) python stats_dataset.py")
    print("  3) python train.py")
    print("=" * 60 + "\n")
    logger.info("Image scraping complete.")


if __name__ == "__main__":
    try:
        main()
    except Exception as exc:
        logger.error(f"Image scraping failed: {exc}", exc_info=True)
        raise


if __name__ == "__main__":
    try:
        main()
    except Exception as exc:
        print(f"Image scraping failed: {exc}")
        raise
