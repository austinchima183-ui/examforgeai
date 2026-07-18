import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/errors/failures.dart';
import '../../../../../core/utils/logger.dart';
import '../../domain/entities/billing_entities.dart';
import '../../domain/usecases/manage_billing_notifications_usecase.dart';

// ═══════════════════════════════════════════════════════════════════════
// BILLING NOTIFICATION STATE
// ═══════════════════════════════════════════════════════════════════════

/// Immutable state snapshot for the billing notification feature.
///
/// Tracks the list of billing notifications and loading/error states
/// for notification operations.
class BillingNotificationState {
  const BillingNotificationState({
    this.isLoading = false,
    this.notifications = const [],
    this.error,
  });

  /// Whether an async operation is in progress.
  final bool isLoading;

  /// The list of billing notifications.
  final List<BillingNotificationEntity> notifications;

  /// The most recent error message, or `null`.
  final String? error;

  /// The number of unread notifications.
  int get unreadCount =>
      notifications.where((n) => !n.isRead).length;

  /// Whether there are unread notifications.
  bool get hasUnread => unreadCount > 0;

  /// Creates a copy of this state with the given fields replaced.
  BillingNotificationState copyWith({
    bool? isLoading,
    List<BillingNotificationEntity>? notifications,
    String? error,
  }) {
    return BillingNotificationState(
      isLoading: isLoading ?? this.isLoading,
      notifications: notifications ?? this.notifications,
      error: error,
    );
  }

  /// Clears the current error message.
  BillingNotificationState clearError() => copyWith(error: null);
}

// ═══════════════════════════════════════════════════════════════════════
// BILLING NOTIFICATION NOTIFIER
// ═══════════════════════════════════════════════════════════════════════

/// Riverpod [StateNotifier] that manages the billing notification
/// feature's state.
///
/// Supports loading notifications, marking notifications as read,
/// and updating notification preferences.
class BillingNotificationNotifier
    extends StateNotifier<BillingNotificationState> {
  BillingNotificationNotifier({
    required GetBillingNotificationsUseCase
        getBillingNotificationsUseCase,
    required MarkNotificationReadUseCase markNotificationReadUseCase,
    required UpdateNotificationPreferencesUseCase
        updateNotificationPreferencesUseCase,
  })  : _getBillingNotificationsUseCase = getBillingNotificationsUseCase,
        _markNotificationReadUseCase = markNotificationReadUseCase,
        _updateNotificationPreferencesUseCase =
            updateNotificationPreferencesUseCase,
        super(const BillingNotificationState());

  final GetBillingNotificationsUseCase _getBillingNotificationsUseCase;
  final MarkNotificationReadUseCase _markNotificationReadUseCase;
  final UpdateNotificationPreferencesUseCase
      _updateNotificationPreferencesUseCase;

  // ─── Load Notifications ────────────────────────────────────────────

  /// Loads billing notifications for the given user.
  Future<void> loadNotifications({
    required String userId,
    required bool unreadOnly,
    required int page,
    required int perPage,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    final result = await _getBillingNotificationsUseCase(
      GetBillingNotificationsParams(
        userId: userId,
        unreadOnly: unreadOnly,
        page: page,
        perPage: perPage,
      ),
    );

    result.fold(
      onSuccess: (paginatedResult) {
        state = state.copyWith(
          isLoading: false,
          notifications: paginatedResult.items,
          error: null,
        );
        AppLogger.info(
          'Loaded ${paginatedResult.items.length} billing notifications',
        );
      },
      onFailure: (failure) {
        state = state.copyWith(
          isLoading: false,
          error: _mapFailureToMessage(failure),
        );
        AppLogger.warning(
          'Failed to load billing notifications: $failure',
        );
      },
    );
  }

  // ─── Mark As Read ──────────────────────────────────────────────────

  /// Marks a billing notification as read.
  Future<void> markAsRead({required String notificationId}) async {
    final result = await _markNotificationReadUseCase(
      MarkNotificationReadParams(notificationId: notificationId),
    );

    result.fold(
      onSuccess: (_) {
        final updatedNotifications = state.notifications
            .map((n) => n.id == notificationId
                ? BillingNotificationEntity(
                    id: n.id,
                    userId: n.userId,
                    schoolId: n.schoolId,
                    subscriptionId: n.subscriptionId,
                    transactionId: n.transactionId,
                    notificationType: n.notificationType,
                    title: n.title,
                    message: n.message,
                    inAppSent: n.inAppSent,
                    pushSent: n.pushSent,
                    emailSent: n.emailSent,
                    smsSent: n.smsSent,
                    isRead: true,
                    readAt: DateTime.now(),
                    scheduledAt: n.scheduledAt,
                    sentAt: n.sentAt,
                    metadata: n.metadata,
                    createdAt: n.createdAt,
                  )
                : n)
            .toList();
        state = state.copyWith(
          notifications: updatedNotifications,
          error: null,
        );
        AppLogger.info('Marked notification as read: $notificationId');
      },
      onFailure: (failure) {
        state = state.copyWith(
          error: _mapFailureToMessage(failure),
        );
        AppLogger.warning(
          'Failed to mark notification as read: $failure',
        );
      },
    );
  }

  // ─── Update Preferences ────────────────────────────────────────────

  /// Updates the notification preferences for a user.
  Future<void> updatePreferences({
    required String userId,
    required Map<String, bool> preferences,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    final result = await _updateNotificationPreferencesUseCase(
      UpdateNotificationPreferencesParams(
        userId: userId,
        preferences: preferences,
      ),
    );

    result.fold(
      onSuccess: (_) {
        state = state.copyWith(
          isLoading: false,
          error: null,
        );
        AppLogger.info(
          'Updated notification preferences for user: $userId',
        );
      },
      onFailure: (failure) {
        state = state.copyWith(
          isLoading: false,
          error: _mapFailureToMessage(failure),
        );
        AppLogger.warning(
          'Failed to update notification preferences: $failure',
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
// BILLING NOTIFICATION PROVIDER
// ═══════════════════════════════════════════════════════════════════════

/// Riverpod provider for the billing notification feature.
///
/// The factory accepts all required use cases via named parameters.
final billingNotificationProvider = StateNotifierProvider<
    BillingNotificationNotifier, BillingNotificationState>(
  (ref) => BillingNotificationNotifier(
    getBillingNotificationsUseCase:
        ref.watch(getBillingNotificationsUseCaseProvider),
    markNotificationReadUseCase:
        ref.watch(markNotificationReadUseCaseProvider),
    updateNotificationPreferencesUseCase:
        ref.watch(updateNotificationPreferencesUseCaseProvider),
  ),
);
