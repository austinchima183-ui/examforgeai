import 'package:equatable/equatable.dart';

// ============================================================================
// ENUMS
// ============================================================================

/// Overall sync health status.
enum SyncHealth {
  good(value: 'good', label: 'Good', color: '#16A34A'),
  warning(value: 'warning', label: 'Warning', color: '#F59E0B'),
  critical(value: 'critical', label: 'Critical', color: '#DC2626');

  const SyncHealth({required this.value, required this.label, required this.color});
  final String value;
  final String label;
  final String color;

  static SyncHealth? fromString(String? value) {
    if (value == null) return null;
    return SyncHealth.values.cast<SyncHealth?>().firstWhere(
      (e) => e?.value == value,
      orElse: () => null,
    );
  }
}

/// Offline exam type.
enum OfflineType {
  practice(value: 'practice', label: 'Practice'),
  mock(value: 'mock', label: 'Mock'),
  none(value: 'none', label: 'None');

  const OfflineType({required this.value, required this.label});
  final String value;
  final String label;

  static OfflineType? fromString(String? value) {
    if (value == null) return null;
    return OfflineType.values.cast<OfflineType?>().firstWhere(
      (e) => e?.value == value,
      orElse: () => null,
    );
  }
}

/// Sync status for an offline exam attempt.
enum AttemptSyncStatus {
  pending(value: 'pending', label: 'Pending'),
  synced(value: 'synced', label: 'Synced'),
  validated(value: 'validated', label: 'Validated'),
  rejected(value: 'rejected', label: 'Rejected');

  const AttemptSyncStatus({required this.value, required this.label});
  final String value;
  final String label;

  static AttemptSyncStatus? fromString(String? value) {
    if (value == null) return null;
    return AttemptSyncStatus.values.cast<AttemptSyncStatus?>().firstWhere(
      (e) => e?.value == value,
      orElse: () => null,
    );
  }
}

/// Connection quality levels.
enum ConnectionQuality {
  excellent(value: 'excellent', label: 'Excellent', color: '#16A34A'),
  good(value: 'good', label: 'Good', color: '#2563EB'),
  limited(value: 'limited', label: 'Limited', color: '#F59E0B'),
  offline(value: 'offline', label: 'Offline', color: '#DC2626');

  const ConnectionQuality({
    required this.value,
    required this.label,
    required this.color,
  });
  final String value;
  final String label;
  final String color;

  static ConnectionQuality? fromString(String? value) {
    if (value == null) return null;
    return ConnectionQuality.values.cast<ConnectionQuality?>().firstWhere(
      (e) => e?.value == value,
      orElse: () => null,
    );
  }
}

/// Connection type.
enum ConnectionType {
  wifi(value: 'wifi', label: 'Wi-Fi'),
  mobile(value: 'mobile', label: 'Mobile Data'),
  ethernet(value: 'ethernet', label: 'Ethernet'),
  none(value: 'none', label: 'No Connection');

  const ConnectionType({required this.value, required this.label});
  final String value;
  final String label;

  static ConnectionType? fromString(String? value) {
    if (value == null) return null;
    return ConnectionType.values.cast<ConnectionType?>().firstWhere(
      (e) => e?.value == value,
      orElse: () => null,
    );
  }
}

/// Draft work type.
enum DraftType {
  exam(value: 'exam', label: 'Exam'),
  assignment(value: 'assignment', label: 'Assignment'),
  lessonPlan(value: 'lesson_plan', label: 'Lesson Plan'),
  question(value: 'question', label: 'Question'),
  resource(value: 'resource', label: 'Resource');

  const DraftType({required this.value, required this.label});
  final String value;
  final String label;

  static DraftType? fromString(String? value) {
    if (value == null) return null;
    return DraftType.values.cast<DraftType?>().firstWhere(
      (e) => e?.value == value,
      orElse: () => null,
    );
  }
}

/// File download status.
enum DownloadStatus {
  pending(value: 'pending', label: 'Pending'),
  downloading(value: 'downloading', label: 'Downloading'),
  completed(value: 'completed', label: 'Completed'),
  failed(value: 'failed', label: 'Failed'),
  expired(value: 'expired', label: 'Expired');

  const DownloadStatus({required this.value, required this.label});
  final String value;
  final String label;

  static DownloadStatus? fromString(String? value) {
    if (value == null) return null;
    return DownloadStatus.values.cast<DownloadStatus?>().firstWhere(
      (e) => e?.value == value,
      orElse: () => null,
    );
  }
}

// ============================================================================
// ENTITIES
// ============================================================================

/// Overall sync status for the offline module.
class SyncStatusInfo extends Equatable {
  const SyncStatusInfo({
    required this.pendingCount,
    required this.failedCount,
    required this.completedCount,
    required this.deadCount,
    required this.conflictCount,
    this.lastSyncAt,
    required this.isSyncing,
    required this.syncHealth,
  });

  final int pendingCount;
  final int failedCount;
  final int completedCount;
  final int deadCount;
  final int conflictCount;
  final DateTime? lastSyncAt;
  final bool isSyncing;
  final SyncHealth syncHealth;

  /// Whether there are any issues requiring attention.
  bool get hasIssues => failedCount > 0 || conflictCount > 0 || deadCount > 0;

  /// Whether the sync system needs user attention.
  bool get needsAttention => hasIssues || syncHealth == SyncHealth.critical;

  @override
  List<Object?> get props => [
        pendingCount,
        failedCount,
        completedCount,
        deadCount,
        conflictCount,
        lastSyncAt,
        isSyncing,
        syncHealth,
      ];

  SyncStatusInfo copyWith({
    int? pendingCount,
    int? failedCount,
    int? completedCount,
    int? deadCount,
    int? conflictCount,
    DateTime? lastSyncAt,
    bool? isSyncing,
    SyncHealth? syncHealth,
  }) {
    return SyncStatusInfo(
      pendingCount: pendingCount ?? this.pendingCount,
      failedCount: failedCount ?? this.failedCount,
      completedCount: completedCount ?? this.completedCount,
      deadCount: deadCount ?? this.deadCount,
      conflictCount: conflictCount ?? this.conflictCount,
      lastSyncAt: lastSyncAt ?? this.lastSyncAt,
      isSyncing: isSyncing ?? this.isSyncing,
      syncHealth: syncHealth ?? this.syncHealth,
    );
  }
}

/// A locally cached resource for offline access.
class OfflineResource extends Equatable {
  const OfflineResource({
    required this.id,
    required this.userId,
    required this.resourceType,
    required this.resourceId,
    required this.title,
    required this.filePath,
    required this.fileSizeBytes,
    required this.mimeType,
    required this.checksum,
    this.licenseExpiresAt,
    required this.isAvailable,
    required this.accessCount,
    this.lastAccessedAt,
    required this.createdAt,
  });

  final String id;
  final String userId;
  final String resourceType;
  final String resourceId;
  final String title;
  final String filePath;
  final int fileSizeBytes;
  final String mimeType;
  final String checksum;
  final DateTime? licenseExpiresAt;
  final bool isAvailable;
  final int accessCount;
  final DateTime? lastAccessedAt;
  final DateTime createdAt;

  /// Human-readable file size string.
  String get fileSizeDisplay {
    if (fileSizeBytes < 1024) return '$fileSizeBytes B';
    if (fileSizeBytes < 1024 * 1024) return '${(fileSizeBytes / 1024).toStringAsFixed(1)} KB';
    if (fileSizeBytes < 1024 * 1024 * 1024) return '${(fileSizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(fileSizeBytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  /// Whether the license has expired.
  bool get isLicenseExpired =>
      licenseExpiresAt != null && licenseExpiresAt!.isBefore(DateTime.now());

  @override
  List<Object?> get props => [
        id,
        userId,
        resourceType,
        resourceId,
        title,
        filePath,
        fileSizeBytes,
        mimeType,
        checksum,
        licenseExpiresAt,
        isAvailable,
        accessCount,
        lastAccessedAt,
        createdAt,
      ];
}

/// School's offline exam configuration.
class OfflineExamConfig extends Equatable {
  const OfflineExamConfig({
    required this.id,
    required this.schoolId,
    required this.examId,
    required this.allowsOffline,
    required this.offlineType,
    required this.maxOfflineAttempts,
    required this.requiresOnlineSubmission,
    required this.autoSubmitOnReconnect,
    required this.createdAt,
  });

  final String id;
  final String schoolId;
  final String examId;
  final bool allowsOffline;
  final OfflineType offlineType;
  final int maxOfflineAttempts;
  final bool requiresOnlineSubmission;
  final bool autoSubmitOnReconnect;
  final DateTime createdAt;

  @override
  List<Object?> get props => [
        id,
        schoolId,
        examId,
        allowsOffline,
        offlineType,
        maxOfflineAttempts,
        requiresOnlineSubmission,
        autoSubmitOnReconnect,
        createdAt,
      ];

  OfflineExamConfig copyWith({
    String? id,
    String? schoolId,
    String? examId,
    bool? allowsOffline,
    OfflineType? offlineType,
    int? maxOfflineAttempts,
    bool? requiresOnlineSubmission,
    bool? autoSubmitOnReconnect,
    DateTime? createdAt,
  }) {
    return OfflineExamConfig(
      id: id ?? this.id,
      schoolId: schoolId ?? this.schoolId,
      examId: examId ?? this.examId,
      allowsOffline: allowsOffline ?? this.allowsOffline,
      offlineType: offlineType ?? this.offlineType,
      maxOfflineAttempts: maxOfflineAttempts ?? this.maxOfflineAttempts,
      requiresOnlineSubmission: requiresOnlineSubmission ?? this.requiresOnlineSubmission,
      autoSubmitOnReconnect: autoSubmitOnReconnect ?? this.autoSubmitOnReconnect,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

/// An offline exam attempt.
class OfflineExamAttempt extends Equatable {
  const OfflineExamAttempt({
    required this.id,
    required this.examId,
    required this.studentId,
    required this.schoolId,
    required this.attemptData,
    required this.answers,
    required this.startedAt,
    this.completedAt,
    this.timeTakenSeconds,
    required this.integrityHash,
    required this.syncStatus,
    required this.syncAttempts,
    this.syncedAt,
    this.validationErrors,
    required this.createdAt,
  });

  final String id;
  final String examId;
  final String studentId;
  final String schoolId;
  final Map<String, dynamic> attemptData;
  final Map<String, dynamic> answers;
  final DateTime startedAt;
  final DateTime? completedAt;
  final int? timeTakenSeconds;
  final String integrityHash;
  final AttemptSyncStatus syncStatus;
  final int syncAttempts;
  final DateTime? syncedAt;
  final List<String>? validationErrors;
  final DateTime createdAt;

  /// Whether the attempt is pending sync.
  bool get isPending => syncStatus == AttemptSyncStatus.pending;

  /// Whether the attempt has been successfully synced.
  bool get isSynced => syncStatus == AttemptSyncStatus.synced || syncStatus == AttemptSyncStatus.validated;

  /// Whether the attempt was rejected after sync.
  bool get isRejected => syncStatus == AttemptSyncStatus.rejected;

  /// Whether the attempt is complete but not yet submitted.
  bool get isCompleteButUnsynced => completedAt != null && !isSynced;

  @override
  List<Object?> get props => [
        id,
        examId,
        studentId,
        schoolId,
        attemptData,
        answers,
        startedAt,
        completedAt,
        timeTakenSeconds,
        integrityHash,
        syncStatus,
        syncAttempts,
        syncedAt,
        validationErrors,
        createdAt,
      ];

  OfflineExamAttempt copyWith({
    String? id,
    String? examId,
    String? studentId,
    String? schoolId,
    Map<String, dynamic>? attemptData,
    Map<String, dynamic>? answers,
    DateTime? startedAt,
    DateTime? completedAt,
    int? timeTakenSeconds,
    String? integrityHash,
    AttemptSyncStatus? syncStatus,
    int? syncAttempts,
    DateTime? syncedAt,
    List<String>? validationErrors,
    DateTime? createdAt,
  }) {
    return OfflineExamAttempt(
      id: id ?? this.id,
      examId: examId ?? this.examId,
      studentId: studentId ?? this.studentId,
      schoolId: schoolId ?? this.schoolId,
      attemptData: attemptData ?? this.attemptData,
      answers: answers ?? this.answers,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
      timeTakenSeconds: timeTakenSeconds ?? this.timeTakenSeconds,
      integrityHash: integrityHash ?? this.integrityHash,
      syncStatus: syncStatus ?? this.syncStatus,
      syncAttempts: syncAttempts ?? this.syncAttempts,
      syncedAt: syncedAt ?? this.syncedAt,
      validationErrors: validationErrors ?? this.validationErrors,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

/// Current connectivity state.
class ConnectivityInfo extends Equatable {
  const ConnectivityInfo({
    required this.isOnline,
    required this.connectionQuality,
    required this.connectionType,
    this.latencyMs,
    this.bandwidthKbps,
    required this.shouldReduceQuality,
    required this.shouldDelaySync,
    required this.shouldCompressUploads,
  });

  final bool isOnline;
  final ConnectionQuality connectionQuality;
  final ConnectionType connectionType;
  final int? latencyMs;
  final double? bandwidthKbps;
  final bool shouldReduceQuality;
  final bool shouldDelaySync;
  final bool shouldCompressUploads;

  /// Whether the connection is strong enough for real-time features.
  bool get isRealTimeCapable =>
      isOnline &&
      connectionQuality == ConnectionQuality.excellent ||
      connectionQuality == ConnectionQuality.good;

  /// Whether the connection should be treated as metered.
  bool get isMetered => connectionType == ConnectionType.mobile;

  @override
  List<Object?> get props => [
        isOnline,
        connectionQuality,
        connectionType,
        latencyMs,
        bandwidthKbps,
        shouldReduceQuality,
        shouldDelaySync,
        shouldCompressUploads,
      ];

  ConnectivityInfo copyWith({
    bool? isOnline,
    ConnectionQuality? connectionQuality,
    ConnectionType? connectionType,
    int? latencyMs,
    double? bandwidthKbps,
    bool? shouldReduceQuality,
    bool? shouldDelaySync,
    bool? shouldCompressUploads,
  }) {
    return ConnectivityInfo(
      isOnline: isOnline ?? this.isOnline,
      connectionQuality: connectionQuality ?? this.connectionQuality,
      connectionType: connectionType ?? this.connectionType,
      latencyMs: latencyMs ?? this.latencyMs,
      bandwidthKbps: bandwidthKbps ?? this.bandwidthKbps,
      shouldReduceQuality: shouldReduceQuality ?? this.shouldReduceQuality,
      shouldDelaySync: shouldDelaySync ?? this.shouldDelaySync,
      shouldCompressUploads: shouldCompressUploads ?? this.shouldCompressUploads,
    );
  }
}

/// In-progress draft work.
class DraftWork extends Equatable {
  const DraftWork({
    required this.id,
    required this.userId,
    required this.draftType,
    required this.title,
    required this.content,
    this.schoolId,
    this.subjectId,
    required this.isSynced,
    required this.lastEditedAt,
    required this.createdAt,
  });

  final String id;
  final String userId;
  final DraftType draftType;
  final String title;
  final Map<String, dynamic> content;
  final String? schoolId;
  final String? subjectId;
  final bool isSynced;
  final DateTime lastEditedAt;
  final DateTime createdAt;

  /// How long since the last edit.
  Duration get timeSinceLastEdit => DateTime.now().difference(lastEditedAt);

  /// Whether the draft has been edited recently (within 1 hour).
  bool get isRecentlyEdited => timeSinceLastEdit.inHours < 1;

  @override
  List<Object?> get props => [
        id,
        userId,
        draftType,
        title,
        content,
        schoolId,
        subjectId,
        isSynced,
        lastEditedAt,
        createdAt,
      ];

  DraftWork copyWith({
    String? id,
    String? userId,
    DraftType? draftType,
    String? title,
    Map<String, dynamic>? content,
    String? schoolId,
    String? subjectId,
    bool? isSynced,
    DateTime? lastEditedAt,
    DateTime? createdAt,
  }) {
    return DraftWork(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      draftType: draftType ?? this.draftType,
      title: title ?? this.title,
      content: content ?? this.content,
      schoolId: schoolId ?? this.schoolId,
      subjectId: subjectId ?? this.subjectId,
      isSynced: isSynced ?? this.isSynced,
      lastEditedAt: lastEditedAt ?? this.lastEditedAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

/// Registered device info for push notifications and session management.
class DeviceRegistration extends Equatable {
  const DeviceRegistration({
    required this.id,
    required this.userId,
    required this.deviceToken,
    required this.platform,
    required this.deviceName,
    required this.deviceModel,
    required this.osVersion,
    required this.appVersion,
    required this.isActive,
    required this.lastActiveAt,
    required this.pushEnabled,
    required this.createdAt,
  });

  final String id;
  final String userId;
  final String deviceToken;
  final String platform;
  final String deviceName;
  final String deviceModel;
  final String osVersion;
  final String appVersion;
  final bool isActive;
  final DateTime lastActiveAt;
  final bool pushEnabled;
  final DateTime createdAt;

  @override
  List<Object?> get props => [
        id,
        userId,
        deviceToken,
        platform,
        deviceName,
        deviceModel,
        osVersion,
        appVersion,
        isActive,
        lastActiveAt,
        pushEnabled,
        createdAt,
      ];

  DeviceRegistration copyWith({
    String? id,
    String? userId,
    String? deviceToken,
    String? platform,
    String? deviceName,
    String? deviceModel,
    String? osVersion,
    String? appVersion,
    bool? isActive,
    DateTime? lastActiveAt,
    bool? pushEnabled,
    DateTime? createdAt,
  }) {
    return DeviceRegistration(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      deviceToken: deviceToken ?? this.deviceToken,
      platform: platform ?? this.platform,
      deviceName: deviceName ?? this.deviceName,
      deviceModel: deviceModel ?? this.deviceModel,
      osVersion: osVersion ?? this.osVersion,
      appVersion: appVersion ?? this.appVersion,
      isActive: isActive ?? this.isActive,
      lastActiveAt: lastActiveAt ?? this.lastActiveAt,
      pushEnabled: pushEnabled ?? this.pushEnabled,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

/// A file download for offline access.
class FileDownload extends Equatable {
  const FileDownload({
    required this.id,
    required this.userId,
    required this.resourceType,
    required this.resourceId,
    required this.fileName,
    required this.fileUrl,
    required this.fileSizeBytes,
    required this.mimeType,
    required this.localPath,
    required this.downloadStatus,
    this.licenseExpiresAt,
    required this.progress,
    required this.createdAt,
  });

  final String id;
  final String userId;
  final String resourceType;
  final String resourceId;
  final String fileName;
  final String fileUrl;
  final int fileSizeBytes;
  final String mimeType;
  final String localPath;
  final DownloadStatus downloadStatus;
  final DateTime? licenseExpiresAt;
  final double progress;
  final DateTime createdAt;

  /// Whether the download is in progress.
  bool get isDownloading => downloadStatus == DownloadStatus.downloading;

  /// Whether the download can be retried.
  bool get canRetry => downloadStatus == DownloadStatus.failed;

  /// Whether the download is complete.
  bool get isComplete => downloadStatus == DownloadStatus.completed;

  /// Human-readable file size string.
  String get fileSizeDisplay {
    if (fileSizeBytes < 1024) return '$fileSizeBytes B';
    if (fileSizeBytes < 1024 * 1024) return '${(fileSizeBytes / 1024).toStringAsFixed(1)} KB';
    if (fileSizeBytes < 1024 * 1024 * 1024) return '${(fileSizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(fileSizeBytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  /// Progress as a percentage string.
  String get progressPercent => '${(progress * 100).toStringAsFixed(0)}%';

  @override
  List<Object?> get props => [
        id,
        userId,
        resourceType,
        resourceId,
        fileName,
        fileUrl,
        fileSizeBytes,
        mimeType,
        localPath,
        downloadStatus,
        licenseExpiresAt,
        progress,
        createdAt,
      ];

  FileDownload copyWith({
    String? id,
    String? userId,
    String? resourceType,
    String? resourceId,
    String? fileName,
    String? fileUrl,
    int? fileSizeBytes,
    String? mimeType,
    String? localPath,
    DownloadStatus? downloadStatus,
    DateTime? licenseExpiresAt,
    double? progress,
    DateTime? createdAt,
  }) {
    return FileDownload(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      resourceType: resourceType ?? this.resourceType,
      resourceId: resourceId ?? this.resourceId,
      fileName: fileName ?? this.fileName,
      fileUrl: fileUrl ?? this.fileUrl,
      fileSizeBytes: fileSizeBytes ?? this.fileSizeBytes,
      mimeType: mimeType ?? this.mimeType,
      localPath: localPath ?? this.localPath,
      downloadStatus: downloadStatus ?? this.downloadStatus,
      licenseExpiresAt: licenseExpiresAt ?? this.licenseExpiresAt,
      progress: progress ?? this.progress,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

/// An analytics event for offline usage tracking.
class AppUsageEvent extends Equatable {
  const AppUsageEvent({
    required this.id,
    required this.userId,
    required this.eventType,
    required this.eventData,
    this.sessionId,
    this.appVersion,
    this.platform,
    this.screenName,
    this.durationMs,
    required this.createdAt,
  });

  final String id;
  final String userId;
  final String eventType;
  final Map<String, dynamic> eventData;
  final String? sessionId;
  final String? appVersion;
  final String? platform;
  final String? screenName;
  final int? durationMs;
  final DateTime createdAt;

  @override
  List<Object?> get props => [
        id,
        userId,
        eventType,
        eventData,
        sessionId,
        appVersion,
        platform,
        screenName,
        durationMs,
        createdAt,
      ];
}
