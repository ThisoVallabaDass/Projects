"""Overnight pipeline for TinyTrail hygiene data expansion and retraining."""

from __future__ import annotations

import argparse
import subprocess
import sys
from pathlib import Path


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Run the overnight scrape -> clean -> train -> evaluate pipeline."
    )
    parser.add_argument("--target-per-class", type=int, default=2500)
    parser.add_argument("--per-query-limit", type=int, default=40)
    parser.add_argument("--epochs", type=int, default=35)
    parser.add_argument("--batch-size", type=int, default=16)
    parser.add_argument("--arch", type=str, default="efficientnet_b0")
    parser.add_argument("--lr", type=float, default=0.0003)
    parser.add_argument("--model-output", type=str, default="models/hygiene_model_overnight.pth")
    parser.add_argument("--report-path", type=str, default="models/training_report_overnight.json")
    parser.add_argument("--google-fallback", action="store_true")
    return parser.parse_args()


def run_step(title: str, command: list[str], cwd: Path) -> None:
    print("\n" + "=" * 84)
    print(title)
    print("=" * 84)
    print(" ".join(command))
    completed = subprocess.run(command, check=False, cwd=str(cwd))
    if completed.returncode != 0:
        raise RuntimeError(f"Step failed: {title}")


def main() -> None:
    args = parse_args()
    python_bin = sys.executable
    root = Path(__file__).resolve().parent

    print("=" * 84)
    print("TINYTRAIL OVERNIGHT HYGIENE PIPELINE")
    print("=" * 84)
    print(f"Working directory : {root}")
    print(f"Python            : {python_bin}")
    print(f"Target/class      : {args.target_per_class}")
    print(f"Epochs            : {args.epochs}")
    print(f"Architecture      : {args.arch}")
    print("=" * 84)

    scrape_cmd = [
        python_bin,
        "scrape_images_indian_kitchens.py",
        "--target-per-class",
        str(args.target_per_class),
        "--per-query-limit",
        str(args.per_query_limit),
        "--min-width",
        "384",
        "--min-height",
        "384",
    ]
    if args.google_fallback:
        scrape_cmd.append("--google-fallback")

    run_step("STEP 1: SCRAPE MORE INDIAN WORKSPACE IMAGES", scrape_cmd, root)
    run_step(
        "STEP 2: REMOVE EXACT DUPLICATES",
        [python_bin, "deduplicate_dataset.py", "--exact-only"],
        root,
    )
    run_step(
        "STEP 3: CLEAN LOW-QUALITY / IRRELEVANT IMAGES",
        [python_bin, "clean_dataset.py", "--filter-irrelevant", "--min-size", "224"],
        root,
    )
    run_step("STEP 4: TRAIN THE UPDATED MODEL", [
        python_bin,
        "train_enhanced.py",
        "--epochs",
        str(args.epochs),
        "--batch-size",
        str(args.batch_size),
        "--arch",
        args.arch,
        "--lr",
        str(args.lr),
        "--freeze-epochs",
        "4",
        "--output",
        args.model_output,
        "--report-path",
        args.report_path,
    ], root)
    run_step(
        "STEP 5: EVALUATE THE FINAL CHECKPOINT",
        [python_bin, "evaluate.py", "--model-path", args.model_output, "--batch-size", str(args.batch_size)],
        root,
    )

    print("\n" + "=" * 84)
    print("OVERNIGHT PIPELINE COMPLETE")
    print("=" * 84)
    print(f"Model  : {args.model_output}")
    print(f"Report : {args.report_path}")


if __name__ == "__main__":
    main()
