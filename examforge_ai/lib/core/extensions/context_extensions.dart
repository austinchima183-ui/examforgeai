import 'package:flutter/material.dart';

/// Convenience getters on [BuildContext] so you never have to write
/// `Theme.of(context)` or `MediaQuery.of(context)` again.
extension ContextExtensions on BuildContext {
  // ─── Theme ─────────────────────────────────────────────────────────

  /// The current [ThemeData].
  ThemeData get theme => Theme.of(this);

  /// The [ColorScheme] from the current theme.
  ColorScheme get colorScheme => theme.colorScheme;

  /// The [TextTheme] from the current theme.
  TextTheme get textTheme => theme.textTheme;

  // ─── Media Query ───────────────────────────────────────────────────

  /// The current [MediaQueryData].
  MediaQueryData get mediaQuery => MediaQuery.of(this);

  /// The logical [Size] of the screen.
  Size get size => mediaQuery.size;

  /// Screen width in logical pixels.
  double get width => size.width;

  /// Screen height in logical pixels.
  double get height => size.height;

  /// The system-imposed padding (notches, status bar, etc.).
  EdgeInsets get padding => mediaQuery.padding;

  /// The insets for on-screen keyboards and system UI.
  EdgeInsets get viewInsets => mediaQuery.viewInsets;

  // ─── Responsive Breakpoints ────────────────────────────────────────

  /// True when the screen width is less than 600 px (phone).
  bool get isMobile => width < 600;

  /// True when the screen width is between 600 and 1024 px (tablet).
  bool get isTablet => width >= 600 && width < 1024;

  /// True when the screen width is 1024 px or wider (desktop).
  bool get isDesktop => width >= 1024;

  // ─── Appearance ────────────────────────────────────────────────────

  /// True when the platform is in dark mode.
  bool get isDarkMode => theme.brightness == Brightness.dark;

  // ─── Keyboard ──────────────────────────────────────────────────────

  /// True when the soft keyboard is currently visible.
  bool get isKeyboardVisible => viewInsets.bottom > 0;

  // ─── Scaffold ──────────────────────────────────────────────────────

  /// The nearest [ScaffoldMessengerState] for showing snack-bars.
  ScaffoldMessengerState get scaffoldMessenger =>
      ScaffoldMessenger.of(this);
}
