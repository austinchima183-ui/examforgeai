import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;

import '../core/utils/logger.dart';

/// Environment configuration loaded from .env file.
///
/// Provides static accessors for all environment variables needed by
/// ExamForge AI. Call [initialize] once during app startup (before
/// Supabase or any service that depends on these values).
///
/// In release builds, falls back to compile-time constants supplied
/// via `--dart-define`. In debug, uses safe placeholder values so the
/// app can still launch without a `.env` file.
class EnvConfig {
  EnvConfig._();

  static late final Map<String, String> _env;
  static bool _initialized = false;

  // ─── Initialization ─────────────────────────────────────────────

  /// Loads environment variables from the bundled `.env` asset.
  ///
  /// Must be called exactly once before accessing any getter.
  /// Typically invoked in `main()` before `runApp()`.
  static Future<void> initialize() async {
    if (_initialized) {
      AppLogger.warning('EnvConfig already initialized — skipping.');
      return;
    }

    try {
      final envString = await rootBundle.loadString('.env');
      _env = _parseEnvString(envString);
      _initialized = true;
      AppLogger.info('EnvConfig loaded ${_env.length} variables from .env');
    } catch (e) {
      AppLogger.warning('Failed to load .env file, using fallback values: $e');

      if (kReleaseMode) {
        // In production, rely on compile-time --dart-define constants.
        _env = {
          'SUPABASE_URL': const String.fromEnvironment('SUPABASE_URL'),
          'SUPABASE_ANON_KEY': const String.fromEnvironment('SUPABASE_ANON_KEY'),
          'SUPABASE_SERVICE_KEY': const String.fromEnvironment('SUPABASE_SERVICE_KEY'),
          'FCM_SERVER_KEY': const String.fromEnvironment('FCM_SERVER_KEY'),
          'FLUTTERWAVE_PUBLIC_KEY':
              const String.fromEnvironment('FLUTTERWAVE_PUBLIC_KEY'),
          'FLUTTERWAVE_SECRET_KEY':
              const String.fromEnvironment('FLUTTERWAVE_SECRET_KEY'),
          'ENVIRONMENT': const String.fromEnvironment(
            'ENVIRONMENT',
            defaultValue: 'production',
          ),
        };
      } else {
        // In debug, safe placeholders so the app still boots.
        _env = {
          'SUPABASE_URL': 'https://placeholder.supabase.co',
          'SUPABASE_ANON_KEY': 'placeholder-key',
          'SUPABASE_SERVICE_KEY': '',
          'FCM_SERVER_KEY': '',
          'FLUTTERWAVE_PUBLIC_KEY': '',
          'FLUTTERWAVE_SECRET_KEY': '',
          'ENVIRONMENT': 'development',
        };
      }
      _initialized = true;
    }
  }

  // ─── Parsing ────────────────────────────────────────────────────

  /// Parses a standard `.env` file string into a `Map<String, String>`.
  ///
  /// - Blank lines are ignored.
  /// - Lines starting with `#` are treated as comments and ignored.
  /// - Only the first `=` is used as the delimiter, so values may
  ///   contain `=` characters.
  /// - Surrounding quotes on values are stripped.
  static Map<String, String> _parseEnvString(String raw) {
    final result = <String, String>{};

    for (final line in raw.split('\n')) {
      final trimmed = line.trim();

      // Skip empty lines and comments.
      if (trimmed.isEmpty || trimmed.startsWith('#')) continue;
      if (!trimmed.contains('=')) continue;

      final eqIndex = trimmed.indexOf('=');
      final key = trimmed.substring(0, eqIndex).trim();
      var value = trimmed.substring(eqIndex + 1).trim();

      // Strip surrounding quotes (single or double).
      if ((value.startsWith('"') && value.endsWith('"')) ||
          (value.startsWith("'") && value.endsWith("'"))) {
        value = value.substring(1, value.length - 1);
      }

      if (key.isNotEmpty) {
        result[key] = value;
      }
    }

    return result;
  }

  // ─── Public Accessors ───────────────────────────────────────────

  /// Whether [initialize] has completed successfully.
  static bool get isInitialized => _initialized;

  /// Raw access to the underlying environment map.
  /// Useful for retrieving keys not exposed as named getters.
  static Map<String, String> get all => Map.unmodifiable(_env);

  /// Retrieve a value by key, returning `null` if not found.
  static String? maybeGet(String key) => _env[key];

  /// Retrieve a value by key, returning [defaultValue] if not found.
  static String getOrElse(String key, String defaultValue) =>
      _env[key] ?? defaultValue;

  // ─── Supabase ───────────────────────────────────────────────────

  static String get supabaseUrl => _env['SUPABASE_URL'] ?? '';
  static String get supabaseAnonKey => _env['SUPABASE_ANON_KEY'] ?? '';
  static String get supabaseServiceKey => _env['SUPABASE_SERVICE_KEY'] ?? '';

  // ─── Firebase Cloud Messaging ────────────────────────────────────

  static String get fcmServerKey => _env['FCM_SERVER_KEY'] ?? '';

  // ─── Flutterwave ────────────────────────────────────────────────

  static String get flutterwavePublicKey =>
      _env['FLUTTERWAVE_PUBLIC_KEY'] ?? '';
  static String get flutterwaveSecretKey =>
      _env['FLUTTERWAVE_SECRET_KEY'] ?? '';

  /// Flutterwave webhook secret hash for signature verification.
  static String get flutterwaveWebhookSecretHash =>
      _env['FLUTTERWAVE_WEBHOOK_SECRET_HASH'] ?? '';

  // ─── Environment ────────────────────────────────────────────────

  static String get environment => _env['ENVIRONMENT'] ?? 'development';
  static bool get isProduction => environment == 'production';
  static bool get isStaging => environment == 'staging';
  static bool get isDevelopment => environment == 'development';

  /// Debug-friendly dump of the loaded config (values may be masked).
  @override
  String toString() {
    final masked = _env.map((key, value) {
      if (key.contains('KEY') || key.contains('SECRET') || key.contains('SERVICE')) {
        return MapEntry(key, '${value.substring(0, value.length > 4 ? 4 : 0)}***');
      }
      return MapEntry(key, value);
    });
    return 'EnvConfig($masked)';
  }
}
