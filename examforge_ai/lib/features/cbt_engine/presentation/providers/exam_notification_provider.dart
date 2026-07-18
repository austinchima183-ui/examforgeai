import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/utils/logger.dart';
import '../../domain/repositories/cbt_repository.dart';

// ═══════════════════════════════════════════════════════════════════════
// EXAM NOTIFICATION STATE
// ═══════════════════════════════════════════════════════════════════════

/// Immutable state snapshot for the exam notification feature.
///
/// Tracks the current list of notifications, unread count, loading flags,
/// and error messages.
class ExamNotificationState {
  const ExamNotificationState({
    this.notifications = const [],
    this.unreadCount = 0,
    this.isLoading = false,
    this.error,
  });

  /// The current list of exam notifications.
  final List<ExamNotificationEntity> notifications;

  /// Number of unread notifications.
  final int unreadCount;

  /// Whether a load operation is in progress.
  final bool isLoading;

  /// The most recent error message, or `null`.
  final String? error;

  // ── Convenience getters ──────────────────────────────────────────────

  /// Whether there are any notifications.
  bool get hasNotifications => notifications.isNotEmpty;

  /// Whether there are unread notifications.
  bool get hasUnread => unreadCount > 0;

  /// Whether any async operation is in progress.
  bool get isBusy => isLoading;

  // ── copyWith ─────────────────────────────────────────────────────────

  ExamNotificationState copyWith({
    List<ExamNotificationEntity>? notifications,
    int? unreadCount,
    bool? isLoading,
    String? error,
  }) {
    return ExamNotificationState(
      notifications: notifications ?? this.notifications,
      unreadCount: unreadCount ?? this.unreadCount,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }

  /// Clears the current error message.
  ExamNotificationState clearError() => copyWith(error: null);
}

// ═══════════════════════════════════════════════════════════════════════
// EXAM NOTIFICATION NOTIFIER
// ═══════════════════════════════════════════════════════════════════════

/// Riverpod [StateNotifier] that manages the exam notification feature's
/// state.
///
/// Provides methods for loading notifications, marking individual
/// notifications as read, marking all as read, and retrieving the
/// unread count.
class ExamNotificationNotifier extends StateNotifier<ExamNotificationState> {
  ExamNotificationNotifier({
    required CbtRepository cbtRepository,
  })  : _cbtRepository = cbtRepository,
        super(const ExamNotificationState());

  final CbtRepository _cbtRepository;

  // ─── Load Notifications ──────────────────────────────────────────────

  /// Loads all exam notifications for the current user.
  Future<void> loadNotifications() async {
    state = state.copyWith(isLoading: true, error: null);

    // TODO: Replace with actual repository method once
    // `getNotifications` is added to CbtRepository.
    // final result = await _cbtRepository.getNotifications();
    // result.fold(
    //   onSuccess: (notifications) {
    //     final unread = notifications.where((n) => !n.isRead).length;
    //     state = state.copyWith(
    //       isLoading: false,
    //       notifications: notifications,
    //       unreadCount: unread,
    //       error: null,
    //     );
    //     AppLogger.info('Loaded ${notifications.length} notifications');
    //   },
    //   onFailure: (failure) {
    //     state = state.copyWith(
    //       isLoading: false,
    //       error: _mapFailureToMessage(failure),
    //     );
    //     AppLogger.warning('Failed to load notifications: $failure');
    //   },
    // );

    // Placeholder: no notifications yet
    state = state.copyWith(isLoading: false);
    AppLogger.info('Notifications loaded (placeholder — no data yet)');
  }

  // ─── Mark As Read ────────────────────────────────────────────────────

  /// Marks a single notification as read by its [notificationId].
  Future<void> markAsRead(String notificationId) async {
    final updatedList = state.notifications.map((n) {
      if (n.id == notificationId) {
        return n.copyWith(isRead: true);
      }
      return n;
    }).toList();

    final newUnreadCount = updatedList.where((n) => !n.isRead).length;

    state = state.copyWith(
      notifications: updatedList,
      unreadCount: newUnreadCount,
    );

    // TODO: Persist to backend once repository method is available.
    // await _cbtRepository.markNotificationAsRead(notificationId);
    AppLogger.info('Notification marked as read: $notificationId');
  }

  // ─── Mark All As Read ────────────────────────────────────────────────

  /// Marks all notifications as read.
  Future<void> markAllAsRead() async {
    final updatedList =
        state.notifications.map((n) => n.copyWith(isRead: true)).toList();

    state = state.copyWith(
      notifications: updatedList,
      unreadCount: 0,
    );

    // TODO: Persist to backend once repository method is available.
    // await _cbtRepository.markAllNotificationsAsRead();
    AppLogger.info('All notifications marked as read');
  }

  // ─── Get Unread Count ────────────────────────────────────────────────

  /// Returns the current unread notification count from state.
  int getUnreadCount() => state.unreadCount;

  // ─── Clear Error ─────────────────────────────────────────────────────

  /// Clears the current error message from the state.
  void clearError() {
    state = state.clearError();
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
// EXAM NOTIFICATION ENTITY (Local UI Model)
// ═══════════════════════════════════════════════════════════════════════

/// A lightweight notification model for the exam module UI layer.
///
/// This is a presentation-side model that represents exam-related
/// notifications such as exam published, exam starting soon, results
/// available, etc. It is not part of the domain entity hierarchy and
/// exists solely for UI rendering.
class ExamNotificationEntity {
  const ExamNotificationEntity({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    required this.createdAt,
    this.isRead = false,
    this.examId,
    this.metadata = const {},
  });

  /// Unique notification identifier.
  final String id;

  /// Short notification title.
  final String title;

  /// Detailed notification body text.
  final String body;

  /// Notification type for icon/routing decisions.
  final ExamNotificationType type;

  /// When the notification was created.
  final DateTime createdAt;

  /// Whether the notification has been read.
  final bool isRead;

  /// Optional associated exam ID for navigation.
  final String? examId;

  /// Optional key-value metadata for deep-linking or extra context.
  final Map<String, dynamic> metadata;

  ExamNotificationEntity copyWith({
    String? id,
    String? title,
    String? body,
    ExamNotificationType? type,
    DateTime? createdAt,
    bool? isRead,
    String? examId,
    Map<String, dynamic>? metadata,
  }) {
    return ExamNotificationEntity(
      id: id ?? this.id,
      title: title ?? this.title,
      body: body ?? this.body,
      type: type ?? this.type,
      createdAt: createdAt ?? this.createdAt,
      isRead: isRead ?? this.isRead,
      examId: examId ?? this.examId,
      metadata: metadata ?? this.metadata,
    );
  }
}

/// Types of exam-related notifications.
enum ExamNotificationType {
  /// A new exam has been published and assigned.
  examPublished('exam_published', 'Exam Published'),

  /// An exam is about to start.
  examStarting('exam_starting', 'Exam Starting'),

  /// An exam has been completed.
  examCompleted('exam_completed', 'Exam Completed'),

  /// Exam results are now available.
  resultsAvailable('results_available', 'Results Available'),

  /// Exam has been cancelled.
  examCancelled('exam_cancelled', 'Exam Cancelled'),

  /// A template has been shared.
  templateShared('template_shared', 'Template Shared'),

  /// General / miscellaneous notification.
  general('general', 'General');

  const ExamNotificationType(this.value, this.label);

  /// The string representation stored in the backend.
  final String value;

  /// Human-readable label for display in the UI.
  final String label;
}
