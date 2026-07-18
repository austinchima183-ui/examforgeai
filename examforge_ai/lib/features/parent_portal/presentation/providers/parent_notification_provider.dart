import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/utils/logger.dart';
import '../../domain/entities/parent_portal_entities.dart';
import '../../domain/usecases/get_parent_notifications_usecase.dart';
import '../../domain/usecases/mark_notification_read_usecase.dart';

// ═══════════════════════════════════════════════════════════════════════
// PARENT NOTIFICATION STATE
// ═══════════════════════════════════════════════════════════════════════

/// Immutable state snapshot for the parent notification feature.
///
/// Tracks the notification list, loading flag, error message,
/// unread count, and active filters.
class ParentNotificationState {
  const ParentNotificationState({
    this.notifications = const [],
    this.isLoading = false,
    this.error,
    this.unreadCount = 0,
    this.categoryFilter,
    this.isReadFilter,
  });

  /// The list of parent notifications.
  final List<ParentNotificationEntity> notifications;

  /// Whether a load operation is in progress.
  final bool isLoading;

  /// The most recent error message, or `null`.
  final String? error;

  /// The number of unread notifications.
  final int unreadCount;

  /// The active category filter, or `null` for all categories.
  final String? categoryFilter;

  /// The active read-status filter, or `null` for all statuses.
  final bool? isReadFilter;

  /// Creates a copy of this state with the given fields replaced.
  ParentNotificationState copyWith({
    List<ParentNotificationEntity>? notifications,
    bool? isLoading,
    String? error,
    int? unreadCount,
    String? categoryFilter,
    bool? isReadFilter,
  }) {
    return ParentNotificationState(
      notifications: notifications ?? this.notifications,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      unreadCount: unreadCount ?? this.unreadCount,
      categoryFilter: categoryFilter ?? this.categoryFilter,
      isReadFilter: isReadFilter ?? this.isReadFilter,
    );
  }

  /// Clears the current error message.
  ParentNotificationState clearError() => copyWith(error: null);
}

// ═══════════════════════════════════════════════════════════════════════
// PARENT NOTIFICATION NOTIFIER
// ═══════════════════════════════════════════════════════════════════════

/// Riverpod [StateNotifier] that manages the parent notification feature's state.
///
/// All notification operations flow through this notifier, which:
/// 1. Sets [isLoading] before each async operation
/// 2. Delegates to the appropriate use case
/// 3. Updates notifications and unread count on success
/// 4. Sets [error] on failure
class ParentNotificationNotifier extends StateNotifier<ParentNotificationState> {
  ParentNotificationNotifier({
    required GetParentNotificationsUseCase getParentNotificationsUseCase,
    required MarkNotificationReadUseCase markNotificationReadUseCase,
  })  : _getParentNotificationsUseCase = getParentNotificationsUseCase,
        _markNotificationReadUseCase = markNotificationReadUseCase,
        super(const ParentNotificationState());

  final GetParentNotificationsUseCase _getParentNotificationsUseCase;
  final MarkNotificationReadUseCase _markNotificationReadUseCase;

  // ─── Load Notifications ────────────────────────────────────────────

  /// Loads notifications for the current parent using the active filters.
  Future<void> loadNotifications() async {
    state = state.copyWith(isLoading: true, error: null);

    final result = await _getParentNotificationsUseCase(
      GetParentNotificationsParams(
        category: state.categoryFilter,
        isRead: state.isReadFilter,
        page: 1,
        perPage: 50,
      ),
    );

    result.fold(
      onSuccess: (notifications) {
        final unreadCount =
            notifications.where((n) => !n.isRead).length;
        state = state.copyWith(
          isLoading: false,
          notifications: notifications,
          unreadCount: unreadCount,
          error: null,
        );
        AppLogger.info(
          'Parent notifications loaded (${notifications.length} items, $unreadCount unread)',
        );
      },
      onFailure: (failure) {
        state = state.copyWith(
          isLoading: false,
          error: _mapFailureToMessage(failure),
        );
        AppLogger.warning('Failed to load parent notifications: $failure');
      },
    );
  }

  // ─── Mark As Read ──────────────────────────────────────────────────

  /// Marks the specified [notificationId] as read.
  Future<void> markAsRead(String notificationId) async {
    final result = await _markNotificationReadUseCase(
      MarkNotificationReadParams(notificationId: notificationId),
    );

    result.fold(
      onSuccess: (_) {
        final updatedNotifications = state.notifications.map((n) {
          if (n.id == notificationId) {
            return n.copyWith(isRead: true);
          }
          return n;
        }).toList();
        final unreadCount =
            updatedNotifications.where((n) => !n.isRead).length;
        state = state.copyWith(
          notifications: updatedNotifications,
          unreadCount: unreadCount,
        );
        AppLogger.info('Parent notification marked as read: $notificationId');
      },
      onFailure: (failure) {
        state = state.copyWith(
          error: _mapFailureToMessage(failure),
        );
        AppLogger.warning('Failed to mark notification as read: $failure');
      },
    );
  }

  // ─── Mark All As Read ──────────────────────────────────────────────

  /// Marks all notifications as read.
  Future<void> markAllAsRead() async {
    final unreadIds =
        state.notifications.where((n) => !n.isRead).map((n) => n.id).toList();

    for (final id in unreadIds) {
      await _markNotificationReadUseCase(
        MarkNotificationReadParams(notificationId: id),
      );
    }

    final updatedNotifications = state.notifications.map((n) {
      return n.copyWith(isRead: true);
    }).toList();

    state = state.copyWith(
      notifications: updatedNotifications,
      unreadCount: 0,
    );
    AppLogger.info('All parent notifications marked as read');
  }

  // ─── Set Filter ────────────────────────────────────────────────────

  /// Updates the active filters and reloads notifications.
  Future<void> setFilter({String? category, bool? isRead}) async {
    state = state.copyWith(
      categoryFilter: category ?? state.categoryFilter,
      isReadFilter: isRead ?? state.isReadFilter,
    );
    await loadNotifications();
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
// PARENT NOTIFICATION PROVIDER
// ═══════════════════════════════════════════════════════════════════════

final parentNotificationProvider =
    StateNotifierProvider<ParentNotificationNotifier, ParentNotificationState>(
        (ref) {
  return ParentNotificationNotifier(
    getParentNotificationsUseCase:
        ref.watch(getParentNotificationsUseCaseProvider),
    markNotificationReadUseCase:
        ref.watch(markNotificationReadUseCaseProvider),
  );
});
