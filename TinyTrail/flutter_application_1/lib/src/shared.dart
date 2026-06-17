import 'package:flutter/material.dart';

enum AppMode { customer, vendor }

class AppProfile {
  AppProfile({
    required this.id,
    required this.username,
    required this.email,
    required this.phone,
    required this.pincode,
    required this.role,
    required this.businessType,
  });

  final String id;
  final String username;
  final String email;
  final String phone;
  final String pincode;
  final String role;
  final String businessType;

  bool get isVendor => role == 'SELLER';

  bool get isFoodVendor => isVendor && businessType == 'food';

  String get businessTypeLabel {
    switch (businessType) {
      case 'food':
        return 'Food Vendor';
      case 'tailor':
        return 'Tailor';
      case 'artisan':
        return 'Artisan';
      default:
        return isVendor ? 'Vendor' : 'Customer';
    }
  }
}

class AppPalette {
  static const Color customer = Color(0xFF2563EB);
  static const Color vendor = Color(0xFF10B981);
  static const Color ink = Color(0xFF111827);
  static const Color muted = Color(0xFF667085);
  static const Color surface = Colors.white;
  static const Color shellBackground = Color(0xFFF8F9FA);
}

Color appAccent(AppMode mode) {
  return mode == AppMode.vendor ? AppPalette.vendor : AppPalette.customer;
}

ThemeData buildTheme(AppMode mode) {
  final accent = appAccent(mode);

  return ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: accent,
      primary: accent,
      surface: AppPalette.surface,
    ),
    scaffoldBackgroundColor: AppPalette.shellBackground,
    textTheme: const TextTheme(
      headlineMedium: TextStyle(
        color: AppPalette.ink,
        fontWeight: FontWeight.w800,
      ),
      titleLarge: TextStyle(
        color: AppPalette.ink,
        fontWeight: FontWeight.w800,
      ),
      bodyMedium: TextStyle(
        color: AppPalette.muted,
        height: 1.45,
      ),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppPalette.shellBackground,
      foregroundColor: AppPalette.ink,
      elevation: 0,
      centerTitle: false,
    ),
    cardTheme: CardThemeData(
      color: Colors.white,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      hintStyle: const TextStyle(color: Color(0xFF98A2B3)),
      labelStyle: const TextStyle(color: AppPalette.muted),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: Color(0xFFD7E0EA)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: Color(0xFFD7E0EA)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide(color: accent, width: 1.5),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: accent,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
        textStyle: const TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 15,
        ),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: Colors.white,
      indicatorColor: accent.withValues(alpha: 0.14),
      labelTextStyle: WidgetStateProperty.resolveWith(
        (states) => TextStyle(
          color: states.contains(WidgetState.selected)
              ? accent
              : const Color(0xFF7A8DA8),
          fontWeight: states.contains(WidgetState.selected)
              ? FontWeight.w700
              : FontWeight.w600,
        ),
      ),
      iconTheme: WidgetStateProperty.resolveWith(
        (states) => IconThemeData(
          color: states.contains(WidgetState.selected)
              ? accent
              : const Color(0xFF7A8DA8),
        ),
      ),
    ),
  );
}

class FirebaseSetupScreen extends StatelessWidget {
  const FirebaseSetupScreen({super.key, this.error});

  final String? error;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Firebase setup needed',
                      style: TextStyle(fontSize: 32, fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 14),
                    const Text('The Flutter app foundation is ready, but Firebase is not connected yet.'),
                    const SizedBox(height: 14),
                    const Text('1. Create a Firebase project.'),
                    const Text('2. Add Android app in Firebase.'),
                    const Text('3. Put google-services.json in android/app/.'),
                    const Text('4. Enable Email/Password auth.'),
                    const Text('5. Create Firestore Database.'),
                    const Text('6. Run flutter pub get and flutter run on Android.'),
                    if (error != null) ...[
                      const SizedBox(height: 14),
                      Text(
                        'Current init error: $error',
                        style: const TextStyle(
                          color: Color(0xFFB42318),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class SoftCard extends StatelessWidget {
  const SoftCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.color = Colors.white,
  });

  final Widget child;
  final EdgeInsets padding;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color(0x140F172A),
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: padding,
        child: child,
      ),
    );
  }
}

class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.title,
    this.action,
    this.subtitle,
  });

  final String title;
  final String? subtitle;
  final String? action;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: AppPalette.ink,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 4),
                Text(
                  subtitle!,
                  style: const TextStyle(
                    color: AppPalette.muted,
                    fontSize: 13,
                  ),
                ),
              ],
            ],
          ),
        ),
        if (action != null)
          Text(
            action!,
            style: const TextStyle(
              color: AppPalette.customer,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
      ],
    );
  }
}

class StatusPill extends StatelessWidget {
  const StatusPill({
    super.key,
    required this.label,
    required this.background,
    required this.foreground,
  });

  final String label;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: foreground,
          fontWeight: FontWeight.w700,
          fontSize: 11,
        ),
      ),
    );
  }
}

class VendorPreviewCard extends StatelessWidget {
  const VendorPreviewCard({
    super.key,
    required this.name,
    required this.note,
    required this.badge,
    required this.hygiene,
    required this.avatarColor,
  });

  final String name;
  final String note;
  final String badge;
  final String hygiene;
  final Color avatarColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 180,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color(0x120F172A),
            blurRadius: 18,
            offset: Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: avatarColor,
                child: Text(
                  name.isEmpty ? 'T' : name[0].toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const Spacer(),
              StatusPill(
                label: badge,
                background: const Color(0xFFEAF2FF),
                foreground: AppPalette.customer,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            name,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: AppPalette.ink,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            note,
            style: const TextStyle(
              fontSize: 12,
              color: AppPalette.muted,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 12),
          StatusPill(
            label: hygiene,
            background: const Color(0xFFE7F7EB),
            foreground: AppPalette.vendor,
          ),
        ],
      ),
    );
  }
}

class MarketplaceProductCard extends StatelessWidget {
  const MarketplaceProductCard({
    super.key,
    required this.name,
    required this.description,
    required this.vendorName,
    required this.price,
    required this.hygieneLabel,
    required this.distanceLabel,
    required this.isMoving,
    this.imageUrl,
    this.onAdd,
  });

  final String name;
  final String description;
  final String vendorName;
  final double price;
  final String hygieneLabel;
  final String distanceLabel;
  final bool isMoving;
  final String? imageUrl;
  final VoidCallback? onAdd;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color(0x120F172A),
            blurRadius: 18,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              SizedBox(
                height: 122,
                width: double.infinity,
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                  child: imageUrl != null && imageUrl!.isNotEmpty
                      ? Image.network(
                          imageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => _ProductImageFallback(),
                        )
                      : const _ProductImageFallback(),
                ),
              ),
              Positioned(
                top: 12,
                right: 12,
                child: StatusPill(
                  label: hygieneLabel,
                  background: const Color(0xFFE7F7EB),
                  foreground: AppPalette.vendor,
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppPalette.ink,
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Rs. ${price.toStringAsFixed(0)}',
                  style: const TextStyle(
                    color: AppPalette.ink,
                    fontWeight: FontWeight.w900,
                    fontSize: 17,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppPalette.muted,
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    CircleAvatar(
                      radius: 14,
                      backgroundColor: const Color(0xFFE8F0FE),
                      child: Text(
                        vendorName.isEmpty ? 'V' : vendorName[0].toUpperCase(),
                        style: const TextStyle(
                          color: AppPalette.customer,
                          fontWeight: FontWeight.w800,
                          fontSize: 11,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            vendorName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppPalette.ink,
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            isMoving ? 'Moving - $distanceLabel away' : distanceLabel,
                            style: const TextStyle(
                              color: AppPalette.muted,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    InkWell(
                      onTap: onAdd,
                      borderRadius: BorderRadius.circular(999),
                      child: Ink(
                        width: 34,
                        height: 34,
                        decoration: const BoxDecoration(
                          color: AppPalette.customer,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.add, size: 20, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProductImageFallback extends StatelessWidget {
  const _ProductImageFallback();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFE0ECFF), Color(0xFFF6F9FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: const Center(
        child: Icon(
          Icons.local_dining_rounded,
          size: 38,
          color: AppPalette.customer,
        ),
      ),
    );
  }
}
