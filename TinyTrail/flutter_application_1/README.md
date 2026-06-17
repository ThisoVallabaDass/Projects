# TinyTrail Flutter

Cleaned Flutter client for TinyTrail with Firebase auth, Firestore-backed demo marketplace data, and dual customer/vendor flows.

## Source of truth

- `lib/main.dart`: single app entry point
- `lib/src/bootstrap.dart`: Firebase startup
- `lib/src/app.dart`: splash + app shell boot
- `lib/src/splash.dart`: white splash screen
- `lib/src/auth.dart`: customer/vendor auth flow
- `lib/src/vendor/hygiene_check.dart`: vendor hygiene gate
- `lib/src/shell.dart`: customer and vendor post-login UI
- `lib/src/shared.dart`: shared theme, cards, and reusable UI pieces

## Current functionality

- dual-role login with customer blue / vendor green theme
- Firebase email/password auth
- demo autofill credentials with fallback demo account creation
- vendor hygiene gate before vendor shell
- customer home with:
  - delivery pincode
  - search bar
  - category grid
  - live radar card
  - popular vendor feed
  - Firestore product grid
- vendor shell with:
  - dashboard
  - product management
  - earnings placeholder
  - profile / trust section
- Firestore demo seed for sample vendors and products
- vendor product add + stock toggle

## Run on Android

Use Android emulator or a physical Android device:

```powershell
cd T:\College\Project\TinyTrail\flutter_application_1
flutter clean
flutter pub get
flutter run
```

If Flutter asks for a device, choose the Android emulator or phone, not `Windows`.

## Important Windows note

If you run the Windows desktop target, Flutter plugins may fail unless Windows Developer Mode is enabled because desktop builds need symlink support.

Open the setting with:

```powershell
start ms-settings:developers
```

For normal mobile testing, you do not need the Windows desktop target at all.

## Cleaned up

The old duplicate experimental Flutter files under:

- `lib/screens/`
- `lib/theme/`
- `lib/widgets/`

were removed so the project now has one clear architecture.
