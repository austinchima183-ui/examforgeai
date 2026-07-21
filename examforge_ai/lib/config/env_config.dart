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
///
/// ─── SECURITY NOTE ──────────────────────────────────────────────────
/// Server-only secrets (SUPABASE_SERVICE_KEY, FLUTTERWAVE_SECRET_KEY,
/// FCM_SERVER_KEY, FLUTTERWAVE_WEBHOOK_SECRET_HASH) have been REMOVED
/// from this client-side configuration. These keys must ONLY exist in
/// Supabase Edge Function environment variables (via Deno.env.get()).
/// The Flutter client must NEVER have access to privileged keys.
/// ─────────────────────────────────────────────────────────────────────
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
        // ONLY client-safe keys are loaded here — no server secrets.
        _env = {
          'SUPABASE_URL': const String.fromEnvironment('SUPABASE_URL'),
          'SUPABASE_ANON_KEY': const String.fromEnvironment('SUPABASE_ANON_KEY'),
          'FLUTTERWAVE_PUBLIC_KEY':
              const String.fromEnvironment('FLUTTERWAVE_PUBLIC_KEY'),
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
          'FLUTTERWAVE_PUBLIC_KEY': '',
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

  // NOTE: supabaseServiceKey has been REMOVED for security.
  // Server-only operations must go through Supabase Edge Functions
  // where the service role key is available via Deno.env.get().

  // ─── Firebase Cloud Messaging ────────────────────────────────────

  // NOTE: fcmServerKey has been REMOVED for security.
  // FCM server-side operations must go through Supabase Edge Functions.

  // ─── Flutterwave ────────────────────────────────────────────────

  static String get flutterwavePublicKey =>
      _env['FLUTTERWAVE_PUBLIC_KEY'] ?? '';

  // NOTE: flutterwaveSecretKey and flutterwaveWebhookSecretHash have
  // been REMOVED for security. All Flutterwave API calls requiring the
  // secret key must go through Supabase Edge Functions where the key
  // is available via Deno.env.get('FLUTTERWAVE_SECRET_KEY').

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
