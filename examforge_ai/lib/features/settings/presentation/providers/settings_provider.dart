import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/utils/logger.dart';
import '../../../../config/dependency_injection.dart';


// ═══════════════════════════════════════════════════════════════════════
// SETTINGS STATE
// ═══════════════════════════════════════════════════════════════════════

/// Immutable state snapshot for the settings feature.
class SettingsState {
  const SettingsState({
    this.themeMode = ThemeMode.system,
    this.notificationsEnabled = true,
    this.emailNotificationsEnabled = true,
    this.language = 'en',
    this.isLoading = false,
    this.error,
  });

  /// The current theme mode.
  final ThemeMode themeMode;

  /// Whether push notifications are enabled.
  final bool notificationsEnabled;

  /// Whether email notifications are enabled.
  final bool emailNotificationsEnabled;

  /// The preferred language code (e.g. 'en', 'fr').
  final String language;

  /// Whether settings are being loaded.
  final bool isLoading;

  /// The most recent error message, or `null`.
  final String? error;

  /// Human-readable theme label.
  String get themeLabel => switch (themeMode) {
        ThemeMode.system => 'System Default',
        ThemeMode.light => 'Light',
        ThemeMode.dark => 'Dark',
      };

  /// Human-readable language label.
  String get languageLabel => switch (language) {
        'en' => 'English',
        'fr' => 'French',
        'es' => 'Spanish',
        'ar' => 'Arabic',
        _ => language.toUpperCase(),
      };

  /// Creates a copy of this state with the given fields replaced.
  SettingsState copyWith({
    ThemeMode? themeMode,
    bool? notificationsEnabled,
    bool? emailNotificationsEnabled,
    String? language,
    bool? isLoading,
    String? error,
  }) {
    return SettingsState(
      themeMode: themeMode ?? this.themeMode,
      notificationsEnabled:
          notificationsEnabled ?? this.notificationsEnabled,
      emailNotificationsEnabled:
          emailNotificationsEnabled ?? this.emailNotificationsEnabled,
      language: language ?? this.language,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// SETTINGS NOTIFIER
// ═══════════════════════════════════════════════════════════════════════

/// Riverpod [StateNotifier] that manages the settings feature's state.
///
/// Handles theme mode, notification preferences, and language persistence
/// using shared preferences for non-sensitive data.
class SettingsNotifier extends StateNotifier<SettingsState> {
  SettingsNotifier({
    required Ref ref,
  })  : _ref = ref,
        super(const SettingsState()) {
    _loadSettings();
  }

  final Ref _ref;

  // ─── Persistence Keys ────────────────────────────────────────────

  static const String _kThemeModeKey = 'examforge_settings_theme_mode';
  static const String _kNotificationsKey =
      'examforge_settings_notifications';
  static const String _kEmailNotificationsKey =
      'examforge_settings_email_notifications';
  static const String _kLanguageKey = 'examforge_settings_language';

  // ─── Load Settings ───────────────────────────────────────────────

  /// Loads persisted settings from shared preferences.
  Future<void> _loadSettings() async {
    state = state.copyWith(isLoading: true);
    try {
      final prefs = await SharedPreferences.getInstance();

      // Theme mode
      final themeIndex = prefs.getInt(_kThemeModeKey);
      final ThemeMode themeMode;
      if (themeIndex != null &&
          themeIndex >= 0 &&
          themeIndex < ThemeMode.values.length) {
        themeMode = ThemeMode.values[themeIndex];
      } else {
        themeMode = ThemeMode.system;
      }

      // Notification preferences
      final notificationsEnabled =
          prefs.getBool(_kNotificationsKey) ?? true;
      final emailNotificationsEnabled =
          prefs.getBool(_kEmailNotificationsKey) ?? true;

      // Language
      final language = prefs.getString(_kLanguageKey) ?? 'en';

      state = state.copyWith(
        themeMode: themeMode,
        notificationsEnabled: notificationsEnabled,
        emailNotificationsEnabled: emailNotificationsEnabled,
        language: language,
        isLoading: false,
        error: null,
      );

      AppLogger.info('Settings loaded');
    } catch (e) {
      AppLogger.error('Failed to load settings', error: e);
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load settings.',
      );
    }
  }

  // ─── Theme Mode ──────────────────────────────────────────────────

  /// Sets the theme mode and persists the choice.
  Future<void> setThemeMode(ThemeMode mode) async {
    state = state.copyWith(themeMode: mode);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_kThemeModeKey, mode.index);
      AppLogger.info('Theme mode set to: ${mode.name}');
    } catch (e) {
      AppLogger.error('Failed to persist theme mode', error: e);
    }
  }

  // ─── Notification Preferences ────────────────────────────────────

  /// Toggles push notifications and persists the choice.
  Future<void> setNotificationsEnabled(bool enabled) async {
    state = state.copyWith(notificationsEnabled: enabled);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_kNotificationsKey, enabled);
      AppLogger.info('Push notifications: $enabled');
    } catch (e) {
      AppLogger.error('Failed to persist notification preference', error: e);
    }
  }

  /// Toggles email notifications and persists the choice.
  Future<void> setEmailNotificationsEnabled(bool enabled) async {
    state = state.copyWith(emailNotificationsEnabled: enabled);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_kEmailNotificationsKey, enabled);
      AppLogger.info('Email notifications: $enabled');
    } catch (e) {
      AppLogger.error('Failed to persist email notification preference',
          error: e);
    }
  }

  // ─── Language ────────────────────────────────────────────────────

  /// Sets the preferred language and persists the choice.
  Future<void> setLanguage(String languageCode) async {
    state = state.copyWith(language: languageCode);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kLanguageKey, languageCode);
      AppLogger.info('Language set to: $languageCode');
    } catch (e) {
      AppLogger.error('Failed to persist language preference', error: e);
    }
  }

  // ─── Reset ───────────────────────────────────────────────────────

  /// Resets all settings to their defaults.
  Future<void> resetToDefaults() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_kThemeModeKey);
      await prefs.remove(_kNotificationsKey);
      await prefs.remove(_kEmailNotificationsKey);
      await prefs.remove(_kLanguageKey);

      state = const SettingsState();
      AppLogger.info('Settings reset to defaults');
    } catch (e) {
      AppLogger.error('Failed to reset settings', error: e);
    }
  }
}

// ═══════════════════════════════════════════════════════════════════════
// PROVIDERS
// ═══════════════════════════════════════════════════════════════════════

/// Provider that holds the current [SettingsState].
final settingsProvider =
    StateNotifierProvider<SettingsNotifier, SettingsState>(
  (ref) => SettingsNotifier(ref: ref),
);

/// Convenience provider that watches the current theme mode.
final settingsThemeModeProvider = Provider<ThemeMode>((ref) {
  return ref.watch(settingsProvider).themeMode;
});

/// Convenience provider that watches whether notifications are enabled.
final settingsNotificationsEnabledProvider = Provider<bool>((ref) {
  return ref.watch(settingsProvider).notificationsEnabled;
});
