# TinyTrail Setup and Run Guide

This project is currently a working MVP stack built with:

- Expo React Native mobile app
- Node.js + Express backend
- SQLite database
- Python hygiene model integration

It is not a Flutter/Firebase project in its current codebase. The fastest way to finish and demo the app is to complete this MVP stack first.

## 1. Install software

Install these on your Windows laptop:

1. Node.js 18 or newer
2. Expo Go on your Android phone
3. Python 3.10 or 3.11
4. Git

Optional but useful:

1. Android Studio if you want an emulator
2. VS Code

## 2. Install Python and model dependencies

Open a terminal in:

`T:\College\Project\TinyTrail\Hygine`

Run:

```powershell
py -3.11 -m venv .venv
.venv\Scripts\Activate.ps1
pip install --upgrade pip
pip install -r requirements.txt
```

If `py` does not work, install Python from the official installer and make sure:

- `python` works in terminal
- or set an environment variable called `PYTHON_BIN` to your Python executable path

Example:

```powershell
$env:PYTHON_BIN="C:\Users\YourName\AppData\Local\Programs\Python\Python311\python.exe"
```

## 3. Install backend packages

Open terminal in:

`T:\College\Project\TinyTrail\model\backend-simple`

Run:

```powershell
npm install
```

## 4. Install mobile packages

Open terminal in:

`T:\College\Project\TinyTrail\model\mobile`

Run:

```powershell
npm install
```

## 5. Start the backend

In:

`T:\College\Project\TinyTrail\model\backend-simple`

Run:

```powershell
node server-v2.js
```

Backend URL:

`http://localhost:8080/api`

Sample login:

- `john_buyer / password123`
- `jane_seller / password123`
- `admin / password123`

## 6. Connect the mobile app to your laptop

If using Android emulator:

- default already works with `http://10.0.2.2:8080/api`

If using a real phone:

1. Connect phone and laptop to the same Wi-Fi
2. Find your laptop IPv4 address:

```powershell
ipconfig
```

3. Start Expo using your local IP:

```powershell
$env:EXPO_PUBLIC_API_URL="http://YOUR_LAPTOP_IP:8080/api"
npx expo start --tunnel
```

Replace `YOUR_LAPTOP_IP` with something like `192.168.1.5`.

## 7. Run the mobile app

In:

`T:\College\Project\TinyTrail\model\mobile`

Run:

```powershell
npx expo start
```

Then:

1. Scan the QR code using Expo Go
2. Login
3. Search by pincode `600001`
4. Open seller onboarding
5. Run hygiene check
6. Add products
7. Add items to cart
8. Checkout

## 8. Hygiene AI feature

What is already integrated:

1. Seller can upload a workspace photo from the mobile app
2. Backend saves the image
3. Backend calls `T:\College\Project\TinyTrail\Hygine\api_predict.py`
4. The trained model at `T:\College\Project\TinyTrail\model\models\hygiene_model.pth` is used
5. Backend returns:
   - predicted class
   - confidence
   - hygiene score
   - badge text

If the hygiene check fails:

1. Confirm Python is installed
2. Confirm `pip install -r requirements.txt` finished successfully
3. Confirm the model file exists at:

`T:\College\Project\TinyTrail\model\models\hygiene_model.pth`

## 9. Main working flows

These flows are now connected in code:

1. Login and register
2. Product search by pincode
3. Product detail screen
4. Cart
5. Checkout UI
6. Seller onboarding
7. Product creation with image upload
8. Hygiene photo upload and AI scoring

## 10. Things you still need to do manually

These are machine or product decisions I cannot finish from here:

1. Install Python locally
2. Install model dependencies from `Hygine/requirements.txt`
3. Run the app on your phone with your actual LAN IP
4. Test camera/gallery permissions on your phone
5. Decide whether your final submission should stay on Expo/Node or be rewritten to Flutter/Firebase

## 11. Important reality check for final project

Your written project vision mentions:

- Flutter
- Firebase Auth
- Firestore
- Realtime Database
- Firebase Storage
- FCM
- live cart tracking
- digital hail

But your existing codebase is not built on that stack right now.

For a final project submission, the safest path is:

1. Submit this Expo + Node MVP as the implemented product
2. Present Firebase/live-tracking as future enhancement

Trying to fully rewrite everything into Flutter + Firebase now will take much longer and is high risk.

## 12. Recommended demo order

1. Start backend
2. Start Expo app
3. Login as buyer
4. Search products by pincode
5. Open a product and add to cart
6. Register or login as seller
7. Complete seller onboarding
8. Upload hygiene workspace image
9. Show AI hygiene score
10. Add a product with image
11. Return to buyer flow and show the new product
