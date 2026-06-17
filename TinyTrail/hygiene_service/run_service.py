#!/usr/bin/env python3
"""
TinyTrails Hygiene Service Auto-Launcher
This script automatically starts the hygiene service and handles graceful shutdown.
"""

import subprocess
import sys
import os
import signal
import time
from pathlib import Path

# Add the hygiene_service directory to path
SCRIPT_DIR = Path(__file__).resolve().parent
os.chdir(SCRIPT_DIR)

def check_dependencies():
    """Check if all required packages are installed"""
    required = ['fastapi', 'uvicorn', 'torch', 'torchvision', 'PIL', 'numpy']
    missing = []

    for pkg in required:
        try:
            __import__(pkg if pkg != 'PIL' else 'PIL')
        except ImportError:
            missing.append(pkg if pkg != 'PIL' else 'pillow')

    if missing:
        print(f"[INFO] Installing missing packages: {', '.join(missing)}")
        subprocess.check_call([sys.executable, '-m', 'pip', 'install'] + missing)

def check_model():
    """Check if model files exist"""
    models_dir = SCRIPT_DIR.parent / "Hygine" / "models"
    model_files = [
        "hygiene_model_indian_kitchen.pth",
        "hygiene_model.pth",
        "hygiene_model_overnight.pth"
    ]

    for model_file in model_files:
        if (models_dir / model_file).exists():
            print(f"[OK] Found model: {model_file}")
            return True

    print("[WARNING] No trained model found. Service will use mock predictions.")
    print(f"[INFO] Expected model location: {models_dir}")
    return False

def run_service(host="0.0.0.0", port=8000):
    """Run the hygiene service"""
    import uvicorn

    print("=" * 50)
    print("  TinyTrails Hygiene Service")
    print("=" * 50)
    print(f"\n[INFO] Starting service on http://{host}:{port}")
    print("[INFO] API Documentation: http://localhost:8000/docs")
    print("[INFO] Health Check: http://localhost:8000/health")
    print("\n[INFO] Press Ctrl+C to stop\n")

    # Import and run the app
    from app_unified import app
    uvicorn.run(app, host=host, port=port, log_level="info")

def main():
    print("\n[STARTUP] TinyTrails Hygiene Service Launcher\n")

    # Check dependencies
    print("[STEP 1] Checking dependencies...")
    try:
        check_dependencies()
        print("[OK] All dependencies installed\n")
    except Exception as e:
        print(f"[ERROR] Failed to install dependencies: {e}")
        sys.exit(1)

    # Check model
    print("[STEP 2] Checking model files...")
    check_model()
    print()

    # Run service
    print("[STEP 3] Starting service...")
    try:
        run_service()
    except KeyboardInterrupt:
        print("\n[INFO] Service stopped by user")
    except Exception as e:
        print(f"[ERROR] Service error: {e}")
        sys.exit(1)

if __name__ == "__main__":
    main()
