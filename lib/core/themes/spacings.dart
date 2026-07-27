import 'package:flutter/material.dart';

/// Design-token spacing, radius, elevation, and icon-size constants.
///
/// All values are in logical pixels and follow a consistent 4 px base grid.
/// Use these tokens everywhere instead of hard-coded numbers to keep the UI
/// visually uniform and easy to update globally.
class Spacings {
  Spacings._();

  // ─── Spacing Scale ────────────────────────────────────────────────────────

  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double xl = 24.0;
  static const double xxl = 32.0;
  static const double xxxl = 48.0;

  // ─── Border Radius ────────────────────────────────────────────────────────

  static const double smRadius = 8.0;
  static const double mdRadius = 12.0;
  static const double lgRadius = 16.0;
  static const double xlRadius = 24.0;
  static const double fullRadius = 9999.0;

  /// Pre-built [BorderRadius] instances for common use-cases.

  static const BorderRadius borderRadiusSm = BorderRadius.all(
    Radius.circular(smRadius),
  );
  static const BorderRadius borderRadiusMd = BorderRadius.all(
    Radius.circular(mdRadius),
  );
  static const BorderRadius borderRadiusLg = BorderRadius.all(
    Radius.circular(lgRadius),
  );
  static const BorderRadius borderRadiusXl = BorderRadius.all(
    Radius.circular(xlRadius),
  );
  static const BorderRadius borderRadiusFull = BorderRadius.all(
    Radius.circular(fullRadius),
  );

  // ─── Elevation ────────────────────────────────────────────────────────────

  static const double elevationNone = 0.0;
  static const double elevationSm = 1.0;
  static const double elevationMd = 2.0;
  static const double elevationLg = 4.0;
  static const double elevationXl = 8.0;

  // ─── Icon Sizes ───────────────────────────────────────────────────────────

  static const double smIcon = 16.0;
  static const double mdIcon = 24.0;
  static const double lgIcon = 32.0;
  static const double xlIcon = 48.0;

  // ─── Common EdgeInsets Helpers ────────────────────────────────────────────
  // These reduce boilerplate for frequently-used padding configurations.

  /// Horizontal padding equal to [lg] (typical screen gutters).
  static const EdgeInsets paddingH = EdgeInsets.symmetric(horizontal: lg);

  /// All-side padding equal to [lg].
  static const EdgeInsets paddingAll = EdgeInsets.all(lg);

  /// All-side padding equal to [md].
  static const EdgeInsets paddingAllMd = EdgeInsets.all(md);

  /// Symmetric horizontal [xl] and vertical [lg] (e.g. button interiors).
  static const EdgeInsets paddingButton = EdgeInsets.symmetric(
    horizontal: xl,
    vertical: lg,
  );

  /// Symmetric horizontal [lg] and vertical [md] (e.g. input interiors).
  static const EdgeInsets paddingInput = EdgeInsets.symmetric(
    horizontal: lg,
    vertical: md,
  );

  /// Screen-edge padding for cards/lists.
  static const EdgeInsets paddingScreen = EdgeInsets.symmetric(
    horizontal: lg,
    vertical: md,
  );

  /// Card content padding.
  static const EdgeInsets paddingCard = EdgeInsets.all(lg);

  /// Section-level vertical gap.
  static const SizedBox sectionGap = SizedBox(height: xxl);

  /// Item-level vertical gap.
  static const SizedBox itemGap = SizedBox(height: md);

  /// Small vertical gap.
  static const SizedBox smallGap = SizedBox(height: sm);

  /// Horizontal gap between icon and text.
  static const SizedBox inlineGap = SizedBox(width: sm);
}
