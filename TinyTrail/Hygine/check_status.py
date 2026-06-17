"""Real-time status checker for pipeline progress"""
import subprocess
from pathlib import Path
import os

def get_stats():
    dataset_path = Path("AI_Hygiene_Model/dataset")
    if not dataset_path.exists():
        return 0, 0
    
    size = sum(f.stat().st_size for f in dataset_path.rglob("*") if f.is_file()) / (1024**3)
    files = sum(1 for f in dataset_path.rglob("*") if f.is_file())
    return size, files

def main():
    print("\n" + "="*70)
    print("REAL-TIME PIPELINE STATUS DASHBOARD")
    print("="*70 + "\n")
    
    targets = {
        "0.89GB": "baseline (current)",
        "5GB": "25% complete",
        "10GB": "67% complete",
        "15GB": "COMPLETE - cleaning starts"
    }
    
    size, files = get_stats()
    progress = (size / 15) * 100
    
    print(f"DATASET STATUS:")
    print(f"  Size: {size:.2f}GB / 15GB ({progress:.1f}%)")
    print(f"  Files: {files:,} images")
    print(f"\nMILESTONES:")
    
    milestones = [0.89, 5, 10, 15]
    for ms in milestones:
        status = "✓ DONE" if size >= ms else "⏳ In Progress" if size > (ms-1) else "⧖ Pending"
        print(f"  {ms:5.2f}GB - {status}")
    
    print(f"\nBACKGROUND PROCESSES:")
    try:
        result = subprocess.run(
            ["Get-Process", "python", "-ErrorAction", "SilentlyContinue"],
            capture_output=True, text=True, shell=True
        )
        py_count = result.stdout.count("python")
        print(f"  Python processes: {py_count} (scraping + pipeline)")
    except:
        print(f"  Python processes: monitoring...")
    
    print("\nNEXT STEPS:")
    if size < 15:
        needed = 15 - size
        remaining_runs = max(1, int(needed / 0.7))  # ~0.7GB per run
        print(f"  Approximately {remaining_runs} more scraping runs needed")
        print(f"  ETA: {remaining_runs * 5} - {remaining_runs * 10} minutes")
    else:
        print(f"  ✓ Scraping complete! Auto-cleaning...")
        print(f"  ✓ Then retraining with full dataset...")
    
    print("\n" + "="*70)

if __name__ == "__main__":
    main()
