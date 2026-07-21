import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/utils/logger.dart';
import '../../domain/entities/offline_entities.dart';
import '../../domain/usecases/delete_draft_usecase.dart';
import '../../domain/usecases/download_resource_usecase.dart';
import '../../domain/usecases/get_connectivity_info_usecase.dart';
import '../../domain/usecases/get_downloads_usecase.dart';
import '../../domain/usecases/get_drafts_usecase.dart';
import '../../domain/usecases/get_offline_resources_usecase.dart';
import '../../domain/usecases/get_sync_status_usecase.dart';
import '../../domain/usecases/register_device_usecase.dart';
import '../../domain/usecases/remove_offline_resource_usecase.dart';
import '../../domain/usecases/save_draft_usecase.dart';
import '../../domain/usecases/start_download_usecase.dart';
import '../../domain/usecases/trigger_sync_usecase.dart';
import '../../../../features/offline/domain/repositories/offline_repository.dart';


// ═══════════════════════════════════════════════════════════════════════
// OFFLINE STATE
// ═══════════════════════════════════════════════════════════════════════

/// Immutable state snapshot for the offline feature.
///
/// Tracks sync status, offline resources, drafts, connectivity info,
/// pending exam attempts, downloads, and device registration state.
class OfflineState {
  const OfflineState({
    this.isLoading = false,
    this.error,
    this.successMessage,
    this.syncStatus,
    this.offlineResources = const [],
    this.drafts = const [],
    this.connectivityInfo,
    this.pendingAttempts = const [],
    this.downloads = const [],
    this.deviceRegistered = false,
  });

  /// Whether an async operation is in progress.
  final bool isLoading;

  /// The most recent error message, or `null`.
  final String? error;

  /// A transient success message, or `null`.
  final String? successMessage;

  /// The current sync status.
  final SyncStatusInfo? syncStatus;

  /// The list of offline-available resources.
  final List<OfflineResource> offlineResources;

  /// The list of saved drafts.
  final List<DraftWork> drafts;

  /// The current connectivity information.
  final ConnectivityInfo? connectivityInfo;

  /// The list of pending exam attempts.
  final List<OfflineExamAttempt> pendingAttempts;

  /// The list of file downloads.
  final List<FileDownload> downloads;

  /// Whether a device has been registered.
  final bool deviceRegistered;

  /// Whether the device is currently offline.
  bool get isOffline => connectivityInfo?.isOnline == false;

  /// Whether sync has issues requiring attention.
  bool get hasSyncIssues => syncStatus?.hasIssues == true;

  /// Count of active (in-progress) downloads.
  int get activeDownloadCount =>
      downloads.where((d) => d.isDownloading).length;

  /// Total size of offline resources in bytes.
  int get totalOfflineSizeBytes =>
      offlineResources.fold(0, (sum, r) => sum + r.fileSizeBytes);

  /// Creates a copy of this state with the given fields replaced.
  OfflineState copyWith({
    bool? isLoading,
    String? error,
    String? successMessage,
    SyncStatusInfo? syncStatus,
    List<OfflineResource>? offlineResources,
    List<DraftWork>? drafts,
    ConnectivityInfo? connectivityInfo,
    List<OfflineExamAttempt>? pendingAttempts,
    List<FileDownload>? downloads,
    bool? deviceRegistered,
  }) {
    return OfflineState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      successMessage: successMessage,
      syncStatus: syncStatus ?? this.syncStatus,
      offlineResources: offlineResources ?? this.offlineResources,
      drafts: drafts ?? this.drafts,
      connectivityInfo: connectivityInfo ?? this.connectivityInfo,
      pendingAttempts: pendingAttempts ?? this.pendingAttempts,
      downloads: downloads ?? this.downloads,
      deviceRegistered: deviceRegistered ?? this.deviceRegistered,
    );
  }

  /// Clears the current error message.
  OfflineState clearError() => copyWith(error: null);

  /// Clears the current success message.
  OfflineState clearSuccess() => copyWith(successMessage: null);
}

// ═══════════════════════════════════════════════════════════════════════
// OFFLINE NOTIFIER
// ═══════════════════════════════════════════════════════════════════════

/// Riverpod [StateNotifier] that manages the offline feature's state.
///
/// Supports loading sync status, managing offline resources, drafts,
/// connectivity info, device registration, and file downloads.
class OfflineNotifier extends StateNotifier<OfflineState> {
  OfflineNotifier({
    required GetSyncStatusUseCase getSyncStatusUseCase,
    required TriggerSyncUseCase triggerSyncUseCase,
    required GetOfflineResourcesUseCase getOfflineResourcesUseCase,
    required DownloadResourceUseCase downloadResourceUseCase,
    required RemoveOfflineResourceUseCase removeOfflineResourceUseCase,
    required SaveDraftUseCase saveDraftUseCase,
    required GetDraftsUseCase getDraftsUseCase,
    required DeleteDraftUseCase deleteDraftUseCase,
    required GetConnectivityInfoUseCase getConnectivityInfoUseCase,
    required RegisterDeviceUseCase registerDeviceUseCase,
    required StartDownloadUseCase startDownloadUseCase,
    required GetDownloadsUseCase getDownloadsUseCase,
  })  : _getSyncStatusUseCase = getSyncStatusUseCase,
        _triggerSyncUseCase = triggerSyncUseCase,
        _getOfflineResourcesUseCase = getOfflineResourcesUseCase,
        _downloadResourceUseCase = downloadResourceUseCase,
        _removeOfflineResourceUseCase = removeOfflineResourceUseCase,
        _saveDraftUseCase = saveDraftUseCase,
        _getDraftsUseCase = getDraftsUseCase,
        _deleteDraftUseCase = deleteDraftUseCase,
        _getConnectivityInfoUseCase = getConnectivityInfoUseCase,
        _registerDeviceUseCase = registerDeviceUseCase,
        _startDownloadUseCase = startDownloadUseCase,
        _getDownloadsUseCase = getDownloadsUseCase,
        super(const OfflineState());

  final GetSyncStatusUseCase _getSyncStatusUseCase;
  final TriggerSyncUseCase _triggerSyncUseCase;
  final GetOfflineResourcesUseCase _getOfflineResourcesUseCase;
  final DownloadResourceUseCase _downloadResourceUseCase;
  final RemoveOfflineResourceUseCase _removeOfflineResourceUseCase;
  final SaveDraftUseCase _saveDraftUseCase;
  final GetDraftsUseCase _getDraftsUseCase;
  final DeleteDraftUseCase _deleteDraftUseCase;
  final GetConnectivityInfoUseCase _getConnectivityInfoUseCase;
  final RegisterDeviceUseCase _registerDeviceUseCase;
  final StartDownloadUseCase _startDownloadUseCase;
  final GetDownloadsUseCase _getDownloadsUseCase;

  // ─── Load Sync Status ──────────────────────────────────────────────

  /// Loads the current sync status for the given user.
  Future<void> loadSyncStatus(String userId) async {
    state = state.copyWith(isLoading: true, error: null);

    final result = await _getSyncStatusUseCase(
      GetSyncStatusParams(userId: userId),
    );

    result.fold(
      onSuccess: (syncStatus) {
        state = state.copyWith(
          isLoading: false,
          syncStatus: syncStatus,
          error: null,
        );
        AppLogger.info('Loaded sync status: ${syncStatus.syncHealth.value}');
      },
      onFailure: (failure) {
        state = state.copyWith(
          isLoading: false,
          error: _mapFailureToMessage(failure),
        );
        AppLogger.warning('Failed to load sync status: $failure');
      },
    );
  }

  // ─── Load Offline Resources ────────────────────────────────────────

  /// Loads the list of offline resources for the given user.
  Future<void> loadOfflineResources(String userId, {String? resourceType}) async {
    state = state.copyWith(isLoading: true, error: null);

    final result = await _getOfflineResourcesUseCase(
      GetOfflineResourcesParams(userId: userId, resourceType: resourceType),
    );

    result.fold(
      onSuccess: (resources) {
        state = state.copyWith(
          isLoading: false,
          offlineResources: resources,
          error: null,
        );
        AppLogger.info('Loaded ${resources.length} offline resources');
      },
      onFailure: (failure) {
        state = state.copyWith(
          isLoading: false,
          error: _mapFailureToMessage(failure),
        );
        AppLogger.warning('Failed to load offline resources: $failure');
      },
    );
  }

  // ─── Download Resource ─────────────────────────────────────────────

  /// Downloads a resource for offline access.
  Future<void> downloadResource({
    required String userId,
    required String resourceType,
    required String resourceId,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    final result = await _downloadResourceUseCase(
      DownloadResourceParams(
        userId: userId,
        resourceType: resourceType,
        resourceId: resourceId,
      ),
    );

    result.fold(
      onSuccess: (_) {
        state = state.copyWith(
          isLoading: false,
          successMessage: 'Resource queued for download',
          error: null,
        );
        AppLogger.info('Resource download queued: $resourceId');
        // Refresh the resources list
        loadOfflineResources(userId);
      },
      onFailure: (failure) {
        state = state.copyWith(
          isLoading: false,
          error: _mapFailureToMessage(failure),
        );
        AppLogger.warning('Failed to download resource: $failure');
      },
    );
  }

  // ─── Remove Resource ───────────────────────────────────────────────

  /// Removes an offline resource from local storage.
  Future<void> removeResource(String resourceId, {String? userId}) async {
    state = state.copyWith(isLoading: true, error: null);

    final result = await _removeOfflineResourceUseCase(
      RemoveOfflineResourceParams(resourceId: resourceId),
    );

    result.fold(
      onSuccess: (_) {
        final updatedResources = state.offlineResources
            .where((r) => r.id != resourceId)
            .toList();
        state = state.copyWith(
          isLoading: false,
          offlineResources: updatedResources,
          successMessage: 'Resource removed from offline storage',
          error: null,
        );
        AppLogger.info('Removed offline resource: $resourceId');
      },
      onFailure: (failure) {
        state = state.copyWith(
          isLoading: false,
          error: _mapFailureToMessage(failure),
        );
        AppLogger.warning('Failed to remove offline resource: $failure');
      },
    );
  }

  // ─── Load Drafts ───────────────────────────────────────────────────

  /// Loads the list of drafts for the given user.
  Future<void> loadDrafts(String userId, {String? draftType}) async {
    state = state.copyWith(isLoading: true, error: null);

    final result = await _getDraftsUseCase(
      GetDraftsParams(userId: userId, draftType: draftType),
    );

    result.fold(
      onSuccess: (drafts) {
        state = state.copyWith(
          isLoading: false,
          drafts: drafts,
          error: null,
        );
        AppLogger.info('Loaded ${drafts.length} drafts');
      },
      onFailure: (failure) {
        state = state.copyWith(
          isLoading: false,
          error: _mapFailureToMessage(failure),
        );
        AppLogger.warning('Failed to load drafts: $failure');
      },
    );
  }

  // ─── Save Draft ────────────────────────────────────────────────────

  /// Saves or updates a draft.
  Future<void> saveDraft(DraftWork draft) async {
    state = state.copyWith(isLoading: true, error: null);

    final result = await _saveDraftUseCase(
      SaveDraftParams(draft: draft),
    );

    result.fold(
      onSuccess: (savedDraft) {
        final existingIndex = state.drafts.indexWhere((d) => d.id == savedDraft.id);
        final updatedDrafts = List<DraftWork>.from(state.drafts);
        if (existingIndex >= 0) {
          updatedDrafts[existingIndex] = savedDraft;
        } else {
          updatedDrafts.add(savedDraft);
        }
        state = state.copyWith(
          isLoading: false,
          drafts: updatedDrafts,
          successMessage: 'Draft saved successfully',
          error: null,
        );
        AppLogger.info('Draft saved: ${savedDraft.id}');
      },
      onFailure: (failure) {
        state = state.copyWith(
          isLoading: false,
          error: _mapFailureToMessage(failure),
        );
        AppLogger.warning('Failed to save draft: $failure');
      },
    );
  }

  // ─── Delete Draft ──────────────────────────────────────────────────

  /// Deletes a draft by ID.
  Future<void> deleteDraft(String draftId) async {
    state = state.copyWith(isLoading: true, error: null);

    final result = await _deleteDraftUseCase(
      DeleteDraftParams(draftId: draftId),
    );

    result.fold(
      onSuccess: (_) {
        final updatedDrafts = state.drafts
            .where((d) => d.id != draftId)
            .toList();
        state = state.copyWith(
          isLoading: false,
          drafts: updatedDrafts,
          successMessage: 'Draft deleted',
          error: null,
        );
        AppLogger.info('Draft deleted: $draftId');
      },
      onFailure: (failure) {
        state = state.copyWith(
          isLoading: false,
          error: _mapFailureToMessage(failure),
        );
        AppLogger.warning('Failed to delete draft: $failure');
      },
    );
  }

  // ─── Load Connectivity Info ────────────────────────────────────────

  /// Loads the current connectivity information.
  Future<void> loadConnectivityInfo() async {
    final result = await _getConnectivityInfoUseCase();

    result.fold(
      onSuccess: (connectivityInfo) {
        state = state.copyWith(
          connectivityInfo: connectivityInfo,
        );
        AppLogger.info(
          'Connectivity: ${connectivityInfo.connectionQuality.value} '
          '(${connectivityInfo.connectionType.value})',
        );
      },
      onFailure: (failure) {
        AppLogger.warning('Failed to load connectivity info: $failure');
      },
    );
  }

  // ─── Register Device ───────────────────────────────────────────────

  /// Registers a device for push notifications.
  Future<void> registerDevice(DeviceRegistration device) async {
    state = state.copyWith(isLoading: true, error: null);

    final result = await _registerDeviceUseCase(
      RegisterDeviceParams(device: device),
    );

    result.fold(
      onSuccess: (_) {
        state = state.copyWith(
          isLoading: false,
          deviceRegistered: true,
          successMessage: 'Device registered successfully',
          error: null,
        );
        AppLogger.info('Device registered: ${device.deviceName}');
      },
      onFailure: (failure) {
        state = state.copyWith(
          isLoading: false,
          error: _mapFailureToMessage(failure),
        );
        AppLogger.warning('Failed to register device: $failure');
      },
    );
  }

  // ─── Load Downloads ────────────────────────────────────────────────

  /// Loads the list of file downloads for the given user.
  Future<void> loadDownloads(String userId, {String? status}) async {
    final result = await _getDownloadsUseCase(
      GetDownloadsParams(userId: userId, status: status),
    );

    result.fold(
      onSuccess: (downloads) {
        state = state.copyWith(
          downloads: downloads,
        );
        AppLogger.info('Loaded ${downloads.length} downloads');
      },
      onFailure: (failure) {
        AppLogger.warning('Failed to load downloads: $failure');
      },
    );
  }

  // ─── Start Download ────────────────────────────────────────────────

  /// Starts a new file download.
  Future<void> startDownload({
    required String userId,
    required String resourceType,
    required String resourceId,
    required String fileUrl,
    required String fileName,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    final result = await _startDownloadUseCase(
      StartDownloadParams(
        userId: userId,
        resourceType: resourceType,
        resourceId: resourceId,
        fileUrl: fileUrl,
        fileName: fileName,
      ),
    );

    result.fold(
      onSuccess: (download) {
        final updatedDownloads = List<FileDownload>.from(state.downloads)
          ..add(download);
        state = state.copyWith(
          isLoading: false,
          downloads: updatedDownloads,
          successMessage: 'Download started',
          error: null,
        );
        AppLogger.info('Download started: ${download.fileName}');
      },
      onFailure: (failure) {
        state = state.copyWith(
          isLoading: false,
          error: _mapFailureToMessage(failure),
        );
        AppLogger.warning('Failed to start download: $failure');
      },
    );
  }

  // ─── Clear Error ───────────────────────────────────────────────────

  /// Clears the current error message from the state.
  void clearError() {
    state = state.clearError();
  }

  // ─── Clear Success ─────────────────────────────────────────────────

  /// Clears the current success message from the state.
  void clearSuccess() {
    state = state.clearSuccess();
  }

  // ═══════════════════════════════════════════════════════════════════════
  // PRIVATE HELPERS
  // ═══════════════════════════════════════════════════════════════════════

  /// Maps a [Failure] to a user-friendly error message.
  String _mapFailureToMessage(Failure failure) {
    return failure.when(
      server: (message, _, __) => message,
      cache: (message) => message,
      auth: (message, _) => message,
      network: (message) => message,
      validation: (message, _) => message,
      notFound: (message) => message,
      unauthorized: (message) => message,
      forbidden: (message) => message,
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// OFFLINE PROVIDER
// ═══════════════════════════════════════════════════════════════════════

/// Riverpod provider for the offline feature.
///
/// The factory accepts all required use cases via named parameters.
/// Use case providers should be defined in the DI layer.
final offlineProvider =
    StateNotifierProvider<OfflineNotifier, OfflineState>(
  (ref) => OfflineNotifier(
    getSyncStatusUseCase: ref.watch(getSyncStatusUseCaseProvider),
    triggerSyncUseCase: ref.watch(triggerSyncUseCaseProvider),
    getOfflineResourcesUseCase: ref.watch(getOfflineResourcesUseCaseProvider),
    downloadResourceUseCase: ref.watch(downloadResourceUseCaseProvider),
    removeOfflineResourceUseCase: ref.watch(removeOfflineResourceUseCaseProvider),
    saveDraftUseCase: ref.watch(saveDraftUseCaseProvider),
    getDraftsUseCase: ref.watch(getDraftsUseCaseProvider),
    deleteDraftUseCase: ref.watch(deleteDraftUseCaseProvider),
    getConnectivityInfoUseCase: ref.watch(getConnectivityInfoUseCaseProvider),
    registerDeviceUseCase: ref.watch(registerDeviceUseCaseProvider),
    startDownloadUseCase: ref.watch(startDownloadUseCaseProvider),
    getDownloadsUseCase: ref.watch(getDownloadsUseCaseProvider),
  ),
);

// ═══════════════════════════════════════════════════════════════════════
// USE CASE PROVIDERS (stubs — wire up in dependency_injection.dart)
// ═══════════════════════════════════════════════════════════════════════
// These placeholder providers must be overridden in the DI layer with
// real implementations that inject the OfflineRepository.

final getSyncStatusUseCaseProvider = Provider<GetSyncStatusUseCase>(
  (ref) => throw UnimplementedError('Wire up in dependency_injection.dart'),
);

final triggerSyncUseCaseProvider = Provider<TriggerSyncUseCase>(
  (ref) => throw UnimplementedError('Wire up in dependency_injection.dart'),
);

final getOfflineResourcesUseCaseProvider = Provider<GetOfflineResourcesUseCase>(
  (ref) => throw UnimplementedError('Wire up in dependency_injection.dart'),
);

final downloadResourceUseCaseProvider = Provider<DownloadResourceUseCase>(
  (ref) => throw UnimplementedError('Wire up in dependency_injection.dart'),
);

final removeOfflineResourceUseCaseProvider = Provider<RemoveOfflineResourceUseCase>(
  (ref) => throw UnimplementedError('Wire up in dependency_injection.dart'),
);

final saveDraftUseCaseProvider = Provider<SaveDraftUseCase>(
  (ref) => throw UnimplementedError('Wire up in dependency_injection.dart'),
);

final getDraftsUseCaseProvider = Provider<GetDraftsUseCase>(
  (ref) => throw UnimplementedError('Wire up in dependency_injection.dart'),
);

final deleteDraftUseCaseProvider = Provider<DeleteDraftUseCase>(
  (ref) => throw UnimplementedError('Wire up in dependency_injection.dart'),
);

final getConnectivityInfoUseCaseProvider = Provider<GetConnectivityInfoUseCase>(
  (ref) => throw UnimplementedError('Wire up in dependency_injection.dart'),
);

final registerDeviceUseCaseProvider = Provider<RegisterDeviceUseCase>(
  (ref) => throw UnimplementedError('Wire up in dependency_injection.dart'),
);

final startDownloadUseCaseProvider = Provider<StartDownloadUseCase>(
  (ref) => throw UnimplementedError('Wire up in dependency_injection.dart'),
);

final getDownloadsUseCaseProvider = Provider<GetDownloadsUseCase>(
  (ref) => throw UnimplementedError('Wire up in dependency_injection.dart'),
);
