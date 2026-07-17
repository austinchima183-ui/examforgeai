import 'package:flutter/material.dart';

/// Typography system for ExamForge AI.
///
/// All styles use the **Inter** font family loaded from `assets/fonts/`.
/// Both light and dark text themes are provided. Custom styles extend the
/// Material 3 type scale with project-specific use-cases.
class AppTypography {
  AppTypography._();

  // ─── Font Family ──────────────────────────────────────────────────────────

  static const String fontFamily = 'Inter';

  // ─── Font Weights ─────────────────────────────────────────────────────────

  static const FontWeight wRegular = FontWeight.w400;
  static const FontWeight wMedium = FontWeight.w500;
  static const FontWeight wSemiBold = FontWeight.w600;
  static const FontWeight wBold = FontWeight.w700;

  // ─── Letter Spacing ───────────────────────────────────────────────────────
  // Material 3 spec defaults expressed as logical pixels.

  static const double lsDisplay = -0.25;
  static const double lsHeadline = 0.0;
  static const double lsTitle = 0.0;
  static const double lsBody = 0.5;
  static const double lsLabel = 0.5;
  static const double lsCaption = 0.4;
  static const double lsOverline = 0.5;
  static const double lsButton = 0.1;

  // ─── Light Text Theme ─────────────────────────────────────────────────────

  static final TextTheme lightTextTheme = TextTheme(
    // Display
    displayLarge: TextStyle(
      fontFamily: fontFamily,
      fontSize: 57,
      fontWeight: wRegular,
      letterSpacing: lsDisplay,
      height: 1.12,
      color: const Color(0xFF1A1A2E),
    ),
    displayMedium: TextStyle(
      fontFamily: fontFamily,
      fontSize: 45,
      fontWeight: wRegular,
      letterSpacing: lsDisplay,
      height: 1.16,
      color: const Color(0xFF1A1A2E),
    ),
    displaySmall: TextStyle(
      fontFamily: fontFamily,
      fontSize: 36,
      fontWeight: wRegular,
      letterSpacing: 0.0,
      height: 1.22,
      color: const Color(0xFF1A1A2E),
    ),

    // Headline
    headlineLarge: TextStyle(
      fontFamily: fontFamily,
      fontSize: 32,
      fontWeight: wSemiBold,
      letterSpacing: lsHeadline,
      height: 1.25,
      color: const Color(0xFF1A1A2E),
    ),
    headlineMedium: TextStyle(
      fontFamily: fontFamily,
      fontSize: 28,
      fontWeight: wSemiBold,
      letterSpacing: lsHeadline,
      height: 1.29,
      color: const Color(0xFF1A1A2E),
    ),
    headlineSmall: TextStyle(
      fontFamily: fontFamily,
      fontSize: 24,
      fontWeight: wSemiBold,
      letterSpacing: lsHeadline,
      height: 1.33,
      color: const Color(0xFF1A1A2E),
    ),

    // Title
    titleLarge: TextStyle(
      fontFamily: fontFamily,
      fontSize: 22,
      fontWeight: wSemiBold,
      letterSpacing: lsTitle,
      height: 1.27,
      color: const Color(0xFF1A1A2E),
    ),
    titleMedium: TextStyle(
      fontFamily: fontFamily,
      fontSize: 16,
      fontWeight: wMedium,
      letterSpacing: lsTitle,
      height: 1.50,
      color: const Color(0xFF1A1A2E),
    ),
    titleSmall: TextStyle(
      fontFamily: fontFamily,
      fontSize: 14,
      fontWeight: wMedium,
      letterSpacing: lsTitle,
      height: 1.43,
      color: const Color(0xFF1A1A2E),
    ),

    // Body
    bodyLarge: TextStyle(
      fontFamily: fontFamily,
      fontSize: 16,
      fontWeight: wRegular,
      letterSpacing: lsBody,
      height: 1.50,
      color: const Color(0xFF374151),
    ),
    bodyMedium: TextStyle(
      fontFamily: fontFamily,
      fontSize: 14,
      fontWeight: wRegular,
      letterSpacing: lsBody,
      height: 1.43,
      color: const Color(0xFF374151),
    ),
    bodySmall: TextStyle(
      fontFamily: fontFamily,
      fontSize: 12,
      fontWeight: wRegular,
      letterSpacing: lsBody,
      height: 1.33,
      color: const Color(0xFF4B5563),
    ),

    // Label
    labelLarge: TextStyle(
      fontFamily: fontFamily,
      fontSize: 14,
      fontWeight: wSemiBold,
      letterSpacing: lsLabel,
      height: 1.43,
      color: const Color(0xFF1A1A2E),
    ),
    labelMedium: TextStyle(
      fontFamily: fontFamily,
      fontSize: 12,
      fontWeight: wMedium,
      letterSpacing: lsLabel,
      height: 1.33,
      color: const Color(0xFF4B5563),
    ),
    labelSmall: TextStyle(
      fontFamily: fontFamily,
      fontSize: 11,
      fontWeight: wMedium,
      letterSpacing: lsLabel,
      height: 1.45,
      color: const Color(0xFF6B7280),
    ),
  );

  // ─── Dark Text Theme ──────────────────────────────────────────────────────

  static final TextTheme darkTextTheme = TextTheme(
    // Display
    displayLarge: TextStyle(
      fontFamily: fontFamily,
      fontSize: 57,
      fontWeight: wRegular,
      letterSpacing: lsDisplay,
      height: 1.12,
      color: const Color(0xFFF9FAFB),
    ),
    displayMedium: TextStyle(
      fontFamily: fontFamily,
      fontSize: 45,
      fontWeight: wRegular,
      letterSpacing: lsDisplay,
      height: 1.16,
      color: const Color(0xFFF9FAFB),
    ),
    displaySmall: TextStyle(
      fontFamily: fontFamily,
      fontSize: 36,
      fontWeight: wRegular,
      letterSpacing: 0.0,
      height: 1.22,
      color: const Color(0xFFF9FAFB),
    ),

    // Headline
    headlineLarge: TextStyle(
      fontFamily: fontFamily,
      fontSize: 32,
      fontWeight: wSemiBold,
      letterSpacing: lsHeadline,
      height: 1.25,
      color: const Color(0xFFF9FAFB),
    ),
    headlineMedium: TextStyle(
      fontFamily: fontFamily,
      fontSize: 28,
      fontWeight: wSemiBold,
      letterSpacing: lsHeadline,
      height: 1.29,
      color: const Color(0xFFF9FAFB),
    ),
    headlineSmall: TextStyle(
      fontFamily: fontFamily,
      fontSize: 24,
      fontWeight: wSemiBold,
      letterSpacing: lsHeadline,
      height: 1.33,
      color: const Color(0xFFF9FAFB),
    ),

    // Title
    titleLarge: TextStyle(
      fontFamily: fontFamily,
      fontSize: 22,
      fontWeight: wSemiBold,
      letterSpacing: lsTitle,
      height: 1.27,
      color: const Color(0xFFF9FAFB),
    ),
    titleMedium: TextStyle(
      fontFamily: fontFamily,
      fontSize: 16,
      fontWeight: wMedium,
      letterSpacing: lsTitle,
      height: 1.50,
      color: const Color(0xFFE5E7EB),
    ),
    titleSmall: TextStyle(
      fontFamily: fontFamily,
      fontSize: 14,
      fontWeight: wMedium,
      letterSpacing: lsTitle,
      height: 1.43,
      color: const Color(0xFFE5E7EB),
    ),

    // Body
    bodyLarge: TextStyle(
      fontFamily: fontFamily,
      fontSize: 16,
      fontWeight: wRegular,
      letterSpacing: lsBody,
      height: 1.50,
      color: const Color(0xFFD1D5DB),
    ),
    bodyMedium: TextStyle(
      fontFamily: fontFamily,
      fontSize: 14,
      fontWeight: wRegular,
      letterSpacing: lsBody,
      height: 1.43,
      color: const Color(0xFFD1D5DB),
    ),
    bodySmall: TextStyle(
      fontFamily: fontFamily,
      fontSize: 12,
      fontWeight: wRegular,
      letterSpacing: lsBody,
      height: 1.33,
      color: const Color(0xFF9CA3AF),
    ),

    // Label
    labelLarge: TextStyle(
      fontFamily: fontFamily,
      fontSize: 14,
      fontWeight: wSemiBold,
      letterSpacing: lsLabel,
      height: 1.43,
      color: const Color(0xFFF9FAFB),
    ),
    labelMedium: TextStyle(
      fontFamily: fontFamily,
      fontSize: 12,
      fontWeight: wMedium,
      letterSpacing: lsLabel,
      height: 1.33,
      color: const Color(0xFF9CA3AF),
    ),
    labelSmall: TextStyle(
      fontFamily: fontFamily,
      fontSize: 11,
      fontWeight: wMedium,
      letterSpacing: lsLabel,
      height: 1.45,
      color: const Color(0xFF9CA3AF),
    ),
  );

  // ─── Custom Styles ────────────────────────────────────────────────────────
  // Project-specific text styles that sit outside the standard Material 3
  // scale. These use the same [fontFamily] and follow the same design tokens.

  /// Caption – small secondary text (below [bodySmall] in hierarchy).
  static const TextStyle caption = TextStyle(
    fontFamily: fontFamily,
    fontSize: 10,
    fontWeight: wRegular,
    letterSpacing: lsCaption,
    height: 1.40,
  );

  /// Overline – small all-caps label typically used above a title.
  static const TextStyle overline = TextStyle(
    fontFamily: fontFamily,
    fontSize: 10,
    fontWeight: wSemiBold,
    letterSpacing: lsOverline,
    height: 1.60,
  );

  /// Button – primary button text style.
  static const TextStyle button = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    fontWeight: wSemiBold,
    letterSpacing: lsButton,
    height: 1.43,
  );

  /// Button small – compact / dense button text.
  static const TextStyle buttonSmall = TextStyle(
    fontFamily: fontFamily,
    fontSize: 12,
    fontWeight: wSemiBold,
    letterSpacing: lsButton,
    height: 1.33,
  );

  /// Navigation label – used in bottom nav bars and rail destinations.
  static const TextStyle navLabel = TextStyle(
    fontFamily: fontFamily,
    fontSize: 12,
    fontWeight: wMedium,
    letterSpacing: lsLabel,
    height: 1.33,
  );

  // ─── Utility Helpers ──────────────────────────────────────────────────────

  /// Returns the appropriate [TextTheme] for the given [brightness].
  static TextTheme themeOf(Brightness brightness) {
    return brightness == Brightness.dark ? darkTextTheme : lightTextTheme;
  }
}
