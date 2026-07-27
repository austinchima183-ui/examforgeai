import 'package:package_info_plus/package_info_plus.dart';

import '../core/constants/app_constants.dart';
import '../core/utils/logger.dart';
import 'env_config.dart';

/// The current runtime environment for the application.
enum AppEnvironment {
  development,
  staging,
  production;

  /// Convenience getter.
  bool get isDev => this == AppEnvironment.development;
  bool get isStaging => this == AppEnvironment.staging;
  bool get isProd => this == AppEnvironment.production;
}

/// Application-level configuration singleton.
///
/// Provides centralized access to app metadata, environment-specific
/// URLs, feature flags, and timeout durations. Call [initialize] once
/// during app startup — typically in `main()` after [EnvConfig.initialize].
///
/// ```dart
/// await EnvConfig.initialize();
/// await AppConfig.initialize();
/// ```
class AppConfig {
  AppConfig._();

  static late AppConfig _instance;
  static bool _initialized = false;

  // ─── Metadata (populated from package_info_plus) ────────────────

  late final String appName;
  late final String appVersion;
  late final String buildNumber;
  late final String packageName;

  // ─── Environment ────────────────────────────────────────────────

  late final AppEnvironment _environment;

  /// Current runtime environment.
  static AppEnvironment get environment => _instance._environment;

  // ─── Feature Flags ──────────────────────────────────────────────

  late final Map<String, bool> _featureFlags;

  // ─── Timeouts ───────────────────────────────────────────────────

  late final Duration connectTimeout;
  late final Duration receiveTimeout;
  late final Duration sendTimeout;

  // ─── Initialization ─────────────────────────────────────────────

  /// Initializes the singleton by reading package info and resolving
  /// the current environment from [EnvConfig].
  static Future<void> initialize() async {
    if (_initialized) {
      AppLogger.warning('AppConfig already initialized — skipping.');
      return;
    }

    // Resolve the environment from EnvConfig.
    final envString = EnvConfig.environment.toLowerCase();
    final env = switch (envString) {
      'production' => AppEnvironment.production,
      'staging' => AppEnvironment.staging,
      _ => AppEnvironment.development,
    };

    // Read package metadata.
    final packageInfo = await PackageInfo.fromPlatform();

    _instance = AppConfig._()
      ..appName = packageInfo.appName.isNotEmpty
          ? packageInfo.appName
          : AppConstants.appName
      ..appVersion = packageInfo.version.isNotEmpty
          ? packageInfo.version
          : AppConstants.appVersion
      ..buildNumber = packageInfo.buildNumber
      ..packageName = packageInfo.packageName
      .._environment = env
      .._featureFlags = _resolveFeatureFlags(env)
      ..connectTimeout = _resolveConnectTimeout(env)
      ..receiveTimeout = _resolveReceiveTimeout(env)
      ..sendTimeout = _resolveSendTimeout(env);

    _initialized = true;

    AppLogger.info(
      'AppConfig initialized — env: $env, version: ${_instance.appVersion}, '
      'build: ${_instance.buildNumber}',
    );
  }

  // ─── Base URL ───────────────────────────────────────────────────

  /// The API base URL for the current environment.
  static String get baseUrl {
    _assertInitialized();
    return switch (_instance._environment) {
      AppEnvironment.production => 'https://api.examforge.ai/v1',
      AppEnvironment.staging => 'https://staging-api.examforge.ai/v1',
      AppEnvironment.development => 'https://dev-api.examforge.ai/v1',
    };
  }

  /// The Supabase URL for the current environment.
  static String get supabaseUrl => EnvConfig.supabaseUrl;

  // ─── Metadata Accessors ─────────────────────────────────────────

  static String get currentAppName {
    _assertInitialized();
    return _instance.appName;
  }

  static String get currentAppVersion {
    _assertInitialized();
    return _instance.appVersion;
  }

  static String get currentBuildNumber {
    _assertInitialized();
    return _instance.buildNumber;
  }

  static String get currentPackageName {
    _assertInitialized();
    return _instance.packageName;
  }

  // ─── Environment Convenience ────────────────────────────────────

  static bool get isProduction {
    _assertInitialized();
    return _instance._environment.isProd;
  }

  static bool get isStaging {
    _assertInitialized();
    return _instance._environment.isStaging;
  }

  static bool get isDevelopment {
    _assertInitialized();
    return _instance._environment.isDev;
  }

  // ─── Feature Flags ──────────────────────────────────────────────

  /// Returns `true` if the feature identified by [flag] is enabled.
  ///
  /// Unknown flags default to `false` so that new features are
  /// opt-in by default.
  static bool isFeatureEnabled(String flag) {
    _assertInitialized();
    return _instance._featureFlags[flag] ?? false;
  }

  /// Returns an unmodifiable view of all feature flags.
  static Map<String, bool> get allFeatureFlags {
    _assertInitialized();
    return Map.unmodifiable(_instance._featureFlags);
  }

  /// Dynamically enables a feature flag at runtime.
  /// This is primarily useful for debugging / remote-config overrides.
  static void enableFeature(String flag) {
    _assertInitialized();
    _instance._featureFlags[flag] = true;
    AppLogger.info('Feature flag enabled: $flag');
  }

  /// Dynamically disables a feature flag at runtime.
  static void disableFeature(String flag) {
    _assertInitialized();
    _instance._featureFlags[flag] = false;
    AppLogger.info('Feature flag disabled: $flag');
  }

  // ─── Timeout Accessors ──────────────────────────────────────────

  static Duration get connectTimeoutDuration {
    _assertInitialized();
    return _instance.connectTimeout;
  }

  static Duration get receiveTimeoutDuration {
    _assertInitialized();
    return _instance.receiveTimeout;
  }

  static Duration get sendTimeoutDuration {
    _assertInitialized();
    return _instance.sendTimeout;
  }

  // ─── Logging ────────────────────────────────────────────────────

  /// Whether verbose logging should be enabled for the current env.
  static bool get enableVerboseLogging {
    _assertInitialized();
    return _instance._environment.isDev || _instance._environment.isStaging;
  }

  // ─── Private Helpers ────────────────────────────────────────────

  /// Resolves the default feature-flag map for [env].
  static Map<String, bool> _resolveFeatureFlags(AppEnvironment env) {
    // Production defaults — all experimental features off.
    const productionFlags = <String, bool>{
      'ai_question_generation': true,
      'ai_exam_hints': false,
      'offline_mode': false,
      'dark_mode': true,
      'push_notifications': true,
      'payment_gateway': true,
      'biometric_login': false,
      'multi_school': false,
      'advanced_analytics': false,
      'export_pdf': true,
    };

    return switch (env) {
      AppEnvironment.production => Map.from(productionFlags),
      AppEnvironment.staging => {
          ...productionFlags,
          'ai_exam_hints': true,
          'offline_mode': true,
          'biometric_login': true,
          'multi_school': true,
          'advanced_analytics': true,
        },
      AppEnvironment.development => {
          ...productionFlags,
          'ai_exam_hints': true,
          'offline_mode': true,
          'biometric_login': true,
          'multi_school': true,
          'advanced_analytics': true,
        },
    };
  }

  static Duration _resolveConnectTimeout(AppEnvironment env) => switch (env) {
        AppEnvironment.production => const Duration(seconds: 15),
        AppEnvironment.staging => const Duration(seconds: 20),
        AppEnvironment.development => const Duration(seconds: 30),
      };

  static Duration _resolveReceiveTimeout(AppEnvironment env) => switch (env) {
        AppEnvironment.production => const Duration(seconds: 15),
        AppEnvironment.staging => const Duration(seconds: 20),
        AppEnvironment.development => const Duration(seconds: 30),
      };

  static Duration _resolveSendTimeout(AppEnvironment env) => switch (env) {
        AppEnvironment.production => const Duration(seconds: 15),
        AppEnvironment.staging => const Duration(seconds: 20),
        AppEnvironment.development => const Duration(seconds: 30),
      };

  static void _assertInitialized() {
    if (!_initialized) {
      throw StateError(
        'AppConfig has not been initialized. '
        'Call AppConfig.initialize() before accessing any properties.',
      );
    }
  }

  /// Debug-friendly string representation.
  @override
  String toString() {
    _assertInitialized();
    return 'AppConfig('
        'appName: $currentAppName, '
        'version: $currentAppVersion, '
        'build: $currentBuildNumber, '
        'environment: ${_instance._environment.name}, '
        'baseUrl: $baseUrl'
        ')';
  }
}
