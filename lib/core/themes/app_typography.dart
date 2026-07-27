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

  static const TextTheme lightTextTheme = TextTheme(
    // Display
    displayLarge: TextStyle(
      fontFamily: fontFamily,
      fontSize: 57,
      fontWeight: wRegular,
      letterSpacing: lsDisplay,
      height: 1.12,
      color: Color(0xFF1A1A2E),
    ),
    displayMedium: TextStyle(
      fontFamily: fontFamily,
      fontSize: 45,
      fontWeight: wRegular,
      letterSpacing: lsDisplay,
      height: 1.16,
      color: Color(0xFF1A1A2E),
    ),
    displaySmall: TextStyle(
      fontFamily: fontFamily,
      fontSize: 36,
      fontWeight: wRegular,
      letterSpacing: 0.0,
      height: 1.22,
      color: Color(0xFF1A1A2E),
    ),

    // Headline
    headlineLarge: TextStyle(
      fontFamily: fontFamily,
      fontSize: 32,
      fontWeight: wSemiBold,
      letterSpacing: lsHeadline,
      height: 1.25,
      color: Color(0xFF1A1A2E),
    ),
    headlineMedium: TextStyle(
      fontFamily: fontFamily,
      fontSize: 28,
      fontWeight: wSemiBold,
      letterSpacing: lsHeadline,
      height: 1.29,
      color: Color(0xFF1A1A2E),
    ),
    headlineSmall: TextStyle(
      fontFamily: fontFamily,
      fontSize: 24,
      fontWeight: wSemiBold,
      letterSpacing: lsHeadline,
      height: 1.33,
      color: Color(0xFF1A1A2E),
    ),

    // Title
    titleLarge: TextStyle(
      fontFamily: fontFamily,
      fontSize: 22,
      fontWeight: wSemiBold,
      letterSpacing: lsTitle,
      height: 1.27,
      color: Color(0xFF1A1A2E),
    ),
    titleMedium: TextStyle(
      fontFamily: fontFamily,
      fontSize: 16,
      fontWeight: wMedium,
      letterSpacing: lsTitle,
      height: 1.50,
      color: Color(0xFF1A1A2E),
    ),
    titleSmall: TextStyle(
      fontFamily: fontFamily,
      fontSize: 14,
      fontWeight: wMedium,
      letterSpacing: lsTitle,
      height: 1.43,
      color: Color(0xFF1A1A2E),
    ),

    // Body
    bodyLarge: TextStyle(
      fontFamily: fontFamily,
      fontSize: 16,
      fontWeight: wRegular,
      letterSpacing: lsBody,
      height: 1.50,
      color: Color(0xFF374151),
    ),
    bodyMedium: TextStyle(
      fontFamily: fontFamily,
      fontSize: 14,
      fontWeight: wRegular,
      letterSpacing: lsBody,
      height: 1.43,
      color: Color(0xFF374151),
    ),
    bodySmall: TextStyle(
      fontFamily: fontFamily,
      fontSize: 12,
      fontWeight: wRegular,
      letterSpacing: lsBody,
      height: 1.33,
      color: Color(0xFF4B5563),
    ),

    // Label
    labelLarge: TextStyle(
      fontFamily: fontFamily,
      fontSize: 14,
      fontWeight: wSemiBold,
      letterSpacing: lsLabel,
      height: 1.43,
      color: Color(0xFF1A1A2E),
    ),
    labelMedium: TextStyle(
      fontFamily: fontFamily,
      fontSize: 12,
      fontWeight: wMedium,
      letterSpacing: lsLabel,
      height: 1.33,
      color: Color(0xFF4B5563),
    ),
    labelSmall: TextStyle(
      fontFamily: fontFamily,
      fontSize: 11,
      fontWeight: wMedium,
      letterSpacing: lsLabel,
      height: 1.45,
      color: Color(0xFF6B7280),
    ),
  );

  // ─── Dark Text Theme ──────────────────────────────────────────────────────

  static const TextTheme darkTextTheme = TextTheme(
    // Display
    displayLarge: TextStyle(
      fontFamily: fontFamily,
      fontSize: 57,
      fontWeight: wRegular,
      letterSpacing: lsDisplay,
      height: 1.12,
      color: Color(0xFFF9FAFB),
    ),
    displayMedium: TextStyle(
      fontFamily: fontFamily,
      fontSize: 45,
      fontWeight: wRegular,
      letterSpacing: lsDisplay,
      height: 1.16,
      color: Color(0xFFF9FAFB),
    ),
    displaySmall: TextStyle(
      fontFamily: fontFamily,
      fontSize: 36,
      fontWeight: wRegular,
      letterSpacing: 0.0,
      height: 1.22,
      color: Color(0xFFF9FAFB),
    ),

    // Headline
    headlineLarge: TextStyle(
      fontFamily: fontFamily,
      fontSize: 32,
      fontWeight: wSemiBold,
      letterSpacing: lsHeadline,
      height: 1.25,
      color: Color(0xFFF9FAFB),
    ),
    headlineMedium: TextStyle(
      fontFamily: fontFamily,
      fontSize: 28,
      fontWeight: wSemiBold,
      letterSpacing: lsHeadline,
      height: 1.29,
      color: Color(0xFFF9FAFB),
    ),
    headlineSmall: TextStyle(
      fontFamily: fontFamily,
      fontSize: 24,
      fontWeight: wSemiBold,
      letterSpacing: lsHeadline,
      height: 1.33,
      color: Color(0xFFF9FAFB),
    ),

    // Title
    titleLarge: TextStyle(
      fontFamily: fontFamily,
      fontSize: 22,
      fontWeight: wSemiBold,
      letterSpacing: lsTitle,
      height: 1.27,
      color: Color(0xFFF9FAFB),
    ),
    titleMedium: TextStyle(
      fontFamily: fontFamily,
      fontSize: 16,
      fontWeight: wMedium,
      letterSpacing: lsTitle,
      height: 1.50,
      color: Color(0xFFE5E7EB),
    ),
    titleSmall: TextStyle(
      fontFamily: fontFamily,
      fontSize: 14,
      fontWeight: wMedium,
      letterSpacing: lsTitle,
      height: 1.43,
      color: Color(0xFFE5E7EB),
    ),

    // Body
    bodyLarge: TextStyle(
      fontFamily: fontFamily,
      fontSize: 16,
      fontWeight: wRegular,
      letterSpacing: lsBody,
      height: 1.50,
      color: Color(0xFFD1D5DB),
    ),
    bodyMedium: TextStyle(
      fontFamily: fontFamily,
      fontSize: 14,
      fontWeight: wRegular,
      letterSpacing: lsBody,
      height: 1.43,
      color: Color(0xFFD1D5DB),
    ),
    bodySmall: TextStyle(
      fontFamily: fontFamily,
      fontSize: 12,
      fontWeight: wRegular,
      letterSpacing: lsBody,
      height: 1.33,
      color: Color(0xFF9CA3AF),
    ),

    // Label
    labelLarge: TextStyle(
      fontFamily: fontFamily,
      fontSize: 14,
      fontWeight: wSemiBold,
      letterSpacing: lsLabel,
      height: 1.43,
      color: Color(0xFFF9FAFB),
    ),
    labelMedium: TextStyle(
      fontFamily: fontFamily,
      fontSize: 12,
      fontWeight: wMedium,
      letterSpacing: lsLabel,
      height: 1.33,
      color: Color(0xFF9CA3AF),
    ),
    labelSmall: TextStyle(
      fontFamily: fontFamily,
      fontSize: 11,
      fontWeight: wMedium,
      letterSpacing: lsLabel,
      height: 1.45,
      color: Color(0xFF9CA3AF),
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

  // ─── Convenience Getters ────────────────────────────────────────────────────
  // Static getters that delegate to lightTextTheme so code can write
  // AppTypography.bodySmall instead of AppTypography.lightTextTheme.bodySmall.

  /// Convenience getter – delegates to [lightTextTheme.displayLarge].
  static TextStyle? get displayLarge => lightTextTheme.displayLarge;
  /// Convenience getter – delegates to [lightTextTheme.displayMedium].
  static TextStyle? get displayMedium => lightTextTheme.displayMedium;
  /// Convenience getter – delegates to [lightTextTheme.displaySmall].
  static TextStyle? get displaySmall => lightTextTheme.displaySmall;

  /// Convenience getter – delegates to [lightTextTheme.headlineLarge].
  static TextStyle? get headlineLarge => lightTextTheme.headlineLarge;
  /// Convenience getter – delegates to [lightTextTheme.headlineMedium].
  static TextStyle? get headlineMedium => lightTextTheme.headlineMedium;
  /// Convenience getter – delegates to [lightTextTheme.headlineSmall].
  static TextStyle? get headlineSmall => lightTextTheme.headlineSmall;

  /// Convenience getter – delegates to [lightTextTheme.titleLarge].
  static TextStyle? get titleLarge => lightTextTheme.titleLarge;
  /// Convenience getter – delegates to [lightTextTheme.titleMedium].
  static TextStyle? get titleMedium => lightTextTheme.titleMedium;
  /// Convenience getter – delegates to [lightTextTheme.titleSmall].
  static TextStyle? get titleSmall => lightTextTheme.titleSmall;

  /// Convenience getter – delegates to [lightTextTheme.bodyLarge].
  static TextStyle? get bodyLarge => lightTextTheme.bodyLarge;
  /// Convenience getter – delegates to [lightTextTheme.bodyMedium].
  static TextStyle? get bodyMedium => lightTextTheme.bodyMedium;
  /// Convenience getter – delegates to [lightTextTheme.bodySmall].
  static TextStyle? get bodySmall => lightTextTheme.bodySmall;

  /// Convenience getter – delegates to [lightTextTheme.labelLarge].
  static TextStyle? get labelLarge => lightTextTheme.labelLarge;
  /// Convenience getter – delegates to [lightTextTheme.labelMedium].
  static TextStyle? get labelMedium => lightTextTheme.labelMedium;
  /// Convenience getter – delegates to [lightTextTheme.labelSmall].
  static TextStyle? get labelSmall => lightTextTheme.labelSmall;

  // ─── Utility Helpers ──────────────────────────────────────────────────────

  /// Returns the appropriate [TextTheme] for the given [brightness].
  static TextTheme themeOf(Brightness brightness) {
    return brightness == Brightness.dark ? darkTextTheme : lightTextTheme;
  }
}


// ═══════════════════════════════════════════════════════════════════════════════
// FONTWEIGHT EXTENSION — Enables .copyWith() on FontWeight constants
// ═══════════════════════════════════════════════════════════════════════════════
//
// Code throughout the app calls AppTypography.wSemiBold.copyWith(fontSize: 13).
// FontWeight doesn't have copyWith — that's a TextStyle method. This extension
// converts the FontWeight to a TextStyle first, then provides copyWith().
//
// Usage:  AppTypography.wSemiBold.copyWith(fontSize: 13)
// Becomes: TextStyle(fontWeight: AppTypography.wSemiBold).copyWith(fontSize: 13)
// Which is: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)

/// Extension on [FontWeight] that provides [copyWith] by converting to [TextStyle].
///
/// This allows the common pattern:
/// ```dart
/// style: AppTypography.wSemiBold.copyWith(fontSize: 13, color: Colors.red)
/// ```
/// which is equivalent to:
/// ```dart
/// style: TextStyle(fontWeight: AppTypography.wSemiBold, fontSize: 13, color: Colors.red)
/// ```
extension FontWeightTextStyle on FontWeight {
  /// Converts this [FontWeight] to a [TextStyle] and calls [TextStyle.copyWith].
  ///
  /// All parameters are forwarded to [TextStyle.copyWith].
  TextStyle copyWith({
    Color? color,
    Color? backgroundColor,
    double? fontSize,
    FontWeight? fontWeight,
    FontStyle? fontStyle,
    double? letterSpacing,
    double? wordSpacing,
    TextBaseline? textBaseline,
    double? height,
    TextLeadingDistribution? leadingDistribution,
    Locale? locale,
    Paint? foreground,
    Paint? background,
    List<Shadow>? shadows,
    List<FontFeature>? fontFeatures,
    List<FontVariation>? fontVariations,
    TextDecoration? decoration,
    Color? decorationColor,
    TextDecorationStyle? decorationStyle,
    double? decorationThickness,
    String? debugLabel,
    String? fontFamily,
    List<String>? fontFamilyFallback,
    String? package,
    TextOverflow? overflow,
  }) {
    return TextStyle(
      fontWeight: this,
      // inherit defaults to true in TextStyle; only override when explicitly set
      // (omit when null so TextStyle uses its own default)
      color: color,
      backgroundColor: backgroundColor,
      fontSize: fontSize,
      fontStyle: fontStyle,
      letterSpacing: letterSpacing,
      wordSpacing: wordSpacing,
      textBaseline: textBaseline,
      height: height,
      leadingDistribution: leadingDistribution,
      locale: locale,
      foreground: foreground,
      background: background,
      shadows: shadows,
      fontFeatures: fontFeatures,
      fontVariations: fontVariations,
      decoration: decoration,
      decorationColor: decorationColor,
      decorationStyle: decorationStyle,
      decorationThickness: decorationThickness,
      debugLabel: debugLabel,
      fontFamily: fontFamily,
      fontFamilyFallback: fontFamilyFallback,
      package: package,
      overflow: overflow,
    );
  }
}
