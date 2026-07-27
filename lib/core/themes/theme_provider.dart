import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_colors.dart';
import 'app_theme.dart';

// ─── Persistence Keys ───────────────────────────────────────────────────────

const String _kThemeModeKey = 'examforge_theme_mode';
const String _kSeedColorKey = 'examforge_seed_color';

// ─── Theme State ────────────────────────────────────────────────────────────

/// Immutable state describing the current theme configuration.
class ThemeState {
  final ThemeMode themeMode;
  final Color? seedColor;

  const ThemeState({
    this.themeMode = ThemeMode.system,
    this.seedColor,
  });

  /// Derived [ColorScheme] based on [seedColor] or the default [AppColors.seed].
  ColorScheme get lightColorScheme => seedColor != null
      ? ColorScheme.fromSeed(seedColor: seedColor!)
      : AppColors.lightScheme;

  ColorScheme get darkColorScheme => seedColor != null
      ? ColorScheme.fromSeed(seedColor: seedColor!, brightness: Brightness.dark)
      : AppColors.darkScheme;

  /// Derived light [ThemeData].
  ThemeData get lightTheme => seedColor != null
      ? _rebuildWithSeed(lightColorScheme, Brightness.light)
      : AppTheme.lightTheme();

  /// Derived dark [ThemeData].
  ThemeData get darkTheme => seedColor != null
      ? _rebuildWithSeed(darkColorScheme, Brightness.dark)
      : AppTheme.darkTheme();

  ThemeData _rebuildWithSeed(ColorScheme colorScheme, Brightness brightness) {
    // Delegate to AppTheme's internal builder is not accessible from here,
    // so we create a minimal themedata that incorporates the dynamic seed.
    // For full component theming the user should extend AppTheme.
    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      brightness: brightness,
    );
  }

  ThemeState copyWith({
    ThemeMode? themeMode,
    Color? Function()? seedColor,
  }) {
    return ThemeState(
      themeMode: themeMode ?? this.themeMode,
      seedColor: seedColor != null ? seedColor() : this.seedColor,
    );
  }
}

// ─── Notifier ───────────────────────────────────────────────────────────────

/// Manages theme mode and optional seed color, persisting changes to
/// [SharedPreferences] and exposing them via Riverpod.
class ThemeNotifier extends StateNotifier<ThemeState> {
  ThemeNotifier() : super(const ThemeState()) {
    _loadFromStorage();
  }

  // ─── Public API ───────────────────────────────────────────────────────

  /// Set the theme mode explicitly.
  Future<void> setThemeMode(ThemeMode mode) async {
    state = state.copyWith(themeMode: mode);
    await _persistMode(mode);
  }

  /// Toggle between light and dark. If system, switches to light first.
  Future<void> toggleTheme() async {
    final next = switch (state.themeMode) {
      ThemeMode.light => ThemeMode.dark,
      ThemeMode.dark => ThemeMode.light,
      ThemeMode.system => ThemeMode.light,
    };
    await setThemeMode(next);
  }

  /// Set a custom seed color for the color scheme. Pass `null` to reset.
  Future<void> setSeedColor(Color? color) async {
    state = state.copyWith(seedColor: color == null ? null : () => color);
    await _persistSeedColor(color);
  }

  /// Reset everything to defaults.
  Future<void> reset() async {
    state = const ThemeState();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kThemeModeKey);
    await prefs.remove(_kSeedColorKey);
  }

  // ─── Private Helpers ──────────────────────────────────────────────────

  Future<void> _loadFromStorage() async {
    final prefs = await SharedPreferences.getInstance();

    // Theme mode
    final modeIndex = prefs.getInt(_kThemeModeKey);
    final ThemeMode mode;
    if (modeIndex != null && modeIndex >= 0 && modeIndex < ThemeMode.values.length) {
      mode = ThemeMode.values[modeIndex];
    } else {
      mode = ThemeMode.system;
    }

    // Seed color
    final colorValue = prefs.getInt(_kSeedColorKey);
    final Color? seed = colorValue != null ? Color(colorValue) : null;

    if (mode != state.themeMode || seed != state.seedColor) {
      state = ThemeState(themeMode: mode, seedColor: seed);
    }
  }

  Future<void> _persistMode(ThemeMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kThemeModeKey, mode.index);
  }

  Future<void> _persistSeedColor(Color? color) async {
    final prefs = await SharedPreferences.getInstance();
    if (color != null) {
      await prefs.setInt(_kSeedColorKey, color.toARGB32());
    } else {
      await prefs.remove(_kSeedColorKey);
    }
  }
}

// ─── Providers ──────────────────────────────────────────────────────────────

/// Provider that holds the current [ThemeState] and persists changes.
final themeProvider = StateNotifierProvider<ThemeNotifier, ThemeState>(
  (ref) => ThemeNotifier(),
);

/// Convenience provider that watches just the [ThemeMode].
final themeModeProvider = Provider<ThemeMode>(
  (ref) => ref.watch(themeProvider).themeMode,
);

/// Convenience provider that watches just the light [ThemeData].
final lightThemeProvider = Provider<ThemeData>(
  (ref) => ref.watch(themeProvider).lightTheme,
);

/// Convenience provider that watches just the dark [ThemeData].
final darkThemeProvider = Provider<ThemeData>(
  (ref) => ref.watch(themeProvider).darkTheme,
);
