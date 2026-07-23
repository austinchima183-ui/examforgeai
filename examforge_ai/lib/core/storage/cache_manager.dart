/// High-level caching service that wraps the local Drift database.
///
/// Provides domain-friendly methods for caching, drafts, sync-queue
/// management, resource tracking, offline exam attempts, and storage
/// statistics. All methods include proper error handling and logging.
library;

import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../config/dependency_injection.dart';
import '../../services/storage_service.dart';
import '../utils/logger.dart';
import 'local_database.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// CACHE MANAGER
// ═══════════════════════════════════════════════════════════════════════════════

/// Centralised caching service for ExamForge AI.
///
/// Wraps [AppDatabase] with high-level, type-safe methods grouped by
/// domain concern (cache, drafts, sync queue, resources, exam attempts).
class CacheManager {
  CacheManager({
    required this.database,
    required this.storageService,
  });

  /// The underlying Drift database.
  final AppDatabase database;

  /// Secure / shared-preferences storage service.
  final StorageService storageService;

  /// UUID generator for new records.
  static const _uuid = Uuid();

  // ═══════════════════════════════════════════════════════════════════════════
  // GENERIC CACHE OPERATIONS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Stores [data] in the cache under [key] for [userId].
  ///
  /// If [ttl] is provided the entry will be considered expired after
  /// the given duration; otherwise it never expires.
  Future<void> cacheData({
    required String key,
    required String userId,
    required String resourceType,
    required String resourceId,
    required Map<String, dynamic> data,
    Duration? ttl,
  }) async {
    try {
      final now = DateTime.now();
      final id = _uuid.v4();
      final json = jsonEncode(data);
      final expiresAt = ttl != null ? now.add(ttl) : null;

      await database.into(database.cache).insertOnConflictUpdate(
            LocalCacheTableCompanion.insert(
              id: id,
              userId: userId,
              cacheKey: key,
              resourceType: resourceType,
              resourceId: resourceId,
              data: json,
              expiresAt: Value(expiresAt),
              fileSizeBytes: Value(json.length),
              createdAt: now,
              updatedAt: now,
            ),
          );
      AppLogger.debug('CacheManager: cached data for key=$key');
    } catch (e, st) {
      AppLogger.error('CacheManager: failed to cache data', error: e, stackTrace: st);
      rethrow;
    }
  }

  /// Retrieves cached data for [key] belonging to [userId].
  ///
  /// Returns `null` if no entry exists or the entry has expired.
  /// On a successful hit the access count and last-accessed timestamp
  /// are updated.
  Future<Map<String, dynamic>?> getCachedData({
    required String key,
    required String userId,
  }) async {
    try {
      final query = database.select(database.cache)
        ..where((t) => t.cacheKey.equals(key) & t.userId.equals(userId));

      final row = await query.getSingleOrNull();
      if (row == null) return null;

      // Check expiry.
      if (row.expiresAt != null &&
          row.expiresAt!.isBefore(DateTime.now())) {
        await invalidateCache(key: key, userId: userId);
        return null;
      }

      // Update access metadata.
      await (database.update(database.cache)
            ..where((t) => t.id.equals(row.id)))
          .write(LocalCacheTableCompanion(
        accessCount: Value(row.accessCount + 1),
        lastAccessedAt: Value(DateTime.now()),
      ),);

      return jsonDecode(row.data) as Map<String, dynamic>;
    } catch (e, st) {
      AppLogger.error('CacheManager: failed to get cached data', error: e, stackTrace: st);
      return null;
    }
  }

  /// Removes a single cache entry identified by [key] and [userId].
  Future<void> invalidateCache({
    required String key,
    required String userId,
  }) async {
    try {
      await (database.delete(database.cache)
            ..where((t) => t.cacheKey.equals(key) & t.userId.equals(userId)))
          .go();
      AppLogger.debug('CacheManager: invalidated cache key=$key');
    } catch (e, st) {
      AppLogger.error('CacheManager: failed to invalidate cache', error: e, stackTrace: st);
      rethrow;
    }
  }

  /// Removes **all** cache entries for [resourceType] belonging to [userId].
  Future<void> invalidateCacheByType({
    required String resourceType,
    required String userId,
  }) async {
    try {
      final count = await (database.delete(database.cache)
            ..where(
                (t) => t.resourceType.equals(resourceType) & t.userId.equals(userId),))
          .go();
      AppLogger.debug(
        'CacheManager: invalidated $count cache entries of type=$resourceType',
      );
    } catch (e, st) {
      AppLogger.error('CacheManager: failed to invalidate cache by type', error: e, stackTrace: st);
      rethrow;
    }
  }

  /// Removes all expired cache entries across all users.
  Future<void> clearExpiredCache() async {
    try {
      final count = await database.clearExpiredCache();
      AppLogger.debug('CacheManager: cleared $count expired cache entries');
    } catch (e, st) {
      AppLogger.error('CacheManager: failed to clear expired cache', error: e, stackTrace: st);
      rethrow;
    }
  }

  /// Returns `true` if a non-expired cache entry exists for [key].
  Future<bool> isCacheValid({
    required String key,
    required String userId,
  }) async {
    try {
      final data = await getCachedData(key: key, userId: userId);
      return data != null;
    } catch (e, st) {
      AppLogger.error('CacheManager: cache validity check failed', error: e, stackTrace: st);
      return false;
    }
  }

  /// Returns the number of cache entries owned by [userId].
  Future<int> getCacheSize({required String userId}) async {
    try {
      final rows = await (database.select(database.cache)
            ..where((t) => t.userId.equals(userId)))
          .get();
      return rows.length;
    } catch (e, st) {
      AppLogger.error('CacheManager: failed to get cache size', error: e, stackTrace: st);
      return 0;
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // USER DATA CACHING
  // ═══════════════════════════════════════════════════════════════════════════

  /// Caches a user profile locally.
  ///
  /// If a profile for [userId] already exists it will be updated.
  Future<void> cacheUserProfile({
    required String userId,
    required Map<String, dynamic> profileData,
    required String role,
    String? schoolId,
  }) async {
    try {
      final now = DateTime.now();

      // Check if a profile already exists for this user.
      final existing = await (database.select(database.userData)
            ..where((t) => t.userId.equals(userId)))
          .getSingleOrNull();

      if (existing != null) {
        await (database.update(database.userData)
              ..where((t) => t.userId.equals(userId)))
            .write(LocalUserDataTableCompanion(
          profileData: Value(jsonEncode(profileData)),
          role: Value(role),
          schoolId: Value(schoolId),
          lastSyncedAt: Value(now),
          updatedAt: Value(now),
        ),);
      } else {
        await database.into(database.userData).insert(
              LocalUserDataTableCompanion.insert(
                id: _uuid.v4(),
                userId: userId,
                profileData: jsonEncode(profileData),
                role: role,
                schoolId: Value(schoolId),
                lastSyncedAt: now,
                createdAt: now,
                updatedAt: now,
              ),
            );
      }
      AppLogger.debug('CacheManager: cached user profile for $userId');
    } catch (e, st) {
      AppLogger.error('CacheManager: failed to cache user profile', error: e, stackTrace: st);
      rethrow;
    }
  }

  /// Retrieves a cached user profile for [userId].
  ///
  /// Returns `null` if no profile has been cached.
  Future<Map<String, dynamic>?> getCachedUserProfile({
    required String userId,
  }) async {
    try {
      final row = await (database.select(database.userData)
            ..where((t) => t.userId.equals(userId)))
          .getSingleOrNull();
      if (row == null) return null;
      return jsonDecode(row.profileData) as Map<String, dynamic>;
    } catch (e, st) {
      AppLogger.error('CacheManager: failed to get cached user profile', error: e, stackTrace: st);
      return null;
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // DRAFT OPERATIONS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Saves a draft locally.
  ///
  /// If a draft with the same [id] already exists it will be updated;
  /// otherwise a new entry is created.
  Future<void> saveDraft({
    required String userId,
    required String draftType,
    required Map<String, dynamic> content,
    String? title,
    String? schoolId,
    String? subjectId,
  }) async {
    try {
      final now = DateTime.now();
      await database.into(database.drafts).insertOnConflictUpdate(
            LocalDraftsTableCompanion.insert(
              id: _uuid.v4(),
              userId: userId,
              draftType: draftType,
              content: jsonEncode(content),
              title: Value(title),
              schoolId: Value(schoolId),
              subjectId: Value(subjectId),
              lastEditedAt: now,
              createdAt: now,
              updatedAt: now,
            ),
          );
      AppLogger.debug('CacheManager: saved draft of type=$draftType');
    } catch (e, st) {
      AppLogger.error('CacheManager: failed to save draft', error: e, stackTrace: st);
      rethrow;
    }
  }

  /// Returns all drafts for [userId], optionally filtered by [draftType].
  Future<List<Map<String, dynamic>>> getDrafts({
    required String userId,
    String? draftType,
  }) async {
    try {
      final query = database.select(database.drafts)
        ..where((t) => t.userId.equals(userId));

      if (draftType != null) {
        query.where((t) => t.draftType.equals(draftType));
      }

      // Most recently edited first.
      query.orderBy([
        (t) => OrderingTerm.desc(t.lastEditedAt),
      ]);

      final rows = await query.get();
      return rows.map((row) => {
            'id': row.id,
            'userId': row.userId,
            'draftType': row.draftType,
            'title': row.title,
            'content': jsonDecode(row.content),
            'schoolId': row.schoolId,
            'subjectId': row.subjectId,
            'isSynced': row.isSynced,
            'lastEditedAt': row.lastEditedAt.toIso8601String(),
            'createdAt': row.createdAt.toIso8601String(),
            'updatedAt': row.updatedAt.toIso8601String(),
          },).toList();
    } catch (e, st) {
      AppLogger.error('CacheManager: failed to get drafts', error: e, stackTrace: st);
      return [];
    }
  }

  /// Deletes a draft by [id].
  Future<void> deleteDraft({required String id}) async {
    try {
      await (database.delete(database.drafts)..where((t) => t.id.equals(id))).go();
      AppLogger.debug('CacheManager: deleted draft $id');
    } catch (e, st) {
      AppLogger.error('CacheManager: failed to delete draft', error: e, stackTrace: st);
      rethrow;
    }
  }

  /// Marks a draft as synced to the server.
  Future<void> markDraftSynced({required String id}) async {
    try {
      await (database.update(database.drafts)..where((t) => t.id.equals(id)))
          .write(const LocalDraftsTableCompanion(
        isSynced: Value(true),
      ),);
      AppLogger.debug('CacheManager: marked draft $id as synced');
    } catch (e, st) {
      AppLogger.error('CacheManager: failed to mark draft synced', error: e, stackTrace: st);
      rethrow;
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // SYNC QUEUE OPERATIONS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Enqueues a sync operation for later replay.
  Future<void> enqueueSync({
    required String userId,
    required String tableName,
    required String operation,
    required Map<String, dynamic> payload,
    String? recordId,
    int priority = 5,
  }) async {
    try {
      final now = DateTime.now();
      await database.into(database.syncQueue).insert(
            LocalSyncQueueTableCompanion.insert(
              id: _uuid.v4(),
              userId: userId,
              targetTable: tableName,
              recordId: Value(recordId),
              operation: operation,
              payload: jsonEncode(payload),
              priority: Value(priority),
              createdAt: now,
              updatedAt: now,
            ),
          );
      AppLogger.debug(
        'CacheManager: enqueued sync op=$operation table=$tableName',
      );
    } catch (e, st) {
      AppLogger.error('CacheManager: failed to enqueue sync', error: e, stackTrace: st);
      rethrow;
    }
  }

  /// Returns up to [limit] pending sync items for [userId],
  /// ordered by priority (ascending) then creation time (ascending).
  Future<List<Map<String, dynamic>>> getPendingSyncItems({
    required String userId,
    int limit = 50,
  }) async {
    try {
      final query = database.select(database.syncQueue)
        ..where((t) =>
            t.userId.equals(userId) &
            t.status.isIn(['pending', 'failed']),)
        ..orderBy([
          (t) => OrderingTerm.asc(t.priority),
          (t) => OrderingTerm.asc(t.createdAt),
        ])
        ..limit(limit);

      final rows = await query.get();
      return rows.map((row) => {
            'id': row.id,
            'userId': row.userId,
            'targetTable': row.targetTable,
            'recordId': row.recordId,
            'operation': row.operation,
            'payload': jsonDecode(row.payload),
            'priority': row.priority,
            'attempts': row.attempts,
            'maxAttempts': row.maxAttempts,
            'lastAttemptAt': row.lastAttemptAt?.toIso8601String(),
            'nextRetryAt': row.nextRetryAt?.toIso8601String(),
            'status': row.status,
            'errorMessage': row.errorMessage,
            'createdAt': row.createdAt.toIso8601String(),
            'updatedAt': row.updatedAt.toIso8601String(),
          },).toList();
    } catch (e, st) {
      AppLogger.error('CacheManager: failed to get pending sync items', error: e, stackTrace: st);
      return [];
    }
  }

  /// Marks a sync queue item as completed.
  Future<void> markSyncItemCompleted({required String id}) async {
    try {
      final now = DateTime.now();
      await (database.update(database.syncQueue)..where((t) => t.id.equals(id)))
          .write(LocalSyncQueueTableCompanion(
        status: const Value('completed'),
        updatedAt: Value(now),
      ),);
      AppLogger.debug('CacheManager: sync item $id completed');
    } catch (e, st) {
      AppLogger.error('CacheManager: failed to mark sync item completed', error: e, stackTrace: st);
      rethrow;
    }
  }

  /// Marks a sync queue item as failed with [errorMessage].
  ///
  /// If the number of attempts exceeds `maxAttempts` the item is
  /// automatically moved to the `dead` status.
  Future<void> markSyncItemFailed({
    required String id,
    required String errorMessage,
  }) async {
    try {
      final now = DateTime.now();

      // Fetch current row to check attempt count.
      final row = await (database.select(database.syncQueue)
            ..where((t) => t.id.equals(id)))
          .getSingleOrNull();

      if (row == null) {
        AppLogger.warning('CacheManager: sync item $id not found');
        return;
      }

      final newAttempts = row.attempts + 1;
      final isDead = newAttempts >= row.maxAttempts;

      // Exponential backoff: 2^attempts seconds, capped at 1 hour.
      final backoffSeconds = (1 << newAttempts).clamp(1, 3600);

      await (database.update(database.syncQueue)..where((t) => t.id.equals(id)))
          .write(LocalSyncQueueTableCompanion(
        attempts: Value(newAttempts),
        status: Value(isDead ? 'dead' : 'failed'),
        errorMessage: Value(errorMessage),
        lastAttemptAt: Value(now),
        nextRetryAt: Value(isDead ? null : now.add(Duration(seconds: backoffSeconds))),
        updatedAt: Value(now),
      ),);

      AppLogger.debug(
        'CacheManager: sync item $id failed (attempt $newAttempts/${row.maxAttempts})'
        '${isDead ? ' → dead' : ''}',
      );
    } catch (e, st) {
      AppLogger.error('CacheManager: failed to mark sync item failed', error: e, stackTrace: st);
      rethrow;
    }
  }

  /// Returns the count of pending (or retryable) sync items for [userId].
  Future<int> getPendingSyncCount({required String userId}) async {
    try {
      final rows = await (database.select(database.syncQueue)
            ..where((t) =>
                t.userId.equals(userId) &
                t.status.isIn(['pending', 'failed']),))
          .get();
      return rows.length;
    } catch (e, st) {
      AppLogger.error('CacheManager: failed to get pending sync count', error: e, stackTrace: st);
      return 0;
    }
  }

  /// Removes dead sync items that have exceeded their max attempts.
  Future<void> cleanupDeadSyncItems() async {
    try {
      final count = await (database.delete(database.syncQueue)
            ..where((t) => t.status.equals('dead')))
          .go();
      AppLogger.debug('CacheManager: cleaned up $count dead sync items');
    } catch (e, st) {
      AppLogger.error('CacheManager: failed to cleanup dead sync items', error: e, stackTrace: st);
      rethrow;
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // RESOURCE OPERATIONS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Records a downloaded resource in the local database.
  Future<void> cacheResource({
    required String userId,
    required String resourceType,
    required String resourceId,
    required String title,
    required String filePath,
    required int fileSizeBytes,
    String? mimeType,
    DateTime? licenseExpiresAt,
  }) async {
    try {
      final now = DateTime.now();
      await database.into(database.resources).insertOnConflictUpdate(
            LocalResourcesTableCompanion.insert(
              id: _uuid.v4(),
              userId: userId,
              resourceType: resourceType,
              resourceId: resourceId,
              title: title,
              filePath: filePath,
              fileSizeBytes: fileSizeBytes,
              mimeType: Value(mimeType),
              licenseExpiresAt: Value(licenseExpiresAt),
              createdAt: now,
              updatedAt: now,
            ),
          );
      AppLogger.debug('CacheManager: cached resource "$title"');
    } catch (e, st) {
      AppLogger.error('CacheManager: failed to cache resource', error: e, stackTrace: st);
      rethrow;
    }
  }

  /// Returns cached resources for [userId], optionally filtered by [resourceType].
  Future<List<Map<String, dynamic>>> getCachedResources({
    required String userId,
    String? resourceType,
  }) async {
    try {
      final query = database.select(database.resources)
        ..where((t) => t.userId.equals(userId) & t.isAvailable.equals(true));

      if (resourceType != null) {
        query.where((t) => t.resourceType.equals(resourceType));
      }

      query.orderBy([
        (t) => OrderingTerm.desc(t.lastAccessedAt),
      ]);

      final rows = await query.get();
      return rows.map((row) => {
            'id': row.id,
            'userId': row.userId,
            'resourceType': row.resourceType,
            'resourceId': row.resourceId,
            'title': row.title,
            'filePath': row.filePath,
            'fileSizeBytes': row.fileSizeBytes,
            'mimeType': row.mimeType,
            'checksum': row.checksum,
            'licenseExpiresAt': row.licenseExpiresAt?.toIso8601String(),
            'isAvailable': row.isAvailable,
            'accessCount': row.accessCount,
            'lastAccessedAt': row.lastAccessedAt?.toIso8601String(),
            'createdAt': row.createdAt.toIso8601String(),
            'updatedAt': row.updatedAt.toIso8601String(),
          },).toList();
    } catch (e, st) {
      AppLogger.error('CacheManager: failed to get cached resources', error: e, stackTrace: st);
      return [];
    }
  }

  /// Removes a cached resource entry by [id].
  Future<void> removeResource({required String id}) async {
    try {
      await (database.delete(database.resources)..where((t) => t.id.equals(id)))
          .go();
      AppLogger.debug('CacheManager: removed resource $id');
    } catch (e, st) {
      AppLogger.error('CacheManager: failed to remove resource', error: e, stackTrace: st);
      rethrow;
    }
  }

  /// Returns `true` if a resource identified by [resourceId] is
  /// available locally for [userId].
  Future<bool> isResourceAvailable({
    required String userId,
    required String resourceId,
  }) async {
    try {
      final row = await (database.select(database.resources)
            ..where((t) =>
                t.userId.equals(userId) &
                t.resourceId.equals(resourceId) &
                t.isAvailable.equals(true),))
          .getSingleOrNull();
      return row != null;
    } catch (e, st) {
      AppLogger.error('CacheManager: failed to check resource availability', error: e, stackTrace: st);
      return false;
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // EXAM ATTEMPT OPERATIONS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Saves an offline exam attempt for later syncing.
  Future<void> saveOfflineExamAttempt({
    required String examId,
    required String studentId,
    Map<String, dynamic>? schoolId,
    required Map<String, dynamic> attemptData,
    required Map<String, dynamic> answers,
    required DateTime startedAt,
    DateTime? completedAt,
    int timeTakenSeconds = 0,
    String? integrityHash,
  }) async {
    try {
      final now = DateTime.now();
      await database.into(database.examAttempts).insert(
            LocalExamAttemptsTableCompanion.insert(
              id: _uuid.v4(),
              examId: examId,
              studentId: studentId,
              schoolId: Value(schoolId?['id'] as String?),
              attemptData: jsonEncode(attemptData),
              answers: jsonEncode(answers),
              startedAt: startedAt,
              completedAt: Value(completedAt),
              timeTakenSeconds: Value(timeTakenSeconds),
              integrityHash: Value(integrityHash),
              createdAt: now,
            ),
          );
      AppLogger.debug(
        'CacheManager: saved offline exam attempt exam=$examId student=$studentId',
      );
    } catch (e, st) {
      AppLogger.error('CacheManager: failed to save offline exam attempt', error: e, stackTrace: st);
      rethrow;
    }
  }

  /// Returns pending (unsynced) exam attempts for [studentId].
  Future<List<Map<String, dynamic>>> getPendingExamAttempts({
    required String studentId,
  }) async {
    try {
      final query = database.select(database.examAttempts)
        ..where((t) =>
            t.studentId.equals(studentId) &
            t.syncStatus.isIn(['pending', 'rejected']),)
        ..orderBy([
          (t) => OrderingTerm.asc(t.startedAt),
        ]);

      final rows = await query.get();
      return rows.map((row) => {
            'id': row.id,
            'examId': row.examId,
            'studentId': row.studentId,
            'schoolId': row.schoolId,
            'attemptData': jsonDecode(row.attemptData),
            'answers': jsonDecode(row.answers),
            'startedAt': row.startedAt.toIso8601String(),
            'completedAt': row.completedAt?.toIso8601String(),
            'timeTakenSeconds': row.timeTakenSeconds,
            'integrityHash': row.integrityHash,
            'syncStatus': row.syncStatus,
            'syncAttempts': row.syncAttempts,
            'syncedAt': row.syncedAt?.toIso8601String(),
            'validationErrors': row.validationErrors,
            'createdAt': row.createdAt.toIso8601String(),
          },).toList();
    } catch (e, st) {
      AppLogger.error('CacheManager: failed to get pending exam attempts', error: e, stackTrace: st);
      return [];
    }
  }

  /// Marks an exam attempt as successfully synced.
  Future<void> markExamAttemptSynced({required String id}) async {
    try {
      final now = DateTime.now();
      await (database.update(database.examAttempts)
            ..where((t) => t.id.equals(id)))
          .write(LocalExamAttemptsTableCompanion(
        syncStatus: const Value('synced'),
        syncedAt: Value(now),
      ),);
      AppLogger.debug('CacheManager: exam attempt $id synced');
    } catch (e, st) {
      AppLogger.error('CacheManager: failed to mark exam attempt synced', error: e, stackTrace: st);
      rethrow;
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // STATS & MAINTENANCE
  // ═══════════════════════════════════════════════════════════════════════════

  /// Returns row counts per table for storage diagnostics.
  Future<Map<String, int>> getStorageStats() async {
    try {
      return database.getDatabaseSize();
    } catch (e, st) {
      AppLogger.error('CacheManager: failed to get storage stats', error: e, stackTrace: st);
      return {};
    }
  }

  /// Deletes all local data associated with [userId] across all tables.
  ///
  /// Typically called on logout. Does **not** clear connectivity logs
  /// or sync metadata (which may be shared across sessions).
  Future<void> clearAllUserData({required String userId}) async {
    try {
      await database.transaction(() async {
        await (database.delete(database.syncQueue)
              ..where((t) => t.userId.equals(userId)))
            .go();
        await (database.delete(database.cache)
              ..where((t) => t.userId.equals(userId)))
            .go();
        await (database.delete(database.drafts)
              ..where((t) => t.userId.equals(userId)))
            .go();
        await (database.delete(database.userData)
              ..where((t) => t.userId.equals(userId)))
            .go();
        await (database.delete(database.resources)
              ..where((t) => t.userId.equals(userId)))
            .go();
        await (database.delete(database.notifications)
              ..where((t) => t.userId.equals(userId)))
            .go();
        await (database.delete(database.syncMetadata)
              ..where((t) => t.userId.equals(userId)))
            .go();
        // Exam attempts are keyed by studentId.
        await (database.delete(database.examAttempts)
              ..where((t) => t.studentId.equals(userId)))
            .go();
      });
      AppLogger.info('CacheManager: cleared all data for user $userId');
    } catch (e, st) {
      AppLogger.error('CacheManager: failed to clear user data', error: e, stackTrace: st);
      rethrow;
    }
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// RIVERPOD PROVIDERS
// ═══════════════════════════════════════════════════════════════════════════════

/// Provides the singleton [AppDatabase] instance.
///
/// The database is lazily opened on first access and automatically
/// closed when the provider is disposed.
final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(() {
    db.close();
    AppLogger.info('AppDatabase: connection closed');
  });
  return db;
});

/// Provides the singleton [CacheManager] instance.
///
/// Depends on [appDatabaseProvider] and [storageServiceProvider].
final cacheManagerProvider = Provider<CacheManager>((ref) {
  final database = ref.watch(appDatabaseProvider);
  final storageService = ref.watch(storageServiceProvider);
  return CacheManager(
    database: database,
    storageService: storageService,
  );
});
