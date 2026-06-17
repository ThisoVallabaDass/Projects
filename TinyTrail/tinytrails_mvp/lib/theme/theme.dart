import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// TinyTrails Design System
/// A minimalist "glass and whitespace" design language
///
/// Consumer Theme: Royal Blue (#2563EB)
/// Vendor Theme: Emerald Green (#10B981)

class TinyTrailsColors {
  TinyTrailsColors._();

  // Primary Colors
  static const Color royalBlue = Color(0xFF2563EB);
  static const Color emeraldGreen = Color(0xFF10B981);

  // Royal Blue Palette (Consumer)
  static const Color royalBlue50 = Color(0xFFEFF6FF);
  static const Color royalBlue100 = Color(0xFFDBEAFE);
  static const Color royalBlue200 = Color(0xFFBFDBFE);
  static const Color royalBlue300 = Color(0xFF93C5FD);
  static const Color royalBlue400 = Color(0xFF60A5FA);
  static const Color royalBlue500 = Color(0xFF3B82F6);
  static const Color royalBlue600 = Color(0xFF2563EB);
  static const Color royalBlue700 = Color(0xFF1D4ED8);
  static const Color royalBlue800 = Color(0xFF1E40AF);
  static const Color royalBlue900 = Color(0xFF1E3A8A);

  // Emerald Green Palette (Vendor)
  static const Color emerald50 = Color(0xFFECFDF5);
  static const Color emerald100 = Color(0xFFD1FAE5);
  static const Color emerald200 = Color(0xFFA7F3D0);
  static const Color emerald300 = Color(0xFF6EE7B7);
  static const Color emerald400 = Color(0xFF34D399);
  static const Color emerald500 = Color(0xFF10B981);
  static const Color emerald600 = Color(0xFF059669);
  static const Color emerald700 = Color(0xFF047857);
  static const Color emerald800 = Color(0xFF065F46);
  static const Color emerald900 = Color(0xFF064E3B);

  // Neutral Colors
  static const Color white = Color(0xFFFFFFFF);
  static const Color offWhite = Color(0xFFFAFAFA);
  static const Color lightGray = Color(0xFFF3F4F6);
  static const Color gray100 = Color(0xFFF1F5F9);
  static const Color gray200 = Color(0xFFE2E8F0);
  static const Color gray300 = Color(0xFFCBD5E1);
  static const Color gray400 = Color(0xFF94A3B8);
  static const Color gray500 = Color(0xFF64748B);
  static const Color slateGray = Color(0xFF475569);
  static const Color darkGray = Color(0xFF334155);
  static const Color charcoal = Color(0xFF1E293B);
  static const Color nearBlack = Color(0xFF0F172A);

  // Semantic Colors
  static const Color success = Color(0xFF22C55E);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color info = Color(0xFF3B82F6);

  // Alias colors for easier use
  static const Color primary = royalBlue;
  static const Color accent = warning;
  static const Color background = offWhite;

  // Glass Effect Colors
  static const Color glassWhite = Color(0x80FFFFFF);
  static const Color glassBorder = Color(0x20000000);

  // Trust Badge Colors
  static const Color badgeBlue = Color(0xFF3B82F6);
  static const Color badgeGold = Color(0xFFF59E0B);
  static const Color badgePlatinum = Color(0xFF9CA3AF);
}

class TinyTrailsTextStyles {
  TinyTrailsTextStyles._();

  // Get the base font family
  static String get fontFamily => GoogleFonts.inter().fontFamily!;

  // Display Styles
  static TextStyle displayLarge = GoogleFonts.inter(
    fontSize: 57,
    fontWeight: FontWeight.w400,
    letterSpacing: -0.25,
    color: TinyTrailsColors.charcoal,
  );

  static TextStyle displayMedium = GoogleFonts.inter(
    fontSize: 45,
    fontWeight: FontWeight.w400,
    color: TinyTrailsColors.charcoal,
  );

  static TextStyle displaySmall = GoogleFonts.inter(
    fontSize: 36,
    fontWeight: FontWeight.w400,
    color: TinyTrailsColors.charcoal,
  );

  // Headline Styles
  static TextStyle headlineLarge = GoogleFonts.inter(
    fontSize: 32,
    fontWeight: FontWeight.w600,
    color: TinyTrailsColors.charcoal,
  );

  static TextStyle headlineMedium = GoogleFonts.inter(
    fontSize: 28,
    fontWeight: FontWeight.w600,
    color: TinyTrailsColors.charcoal,
  );

  static TextStyle headlineSmall = GoogleFonts.inter(
    fontSize: 24,
    fontWeight: FontWeight.w600,
    color: TinyTrailsColors.charcoal,
  );

  // Title Styles
  static TextStyle titleLarge = GoogleFonts.inter(
    fontSize: 22,
    fontWeight: FontWeight.w600,
    color: TinyTrailsColors.charcoal,
  );

  static TextStyle titleMedium = GoogleFonts.inter(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.15,
    color: TinyTrailsColors.charcoal,
  );

  static TextStyle titleSmall = GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.1,
    color: TinyTrailsColors.charcoal,
  );

  // Body Styles
  static TextStyle bodyLarge = GoogleFonts.inter(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.5,
    color: TinyTrailsColors.slateGray,
  );

  static TextStyle bodyMedium = GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.25,
    color: TinyTrailsColors.slateGray,
  );

  static TextStyle bodySmall = GoogleFonts.inter(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.4,
    color: TinyTrailsColors.gray500,
  );

  // Label Styles
  static TextStyle labelLarge = GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.1,
    color: TinyTrailsColors.charcoal,
  );

  static TextStyle labelMedium = GoogleFonts.inter(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.5,
    color: TinyTrailsColors.charcoal,
  );

  static TextStyle labelSmall = GoogleFonts.inter(
    fontSize: 11,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.5,
    color: TinyTrailsColors.gray500,
  );

  // Brand Logo Style
  static TextStyle brandLogo = GoogleFonts.inter(
    fontSize: 32,
    fontWeight: FontWeight.w800,
    letterSpacing: -1,
    color: TinyTrailsColors.charcoal,
  );

  // Button Text Styles
  static TextStyle buttonLarge = GoogleFonts.inter(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.5,
  );

  static TextStyle buttonMedium = GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.5,
  );
}

class TinyTrailsTheme {
  TinyTrailsTheme._();

  // Consumer Theme (Royal Blue)
  static ThemeData consumerTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    primaryColor: TinyTrailsColors.royalBlue,
    scaffoldBackgroundColor: TinyTrailsColors.white,
    colorScheme: const ColorScheme.light(
      primary: TinyTrailsColors.royalBlue,
      primaryContainer: TinyTrailsColors.royalBlue100,
      secondary: TinyTrailsColors.royalBlue400,
      secondaryContainer: TinyTrailsColors.royalBlue50,
      surface: TinyTrailsColors.white,
      error: TinyTrailsColors.error,
      onPrimary: TinyTrailsColors.white,
      onSecondary: TinyTrailsColors.white,
      onSurface: TinyTrailsColors.charcoal,
      onError: TinyTrailsColors.white,
    ),
    textTheme: _buildTextTheme(),
    appBarTheme: const AppBarTheme(
      backgroundColor: TinyTrailsColors.white,
      foregroundColor: TinyTrailsColors.charcoal,
      elevation: 0,
      centerTitle: true,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: TinyTrailsColors.royalBlue,
        foregroundColor: TinyTrailsColors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(50),
        ),
        textStyle: TinyTrailsTextStyles.buttonLarge,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: TinyTrailsColors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: TinyTrailsColors.gray200),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: TinyTrailsColors.gray200),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: TinyTrailsColors.royalBlue, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: TinyTrailsColors.error),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      labelStyle: TinyTrailsTextStyles.bodyMedium,
      hintStyle: TinyTrailsTextStyles.bodyMedium.copyWith(
        color: TinyTrailsColors.gray400,
      ),
    ),
  );

  // Vendor Theme (Emerald Green)
  static ThemeData vendorTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    primaryColor: TinyTrailsColors.emeraldGreen,
    scaffoldBackgroundColor: TinyTrailsColors.white,
    colorScheme: const ColorScheme.light(
      primary: TinyTrailsColors.emeraldGreen,
      primaryContainer: TinyTrailsColors.emerald100,
      secondary: TinyTrailsColors.emerald400,
      secondaryContainer: TinyTrailsColors.emerald50,
      surface: TinyTrailsColors.white,
      error: TinyTrailsColors.error,
      onPrimary: TinyTrailsColors.white,
      onSecondary: TinyTrailsColors.white,
      onSurface: TinyTrailsColors.charcoal,
      onError: TinyTrailsColors.white,
    ),
    textTheme: _buildTextTheme(),
    appBarTheme: const AppBarTheme(
      backgroundColor: TinyTrailsColors.white,
      foregroundColor: TinyTrailsColors.charcoal,
      elevation: 0,
      centerTitle: true,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: TinyTrailsColors.emeraldGreen,
        foregroundColor: TinyTrailsColors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(50),
        ),
        textStyle: TinyTrailsTextStyles.buttonLarge,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: TinyTrailsColors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: TinyTrailsColors.gray200),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: TinyTrailsColors.gray200),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: TinyTrailsColors.emeraldGreen, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: TinyTrailsColors.error),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      labelStyle: TinyTrailsTextStyles.bodyMedium,
      hintStyle: TinyTrailsTextStyles.bodyMedium.copyWith(
        color: TinyTrailsColors.gray400,
      ),
    ),
  );

  static TextTheme _buildTextTheme() {
    return TextTheme(
      displayLarge: TinyTrailsTextStyles.displayLarge,
      displayMedium: TinyTrailsTextStyles.displayMedium,
      displaySmall: TinyTrailsTextStyles.displaySmall,
      headlineLarge: TinyTrailsTextStyles.headlineLarge,
      headlineMedium: TinyTrailsTextStyles.headlineMedium,
      headlineSmall: TinyTrailsTextStyles.headlineSmall,
      titleLarge: TinyTrailsTextStyles.titleLarge,
      titleMedium: TinyTrailsTextStyles.titleMedium,
      titleSmall: TinyTrailsTextStyles.titleSmall,
      bodyLarge: TinyTrailsTextStyles.bodyLarge,
      bodyMedium: TinyTrailsTextStyles.bodyMedium,
      bodySmall: TinyTrailsTextStyles.bodySmall,
      labelLarge: TinyTrailsTextStyles.labelLarge,
      labelMedium: TinyTrailsTextStyles.labelMedium,
      labelSmall: TinyTrailsTextStyles.labelSmall,
    );
  }
}

/// Enum for user roles
enum UserRole {
  customer,
  vendor,
}

/// Extension to get role-specific colors
extension UserRoleColors on UserRole {
  Color get primaryColor {
    switch (this) {
      case UserRole.customer:
        return TinyTrailsColors.royalBlue;
      case UserRole.vendor:
        return TinyTrailsColors.emeraldGreen;
    }
  }

  Color get lightColor {
    switch (this) {
      case UserRole.customer:
        return TinyTrailsColors.royalBlue50;
      case UserRole.vendor:
        return TinyTrailsColors.emerald50;
    }
  }

  ThemeData get theme {
    switch (this) {
      case UserRole.customer:
        return TinyTrailsTheme.consumerTheme;
      case UserRole.vendor:
        return TinyTrailsTheme.vendorTheme;
    }
  }

  String get label {
    switch (this) {
      case UserRole.customer:
        return 'Customer';
      case UserRole.vendor:
        return 'Vendor';
    }
  }
}
