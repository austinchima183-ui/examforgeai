import '../../../../core/utils/result.dart';
import '../entities/offline_entities.dart';
import '../../../../features/offline/domain/repositories/offline_repository.dart';


/// Abstract contract for the offline repository.
///
/// All offline, sync, connectivity, download, and device operations flow
/// through this interface, enabling Clean Architecture separation and
/// testability.
abstract class OfflineRepository {
  // ─── Sync Status ────────────────────────────────────────────────────────

  /// Get the current sync status for a user.
  Future<Result<SyncStatusInfo>> getSyncStatus(String userId);

  /// Trigger a manual sync for a user.
  Future<Result<bool>> triggerSync(String userId);

  // ─── Offline Resources ──────────────────────────────────────────────────

  /// Get all offline resources for a user, optionally filtered by type.
  Future<Result<List<OfflineResource>>> getOfflineResources(
    String userId, {
    String? resourceType,
  });

  /// Download a resource for offline access.
  Future<Result<bool>> downloadResourceForOffline(
    String userId,
    String resourceType,
    String resourceId,
  );

  /// Remove an offline resource from local storage.
  Future<Result<bool>> removeOfflineResource(String resourceId);

  /// Check whether a resource is available offline.
  Future<Result<bool>> isResourceAvailableOffline(
    String userId,
    String resourceId,
  );

  // ─── Offline Exams ──────────────────────────────────────────────────────

  /// Get offline exam configurations for a school.
  Future<Result<List<OfflineExamConfig>>> getOfflineExamConfigs(String schoolId);

  /// Update an offline exam configuration.
  Future<Result<OfflineExamConfig>> updateOfflineExamConfig(
    OfflineExamConfig config,
  );

  /// Save an offline exam attempt locally.
  Future<Result<OfflineExamAttempt>> saveOfflineExamAttempt(
    OfflineExamAttempt attempt,
  );

  /// Get all pending exam attempts for a student.
  Future<Result<List<OfflineExamAttempt>>> getPendingExamAttempts(
    String studentId,
  );

  /// Sync a single exam attempt to the server.
  Future<Result<bool>> syncExamAttempt(String attemptId);

  // ─── Drafts ─────────────────────────────────────────────────────────────

  /// Get all drafts for a user, optionally filtered by draft type.
  Future<Result<List<DraftWork>>> getDrafts(
    String userId, {
    String? draftType,
  });

  /// Save or update a draft.
  Future<Result<DraftWork>> saveDraft(DraftWork draft);

  /// Delete a draft by ID.
  Future<Result<bool>> deleteDraft(String draftId);

  // ─── Connectivity ───────────────────────────────────────────────────────

  /// Get the current connectivity information.
  Future<Result<ConnectivityInfo>> getConnectivityInfo();

  // ─── Device ─────────────────────────────────────────────────────────────

  /// Register a device for push notifications.
  Future<Result<DeviceRegistration>> registerDevice(
    DeviceRegistration device,
  );

  /// Unregister a device.
  Future<Result<bool>> unregisterDevice(String deviceId);

  /// Get all registered devices for a user.
  Future<Result<List<DeviceRegistration>>> getUserDevices(String userId);

  // ─── File Downloads ─────────────────────────────────────────────────────

  /// Start a file download for offline access.
  Future<Result<FileDownload>> startDownload(
    String userId,
    String resourceType,
    String resourceId,
    String fileUrl,
    String fileName,
  );

  /// Get all downloads for a user, optionally filtered by status.
  Future<Result<List<FileDownload>>> getDownloads(
    String userId, {
    String? status,
  });

  /// Cancel an active download.
  Future<Result<bool>> cancelDownload(String downloadId);

  /// Retry a failed download.
  Future<Result<bool>> retryDownload(String downloadId);

  // ─── Analytics ──────────────────────────────────────────────────────────

  /// Log an app usage event for analytics.
  Future<Result<bool>> logUsageEvent(AppUsageEvent event);

  /// Sync all pending analytics events for a user.
  Future<Result<bool>> syncAnalyticsEvents(String userId);
}
