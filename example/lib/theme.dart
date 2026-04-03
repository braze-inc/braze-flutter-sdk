import 'package:flutter/material.dart';

/// Matches color constants from the Braze React Native sample app.
abstract final class BrazeAppColors {

  // Updated from React Native's`0xFF801ED7` to distinguish the Flutter sample from
  // the React Native sample
  static const Color primary = Color(0xFF42A5F5);

  static const Color primaryDark = Color(0xFF300266);
  static const Color orange = Color(0xFFFFA524);
  static const Color pink = Color(0xFFFFA4FB);
  static const Color backgroundLight = Color(0xFFF9FAFB);
  static const Color backgroundGray = Color(0xFFF3F4F6);
  static const Color backgroundWhite = Color(0xFFFFFFFF);
  static const Color textDark = Color(0xFF111827);
  static const Color textMedium = Color(0xFF374151);
  static const Color textGray = Color(0xFF6B7280);
  static const Color textLight = Color(0xFFD1D5DB);
  static const Color textPlaceholder = Color(0xFF9CA3AF);
  static const Color secondary = Color(0xFF6B7280);
  static const Color danger = Color(0xFFFA003F);
  static const Color success = Color(0xFF008000);
  static const Color infoBackground = Color(0xFFEFF6FF);
  static const Color infoText = Color(0xFF1E40AF);
  static const Color borderGray = Color(0xFFD1D5DB);
}

/// Material 3 theme for the Braze sample app.
abstract final class BrazeAppTheme {
  static ThemeData get light {
    return ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: BrazeAppColors.primary,
        primary: BrazeAppColors.primary,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: BrazeAppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
      scaffoldBackgroundColor: BrazeAppColors.backgroundLight,
      useMaterial3: true,
    );
  }
}
