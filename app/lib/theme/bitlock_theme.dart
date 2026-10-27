import 'package:flutter/material.dart';

/// Colour palette for the BitLock design system.
///
/// Dark-and-purple is the primary identity: a deep navy background,
/// violet as the action colour, and restrained semantic colours for
/// status. Every value here is a plain colour choice — none of them
/// implies a security property.
abstract final class BitLockColors {
  /// Deep navy app background.
  static const Color background = Color(0xFF0E0B1E);

  /// Slightly lifted background used for sheets and dialogs.
  static const Color backgroundElevated = Color(0xFF171230);

  /// Card and list surface colour on the dark background.
  static const Color surface = Color(0xFF1B1533);

  /// Higher-emphasis surface (selected rows, input fills).
  static const Color surfaceVariant = Color(0xFF26204A);

  /// Primary violet used for buttons and highlights.
  static const Color primary = Color(0xFF7C4DFF);

  /// Lighter violet used for accents and secondary highlights.
  static const Color primaryLight = Color(0xFF8B5CF6);

  /// Accent teal used sparingly for positive, factual status.
  static const Color accent = Color(0xFF2DD4BF);

  /// Primary text colour on dark surfaces.
  static const Color textPrimary = Color(0xFFF3F0FF);

  /// Secondary text colour on dark surfaces.
  static const Color textSecondary = Color(0xFFB8B0D9);

  /// Error colour for failures and destructive actions.
  static const Color error = Color(0xFFFF6B81);

  /// Success colour for confirmed, completed actions.
  static const Color success = Color(0xFF4ADE80);

  /// Warning colour for caution states (expiry, limits).
  static const Color warning = Color(0xFFFBBF24);

  /// Divider and outline colour on dark surfaces.
  static const Color outline = Color(0xFF3A3163);

  /// Light-theme background.
  static const Color lightBackground = Color(0xFFF6F4FF);

  /// Light-theme surface.
  static const Color lightSurface = Color(0xFFFFFFFF);

  /// Light-theme primary text.
  static const Color lightTextPrimary = Color(0xFF1B1533);

  /// Light-theme secondary text.
  static const Color lightTextSecondary = Color(0xFF5B5478);
}

/// Builds the [ThemeData] for BitLock in dark and light variants.
abstract final class BitLockTheme {
  /// The primary dark-and-purple theme.
  static ThemeData dark() {
    const ColorScheme scheme = ColorScheme.dark(
      primary: BitLockColors.primary,
      onPrimary: Colors.white,
      secondary: BitLockColors.primaryLight,
      onSecondary: Colors.white,
      tertiary: BitLockColors.accent,
      error: BitLockColors.error,
      onError: Colors.white,
      surface: BitLockColors.surface,
      onSurface: BitLockColors.textPrimary,
      onSurfaceVariant: BitLockColors.textSecondary,
      outline: BitLockColors.outline,
    );
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: scheme,
      scaffoldBackgroundColor: BitLockColors.background,
      appBarTheme: const AppBarTheme(
        backgroundColor: BitLockColors.background,
        foregroundColor: BitLockColors.textPrimary,
        elevation: 0,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        color: BitLockColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: BitLockColors.outline),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: BitLockColors.surfaceVariant,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: BitLockColors.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: BitLockColors.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: BitLockColors.primaryLight,
            width: 1.6,
          ),
        ),
        labelStyle: const TextStyle(color: BitLockColors.textSecondary),
        hintStyle: const TextStyle(color: BitLockColors.textSecondary),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: BitLockColors.primary,
          foregroundColor: Colors.white,
          minimumSize: const Size(0, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: BitLockColors.textPrimary,
          minimumSize: const Size(0, 52),
          side: const BorderSide(color: BitLockColors.outline),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: BitLockColors.surfaceVariant,
        selectedColor: BitLockColors.primary,
        labelStyle: const TextStyle(color: BitLockColors.textPrimary),
        side: const BorderSide(color: BitLockColors.outline),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: BitLockColors.backgroundElevated,
        indicatorColor: BitLockColors.primary.withValues(alpha: 0.35),
        labelTextStyle: WidgetStateProperty.all(
          const TextStyle(fontSize: 12),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: BitLockColors.surfaceVariant,
        contentTextStyle: const TextStyle(
          color: BitLockColors.textPrimary,
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: BitLockColors.backgroundElevated,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: BitLockColors.outline,
        thickness: 1,
      ),
      listTileTheme: const ListTileThemeData(
        iconColor: BitLockColors.primaryLight,
        textColor: BitLockColors.textPrimary,
      ),
    );
  }

  /// A minimal light counterpart, used when the user turns the dark
  /// theme off in Settings.
  static ThemeData light() {
    const ColorScheme scheme = ColorScheme.light(
      primary: BitLockColors.primary,
      onPrimary: Colors.white,
      secondary: BitLockColors.primaryLight,
      onSecondary: Colors.white,
      error: BitLockColors.error,
      surface: BitLockColors.lightSurface,
      onSurface: BitLockColors.lightTextPrimary,
      onSurfaceVariant: BitLockColors.lightTextSecondary,
    );
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: scheme,
      scaffoldBackgroundColor: BitLockColors.lightBackground,
      appBarTheme: const AppBarTheme(
        backgroundColor: BitLockColors.lightBackground,
        foregroundColor: BitLockColors.lightTextPrimary,
        elevation: 0,
      ),
      cardTheme: CardThemeData(
        color: BitLockColors.lightSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.grey.shade300),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: BitLockColors.primary,
            width: 1.6,
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: BitLockColors.primary,
          foregroundColor: Colors.white,
          minimumSize: const Size(0, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.white,
        indicatorColor: BitLockColors.primary.withValues(alpha: 0.2),
      ),
    );
  }
}
