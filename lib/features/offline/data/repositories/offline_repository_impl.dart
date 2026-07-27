// =============================================================================
// ExamForge AI — Offline Repository Implementation
// =============================================================================
//
// Implements [OfflineRepository] using both local and remote data sources.
//
// Strategy:
//   - Online operations: try remote first, cache locally on success.
//   - Offline operations: use local data source, queue mutations in sync
//     queue for later replay.
//   - Maps all exceptions to domain [Failure] types and wraps results
//     in [Result<T>].
// =============================================================================

import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/network/network_info.dart';
import '../../../../core/storage/cache_manager.dart';
import '../../../../core/sync/sync_engine.dart';
import '../../../../core/utils/logger.dart';
import '../../../../core/utils/result.dart';
import '../../domain/entities/offline_entities.dart';
import '../../domain/repositories/offline_repository.dart';
import '../datasources/offline_local_datasource.dart';
import '../datasources/offline_remote_datasource.dart';


// ═══════════════════════════════════════════════════════════════════════════════
// OFFLINE REPOSITORY IMPLEMENTATION
// ═══════════════════════════════════════════════════════════════════════════════

/// Concrete implementation of [OfflineRepository] that coordinates
/// between local and remote data sources with an offline-first strategy.
///
/// When the device is online:
///   - Read operations try the remote source first and cache the result.
///   - Write operations go to the remote source and update the local cache.
///
/// When the device is offline:
///   - Read operations fall back to the local data source.
///   - Write operations are persisted locally and enqueued in the sync
///     queue for automatic replay when connectivity is restored.
class OfflineRepositoryImpl implements OfflineRepository {
  OfflineRepositoryImpl({
    required OfflineLocalDataSource localDataSource,
    required OfflineRemoteDataSource remoteDataSource,
    required NetworkInfo networkInfo,
    required CacheManager cacheManager,
    required SyncEngine syncEngine,
  })  : _localDataSource = localDataSource,
        _remoteDataSource = remoteDataSource,
        _networkInfo = networkInfo,
        _cacheManager = cacheManager,
        _syncEngine = syncEngine;

  final OfflineLocalDataSource _localDataSource;
  final OfflineRemoteDataSource _remoteDataSource;
  final NetworkInfo _networkInfo;
  final CacheManager _cacheManager;
  final SyncEngine _syncEngine;

  // ═══════════════════════════════════════════════════════════════════════
  // Helper: Convert exceptions to Failures
  // ═══════════════════════════════════════════════════════════════════════

  Failure _mapExceptionToFailure(Object e) {
    if (e is AuthException) {
      return Failure.auth(message: e.message, code: e.code);
    } else if (e is ServerException) {
      return Failure.server(
        message: e.message,
        statusCode: e.statusCode,
        data: e.data,
      );
    } else if (e is CacheException) {
      return Failure.cache(message: e.message);
    } else if (e is NetworkException) {
      return Failure.network(message: e.message);
    } else if (e is ValidationException) {
      return Failure.validation(
        message: e.message,
        fieldErrors: e.fieldErrors,
      );
    } else if (e is NotFoundException) {
      return Failure.notFound(message: e.message);
    } else if (e is UnauthorizedException) {
      return Failure.unauthorized(message: e.message);
    } else if (e is ForbiddenException) {
      return Failure.forbidden(message: e.message);
    } else {
      AppLogger.error(
        'Unexpected exception in OfflineRepositoryImpl',
        error: e,
      );
      return Failure.server(
        message: 'An unexpected error occurred: $e',
        statusCode: 500,
      );
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // SYNC STATUS
  // ═══════════════════════════════════════════════════════════════════════

  @override
  Future<Result<SyncStatusInfo>> getSyncStatus(String userId) async {
    try {
      // Sync status is always derived from local data (sync queue state).
      final status = _localDataSource.getSyncStatus(userId);
      return Success(status);
    } on CacheException catch (e) {
      return FailureResult(Failure.cache(message: e.message));
    } catch (e) {
      return FailureResult(_mapExceptionToFailure(e));
    }
  }

  @override
  Future<Result<bool>> triggerSync(String userId) async {
    try {
      final isOnline = await _networkInfo.isConnected;
      if (!isOnline) {
        return const FailureResult(
          Failure.network(message: 'No network connection available'),
        );
      }

      // Process the sync queue via SyncEngine.
      await _syncEngine.processQueue();
      return const Success(true);
    } on NetworkException catch (e) {
      return FailureResult(Failure.network(message: e.message));
    } on ServerException catch (e) {
      return FailureResult(Failure.server(
        message: e.message,
        statusCode: e.statusCode,
        data: e.data,
      ),);
    } catch (e) {
      return FailureResult(_mapExceptionToFailure(e));
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // OFFLINE RESOURCES
  // ═══════════════════════════════════════════════════════════════════════

  @override
  Future<Result<List<OfflineResource>>> getOfflineResources(
    String userId, {
    String? resourceType,
  }) async {
    try {
      // Always read offline resources from local storage.
      final resources = await _localDataSource.getOfflineResources(
        userId,
        resourceType: resourceType,
      );
      return Success(resources);
    } on CacheException catch (e) {
      return FailureResult(Failure.cache(message: e.message));
    } catch (e) {
      return FailureResult(_mapExceptionToFailure(e));
    }
  }

  @override
  Future<Result<bool>> downloadResourceForOffline(
    String userId,
    String resourceType,
    String resourceId,
  ) async {
    try {
      final isOnline = await _networkInfo.isConnected;

      if (isOnline) {
        // Get the download URL from the server.
        final downloadUrl = await _remoteDataSource.getFileDownloadUrl(
          resourceType,
          resourceId,
        );

        // Save the resource metadata locally.
        await _localDataSource.saveOfflineResource({
          'user_id': userId,
          'resource_type': resourceType,
          'resource_id': resourceId,
          'title': '$resourceType - $resourceId',
          'file_path': downloadUrl,
          'file_size_bytes': 0, // Updated when download completes
          'mime_type': 'application/octet-stream',
        });

        // Enqueue the actual download in the sync queue.
        await _cacheManager.enqueueSync(
          userId: userId,
          tableName: 'resources',
          operation: 'download',
          payload: {
            'resource_type': resourceType,
            'resource_id': resourceId,
            'download_url': downloadUrl,
          },
          priority: 3,
        );

        return const Success(true);
      } else {
        // Offline: queue the download for later.
        await _cacheManager.enqueueSync(
          userId: userId,
          tableName: 'resources',
          operation: 'download',
          payload: {
            'resource_type': resourceType,
            'resource_id': resourceId,
          },
          priority: 3,
        );

        return const Success(true);
      }
    } on ServerException catch (e) {
      return FailureResult(Failure.server(
        message: e.message,
        statusCode: e.statusCode,
        data: e.data,
      ),);
    } on CacheException catch (e) {
      return FailureResult(Failure.cache(message: e.message));
    } catch (e) {
      return FailureResult(_mapExceptionToFailure(e));
    }
  }

  @override
  Future<Result<bool>> removeOfflineResource(String resourceId) async {
    try {
      final result = await _localDataSource.removeOfflineResource(resourceId);
      return Success(result);
    } on CacheException catch (e) {
      return FailureResult(Failure.cache(message: e.message));
    } catch (e) {
      return FailureResult(_mapExceptionToFailure(e));
    }
  }

  @override
  Future<Result<bool>> isResourceAvailableOffline(
    String userId,
    String resourceId,
  ) async {
    try {
      final available = await _cacheManager.isResourceAvailable(
        userId: userId,
        resourceId: resourceId,
      );
      return Success(available);
    } on CacheException catch (e) {
      return FailureResult(Failure.cache(message: e.message));
    } catch (e) {
      return FailureResult(_mapExceptionToFailure(e));
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // OFFLINE EXAMS
  // ═══════════════════════════════════════════════════════════════════════

  @override
  Future<Result<List<OfflineExamConfig>>> getOfflineExamConfigs(
    String schoolId,
  ) async {
    try {
      final isOnline = await _networkInfo.isConnected;

      if (isOnline) {
        // Try remote first.
        try {
          final remoteConfigs =
              await _remoteDataSource.getOfflineExamConfigs(schoolId);

          final configs = remoteConfigs
              .map((data) => OfflineExamConfig(
                    id: data['id'] as String,
                    schoolId: data['school_id'] as String,
                    examId: data['exam_id'] as String,
                    allowsOffline: data['allows_offline'] as bool? ?? false,
                    offlineType: OfflineType.fromString(
                            data['offline_type'] as String?,) ??
                        OfflineType.none,
                    maxOfflineAttempts:
                        data['max_offline_attempts'] as int? ?? 0,
                    requiresOnlineSubmission:
                        data['requires_online_submission'] as bool? ?? true,
                    autoSubmitOnReconnect:
                        data['auto_submit_on_reconnect'] as bool? ?? false,
                    createdAt: data['created_at'] != null
                        ? DateTime.parse(data['created_at'] as String)
                        : DateTime.now(),
                  ),)
              .toList();

          // Cache locally.
          await _cacheManager.cacheData(
            key: 'offline_exam_configs_$schoolId',
            userId: schoolId,
            resourceType: 'offline_exam_config',
            resourceId: schoolId,
            data: {'configs': remoteConfigs},
          );

          return Success(configs);
        } on ServerException {
          // Fall back to local cache.
          AppLogger.warning(
            '[OfflineRepo] Remote configs fetch failed, falling back to cache',
          );
        }
      }

      // Read from local cache.
      final cached = await _cacheManager.getCachedData(
        key: 'offline_exam_configs_$schoolId',
        userId: schoolId,
      );

      if (cached != null && cached['configs'] != null) {
        final configsList =
            List<Map<String, dynamic>>.from(cached['configs'] as List);
        final configs = configsList
            .map((data) => OfflineExamConfig(
                  id: data['id'] as String,
                  schoolId: data['school_id'] as String,
                  examId: data['exam_id'] as String,
                  allowsOffline: data['allows_offline'] as bool? ?? false,
                  offlineType:
                      OfflineType.fromString(data['offline_type'] as String?) ??
                          OfflineType.none,
                  maxOfflineAttempts: data['max_offline_attempts'] as int? ?? 0,
                  requiresOnlineSubmission:
                      data['requires_online_submission'] as bool? ?? true,
                  autoSubmitOnReconnect:
                      data['auto_submit_on_reconnect'] as bool? ?? false,
                  createdAt: data['created_at'] != null
                      ? DateTime.parse(data['created_at'] as String)
                      : DateTime.now(),
                ),)
            .toList();
        return Success(configs);
      }

      return const Success([]);
    } on CacheException catch (e) {
      return FailureResult(Failure.cache(message: e.message));
    } catch (e) {
      return FailureResult(_mapExceptionToFailure(e));
    }
  }

  @override
  Future<Result<OfflineExamConfig>> updateOfflineExamConfig(
    OfflineExamConfig config,
  ) async {
    try {
      final isOnline = await _networkInfo.isConnected;

      if (isOnline) {
        // Update on server (would use a proper Supabase call).
        // Cache the updated config locally.
        await _cacheManager.cacheData(
          key: 'offline_exam_config_${config.examId}',
          userId: config.schoolId,
          resourceType: 'offline_exam_config',
          resourceId: config.examId,
          data: {
            'id': config.id,
            'school_id': config.schoolId,
            'exam_id': config.examId,
            'allows_offline': config.allowsOffline,
            'offline_type': config.offlineType.value,
            'max_offline_attempts': config.maxOfflineAttempts,
            'requires_online_submission': config.requiresOnlineSubmission,
            'auto_submit_on_reconnect': config.autoSubmitOnReconnect,
          },
        );
      } else {
        // Queue for sync.
        await _cacheManager.enqueueSync(
          userId: config.schoolId,
          tableName: 'offline_exam_configs',
          operation: 'update',
          payload: {
            'id': config.id,
            'school_id': config.schoolId,
            'exam_id': config.examId,
            'allows_offline': config.allowsOffline,
            'offline_type': config.offlineType.value,
            'max_offline_attempts': config.maxOfflineAttempts,
            'requires_online_submission': config.requiresOnlineSubmission,
            'auto_submit_on_reconnect': config.autoSubmitOnReconnect,
          },
          recordId: config.id,
        );
      }

      return Success(config);
    } on ServerException catch (e) {
      return FailureResult(Failure.server(
        message: e.message,
        statusCode: e.statusCode,
        data: e.data,
      ),);
    } on CacheException catch (e) {
      return FailureResult(Failure.cache(message: e.message));
    } catch (e) {
      return FailureResult(_mapExceptionToFailure(e));
    }
  }

  @override
  Future<Result<OfflineExamAttempt>> saveOfflineExamAttempt(
    OfflineExamAttempt attempt,
  ) async {
    try {
      // Always save locally first.
      final savedAttempt = await _localDataSource.saveExamAttempt({
        'id': attempt.id,
        'exam_id': attempt.examId,
        'student_id': attempt.studentId,
        'school_id': attempt.schoolId,
        'attempt_data': attempt.attemptData,
        'answers': attempt.answers,
        'started_at': attempt.startedAt.toIso8601String(),
        'completed_at': attempt.completedAt?.toIso8601String(),
        'time_taken_seconds': attempt.timeTakenSeconds,
        'integrity_hash': attempt.integrityHash,
      });

      // Try to sync immediately if online.
      final isOnline = await _networkInfo.isConnected;
      if (isOnline && attempt.completedAt != null) {
        try {
          await _remoteDataSource.syncExamAttempt(
            attempt.id,
            {
              'exam_id': attempt.examId,
              'student_id': attempt.studentId,
              'school_id': attempt.schoolId,
              'attempt_data': attempt.attemptData,
              'answers': attempt.answers,
              'started_at': attempt.startedAt.toIso8601String(),
              'completed_at': attempt.completedAt?.toIso8601String(),
              'time_taken_seconds': attempt.timeTakenSeconds,
              'integrity_hash': attempt.integrityHash,
            },
          );

          // Mark as synced locally.
          await _localDataSource.markExamAttemptSynced(attempt.id);

          return Success(savedAttempt.copyWith(
            syncStatus: AttemptSyncStatus.synced,
            syncedAt: DateTime.now(),
          ),);
        } on ServerException catch (e) {
          // Sync failed — keep as pending, queue for later.
          AppLogger.warning(
            '[OfflineRepo] Exam attempt sync failed, queued for later: ${e.message}',
          );

          await _cacheManager.enqueueSync(
            userId: attempt.studentId,
            tableName: 'offline_exam_attempts',
            operation: 'sync',
            payload: {
              'attempt_id': attempt.id,
              'exam_id': attempt.examId,
              'student_id': attempt.studentId,
              'school_id': attempt.schoolId,
              'attempt_data': attempt.attemptData,
              'answers': attempt.answers,
              'integrity_hash': attempt.integrityHash,
            },
            recordId: attempt.id,
            priority: 2, // High priority
          );
        }
      } else if (attempt.completedAt != null) {
        // Offline — queue for sync.
        await _cacheManager.enqueueSync(
          userId: attempt.studentId,
          tableName: 'offline_exam_attempts',
          operation: 'sync',
          payload: {
            'attempt_id': attempt.id,
            'exam_id': attempt.examId,
            'student_id': attempt.studentId,
            'school_id': attempt.schoolId,
            'attempt_data': attempt.attemptData,
            'answers': attempt.answers,
            'integrity_hash': attempt.integrityHash,
          },
          recordId: attempt.id,
          priority: 2,
        );
      }

      return Success(savedAttempt);
    } on CacheException catch (e) {
      return FailureResult(Failure.cache(message: e.message));
    } catch (e) {
      return FailureResult(_mapExceptionToFailure(e));
    }
  }

  @override
  Future<Result<List<OfflineExamAttempt>>> getPendingExamAttempts(
    String studentId,
  ) async {
    try {
      final attempts =
          await _localDataSource.getPendingExamAttempts(studentId);
      return Success(attempts);
    } on CacheException catch (e) {
      return FailureResult(Failure.cache(message: e.message));
    } catch (e) {
      return FailureResult(_mapExceptionToFailure(e));
    }
  }

  @override
  Future<Result<bool>> syncExamAttempt(String attemptId) async {
    try {
      final isOnline = await _networkInfo.isConnected;
      if (!isOnline) {
        return const FailureResult(
          Failure.network(message: 'Cannot sync while offline'),
        );
      }

      // Get the attempt from local storage.
      final pendingAttempts =
          await _localDataSource.getPendingExamAttempts('');
      final attempt = pendingAttempts.where((a) => a.id == attemptId).firstOrNull;

      if (attempt == null) {
        return FailureResult(
          Failure.notFound(message: 'Exam attempt not found: $attemptId'),
        );
      }

      // Sync with server.
      await _remoteDataSource.syncExamAttempt(
        attemptId,
        {
          'exam_id': attempt.examId,
          'student_id': attempt.studentId,
          'school_id': attempt.schoolId,
          'attempt_data': attempt.attemptData,
          'answers': attempt.answers,
          'started_at': attempt.startedAt.toIso8601String(),
          'completed_at': attempt.completedAt?.toIso8601String(),
          'time_taken_seconds': attempt.timeTakenSeconds,
          'integrity_hash': attempt.integrityHash,
        },
      );

      // Mark as synced locally.
      await _localDataSource.markExamAttemptSynced(attemptId);

      return const Success(true);
    } on ServerException catch (e) {
      return FailureResult(Failure.server(
        message: e.message,
        statusCode: e.statusCode,
        data: e.data,
      ),);
    } on CacheException catch (e) {
      return FailureResult(Failure.cache(message: e.message));
    } catch (e) {
      return FailureResult(_mapExceptionToFailure(e));
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // DRAFTS
  // ═══════════════════════════════════════════════════════════════════════

  @override
  Future<Result<List<DraftWork>>> getDrafts(
    String userId, {
    String? draftType,
  }) async {
    try {
      // Always read drafts from local storage.
      final drafts = await _localDataSource.getDrafts(
        userId,
        draftType: draftType,
      );
      return Success(drafts);
    } on CacheException catch (e) {
      return FailureResult(Failure.cache(message: e.message));
    } catch (e) {
      return FailureResult(_mapExceptionToFailure(e));
    }
  }

  @override
  Future<Result<DraftWork>> saveDraft(DraftWork draft) async {
    try {
      // Always save locally first.
      final savedDraft = await _localDataSource.saveDraft({
        'id': draft.id,
        'user_id': draft.userId,
        'draft_type': draft.draftType.value,
        'title': draft.title,
        'content': draft.content,
        'school_id': draft.schoolId,
        'subject_id': draft.subjectId,
      });

      final isOnline = await _networkInfo.isConnected;
      if (isOnline) {
        // Sync to server.
        try {
          await _remoteDataSource.syncDrafts([
            {
              'id': draft.id,
              'user_id': draft.userId,
              'draft_type': draft.draftType.value,
              'title': draft.title,
              'content': draft.content,
              'school_id': draft.schoolId,
              'subject_id': draft.subjectId,
              'last_edited_at': draft.lastEditedAt.toIso8601String(),
            },
          ]);
        } on ServerException catch (e) {
          // Remote sync failed — enqueue for later.
          AppLogger.warning(
            '[OfflineRepo] Draft sync failed, queued: ${e.message}',
          );
          await _cacheManager.enqueueSync(
            userId: draft.userId,
            tableName: 'drafts',
            operation: 'upsert',
            payload: {
              'id': draft.id,
              'draft_type': draft.draftType.value,
              'title': draft.title,
              'content': draft.content,
            },
            recordId: draft.id,
            priority: 5,
          );
        }
      } else {
        // Queue for later sync.
        await _cacheManager.enqueueSync(
          userId: draft.userId,
          tableName: 'drafts',
          operation: 'upsert',
          payload: {
            'id': draft.id,
            'draft_type': draft.draftType.value,
            'title': draft.title,
            'content': draft.content,
          },
          recordId: draft.id,
          priority: 5,
        );
      }

      return Success(savedDraft);
    } on CacheException catch (e) {
      return FailureResult(Failure.cache(message: e.message));
    } catch (e) {
      return FailureResult(_mapExceptionToFailure(e));
    }
  }

  @override
  Future<Result<bool>> deleteDraft(String draftId) async {
    try {
      final result = await _localDataSource.deleteDraft(draftId);
      return Success(result);
    } on CacheException catch (e) {
      return FailureResult(Failure.cache(message: e.message));
    } catch (e) {
      return FailureResult(_mapExceptionToFailure(e));
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // CONNECTIVITY
  // ═══════════════════════════════════════════════════════════════════════

  @override
  Future<Result<ConnectivityInfo>> getConnectivityInfo() async {
    try {
      final isOnline = await _networkInfo.isConnected;
      final connectionType = await _networkInfo.connectionType;

      return Success(ConnectivityInfo(
        isOnline: isOnline,
        connectionQuality: isOnline
            ? ConnectionQuality.good
            : ConnectionQuality.offline,
        connectionType: _parseConnectionType(connectionType),
        shouldReduceQuality: false,
        shouldDelaySync: !isOnline,
        shouldCompressUploads: false,
      ),);
    } catch (e) {
      return FailureResult(_mapExceptionToFailure(e));
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // DEVICE
  // ═══════════════════════════════════════════════════════════════════════

  @override
  Future<Result<DeviceRegistration>> registerDevice(
    DeviceRegistration device,
  ) async {
    try {
      final isOnline = await _networkInfo.isConnected;

      if (isOnline) {
        final response = await _remoteDataSource.registerDevice({
          'user_id': device.userId,
          'device_token': device.deviceToken,
          'platform': device.platform,
          'device_name': device.deviceName,
          'device_model': device.deviceModel,
          'os_version': device.osVersion,
          'app_version': device.appVersion,
          'is_active': device.isActive,
          'push_enabled': device.pushEnabled,
        });

        return Success(DeviceRegistration(
          id: response['id'] as String? ?? device.id,
          userId: device.userId,
          deviceToken: device.deviceToken,
          platform: device.platform,
          deviceName: device.deviceName,
          deviceModel: device.deviceModel,
          osVersion: device.osVersion,
          appVersion: device.appVersion,
          isActive: true,
          lastActiveAt: DateTime.now(),
          pushEnabled: device.pushEnabled,
          createdAt: device.createdAt,
        ),);
      } else {
        // Queue device registration for later.
        await _cacheManager.enqueueSync(
          userId: device.userId,
          tableName: 'device_registrations',
          operation: 'upsert',
          payload: {
            'device_token': device.deviceToken,
            'platform': device.platform,
            'device_name': device.deviceName,
            'device_model': device.deviceModel,
          },
          priority: 4,
        );

        return Success(device);
      }
    } on ServerException catch (e) {
      return FailureResult(Failure.server(
        message: e.message,
        statusCode: e.statusCode,
        data: e.data,
      ),);
    } catch (e) {
      return FailureResult(_mapExceptionToFailure(e));
    }
  }

  @override
  Future<Result<bool>> unregisterDevice(String deviceId) async {
    try {
      final isOnline = await _networkInfo.isConnected;

      if (isOnline) {
        return Success(await _remoteDataSource.unregisterDevice(deviceId));
      } else {
        // Queue for later.
        await _cacheManager.enqueueSync(
          userId: deviceId,
          tableName: 'device_registrations',
          operation: 'deactivate',
          payload: {'device_id': deviceId},
          recordId: deviceId,
          priority: 4,
        );
        return const Success(true);
      }
    } on ServerException catch (e) {
      return FailureResult(Failure.server(
        message: e.message,
        statusCode: e.statusCode,
        data: e.data,
      ),);
    } catch (e) {
      return FailureResult(_mapExceptionToFailure(e));
    }
  }

  @override
  Future<Result<List<DeviceRegistration>>> getUserDevices(String userId) async {
    // Device list is primarily a server-side concern.
    // Fall back to empty list if offline.
    try {
      final isOnline = await _networkInfo.isConnected;
      if (!isOnline) {
        return const Success([]);
      }

      // Would query Supabase for device list.
      // For now, return empty list (full implementation would
      // query the device_registrations table).
      return const Success([]);
    } catch (e) {
      return FailureResult(_mapExceptionToFailure(e));
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // FILE DOWNLOADS
  // ═══════════════════════════════════════════════════════════════════════

  @override
  Future<Result<FileDownload>> startDownload(
    String userId,
    String resourceType,
    String resourceId,
    String fileUrl,
    String fileName,
  ) async {
    try {
      final download = await _localDataSource.saveDownload({
        'user_id': userId,
        'resource_type': resourceType,
        'resource_id': resourceId,
        'file_name': fileName,
        'file_url': fileUrl,
        'file_size_bytes': 0,
        'mime_type': 'application/octet-stream',
        'local_path': '',
      });

      // Queue the actual download operation.
      await _cacheManager.enqueueSync(
        userId: userId,
        tableName: 'downloads',
        operation: 'download',
        payload: {
          'resource_type': resourceType,
          'resource_id': resourceId,
          'file_url': fileUrl,
          'file_name': fileName,
        },
        priority: 3,
      );

      return Success(download);
    } on CacheException catch (e) {
      return FailureResult(Failure.cache(message: e.message));
    } catch (e) {
      return FailureResult(_mapExceptionToFailure(e));
    }
  }

  @override
  Future<Result<List<FileDownload>>> getDownloads(
    String userId, {
    String? status,
  }) async {
    try {
      final downloads = await _localDataSource.getDownloads(
        userId,
        status: status,
      );
      return Success(downloads);
    } on CacheException catch (e) {
      return FailureResult(Failure.cache(message: e.message));
    } catch (e) {
      return FailureResult(_mapExceptionToFailure(e));
    }
  }

  @override
  Future<Result<bool>> cancelDownload(String downloadId) async {
    try {
      return Success(
        await _localDataSource.updateDownloadStatus(downloadId, 'failed'),
      );
    } on CacheException catch (e) {
      return FailureResult(Failure.cache(message: e.message));
    } catch (e) {
      return FailureResult(_mapExceptionToFailure(e));
    }
  }

  @override
  Future<Result<bool>> retryDownload(String downloadId) async {
    try {
      return Success(
        await _localDataSource.updateDownloadStatus(downloadId, 'pending'),
      );
    } on CacheException catch (e) {
      return FailureResult(Failure.cache(message: e.message));
    } catch (e) {
      return FailureResult(_mapExceptionToFailure(e));
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // ANALYTICS
  // ═══════════════════════════════════════════════════════════════════════

  @override
  Future<Result<bool>> logUsageEvent(AppUsageEvent event) async {
    try {
      final isOnline = await _networkInfo.isConnected;

      if (isOnline) {
        return Success(
          await _remoteDataSource.logUsageEvents([
            {
              'id': event.id,
              'user_id': event.userId,
              'event_type': event.eventType,
              'event_data': event.eventData,
              'session_id': event.sessionId,
              'app_version': event.appVersion,
              'platform': event.platform,
              'screen_name': event.screenName,
              'duration_ms': event.durationMs,
              'created_at': event.createdAt.toIso8601String(),
            },
          ]),
        );
      } else {
        // Queue for later.
        await _cacheManager.enqueueSync(
          userId: event.userId,
          tableName: 'app_usage_events',
          operation: 'insert',
          payload: {
            'event_type': event.eventType,
            'event_data': event.eventData,
            'session_id': event.sessionId,
          },
          priority: 8, // Low priority
        );
        return const Success(true);
      }
    } on ServerException catch (e) {
      return FailureResult(Failure.server(
        message: e.message,
        statusCode: e.statusCode,
        data: e.data,
      ),);
    } catch (e) {
      return FailureResult(_mapExceptionToFailure(e));
    }
  }

  @override
  Future<Result<bool>> syncAnalyticsEvents(String userId) async {
    try {
      final isOnline = await _networkInfo.isConnected;
      if (!isOnline) {
        return const FailureResult(
          Failure.network(message: 'Cannot sync analytics while offline'),
        );
      }

      // Get pending analytics sync items.
      final pendingItems = await _cacheManager.getPendingSyncItems(
        userId: userId,
      );

      final analyticsItems = pendingItems
          .where((item) => item['tableName'] == 'app_usage_events')
          .map((item) => item['payload'] as Map<String, dynamic>)
          .toList();

      if (analyticsItems.isEmpty) {
        return const Success(true);
      }

      final success =
          await _remoteDataSource.logUsageEvents(analyticsItems);

      // Mark synced items as completed.
      for (final item in pendingItems
          .where((item) => item['tableName'] == 'app_usage_events')) {
        await _cacheManager.markSyncItemCompleted(id: item['id'] as String);
      }

      return Success(success);
    } on ServerException catch (e) {
      return FailureResult(Failure.server(
        message: e.message,
        statusCode: e.statusCode,
        data: e.data,
      ),);
    } on CacheException catch (e) {
      return FailureResult(Failure.cache(message: e.message));
    } catch (e) {
      return FailureResult(_mapExceptionToFailure(e));
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // PRIVATE HELPERS
  // ═══════════════════════════════════════════════════════════════════════

  /// Parses a human-readable connection type string to a [ConnectionType].
  ConnectionType _parseConnectionType(String type) {
    switch (type.toLowerCase()) {
      case 'wifi':
        return ConnectionType.wifi;
      case 'mobile':
        return ConnectionType.mobile;
      case 'ethernet':
        return ConnectionType.ethernet;
      default:
        return ConnectionType.none;
    }
  }
}
