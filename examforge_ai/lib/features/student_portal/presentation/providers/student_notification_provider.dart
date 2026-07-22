import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/utils/logger.dart';
import '../../domain/entities/student_portal_entities.dart';
import '../../domain/usecases/student_portal_usecases.dart';
import 'student_dashboard_provider.dart';

// ═══════════════════════════════════════════════════════════════════════
// STUDENT NOTIFICATION STATE
// ═══════════════════════════════════════════════════════════════════════

/// Immutable state snapshot for the Student Notification feature.
///
/// Tracks the notification list, loading flags, pagination state,
/// unread count, and errors.
class StudentNotificationState {
  const StudentNotificationState({
    this.notifications = const [],
    this.isLoading = false,
    this.error,
    this.hasMore = true,
    this.unreadCount = 0,
    this.currentPage = 1,
  });

  /// All notifications for the current student.
  final List<StudentNotificationEntity> notifications;

  /// Whether the initial notification list load is in progress.
  final bool isLoading;

  /// The most recent error message, or `null`.
  final String? error;

  /// Whether there are more notification pages to load.
  final bool hasMore;

  /// Number of unread notifications.
  final int unreadCount;

  /// Current page number for notification pagination (1-based).
  // ignore: unused_field
  final int currentPage;

  /// Current page number for notification pagination.

  /// Whether any async operation is in progress.
  bool get isBusy => isLoading;

  /// Number of notifications loaded.
  int get notificationCount => notifications.length;

  /// Creates a copy of this state with the given fields replaced.
  StudentNotificationState copyWith({
    List<StudentNotificationEntity>? notifications,
    bool? isLoading,
    String? error,
    bool? hasMore,
    int? unreadCount,
    int? currentPage,
  }) {
    return StudentNotificationState(
      notifications: notifications ?? this.notifications,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      hasMore: hasMore ?? this.hasMore,
      unreadCount: unreadCount ?? this.unreadCount,
      currentPage: currentPage ?? currentPage,
    );
  }

  /// Clears the current error message.
  StudentNotificationState clearError() => copyWith(error: null);
}

// ═══════════════════════════════════════════════════════════════════════
// STUDENT NOTIFICATION NOTIFIER
// ═══════════════════════════════════════════════════════════════════════

/// Riverpod [StateNotifier] that manages the Student Notification
/// feature's state.
///
/// All notification operations flow through this notifier, which:
/// 1. Sets [isLoading] before each async operation
/// 2. Delegates to the appropriate use case
/// 3. Updates the notification list, unread count, and pagination on success
/// 4. Sets [error] on failure
class StudentNotificationNotifier
    extends StateNotifier<StudentNotificationState> {
  StudentNotificationNotifier({
    required GetNotificationsUseCase getNotifications,
    required MarkNotificationReadUseCase markNotificationRead,
    required MarkAllNotificationsReadUseCase markAllNotificationsRead,
    required String? studentId,
  })  : _getNotifications = getNotifications,
        _markNotificationRead = markNotificationRead,
        _markAllNotificationsRead = markAllNotificationsRead,
        _studentId = studentId,
        super(const StudentNotificationState());

  final GetNotificationsUseCase _getNotifications;
  final MarkNotificationReadUseCase _markNotificationRead;
  final MarkAllNotificationsReadUseCase _markAllNotificationsRead;
  final String? _studentId;

  static const int _pageSize = 20;

  // ─── Load Notifications (first page) ───────────────────────────────

  /// Loads the first page of notifications for the current student.
  Future<void> loadNotifications() async {
    if (_studentId == null) return;

    state = state.copyWith(isLoading: true, error: null);

    final result = await _getNotifications(
      studentId: _studentId!,
      page: 1,
      pageSize: _pageSize,
    );

    result.fold(
      onSuccess: (notifications) {
        final unread = notifications.where((n) => !n.isRead).length;
        state = state.copyWith(
          isLoading: false,
          notifications: notifications,
          currentPage: 1,
          hasMore: notifications.length >= _pageSize,
          unreadCount: unread,
          error: null,
        );
        AppLogger.info(
          'Loaded ${notifications.length} notifications (page 1)',
        );
      },
      onFailure: (failure) {
        state = state.copyWith(
          isLoading: false,
          error: _mapFailureToMessage(failure),
        );
        AppLogger.warning('Failed to load notifications: $failure');
      },
    );
  }

  // ─── Load More ─────────────────────────────────────────────────────

  /// Loads the next page of notifications and appends to the list.
  Future<void> loadMore() async {
    if (_studentId == null || !state.hasMore) return;

    final nextPage = state.currentPage + 1;

    final result = await _getNotifications(
      studentId: _studentId!,
      page: nextPage,
      pageSize: _pageSize,
    );

    result.fold(
      onSuccess: (newNotifications) {
        final allNotifications = [
          ...state.notifications,
          ...newNotifications,
        ];
        state = state.copyWith(
          notifications: allNotifications,
          currentPage: nextPage,
          hasMore: newNotifications.length >= _pageSize,
        );
        AppLogger.info(
          'Loaded ${newNotifications.length} more notifications (page $nextPage)',
        );
      },
      onFailure: (failure) {
        state = state.copyWith(
          error: _mapFailureToMessage(failure),
        );
        AppLogger.warning(
          'Failed to load more notifications: $failure',
        );
      },
    );
  }

  // ─── Mark As Read ──────────────────────────────────────────────────

  /// Marks a single notification as read by [id].
  Future<void> markAsRead(String id) async {
    // Optimistically update local state.
    final updatedNotifications = state.notifications
        .map((n) => n.id == id ? n.copyWith(isRead: true) : n)
        .toList();

    final previousUnreadCount = state.unreadCount;
    state = state.copyWith(
      notifications: updatedNotifications,
      unreadCount: previousUnreadCount > 0
          ? previousUnreadCount - 1
          : 0,
    );

    final result = await _markNotificationRead(notificationId: id);

    result.fold(
      onSuccess: (_) {
        AppLogger.info('Marked notification as read: $id');
      },
      onFailure: (failure) {
        // Revert optimistic update on failure.
        state = state.copyWith(
          notifications: state.notifications
              .map((n) => n.id == id ? n.copyWith(isRead: false) : n)
              .toList(),
          unreadCount: previousUnreadCount,
          error: _mapFailureToMessage(failure),
        );
        AppLogger.warning(
          'Failed to mark notification as read: $failure',
        );
      },
    );
  }

  // ─── Mark All As Read ──────────────────────────────────────────────

  /// Marks all notifications as read for the current student.
  Future<void> markAllAsRead() async {
    if (_studentId == null) return;

    // Optimistically update local state.
    final previousNotifications = state.notifications;
    final previousUnreadCount = state.unreadCount;

    final updatedNotifications = state.notifications
        .map((n) => n.copyWith(isRead: true))
        .toList();

    state = state.copyWith(
      notifications: updatedNotifications,
      unreadCount: 0,
    );

    final result = await _markAllNotificationsRead(
      studentId: _studentId!,
    );

    result.fold(
      onSuccess: (_) {
        AppLogger.info('Marked all notifications as read');
      },
      onFailure: (failure) {
        // Revert optimistic update on failure.
        state = state.copyWith(
          notifications: previousNotifications,
          unreadCount: previousUnreadCount,
          error: _mapFailureToMessage(failure),
        );
        AppLogger.warning(
          'Failed to mark all notifications as read: $failure',
        );
      },
    );
  }

  // ─── Clear Error ───────────────────────────────────────────────────

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
// STUDENT NOTIFICATION PROVIDER
// ═══════════════════════════════════════════════════════════════════════

/// Provides the [StudentNotificationNotifier] with all required use cases.
final studentNotificationProvider = StateNotifierProvider<
    StudentNotificationNotifier, StudentNotificationState>((ref) {
  return StudentNotificationNotifier(
    getNotifications: ref.watch(getNotificationsUseCaseProvider),
    markNotificationRead: ref.watch(markNotificationReadUseCaseProvider),
    markAllNotificationsRead:
        ref.watch(markAllNotificationsReadUseCaseProvider),
    studentId: ref.watch(currentStudentIdProvider),
  );
});
