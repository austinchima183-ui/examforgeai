// ===========================================================================
// ExamForge AI — Adaptive Connectivity Engine
// ===========================================================================
//
// A sophisticated network quality detection system that goes beyond simple
// online/offline. Designed for regions with inconsistent internet, this
// engine continuously monitors latency, bandwidth, and connection type to
// classify connectivity into four quality tiers and adapt application
// behaviour accordingly.
//
// Usage:
//   // In your provider scope:
//   final quality = ref.watch(connectionQualityProvider);
//   final behavior = ref.watch(adaptiveBehaviorProvider);
//
//   // Direct engine access:
//   ref.read(connectivityEngineProvider.notifier).startMonitoring();
// ===========================================================================

import 'dart:async';
import 'dart:collection';
import 'dart:math';

import 'package:dio/dio.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

import '../../config/dependency_injection.dart';
import '../errors/failures.dart';
import '../utils/logger.dart';
import '../utils/result.dart';

// ─────────────────────────────────────────────────────────────────────────────
// ConnectionQuality — Enhanced Enum
// ─────────────────────────────────────────────────────────────────────────────

/// Represents the quality tier of the current network connection.
///
/// Each tier carries metadata (label, minimum speed threshold, UI colour,
/// icon) so that the rest of the app can render appropriate feedback
/// without scattering magic numbers everywhere.
enum ConnectionQuality {
  excellent(
    value: 'excellent',
    label: 'Excellent',
    minSpeed: 1000,
    color: Colors.green,
    icon: Icons.signal_cellular_alt,
  ),
  good(
    value: 'good',
    label: 'Good',
    minSpeed: 500,
    color: Colors.blue,
    icon: Icons.signal_cellular_4_bar,
  ),
  limited(
    value: 'limited',
    label: 'Limited',
    minSpeed: 100,
    color: Colors.orange,
    icon: Icons.signal_cellular_connected_no_internet_4_bar,
  ),
  offline(
    value: 'offline',
    label: 'Offline',
    minSpeed: 0,
    color: Colors.red,
    icon: Icons.signal_cellular_off,
  );

  const ConnectionQuality({
    required this.value,
    required this.label,
    required this.minSpeed,
    required this.color,
    required this.icon,
  });

  /// String identifier used for serialisation / logging.
  final String value;

  /// Human-readable label for UI display.
  final String label;

  /// Minimum bandwidth (kbps) that qualifies for this tier.
  final int minSpeed;

  /// Semantic colour for status indicators.
  final Color color;

  /// Material icon for status indicators.
  final IconData icon;

  // ── Factory Constructors ──────────────────────────────────────────────

  /// Constructs a [ConnectionQuality] from its serialised [value] string.
  ///
  /// Returns [ConnectionQuality.offline] if the string does not match any
  /// known tier, which is the safest fallback.
  static ConnectionQuality fromString(String value) {
    return ConnectionQuality.values.firstWhere(
      (q) => q.value == value,
      orElse: () => ConnectionQuality.offline,
    );
  }

  /// Constructs a [ConnectionQuality] from a measured bandwidth in kbps.
  ///
  /// The classification walks from best to worst so that the highest
  /// qualifying tier wins.
  static ConnectionQuality fromSpeed(int bandwidthKbps) {
    if (bandwidthKbps >= ConnectionQuality.excellent.minSpeed) {
      return ConnectionQuality.excellent;
    }
    if (bandwidthKbps >= ConnectionQuality.good.minSpeed) {
      return ConnectionQuality.good;
    }
    if (bandwidthKbps >= ConnectionQuality.limited.minSpeed) {
      return ConnectionQuality.limited;
    }
    return ConnectionQuality.offline;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ConnectionType — Network Interface Classification
// ─────────────────────────────────────────────────────────────────────────────

/// Simplified classification of the physical network interface.
enum ConnectionType { wifi, mobile, ethernet, none }

// ─────────────────────────────────────────────────────────────────────────────
// ConnectivityState — Immutable State
// ─────────────────────────────────────────────────────────────────────────────

/// Immutable snapshot of the current connectivity situation.
///
/// Designed to be emitted by [ConnectivityEngine] via [StateNotifier].
/// Implements [Equatable] so that Riverpod can skip redundant rebuilds.
class ConnectivityState extends Equatable {
  const ConnectivityState({
    this.isOnline = false,
    this.connectionQuality = ConnectionQuality.offline,
    this.connectionType = ConnectionType.none,
    this.latencyMs = 0,
    this.bandwidthKbps = 0,
    this.isSyncing = false,
    this.lastOnlineAt,
    this.lastOfflineAt,
    this.offlineDuration,
    this.pendingSyncCount = 0,
    this.errorMessage,
    this.successMessage,
  });

  /// Whether the device currently has any network connectivity.
  final bool isOnline;

  /// Classified quality tier of the current connection.
  final ConnectionQuality connectionQuality;

  /// The physical network interface in use.
  final ConnectionType connectionType;

  /// Most recent round-trip latency in milliseconds.
  final int latencyMs;

  /// Estimated downstream bandwidth in kilobits per second.
  final int bandwidthKbps;

  /// Whether a background sync operation is currently in progress.
  final bool isSyncing;

  /// Timestamp of the last moment the device was confirmed online.
  final DateTime? lastOnlineAt;

  /// Timestamp of the last moment the device transitioned to offline.
  final DateTime? lastOfflineAt;

  /// Cumulative duration spent offline since the last online period.
  final Duration? offlineDuration;

  /// Number of operations queued for the next sync window.
  final int pendingSyncCount;

  /// Transient error message for UI display (cleared on next state).
  final String? errorMessage;

  /// Transient success message for UI display (cleared on next state).
  final String? successMessage;

  // ── Computed Getters ──────────────────────────────────────────────────

  bool get isExcellent => connectionQuality == ConnectionQuality.excellent;
  bool get isGood => connectionQuality == ConnectionQuality.good;
  bool get isLimited => connectionQuality == ConnectionQuality.limited;
  bool get isOffline => connectionQuality == ConnectionQuality.offline;

  /// Whether image payloads should be served at reduced quality.
  bool get shouldReduceImageQuality =>
      connectionQuality == ConnectionQuality.limited ||
      connectionQuality == ConnectionQuality.offline;

  /// Whether non-critical syncs should be deferred.
  bool get shouldDelaySync =>
      connectionQuality == ConnectionQuality.limited ||
      connectionQuality == ConnectionQuality.offline;

  /// Whether uploads should be compressed before transmission.
  bool get shouldCompressUploads =>
      connectionQuality == ConnectionQuality.limited ||
      connectionQuality == ConnectionQuality.good;

  /// Whether the app should switch to minimal-data mode (text-only,
  /// no pre-fetching, no auto-play).
  bool get shouldUseMinimalData =>
      connectionQuality == ConnectionQuality.limited ||
      connectionQuality == ConnectionQuality.offline;

  // ── copyWith ──────────────────────────────────────────────────────────

  /// Returns a new [ConnectivityState] with the specified fields replaced.
  ///
  /// Nullable fields that are *not* passed retain their current value.
  /// To explicitly reset [lastOnlineAt], [lastOfflineAt], or
  /// [offlineDuration], pass `null` through the corresponding parameter.
  ConnectivityState copyWith({
    bool? isOnline,
    ConnectionQuality? connectionQuality,
    ConnectionType? connectionType,
    int? latencyMs,
    int? bandwidthKbps,
    bool? isSyncing,
    DateTime? lastOnlineAt,
    DateTime? lastOfflineAt,
    Duration? offlineDuration,
    int? pendingSyncCount,
    String? errorMessage,
    String? successMessage,
    bool clearOfflineDuration = false,
    bool clearLastOnlineAt = false,
    bool clearLastOfflineAt = false,
  }) {
    return ConnectivityState(
      isOnline: isOnline ?? this.isOnline,
      connectionQuality: connectionQuality ?? this.connectionQuality,
      connectionType: connectionType ?? this.connectionType,
      latencyMs: latencyMs ?? this.latencyMs,
      bandwidthKbps: bandwidthKbps ?? this.bandwidthKbps,
      isSyncing: isSyncing ?? this.isSyncing,
      lastOnlineAt: clearLastOnlineAt ? null : (lastOnlineAt ?? this.lastOnlineAt),
      lastOfflineAt: clearLastOfflineAt ? null : (lastOfflineAt ?? this.lastOfflineAt),
      offlineDuration: clearOfflineDuration ? null : (offlineDuration ?? this.offlineDuration),
      pendingSyncCount: pendingSyncCount ?? this.pendingSyncCount,
      errorMessage: errorMessage,
      successMessage: successMessage,
    );
  }

  /// Convenience that returns a copy with [errorMessage] cleared.
  ConnectivityState clearError() => copyWith(errorMessage: null);

  /// Convenience that returns a copy with [successMessage] cleared.
  ConnectivityState clearSuccess() => copyWith(successMessage: null);

  @override
  List<Object?> get props => [
        isOnline,
        connectionQuality,
        connectionType,
        latencyMs,
        bandwidthKbps,
        isSyncing,
        lastOnlineAt,
        lastOfflineAt,
        offlineDuration,
        pendingSyncCount,
        errorMessage,
        successMessage,
      ];

  @override
  String toString() => 'ConnectivityState('
      'isOnline: $isOnline, '
      'quality: ${connectionQuality.value}, '
      'type: ${connectionType.name}, '
      'latency: ${latencyMs}ms, '
      'bandwidth: ${bandwidthKbps}kbps, '
      'syncing: $isSyncing, '
      'pendingSync: $pendingSyncCount'
      ')';
}

// ─────────────────────────────────────────────────────────────────────────────
// ConnectivityEngine — Core Monitoring & Classification Engine
// ─────────────────────────────────────────────────────────────────────────────

/// The core engine that monitors and classifies network connectivity.
///
/// Extends [StateNotifier] so that any widget or provider watching
/// [connectivityEngineProvider] rebuilds automatically when connectivity
/// state changes.
///
/// The engine runs a periodic health-check loop that:
///   1. Checks the physical connection type via `connectivity_plus`.
///   2. Measures latency by sending an HTTP HEAD request to a known
///      lightweight endpoint and recording the RTT.
///   3. Estimates bandwidth by downloading a small test payload and
///      computing the transfer speed, smoothed with a moving average.
///   4. Classifies the combined metrics into a [ConnectionQuality] tier.
///   5. Emits an updated [ConnectivityState] only when the quality tier
///      actually changes (debounced to avoid flicker).
class ConnectivityEngine extends StateNotifier<ConnectivityState> {
  ConnectivityEngine({
    required Connectivity connectivity,
    required Dio dio,
    this.pingEndpoint = 'https://www.google.com/generate_204',
    this.bandwidthTestUrl =
        'https://www.google.com/generate_204', // lightweight; size ≈ 0
    this.checkInterval = const Duration(seconds: 15),
    this.latencyHistorySize = 10,
    this.bandwidthHistorySize = 5,
    this.qualityDebounceDuration = const Duration(seconds: 3),
  })  : _connectivity = connectivity,
        _dio = dio,
        super(const ConnectivityState()) {
    _init();
  }

  // ── Dependencies ──────────────────────────────────────────────────────
  final Connectivity _connectivity;
  final Dio _dio;

  // ── Configuration ─────────────────────────────────────────────────────

  /// Endpoint used for latency measurement (HTTP HEAD → RTT).
  final String pingEndpoint;

  /// URL used for bandwidth estimation downloads.
  final String bandwidthTestUrl;

  /// How often the engine runs a full health-check cycle.
  final Duration checkInterval;

  /// Number of recent latency samples to keep for smoothing.
  final int latencyHistorySize;

  /// Number of recent bandwidth samples to keep for smoothing.
  final int bandwidthHistorySize;

  /// Minimum time the engine waits before committing to a quality-tier
  /// change, to avoid rapid flickering between tiers.
  final Duration qualityDebounceDuration;

  // ── Internal State ────────────────────────────────────────────────────

  Timer? _monitorTimer;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  DateTime? _lastQualityChangeAt;
  ConnectionQuality? _pendingQuality;
  Timer? _qualityDebounceTimer;

  /// Ring-buffer of recent latency measurements (ms).
  final Queue<int> _latencyHistory = ListQueue<int>();

  /// Ring-buffer of recent bandwidth measurements (kbps).
  final Queue<int> _bandwidthHistory = ListQueue<int>();

  bool _isDisposed = false;

  // ── Initialisation ────────────────────────────────────────────────────

  void _init() {
    // Subscribe to platform connectivity changes for immediate feedback.
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
      _onConnectivityChanged,
      onError: (Object error) {
        AppLogger.error('Connectivity stream error', error: error);
      },
    );

    // Perform an initial check so we don't start with a stale state.
    _performHealthCheck();
  }

  // ── Public API ────────────────────────────────────────────────────────

  /// Begins periodic health-check monitoring.
  ///
  /// If monitoring is already active this call is a no-op.
  void startMonitoring() {
    if (_monitorTimer != null) return;
    AppLogger.info('ConnectivityEngine: monitoring started');
    _monitorTimer = Timer.periodic(checkInterval, (_) => _performHealthCheck());
  }

  /// Stops periodic health-check monitoring.
  ///
  /// The connectivity-type subscription remains active so the engine
  /// still reacts to physical network changes instantly.
  void stopMonitoring() {
    _monitorTimer?.cancel();
    _monitorTimer = null;
    _qualityDebounceTimer?.cancel();
    _qualityDebounceTimer = null;
    AppLogger.info('ConnectivityEngine: monitoring stopped');
  }

  /// Sends a lightweight HTTP HEAD request to [pingEndpoint] and returns
  /// the round-trip time in milliseconds.
  ///
  /// Returns a [Success] containing the latency in ms, or a
  /// [FailureResult] with a [Failure.network] if the request fails.
  Future<Result<int>> measureLatency() async {
    try {
      final stopwatch = Stopwatch()..start();
      await _dio.head<void>(
        pingEndpoint,
        options: Options(
          sendTimeout: const Duration(seconds: 5),
          receiveTimeout: const Duration(seconds: 5),
          // Prevent Dio from following redirects — we only need the RTT.
          followRedirects: false,
          validateStatus: (status) => status != null && status < 400,
        ),
      );
      stopwatch.stop();
      final latency = stopwatch.elapsedMilliseconds;
      AppLogger.debug('Latency measured: ${latency}ms');
      return Success(latency);
    } on DioException catch (e) {
      AppLogger.warning('Latency measurement failed: ${e.message}');
      return FailureResult(Failure.network(
        message: 'Latency measurement failed: ${e.message}',
      ));
    } catch (e) {
      AppLogger.warning('Latency measurement error: $e');
      return FailureResult(Failure.network(
        message: 'Latency measurement error: $e',
      ));
    }
  }

  /// Downloads a small test payload from [bandwidthTestUrl] and estimates
  /// the downstream bandwidth in kbps.
  ///
  /// Returns a [Success] containing the bandwidth in kbps, or a
  /// [FailureResult] with a [Failure.network] if the measurement cannot be
  /// completed.
  Future<Result<int>> estimateBandwidth() async {
    try {
      final stopwatch = Stopwatch()..start();
      final response = await _dio.get<List<int>>(
        bandwidthTestUrl,
        options: Options(
          responseType: ResponseType.bytes,
          sendTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
          validateStatus: (status) => status != null && status < 400,
        ),
      );
      stopwatch.stop();

      final bytesDownloaded = response.data?.length ?? 0;
      final elapsedSeconds = stopwatch.elapsedMilliseconds / 1000.0;

      if (elapsedSeconds <= 0 || bytesDownloaded <= 0) {
        return FailureResult(Failure.network(
          message: 'Bandwidth estimation: insufficient data received',
        ));
      }

      // Convert bytes/s → kilobits/s.
      final bytesPerSecond = bytesDownloaded / elapsedSeconds;
      final kbps = (bytesPerSecond * 8 / 1000).round();

      AppLogger.debug('Bandwidth estimated: $kbps kbps');
      return Success(kbps);
    } on DioException catch (e) {
      AppLogger.warning('Bandwidth estimation failed: ${e.message}');
      return FailureResult(Failure.network(
        message: 'Bandwidth estimation failed: ${e.message}',
      ));
    } catch (e) {
      AppLogger.warning('Bandwidth estimation error: $e');
      return FailureResult(Failure.network(
        message: 'Bandwidth estimation error: $e',
      ));
    }
  }

  /// Classifies the current connection quality from the latest metrics.
  ///
  /// Algorithm:
  ///   - **offline**: no connectivity detected.
  ///   - **limited**: latency > 500 ms **OR** bandwidth < 100 kbps.
  ///   - **good**: latency 100-500 ms **AND** bandwidth 100-500 kbps.
  ///   - **excellent**: latency < 100 ms **AND** bandwidth > 500 kbps.
  ConnectionQuality classifyQuality({
    required bool isOnline,
    required int latencyMs,
    required int bandwidthKbps,
  }) {
    if (!isOnline) return ConnectionQuality.offline;
    if (latencyMs > 500 || bandwidthKbps < 100) {
      return ConnectionQuality.limited;
    }
    if (latencyMs <= 100 && bandwidthKbps > 500) {
      return ConnectionQuality.excellent;
    }
    return ConnectionQuality.good;
  }

  /// Returns the current [ConnectionQuality] without triggering a check.
  ConnectionQuality getConnectionQuality() => state.connectionQuality;

  /// Whether a sync operation should proceed given current conditions.
  ///
  /// Syncing is allowed on *excellent* and *good* connections, deferred on
  /// *limited*, and never attempted on *offline*.
  bool shouldPerformSync() {
    final q = state.connectionQuality;
    return q == ConnectionQuality.excellent || q == ConnectionQuality.good;
  }

  /// Whether file downloads should proceed given current conditions.
  ///
  /// Downloads are allowed on *excellent*, *good*, and *limited*
  /// connections (the caller should adapt chunk size on *limited*), but
  /// not on *offline*.
  bool shouldDownloadFiles() {
    return state.connectionQuality != ConnectionQuality.offline;
  }

  /// Returns an image quality scalar (0.0 – 1.0) based on connection quality.
  ///
  ///   - excellent → 1.0
  ///   - good → 0.8
  ///   - limited → 0.5
  ///   - offline → 0.0
  double getImageQuality() {
    switch (state.connectionQuality) {
      case ConnectionQuality.excellent:
        return 1.0;
      case ConnectionQuality.good:
        return 0.8;
      case ConnectionQuality.limited:
        return 0.5;
      case ConnectionQuality.offline:
        return 0.0;
    }
  }

  /// Returns a compression level (1–9) for uploads based on quality.
  ///
  ///   - excellent → 1 (fastest, least compression)
  ///   - good → 3
  ///   - limited → 7
  ///   - offline → 9 (max compression, will be queued)
  int getCompressionLevel() {
    switch (state.connectionQuality) {
      case ConnectionQuality.excellent:
        return 1;
      case ConnectionQuality.good:
        return 3;
      case ConnectionQuality.limited:
        return 7;
      case ConnectionQuality.offline:
        return 9;
    }
  }

  /// Returns the recommended sync batch size for the current quality tier.
  ///
  ///   - excellent → 50
  ///   - good → 20
  ///   - limited → 5
  ///   - offline → 0
  int getSyncBatchSize() {
    switch (state.connectionQuality) {
      case ConnectionQuality.excellent:
        return 50;
      case ConnectionQuality.good:
        return 20;
      case ConnectionQuality.limited:
        return 5;
      case ConnectionQuality.offline:
        return 0;
    }
  }

  // ── Internal Health-Check Cycle ───────────────────────────────────────

  Future<void> _performHealthCheck() async {
    if (_isDisposed) return;

    try {
      // 1. Determine physical connection type.
      final connectivityResults = await _connectivity.checkConnectivity();
      final connectionType = _mapConnectivityResult(connectivityResults);
      final isOnline = connectionType != ConnectionType.none;

      // 2. Measure latency (if online).
      int? latencyMs;
      if (isOnline) {
        final result = await measureLatency();
        latencyMs = result.getOrElse(999); // pessimistic default on failure
      }

      // 3. Estimate bandwidth (if online and latency succeeded).
      int? bandwidthKbps;
      if (isOnline && latencyMs != null) {
        final result = await estimateBandwidth();
        bandwidthKbps = result.getOrElse(0); // conservative default
      }

      // 4. Update rolling histories.
      if (latencyMs != null) _addToHistory(_latencyHistory, latencyMs);
      if (bandwidthKbps != null) {
        _addToHistory(_bandwidthHistory, bandwidthKbps);
      }

      // 5. Compute smoothed metrics.
      final smoothedLatency = _latencyHistory.isNotEmpty
          ? _latencyHistory.reduce((a, b) => a + b) ~/
              _latencyHistory.length
          : (isOnline ? 999 : 0);
      final smoothedBandwidth = _bandwidthHistory.isNotEmpty
          ? _bandwidthHistory.reduce((a, b) => a + b) ~/
              _bandwidthHistory.length
          : (isOnline ? 0 : 0);

      // 6. Classify quality.
      final quality = classifyQuality(
        isOnline: isOnline,
        latencyMs: smoothedLatency,
        bandwidthKbps: smoothedBandwidth,
      );

      // 7. Build the new state.
      _applyQualityChange(
        quality: quality,
        connectionType: connectionType,
        isOnline: isOnline,
        latencyMs: smoothedLatency,
        bandwidthKbps: smoothedBandwidth,
      );
    } catch (e, st) {
      AppLogger.error('Health check failed', error: e, stackTrace: st);
    }
  }

  /// Reacts to platform connectivity-change events immediately.
  void _onConnectivityChanged(List<ConnectivityResult> results) {
    if (_isDisposed) return;

    final connectionType = _mapConnectivityResult(results);
    final isOnline = connectionType != ConnectionType.none;

    AppLogger.info(
      'Connectivity changed: ${results.map((r) => r.name).join(', ')} '
      '→ type=$connectionType, online=$isOnline',
    );

    // Immediately update online status; full metrics will follow on
    // the next health-check cycle.
    if (!isOnline) {
      // Went offline — update immediately for snappy UI.
      _applyQualityChange(
        quality: ConnectionQuality.offline,
        connectionType: connectionType,
        isOnline: false,
        latencyMs: 0,
        bandwidthKbps: 0,
      );
    } else {
      // Came online — trigger an immediate health check.
      _performHealthCheck();
    }
  }

  /// Applies a quality-tier change, respecting the debounce window to
  /// prevent rapid flicker between tiers.
  void _applyQualityChange({
    required ConnectionQuality quality,
    required ConnectionType connectionType,
    required bool isOnline,
    required int latencyMs,
    required int bandwidthKbps,
  }) {
    if (_isDisposed) return;

    final now = DateTime.now();
    final previousQuality = state.connectionQuality;

    // Determine timestamps and offline duration.
    DateTime? lastOnlineAt = state.lastOnlineAt;
    DateTime? lastOfflineAt = state.lastOfflineAt;
    Duration? offlineDuration = state.offlineDuration;
    bool clearOfflineDuration = false;

    if (isOnline && !state.isOnline) {
      // Transitioned from offline → online.
      lastOnlineAt = now;
      if (state.lastOfflineAt != null) {
        offlineDuration = now.difference(state.lastOfflineAt!);
      }
    } else if (!isOnline && state.isOnline) {
      // Transitioned from online → offline.
      lastOfflineAt = now;
      clearOfflineDuration = true;
    }

    // If quality hasn't changed, just update metrics silently.
    if (quality == previousQuality) {
      _qualityDebounceTimer?.cancel();
      _qualityDebounceTimer = null;
      _pendingQuality = null;
      _lastQualityChangeAt = now;

      state = state.copyWith(
        isOnline: isOnline,
        connectionType: connectionType,
        latencyMs: latencyMs,
        bandwidthKbps: bandwidthKbps,
        lastOnlineAt: lastOnlineAt,
        lastOfflineAt: lastOfflineAt,
        offlineDuration: offlineDuration,
        clearOfflineDuration: clearOfflineDuration,
      );
      return;
    }

    // Quality has changed — apply debounce unless going offline (instant).
    if (quality == ConnectionQuality.offline) {
      // Going offline should be instant — no debounce.
      _qualityDebounceTimer?.cancel();
      _qualityDebounceTimer = null;
      _pendingQuality = null;
      _lastQualityChangeAt = now;

      state = state.copyWith(
        isOnline: isOnline,
        connectionQuality: quality,
        connectionType: connectionType,
        latencyMs: latencyMs,
        bandwidthKbps: bandwidthKbps,
        lastOnlineAt: lastOnlineAt,
        lastOfflineAt: lastOfflineAt,
        offlineDuration: offlineDuration,
        clearOfflineDuration: clearOfflineDuration,
        errorMessage: 'You are offline. Some features may be unavailable.',
      );

      AppLogger.info(
        'Connectivity quality: ${previousQuality.value} → ${quality.value}',
      );
      return;
    }

    // Debounce quality upgrades / downgrades while online.
    if (_pendingQuality == quality && _qualityDebounceTimer != null) {
      // Already debouncing this exact change — wait for timer.
      // Still update the raw metrics so they stay current.
      state = state.copyWith(
        isOnline: isOnline,
        connectionType: connectionType,
        latencyMs: latencyMs,
        bandwidthKbps: bandwidthKbps,
        lastOnlineAt: lastOnlineAt,
        lastOfflineAt: lastOfflineAt,
        offlineDuration: offlineDuration,
        clearOfflineDuration: clearOfflineDuration,
      );
      return;
    }

    // New quality change — start debounce timer.
    _pendingQuality = quality;
    _qualityDebounceTimer?.cancel();
    _qualityDebounceTimer = Timer(qualityDebounceDuration, () {
      if (_isDisposed || _pendingQuality == null) return;

      final committedQuality = _pendingQuality!;
      _pendingQuality = null;
      _lastQualityChangeAt = DateTime.now();

      String? successMsg;
      if (committedQuality.index < previousQuality.index) {
        // Quality improved (lower index = better).
        successMsg = 'Connection improved to ${committedQuality.label}';
      }

      state = state.copyWith(
        isOnline: isOnline,
        connectionQuality: committedQuality,
        connectionType: connectionType,
        latencyMs: latencyMs,
        bandwidthKbps: bandwidthKbps,
        lastOnlineAt: lastOnlineAt,
        lastOfflineAt: lastOfflineAt,
        offlineDuration: offlineDuration,
        clearOfflineDuration: clearOfflineDuration,
        successMessage: successMsg,
      );

      AppLogger.info(
        'Connectivity quality (debounced): '
        '${previousQuality.value} → ${committedQuality.value}',
      );
    });

    // Update metrics immediately even while debouncing quality tier.
    state = state.copyWith(
      isOnline: isOnline,
      connectionType: connectionType,
      latencyMs: latencyMs,
      bandwidthKbps: bandwidthKbps,
      lastOnlineAt: lastOnlineAt,
      lastOfflineAt: lastOfflineAt,
      offlineDuration: offlineDuration,
      clearOfflineDuration: clearOfflineDuration,
    );
  }

  // ── Utility Helpers ───────────────────────────────────────────────────

  /// Maps platform connectivity results to our [ConnectionType] enum.
  static ConnectionType _mapConnectivityResult(
    List<ConnectivityResult> results,
  ) {
    if (results.isEmpty || results.every((r) => r == ConnectivityResult.none)) {
      return ConnectionType.none;
    }
    if (results.contains(ConnectivityResult.wifi)) {
      return ConnectionType.wifi;
    }
    if (results.contains(ConnectivityResult.ethernet)) {
      return ConnectionType.ethernet;
    }
    if (results.contains(ConnectivityResult.mobile)) {
      return ConnectionType.mobile;
    }
    // VPN, bluetooth, other — treat as mobile for conservative estimates.
    if (results.contains(ConnectivityResult.vpn) ||
        results.contains(ConnectivityResult.bluetooth) ||
        results.contains(ConnectivityResult.other)) {
      return ConnectionType.mobile;
    }
    return ConnectionType.none;
  }

  /// Adds a measurement to a ring-buffer and trims to [maxSize].
  void _addToHistory(Queue<int> history, int value) {
    history.addLast(value);
    while (history.length > latencyHistorySize) {
      history.removeFirst();
    }
  }

  // ── Testing Hooks ─────────────────────────────────────────────────────

  /// Exposes the latency history for testing / diagnostics.
  @visibleForTesting
  List<int> get latencyHistory => List.unmodifiable(_latencyHistory);

  /// Exposes the bandwidth history for testing / diagnostics.
  @visibleForTesting
  List<int> get bandwidthHistory => List.unmodifiable(_bandwidthHistory);

  /// Allows tests to inject a connectivity result without waiting for
  /// the platform stream.
  @visibleForTesting
  void simulateConnectivityChange(List<ConnectivityResult> results) {
    _onConnectivityChanged(results);
  }

  /// Allows tests to inject measured metrics directly.
  @visibleForTesting
  void simulateMetrics({
    required bool isOnline,
    required int latencyMs,
    required int bandwidthKbps,
    ConnectionType connectionType = ConnectionType.wifi,
  }) {
    _addToHistory(_latencyHistory, latencyMs);
    _addToHistory(_bandwidthHistory, bandwidthKbps);

    final quality = classifyQuality(
      isOnline: isOnline,
      latencyMs: latencyMs,
      bandwidthKbps: bandwidthKbps,
    );

    _applyQualityChange(
      quality: quality,
      connectionType: connectionType,
      isOnline: isOnline,
      latencyMs: latencyMs,
      bandwidthKbps: bandwidthKbps,
    );
  }

  // ── Lifecycle ─────────────────────────────────────────────────────────

  @override
  void dispose() {
    _isDisposed = true;
    _monitorTimer?.cancel();
    _connectivitySubscription?.cancel();
    _qualityDebounceTimer?.cancel();
    _latencyHistory.clear();
    _bandwidthHistory.clear();
    super.dispose();
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// AdaptiveBehavior — Quality-Driven Behaviour Adjustments
// ─────────────────────────────────────────────────────────────────────────────

/// Configures adaptive responses based on the current [ConnectivityState].
///
/// Instead of scattering quality-checking conditionals throughout the
/// codebase, centralise every adaptive decision here. Each method is a
/// pure function of the current connectivity state, making it trivial to
/// test and reason about.
class AdaptiveBehavior {
  const AdaptiveBehavior(this._state);

  final ConnectivityState _state;

  // ── Image Quality ─────────────────────────────────────────────────────

  /// Image quality scalar from 0.0 (lowest) to 1.0 (original).
  ///
  ///   - excellent → 1.0
  ///   - good → 0.8
  ///   - limited → 0.5
  ///   - offline → 0.0
  double get imageQuality {
    switch (_state.connectionQuality) {
      case ConnectionQuality.excellent:
        return 1.0;
      case ConnectionQuality.good:
        return 0.8;
      case ConnectionQuality.limited:
        return 0.5;
      case ConnectionQuality.offline:
        return 0.0;
    }
  }

  // ── Sync Interval ─────────────────────────────────────────────────────

  /// Recommended interval between automatic sync operations.
  ///
  ///   - excellent → 30 s
  ///   - good → 1 min
  ///   - limited → 5 min
  ///   - offline → never (Duration.zero sentinel; caller should not sync)
  Duration get syncInterval {
    switch (_state.connectionQuality) {
      case ConnectionQuality.excellent:
        return const Duration(seconds: 30);
      case ConnectionQuality.good:
        return const Duration(minutes: 1);
      case ConnectionQuality.limited:
        return const Duration(minutes: 5);
      case ConnectionQuality.offline:
        return Duration.zero;
    }
  }

  // ── Upload Compression ────────────────────────────────────────────────

  /// Compression level (1–9) for uploads. Higher = more compression.
  ///
  ///   - excellent → 1
  ///   - good → 3
  ///   - limited → 7
  ///   - offline → 9 (queued for later)
  int get uploadCompressionLevel {
    switch (_state.connectionQuality) {
      case ConnectionQuality.excellent:
        return 1;
      case ConnectionQuality.good:
        return 3;
      case ConnectionQuality.limited:
        return 7;
      case ConnectionQuality.offline:
        return 9;
    }
  }

  // ── Batch Size ────────────────────────────────────────────────────────

  /// Recommended batch size for sync operations.
  ///
  ///   - excellent → 50
  ///   - good → 20
  ///   - limited → 5
  ///   - offline → 0
  int get batchSize {
    switch (_state.connectionQuality) {
      case ConnectionQuality.excellent:
        return 50;
      case ConnectionQuality.good:
        return 20;
      case ConnectionQuality.limited:
        return 5;
      case ConnectionQuality.offline:
        return 0;
    }
  }

  // ── Preloading ────────────────────────────────────────────────────────

  /// Whether images should be pre-loaded / cached proactively.
  bool get shouldPreloadImages {
    return _state.connectionQuality == ConnectionQuality.excellent ||
        _state.connectionQuality == ConnectionQuality.good;
  }

  // ── Background Fetch ──────────────────────────────────────────────────

  /// Whether background data fetches should be scheduled.
  bool get shouldBackgroundFetch {
    return _state.connectionQuality == ConnectionQuality.excellent ||
        _state.connectionQuality == ConnectionQuality.good;
  }

  // ── Cache Size ────────────────────────────────────────────────────────

  /// Maximum cache size in megabytes.
  ///
  ///   - excellent → 500 MB (pre-load aggressively)
  ///   - good → 200 MB
  ///   - limited → 50 MB
  ///   - offline → 10 MB (only essential cached content)
  int get maxCacheSize {
    switch (_state.connectionQuality) {
      case ConnectionQuality.excellent:
        return 500;
      case ConnectionQuality.good:
        return 200;
      case ConnectionQuality.limited:
        return 50;
      case ConnectionQuality.offline:
        return 10;
    }
  }

  // ── Video Autoplay ────────────────────────────────────────────────────

  /// Whether videos should auto-play in feeds.
  bool get shouldAutoPlayVideo {
    return _state.connectionQuality == ConnectionQuality.excellent;
  }

  // ── Full Content ──────────────────────────────────────────────────────

  /// Whether full content (images, rich media) should be loaded.
  bool get shouldLoadFullContent {
    return _state.connectionQuality == ConnectionQuality.excellent ||
        _state.connectionQuality == ConnectionQuality.good;
  }

  // ── Retry Delay ───────────────────────────────────────────────────────

  /// Exponential retry delay based on connection quality.
  ///
  ///   - excellent → 1 s base × 2^attempt
  ///   - good → 2 s base × 2^attempt
  ///   - limited → 5 s base × 2^attempt
  ///   - offline → 30 s base × 2^attempt
  Duration retryDelay({int attempt = 0}) {
    final baseSeconds = switch (_state.connectionQuality) {
      ConnectionQuality.excellent => 1,
      ConnectionQuality.good => 2,
      ConnectionQuality.limited => 5,
      ConnectionQuality.offline => 30,
    };
    final multiplier = pow(2, attempt).toInt();
    return Duration(seconds: baseSeconds * multiplier);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Riverpod Providers
// ─────────────────────────────────────────────────────────────────────────────

/// Primary provider: the [ConnectivityEngine] state notifier.
///
/// Watches [dioProvider] from the DI container so that the engine
/// always uses the currently configured Dio instance.
final connectivityEngineProvider =
    StateNotifierProvider<ConnectivityEngine, ConnectivityState>((ref) {
  final connectivity = Connectivity();
  final dio = ref.watch(dioProvider);

  final engine = ConnectivityEngine(
    connectivity: connectivity,
    dio: dio,
  );

  // Auto-start monitoring and clean up on dispose.
  engine.startMonitoring();
  ref.onDispose(() => engine.stopMonitoring());

  return engine;
});

/// Derived provider: current [ConnectionQuality].
final connectionQualityProvider = Provider<ConnectionQuality>((ref) {
  return ref.watch(connectivityEngineProvider).connectionQuality;
});

/// Derived provider: whether the device is currently online.
final isOnlineProvider = Provider<bool>((ref) {
  return ref.watch(connectivityEngineProvider).isOnline;
});

/// Derived provider: the [AdaptiveBehavior] for the current state.
final adaptiveBehaviorProvider = Provider<AdaptiveBehavior>((ref) {
  final state = ref.watch(connectivityEngineProvider);
  return AdaptiveBehavior(state);
});

/// Derived provider: whether image quality should be reduced.
final shouldReduceQualityProvider = Provider<bool>((ref) {
  return ref.watch(connectivityEngineProvider).shouldReduceImageQuality;
});

/// Derived provider: recommended sync batch size.
final syncBatchSizeProvider = Provider<int>((ref) {
  return ref.watch(connectivityEngineProvider).connectionQuality ==
          ConnectionQuality.offline
      ? 0
      : AdaptiveBehavior(ref.watch(connectivityEngineProvider)).batchSize;
});
