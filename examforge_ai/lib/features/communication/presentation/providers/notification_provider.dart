import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/utils/logger.dart';
import '../../domain/entities/communication_entities.dart';
import '../../domain/usecases/get_notification_preferences_usecase.dart';
import '../../domain/usecases/get_notifications_usecase.dart';
import '../../domain/usecases/mark_all_notifications_read_usecase.dart';
import '../../domain/usecases/mark_notification_read_usecase.dart';
import '../../domain/usecases/update_notification_preferences_usecase.dart';

// ═══════════════════════════════════════════════════════════════════════
// NOTIFICATION STATE
// ═══════════════════════════════════════════════════════════════════════

/// Immutable state snapshot for the notification feature.
///
/// Tracks notifications list, loading flag, error message,
/// unread count, and notification preferences.
class NotificationState {
  const NotificationState({
    this.notifications = const [],
    this.isLoading = false,
    this.error,
    this.unreadCount = 0,
    this.preferences,
  });

  /// The list of notifications for the current user.
  final List<CommunicationNotificationEntity> notifications;

  /// Whether a load operation is in progress.
  final bool isLoading;

  /// The most recent error message, or `null`.
  final String? error;

  /// The count of unread notifications.
  final int unreadCount;

  /// The user's notification preferences, or `null`.
  final NotificationPreferencesEntity? preferences;

  /// Creates a copy of this state with the given fields replaced.
  NotificationState copyWith({
    List<CommunicationNotificationEntity>? notifications,
    bool? isLoading,
    String? error,
    int? unreadCount,
    NotificationPreferencesEntity? preferences,
    bool clearPreferences = false,
  }) {
    return NotificationState(
      notifications: notifications ?? this.notifications,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      unreadCount: unreadCount ?? this.unreadCount,
      preferences: clearPreferences ? null : (preferences ?? this.preferences),
    );
  }

  /// Clears the current error message.
  NotificationState clearError() => copyWith(error: null);
}

// ═══════════════════════════════════════════════════════════════════════
// NOTIFICATION NOTIFIER
// ═══════════════════════════════════════════════════════════════════════

/// Riverpod [StateNotifier] that manages the notification feature's state.
///
/// All notification operations flow through this notifier, which:
/// 1. Sets the appropriate loading flag before each async operation
/// 2. Delegates to the relevant use case
/// 3. Updates notifications and metadata on success
/// 4. Sets [error] on failure
class NotificationNotifier extends StateNotifier<NotificationState> {
  NotificationNotifier({
    required GetNotificationsUseCase getNotificationsUseCase,
    required MarkNotificationReadUseCase markNotificationReadUseCase,
    required MarkAllNotificationsReadUseCase markAllNotificationsReadUseCase,
    required GetNotificationPreferencesUseCase getNotificationPreferencesUseCase,
    required UpdateNotificationPreferencesUseCase
        updateNotificationPreferencesUseCase,
  })  : _getNotificationsUseCase = getNotificationsUseCase,
        _markNotificationReadUseCase = markNotificationReadUseCase,
        _markAllNotificationsReadUseCase = markAllNotificationsReadUseCase,
        _getNotificationPreferencesUseCase = getNotificationPreferencesUseCase,
        _updateNotificationPreferencesUseCase =
            updateNotificationPreferencesUseCase,
        super(const NotificationState());

  final GetNotificationsUseCase _getNotificationsUseCase;
  final MarkNotificationReadUseCase _markNotificationReadUseCase;
  final MarkAllNotificationsReadUseCase _markAllNotificationsReadUseCase;
  final GetNotificationPreferencesUseCase _getNotificationPreferencesUseCase;
  final UpdateNotificationPreferencesUseCase
      _updateNotificationPreferencesUseCase;

  // ─── Load Notifications ─────────────────────────────────────────────

  /// Loads the notifications list with the provided [params].
  Future<void> loadNotifications(GetNotificationsParams params) async {
    state = state.copyWith(isLoading: true, error: null);

    final result = await _getNotificationsUseCase(params);

    result.fold(
      onSuccess: (notifications) {
        final unread = notifications.where((n) => !n.isRead).length;
        state = state.copyWith(
          isLoading: false,
          notifications: notifications,
          unreadCount: unread,
          error: null,
        );
        AppLogger.info(
          'Notifications loaded (${notifications.length} notifications, $unread unread)',
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

  // ─── Mark Read ─────────────────────────────────────────────────────

  /// Marks the notification with the given [id] as read.
  Future<void> markRead(String id) async {
    final result = await _markNotificationReadUseCase(
      MarkNotificationReadParams(notificationId: id),
    );

    result.fold(
      onSuccess: (_) {
        final updatedNotifications = state.notifications.map((n) {
          if (n.id == id) {
            return n.copyWith(isRead: true, readAt: DateTime.now());
          }
          return n;
        }).toList();
        final newUnreadCount =
            updatedNotifications.where((n) => !n.isRead).length;
        state = state.copyWith(
          notifications: updatedNotifications,
          unreadCount: newUnreadCount,
        );
        AppLogger.info('Notification marked as read: $id');
      },
      onFailure: (failure) {
        state = state.copyWith(
          error: _mapFailureToMessage(failure),
        );
        AppLogger.warning('Failed to mark notification as read: $failure');
      },
    );
  }

  // ─── Mark All Read ─────────────────────────────────────────────────

  /// Marks all notifications as read.
  Future<void> markAllRead() async {
    final result = await _markAllNotificationsReadUseCase();

    result.fold(
      onSuccess: (_) {
        final updatedNotifications = state.notifications.map((n) {
          return n.copyWith(isRead: true, readAt: DateTime.now());
        }).toList();
        state = state.copyWith(
          notifications: updatedNotifications,
          unreadCount: 0,
        );
        AppLogger.info('All notifications marked as read');
      },
      onFailure: (failure) {
        state = state.copyWith(
          error: _mapFailureToMessage(failure),
        );
        AppLogger.warning('Failed to mark all notifications as read: $failure');
      },
    );
  }

  // ─── Load Preferences ──────────────────────────────────────────────

  /// Loads the current user's notification preferences.
  Future<void> loadPreferences() async {
    state = state.copyWith(isLoading: true, error: null);

    final result = await _getNotificationPreferencesUseCase();

    result.fold(
      onSuccess: (preferences) {
        state = state.copyWith(
          isLoading: false,
          preferences: preferences,
          error: null,
        );
        AppLogger.info('Notification preferences loaded');
      },
      onFailure: (failure) {
        state = state.copyWith(
          isLoading: false,
          error: _mapFailureToMessage(failure),
        );
        AppLogger.warning('Failed to load notification preferences: $failure');
      },
    );
  }

  // ─── Update Preferences ────────────────────────────────────────────

  /// Updates the user's notification preferences with the given [prefs].
  Future<void> updatePreferences(
    Map<String, dynamic> prefs,
  ) async {
    state = state.copyWith(isLoading: true, error: null);

    final result = await _updateNotificationPreferencesUseCase(
      UpdateNotificationPreferencesParams(preferences: prefs),
    );

    result.fold(
      onSuccess: (preferences) {
        state = state.copyWith(
          isLoading: false,
          preferences: preferences,
          error: null,
        );
        AppLogger.info('Notification preferences updated');
      },
      onFailure: (failure) {
        state = state.copyWith(
          isLoading: false,
          error: _mapFailureToMessage(failure),
        );
        AppLogger.warning('Failed to update notification preferences: $failure');
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
// NOTIFICATION PROVIDER
// ═══════════════════════════════════════════════════════════════════════

final notificationProvider =
    StateNotifierProvider<NotificationNotifier, NotificationState>((ref) {
  return NotificationNotifier(
    getNotificationsUseCase: ref.watch(getNotificationsUseCaseProvider),
    markNotificationReadUseCase:
        ref.watch(markNotificationReadUseCaseProvider),
    markAllNotificationsReadUseCase:
        ref.watch(markAllNotificationsReadUseCaseProvider),
    getNotificationPreferencesUseCase:
        ref.watch(getNotificationPreferencesUseCaseProvider),
    updateNotificationPreferencesUseCase:
        ref.watch(updateNotificationPreferencesUseCaseProvider),
  );
});
