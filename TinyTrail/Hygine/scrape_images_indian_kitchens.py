"""Balanced image scraper for Indian kitchen and food-vendor hygiene data."""

from __future__ import annotations

import argparse
import logging
from pathlib import Path

from icrawler.builtin import BingImageCrawler, GoogleImageCrawler

from utils import IMAGE_EXTS, setup_logging


logger = logging.getLogger(__name__)


QUERY_BANK = {
    "meets_standard": [
        "clean Indian home kitchen stove utensils close up",
        "clean Indian cooking area stainless steel vessels",
        "clean hotel kitchen India stove section",
        "hygienic street food cart India close up utensils",
        "clean dosa counter stainless steel utensils",
        "clean tea stall India stove and vessels",
        "clean juice shop India workstation",
        "organized Indian home kitchen prep area",
        "messy wall but clean Indian kitchen stove utensils",
        "old kitchen but clean stainless steel utensils India",
        "street vendor cart India clean vessels and counter",
        "cloud kitchen India clean prep counter",
        "clean kadai tawa utensils Indian cooking area",
        "clean idli dosa batter station India",
        "clean Indian restaurant utensil washing area",
        "covered ingredients clean Indian kitchen counter",
    ],
    "needs_work": [
        "Indian kitchen slight clutter near stove utensils",
        "street food stall India minor spill counter",
        "Indian home kitchen cluttered but usable prep area",
        "oil marks near stove Indian kitchen moderate",
        "mixed utensils clutter Indian cooking counter",
        "busy Indian hotel kitchen moderate clutter",
        "crowded tea stall prep area India moderate hygiene",
        "old kitchen clean utensils but cluttered slab India",
        "kitchen with clean vessels but messy wall India",
        "street cart India clutter around utensils moderate",
        "partially cleaned Indian stove counter",
        "Indian food prep area needs cleaning",
        "messy but hygienic Indian kitchen utensils visible",
        "food stall India acceptable but cluttered counter",
        "minor food spill near Indian cooking area",
    ],
    "shouldnt_work": [
        "dirty Indian kitchen unwashed utensils close up",
        "dirty stove greasy Indian kitchen",
        "street food stall dirty utensils India",
        "flies near food preparation India kitchen",
        "garbage near cooking area India",
        "dirty hotel kitchen India food residue",
        "spoiled food and dirty utensils kitchen India",
        "oil sludge on stove Indian restaurant",
        "unhygienic street vendor cart India close up",
        "food waste near prep counter India kitchen",
        "dirty cutting board raw food contamination India",
        "moldy food storage Indian kitchen",
        "dirty juice stall India utensils and counter",
        "dirty sink and utensils Indian kitchen",
        "contaminated prep area India food business",
    ],
}


def existing_image_count(folder: Path) -> int:
    return sum(1 for p in folder.rglob("*") if p.is_file() and p.suffix.lower() in IMAGE_EXTS)


def download_with_bing(keyword: str, folder: Path, limit: int, min_size: tuple[int, int]) -> int:
    before = existing_image_count(folder)
    crawler = BingImageCrawler(
        parser_threads=2,
        downloader_threads=4,
        storage={"root_dir": str(folder)},
    )
    crawler.crawl(keyword=keyword, max_num=limit, min_size=min_size, file_idx_offset=before)
    return max(existing_image_count(folder) - before, 0)


def download_with_google(keyword: str, folder: Path, limit: int, min_size: tuple[int, int]) -> int:
    before = existing_image_count(folder)
    crawler = GoogleImageCrawler(
        parser_threads=1,
        downloader_threads=2,
        storage={"root_dir": str(folder)},
    )
    crawler.crawl(keyword=keyword, max_num=limit, min_size=min_size, file_idx_offset=before)
    return max(existing_image_count(folder) - before, 0)


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Scrape Indian kitchen and food-vendor hygiene images with class balancing."
    )
    parser.add_argument(
        "--dataset-dir",
        type=str,
        default="AI_Hygiene_Model/dataset",
        help="Dataset root directory.",
    )
    parser.add_argument(
        "--target-per-class",
        type=int,
        default=2500,
        help="Stop scraping a class when it reaches this image count.",
    )
    parser.add_argument(
        "--per-query-limit",
        type=int,
        default=40,
        help="Maximum images to request per query.",
    )
    parser.add_argument(
        "--min-width",
        type=int,
        default=384,
        help="Minimum image width.",
    )
    parser.add_argument(
        "--min-height",
        type=int,
        default=384,
        help="Minimum image height.",
    )
    parser.add_argument(
        "--google-fallback",
        action="store_true",
        help="Try Google crawler when Bing adds zero files for a query.",
    )
    return parser.parse_args()


def scrape_class(
    class_name: str,
    class_dir: Path,
    queries: list[str],
    target_per_class: int,
    per_query_limit: int,
    min_size: tuple[int, int],
    google_fallback: bool,
) -> int:
    total_added = 0
    class_dir.mkdir(parents=True, exist_ok=True)

    for index, query in enumerate(queries, start=1):
        current_count = existing_image_count(class_dir)
        if current_count >= target_per_class:
            logger.info("%s already reached target (%s images).", class_name, current_count)
            break

        logger.info("[%s/%s] %s -> %s", index, len(queries), class_name, query)
        try:
            added = download_with_bing(query, class_dir, per_query_limit, min_size)
        except Exception as exc:
            logger.warning("Bing crawl failed for '%s': %s", query, exc)
            added = 0

        if added == 0 and google_fallback:
            try:
                added = download_with_google(query, class_dir, max(10, per_query_limit // 2), min_size)
            except Exception as exc:
                logger.warning("Google crawl failed for '%s': %s", query, exc)
                added = 0

        total_added += added
        logger.info("Added %s images for query '%s'.", added, query)

    return total_added


def main() -> None:
    setup_logging()
    args = parse_args()
    dataset_root = Path(args.dataset_dir)
    dataset_root.mkdir(parents=True, exist_ok=True)
    min_size = (args.min_width, args.min_height)

    print("=" * 72)
    print("TINYTRAIL INDIAN WORKSPACE DATASET SCRAPER")
    print("=" * 72)
    print(f"Dataset root      : {dataset_root}")
    print(f"Target per class  : {args.target_per_class}")
    print(f"Per-query limit   : {args.per_query_limit}")
    print(f"Min image size    : {args.min_width}x{args.min_height}")
    print(f"Google fallback   : {args.google_fallback}")
    print("=" * 72)

    total_added = 0
    for class_name, queries in QUERY_BANK.items():
        class_dir = dataset_root / class_name
        before = existing_image_count(class_dir) if class_dir.exists() else 0
        print(f"\n[{class_name}] existing images: {before}")
        added = scrape_class(
            class_name=class_name,
            class_dir=class_dir,
            queries=queries,
            target_per_class=args.target_per_class,
            per_query_limit=args.per_query_limit,
            min_size=min_size,
            google_fallback=args.google_fallback,
        )
        after = existing_image_count(class_dir)
        total_added += added
        print(f"[{class_name}] now has {after} images (added {after - before})")

    print("\n" + "=" * 72)
    print("SCRAPE COMPLETE")
    print("=" * 72)
    for class_name in QUERY_BANK:
        count = existing_image_count(dataset_root / class_name)
        print(f"{class_name:<18} {count}")
    print(f"{'total added':<18} {total_added}")
    print("=" * 72)
    print("Next recommended steps:")
    print("  python deduplicate_dataset.py --exact-only")
    print("  python clean_dataset.py --filter-irrelevant --min-size 224")
    print("  python train_enhanced.py --epochs 35 --batch-size 16 --arch efficientnet_b0")


if __name__ == "__main__":
    main()
