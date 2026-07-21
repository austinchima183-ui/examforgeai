import 'package:flutter/material.dart';

/// Centralized color definitions for ExamForge AI.
///
/// Provides both Material 3 [ColorScheme] instances generated from the brand
/// seed color and custom semantic / surface colors used throughout the app.
class AppColors {
  AppColors._();

  // ─── Brand Seed ───────────────────────────────────────────────────────────

  /// Primary brand seed – Indigo 600 (#4F46E5)
  static const Color seed = Color(0xFF4F46E5);

  // ─── Material 3 Color Schemes ─────────────────────────────────────────────

  /// Light color scheme derived from [seed].
  static final ColorScheme lightScheme = ColorScheme.fromSeed(
    seedColor: seed,
    brightness: Brightness.light,
  );

  /// Dark color scheme derived from [seed].
  static final ColorScheme darkScheme = ColorScheme.fromSeed(
    seedColor: seed,
    brightness: Brightness.dark,
  );

  // ─── Semantic Colors ──────────────────────────────────────────────────────

  // Success (Green)
  static const Color success = Color(0xFF16A34A);
  static const Color successLight = Color(0xFFDCFCE7);
  static const Color successDark = Color(0xFF166534);
  static const Color onSuccess = Color(0xFFFFFFFF);
  static const Color onSuccessDark = Color(0xFFDCFCE7);

  // Warning (Amber)
  // Note: #F59E0B fails AA contrast on white (1.9:1). Use warningOf(brightness)
  // which returns warningDark (#92400E) for light mode to ensure 4.5:1+.
  static const Color warning = Color(0xFFF59E0B);
  static const Color warningLight = Color(0xFFFEF3C7);
  static const Color warningDark = Color(0xFF92400E);
  static const Color onWarning = Color(0xFFFFFFFF);
  static const Color onWarningDark = Color(0xFFFEF3C7);

  // Error (Red)
  static const Color error = Color(0xFFDC2626);
  static const Color errorLight = Color(0xFFFEE2E2);
  static const Color errorDark = Color(0xFF991B1B);
  static const Color onError = Color(0xFFFFFFFF);
  static const Color onErrorDark = Color(0xFFFEE2E2);

  // Info (Blue)
  static const Color info = Color(0xFF2563EB);
  static const Color infoLight = Color(0xFFDBEAFE);
  static const Color infoDark = Color(0xFF1E3A8A);
  static const Color onInfo = Color(0xFFFFFFFF);
  static const Color onInfoDark = Color(0xFFDBEAFE);

  // ─── Custom Surface / Overlay Colors ──────────────────────────────────────

  // Light surfaces
  static const Color surfaceCardLight = Color(0xFFFFFFFF);
  static const Color surfaceOverlayLight = Color(0xCCFFFFFF); // 80 % white
  static const Color surfaceVariantLight = Color(0xFFF1F5F9);

  // Dark surfaces
  static const Color surfaceCardDark = Color(0xFF1E293B);
  static const Color surfaceOverlayDark = Color(0xCC1E293B); // 80 % dark
  static const Color surfaceVariantDark = Color(0xFF0F172A);

  // Scrim / barrier
  static const Color scrimLight = Color(0x52000000); // 32 % black
  static const Color scrimDark = Color(0x8A000000); // 54 % black

  // ─── Brand Gradient ───────────────────────────────────────────────────────

  static const LinearGradient brandGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF4F46E5), // Indigo 600
      Color(0xFF7C3AED), // Violet 600
    ],
  );

  static const LinearGradient brandGradientReversed = LinearGradient(
    begin: Alignment.bottomRight,
    end: Alignment.topLeft,
    colors: [
      Color(0xFF4F46E5),
      Color(0xFF7C3AED),
    ],
  );

  static const LinearGradient warmGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF4F46E5), // Indigo 600
      Color(0xFFEC4899), // Pink 500
    ],
  );

  static const LinearGradient coolGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF4F46E5), // Indigo 600
      Color(0xFF06B6D4), // Cyan 500
    ],
  );

  // ─── Utility Helpers ──────────────────────────────────────────────────────

  /// Returns the appropriate [ColorScheme] for the given [brightness].
  static ColorScheme schemeOf(Brightness brightness) {
    return brightness == Brightness.dark ? darkScheme : lightScheme;
  }

  /// Returns the success color variant appropriate for [brightness].
  static Color successOf(Brightness brightness) =>
      brightness == Brightness.dark ? successDark : success;

  /// Returns the warning color variant appropriate for [brightness].
  /// Uses warningDark for light mode to ensure WCAG AA contrast (4.5:1+).
  static Color warningOf(Brightness brightness) =>
      brightness == Brightness.dark ? warning : warningDark;

  /// Returns the error color variant appropriate for [brightness].
  static Color errorOf(Brightness brightness) =>
      brightness == Brightness.dark ? errorDark : error;

  /// Returns the info color variant appropriate for [brightness].
  static Color infoOf(Brightness brightness) =>
      brightness == Brightness.dark ? infoDark : info;

  /// Returns the on-success text color appropriate for [brightness].
  static Color onSuccessOf(Brightness brightness) =>
      brightness == Brightness.dark ? onSuccessDark : onSuccess;

  /// Returns the on-warning text color appropriate for [brightness].
  static Color onWarningOf(Brightness brightness) =>
      brightness == Brightness.dark ? onWarningDark : onWarning;

  /// Returns the on-error text color appropriate for [brightness].
  static Color onErrorOf(Brightness brightness) =>
      brightness == Brightness.dark ? onErrorDark : onError;

  /// Returns the on-info text color appropriate for [brightness].
  static Color onInfoOf(Brightness brightness) =>
      brightness == Brightness.dark ? onInfoDark : onInfo;

  /// Returns the success container (light bg) color for [brightness].
  static Color successContainerOf(Brightness brightness) =>
      brightness == Brightness.dark ? successDark.withOpacity(0.15) : successLight;

  /// Returns the warning container (light bg) color for [brightness].
  static Color warningContainerOf(Brightness brightness) =>
      brightness == Brightness.dark ? warningDark.withOpacity(0.15) : warningLight;

  /// Returns the error container (light bg) color for [brightness].
  static Color errorContainerOf(Brightness brightness) =>
      brightness == Brightness.dark ? errorDark.withOpacity(0.15) : errorLight;

  /// Returns the info container (light bg) color for [brightness].
  static Color infoContainerOf(Brightness brightness) =>
      brightness == Brightness.dark ? infoDark.withOpacity(0.15) : infoLight;
}
