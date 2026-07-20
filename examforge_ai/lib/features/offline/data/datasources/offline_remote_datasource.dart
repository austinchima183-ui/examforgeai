// =============================================================================
// ExamForge AI — Offline Remote Data Source
// =============================================================================
//
// Abstract interface and concrete implementation for all remote (Supabase)
// sync operations related to the offline module. This includes:
//   - Device registration / unregistration
//   - Exam attempt syncing
//   - Draft syncing
//   - File download URL generation
//   - Connectivity event reporting
//   - Usage event logging
//   - Offline exam configuration fetching
//
// Throws [ServerException] on any server-side failure.
// =============================================================================

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;

import '../../../../core/errors/exceptions.dart';
import '../../../../core/utils/logger.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// ABSTRACT INTERFACE
// ═══════════════════════════════════════════════════════════════════════════════

/// Abstract contract for all remote (sync) data operations.
///
/// Every method communicates with the Supabase backend. Implementations
/// must throw [ServerException] on any server-side failure.
abstract class OfflineRemoteDataSource {
  /// Registers a device for push notifications and session tracking.
  ///
  /// Returns the created device record as a Map.
  Future<Map<String, dynamic>> registerDevice(Map<String, dynamic> deviceData);

  /// Unregisters a device by [deviceId].
  ///
  /// Returns `true` on success.
  Future<bool> unregisterDevice(String deviceId);

  /// Syncs a single exam attempt to the server.
  ///
  /// [attemptId] is the local attempt ID. [attemptData] contains the
  /// full attempt payload including answers and integrity data.
  ///
  /// Returns the server's response (including the server-side attempt ID
  /// and validation results).
  Future<Map<String, dynamic>> syncExamAttempt(
    String attemptId,
    Map<String, dynamic> attemptData,
  );

  /// Syncs a batch of drafts to the server.
  ///
  /// Returns a list of server responses for each draft.
  Future<List<Map<String, dynamic>>> syncDrafts(
    List<Map<String, dynamic>> drafts,
  );

  /// Gets a signed download URL for a resource.
  ///
  /// [resourceType] is the type of resource (e.g. 'exam', 'resource').
  /// [resourceId] is the ID of the resource.
  ///
  /// Returns the signed URL string.
  Future<String> getFileDownloadUrl(
    String resourceType,
    String resourceId,
  );

  /// Reports a connectivity event to the server for analytics.
  ///
  /// Returns `true` on success.
  Future<bool> reportConnectivityEvent(Map<String, dynamic> eventData);

  /// Logs usage events to the server for analytics.
  ///
  /// Returns `true` on success.
  Future<bool> logUsageEvents(List<Map<String, dynamic>> events);

  /// Gets offline exam configurations for a school.
  ///
  /// Returns a list of configuration maps.
  Future<List<Map<String, dynamic>>> getOfflineExamConfigs(String schoolId);
}

// ═══════════════════════════════════════════════════════════════════════════════
// IMPLEMENTATION
// ═══════════════════════════════════════════════════════════════════════════════

/// Concrete implementation of [OfflineRemoteDataSource] that communicates
/// with the Supabase backend.
class OfflineRemoteDataSourceImpl implements OfflineRemoteDataSource {
  OfflineRemoteDataSourceImpl({required this.supabaseClient});

  final sb.SupabaseClient supabaseClient;

  // ─── Table Names ──────────────────────────────────────────────────────

  static const _deviceTable = 'device_registrations';
  static const _examAttemptTable = 'offline_exam_attempts';
  static const _draftsTable = 'draft_work';
  static const _connectivityTable = 'connectivity_events';
  static const _usageEventsTable = 'app_usage_events';
  static const _offlineExamConfigTable = 'offline_exam_configs';

  // ═══════════════════════════════════════════════════════════════════════
  // DEVICE REGISTRATION
  // ═══════════════════════════════════════════════════════════════════════

  @override
  Future<Map<String, dynamic>> registerDevice(
    Map<String, dynamic> deviceData,
  ) async {
    try {
      final response = await supabaseClient
          .from(_deviceTable)
          .upsert(deviceData, onConflict: 'user_id,device_token')
          .select()
          .single();

      AppLogger.info('[OfflineRemoteDS] Device registered: ${response['id']}');
      return response;
    } on sb.PostgrestException catch (e) {
      AppLogger.error(
        '[OfflineRemoteDS] Failed to register device',
        error: e,
      );
      throw ServerException(
        message: e.message,
        statusCode: int.tryParse(e.code ?? '') ?? 500,
        data: e.details,
      );
    } catch (e) {
      AppLogger.error(
        '[OfflineRemoteDS] Unexpected error registering device',
        error: e,
      );
      throw ServerException(
        message: 'Failed to register device: $e',
        statusCode: 500,
      );
    }
  }

  @override
  Future<bool> unregisterDevice(String deviceId) async {
    try {
      await supabaseClient
          .from(_deviceTable)
          .update({'is_active': false, 'updated_at': DateTime.now().toIso8601String()})
          .eq('id', deviceId);

      AppLogger.info('[OfflineRemoteDS] Device unregistered: $deviceId');
      return true;
    } on sb.PostgrestException catch (e) {
      AppLogger.error(
        '[OfflineRemoteDS] Failed to unregister device',
        error: e,
      );
      throw ServerException(
        message: e.message,
        statusCode: int.tryParse(e.code ?? '') ?? 500,
        data: e.details,
      );
    } catch (e) {
      AppLogger.error(
        '[OfflineRemoteDS] Unexpected error unregistering device',
        error: e,
      );
      throw ServerException(
        message: 'Failed to unregister device: $e',
        statusCode: 500,
      );
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // EXAM ATTEMPT SYNC
  // ═══════════════════════════════════════════════════════════════════════

  @override
  Future<Map<String, dynamic>> syncExamAttempt(
    String attemptId,
    Map<String, dynamic> attemptData,
  ) async {
    try {
      // Use the RPC function for atomic attempt syncing.
      final response = await supabaseClient.rpc(
        'sync_offline_exam_attempt',
        params: {
          'p_local_attempt_id': attemptId,
          'p_attempt_data': attemptData,
        },
      );

      AppLogger.info(
        '[OfflineRemoteDS] Exam attempt synced: $attemptId',
      );
      return response as Map<String, dynamic>;
    } on sb.PostgrestException catch (e) {
      AppLogger.error(
        '[OfflineRemoteDS] Failed to sync exam attempt',
        error: e,
      );
      throw ServerException(
        message: e.message,
        statusCode: int.tryParse(e.code ?? '') ?? 500,
        data: e.details,
      );
    } catch (e) {
      AppLogger.error(
        '[OfflineRemoteDS] Unexpected error syncing exam attempt',
        error: e,
      );
      throw ServerException(
        message: 'Failed to sync exam attempt: $e',
        statusCode: 500,
      );
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // DRAFT SYNC
  // ═══════════════════════════════════════════════════════════════════════

  @override
  Future<List<Map<String, dynamic>>> syncDrafts(
    List<Map<String, dynamic>> drafts,
  ) async {
    try {
      final results = <Map<String, dynamic>>[];

      for (final draft in drafts) {
        final response = await supabaseClient
            .from(_draftsTable)
            .upsert(draft, onConflict: 'id')
            .select()
            .single();
        results.add(response);
      }

      AppLogger.info(
        '[OfflineRemoteDS] Synced ${results.length} drafts',
      );
      return results;
    } on sb.PostgrestException catch (e) {
      AppLogger.error(
        '[OfflineRemoteDS] Failed to sync drafts',
        error: e,
      );
      throw ServerException(
        message: e.message,
        statusCode: int.tryParse(e.code ?? '') ?? 500,
        data: e.details,
      );
    } catch (e) {
      AppLogger.error(
        '[OfflineRemoteDS] Unexpected error syncing drafts',
        error: e,
      );
      throw ServerException(
        message: 'Failed to sync drafts: $e',
        statusCode: 500,
      );
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // FILE DOWNLOAD URL
  // ═══════════════════════════════════════════════════════════════════════

  @override
  Future<String> getFileDownloadUrl(
    String resourceType,
    String resourceId,
  ) async {
    try {
      // Generate a signed URL from Supabase Storage.
      final bucket = _resolveBucket(resourceType);
      final filePath = '$resourceType/$resourceId';

      final signedUrl = await supabaseClient.storage
          .from(bucket)
          .createSignedUrl(filePath, 3600); // 1 hour expiry

      AppLogger.info(
        '[OfflineRemoteDS] Generated download URL for $resourceType/$resourceId',
      );
      return signedUrl;
    } on sb.StorageException catch (e) {
      AppLogger.error(
        '[OfflineRemoteDS] Failed to get download URL',
        error: e,
      );
      throw ServerException(
        message: e.message,
        statusCode: 500,
      );
    } catch (e) {
      AppLogger.error(
        '[OfflineRemoteDS] Unexpected error getting download URL',
        error: e,
      );
      throw ServerException(
        message: 'Failed to get download URL: $e',
        statusCode: 500,
      );
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // CONNECTIVITY EVENTS
  // ═══════════════════════════════════════════════════════════════════════

  @override
  Future<bool> reportConnectivityEvent(
    Map<String, dynamic> eventData,
  ) async {
    try {
      await supabaseClient
          .from(_connectivityTable)
          .insert(eventData);

      AppLogger.debug('[OfflineRemoteDS] Connectivity event reported');
      return true;
    } on sb.PostgrestException catch (e) {
      AppLogger.error(
        '[OfflineRemoteDS] Failed to report connectivity event',
        error: e,
      );
      throw ServerException(
        message: e.message,
        statusCode: int.tryParse(e.code ?? '') ?? 500,
        data: e.details,
      );
    } catch (e) {
      AppLogger.error(
        '[OfflineRemoteDS] Unexpected error reporting connectivity event',
        error: e,
      );
      throw ServerException(
        message: 'Failed to report connectivity event: $e',
        statusCode: 500,
      );
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // USAGE EVENTS
  // ═══════════════════════════════════════════════════════════════════════

  @override
  Future<bool> logUsageEvents(List<Map<String, dynamic>> events) async {
    try {
      await supabaseClient
          .from(_usageEventsTable)
          .insert(events);

      AppLogger.info(
        '[OfflineRemoteDS] Logged ${events.length} usage events',
      );
      return true;
    } on sb.PostgrestException catch (e) {
      AppLogger.error(
        '[OfflineRemoteDS] Failed to log usage events',
        error: e,
      );
      throw ServerException(
        message: e.message,
        statusCode: int.tryParse(e.code ?? '') ?? 500,
        data: e.details,
      );
    } catch (e) {
      AppLogger.error(
        '[OfflineRemoteDS] Unexpected error logging usage events',
        error: e,
      );
      throw ServerException(
        message: 'Failed to log usage events: $e',
        statusCode: 500,
      );
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // OFFLINE EXAM CONFIGS
  // ═══════════════════════════════════════════════════════════════════════

  @override
  Future<List<Map<String, dynamic>>> getOfflineExamConfigs(
    String schoolId,
  ) async {
    try {
      final response = await supabaseClient
          .from(_offlineExamConfigTable)
          .select()
          .eq('school_id', schoolId)
          .eq('allows_offline', true);

      AppLogger.info(
        '[OfflineRemoteDS] Fetched ${(response as List).length} '
        'offline exam configs for school $schoolId',
      );
      return List<Map<String, dynamic>>.from(response);
    } on sb.PostgrestException catch (e) {
      AppLogger.error(
        '[OfflineRemoteDS] Failed to get offline exam configs',
        error: e,
      );
      throw ServerException(
        message: e.message,
        statusCode: int.tryParse(e.code ?? '') ?? 500,
        data: e.details,
      );
    } catch (e) {
      AppLogger.error(
        '[OfflineRemoteDS] Unexpected error getting offline exam configs',
        error: e,
      );
      throw ServerException(
        message: 'Failed to get offline exam configs: $e',
        statusCode: 500,
      );
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // PRIVATE HELPERS
  // ═══════════════════════════════════════════════════════════════════════

  /// Resolves a resource type to the appropriate Supabase Storage bucket.
  String _resolveBucket(String resourceType) {
    switch (resourceType) {
      case 'exam':
        return 'exams';
      case 'resource':
        return 'resources';
      case 'question':
        return 'questions';
      default:
        return 'misc';
    }
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// RIVERPOD PROVIDER
// ═══════════════════════════════════════════════════════════════════════════════

/// Provider for the [OfflineRemoteDataSource] implementation.
final offlineRemoteDataSourceProvider =
    Provider<OfflineRemoteDataSource>((ref) {
  final supabaseClient = sb.Supabase.instance.client;
  return OfflineRemoteDataSourceImpl(supabaseClient: supabaseClient);
});
