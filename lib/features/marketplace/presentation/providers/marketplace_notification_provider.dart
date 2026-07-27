import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../config/dependency_injection.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/utils/logger.dart';
import '../../domain/entities/marketplace_entities.dart';
import '../../domain/usecases/get_notifications_usecase.dart';
import '../../domain/usecases/mark_notification_read_usecase.dart';

// ═══════════════════════════════════════════════════════════════════════
// MARKETPLACE NOTIFICATION STATE
// ═══════════════════════════════════════════════════════════════════════

/// Immutable state snapshot for the marketplace notifications feature.
///
/// Tracks notifications, unread count, and loading/error states.
class MarketplaceNotificationState {
  const MarketplaceNotificationState({
    this.isLoading = false,
    this.error,
    this.notifications = const [],
    this.unreadCount = 0,
  });

  /// Whether an async operation is in progress.
  final bool isLoading;

  /// The most recent error message, or `null`.
  final String? error;

  /// The list of marketplace notifications.
  final List<MarketplaceNotificationEntity> notifications;

  /// The count of unread notifications.
  final int unreadCount;

  // ─── Computed Getters ────────────────────────────────────────────────

  /// Whether there are any notifications.
  bool get hasNotifications => notifications.isNotEmpty;

  /// Whether there are unread notifications.
  bool get hasUnread => unreadCount > 0;

  /// Creates a copy of this state with the given fields replaced.
  MarketplaceNotificationState copyWith({
    bool? isLoading,
    String? error,
    List<MarketplaceNotificationEntity>? notifications,
    int? unreadCount,
  }) {
    return MarketplaceNotificationState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      notifications: notifications ?? this.notifications,
      unreadCount: unreadCount ?? this.unreadCount,
    );
  }

  /// Clears the current error message.
  MarketplaceNotificationState clearError() => copyWith(error: null);

  /// Clears the current success message (no-op, included for consistency).
  MarketplaceNotificationState clearSuccess() => copyWith();
}

// ═══════════════════════════════════════════════════════════════════════
// MARKETPLACE NOTIFICATION NOTIFIER
// ═══════════════════════════════════════════════════════════════════════

/// Riverpod [StateNotifier] that manages the marketplace notification state.
///
/// Supports loading notifications, marking individual notifications as
/// read, and marking all notifications as read.
class MarketplaceNotificationNotifier
    extends StateNotifier<MarketplaceNotificationState> {
  MarketplaceNotificationNotifier({
    required GetNotificationsUseCase getNotificationsUseCase,
    required MarkNotificationReadUseCase markNotificationReadUseCase,
  })  : _getNotificationsUseCase = getNotificationsUseCase,
        _markNotificationReadUseCase = markNotificationReadUseCase,
        super(const MarketplaceNotificationState());

  final GetNotificationsUseCase _getNotificationsUseCase;
  final MarkNotificationReadUseCase _markNotificationReadUseCase;

  // ─── Load Notifications ─────────────────────────────────────────────

  /// Loads notifications for the given user.
  Future<void> loadNotifications({
    required String userId,
    bool unreadOnly = false,
    int limit = 20,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    final result = await _getNotificationsUseCase(
      GetNotificationsParams(
        userId: userId,
        unreadOnly: unreadOnly,
        limit: limit,
      ),
    );

    result.fold(
      onSuccess: (notifications) {
        final unread = notifications.where((n) => !n.isRead).length;
        state = state.copyWith(
          isLoading: false,
          notifications: notifications,
          unreadCount: unread,
        );
        AppLogger.info('Loaded ${notifications.length} notifications');
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

  // ─── Mark Read ──────────────────────────────────────────────────────

  /// Marks a single notification as read.
  Future<void> markRead({required String notificationId}) async {
    final result = await _markNotificationReadUseCase(
      MarkNotificationReadParams(notificationId: notificationId),
    );

    result.fold(
      onSuccess: (_) {
        state = state.copyWith(
          notifications: state.notifications
              .map((n) => n.id == notificationId
                  ? n.copyWith(isRead: true)
                  : n,)
              .toList(),
          unreadCount: state.unreadCount > 0
              ? state.unreadCount - 1
              : 0,
        );
        AppLogger.info('Notification marked as read: $notificationId');
      },
      onFailure: (failure) {
        state = state.copyWith(
          error: _mapFailureToMessage(failure),
        );
        AppLogger.warning('Failed to mark notification as read: $failure');
      },
    );
  }

  // ─── Mark All Read ──────────────────────────────────────────────────

  /// Marks all notifications as read.
  Future<void> markAllRead() async {
    // Mark each unread notification as read sequentially
    final unreadNotifications =
        state.notifications.where((n) => !n.isRead).toList();

    for (final notification in unreadNotifications) {
      await _markNotificationReadUseCase(
        MarkNotificationReadParams(notificationId: notification.id),
      );
    }

    state = state.copyWith(
      notifications: state.notifications
          .map((n) => n.copyWith(isRead: true))
          .toList(),
      unreadCount: 0,
    );
    AppLogger.info('All notifications marked as read');
  }

  // ─── Clear Error ────────────────────────────────────────────────────

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
// MARKETPLACE NOTIFICATION PROVIDER
// ═══════════════════════════════════════════════════════════════════════

/// Riverpod provider for the marketplace notification feature.
///
/// The factory accepts all required use cases via named parameters.
final marketplaceNotificationProvider = StateNotifierProvider<
    MarketplaceNotificationNotifier, MarketplaceNotificationState>(
  (ref) => MarketplaceNotificationNotifier(
    getNotificationsUseCase: ref.watch(getNotificationsUseCaseProvider),
    markNotificationReadUseCase:
        ref.watch(markNotificationReadUseCaseProvider),
  ),
);
