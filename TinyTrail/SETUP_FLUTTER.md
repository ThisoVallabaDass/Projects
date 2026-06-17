# TinyTrails MVP - Setup Guide

## Quick Start

### 1. Install Dependencies
```bash
cd tinytrails_mvp
flutter pub get
```

### 2. Firebase Setup
This app requires Firebase. Follow these steps:

#### Step 2.1: Create Firebase Project
1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Create a new project named "TinyTrails"
3. Enable Google Analytics (optional)

#### Step 2.2: Add Android App
1. Click "Add app" > Android
2. Package name: `com.tinytrails.mvp`
3. Download `google-services.json`
4. Place it in `android/app/google-services.json`

#### Step 2.3: Enable Authentication
1. Go to Authentication > Sign-in method
2. Enable **Email/Password**
3. Enable **Google** (add SHA-1 fingerprint)

To get SHA-1:
```bash
cd android && ./gradlew signingReport
```

#### Step 2.4: Create Firestore Database
1. Go to Firestore Database
2. Click "Create database"
3. Start in **test mode** for development
4. Select your region

#### Step 2.5: Firestore Rules (Development)
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /{document=**} {
      allow read, write: if request.time < timestamp.date(2025, 12, 31);
    }
  }
}
```

### 3. Run the App
```bash
# Connect your Android device or start emulator
flutter run
```

## Project Structure

```
lib/
├── main.dart                 # App entry point with Firebase init
├── theme/
│   └── theme.dart            # Design system (Royal Blue + Emerald Green)
├── models/
│   ├── user_model.dart       # User data model with roles
│   ├── product_model.dart    # Product, Cart, Order models
│   └── models.dart           # Barrel export
├── services/
│   └── firebase_service.dart # Auth & Firestore operations
├── screens/
│   ├── login_screen.dart     # Dual-role animated login
│   ├── customer_home.dart    # Customer home with live radar
│   ├── customer_vendor_view.dart  # Vendor detail + cart
│   ├── vendor_dashboard.dart # Vendor dashboard with hygiene check
│   └── vendor_menu_manager.dart   # Menu management
└── widgets/
    └── ...                   # Reusable UI components
```

## Color Themes

| Role     | Primary Color | Hex Code  |
|----------|--------------|-----------|
| Customer | Royal Blue   | `#2563EB` |
| Vendor   | Emerald Green| `#10B981` |

## Features

### Login Screen
- Animated role switcher (Customer/Vendor)
- Email/Password authentication
- Google Sign-In
- Dynamic color theming

### Customer Features
- Location-based header
- Search with voice input
- Veg/Non-Veg filters
- Live Kart radar banner
- Vendor cards with hygiene badges
- Floating cart banner (Swiggy-style)

### Vendor Features
- AI Hygiene Check (simulated)
- Go-Live status toggle
- Trust tier badges
- Menu management
- Active orders queue
- Stock toggle for items

## Troubleshooting

### "No google-services.json found"
Download from Firebase Console and place in `android/app/`

### "Firebase app not initialized"
Ensure `await Firebase.initializeApp()` is called in `main()`

### Google Sign-In fails
Add SHA-1 fingerprint to Firebase Console:
```bash
keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android
```
