// ===========================================================================
// ExamForge AI — Smart Synchronization Engine
// ===========================================================================
//
// The heart of the offline-first architecture. Manages a persistent queue
// of pending operations, processes them in priority order respecting
// connectivity quality, detects and resolves conflicts, and provides
// an [OfflineAwareRepository] mixin so any repository can transparently
// fall back to cached data when offline.
//
// Usage:
//   // Watch sync state:
//   final syncState = ref.watch(syncEngineProvider);
//
//   // Enqueue an operation:
//   ref.read(syncEngineProvider.notifier).enqueueOperation(
//     tableName: 'questions',
//     operation: SyncOperationType.insert,
//     payload: {'title': 'New Question', ...},
//     priority: SyncPriority.high,
//   );
//
//   // Use offline-aware execution:
//   final result = await OfflineAwareRepository(ref).executeOfflineAware(
//     remoteCall: () => apiClient.get('/questions'),
//     localFallback: () => cacheManager.getCachedData(...),
//     tableName: 'questions',
//     operation: SyncOperationType.insert,
//     syncPayload: data,
//   );
// ===========================================================================

import 'dart:async';
import 'dart:convert';

import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;
import 'package:uuid/uuid.dart';

import '../../config/dependency_injection.dart';
import '../connectivity/connectivity_engine.dart';
import '../errors/failures.dart';
import '../storage/cache_manager.dart';
import '../storage/local_database.dart';
import '../utils/logger.dart';
import '../utils/result.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// SYNC OPERATION TYPE — Enhanced Enum
// ═══════════════════════════════════════════════════════════════════════════════

/// Represents the type of database operation being synced.
enum SyncOperationType {
  insert(value: 'insert', label: 'Insert'),
  update(value: 'update', label: 'Update'),
  delete(value: 'delete', label: 'Delete');

  const SyncOperationType({required this.value, required this.label});

  /// String identifier used for serialisation and database storage.
  final String value;

  /// Human-readable label for UI display and logging.
  final String label;

  /// Constructs a [SyncOperationType] from its serialised [value] string.
  ///
  /// Returns [SyncOperationType.update] as a safe default if the string
  /// does not match any known operation type.
  static SyncOperationType fromString(String value) {
    return SyncOperationType.values.firstWhere(
      (t) => t.value == value,
      orElse: () => SyncOperationType.update,
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// SYNC STATUS — Enhanced Enum
// ═══════════════════════════════════════════════════════════════════════════════

/// Represents the lifecycle state of a sync queue item.
enum SyncStatus {
  pending(value: 'pending', label: 'Pending'),
  inProgress(value: 'in_progress', label: 'In Progress'),
  completed(value: 'completed', label: 'Completed'),
  failed(value: 'failed', label: 'Failed'),
  dead(value: 'dead', label: 'Dead'),
  conflict(value: 'conflict', label: 'Conflict');

  const SyncStatus({required this.value, required this.label});

  /// String identifier used for serialisation and database storage.
  final String value;

  /// Human-readable label for UI display and logging.
  final String label;

  /// Constructs a [SyncStatus] from its serialised [value] string.
  ///
  /// Returns [SyncStatus.pending] as a safe default if the string
  /// does not match any known status.
  static SyncStatus fromString(String value) {
    return SyncStatus.values.firstWhere(
      (s) => s.value == value,
      orElse: () => SyncStatus.pending,
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// CONFLICT RESOLUTION — Enhanced Enum
// ═══════════════════════════════════════════════════════════════════════════════

/// Strategy for resolving a sync conflict between local and server data.
enum ConflictResolution {
  localWins(value: 'local_wins', label: 'Local Wins'),
  serverWins(value: 'server_wins', label: 'Server Wins'),
  merge(value: 'merge', label: 'Merge'),
  manual(value: 'manual', label: 'Manual');

  const ConflictResolution({required this.value, required this.label});

  /// String identifier used for serialisation and database storage.
  final String value;

  /// Human-readable label for UI display and logging.
  final String label;

  /// Constructs a [ConflictResolution] from its serialised [value] string.
  ///
  /// Returns [ConflictResolution.manual] as a safe default so that
  /// unrecognised strategies never silently discard data.
  static ConflictResolution fromString(String value) {
    return ConflictResolution.values.firstWhere(
      (r) => r.value == value,
      orElse: () => ConflictResolution.manual,
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// SYNC PRIORITY — Enhanced Enum
// ═══════════════════════════════════════════════════════════════════════════════

/// Priority level for a sync queue item. Lower values are processed first.
///
/// The [level] integer is used for sorting; the semantic names are for
/// human consumption and UI rendering.
enum SyncPriority {
  critical(value: 'critical', label: 'Critical', level: 1),
  high(value: 'high', label: 'High', level: 3),
  normal(value: 'normal', label: 'Normal', level: 5),
  low(value: 'low', label: 'Low', level: 7),
  background(value: 'background', label: 'Background', level: 10);

  const SyncPriority({
    required this.value,
    required this.label,
    required this.level,
  });

  /// String identifier used for serialisation and database storage.
  final String value;

  /// Human-readable label for UI display and logging.
  final String label;

  /// Numeric level used for priority sorting (lower = higher priority).
  final int level;

  /// Constructs a [SyncPriority] from its serialised [value] string.
  ///
  /// Returns [SyncPriority.normal] as a safe default.
  static SyncPriority fromString(String value) {
    return SyncPriority.values.firstWhere(
      (p) => p.value == value,
      orElse: () => SyncPriority.normal,
    );
  }

  /// Constructs a [SyncPriority] from its numeric [level].
  ///
  /// Returns [SyncPriority.normal] if no priority matches exactly.
  static SyncPriority fromLevel(int level) {
    return SyncPriority.values.firstWhere(
      (p) => p.level == level,
      orElse: () => SyncPriority.normal,
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// SYNC QUEUE ITEM
// ═══════════════════════════════════════════════════════════════════════════════

/// Represents a single pending sync operation in the persistent queue.
///
/// Instances are stored in the local [LocalSyncQueueTable] via
/// [CacheManager] and processed by [SyncEngine.processQueue].
class SyncQueueItem extends Equatable {
  const SyncQueueItem({
    required this.id,
    required this.userId,
    required this.tableName,
    required this.recordId,
    required this.operationType,
    required this.payload,
    required this.priority,
    required this.attempts,
    required this.maxAttempts,
    required this.status,
    required this.errorMessage,
    required this.createdAt,
    required this.updatedAt,
    required this.nextRetryAt,
  });

  /// Unique identifier for this queue entry.
  final String id;

  /// Owner of the sync entry.
  final String userId;

  /// Target table name on the remote (e.g. `questions`, `exams`).
  final String tableName;

  /// Remote record ID. Null for inserts (server assigns the ID).
  final String? recordId;

  /// The type of operation to perform.
  final SyncOperationType operationType;

  /// JSON-serialisable payload for the operation.
  final Map<String, dynamic> payload;

  /// Priority level (lower = higher priority).
  final SyncPriority priority;

  /// Number of attempts made so far.
  final int attempts;

  /// Maximum number of retry attempts before marking dead.
  final int maxAttempts;

  /// Current lifecycle state.
  final SyncStatus status;

  /// Error message from the last failed attempt, if any.
  final String? errorMessage;

  /// When the entry was created locally.
  final DateTime createdAt;

  /// When the entry was last updated.
  final DateTime updatedAt;

  /// When the next retry should be attempted (null = immediate).
  final DateTime? nextRetryAt;

  // ── Computed Getters ──────────────────────────────────────────────────

  /// Whether this item can be retried (has not exceeded max attempts
  /// and is not in a terminal dead state).
  bool get isRetryable => attempts < maxAttempts && status != SyncStatus.dead;

  /// Whether this item is critical or high priority (level <= 3).
  bool get isCritical => priority.level <= 3;

  // ── Factory ───────────────────────────────────────────────────────────

  /// Constructs a [SyncQueueItem] from a raw database row map
  /// (as returned by [CacheManager.getPendingSyncItems]).
  factory SyncQueueItem.fromMap(Map<String, dynamic> map) {
    return SyncQueueItem(
      id: map['id'] as String,
      userId: map['userId'] as String,
      tableName: map['tableName'] as String,
      recordId: map['recordId'] as String?,
      operationType: SyncOperationType.fromString(map['operation'] as String),
      payload: map['payload'] is String
          ? jsonDecode(map['payload'] as String) as Map<String, dynamic>
          : Map<String, dynamic>.from(map['payload'] as Map),
      priority: map['priority'] is int
          ? SyncPriority.fromLevel(map['priority'] as int)
          : SyncPriority.fromString(map['priority'] as String),
      attempts: map['attempts'] as int,
      maxAttempts: map['maxAttempts'] as int,
      status: SyncStatus.fromString(map['status'] as String),
      errorMessage: map['errorMessage'] as String?,
      createdAt: map['createdAt'] is DateTime
          ? map['createdAt'] as DateTime
          : DateTime.parse(map['createdAt'] as String),
      updatedAt: map['updatedAt'] is DateTime
          ? map['updatedAt'] as DateTime
          : DateTime.parse(map['updatedAt'] as String),
      nextRetryAt: map['nextRetryAt'] == null
          ? null
          : map['nextRetryAt'] is DateTime
              ? map['nextRetryAt'] as DateTime
              : DateTime.parse(map['nextRetryAt'] as String),
    );
  }

  /// Serialises this item to a JSON-compatible map.
  Map<String, dynamic> toMap() => {
        'id': id,
        'userId': userId,
        'tableName': tableName,
        'recordId': recordId,
        'operation': operationType.value,
        'payload': jsonEncode(payload),
        'priority': priority.level,
        'attempts': attempts,
        'maxAttempts': maxAttempts,
        'status': status.value,
        'errorMessage': errorMessage,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'nextRetryAt': nextRetryAt?.toIso8601String(),
      };

  /// Returns a copy with the specified fields replaced.
  SyncQueueItem copyWith({
    String? id,
    String? userId,
    String? tableName,
    String? recordId,
    SyncOperationType? operationType,
    Map<String, dynamic>? payload,
    SyncPriority? priority,
    int? attempts,
    int? maxAttempts,
    SyncStatus? status,
    String? errorMessage,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? nextRetryAt,
    bool clearErrorMessage = false,
    bool clearNextRetryAt = false,
  }) {
    return SyncQueueItem(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      tableName: tableName ?? this.tableName,
      recordId: recordId ?? this.recordId,
      operationType: operationType ?? this.operationType,
      payload: payload ?? this.payload,
      priority: priority ?? this.priority,
      attempts: attempts ?? this.attempts,
      maxAttempts: maxAttempts ?? this.maxAttempts,
      status: status ?? this.status,
      errorMessage:
          clearErrorMessage ? null : (errorMessage ?? this.errorMessage),
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      nextRetryAt: clearNextRetryAt ? null : (nextRetryAt ?? this.nextRetryAt),
    );
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        tableName,
        recordId,
        operationType,
        payload,
        priority,
        attempts,
        maxAttempts,
        status,
        errorMessage,
        createdAt,
        updatedAt,
        nextRetryAt,
      ];

  @override
  String toString() => 'SyncQueueItem('
      'id: $id, '
      'table: $tableName, '
      'operation: ${operationType.value}, '
      'priority: ${priority.value}, '
      'status: ${status.value}, '
      'attempts: $attempts/$maxAttempts'
      ')';
}

// ═══════════════════════════════════════════════════════════════════════════════
// SYNC CONFLICT
// ═══════════════════════════════════════════════════════════════════════════════

/// Represents a detected conflict between local and server data.
///
/// Created when [SyncEngine.detectConflict] determines that the local
/// version of a record diverges from the server version. The conflict
/// must be resolved before the sync can proceed.
class SyncConflict extends Equatable {
  const SyncConflict({
    required this.id,
    required this.userId,
    required this.tableName,
    required this.recordId,
    required this.localData,
    required this.serverData,
    required this.resolution,
    required this.resolvedData,
    required this.createdAt,
  });

  /// Unique identifier for this conflict entry.
  final String id;

  /// Owner of the conflicting record.
  final String userId;

  /// Table where the conflict occurred.
  final String tableName;

  /// ID of the conflicting record.
  final String recordId;

  /// The local version of the data at the time of conflict detection.
  final Map<String, dynamic> localData;

  /// The server version of the data at the time of conflict detection.
  final Map<String, dynamic> serverData;

  /// The resolution strategy that was (or will be) applied.
  final ConflictResolution resolution;

  /// The merged / resolved data, or null if not yet resolved.
  final Map<String, dynamic>? resolvedData;

  /// When the conflict was first detected.
  final DateTime createdAt;

  /// Whether the conflict has been resolved.
  bool get isResolved => resolution != ConflictResolution.manual ||
      resolvedData != null;

  /// Factory for creating a new unresolved conflict.
  factory SyncConflict.create({
    required String userId,
    required String tableName,
    required String recordId,
    required Map<String, dynamic> localData,
    required Map<String, dynamic> serverData,
  }) {
    return SyncConflict(
      id: const Uuid().v4(),
      userId: userId,
      tableName: tableName,
      recordId: recordId,
      localData: localData,
      serverData: serverData,
      resolution: ConflictResolution.manual,
      resolvedData: null,
      createdAt: DateTime.now(),
    );
  }

  /// Returns a copy with the conflict resolved.
  SyncConflict resolve(
    ConflictResolution resolution, {
    Map<String, dynamic>? mergedData,
  }) {
    return SyncConflict(
      id: id,
      userId: userId,
      tableName: tableName,
      recordId: recordId,
      localData: localData,
      serverData: serverData,
      resolution: resolution,
      resolvedData: mergedData,
      createdAt: createdAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        tableName,
        recordId,
        localData,
        serverData,
        resolution,
        resolvedData,
        createdAt,
      ];

  @override
  String toString() => 'SyncConflict('
      'id: $id, '
      'table: $tableName, '
      'record: $recordId, '
      'resolution: ${resolution.value}'
      ')';
}

// ═══════════════════════════════════════════════════════════════════════════════
// SYNC RESULT
// ═══════════════════════════════════════════════════════════════════════════════

/// Aggregated result of a sync batch operation.
///
/// Returned by [SyncEngine.processQueue] to summarise what happened
/// during a single sync pass.
class SyncResult extends Equatable {
  const SyncResult({
    required this.itemsSynced,
    required this.itemsFailed,
    required this.conflicts,
    required this.duration,
    required this.errors,
  });

  /// Number of items successfully synced to the server.
  final int itemsSynced;

  /// Number of items that failed to sync.
  final int itemsFailed;

  /// List of conflicts detected during this sync pass.
  final List<SyncConflict> conflicts;

  /// Wall-clock duration of the sync operation.
  final Duration duration;

  /// Human-readable error messages from failed items.
  final List<String> errors;

  // ── Computed Getters ──────────────────────────────────────────────────

  /// Whether all items synced successfully (zero failures).
  bool get isSuccess => itemsFailed == 0;

  /// Whether any conflicts were detected.
  bool get hasConflicts => conflicts.isNotEmpty;

  /// Total number of items processed.
  int get totalProcessed => itemsSynced + itemsFailed;

  /// Success rate as a value between 0.0 and 1.0.
  double get successRate => totalProcessed == 0
      ? 0.0
      : itemsSynced / totalProcessed;

  /// An empty result indicating no work was done.
  static const empty = SyncResult(
    itemsSynced: 0,
    itemsFailed: 0,
    conflicts: [],
    duration: Duration.zero,
    errors: [],
  );

  @override
  List<Object?> get props => [
        itemsSynced,
        itemsFailed,
        conflicts,
        duration,
        errors,
      ];

  @override
  String toString() => 'SyncResult('
      'synced: $itemsSynced, '
      'failed: $itemsFailed, '
      'conflicts: ${conflicts.length}, '
      'duration: ${duration.inMilliseconds}ms'
      ')';
}

// ═══════════════════════════════════════════════════════════════════════════════
// SYNC ENGINE STATE
// ═══════════════════════════════════════════════════════════════════════════════

/// Immutable state snapshot for the [SyncEngine].
///
/// Follows the same pattern as [ConnectivityState] — emitted via
/// [StateNotifier] and consumed by Riverpod providers so that widgets
/// rebuild only when the state genuinely changes.
class SyncEngineState extends Equatable {
  const SyncEngineState({
    this.isSyncing = false,
    this.lastSyncAt,
    this.pendingCount = 0,
    this.failedCount = 0,
    this.currentBatch = 0,
    this.lastResult,
    this.errors = const [],
    this.syncProgress = 0.0,
    this.isAutoSyncEnabled = true,
    this.conflictItems = const [],
  });

  /// Whether a sync operation is currently in progress.
  final bool isSyncing;

  /// Timestamp of the last successful sync completion.
  final DateTime? lastSyncAt;

  /// Number of items currently in the pending state.
  final int pendingCount;

  /// Number of items currently in the failed state.
  final int failedCount;

  /// Number of items being processed in the current batch.
  final int currentBatch;

  /// Result of the most recent sync pass, if any.
  final SyncResult? lastResult;

  /// Transient error messages for UI display.
  final List<String> errors;

  /// Sync progress as a value between 0.0 and 1.0.
  final double syncProgress;

  /// Whether automatic periodic sync is enabled.
  final bool isAutoSyncEnabled;

  /// Currently unresolved conflicts awaiting manual resolution.
  final List<SyncConflict> conflictItems;

  // ── Computed Getters ──────────────────────────────────────────────────

  /// Whether there are any items waiting to be synced.
  bool get hasPendingItems => pendingCount > 0;

  /// Whether there are any failed items that may be retryable.
  bool get hasFailedItems => failedCount > 0;

  /// Whether there are any unresolved conflicts.
  bool get hasConflicts => conflictItems.isNotEmpty;

  /// Overall sync health assessment.
  ///
  ///   - **good**: no failed items and no conflicts.
  ///   - **warning**: some failures but < 20 % of total, or conflicts exist.
  ///   - **critical**: failures >= 20 % of total, or more than 10 dead items.
  String get syncHealth {
    final total = pendingCount + failedCount;
    if (total == 0 && !hasConflicts) return 'good';

    final failureRatio = total > 0 ? failedCount / total : 0.0;

    if (failureRatio >= 0.2 || failedCount > 10) return 'critical';
    if (failedCount > 0 || hasConflicts) return 'warning';
    return 'good';
  }

  // ── copyWith ──────────────────────────────────────────────────────────

  /// Returns a new [SyncEngineState] with the specified fields replaced.
  SyncEngineState copyWith({
    bool? isSyncing,
    DateTime? lastSyncAt,
    int? pendingCount,
    int? failedCount,
    int? currentBatch,
    SyncResult? lastResult,
    List<String>? errors,
    double? syncProgress,
    bool? isAutoSyncEnabled,
    List<SyncConflict>? conflictItems,
    bool clearLastSyncAt = false,
    bool clearLastResult = false,
  }) {
    return SyncEngineState(
      isSyncing: isSyncing ?? this.isSyncing,
      lastSyncAt: clearLastSyncAt ? null : (lastSyncAt ?? this.lastSyncAt),
      pendingCount: pendingCount ?? this.pendingCount,
      failedCount: failedCount ?? this.failedCount,
      currentBatch: currentBatch ?? this.currentBatch,
      lastResult: clearLastResult ? null : (lastResult ?? this.lastResult),
      errors: errors ?? this.errors,
      syncProgress: syncProgress ?? this.syncProgress,
      isAutoSyncEnabled: isAutoSyncEnabled ?? this.isAutoSyncEnabled,
      conflictItems: conflictItems ?? this.conflictItems,
    );
  }

  /// Convenience that returns a copy with [errors] cleared.
  SyncEngineState clearError() => copyWith(errors: []);

  /// Convenience that returns a copy with [lastResult] cleared.
  SyncEngineState clearSuccess() => copyWith(clearLastResult: true);

  @override
  List<Object?> get props => [
        isSyncing,
        lastSyncAt,
        pendingCount,
        failedCount,
        currentBatch,
        lastResult,
        errors,
        syncProgress,
        isAutoSyncEnabled,
        conflictItems,
      ];

  @override
  String toString() => 'SyncEngineState('
      'syncing: $isSyncing, '
      'pending: $pendingCount, '
      'failed: $failedCount, '
      'progress: ${(syncProgress * 100).toStringAsFixed(0)}%, '
      'health: $syncHealth, '
      'conflicts: ${conflictItems.length}'
      ')';
}

// ═══════════════════════════════════════════════════════════════════════════════
// SYNC ENGINE
// ═══════════════════════════════════════════════════════════════════════════════

/// Core synchronisation engine for ExamForge AI's offline-first architecture.
///
/// Extends [StateNotifier]<[SyncEngineState]> so that any widget or
/// provider watching [syncEngineProvider] rebuilds automatically when
/// sync state changes.
///
/// The engine:
///   1. Maintains a persistent queue of pending operations in the local DB.
///   2. Processes them in priority order, respecting batch size limits
///      derived from the current connectivity quality.
///   3. Detects conflicts by comparing local and server timestamps.
///   4. Auto-resolves conflicts where possible (server wins for non-drafts,
///      merge for drafts) and escalates the rest to manual resolution.
///   5. Applies exponential backoff for failed items.
///   6. Runs a periodic auto-sync timer when enabled and online.
class SyncEngine extends StateNotifier<SyncEngineState> {
  SyncEngine({
    required CacheManager cacheManager,
    required dynamic supabaseClient,
    required ConnectivityEngine connectivityEngine,
    this.maxRetryAttempts = 5,
    this.defaultSyncInterval = const Duration(seconds: 30),
  })  : _cacheManager = cacheManager,
        _supabaseClient = supabaseClient,
        _connectivityEngine = connectivityEngine,
        super(const SyncEngineState());

  // ── Dependencies ──────────────────────────────────────────────────────

  /// Persistent cache / sync-queue manager.
  final CacheManager _cacheManager;

  /// Supabase client for remote operations. Typed as `dynamic` to
  /// decouple from the concrete Supabase version at compile time.
  final dynamic _supabaseClient;

  /// Reference to the connectivity engine for quality-aware decisions.
  final ConnectivityEngine _connectivityEngine;

  // ── Configuration ─────────────────────────────────────────────────────

  /// Maximum retry attempts before marking an item as dead.
  final int maxRetryAttempts;

  /// Default interval between automatic sync passes.
  final Duration defaultSyncInterval;

  /// UUID generator for new records.
  static const _uuid = Uuid();

  // ── Internal State ────────────────────────────────────────────────────

  /// Periodic timer for auto-sync.
  Timer? _autoSyncTimer;

  /// Subscription to connectivity state changes.
  StreamSubscription<ConnectivityState>? _connectivitySubscription;

  /// In-memory list of pending items loaded from the DB.
  List<SyncQueueItem> _pendingItems = [];

  /// In-memory list of detected conflicts.
  List<SyncConflict> _conflicts = [];

  /// Whether the engine has been initialised.
  bool _isInitialized = false;

  /// Whether the engine has been disposed.
  bool _isDisposed = false;

  // ═══════════════════════════════════════════════════════════════════════
  // LIFECYCLE
  // ═══════════════════════════════════════════════════════════════════════

  /// Initialises the engine by loading pending items from the local DB
  /// and starting the auto-sync timer if enabled.
  ///
  /// Should be called once after the engine is created (typically from
  /// the Riverpod provider's constructor).
  Future<void> initialize() async {
    if (_isInitialized) return;

    AppLogger.info('SyncEngine: initializing...');

    try {
      // Load pending items from the local database.
      await _loadPendingItems();

      // Load any persisted conflicts (could be stored in cache).
      await _loadConflicts();

      // Subscribe to connectivity changes to trigger sync when coming online.
      _connectivitySubscription =
          _connectivityEngine.stream.listen(_onConnectivityChanged);

      // Start auto-sync if enabled.
      if (state.isAutoSyncEnabled) {
        _startAutoSyncTimer();
      }

      _isInitialized = true;

      // Update state with loaded counts.
      state = state.copyWith(
        pendingCount: _pendingItems
            .where((i) => i.status == SyncStatus.pending)
            .length,
        failedCount: _pendingItems
            .where((i) => i.status == SyncStatus.failed)
            .length,
        conflictItems: _conflicts,
      );

      AppLogger.info(
        'SyncEngine: initialized '
        '(pending: ${state.pendingCount}, failed: ${state.failedCount}, '
        'conflicts: ${_conflicts.length})',
      );
    } catch (e, st) {
      AppLogger.error(
        'SyncEngine: initialization failed',
        error: e,
        stackTrace: st,
      );
      state = state.copyWith(
        errors: ['Initialization failed: $e'],
      );
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    _autoSyncTimer?.cancel();
    _connectivitySubscription?.cancel();
    _pendingItems.clear();
    _conflicts.clear();
    super.dispose();
  }

  // ═══════════════════════════════════════════════════════════════════════
  // PUBLIC API — ENQUEUE & CANCEL
  // ═══════════════════════════════════════════════════════════════════════

  /// Adds an operation to the sync queue.
  ///
  /// If the device is online and the engine is not currently syncing,
  /// the operation may be processed immediately on the next sync tick.
  Future<void> enqueueOperation({
    required String tableName,
    required SyncOperationType operation,
    required Map<String, dynamic> payload,
    String? recordId,
    SyncPriority priority = SyncPriority.normal,
  }) async {
    try {
      // Get current user ID from Supabase auth.
      final userId = _currentUserId;
      if (userId == null) {
        AppLogger.warning('SyncEngine: cannot enqueue — no authenticated user');
        return;
      }

      // Persist to the local database via CacheManager.
      await _cacheManager.enqueueSync(
        userId: userId,
        tableName: tableName,
        operation: operation.value,
        payload: payload,
        recordId: recordId,
        priority: priority.level,
      );

      // Create an in-memory representation.
      final now = DateTime.now();
      final item = SyncQueueItem(
        id: _uuid.v4(),
        userId: userId,
        tableName: tableName,
        recordId: recordId,
        operationType: operation,
        payload: payload,
        priority: priority,
        attempts: 0,
        maxAttempts: maxRetryAttempts,
        status: SyncStatus.pending,
        errorMessage: null,
        createdAt: now,
        updatedAt: now,
        nextRetryAt: null,
      );

      _pendingItems.add(item);
      _sortPendingItems();

      state = state.copyWith(
        pendingCount: _pendingItems
            .where((i) => i.status == SyncStatus.pending)
            .length,
      );

      AppLogger.info(
        'SyncEngine: enqueued ${operation.value} on $tableName '
        '(priority: ${priority.value}, queue depth: ${_pendingItems.length})',
      );
    } catch (e, st) {
      AppLogger.error(
        'SyncEngine: failed to enqueue operation',
        error: e,
        stackTrace: st,
      );
      state = state.copyWith(
        errors: ['Failed to enqueue operation: $e'],
      );
    }
  }

  /// Cancels a pending operation by its [id].
  ///
  /// Completed, dead, or in-progress items cannot be cancelled.
  Future<void> cancelOperation(String id) async {
    try {
      final index = _pendingItems.indexWhere((i) => i.id == id);
      if (index == -1) {
        AppLogger.warning('SyncEngine: cancel — item $id not found in memory');
        return;
      }

      final item = _pendingItems[index];
      if (item.status == SyncStatus.completed ||
          item.status == SyncStatus.dead ||
          item.status == SyncStatus.inProgress) {
        AppLogger.warning(
          'SyncEngine: cannot cancel item $id in state ${item.status.value}',
        );
        return;
      }

      // Remove from in-memory list.
      _pendingItems.removeAt(index);

      // Remove from persistent store.
      await _cacheManager.markSyncItemCompleted(id: id);

      state = state.copyWith(
        pendingCount: _pendingItems
            .where((i) => i.status == SyncStatus.pending)
            .length,
        failedCount: _pendingItems
            .where((i) => i.status == SyncStatus.failed)
            .length,
      );

      AppLogger.info('SyncEngine: cancelled operation $id');
    } catch (e, st) {
      AppLogger.error(
        'SyncEngine: failed to cancel operation $id',
        error: e,
        stackTrace: st,
      );
    }
  }

  /// Removes all completed items from the queue (both in-memory and DB).
  Future<void> clearCompleted() async {
    try {
      final completedIds = _pendingItems
          .where((i) => i.status == SyncStatus.completed)
          .map((i) => i.id)
          .toList();

      _pendingItems.removeWhere((i) => i.status == SyncStatus.completed);

      // Clean up dead items while we are at it.
      await _cacheManager.cleanupDeadSyncItems();

      state = state.copyWith(
        pendingCount: _pendingItems
            .where((i) => i.status == SyncStatus.pending)
            .length,
        failedCount: _pendingItems
            .where((i) => i.status == SyncStatus.failed)
            .length,
      );

      AppLogger.info(
        'SyncEngine: cleared ${completedIds.length} completed items',
      );
    } catch (e, st) {
      AppLogger.error(
        'SyncEngine: failed to clear completed items',
        error: e,
        stackTrace: st,
      );
    }
  }

  /// Returns pending items for a specific [tableName].
  List<SyncQueueItem> getPendingForTable(String tableName) {
    return _pendingItems
        .where(
          (i) =>
              i.tableName == tableName &&
              (i.status == SyncStatus.pending ||
                  i.status == SyncStatus.failed),
        )
        .toList();
  }

  // ═══════════════════════════════════════════════════════════════════════
  // PUBLIC API — PROCESS QUEUE
  // ═══════════════════════════════════════════════════════════════════════

  /// Processes pending sync items in priority order, respecting the
  /// batch size dictated by the current connectivity quality.
  ///
  /// Returns a [SyncResult] summarising the outcome of this sync pass.
  Future<SyncResult> processQueue() async {
    if (state.isSyncing) {
      AppLogger.debug('SyncEngine: processQueue skipped — already syncing');
      return SyncResult.empty;
    }

    // Check if we should sync at all given current connectivity.
    if (!_connectivityEngine.shouldPerformSync()) {
      AppLogger.info(
        'SyncEngine: processQueue skipped — '
        'connectivity quality is ${_connectivityEngine.state.connectionQuality.value}',
      );
      return SyncResult.empty;
    }

    // Filter items that are eligible for processing.
    final eligibleItems = _pendingItems.where((i) {
      if (i.status == SyncStatus.completed || i.status == SyncStatus.dead) {
        return false;
      }
      if (i.status == SyncStatus.inProgress) return false;
      // Respect scheduled retry time.
      if (i.nextRetryAt != null &&
          DateTime.now().isBefore(i.nextRetryAt!)) {
        return false;
      }
      return true;
    }).toList();

    if (eligibleItems.isEmpty) {
      AppLogger.debug('SyncEngine: no eligible items to process');
      return SyncResult.empty;
    }

    // Determine batch size from adaptive behaviour.
    final behavior = AdaptiveBehavior(_connectivityEngine.state);
    final batchSize = behavior.batchSize;
    final batch = eligibleItems.take(batchSize).toList();

    AppLogger.info(
      'SyncEngine: processing ${batch.length} items '
      '(batch size: $batchSize, quality: ${_connectivityEngine.state.connectionQuality.value})',
    );

    state = state.copyWith(
      isSyncing: true,
      currentBatch: batch.length,
      syncProgress: 0.0,
    );

    final stopwatch = Stopwatch()..start();
    var itemsSynced = 0;
    var itemsFailed = 0;
    final detectedConflicts = <SyncConflict>[];
    final errors = <String>[];

    for (var i = 0; i < batch.length; i++) {
      if (_isDisposed) break;

      final item = batch[i];

      // Update progress.
      state = state.copyWith(
        syncProgress: (i + 1) / batch.length,
      );

      try {
        final result = await processItem(item);
        result.fold(
          onSuccess: (_) {
            itemsSynced++;
          },
          onFailure: (failure) {
            // Check if this is a conflict.
            if (failure is ServerFailure && failure.statusCode == 409) {
              // Conflict detected — try auto-resolution.
              final conflictResult = _handleConflictForItem(item, failure);
              if (conflictResult != null) {
                detectedConflicts.add(conflictResult);
                itemsFailed++;
              } else {
                itemsSynced++; // Auto-resolved
              }
            } else if (failure is ValidationFailure) {
              // Validation errors are permanent — mark as dead.
              _markItemDead(item, failure.message);
              itemsFailed++;
              errors.add('${item.tableName}/${item.recordId}: ${failure.message}');
            } else if (failure is NetworkFailure) {
              // Network errors are transient — mark for retry.
              _markItemFailed(item, failure.message);
              itemsFailed++;
              errors.add('${item.tableName}/${item.recordId}: ${failure.message}');
            } else {
              _markItemFailed(item, failure.message);
              itemsFailed++;
              errors.add('${item.tableName}/${item.recordId}: ${failure.message}');
            }
          },
        );
      } catch (e, st) {
        AppLogger.error(
          'SyncEngine: unexpected error processing item ${item.id}',
          error: e,
          stackTrace: st,
        );
        _markItemFailed(item, e.toString());
        itemsFailed++;
        errors.add('${item.tableName}/${item.recordId}: $e');
      }
    }

    stopwatch.stop();

    final result = SyncResult(
      itemsSynced: itemsSynced,
      itemsFailed: itemsFailed,
      conflicts: detectedConflicts,
      duration: stopwatch.elapsed,
      errors: errors,
    );

    // Refresh pending items from DB to get accurate counts.
    await _loadPendingItems();

    state = state.copyWith(
      isSyncing: false,
      lastSyncAt: DateTime.now(),
      currentBatch: 0,
      syncProgress: 1.0,
      lastResult: result,
      pendingCount: _pendingItems
          .where((i) => i.status == SyncStatus.pending)
          .length,
      failedCount: _pendingItems
          .where((i) => i.status == SyncStatus.failed)
          .length,
    );

    AppLogger.info(
      'SyncEngine: sync completed — '
      'synced: $itemsSynced, failed: $itemsFailed, '
      'conflicts: ${detectedConflicts.length}, '
      'duration: ${stopwatch.elapsedMilliseconds}ms',
    );

    return result;
  }

  /// Processes a single sync item against the Supabase backend.
  ///
  /// Returns a [Result] indicating success or failure with a [Failure].
  Future<Result<void>> processItem(SyncQueueItem item) async {
    AppLogger.debug(
      'SyncEngine: processing ${item.operationType.value} '
      'on ${item.tableName}/${item.recordId ?? "new"}',
    );

    // Mark as in-progress in memory.
    _updateItemInMemory(item.id, status: SyncStatus.inProgress);

    try {
      final table = _supabaseClient.from(item.tableName);

      switch (item.operationType) {
        case SyncOperationType.insert:
          await table.insert(item.payload);
          AppLogger.debug(
            'SyncEngine: inserted into ${item.tableName}',
          );

        case SyncOperationType.update:
          if (item.recordId == null) {
            return const FailureResult(Failure.validation(
              message: 'Cannot update without a recordId',
              fieldErrors: {},
            ),);
          }
          await table.update(item.payload).eq('id', item.recordId!);
          AppLogger.debug(
            'SyncEngine: updated ${item.tableName}/${item.recordId}',
          );

        case SyncOperationType.delete:
          if (item.recordId == null) {
            return const FailureResult(Failure.validation(
              message: 'Cannot delete without a recordId',
              fieldErrors: {},
            ),);
          }
          await table.delete().eq('id', item.recordId!);
          AppLogger.debug(
            'SyncEngine: deleted from ${item.tableName}/${item.recordId}',
          );
      }

      // Mark as completed in the persistent store.
      await _cacheManager.markSyncItemCompleted(id: item.id);
      _updateItemInMemory(item.id, status: SyncStatus.completed);

      // Update local cache to reflect the synced state.
      await _updateLocalCache(item);

      return const Success(null);
    } on sb.PostgrestException catch (e) {
      AppLogger.warning(
        'SyncEngine: Supabase error for ${item.id}: ${e.message} '
        '(code: ${e.code})',
      );

      // Map Postgrest error codes to failure types.
      if (e.code == '409' || e.code == '23505') {
        return FailureResult(Failure.server(
          message: e.message,
          statusCode: 409,
          data: e.details,
        ),);
      }
      if (e.code == '422' || e.code == '400') {
        return FailureResult(Failure.validation(
          message: e.message,
          fieldErrors: {},
        ),);
      }
      if (e.code == '401') {
        return FailureResult(Failure.unauthorized(
          message: e.message,
        ),);
      }
      if (e.code == '403') {
        return FailureResult(Failure.forbidden(
          message: e.message,
        ),);
      }
      if (e.code == '404') {
        return FailureResult(Failure.notFound(
          message: e.message,
        ),);
      }
      return FailureResult(Failure.server(
        message: e.message,
        statusCode: int.tryParse(e.code ?? '') ?? 500,
      ),);
    } on sb.AuthException catch (e) {
      return FailureResult(Failure.auth(
        message: e.message,
        code: 'auth_error',
      ),);
    } catch (e) {
      // Assume network-level error for any other exception.
      return FailureResult(Failure.network(
        message: e.toString(),
      ),);
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // PUBLIC API — CONFLICT DETECTION & RESOLUTION
  // ═══════════════════════════════════════════════════════════════════════

  /// Detects a conflict by comparing local and server data using
  /// timestamps and checksums.
  ///
  /// A conflict exists when:
  ///   - The server's `updated_at` is newer than the local `updated_at`
  ///     embedded in the payload, **and**
  ///   - The payload content differs from the server version.
  ///
  /// Returns a [SyncConflict] if a conflict is detected, or `null`
  /// if the data is compatible.
  SyncConflict? detectConflict(
    SyncQueueItem item,
    Map<String, dynamic> serverData,
  ) {
    final localUpdatedAt = item.payload['updated_at'];
    final serverUpdatedAt = serverData['updated_at'];

    // Parse timestamps for comparison.
    DateTime? localTime;
    DateTime? serverTime;

    if (localUpdatedAt is String) {
      localTime = DateTime.tryParse(localUpdatedAt);
    } else if (localUpdatedAt is DateTime) {
      localTime = localUpdatedAt;
    }

    if (serverUpdatedAt is String) {
      serverTime = DateTime.tryParse(serverUpdatedAt);
    } else if (serverUpdatedAt is DateTime) {
      serverTime = serverUpdatedAt;
    }

    // If we can't parse timestamps, assume conflict to be safe.
    if (localTime == null || serverTime == null) {
      AppLogger.warning(
        'SyncEngine: conflict detection — unparseable timestamps for '
        '${item.tableName}/${item.recordId}',
      );
      return SyncConflict.create(
        userId: item.userId,
        tableName: item.tableName,
        recordId: item.recordId ?? item.id,
        localData: item.payload,
        serverData: serverData,
      );
    }

    // Server is newer → potential conflict.
    if (serverTime.isAfter(localTime)) {
      // Check if the actual content differs by comparing checksums
      // or by a key-by-key comparison of non-metadata fields.
      if (_dataDiffers(item.payload, serverData)) {
        AppLogger.info(
          'SyncEngine: conflict detected for '
          '${item.tableName}/${item.recordId} '
          '(local: $localTime, server: $serverTime)',
        );
        return SyncConflict.create(
          userId: item.userId,
          tableName: item.tableName,
          recordId: item.recordId ?? item.id,
          localData: item.payload,
          serverData: serverData,
        );
      }
      // Server is newer but data is the same — no real conflict.
      return null;
    }

    // Local is newer or same — no conflict (local wins).
    return null;
  }

  /// Resolves a conflict according to the specified [resolution] strategy.
  ///
  /// For [ConflictResolution.merge], [mergedData] must be provided.
  /// For other strategies, the resolution is deterministic.
  Future<void> resolveConflict(
    SyncQueueItem item,
    ConflictResolution resolution, {
    Map<String, dynamic>? mergedData,
  }) async {
    try {
      final conflictIndex = _conflicts.indexWhere(
        (c) => c.recordId == (item.recordId ?? item.id),
      );

      if (conflictIndex == -1) {
        AppLogger.warning(
          'SyncEngine: resolveConflict — no matching conflict found for '
          '${item.tableName}/${item.recordId}',
        );
        return;
      }

      final conflict = _conflicts[conflictIndex];
      Map<String, dynamic> resolvedData;

      switch (resolution) {
        case ConflictResolution.localWins:
          resolvedData = conflict.localData;
          AppLogger.info(
            'SyncEngine: conflict resolved — local wins for '
            '${item.tableName}/${conflict.recordId}',
          );

        case ConflictResolution.serverWins:
          resolvedData = conflict.serverData;
          AppLogger.info(
            'SyncEngine: conflict resolved — server wins for '
            '${item.tableName}/${conflict.recordId}',
          );

        case ConflictResolution.merge:
          if (mergedData == null) {
            AppLogger.error(
              'SyncEngine: merge resolution requires mergedData',
            );
            return;
          }
          resolvedData = mergedData;
          AppLogger.info(
            'SyncEngine: conflict resolved — merge for '
            '${item.tableName}/${conflict.recordId}',
          );

        case ConflictResolution.manual:
          AppLogger.info(
            'SyncEngine: conflict resolution deferred to manual for '
            '${item.tableName}/${conflict.recordId}',
          );
          return;
      }

      // Update the conflict record.
      _conflicts[conflictIndex] = conflict.resolve(
        resolution,
        mergedData: resolvedData,
      );

      // Update the queue item's payload and re-enqueue.
      _updateItemInMemory(
        item.id,
        payload: resolvedData,
        status: SyncStatus.pending,
      );

      // Update the server with resolved data.
      try {
        final table = _supabaseClient.from(item.tableName);
        if (item.recordId != null) {
          await table.update(resolvedData).eq('id', item.recordId!);
        }
        await _cacheManager.markSyncItemCompleted(id: item.id);
        _updateItemInMemory(item.id, status: SyncStatus.completed);
      } catch (e) {
        AppLogger.error(
          'SyncEngine: failed to apply resolved data to server',
          error: e,
        );
        _markItemFailed(item, 'Failed to apply resolution: $e');
      }

      // Remove the resolved conflict.
      _conflicts.removeAt(conflictIndex);

      state = state.copyWith(
        conflictItems: List.from(_conflicts),
        pendingCount: _pendingItems
            .where((i) => i.status == SyncStatus.pending)
            .length,
      );
    } catch (e, st) {
      AppLogger.error(
        'SyncEngine: failed to resolve conflict',
        error: e,
        stackTrace: st,
      );
    }
  }

  /// Attempts automatic conflict resolution.
  ///
  /// Strategy:
  ///   - **Non-draft data**: Server wins (the server is the source of truth
  ///     for committed records).
  ///   - **Draft data** (payload contains `is_draft: true`): Merge by
  ///     taking the union of local and server fields, with server fields
  ///     winning for overlapping keys — except `content` and `title`,
  ///     which prefer the local version.
  ///
  /// Returns the resolution used, or `null` if auto-resolution is not
  /// possible and manual intervention is required.
  ConflictResolution? autoResolveConflict(
    SyncQueueItem item,
    Map<String, dynamic> serverData,
  ) {
    final isDraft = item.payload['is_draft'] == true;

    if (!isDraft) {
      // For non-draft data, server is authoritative.
      AppLogger.info(
        'SyncEngine: auto-resolving conflict — server wins '
        '(non-draft ${item.tableName}/${item.recordId})',
      );
      return ConflictResolution.serverWins;
    }

    // For drafts, attempt a merge.
    // Merge strategy: start with server data, overlay local changes for
    // user-editable fields.
    final mergedData = Map<String, dynamic>.from(serverData);
    const localPreferredFields = {'content', 'title', 'description', 'body'};

    for (final field in localPreferredFields) {
      if (item.payload.containsKey(field) &&
          item.payload[field] != null) {
        mergedData[field] = item.payload[field];
      }
    }

    // Check if the merge actually differs from both sides.
    // If it does, we can auto-resolve; otherwise, manual is needed.
    if (_dataDiffers(mergedData, serverData) ||
        _dataDiffers(mergedData, item.payload)) {
      AppLogger.info(
        'SyncEngine: auto-resolving conflict — merge '
        '(draft ${item.tableName}/${item.recordId})',
      );
      return ConflictResolution.merge;
    }

    // Data is identical after merge — no real conflict.
    return ConflictResolution.serverWins;
  }

  // ═══════════════════════════════════════════════════════════════════════
  // PUBLIC API — RETRY, SYNC, AUTO-SYNC
  // ═══════════════════════════════════════════════════════════════════════

  /// Retries all failed items that are retryable.
  ///
  /// Items that have exceeded their max attempts are skipped.
  Future<SyncResult> retryFailed() async {
    final retryable = _pendingItems
        .where((i) =>
            i.status == SyncStatus.failed &&
            i.isRetryable &&
            (i.nextRetryAt == null ||
                DateTime.now().isAfter(i.nextRetryAt!)),)
        .toList();

    if (retryable.isEmpty) {
      AppLogger.debug('SyncEngine: no retryable failed items');
      return SyncResult.empty;
    }

    AppLogger.info(
      'SyncEngine: retrying ${retryable.length} failed items',
    );

    // Reset their status to pending so processQueue picks them up.
    for (final item in retryable) {
      _updateItemInMemory(item.id, status: SyncStatus.pending);
    }

    return processQueue();
  }

  /// Forces a full sync of a specific table — pulls from server and
  /// pushes local changes.
  ///
  /// 1. Push any pending local mutations for [tableName].
  /// 2. Pull latest data from server and update the local cache.
  Future<SyncResult> syncTable(String tableName) async {
    AppLogger.info('SyncEngine: forcing full sync for table $tableName');

    // Step 1: Push local changes first.
    final pushResult = await processQueue();

    // Step 2: Pull latest from server.
    try {
      final userId = _currentUserId;
      if (userId == null) {
        AppLogger.warning('SyncEngine: cannot sync table — no user');
        return pushResult;
      }

      final response = await _supabaseClient
          .from(tableName)
          .select()
          .eq('user_id', userId);

      if (response is List) {
        // Cache each record locally.
        for (final record in response) {
          if (record is Map<String, dynamic>) {
            final recordId = record['id'] as String?;
            if (recordId != null) {
              await _cacheManager.cacheData(
                key: '$tableName:$recordId',
                userId: userId,
                resourceType: tableName,
                resourceId: recordId,
                data: record,
              );
            }
          }
        }
        AppLogger.info(
          'SyncEngine: pulled ${response.length} records from $tableName',
        );
      }
    } catch (e, st) {
      AppLogger.error(
        'SyncEngine: failed to pull data from $tableName',
        error: e,
        stackTrace: st,
      );
    }

    return pushResult;
  }

  /// Forces a complete synchronisation of all tables.
  ///
  /// Processes all pending operations and then pulls the latest data
  /// for each known table.
  Future<SyncResult> forceFullSync() async {
    AppLogger.info('SyncEngine: forcing full sync across all tables');

    final result = await processQueue();

    // Pull from each table that has pending items.
    final tables = _pendingItems
        .map((i) => i.tableName)
        .toSet();

    for (final table in tables) {
      try {
        final userId = _currentUserId;
        if (userId == null) continue;

        final response = await _supabaseClient
            .from(table)
            .select()
            .eq('user_id', userId);

        if (response is List) {
          for (final record in response) {
            if (record is Map<String, dynamic>) {
              final recordId = record['id'] as String?;
              if (recordId != null) {
                await _cacheManager.cacheData(
                  key: '$table:$recordId',
                  userId: userId,
                  resourceType: table,
                  resourceId: recordId,
                  data: record,
                );
              }
            }
          }
        }
      } catch (e, st) {
        AppLogger.error(
          'SyncEngine: full sync pull failed for $table',
          error: e,
          stackTrace: st,
        );
      }
    }

    AppLogger.info('SyncEngine: full sync completed');
    return result;
  }

  /// Enables automatic periodic sync.
  void enableAutoSync() {
    if (state.isAutoSyncEnabled) return;

    state = state.copyWith(isAutoSyncEnabled: true);
    _startAutoSyncTimer();
    AppLogger.info('SyncEngine: auto-sync enabled');
  }

  /// Disables automatic periodic sync.
  void disableAutoSync() {
    if (!state.isAutoSyncEnabled) return;

    state = state.copyWith(isAutoSyncEnabled: false);
    _autoSyncTimer?.cancel();
    _autoSyncTimer = null;
    AppLogger.info('SyncEngine: auto-sync disabled');
  }

  /// Returns the overall sync health assessment.
  ///
  /// Mirrors [SyncEngineState.syncHealth] but is accessible as a method.
  String getSyncHealth() => state.syncHealth;

  // ═══════════════════════════════════════════════════════════════════════
  // INTERNAL — LOAD & REFRESH
  // ═══════════════════════════════════════════════════════════════════════

  /// Loads pending items from the persistent store into memory.
  Future<void> _loadPendingItems() async {
    try {
      final userId = _currentUserId;
      if (userId == null) {
        _pendingItems = [];
        return;
      }

      final rows = await _cacheManager.getPendingSyncItems(
        userId: userId,
        limit: 500,
      );

      _pendingItems = rows.map(SyncQueueItem.fromMap).toList();
      _sortPendingItems();

      AppLogger.debug(
        'SyncEngine: loaded ${_pendingItems.length} pending items',
      );
    } catch (e, st) {
      AppLogger.error(
        'SyncEngine: failed to load pending items',
        error: e,
        stackTrace: st,
      );
      _pendingItems = [];
    }
  }

  /// Loads persisted conflicts from the cache.
  Future<void> _loadConflicts() async {
    try {
      final userId = _currentUserId;
      if (userId == null) {
        _conflicts = [];
        return;
      }

      final data = await _cacheManager.getCachedData(
        key: 'sync:conflicts',
        userId: userId,
      );

      if (data != null && data['conflicts'] is List) {
        _conflicts = (data['conflicts'] as List)
            .whereType<Map<String, dynamic>>()
            .map((m) => SyncConflict(
                  id: m['id'] as String,
                  userId: m['userId'] as String,
                  tableName: m['tableName'] as String,
                  recordId: m['recordId'] as String,
                  localData: Map<String, dynamic>.from(
                    m['localData'] as Map,
                  ),
                  serverData: Map<String, dynamic>.from(
                    m['serverData'] as Map,
                  ),
                  resolution:
                      ConflictResolution.fromString(m['resolution'] as String),
                  resolvedData: m['resolvedData'] != null
                      ? Map<String, dynamic>.from(
                          m['resolvedData'] as Map,
                        )
                      : null,
                  createdAt: DateTime.parse(m['createdAt'] as String),
                ),)
            .where((c) => c.resolution == ConflictResolution.manual)
            .toList();
      }
    } catch (e, st) {
      AppLogger.error(
        'SyncEngine: failed to load conflicts',
        error: e,
        stackTrace: st,
      );
      _conflicts = [];
    }
  }

  /// Persists current conflicts to the cache.
  Future<void> _persistConflicts() async {
    try {
      final userId = _currentUserId;
      if (userId == null) return;

      final conflictMaps = _conflicts
          .map((c) => {
                'id': c.id,
                'userId': c.userId,
                'tableName': c.tableName,
                'recordId': c.recordId,
                'localData': c.localData,
                'serverData': c.serverData,
                'resolution': c.resolution.value,
                'resolvedData': c.resolvedData,
                'createdAt': c.createdAt.toIso8601String(),
              },)
          .toList();

      await _cacheManager.cacheData(
        key: 'sync:conflicts',
        userId: userId,
        resourceType: 'sync',
        resourceId: 'conflicts',
        data: {'conflicts': conflictMaps},
      );
    } catch (e, st) {
      AppLogger.error(
        'SyncEngine: failed to persist conflicts',
        error: e,
        stackTrace: st,
      );
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // INTERNAL — ITEM MANAGEMENT
  // ═══════════════════════════════════════════════════════════════════════

  /// Updates an item's in-memory state by [id].
  void _updateItemInMemory(
    String id, {
    SyncStatus? status,
    Map<String, dynamic>? payload,
    int? attempts,
    String? errorMessage,
    bool clearErrorMessage = false,
    DateTime? nextRetryAt,
    bool clearNextRetryAt = false,
  }) {
    final index = _pendingItems.indexWhere((i) => i.id == id);
    if (index == -1) return;

    _pendingItems[index] = _pendingItems[index].copyWith(
      status: status,
      payload: payload,
      attempts: attempts,
      errorMessage: errorMessage,
      clearErrorMessage: clearErrorMessage,
      nextRetryAt: nextRetryAt,
      clearNextRetryAt: clearNextRetryAt,
      updatedAt: DateTime.now(),
    );

    _sortPendingItems();
  }

  /// Marks an item as failed and schedules a retry with exponential backoff.
  void _markItemFailed(SyncQueueItem item, String errorMessage) {
    final newAttempts = item.attempts + 1;
    final isDead = newAttempts >= item.maxAttempts;

    // Compute backoff using adaptive behaviour.
    final behavior = AdaptiveBehavior(_connectivityEngine.state);
    final backoff = behavior.retryDelay(attempt: newAttempts);

    _updateItemInMemory(
      item.id,
      status: isDead ? SyncStatus.dead : SyncStatus.failed,
      attempts: newAttempts,
      errorMessage: errorMessage,
      nextRetryAt: isDead ? null : DateTime.now().add(backoff),
      clearNextRetryAt: isDead,
    );

    // Persist to the database.
    _cacheManager.markSyncItemFailed(id: item.id, errorMessage: errorMessage);

    AppLogger.debug(
      'SyncEngine: item ${item.id} failed '
      '(attempt $newAttempts/${item.maxAttempts})'
      '${isDead ? ' → dead' : ', retry after ${backoff.inSeconds}s'}',
    );
  }

  /// Marks an item as dead (no further retries).
  void _markItemDead(SyncQueueItem item, String errorMessage) {
    _updateItemInMemory(
      item.id,
      status: SyncStatus.dead,
      attempts: item.maxAttempts,
      errorMessage: errorMessage,
      clearNextRetryAt: true,
    );

    // Persist to the database.
    _cacheManager.markSyncItemFailed(id: item.id, errorMessage: errorMessage);

    AppLogger.warning(
      'SyncEngine: item ${item.id} marked dead — $errorMessage',
    );
  }

  /// Handles a conflict for an item, attempting auto-resolution.
  ///
  /// Returns a [SyncConflict] if the conflict requires manual resolution,
  /// or `null` if it was auto-resolved.
  SyncConflict? _handleConflictForItem(SyncQueueItem item, Failure failure) {
    // Extract server data from the failure details if available.
    final serverData = failure is ServerFailure && failure.data != null
        ? Map<String, dynamic>.from(failure.data as Map)
        : <String, dynamic>{};

    // If we don't have server data, try to fetch it.
    if (serverData.isEmpty && item.recordId != null) {
      _fetchServerDataForConflict(item);
    }

    final conflict = detectConflict(item, serverData);
    if (conflict == null) {
      // No actual conflict — server data is compatible.
      AppLogger.debug(
        'SyncEngine: 409 response but no real conflict for ${item.id}',
      );
      return null;
    }

    // Attempt auto-resolution.
    final resolution = autoResolveConflict(item, serverData);
    if (resolution == null) {
      // Cannot auto-resolve — add to conflict list.
      _conflicts.add(conflict);
      _persistConflicts();
      _updateItemInMemory(item.id, status: SyncStatus.conflict);

      state = state.copyWith(
        conflictItems: List.from(_conflicts),
      );

      AppLogger.warning(
        'SyncEngine: conflict requires manual resolution for '
        '${item.tableName}/${item.recordId}',
      );
      return conflict;
    }

    // Auto-resolve the conflict.
    AppLogger.info(
      'SyncEngine: auto-resolving conflict with ${resolution.value} '
      'for ${item.tableName}/${item.recordId}',
    );

    Map<String, dynamic>? resolvedData;
    switch (resolution) {
      case ConflictResolution.localWins:
        resolvedData = item.payload;
      case ConflictResolution.serverWins:
        resolvedData = serverData;
      case ConflictResolution.merge:
        // Merge: server base + local user-editable fields.
        resolvedData = Map<String, dynamic>.from(serverData);
        const localPreferredFields = {
          'content',
          'title',
          'description',
          'body',
        };
        for (final field in localPreferredFields) {
          if (item.payload.containsKey(field) &&
              item.payload[field] != null) {
            resolvedData[field] = item.payload[field];
          }
        }
      case ConflictResolution.manual:
        // Should not reach here, but handle gracefully.
        _conflicts.add(conflict);
        _persistConflicts();
        state = state.copyWith(conflictItems: List.from(_conflicts));
        return conflict;
    }

    // Apply the resolution by updating the item's payload.
    _updateItemInMemory(
      item.id,
      payload: resolvedData,
      status: SyncStatus.pending,
    );

    return null; // Auto-resolved.
  }

  /// Attempts to fetch server data for a conflict item.
  Future<void> _fetchServerDataForConflict(SyncQueueItem item) async {
    try {
      if (item.recordId == null) return;

      final response = await _supabaseClient
          .from(item.tableName)
          .select()
          .eq('id', item.recordId!)
          .maybeSingle();

      if (response is Map<String, dynamic>) {
        // Re-run conflict detection with actual server data.
        final conflict = detectConflict(item, response);
        if (conflict != null) {
          final resolution = autoResolveConflict(item, response);
          if (resolution == null) {
            _conflicts.add(conflict);
            _persistConflicts();
            _updateItemInMemory(item.id, status: SyncStatus.conflict);
            state = state.copyWith(conflictItems: List.from(_conflicts));
          }
        }
      }
    } catch (e) {
      AppLogger.warning(
        'SyncEngine: failed to fetch server data for conflict check',
        error: e,
      );
    }
  }

  /// Updates the local cache after a successful sync.
  Future<void> _updateLocalCache(SyncQueueItem item) async {
    try {
      final userId = _currentUserId;
      if (userId == null) return;

      switch (item.operationType) {
        case SyncOperationType.insert:
          // Cache the newly inserted record.
          final recordId = item.recordId ?? item.payload['id'] as String?;
          if (recordId != null) {
            await _cacheManager.cacheData(
              key: '${item.tableName}:$recordId',
              userId: userId,
              resourceType: item.tableName,
              resourceId: recordId,
              data: item.payload,
            );
          }
          break;

        case SyncOperationType.update:
          // Update the cached record.
          if (item.recordId != null) {
            await _cacheManager.cacheData(
              key: '${item.tableName}:${item.recordId}',
              userId: userId,
              resourceType: item.tableName,
              resourceId: item.recordId!,
              data: item.payload,
            );
          }
          break;

        case SyncOperationType.delete:
          // Remove from cache.
          if (item.recordId != null) {
            await _cacheManager.invalidateCache(
              key: '${item.tableName}:${item.recordId}',
              userId: userId,
            );
          }
          break;
      }
    } catch (e, st) {
      AppLogger.error(
        'SyncEngine: failed to update local cache',
        error: e,
        stackTrace: st,
      );
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // INTERNAL — TIMER & CONNECTIVITY
  // ═══════════════════════════════════════════════════════════════════════

  /// Starts the periodic auto-sync timer.
  void _startAutoSyncTimer() {
    _autoSyncTimer?.cancel();

    final behavior = AdaptiveBehavior(_connectivityEngine.state);
    final interval = behavior.syncInterval;

    // Don't start a timer if offline (interval is Duration.zero).
    if (interval == Duration.zero) {
      AppLogger.debug('SyncEngine: auto-sync timer skipped — offline');
      return;
    }

    _autoSyncTimer = Timer.periodic(interval, (_) async {
      if (!state.isSyncing && state.isAutoSyncEnabled) {
        AppLogger.debug('SyncEngine: auto-sync triggered');
        await processQueue();
      }
    });

    AppLogger.debug(
      'SyncEngine: auto-sync timer started (interval: ${interval.inSeconds}s)',
    );
  }

  /// Reacts to connectivity state changes.
  void _onConnectivityChanged(ConnectivityState connectivityState) {
    if (_isDisposed) return;

    if (connectivityState.isOnline &&
        !connectivityState.isSyncing &&
        state.isAutoSyncEnabled) {
      // Came online — restart timer with updated interval.
      _startAutoSyncTimer();

      // If we have pending items, trigger an immediate sync.
      if (state.hasPendingItems) {
        AppLogger.info(
          'SyncEngine: device online with ${state.pendingCount} pending — '
          'triggering immediate sync',
        );
        processQueue();
      }
    } else if (!connectivityState.isOnline) {
      // Went offline — cancel the timer.
      _autoSyncTimer?.cancel();
      _autoSyncTimer = null;
      AppLogger.info('SyncEngine: device offline — auto-sync paused');
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // INTERNAL — UTILITIES
  // ═══════════════════════════════════════════════════════════════════════

  /// Returns the currently authenticated user's ID, or null.
  String? get _currentUserId {
    try {
      return (_supabaseClient as sb.SupabaseClient).auth.currentUser?.id;
    } catch (e) {
      AppLogger.warning('SyncEngine: could not resolve current user ID');
      return null;
    }
  }

  /// Sorts pending items by priority (ascending) then creation time.
  void _sortPendingItems() {
    _pendingItems.sort((a, b) {
      final priorityCompare = a.priority.level.compareTo(b.priority.level);
      if (priorityCompare != 0) return priorityCompare;
      return a.createdAt.compareTo(b.createdAt);
    });
  }

  /// Compares two data maps for meaningful differences, ignoring
  /// metadata fields like `updated_at`, `created_at`, and `id`.
  bool _dataDiffers(
    Map<String, dynamic> local,
    Map<String, dynamic> server,
  ) {
    const metadataFields = {
      'updated_at',
      'created_at',
      'id',
      'sync_version',
      'checksum',
    };

    final localData = Map<String, dynamic>.from(local)
      ..removeWhere((k, _) => metadataFields.contains(k));
    final serverData = Map<String, dynamic>.from(server)
      ..removeWhere((k, _) => metadataFields.contains(k));

    if (localData.length != serverData.length) return true;

    for (final key in localData.keys) {
      if (!serverData.containsKey(key)) return true;
      if (localData[key] != serverData[key]) return true;
    }

    return false;
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// OFFLINE-AWARE REPOSITORY
// ═══════════════════════════════════════════════════════════════════════════════

/// A mixin/wrapper that makes any repository offline-aware.
///
/// Implements the template method pattern: every method call is wrapped
/// with a connectivity check. If online, the remote call is executed and
/// the result is cached locally. If offline, mutations are queued in the
/// sync queue and cached data is returned as a fallback.
///
/// Usage:
/// ```dart
/// class QuestionRepository with OfflineAwareRepository {
///   @override
///   final Ref ref;
///
///   QuestionRepository(this.ref);
///
///   Future<Result<List<Question>>> getQuestions() {
///     return executeOfflineAware(
///       remoteCall: () => apiClient.get('/questions'),
///       localFallback: () => cacheManager.getCachedData(...),
///       tableName: 'questions',
///       operation: SyncOperationType.insert,
///     );
///   }
/// }
/// ```
mixin OfflineAwareRepository {
  /// The Riverpod [Ref] for accessing providers.
  ///
  /// Implementations must provide this — typically via their constructor.
  Ref get ref;

  /// Executes an operation with offline-awareness.
  ///
  /// Algorithm:
  ///   1. Check connectivity.
  ///   2. If **online**:
  ///      a. Execute [remoteCall].
  ///      b. If successful, cache the result locally.
  ///      c. Return the result.
  ///   3. If **offline**:
  ///      a. If [operation] is a mutation (insert/update/delete),
  ///         enqueue it in the sync queue.
  ///      b. Return [localFallback] data.
  Future<Result<T>> executeOfflineAware<T>({
    required Future<Result<T>> Function() remoteCall,
    required Future<Result<T>> Function() localFallback,
    required String tableName,
    required SyncOperationType operation,
    Map<String, dynamic>? syncPayload,
    String? recordId,
    SyncPriority priority = SyncPriority.normal,
  }) async {
    final connectivityState = ref.read(connectivityEngineProvider);
    final isOnline = connectivityState.isOnline;

    if (isOnline) {
      try {
        // Execute the remote call.
        final result = await remoteCall();

        // If successful, cache the result and return.
        await result.fold(
          onSuccess: (data) async {
            // Cache the successful result.
            await _cacheSuccessfulResult(
              data,
              tableName,
              recordId,
            );
          },
          onFailure: (_) async {
            // Remote call failed — fall back to local cache.
          },
        );

        // Return the remote result even if caching fails.
        return result;
      } catch (e) {
        AppLogger.warning(
          'OfflineAwareRepository: remote call failed, '
          'falling back to local — $e',
        );
        // Fall through to local fallback.
      }
    }

    // Offline (or remote call failed) — use local fallback.
    if (!isOnline && syncPayload != null) {
      // If this is a mutation, enqueue it for later sync.
      try {
        await ref.read(syncEngineProvider.notifier).enqueueOperation(
              tableName: tableName,
              operation: operation,
              payload: syncPayload,
              recordId: recordId,
              priority: priority,
            );
      } catch (e, st) {
        AppLogger.error(
          'OfflineAwareRepository: failed to enqueue offline operation',
          error: e,
          stackTrace: st,
        );
      }
    }

    // Return the local fallback.
    return localFallback();
  }

  /// Caches a successful result locally for offline access.
  Future<void> _cacheSuccessfulResult<T>(
    T data,
    String tableName,
    String? recordId,
  ) async {
    try {
      if (data is! Map<String, dynamic>) return;

      final cacheManager = ref.read(cacheManagerProvider);
      final userId = ref.read(supabaseClientProvider).auth.currentUser?.id;
      if (userId == null || recordId == null) return;

      await cacheManager.cacheData(
        key: '$tableName:$recordId',
        userId: userId,
        resourceType: tableName,
        resourceId: recordId,
        data: data,
      );
    } catch (e, st) {
      AppLogger.error(
        'OfflineAwareRepository: failed to cache result',
        error: e,
        stackTrace: st,
      );
    }
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// RIVERPOD PROVIDERS
// ═══════════════════════════════════════════════════════════════════════════════

/// Primary provider: the [SyncEngine] state notifier.
///
/// Watches [cacheManagerProvider], [supabaseClientProvider], and
/// [connectivityEngineProvider] so that the engine is always using
/// the currently configured dependencies.
final syncEngineProvider =
    StateNotifierProvider<SyncEngine, SyncEngineState>((ref) {
  final cacheManager = ref.watch(cacheManagerProvider);
  final supabaseClient = ref.watch(supabaseClientProvider);
  final connectivityEngine =
      ref.watch(connectivityEngineProvider.notifier);

  final engine = SyncEngine(
    cacheManager: cacheManager,
    supabaseClient: supabaseClient,
    connectivityEngine: connectivityEngine,
  );

  // Initialize the engine and clean up on dispose.
  engine.initialize();
  ref.onDispose(() {
    AppLogger.info('SyncEngineProvider: disposing sync engine');
  });

  return engine;
});

/// Derived provider: count of pending sync items.
final pendingSyncCountProvider = Provider<int>((ref) {
  return ref.watch(syncEngineProvider).pendingCount;
});

/// Derived provider: whether there are unresolved conflicts.
final hasConflictsProvider = Provider<bool>((ref) {
  return ref.watch(syncEngineProvider).hasConflicts;
});

/// Derived provider: overall sync health assessment string.
final syncHealthProvider = Provider<String>((ref) {
  return ref.watch(syncEngineProvider).syncHealth;
});

/// Derived provider: whether automatic sync is currently enabled.
final isAutoSyncEnabledProvider = Provider<bool>((ref) {
  return ref.watch(syncEngineProvider).isAutoSyncEnabled;
});
