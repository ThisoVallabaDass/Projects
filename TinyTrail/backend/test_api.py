"""
Test script for the Enhanced Hygiene API
Tests baseline storage and daily verification
"""

import requests
import json
from pathlib import Path

# API Configuration
API_BASE = "http://localhost:8000"
TEST_VENDOR_ID = "test_vendor_001"

def test_health_check():
    """Test if the API is running"""
    try:
        response = requests.get(f"{API_BASE}/health")
        if response.status_code == 200:
            print("[SUCCESS] API Health Check: PASSED")
            print(json.dumps(response.json(), indent=2))
            return True
        else:
            print(f"[FAIL] API Health Check: FAILED (Status: {response.status_code})")
            return False
    except Exception as e:
        print(f"[FAIL] API Health Check: FAILED (Error: {e})")
        return False

def test_baseline_storage():
    """Test baseline image storage"""
    print("\n[TEST] Testing Baseline Storage...")

    # You'll need to provide actual test images
    test_images_dir = Path("./test_images")
    if not test_images_dir.exists():
        print("[FAIL] Please create ./test_images/ directory with 5 test images (baseline1.jpg to baseline5.jpg)")
        return False

    # Look for test images
    baseline_files = []
    for i in range(1, 6):
        img_file = test_images_dir / f"baseline{i}.jpg"
        if img_file.exists():
            baseline_files.append(('baseline_images', (img_file.name, open(img_file, 'rb'), 'image/jpeg')))
        else:
            print(f"[FAIL] Missing test image: {img_file}")
            return False

    try:
        # Send baseline images
        data = {'vendor_id': TEST_VENDOR_ID}
        response = requests.post(f"{API_BASE}/train-baseline", data=data, files=baseline_files)

        # Close files
        for _, file_info in baseline_files:
            file_info[1].close()

        if response.status_code == 200:
            print("[SUCCESS] Baseline Storage: PASSED")
            print(json.dumps(response.json(), indent=2))
            return True
        else:
            print(f"[FAIL] Baseline Storage: FAILED (Status: {response.status_code})")
            print(response.text)
            return False

    except Exception as e:
        print(f"[FAIL] Baseline Storage: FAILED (Error: {e})")
        return False

def test_daily_verification():
    """Test daily image verification"""
    print("\n[TEST] Testing Daily Verification...")

    test_daily_image = Path("./test_images/daily_test.jpg")
    if not test_daily_image.exists():
        print("[FAIL] Please provide ./test_images/daily_test.jpg for testing")
        return False

    try:
        data = {'vendor_id': TEST_VENDOR_ID}
        files = {'daily_image': (test_daily_image.name, open(test_daily_image, 'rb'), 'image/jpeg')}

        response = requests.post(f"{API_BASE}/verify-daily", data=data, files=files)
        files['daily_image'][1].close()

        if response.status_code == 200:
            result = response.json()
            print("[SUCCESS] Daily Verification: PASSED")
            print(json.dumps(result, indent=2))

            # Check if bounding boxes are provided
            if result.get('bounding_boxes'):
                print(f"\n[ANALYSIS] Found {len(result['bounding_boxes'])} anomaly regions:")
                for i, box in enumerate(result['bounding_boxes']):
                    print(f"  Box {i+1}: x={box[0]}, y={box[1]}, w={box[2]}, h={box[3]}")

            return True
        else:
            print(f"[FAIL] Daily Verification: FAILED (Status: {response.status_code})")
            print(response.text)
            return False

    except Exception as e:
        print(f"[FAIL] Daily Verification: FAILED (Error: {e})")
        return False

def test_vendor_info():
    """Test vendor baseline info retrieval"""
    print("\n[TEST] Testing Vendor Info...")

    try:
        response = requests.get(f"{API_BASE}/vendor/{TEST_VENDOR_ID}/baselines")

        if response.status_code == 200:
            print("[SUCCESS] Vendor Info: PASSED")
            print(json.dumps(response.json(), indent=2))
            return True
        else:
            print(f"[FAIL] Vendor Info: FAILED (Status: {response.status_code})")
            return False

    except Exception as e:
        print(f"[FAIL] Vendor Info: FAILED (Error: {e})")
        return False

def main():
    """Run all tests"""
    print("TinyTrails Enhanced Hygiene API Test Suite")
    print("=" * 50)

    tests = [
        ("Health Check", test_health_check),
        ("Baseline Storage", test_baseline_storage),
        ("Daily Verification", test_daily_verification),
        ("Vendor Info", test_vendor_info)
    ]

    passed = 0
    total = len(tests)

    for test_name, test_func in tests:
        if test_func():
            passed += 1

    print("\n" + "=" * 50)
    print(f"[RESULTS] Test Results: {passed}/{total} tests passed")

    if passed == total:
        print("[SUCCESS] All tests passed! Your API is working correctly.")
    else:
        print("[WARNING] Some tests failed. Please check the setup and try again.")

    print("\n[INFO] Test Image Requirements:")
    print("  - Create ./test_images/ directory")
    print("  - Add baseline1.jpg through baseline5.jpg (clean kitchen images)")
    print("  - Add daily_test.jpg (test daily image)")

if __name__ == "__main__":
    main()