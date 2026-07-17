import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/logger.dart';

// ═══════════════════════════════════════════════════════════════════════
// NOTIFICATION MODEL
// ═══════════════════════════════════════════════════════════════════════

/// Type of notification for categorization and filtering.
enum NotificationType {
  exam('exam'),
  system('system'),
  result('result'),
  reminder('reminder');

  const NotificationType(this.value);

  final String value;

  static NotificationType fromString(String? value) {
    if (value == null) return NotificationType.system;
    return NotificationType.values.cast<NotificationType?>().firstWhere(
          (type) => type?.value == value,
          orElse: () => NotificationType.system,
        );
  }
}

/// Represents a single notification item.
class NotificationItem extends Equatable {
  const NotificationItem({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.createdAt,
    this.isRead = false,
    this.icon,
  });

  /// Unique identifier.
  final String id;

  /// Notification title.
  final String title;

  /// Notification message / body.
  final String message;

  /// Category type.
  final NotificationType type;

  /// When the notification was created.
  final DateTime createdAt;

  /// Whether the notification has been read.
  final bool isRead;

  /// Optional custom icon code point.
  final int? icon;

  @override
  List<Object?> get props => [id, title, message, type, createdAt, isRead, icon];

  NotificationItem copyWith({
    String? id,
    String? title,
    String? message,
    NotificationType? type,
    DateTime? createdAt,
    bool? isRead,
    int? icon,
  }) {
    return NotificationItem(
      id: id ?? this.id,
      title: title ?? this.title,
      message: message ?? this.message,
      type: type ?? this.type,
      createdAt: createdAt ?? this.createdAt,
      isRead: isRead ?? this.isRead,
      icon: icon ?? this.icon,
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// NOTIFICATION FILTER
// ═══════════════════════════════════════════════════════════════════════

/// Filter options for the notifications list.
enum NotificationFilter {
  all('All'),
  unread('Unread'),
  exam('Exams'),
  system('System');

  const NotificationFilter(this.label);

  final String label;

  /// Whether a notification matches this filter.
  bool matches(NotificationItem item) {
    return switch (this) {
      NotificationFilter.all => true,
      NotificationFilter.unread => !item.isRead,
      NotificationFilter.exam => item.type == NotificationType.exam || item.type == NotificationType.result || item.type == NotificationType.reminder,
      NotificationFilter.system => item.type == NotificationType.system,
    };
  }
}

// ═══════════════════════════════════════════════════════════════════════
// NOTIFICATION STATE
// ═══════════════════════════════════════════════════════════════════════

/// Immutable state snapshot for the notifications feature.
class NotificationState {
  const NotificationState({
    this.notifications = const [],
    this.isLoading = false,
    this.error,
    this.filter = NotificationFilter.all,
  });

  /// The full list of notifications (before filtering).
  final List<NotificationItem> notifications;

  /// Whether notifications are being loaded.
  final bool isLoading;

  /// The most recent error message, or `null`.
  final String? error;

  /// The currently selected filter.
  final NotificationFilter filter;

  /// Notifications filtered by the current [filter].
  List<NotificationItem> get filteredNotifications =>
      notifications.where((n) => filter.matches(n)).toList();

  /// Count of unread notifications.
  int get unreadCount =>
      notifications.where((n) => !n.isRead).length;

  /// Whether there are no notifications at all.
  bool get isEmpty => notifications.isEmpty;

  /// Whether there are no notifications matching the current filter.
  bool get isFilterEmpty => filteredNotifications.isEmpty;

  /// Creates a copy of this state with the given fields replaced.
  NotificationState copyWith({
    List<NotificationItem>? notifications,
    bool? isLoading,
    String? error,
    NotificationFilter? filter,
  }) {
    return NotificationState(
      notifications: notifications ?? this.notifications,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      filter: filter ?? this.filter,
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// NOTIFICATION NOTIFIER
// ═══════════════════════════════════════════════════════════════════════

/// Riverpod [StateNotifier] that manages the notifications feature's state.
///
/// In production, this would fetch notifications from the backend.
/// For now, it uses mock data to demonstrate the full UI flow.
class NotificationNotifier extends StateNotifier<NotificationState> {
  NotificationNotifier() : super(const NotificationState()) {
    _loadNotifications();
  }

  // ─── Load Notifications ──────────────────────────────────────────

  /// Loads notifications from the backend (mock data for now).
  Future<void> _loadNotifications() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      // Simulate network delay
      await Future.delayed(const Duration(milliseconds: 800));

      final now = DateTime.now();
      final mockNotifications = [
        NotificationItem(
          id: '1',
          title: 'Exam Coming Up',
          message:
              'Your Mathematics Mid-Term exam is scheduled for tomorrow at 9:00 AM. Make sure to prepare!',
          type: NotificationType.reminder,
          createdAt: now.subtract(const Duration(minutes: 15)),
          isRead: false,
        ),
        NotificationItem(
          id: '2',
          title: 'Exam Results Available',
          message:
              'Your Physics Final Exam results are now available. You scored 87/100.',
          type: NotificationType.result,
          createdAt: now.subtract(const Duration(hours: 2)),
          isRead: false,
        ),
        NotificationItem(
          id: '3',
          title: 'New Question Bank Added',
          message:
              'A new question bank "Chemistry 101" has been added to your school\'s resources.',
          type: NotificationType.exam,
          createdAt: now.subtract(const Duration(hours: 5)),
          isRead: true,
        ),
        NotificationItem(
          id: '4',
          title: 'System Maintenance',
          message:
              'Scheduled maintenance on March 15th from 2:00 AM to 4:00 AM UTC. Service may be briefly unavailable.',
          type: NotificationType.system,
          createdAt: now.subtract(const Duration(days: 1)),
          isRead: true,
        ),
        NotificationItem(
          id: '5',
          title: 'Exam Created Successfully',
          message:
              'Your CBT exam "Biology Chapter 5 Quiz" has been created and is ready for students.',
          type: NotificationType.exam,
          createdAt: now.subtract(const Duration(days: 1, hours: 3)),
          isRead: true,
        ),
        NotificationItem(
          id: '6',
          title: 'Password Changed',
          message:
              'Your account password was changed successfully. If this wasn\'t you, contact support immediately.',
          type: NotificationType.system,
          createdAt: now.subtract(const Duration(days: 2)),
          isRead: true,
        ),
        NotificationItem(
          id: '7',
          title: 'Exam Reminder',
          message:
              'English Literature exam starts in 30 minutes. Please join the exam room on time.',
          type: NotificationType.reminder,
          createdAt: now.subtract(const Duration(days: 3)),
          isRead: true,
        ),
      ];

      state = state.copyWith(
        notifications: mockNotifications,
        isLoading: false,
        error: null,
      );

      AppLogger.info('Loaded ${mockNotifications.length} notifications');
    } catch (e) {
      AppLogger.error('Failed to load notifications', error: e);
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load notifications. Please try again.',
      );
    }
  }

  // ─── Refresh ─────────────────────────────────────────────────────

  /// Refreshes the notifications list from the backend.
  Future<void> refresh() async {
    await _loadNotifications();
  }

  // ─── Mark as Read ────────────────────────────────────────────────

  /// Marks a single notification as read by its [notificationId].
  void markAsRead(String notificationId) {
    final updated = state.notifications.map((n) {
      if (n.id == notificationId) {
        return n.copyWith(isRead: true);
      }
      return n;
    }).toList();

    state = state.copyWith(notifications: updated);
    AppLogger.debug('Notification marked as read: $notificationId');
  }

  // ─── Mark All as Read ────────────────────────────────────────────

  /// Marks all notifications as read.
  void markAllAsRead() {
    final updated = state.notifications.map((n) {
      return n.copyWith(isRead: true);
    }).toList();

    state = state.copyWith(notifications: updated);
    AppLogger.info('All notifications marked as read');
  }

  // ─── Delete Notification ─────────────────────────────────────────

  /// Deletes a single notification by its [notificationId].
  void deleteNotification(String notificationId) {
    final updated = state.notifications
        .where((n) => n.id != notificationId)
        .toList();

    state = state.copyWith(notifications: updated);
    AppLogger.info('Notification deleted: $notificationId');
  }

  // ─── Filter ──────────────────────────────────────────────────────

  /// Sets the current filter for the notifications list.
  void setFilter(NotificationFilter filter) {
    state = state.copyWith(filter: filter);
    AppLogger.debug('Notification filter set to: ${filter.label}');
  }

  // ─── Clear Error ─────────────────────────────────────────────────

  /// Clears the current error message.
  void clearError() {
    state = state.copyWith(error: null);
  }
}

// ═══════════════════════════════════════════════════════════════════════
// PROVIDERS
// ═══════════════════════════════════════════════════════════════════════

/// Provider that holds the current [NotificationState].
final notificationProvider =
    StateNotifierProvider<NotificationNotifier, NotificationState>(
  (ref) => NotificationNotifier(),
);

/// Convenience provider that watches the unread count.
final notificationUnreadCountProvider = Provider<int>((ref) {
  return ref.watch(notificationProvider).unreadCount;
});

/// Convenience provider that watches the current filter.
final notificationFilterProvider = Provider<NotificationFilter>((ref) {
  return ref.watch(notificationProvider).filter;
});
