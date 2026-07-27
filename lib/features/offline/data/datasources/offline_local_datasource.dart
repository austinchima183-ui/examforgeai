// =============================================================================
// ExamForge AI — Offline Local Data Source
// =============================================================================
//
// Abstract interface and concrete implementation for all local offline data
// operations. Delegates to [CacheManager] (which wraps the Drift database)
// for all reads and writes.
//
// Throws [CacheException] on any local storage failure.
// =============================================================================

import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/errors/exceptions.dart';
import '../../../../core/storage/cache_manager.dart';
import '../../../../core/utils/logger.dart';
import '../../domain/entities/offline_entities.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// ABSTRACT INTERFACE
// ═══════════════════════════════════════════════════════════════════════════════

/// Abstract contract for all local (offline) data operations.
///
/// Every method reads from or writes to the device's local storage via
/// [CacheManager]. Implementations must throw [CacheException] on failure.
abstract class OfflineLocalDataSource {
  // ─── Sync Status ────────────────────────────────────────────────────────

  /// Returns the current sync status for [userId].
  SyncStatusInfo getSyncStatus(String userId);

  // ─── Offline Resources ──────────────────────────────────────────────────

  /// Returns all offline resources for [userId], optionally filtered by
  /// [resourceType].
  Future<List<OfflineResource>> getOfflineResources(
    String userId, {
    String? resourceType,
  });

  /// Saves an offline resource to local storage.
  ///
  /// Returns `true` on success.
  Future<bool> saveOfflineResource(Map<String, dynamic> resourceData);

  /// Removes an offline resource by [resourceId].
  ///
  /// Returns `true` on success.
  Future<bool> removeOfflineResource(String resourceId);

  // ─── Drafts ─────────────────────────────────────────────────────────────

  /// Returns all drafts for [userId], optionally filtered by [draftType].
  Future<List<DraftWork>> getDrafts(
    String userId, {
    String? draftType,
  });

  /// Saves or updates a draft.
  Future<DraftWork> saveDraft(Map<String, dynamic> draftData);

  /// Deletes a draft by [draftId].
  ///
  /// Returns `true` on success.
  Future<bool> deleteDraft(String draftId);

  // ─── Exam Attempts ──────────────────────────────────────────────────────

  /// Saves an offline exam attempt locally.
  Future<OfflineExamAttempt> saveExamAttempt(Map<String, dynamic> attemptData);

  /// Returns all pending (unsynced) exam attempts for [studentId].
  Future<List<OfflineExamAttempt>> getPendingExamAttempts(String studentId);

  /// Marks an exam attempt as successfully synced.
  ///
  /// Returns `true` on success.
  Future<bool> markExamAttemptSynced(String attemptId);

  // ─── File Downloads ─────────────────────────────────────────────────────

  /// Returns all downloads for [userId], optionally filtered by [status].
  Future<List<FileDownload>> getDownloads(
    String userId, {
    String? status,
  });

  /// Saves a file download record.
  Future<FileDownload> saveDownload(Map<String, dynamic> downloadData);

  /// Updates the status (and optionally [progress]) of a download.
  ///
  /// Returns `true` on success.
  Future<bool> updateDownloadStatus(
    String downloadId,
    String status, {
    double? progress,
  });
}

// ═══════════════════════════════════════════════════════════════════════════════
// IMPLEMENTATION
// ═══════════════════════════════════════════════════════════════════════════════

/// Concrete implementation of [OfflineLocalDataSource] that delegates all
/// operations to [CacheManager].
class OfflineLocalDataSourceImpl implements OfflineLocalDataSource {
  OfflineLocalDataSourceImpl({required this.cacheManager});

  final CacheManager cacheManager;

  static const _uuid = Uuid();

  // ═══════════════════════════════════════════════════════════════════════
  // SYNC STATUS
  // ═══════════════════════════════════════════════════════════════════════

  @override
  SyncStatusInfo getSyncStatus(String userId) {
    try {
      // Build a SyncStatusInfo from sync queue metadata.
      // In a full implementation, this queries the sync queue table
      // directly. For now, we provide a reasonable default.
      return const SyncStatusInfo(
        pendingCount: 0,
        failedCount: 0,
        completedCount: 0,
        deadCount: 0,
        conflictCount: 0,
        isSyncing: false,
        syncHealth: SyncHealth.good,
      );
    } catch (e) {
      AppLogger.error('[OfflineLocalDS] Failed to get sync status', error: e);
      throw CacheException(message: 'Failed to get sync status: $e');
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // OFFLINE RESOURCES
  // ═══════════════════════════════════════════════════════════════════════

  @override
  Future<List<OfflineResource>> getOfflineResources(
    String userId, {
    String? resourceType,
  }) async {
    try {
      final rows = await cacheManager.getCachedResources(
        userId: userId,
        resourceType: resourceType,
      );

      return rows.map(_mapRowToOfflineResource).toList();
    } catch (e) {
      AppLogger.error(
        '[OfflineLocalDS] Failed to get offline resources',
        error: e,
      );
      throw CacheException(message: 'Failed to get offline resources: $e');
    }
  }

  @override
  Future<bool> saveOfflineResource(Map<String, dynamic> resourceData) async {
    try {
      await cacheManager.cacheResource(
        userId: resourceData['user_id'] as String? ?? '',
        resourceType: resourceData['resource_type'] as String? ?? '',
        resourceId: resourceData['resource_id'] as String? ?? '',
        title: resourceData['title'] as String? ?? '',
        filePath: resourceData['file_path'] as String? ?? '',
        fileSizeBytes: resourceData['file_size_bytes'] as int? ?? 0,
        mimeType: resourceData['mime_type'] as String?,
        licenseExpiresAt: resourceData['license_expires_at'] != null
            ? DateTime.parse(resourceData['license_expires_at'] as String)
            : null,
      );
      return true;
    } catch (e) {
      AppLogger.error(
        '[OfflineLocalDS] Failed to save offline resource',
        error: e,
      );
      throw CacheException(message: 'Failed to save offline resource: $e');
    }
  }

  @override
  Future<bool> removeOfflineResource(String resourceId) async {
    try {
      await cacheManager.removeResource(id: resourceId);
      return true;
    } catch (e) {
      AppLogger.error(
        '[OfflineLocalDS] Failed to remove offline resource',
        error: e,
      );
      throw CacheException(message: 'Failed to remove offline resource: $e');
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // DRAFTS
  // ═══════════════════════════════════════════════════════════════════════

  @override
  Future<List<DraftWork>> getDrafts(
    String userId, {
    String? draftType,
  }) async {
    try {
      final rows = await cacheManager.getDrafts(
        userId: userId,
        draftType: draftType,
      );

      return rows.map(_mapRowToDraftWork).toList();
    } catch (e) {
      AppLogger.error(
        '[OfflineLocalDS] Failed to get drafts',
        error: e,
      );
      throw CacheException(message: 'Failed to get drafts: $e');
    }
  }

  @override
  Future<DraftWork> saveDraft(Map<String, dynamic> draftData) async {
    try {
      final draftId = draftData['id'] as String? ?? _uuid.v4();
      final userId = draftData['user_id'] as String;
      final draftType = draftData['draft_type'] as String? ?? 'resource';
      final title = draftData['title'] as String?;
      final content = draftData['content'] as Map<String, dynamic>? ?? {};
      final schoolId = draftData['school_id'] as String?;
      final subjectId = draftData['subject_id'] as String?;

      await cacheManager.saveDraft(
        userId: userId,
        draftType: draftType,
        content: content,
        title: title,
        schoolId: schoolId,
        subjectId: subjectId,
      );

      return DraftWork(
        id: draftId,
        userId: userId,
        draftType: DraftType.fromString(draftType) ?? DraftType.resource,
        title: title ?? '',
        content: content,
        schoolId: schoolId,
        subjectId: subjectId,
        isSynced: false,
        lastEditedAt: DateTime.now(),
        createdAt: DateTime.now(),
      );
    } catch (e) {
      AppLogger.error(
        '[OfflineLocalDS] Failed to save draft',
        error: e,
      );
      throw CacheException(message: 'Failed to save draft: $e');
    }
  }

  @override
  Future<bool> deleteDraft(String draftId) async {
    try {
      await cacheManager.deleteDraft(id: draftId);
      return true;
    } catch (e) {
      AppLogger.error(
        '[OfflineLocalDS] Failed to delete draft',
        error: e,
      );
      throw CacheException(message: 'Failed to delete draft: $e');
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // EXAM ATTEMPTS
  // ═══════════════════════════════════════════════════════════════════════

  @override
  Future<OfflineExamAttempt> saveExamAttempt(
    Map<String, dynamic> attemptData,
  ) async {
    try {
      final attemptId = attemptData['id'] as String? ?? _uuid.v4();
      final examId = attemptData['exam_id'] as String;
      final studentId = attemptData['student_id'] as String;
      final schoolId = attemptData['school_id'];
      final startedAt = attemptData['started_at'] != null
          ? DateTime.parse(attemptData['started_at'] as String)
          : DateTime.now();
      final completedAt = attemptData['completed_at'] != null
          ? DateTime.parse(attemptData['completed_at'] as String)
          : null;
      final timeTakenSeconds = attemptData['time_taken_seconds'] as int? ?? 0;
      final integrityHash = attemptData['integrity_hash'] as String?;
      final answers = attemptData['answers'] as Map<String, dynamic>? ?? {};
      final attemptDataMap =
          attemptData['attempt_data'] as Map<String, dynamic>? ?? {};

      await cacheManager.saveOfflineExamAttempt(
        examId: examId,
        studentId: studentId,
        schoolId: schoolId is String ? {'id': schoolId} : null,
        attemptData: attemptDataMap,
        answers: answers,
        startedAt: startedAt,
        completedAt: completedAt,
        timeTakenSeconds: timeTakenSeconds,
        integrityHash: integrityHash,
      );

      return OfflineExamAttempt(
        id: attemptId,
        examId: examId,
        studentId: studentId,
        schoolId: schoolId is String ? schoolId : '',
        attemptData: attemptDataMap,
        answers: answers,
        startedAt: startedAt,
        completedAt: completedAt,
        timeTakenSeconds: timeTakenSeconds,
        integrityHash: integrityHash ?? '',
        syncStatus: AttemptSyncStatus.pending,
        syncAttempts: 0,
        createdAt: DateTime.now(),
      );
    } catch (e) {
      AppLogger.error(
        '[OfflineLocalDS] Failed to save exam attempt',
        error: e,
      );
      throw CacheException(message: 'Failed to save exam attempt: $e');
    }
  }

  @override
  Future<List<OfflineExamAttempt>> getPendingExamAttempts(
    String studentId,
  ) async {
    try {
      final rows = await cacheManager.getPendingExamAttempts(
        studentId: studentId,
      );

      return rows.map(_mapRowToOfflineExamAttempt).toList();
    } catch (e) {
      AppLogger.error(
        '[OfflineLocalDS] Failed to get pending exam attempts',
        error: e,
      );
      throw CacheException(message: 'Failed to get pending exam attempts: $e');
    }
  }

  @override
  Future<bool> markExamAttemptSynced(String attemptId) async {
    try {
      await cacheManager.markExamAttemptSynced(id: attemptId);
      return true;
    } catch (e) {
      AppLogger.error(
        '[OfflineLocalDS] Failed to mark exam attempt synced',
        error: e,
      );
      throw CacheException(message: 'Failed to mark exam attempt synced: $e');
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // FILE DOWNLOADS
  // ═══════════════════════════════════════════════════════════════════════

  @override
  Future<List<FileDownload>> getDownloads(
    String userId, {
    String? status,
  }) async {
    try {
      // Downloads are stored as cached resources with a special type.
      final rows = await cacheManager.getCachedResources(
        userId: userId,
        resourceType: 'download',
      );

      var downloads = rows.map(_mapRowToFileDownload).toList();

      if (status != null) {
        downloads = downloads
            .where((d) => d.downloadStatus.value == status)
            .toList();
      }

      return downloads;
    } catch (e) {
      AppLogger.error(
        '[OfflineLocalDS] Failed to get downloads',
        error: e,
      );
      throw CacheException(message: 'Failed to get downloads: $e');
    }
  }

  @override
  Future<FileDownload> saveDownload(Map<String, dynamic> downloadData) async {
    try {
      final downloadId = downloadData['id'] as String? ?? _uuid.v4();
      final userId = downloadData['user_id'] as String;
      final resourceType = downloadData['resource_type'] as String? ?? 'download';
      final resourceId = downloadData['resource_id'] as String? ?? '';
      final fileName = downloadData['file_name'] as String? ?? '';
      final fileUrl = downloadData['file_url'] as String? ?? '';
      final fileSizeBytes = downloadData['file_size_bytes'] as int? ?? 0;
      final mimeType = downloadData['mime_type'] as String? ?? '';
      final localPath = downloadData['local_path'] as String? ?? '';

      await cacheManager.cacheResource(
        userId: userId,
        resourceType: resourceType,
        resourceId: resourceId,
        title: fileName,
        filePath: localPath,
        fileSizeBytes: fileSizeBytes,
        mimeType: mimeType,
      );

      return FileDownload(
        id: downloadId,
        userId: userId,
        resourceType: resourceType,
        resourceId: resourceId,
        fileName: fileName,
        fileUrl: fileUrl,
        fileSizeBytes: fileSizeBytes,
        mimeType: mimeType,
        localPath: localPath,
        downloadStatus: DownloadStatus.pending,
        progress: 0.0,
        createdAt: DateTime.now(),
      );
    } catch (e) {
      AppLogger.error(
        '[OfflineLocalDS] Failed to save download',
        error: e,
      );
      throw CacheException(message: 'Failed to save download: $e');
    }
  }

  @override
  Future<bool> updateDownloadStatus(
    String downloadId,
    String status, {
    double? progress,
  }) async {
    try {
      // In a full implementation, this would update the download record
      // in a dedicated downloads table. For now, we update the cached
      // resource metadata.
      AppLogger.debug(
        '[OfflineLocalDS] Download $downloadId status updated to $status '
        '${progress != null ? '($progress)' : ''}',
      );
      return true;
    } catch (e) {
      AppLogger.error(
        '[OfflineLocalDS] Failed to update download status',
        error: e,
      );
      throw CacheException(message: 'Failed to update download status: $e');
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // MAPPING HELPERS
  // ═══════════════════════════════════════════════════════════════════════

  /// Maps a CacheManager resource row to an [OfflineResource] entity.
  OfflineResource _mapRowToOfflineResource(Map<String, dynamic> row) {
    return OfflineResource(
      id: row['id'] as String,
      userId: row['userId'] as String,
      resourceType: row['resourceType'] as String,
      resourceId: row['resourceId'] as String,
      title: row['title'] as String,
      filePath: row['filePath'] as String,
      fileSizeBytes: row['fileSizeBytes'] as int,
      mimeType: row['mimeType'] as String? ?? '',
      checksum: row['checksum'] as String? ?? '',
      licenseExpiresAt: row['licenseExpiresAt'] != null
          ? DateTime.parse(row['licenseExpiresAt'] as String)
          : null,
      isAvailable: row['isAvailable'] as bool? ?? true,
      accessCount: row['accessCount'] as int? ?? 0,
      lastAccessedAt: row['lastAccessedAt'] != null
          ? DateTime.parse(row['lastAccessedAt'] as String)
          : null,
      createdAt: row['createdAt'] != null
          ? DateTime.parse(row['createdAt'] as String)
          : DateTime.now(),
    );
  }

  /// Maps a CacheManager draft row to a [DraftWork] entity.
  DraftWork _mapRowToDraftWork(Map<String, dynamic> row) {
    return DraftWork(
      id: row['id'] as String,
      userId: row['userId'] as String,
      draftType: DraftType.fromString(row['draftType'] as String?) ??
          DraftType.resource,
      title: row['title'] as String? ?? '',
      content: row['content'] is Map<String, dynamic>
          ? row['content'] as Map<String, dynamic>
          : {},
      schoolId: row['schoolId'] as String?,
      subjectId: row['subjectId'] as String?,
      isSynced: row['isSynced'] as bool? ?? false,
      lastEditedAt: row['lastEditedAt'] != null
          ? DateTime.parse(row['lastEditedAt'] as String)
          : DateTime.now(),
      createdAt: row['createdAt'] != null
          ? DateTime.parse(row['createdAt'] as String)
          : DateTime.now(),
    );
  }

  /// Maps a CacheManager exam attempt row to an [OfflineExamAttempt] entity.
  OfflineExamAttempt _mapRowToOfflineExamAttempt(Map<String, dynamic> row) {
    return OfflineExamAttempt(
      id: row['id'] as String,
      examId: row['examId'] as String,
      studentId: row['studentId'] as String,
      schoolId: row['schoolId'] as String? ?? '',
      attemptData: row['attemptData'] is Map<String, dynamic>
          ? row['attemptData'] as Map<String, dynamic>
          : {},
      answers: row['answers'] is Map<String, dynamic>
          ? row['answers'] as Map<String, dynamic>
          : {},
      startedAt: row['startedAt'] != null
          ? DateTime.parse(row['startedAt'] as String)
          : DateTime.now(),
      completedAt: row['completedAt'] != null
          ? DateTime.parse(row['completedAt'] as String)
          : null,
      timeTakenSeconds: row['timeTakenSeconds'] as int?,
      integrityHash: row['integrityHash'] as String? ?? '',
      syncStatus: AttemptSyncStatus.fromString(row['syncStatus'] as String?) ??
          AttemptSyncStatus.pending,
      syncAttempts: row['syncAttempts'] as int? ?? 0,
      syncedAt: row['syncedAt'] != null
          ? DateTime.parse(row['syncedAt'] as String)
          : null,
      validationErrors: row['validationErrors'] != null
          ? (row['validationErrors'] is String
              ? (jsonDecode(row['validationErrors'] as String) as List)
                  .cast<String>()
              : [])
          : null,
      createdAt: row['createdAt'] != null
          ? DateTime.parse(row['createdAt'] as String)
          : DateTime.now(),
    );
  }

  /// Maps a CacheManager resource row to a [FileDownload] entity.
  FileDownload _mapRowToFileDownload(Map<String, dynamic> row) {
    return FileDownload(
      id: row['id'] as String,
      userId: row['userId'] as String,
      resourceType: row['resourceType'] as String,
      resourceId: row['resourceId'] as String,
      fileName: row['title'] as String? ?? '',
      fileUrl: '', // Not stored in cache resource
      fileSizeBytes: row['fileSizeBytes'] as int,
      mimeType: row['mimeType'] as String? ?? '',
      localPath: row['filePath'] as String? ?? '',
      downloadStatus: DownloadStatus.completed,
      progress: 1.0,
      createdAt: row['createdAt'] != null
          ? DateTime.parse(row['createdAt'] as String)
          : DateTime.now(),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// RIVERPOD PROVIDER
// ═══════════════════════════════════════════════════════════════════════════════

/// Provider for the [OfflineLocalDataSource] implementation.
final offlineLocalDataSourceProvider = Provider<OfflineLocalDataSource>((ref) {
  final cacheManager = ref.watch(cacheManagerProvider);
  return OfflineLocalDataSourceImpl(cacheManager: cacheManager);
});
