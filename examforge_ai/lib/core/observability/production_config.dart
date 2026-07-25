// ============================================================================
// ExamForge AI — Production Monitoring Configuration
// ============================================================================
//
// Environment-specific configurations for development, staging, and production:
//   - Sampling rates (which events to capture at what rate)
//   - Log levels (minimum severity per environment)
//   - Feature flags (enable/disable observability features)
//   - Alert thresholds (per environment)
//   - Environment overrides
//
// ROOT CAUSE: The project has no monitoring configuration. All environments
// would use the same settings, causing debug noise in production or missing
// production data in development. This module provides proper env separation.
// ============================================================================

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../logging/structured_logger.dart';
import 'alert_engine.dart';
import 'log_shipping.dart';

// ═══════════════════════════════════════════════════════════════════════════
// ENVIRONMENT TYPE
// ═══════════════════════════════════════════════════════════════════════════

/// Deployment environment types.
enum Environment {
  development('development'),
  staging('staging'),
  production('production');

  const Environment(this.label);
  final String label;
}

// ═══════════════════════════════════════════════════════════════════════════
// MONITORING FEATURE FLAGS
// ═══════════════════════════════════════════════════════════════════════════

/// Feature flags for observability components.
class MonitoringFeatureFlags {
  const MonitoringFeatureFlags({
    this.crashReportingEnabled = true,
    this.logShippingEnabled = true,
    this.metricsCollectionEnabled = true,
    this.healthMonitoringEnabled = true,
    this.alertEngineEnabled = true,
    this.distributedTracingEnabled = true,
    this.diagnosticsEnabled = true,
    this.workerMonitoringEnabled = true,
    this.dashboardEnabled = true,
  });

  final bool crashReportingEnabled;
  final bool logShippingEnabled;
  final bool metricsCollectionEnabled;
  final bool healthMonitoringEnabled;
  final bool alertEngineEnabled;
  final bool distributedTracingEnabled;
  final bool diagnosticsEnabled;
  final bool workerMonitoringEnabled;
  final bool dashboardEnabled;
}

// ═══════════════════════════════════════════════════════════════════════════
// SAMPLING RATES
// ═══════════════════════════════════════════════════════════════════════════

/// Sampling rates for different event types. 1.0 = capture all, 0.0 = none.
class SamplingRates {
  const SamplingRates({
    this.crashReports = 1.0,
    this.apiLatency = 1.0,
    this.aiLatency = 1.0,
    this.databaseLatency = 0.5,
    this.syncOperations = 1.0,
    this.examSubmissions = 1.0,
    this.uiEvents = 0.1,
    this.networkEvents = 0.3,
    this.logEntries = 0.5,
    this.healthChecks = 1.0,
  });

  final double crashReports;
  final double apiLatency;
  final double aiLatency;
  final double databaseLatency;
  final double syncOperations;
  final double examSubmissions;
  final double uiEvents;
  final double networkEvents;
  final double logEntries;
  final double healthChecks;
}

// ═══════════════════════════════════════════════════════════════════════════
// PRODUCTION MONITORING CONFIG
// ═══════════════════════════════════════════════════════════════════════════

/// Complete monitoring configuration for a specific environment.
class MonitoringConfig {
  const MonitoringConfig({
    required this.environment,
    required this.featureFlags,
    required this.samplingRates,
    required this.minimumLogLevel,
    required this.logShippingConfig,
    required this.alertThresholds,
    required this.healthCheckIntervalSeconds,
    required this.crashBufferLimit,
    required this.metricBufferLimit,
  });

  final Environment environment;
  final MonitoringFeatureFlags featureFlags;
  final SamplingRates samplingRates;
  final ExtendedLogLevel minimumLogLevel;
  final LogShippingConfig logShippingConfig;
  final AlertThresholds alertThresholds;
  final int healthCheckIntervalSeconds;
  final int crashBufferLimit;
  final int metricBufferLimit;

  /// Development environment configuration.
  static const MonitoringConfig development = MonitoringConfig(
    environment: Environment.development,
    featureFlags: MonitoringFeatureFlags(
      crashReportingEnabled: true,
      logShippingEnabled: false,  // local logging only in dev
      metricsCollectionEnabled: true,
      healthMonitoringEnabled: true,
      alertEngineEnabled: false,  // alerts disabled in dev
      distributedTracingEnabled: true,
      diagnosticsEnabled: true,
      workerMonitoringEnabled: true,
      dashboardEnabled: true,
    ),
    samplingRates: SamplingRates(
      crashReports: 1.0,
      apiLatency: 1.0,
      aiLatency: 1.0,
      databaseLatency: 1.0,
      syncOperations: 1.0,
      examSubmissions: 1.0,
      uiEvents: 1.0,  // capture all UI events in dev
      networkEvents: 1.0,
      logEntries: 1.0,
      healthChecks: 1.0,
    ),
    minimumLogLevel: ExtendedLogLevel.info,
    logShippingConfig: LogShippingConfig(
      batchSize: 10,
      shippingIntervalSeconds: 10,
      maxBufferSize: 100,
    ),
    alertThresholds: AlertThresholds(
      crashSpikeRate: 1,
      authFailureThreshold: 1,
      apiLatencyThresholdMs: 5000,
      databaseTimeoutMs: 10000,
    ),
    healthCheckIntervalSeconds: 10,
    crashBufferLimit: 100,
    metricBufferLimit: 200,
  );

  /// Staging environment configuration.
  static const MonitoringConfig staging = MonitoringConfig(
    environment: Environment.staging,
    featureFlags: MonitoringFeatureFlags(
      crashReportingEnabled: true,
      logShippingEnabled: true,
      metricsCollectionEnabled: true,
      healthMonitoringEnabled: true,
      alertEngineEnabled: true,
      distributedTracingEnabled: true,
      diagnosticsEnabled: true,
      workerMonitoringEnabled: true,
      dashboardEnabled: true,
    ),
    samplingRates: SamplingRates(
      crashReports: 1.0,
      apiLatency: 1.0,
      aiLatency: 0.8,
      databaseLatency: 0.7,
      syncOperations: 1.0,
      examSubmissions: 1.0,
      uiEvents: 0.5,
      networkEvents: 0.5,
      logEntries: 0.8,
      healthChecks: 1.0,
    ),
    minimumLogLevel: ExtendedLogLevel.info,
    logShippingConfig: LogShippingConfig(
      batchSize: 50,
      shippingIntervalSeconds: 30,
      maxBufferSize: 500,
    ),
    alertThresholds: AlertThresholds(
      crashSpikeRate: 5,
      authFailureThreshold: 3,
      apiLatencyThresholdMs: 3000,
      databaseTimeoutMs: 7000,
    ),
    healthCheckIntervalSeconds: 30,
    crashBufferLimit: 200,
    metricBufferLimit: 500,
  );

  /// Production environment configuration.
  static const MonitoringConfig production = MonitoringConfig(
    environment: Environment.production,
    featureFlags: MonitoringFeatureFlags(
      crashReportingEnabled: true,
      logShippingEnabled: true,
      metricsCollectionEnabled: true,
      healthMonitoringEnabled: true,
      alertEngineEnabled: true,
      distributedTracingEnabled: true,
      diagnosticsEnabled: false,  // diagnostics disabled in prod (security)
      workerMonitoringEnabled: true,
      dashboardEnabled: true,
    ),
    samplingRates: SamplingRates(
      crashReports: 1.0,  // always capture crashes
      apiLatency: 0.5,  // sample 50% of API calls
      aiLatency: 1.0,
      databaseLatency: 0.3,
      syncOperations: 1.0,
      examSubmissions: 1.0,  // always capture exam events
      uiEvents: 0.05,  // minimal UI sampling
      networkEvents: 0.2,
      logEntries: 0.3,
      healthChecks: 1.0,
    ),
    minimumLogLevel: ExtendedLogLevel.warning,
    logShippingConfig: LogShippingConfig(
      batchSize: 100,
      shippingIntervalSeconds: 60,
      maxBufferSize: 1000,
      compressionEnabled: true,
    ),
    alertThresholds: AlertThresholds(
      crashSpikeRate: 10,
      authFailureThreshold: 5,
      apiLatencyThresholdMs: 2000,
      databaseTimeoutMs: 5000,
    ),
    healthCheckIntervalSeconds: 60,
    crashBufferLimit: 200,
    metricBufferLimit: 500,
  );

  /// Resolve the correct configuration based on the current Flutter build mode.
  static MonitoringConfig resolve() {
    if (kDebugMode) return development;
    if (kProfileMode) return staging;
    return production;
  }

  Map<String, dynamic> toJson() => {
    'environment': environment.label,
    'feature_flags': {
      'crash_reporting': featureFlags.crashReportingEnabled,
      'log_shipping': featureFlags.logShippingEnabled,
      'metrics': featureFlags.metricsCollectionEnabled,
      'health_monitoring': featureFlags.healthMonitoringEnabled,
      'alert_engine': featureFlags.alertEngineEnabled,
      'tracing': featureFlags.distributedTracingEnabled,
      'diagnostics': featureFlags.diagnosticsEnabled,
      'workers': featureFlags.workerMonitoringEnabled,
      'dashboard': featureFlags.dashboardEnabled,
    },
    'sampling_rates': {
      'crash': samplingRates.crashReports,
      'api': samplingRates.apiLatency,
      'ai': samplingRates.aiLatency,
      'db': samplingRates.databaseLatency,
      'sync': samplingRates.syncOperations,
      'exam': samplingRates.examSubmissions,
      'ui': samplingRates.uiEvents,
      'network': samplingRates.networkEvents,
      'log': samplingRates.logEntries,
      'health': samplingRates.healthChecks,
    },
    'minimum_log_level': minimumLogLevel.name,
    'health_check_interval_s': healthCheckIntervalSeconds,
  };
}

// ═══════════════════════════════════════════════════════════════════════════
// RIVERPOD PROVIDERS
// ═══════════════════════════════════════════════════════════════════════════

/// Provider for resolved monitoring configuration (auto-selects environment).
final monitoringConfigProvider = Provider<MonitoringConfig>((ref) {
  final config = MonitoringConfig.resolve();
  StructuredLogger.info('Monitoring config resolved', metadata: config.toJson());
  return config;
});

/// Provider for feature flags (derived from config).
final monitoringFeatureFlagsProvider = Provider<MonitoringFeatureFlags>((ref) {
  final config = ref.watch(monitoringConfigProvider);
  return config.featureFlags;
});

/// Provider for sampling rates (derived from config).
final samplingRatesProvider = Provider<SamplingRates>((ref) {
  final config = ref.watch(monitoringConfigProvider);
  return config.samplingRates;
});

/// Provider for environment label.
final environmentLabelProvider = Provider<String>((ref) {
  final config = ref.watch(monitoringConfigProvider);
  return config.environment.label;
});
