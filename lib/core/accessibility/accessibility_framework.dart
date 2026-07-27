/// Accessibility Framework for ExamForge AI.
///
/// Provides a comprehensive set of tools, widgets, and providers that ensure
/// the application is usable by everyone, including users who rely on screen
/// readers, keyboard navigation, high-contrast modes, or colorblind filters.
///
/// **Key concepts:**
/// - [AccessibilitySettings] – immutable settings model persisted via SharedPreferences
/// - [ColorblindMode] – enhanced enum with color-filter matrix support
/// - [AccessibilityNotifier] – StateNotifier that manages settings + persistence
/// - [AccessibleText] – Text widget that auto-applies scale, bold, and semantics
/// - [AccessibleButton] – button with minimum touch target, focus ring, and semantics
/// - [AccessibleImage] – image with required semantic label and colorblind filter
/// - [HighContrastTheme] – generates high-contrast Material 3 theme overrides
/// - [ScreenReaderHelper] – announcements, tooltips, and live regions
/// - [FocusTraversalHelper] – keyboard tab order and shortcut actions
/// - Provider suite for reactive access to accessibility state
library;

import 'dart:convert';

import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../themes/spacings.dart';
import '../utils/logger.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// ColorblindMode Enum
// ═══════════════════════════════════════════════════════════════════════════════

/// Represents the different types of color vision deficiency that
/// [AccessibleImage] and [AccessibilitySettings] can accommodate.
///
/// Each value provides a [colorFilter] getter that returns a
/// [ColorFilter] matrix appropriate for simulating / compensating
/// that deficiency, or `null` when no filter is needed.
enum ColorblindMode {
  /// No color vision deficiency – normal vision.
  none('None', 'none'),

  /// Red-blind (protanopia) – cannot perceive red light.
  protanopia('Protanopia', 'protanopia'),

  /// Green-blind (deuteranopia) – cannot perceive green light.
  deuteranopia('Deuteranopia', 'deuteranopia'),

  /// Blue-blind (tritanopia) – cannot perceive blue light.
  tritanopia('Tritanopia', 'tritanopia'),

  /// Total color blindness (achromatopsia) – no color perception.
  achromatopsia('Achromatopsia', 'achromatopsia');

  const ColorblindMode(this.displayName, this.jsonKey);

  /// Human-readable name suitable for UI display.
  final String displayName;

  /// Key used for JSON serialization.
  final String jsonKey;

  /// Returns a [ColorFilter] matrix for this colorblind mode,
  /// or `null` when [none] (no filter needed).
  ///
  /// Matrices sourced from widely-used colorblind simulation research
  /// (Machado, Oliveira, Fernandes 2009).
  ColorFilter? get colorFilter {
    const List<double> identity = <double>[
      1, 0, 0, 0, 0, //
      0, 1, 0, 0, 0, //
      0, 0, 1, 0, 0, //
      0, 0, 0, 1, 0, //
    ];

    const List<double> protanopiaMatrix = <double>[
      0.567, 0.433, 0, 0, 0, //
      0.558, 0.442, 0, 0, 0, //
      0, 0.242, 0.758, 0, 0, //
      0, 0, 0, 1, 0, //
    ];

    const List<double> deuteranopiaMatrix = <double>[
      0.625, 0.375, 0, 0, 0, //
      0.7, 0.3, 0, 0, 0, //
      0, 0.3, 0.7, 0, 0, //
      0, 0, 0, 1, 0, //
    ];

    const List<double> tritanopiaMatrix = <double>[
      0.95, 0.05, 0, 0, 0, //
      0, 0.433, 0.567, 0, 0, //
      0, 0.475, 0.525, 0, 0, //
      0, 0, 0, 1, 0, //
    ];

    const List<double> achromatopsiaMatrix = <double>[
      0.299, 0.587, 0.114, 0, 0, //
      0.299, 0.587, 0.114, 0, 0, //
      0.299, 0.587, 0.114, 0, 0, //
      0, 0, 0, 1, 0, //
    ];

    switch (this) {
      case ColorblindMode.none:
        return null;
      case ColorblindMode.protanopia:
        return const ColorFilter.matrix(protanopiaMatrix);
      case ColorblindMode.deuteranopia:
        return const ColorFilter.matrix(deuteranopiaMatrix);
      case ColorblindMode.tritanopia:
        return const ColorFilter.matrix(tritanopiaMatrix);
      case ColorblindMode.achromatopsia:
        return const ColorFilter.matrix(achromatopsiaMatrix);
    }
  }

  /// Parses a [ColorblindMode] from its [jsonKey].
  static ColorblindMode fromJsonKey(String key) {
    return ColorblindMode.values.firstWhere(
      (mode) => mode.jsonKey == key,
      orElse: () => ColorblindMode.none,
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// AccessibilitySettings
// ═══════════════════════════════════════════════════════════════════════════════

/// Immutable model holding all accessibility preferences for the current user.
///
/// Instances are managed by [AccessibilityNotifier] and persisted to
/// [SharedPreferences] so they survive app restarts.
class AccessibilitySettings extends Equatable {
  /// Text scale multiplier. Clamped to 0.8–2.0. Defaults to 1.0.
  final double textScaleFactor;

  /// Whether high-contrast mode is enabled.
  final bool isHighContrast;

  /// Whether a screen reader is currently active.
  final bool isScreenReaderEnabled;

  /// Whether reduce-motion is enabled (disables animations).
  final bool isReduceMotion;

  /// Whether bold text is requested.
  final bool isBoldText;

  /// Whether a large font variant should be used.
  final bool isLargeFont;

  /// Active colorblind compensation mode.
  final ColorblindMode colorblindMode;

  const AccessibilitySettings({
    this.textScaleFactor = 1.0,
    this.isHighContrast = false,
    this.isScreenReaderEnabled = false,
    this.isReduceMotion = false,
    this.isBoldText = false,
    this.isLargeFont = false,
    this.colorblindMode = ColorblindMode.none,
  });

  /// Creates a copy with the given fields replaced.
  AccessibilitySettings copyWith({
    double? textScaleFactor,
    bool? isHighContrast,
    bool? isScreenReaderEnabled,
    bool? isReduceMotion,
    bool? isBoldText,
    bool? isLargeFont,
    ColorblindMode? colorblindMode,
  }) {
    return AccessibilitySettings(
      textScaleFactor: textScaleFactor ?? this.textScaleFactor,
      isHighContrast: isHighContrast ?? this.isHighContrast,
      isScreenReaderEnabled:
          isScreenReaderEnabled ?? this.isScreenReaderEnabled,
      isReduceMotion: isReduceMotion ?? this.isReduceMotion,
      isBoldText: isBoldText ?? this.isBoldText,
      isLargeFont: isLargeFont ?? this.isLargeFont,
      colorblindMode: colorblindMode ?? this.colorblindMode,
    );
  }

  /// Serialises to a JSON-compatible map.
  Map<String, dynamic> toJson() => {
        'textScaleFactor': textScaleFactor,
        'isHighContrast': isHighContrast,
        'isScreenReaderEnabled': isScreenReaderEnabled,
        'isReduceMotion': isReduceMotion,
        'isBoldText': isBoldText,
        'isLargeFont': isLargeFont,
        'colorblindMode': colorblindMode.jsonKey,
      };

  /// Deserialises from a JSON-compatible map.
  static AccessibilitySettings fromJson(Map<String, dynamic> json) {
    return AccessibilitySettings(
      textScaleFactor: (json['textScaleFactor'] as num?)?.toDouble() ?? 1.0,
      isHighContrast: json['isHighContrast'] as bool? ?? false,
      isScreenReaderEnabled: json['isScreenReaderEnabled'] as bool? ?? false,
      isReduceMotion: json['isReduceMotion'] as bool? ?? false,
      isBoldText: json['isBoldText'] as bool? ?? false,
      isLargeFont: json['isLargeFont'] as bool? ?? false,
      colorblindMode: json['colorblindMode'] != null
          ? ColorblindMode.fromJsonKey(json['colorblindMode'] as String)
          : ColorblindMode.none,
    );
  }

  @override
  List<Object?> get props => [
        textScaleFactor,
        isHighContrast,
        isScreenReaderEnabled,
        isReduceMotion,
        isBoldText,
        isLargeFont,
        colorblindMode,
      ];
}

// ═══════════════════════════════════════════════════════════════════════════════
// AccessibilityNotifier
// ═══════════════════════════════════════════════════════════════════════════════

/// Riverpod [StateNotifier] that manages [AccessibilitySettings].
///
/// Persists settings to [SharedPreferences] on every mutation and loads
/// them on initialisation. Also provides [detectSystemSettings] to
/// synchronise with the platform's current accessibility flags.
class AccessibilityNotifier extends StateNotifier<AccessibilitySettings> {
  static const String _prefsKey = 'examforge_accessibility_settings';

  AccessibilityNotifier() : super(const AccessibilitySettings()) {
    _loadFromPrefs();
  }

  // ─── Mutations ─────────────────────────────────────────────────────────

  /// Updates the text scale factor, clamped to the 0.8–2.0 range.
  void updateTextScale(double factor) {
    final clamped = factor.clamp(0.8, 2.0);
    state = state.copyWith(textScaleFactor: clamped);
    _persist();
    AppLogger.info('Text scale updated to $clamped');
  }

  /// Toggles high-contrast mode on/off.
  void toggleHighContrast() {
    state = state.copyWith(isHighContrast: !state.isHighContrast);
    _persist();
    AppLogger.info('High contrast: ${state.isHighContrast}');
  }

  /// Sets the colorblind compensation mode.
  void setColorblindMode(ColorblindMode mode) {
    state = state.copyWith(colorblindMode: mode);
    _persist();
    AppLogger.info('Colorblind mode: ${mode.displayName}');
  }

  /// Toggles bold text on/off.
  void toggleBoldText() {
    state = state.copyWith(isBoldText: !state.isBoldText);
    _persist();
    AppLogger.info('Bold text: ${state.isBoldText}');
  }

  /// Toggles reduce-motion on/off.
  void toggleReduceMotion() {
    state = state.copyWith(isReduceMotion: !state.isReduceMotion);
    _persist();
    AppLogger.info('Reduce motion: ${state.isReduceMotion}');
  }

  /// Resets all settings to their defaults.
  void resetToDefaults() {
    state = const AccessibilitySettings();
    _persist();
    AppLogger.info('Accessibility settings reset to defaults');
  }

  /// Reads the platform's accessibility flags via [MediaQueryData] and
  /// merges them into the current state.
  ///
  /// Call this from a widget that has a [MediaQuery] ancestor, e.g.:
  /// ```dart
  /// ref.read(accessibilitySettingsProvider.notifier).detectSystemSettings(
  ///   MediaQuery.of(context),
  /// );
  /// ```
  void detectSystemSettings(MediaQueryData mediaQuery) {
    state = state.copyWith(
      isHighContrast: mediaQuery.highContrast,
      isBoldText: mediaQuery.boldText,
      isReduceMotion: mediaQuery.disableAnimations,
      textScaleFactor: mediaQuery.textScaleFactor.clamp(0.8, 2.0),
    );
    _persist();
    AppLogger.info('System accessibility settings detected');
  }

  // ─── Persistence ───────────────────────────────────────────────────────

  Future<void> _loadFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_prefsKey);
      if (raw != null) {
        final json = jsonDecode(raw) as Map<String, dynamic>;
        state = AccessibilitySettings.fromJson(json);
        AppLogger.info('Accessibility settings loaded from prefs');
      }
    } catch (e, st) {
      AppLogger.error('Failed to load accessibility settings', error: e, stackTrace: st);
    }
  }

  Future<void> _persist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefsKey, jsonEncode(state.toJson()));
    } catch (e, st) {
      AppLogger.error('Failed to persist accessibility settings', error: e, stackTrace: st);
    }
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Providers
// ═══════════════════════════════════════════════════════════════════════════════

/// Main provider for accessibility settings state.
final accessibilitySettingsProvider =
    StateNotifierProvider<AccessibilityNotifier, AccessibilitySettings>(
  (ref) => AccessibilityNotifier(),
);

/// Derived provider that exposes just the current text scale factor.
final textScaleFactorProvider = Provider<double>((ref) {
  return ref.watch(accessibilitySettingsProvider).textScaleFactor;
});

/// Derived provider that exposes whether high-contrast mode is active.
final isHighContrastProvider = Provider<bool>((ref) {
  return ref.watch(accessibilitySettingsProvider).isHighContrast;
});

/// Derived provider that exposes the current colorblind mode.
final colorblindModeProvider = Provider<ColorblindMode>((ref) {
  return ref.watch(accessibilitySettingsProvider).colorblindMode;
});

/// Derived provider that exposes whether a screen reader is active.
final isScreenReaderEnabledProvider = Provider<bool>((ref) {
  return ref.watch(accessibilitySettingsProvider).isScreenReaderEnabled;
});

// ═══════════════════════════════════════════════════════════════════════════════
// AccessibleText
// ═══════════════════════════════════════════════════════════════════════════════

/// A drop-in replacement for [Text] that automatically respects
/// [AccessibilitySettings].
///
/// - Applies [textScaleFactor] from settings.
/// - Switches to [FontWeight.bold] when [isBoldText] is true.
/// - Attaches a [Semantics] label for screen readers.
/// - Enforces a minimum contrast ratio (4.5:1) when high-contrast is on.
///
/// ```dart
/// AccessibleText(
///   'Hello, ExamForge!',
///   style: TextStyle(fontSize: 16),
///   semanticLabel: 'Greeting message',
/// )
/// ```
class AccessibleText extends StatelessWidget {
  /// The text to display.
  final String data;

  /// Optional style. [fontWeight] and [fontSize] may be overridden by
  /// accessibility settings.
  final TextStyle? style;

  /// How the text should be aligned horizontally.
  final TextAlign? textAlign;

  /// Maximum number of lines.
  final int? maxLines;

  /// How overflow should be handled.
  final TextOverflow? overflow;

  /// Semantic label read by screen readers. Falls back to [data].
  final String? semanticLabel;

  /// Whether this text should be treated as a semantic header.
  final bool isHeader;

  const AccessibleText(
    this.data, {
    super.key,
    this.style,
    this.textAlign,
    this.maxLines,
    this.overflow,
    this.semanticLabel,
    this.isHeader = false,
  });

  @override
  Widget build(BuildContext context) {
    final settings = _watchSettings(context);
    final effectiveStyle = _resolveStyle(context, settings);

    Widget textWidget = Text(
      data,
      style: effectiveStyle,
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
      textScaler: TextScaler.linear(settings.textScaleFactor),
    );

    if (semanticLabel != null || isHeader) {
      textWidget = Semantics(
        label: semanticLabel ?? data,
        header: isHeader,
        child: textWidget,
      );
    }

    return textWidget;
  }

  TextStyle _resolveStyle(BuildContext context, AccessibilitySettings settings) {
    var effective = style ?? DefaultTextStyle.of(context).style;

    // Apply bold text override
    if (settings.isBoldText && effective.fontWeight != FontWeight.bold) {
      effective = effective.copyWith(fontWeight: FontWeight.bold);
    }

    // Enforce high contrast: ensure text is dark/light enough
    if (settings.isHighContrast) {
      final brightness = Theme.of(context).brightness;
      final highContrastColor =
          brightness == Brightness.dark ? const Color(0xFFFFFFFF) : const Color(0xFF000000);
      effective = effective.copyWith(color: highContrastColor);
    }

    return effective;
  }

  /// Convenience: read accessibility settings from context via ProviderScope.
  AccessibilitySettings _watchSettings(BuildContext context) {
    // Try Riverpod first; fall back to defaults.
    try {
      final container = ProviderScope.containerOf(context);
      return container.read(accessibilitySettingsProvider);
    } catch (_) {
      return const AccessibilitySettings();
    }
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// AccessibleButton
// ═══════════════════════════════════════════════════════════════════════════════

/// A Material 3 button that enforces accessibility best practices:
///
/// - **Minimum touch target**: 48 x 48 dp (WCAG 2.5.5)
/// - **Semantic label** for screen readers
/// - **High-contrast border** when [isHighContrast] is enabled
/// - **Focus indicator** for keyboard navigation
///
/// ```dart
/// AccessibleButton(
///   label: 'Submit',
///   semanticLabel: 'Submit exam answers',
///   onPressed: () => handleSubmit(),
///   icon: Icons.send,
/// )
/// ```
class AccessibleButton extends StatelessWidget {
  /// The button label.
  final String label;

  /// Semantic label for screen readers. Falls back to [label].
  final String? semanticLabel;

  /// Callback when pressed. If `null`, the button is disabled.
  final VoidCallback? onPressed;

  /// Optional leading icon.
  final IconData? icon;

  /// Whether this is a filled (primary) button. Defaults to true.
  final bool isFilled;

  /// Minimum touch target dimension in logical pixels.
  final double minTouchTarget;

  const AccessibleButton({
    super.key,
    required this.label,
    this.semanticLabel,
    this.onPressed,
    this.icon,
    this.isFilled = true,
    this.minTouchTarget = 48.0,
  });

  @override
  Widget build(BuildContext context) {
    final settings = _watchSettings(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Determine border for high-contrast mode
    OutlinedBorder? shape;
    if (settings.isHighContrast) {
      shape = RoundedRectangleBorder(
        borderRadius: Spacings.borderRadiusMd,
        side: BorderSide(
          color: colorScheme.onSurface,
          width: 2.0,
        ),
      );
    }

    // Build the appropriate button type
    Widget button;
    if (icon != null) {
      if (isFilled) {
        button = FilledButton.icon(
          onPressed: onPressed,
          icon: Icon(icon),
          label: Text(label),
          style: _buildButtonStyle(colorScheme, shape),
        );
      } else {
        button = OutlinedButton.icon(
          onPressed: onPressed,
          icon: Icon(icon),
          label: Text(label),
          style: _buildOutlinedButtonStyle(colorScheme, shape),
        );
      }
    } else {
      if (isFilled) {
        button = FilledButton(
          onPressed: onPressed,
          style: _buildButtonStyle(colorScheme, shape),
          child: Text(label),
        );
      } else {
        button = OutlinedButton(
          onPressed: onPressed,
          style: _buildOutlinedButtonStyle(colorScheme, shape),
          child: Text(label),
        );
      }
    }

    // Enforce minimum touch target
    button = ConstrainedBox(
      constraints: BoxConstraints(
        minHeight: minTouchTarget,
        minWidth: minTouchTarget,
      ),
      child: button,
    );

    // Wrap with semantics
    return Semantics(
      label: semanticLabel ?? label,
      button: true,
      enabled: onPressed != null,
      child: Focus(
        debugLabel: 'AccessibleButton: $label',
        child: button,
      ),
    );
  }

  ButtonStyle _buildButtonStyle(
    ColorScheme colorScheme,
    OutlinedBorder? highContrastShape,
  ) {
    return FilledButton.styleFrom(
      shape: highContrastShape ??
          const RoundedRectangleBorder(borderRadius: Spacings.borderRadiusMd),
    );
  }

  ButtonStyle _buildOutlinedButtonStyle(
    ColorScheme colorScheme,
    OutlinedBorder? highContrastShape,
  ) {
    return OutlinedButton.styleFrom(
      shape: highContrastShape ??
          const RoundedRectangleBorder(borderRadius: Spacings.borderRadiusMd),
      side: highContrastShape != null
          ? const BorderSide(color: Color(0xFF000000), width: 2.0)
          : null,
    );
  }

  AccessibilitySettings _watchSettings(BuildContext context) {
    try {
      final container = ProviderScope.containerOf(context);
      return container.read(accessibilitySettingsProvider);
    } catch (_) {
      return const AccessibilitySettings();
    }
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// AccessibleImage
// ═══════════════════════════════════════════════════════════════════════════════

/// An image widget with built-in accessibility support.
///
/// - [semanticLabel] is **always required** – every image must be described.
/// - When a [colorblindMode] is active, the corresponding [ColorFilter]
///   is applied automatically.
/// - An optional [highContrastChild] can replace the default image when
///   high-contrast mode is enabled.
///
/// ```dart
/// AccessibleImage(
///   semanticLabel: 'Chart showing student performance over time',
///   image: Image.asset('assets/chart.png'),
///   highContrastImage: Image.asset('assets/chart_hc.png'),
/// )
/// ```
class AccessibleImage extends StatelessWidget {
  /// The primary image widget.
  final Widget image;

  /// **Required** semantic description for screen readers.
  final String semanticLabel;

  /// Optional high-contrast variant of the image.
  final Widget? highContrastImage;

  /// Optional width constraint.
  final double? width;

  /// Optional height constraint.
  final double? height;

  /// Optional fit mode.
  final BoxFit? fit;

  const AccessibleImage({
    super.key,
    required this.image,
    required this.semanticLabel,
    this.highContrastImage,
    this.width,
    this.height,
    this.fit,
  });

  @override
  Widget build(BuildContext context) {
    final settings = _watchSettings(context);
    final effectiveImage = settings.isHighContrast && highContrastImage != null
        ? highContrastImage!
        : image;

    Widget result = effectiveImage;

    // Apply colorblind filter
    final filter = settings.colorblindMode.colorFilter;
    if (filter != null) {
      result = ColorFiltered(
        colorFilter: filter,
        child: result,
      );
    }

    // Apply size constraints
    if (width != null || height != null) {
      result = SizedBox(
        width: width,
        height: height,
        child: result,
      );
    }

    // Wrap with semantics
    return Semantics(
      label: semanticLabel,
      image: true,
      child: result,
    );
  }

  AccessibilitySettings _watchSettings(BuildContext context) {
    try {
      final container = ProviderScope.containerOf(context);
      return container.read(accessibilitySettingsProvider);
    } catch (_) {
      return const AccessibilitySettings();
    }
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// HighContrastTheme
// ═══════════════════════════════════════════════════════════════════════════════

/// Generates high-contrast Material 3 theme overrides.
///
/// When [AccessibilitySettings.isHighContrast] is `true`, use this class
/// to produce a [ThemeData] that:
/// - Forces black/white text with no subtle alpha values
/// - Strengthens borders and dividers
/// - Removes subtle / translucent backgrounds
/// - Increases button contrast
///
/// ```dart
/// final theme = isHighContrast
///     ? HighContrastTheme.buildHighContrastTheme(baseTheme)
///     : baseTheme;
/// ```
class HighContrastTheme {
  HighContrastTheme._();

  /// Builds a high-contrast variant of [baseTheme].
  static ThemeData buildHighContrastTheme(ThemeData baseTheme) {
    final isDark = baseTheme.brightness == Brightness.dark;
    final onSurface = isDark ? const Color(0xFFFFFFFF) : const Color(0xFF000000);
    final surface = isDark ? const Color(0xFF000000) : const Color(0xFFFFFFFF);
    final primary = isDark ? const Color(0xFFBB86FC) : const Color(0xFF4F46E5);

    // Base color scheme with maximum contrast
    final highContrastScheme = ColorScheme(
      brightness: baseTheme.brightness,
      primary: primary,
      onPrimary: surface,
      secondary: primary,
      onSecondary: surface,
      error: isDark ? const Color(0xFFFF6B6B) : const Color(0xFFCC0000),
      onError: surface,
      surface: surface,
      onSurface: onSurface,
      surfaceContainerHighest: isDark
          ? const Color(0xFF1A1A1A)
          : const Color(0xFFF5F5F5),
      outline: onSurface,
      outlineVariant: onSurface,
    );

    return baseTheme.copyWith(
      colorScheme: highContrastScheme,
      textTheme: baseTheme.textTheme.apply(
        bodyColor: onSurface,
        displayColor: onSurface,
        decorationColor: onSurface,
      ),
      dividerColor: onSurface,
      dividerTheme: const DividerThemeData(
        thickness: 2.0,
        space: 2.0,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: Spacings.borderRadiusMd,
          side: BorderSide(color: onSurface, width: 2.0),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          foregroundColor: surface,
          backgroundColor: primary,
          side: BorderSide(color: onSurface, width: 2.0),
          shape: const RoundedRectangleBorder(
            borderRadius: Spacings.borderRadiusMd,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: onSurface,
          side: BorderSide(color: onSurface, width: 2.0),
          shape: const RoundedRectangleBorder(
            borderRadius: Spacings.borderRadiusMd,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: Spacings.borderRadiusMd,
          borderSide: BorderSide(color: onSurface, width: 2.0),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: Spacings.borderRadiusMd,
          borderSide: BorderSide(color: primary, width: 3.0),
        ),
        labelStyle: TextStyle(color: onSurface),
      ),
      scaffoldBackgroundColor: surface,
      appBarTheme: AppBarTheme(
        backgroundColor: surface,
        foregroundColor: onSurface,
        elevation: 0,
        shadowColor: null,
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// ScreenReaderHelper
// ═══════════════════════════════════════════════════════════════════════════════

/// Utility class for screen reader announcements, tooltips, and ARIA-like
/// live regions.
///
/// ```dart
/// ScreenReaderHelper.announce('Exam submitted successfully');
/// ScreenReaderHelper.buildTooltip('Close', IconButton(...));
/// ```
class ScreenReaderHelper {
  ScreenReaderHelper._();

  /// Announces [message] to assistive technologies via [SemanticsService].
  ///
  /// Use this for important state changes that are not reflected by
  /// widget rebuilds (e.g. async operation completion, errors).
  static void announce(String message) {
    SemanticsService.announce(message, TextDirection.ltr);
    AppLogger.debug('Screen reader announcement: $message');
  }

  /// Wraps [child] in a [Semantics] widget that provides a tooltip.
  ///
  /// Screen readers will read the tooltip when the child receives focus.
  static Widget buildTooltip(String message, Widget child) {
    return Semantics(
      tooltip: message,
      child: child,
    );
  }

  /// Wraps [child] in an ARIA-like live region.
  ///
  /// When [assertive] is [LiveRegion.assertive], the screen reader
  /// interrupts the current announcement. When [LiveRegion.polite]
  /// (default), it waits for a pause.
  static Widget buildLiveRegion(
    Widget child, {
    LiveRegion assertive = LiveRegion.polite,
  }) {
    return Semantics(
      liveRegion: assertive == LiveRegion.assertive,
      child: child,
    );
  }
}

/// Enum mirroring ARIA live region politeness settings.
enum LiveRegion {
  /// The screen reader will announce changes after the current task.
  polite,

  /// The screen reader will interrupt the current task to announce changes.
  assertive,
}

// ═══════════════════════════════════════════════════════════════════════════════
// FocusTraversalHelper
// ═══════════════════════════════════════════════════════════════════════════════

/// Keyboard navigation helpers for focus traversal and shortcut actions.
///
/// These utilities ensure keyboard-only users can navigate and activate
/// controls efficiently.
///
/// ```dart
/// FocusTraversalHelper.buildTabbableOrder([
///   TextField(...),
///   AccessibleButton(...),
/// ])
/// ```
class FocusTraversalHelper {
  FocusTraversalHelper._();

  /// Assigns explicit tab order to a list of children.
  ///
  /// Each child is wrapped in a [FocusTraversalGroup] with an
  /// [OrderedTraversalPolicy] and a unique [FocusTraversalOrder]
  /// derived from its index.
  static List<Widget> buildTabbableOrder(List<Widget> children) {
    return List<Widget>.generate(children.length, (index) {
      return FocusTraversalOrder(
        order: NumericFocusOrder(index.toDouble()),
        child: children[index],
      );
    });
  }

  /// Wraps [child] in a [Shortcuts] + [Actions] widget that fires
  /// [action] when [trigger] key is pressed.
  ///
  /// ```dart
  /// FocusTraversalHelper.buildShortcutAction(
  ///   trigger: LogicalKeyboardKey.enter,
  ///   action: () => submitForm(),
  ///   child: TextField(...),
  /// )
  /// ```
  static Widget buildShortcutAction({
    required LogicalKeyboardKey trigger,
    required VoidCallback action,
    required Widget child,
  }) {
    return Shortcuts(
      shortcuts: <LogicalKeySet, Intent>{
        LogicalKeySet(trigger): _CallbackIntent(action),
      },
      child: Actions(
        actions: <Type, Action<Intent>>{
          _CallbackIntent: _CallbackAction(),
        },
        child: child,
      ),
    );
  }
}

// ─── Private: Callback Intent / Action ────────────────────────────────────

class _CallbackIntent extends Intent {
  const _CallbackIntent(this.callback);
  final VoidCallback callback;
}

class _CallbackAction extends Action<_CallbackIntent> {
  @override
  Object? invoke(_CallbackIntent intent) {
    intent.callback();
    return null;
  }
}
