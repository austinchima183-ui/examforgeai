import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/constants/app_constants.dart';
import '../core/errors/exceptions.dart';
import '../core/utils/logger.dart';

/// Centralized storage service that manages both secure and non-secure
/// persistence.
///
/// **Secure storage** (`flutter_secure_storage`) is used for sensitive
/// data such as tokens, user IDs, and roles — values that must be
/// encrypted at rest.
///
/// **Shared preferences** is used for non-sensitive preferences such
/// as theme mode, locale, and onboarding state — values that do not
/// require encryption and benefit from fast synchronous reads.
///
/// All methods are async and include proper error handling with
/// meaningful exceptions.
class StorageService {
  StorageService({
    FlutterSecureStorage? secureStorage,
    SharedPreferencesAsync? sharedPreferences,
  })  : _secureStorage = secureStorage ?? const FlutterSecureStorage(),
        _sharedPrefs = sharedPreferences ?? SharedPreferencesAsync();

  final FlutterSecureStorage _secureStorage;
  final SharedPreferencesAsync _sharedPrefs;

  // ═══════════════════════════════════════════════════════════════════════
  // SECURE STORAGE — Sensitive Data
  // ═══════════════════════════════════════════════════════════════════════

  // ─── Access Token ────────────────────────────────────────────────

  /// Persists the access [token] securely.
  Future<void> saveToken(String token) async {
    try {
      await _secureStorage.write(
        key: AppConstants.accessToken,
        value: token,
      );
      AppLogger.debug('Access token saved');
    } catch (e) {
      AppLogger.error('Failed to save access token', error: e);
      throw CacheException('Failed to save access token: $e');
    }
  }

  /// Retrieves the stored access token, or `null` if not found.
  Future<String?> getToken() async {
    try {
      return await _secureStorage.read(key: AppConstants.accessToken);
    } catch (e) {
      AppLogger.error('Failed to read access token', error: e);
      throw CacheException('Failed to read access token: $e');
    }
  }

  /// Deletes the stored access token.
  Future<void> deleteToken() async {
    try {
      await _secureStorage.delete(key: AppConstants.accessToken);
      AppLogger.debug('Access token deleted');
    } catch (e) {
      AppLogger.error('Failed to delete access token', error: e);
      throw CacheException('Failed to delete access token: $e');
    }
  }

  // ─── Refresh Token ───────────────────────────────────────────────

  /// Persists the refresh [token] securely.
  Future<void> saveRefreshToken(String token) async {
    try {
      await _secureStorage.write(
        key: AppConstants.refreshToken,
        value: token,
      );
      AppLogger.debug('Refresh token saved');
    } catch (e) {
      AppLogger.error('Failed to save refresh token', error: e);
      throw CacheException('Failed to save refresh token: $e');
    }
  }

  /// Retrieves the stored refresh token, or `null` if not found.
  Future<String?> getRefreshToken() async {
    try {
      return await _secureStorage.read(key: AppConstants.refreshToken);
    } catch (e) {
      AppLogger.error('Failed to read refresh token', error: e);
      throw CacheException('Failed to read refresh token: $e');
    }
  }

  /// Deletes the stored refresh token.
  Future<void> deleteRefreshToken() async {
    try {
      await _secureStorage.delete(key: AppConstants.refreshToken);
      AppLogger.debug('Refresh token deleted');
    } catch (e) {
      AppLogger.error('Failed to delete refresh token', error: e);
      throw CacheException('Failed to delete refresh token: $e');
    }
  }

  // ─── User ID ─────────────────────────────────────────────────────

  /// Persists the user [id] securely.
  Future<void> saveUserId(String id) async {
    try {
      await _secureStorage.write(
        key: AppConstants.userId,
        value: id,
      );
      AppLogger.debug('User ID saved');
    } catch (e) {
      AppLogger.error('Failed to save user ID', error: e);
      throw CacheException('Failed to save user ID: $e');
    }
  }

  /// Retrieves the stored user ID, or `null` if not found.
  Future<String?> getUserId() async {
    try {
      return await _secureStorage.read(key: AppConstants.userId);
    } catch (e) {
      AppLogger.error('Failed to read user ID', error: e);
      throw CacheException('Failed to read user ID: $e');
    }
  }

  /// Deletes the stored user ID.
  Future<void> deleteUserId() async {
    try {
      await _secureStorage.delete(key: AppConstants.userId);
    } catch (e) {
      AppLogger.error('Failed to delete user ID', error: e);
      throw CacheException('Failed to delete user ID: $e');
    }
  }

  // ─── User Role ──────────────────────────────────────────────────

  /// Persists the user [role] securely (e.g. `admin`, `teacher`, `student`).
  Future<void> saveUserRole(String role) async {
    try {
      await _secureStorage.write(
        key: AppConstants.userRole,
        value: role,
      );
      AppLogger.debug('User role saved: $role');
    } catch (e) {
      AppLogger.error('Failed to save user role', error: e);
      throw CacheException('Failed to save user role: $e');
    }
  }

  /// Retrieves the stored user role, or `null` if not found.
  Future<String?> getUserRole() async {
    try {
      return await _secureStorage.read(key: AppConstants.userRole);
    } catch (e) {
      AppLogger.error('Failed to read user role', error: e);
      throw CacheException('Failed to read user role: $e');
    }
  }

  /// Deletes the stored user role.
  Future<void> deleteUserRole() async {
    try {
      await _secureStorage.delete(key: AppConstants.userRole);
    } catch (e) {
      AppLogger.error('Failed to delete user role', error: e);
      throw CacheException('Failed to delete user role: $e');
    }
  }

  // ─── Biometric Enabled ──────────────────────────────────────────

  /// Persists the biometric auth enabled preference securely.
  Future<void> saveBiometricEnabled(bool enabled) async {
    try {
      await _secureStorage.write(
        key: AppConstants.biometricEnabled,
        value: enabled.toString(),
      );
    } catch (e) {
      AppLogger.error('Failed to save biometric preference', error: e);
      throw CacheException('Failed to save biometric preference: $e');
    }
  }

  /// Retrieves the biometric auth preference, defaults to `false`.
  Future<bool> isBiometricEnabled() async {
    try {
      final value = await _secureStorage.read(key: AppConstants.biometricEnabled);
      return value?.toLowerCase() == 'true';
    } catch (e) {
      AppLogger.error('Failed to read biometric preference', error: e);
      return false;
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // SHARED PREFERENCES — Non-Sensitive Data
  // ═══════════════════════════════════════════════════════════════════════

  // ─── Theme Mode ─────────────────────────────────────────────────

  /// Persists the theme mode string (e.g. `light`, `dark`, `system`).
  Future<void> saveThemeMode(String mode) async {
    try {
      await _sharedPrefs.setString(AppConstants.themeMode, mode);
      AppLogger.debug('Theme mode saved: $mode');
    } catch (e) {
      AppLogger.error('Failed to save theme mode', error: e);
      throw CacheException('Failed to save theme mode: $e');
    }
  }

  /// Retrieves the stored theme mode, defaults to `'system'`.
  Future<String> getThemeMode() async {
    try {
      return await _sharedPrefs.getString(AppConstants.themeMode) ?? 'system';
    } catch (e) {
      AppLogger.error('Failed to read theme mode', error: e);
      return 'system';
    }
  }

  // ─── Locale ─────────────────────────────────────────────────────

  /// Persists the preferred locale code (e.g. `en`, `fr`).
  Future<void> saveLocale(String localeCode) async {
    try {
      await _sharedPrefs.setString(AppConstants.locale, localeCode);
      AppLogger.debug('Locale saved: $localeCode');
    } catch (e) {
      AppLogger.error('Failed to save locale', error: e);
      throw CacheException('Failed to save locale: $e');
    }
  }

  /// Retrieves the stored locale code, defaults to `'en'`.
  Future<String> getLocale() async {
    try {
      return await _sharedPrefs.getString(AppConstants.locale) ?? 'en';
    } catch (e) {
      AppLogger.error('Failed to read locale', error: e);
      return 'en';
    }
  }

  // ─── Onboarding ─────────────────────────────────────────────────

  /// Marks onboarding as completed.
  Future<void> setOnboardingComplete({bool complete = true}) async {
    try {
      await _sharedPrefs.setBool(AppConstants.onboardingComplete, complete);
      AppLogger.debug('Onboarding complete: $complete');
    } catch (e) {
      AppLogger.error('Failed to save onboarding state', error: e);
      throw CacheException('Failed to save onboarding state: $e');
    }
  }

  /// Returns `true` if the user has completed onboarding.
  Future<bool> isOnboardingComplete() async {
    try {
      return await _sharedPrefs.getBool(AppConstants.onboardingComplete) ??
          false;
    } catch (e) {
      AppLogger.error('Failed to read onboarding state', error: e);
      return false;
    }
  }

  // ─── Remember Me ────────────────────────────────────────────────

  /// Persists the "remember me" preference.
  Future<void> setRememberMe(bool remember) async {
    try {
      await _sharedPrefs.setBool(AppConstants.rememberMe, remember);
      AppLogger.debug('Remember me saved: $remember');
    } catch (e) {
      AppLogger.error('Failed to save remember me preference', error: e);
      throw CacheException('Failed to save remember me preference: $e');
    }
  }

  /// Returns `true` if the "remember me" option is enabled.
  Future<bool> isRememberMe() async {
    try {
      return await _sharedPrefs.getBool(AppConstants.rememberMe) ?? false;
    } catch (e) {
      AppLogger.error('Failed to read remember me preference', error: e);
      return false;
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // GENERIC KEY-VALUE HELPERS
  // ═══════════════════════════════════════════════════════════════════════

  /// Writes a string value to secure storage under [key].
  Future<void> writeSecure(String key, String value) async {
    try {
      await _secureStorage.write(key: key, value: value);
    } catch (e) {
      AppLogger.error('Failed to write secure key: $key', error: e);
      throw CacheException('Failed to write secure value: $e');
    }
  }

  /// Reads a string value from secure storage under [key].
  Future<String?> readSecure(String key) async {
    try {
      return await _secureStorage.read(key: key);
    } catch (e) {
      AppLogger.error('Failed to read secure key: $key', error: e);
      throw CacheException('Failed to read secure value: $e');
    }
  }

  /// Writes a string value to shared preferences under [key].
  Future<void> writePreference(String key, String value) async {
    try {
      await _sharedPrefs.setString(key, value);
    } catch (e) {
      AppLogger.error('Failed to write preference key: $key', error: e);
      throw CacheException('Failed to write preference: $e');
    }
  }

  /// Reads a string value from shared preferences under [key].
  Future<String?> readPreference(String key) async {
    try {
      return await _sharedPrefs.getString(key);
    } catch (e) {
      AppLogger.error('Failed to read preference key: $key', error: e);
      throw CacheException('Failed to read preference: $e');
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // BULK OPERATIONS
  // ═══════════════════════════════════════════════════════════════════════

  /// Clears **all** data from both secure storage and shared preferences.
  ///
  /// Typically called when the user explicitly logs out or when a full
  /// data reset is required.
  Future<void> clearAll() async {
    try {
      await _secureStorage.deleteAll();
      await _sharedPrefs.clear();
      AppLogger.info('All storage cleared');
    } catch (e) {
      AppLogger.error('Failed to clear all storage', error: e);
      throw CacheException('Failed to clear all storage: $e');
    }
  }

  /// Clears only **sensitive** data (tokens, user ID, role) from secure
  /// storage while preserving user preferences such as theme and locale.
  ///
  /// Use this when the user signs out but you want to keep their
  /// preference settings for the next sign-in.
  Future<void> clearSensitiveData() async {
    try {
      await _secureStorage.delete(key: AppConstants.accessToken);
      await _secureStorage.delete(key: AppConstants.refreshToken);
      await _secureStorage.delete(key: AppConstants.userId);
      await _secureStorage.delete(key: AppConstants.userRole);
      await _secureStorage.delete(key: AppConstants.biometricEnabled);
      AppLogger.info('Sensitive data cleared');
    } catch (e) {
      AppLogger.error('Failed to clear sensitive data', error: e);
      throw CacheException('Failed to clear sensitive data: $e');
    }
  }

  /// Persists both access and refresh tokens in a single call.
  Future<void> saveTokenPair({
    required String accessToken,
    String? refreshToken,
  }) async {
    try {
      await _secureStorage.write(
        key: AppConstants.accessToken,
        value: accessToken,
      );
      if (refreshToken != null) {
        await _secureStorage.write(
          key: AppConstants.refreshToken,
          value: refreshToken,
        );
      }
      AppLogger.debug('Token pair saved');
    } catch (e) {
      AppLogger.error('Failed to save token pair', error: e);
      throw CacheException('Failed to save token pair: $e');
    }
  }

  /// Checks whether a stored access token exists.
  Future<bool> hasToken() async {
    try {
      final token = await _secureStorage.read(key: AppConstants.accessToken);
      return token != null && token.isNotEmpty;
    } catch (e) {
      AppLogger.error('Failed to check token existence', error: e);
      return false;
    }
  }

  /// Checks whether a stored user ID exists.
  Future<bool> hasUserId() async {
    try {
      final id = await _secureStorage.read(key: AppConstants.userId);
      return id != null && id.isNotEmpty;
    } catch (e) {
      AppLogger.error('Failed to check user ID existence', error: e);
      return false;
    }
  }
}
