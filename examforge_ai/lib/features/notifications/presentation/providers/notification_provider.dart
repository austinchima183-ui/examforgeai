import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;

import '../../../../config/dependency_injection.dart';
import '../../../../core/utils/logger.dart';
import '../../../../shared/providers/auth_state_provider.dart';

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

  static NotificationType? fromString(String? value) {
    if (value == null) return null;
    // Try exact match first.
    final exact = NotificationType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => NotificationType.system,
    );
    if (exact.value == value) return exact;

    // Map the granular exam-notification types from the backend
    // (e.g. 'exam_published', 'exam_started', 'results_released')
    // to the broader categories used in the UI.
    final lower = value.toLowerCase();
    if (lower.contains('exam') || lower.contains('cbt')) {
      return NotificationType.exam;
    }
    if (lower.contains('result') || lower.contains('score') || lower.contains('grade')) {
      return NotificationType.result;
    }
    if (lower.contains('remind') || lower.contains('warning') || lower.contains('time')) {
      return NotificationType.reminder;
    }
    return NotificationType.system;
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
    this.rawType,
    this.extraData,
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

  /// The raw type string from the database (e.g. 'exam_published').
  final String? rawType;

  /// Extra data payload from the database (e.g. exam_id).
  final Map<String, dynamic>? extraData;

  @override
  List<Object?> get props => [id, title, message, type, createdAt, isRead, icon, rawType, extraData];

  NotificationItem copyWith({
    String? id,
    String? title,
    String? message,
    NotificationType? type,
    DateTime? createdAt,
    bool? isRead,
    int? icon,
    String? rawType,
    Map<String, dynamic>? extraData,
  }) {
    return NotificationItem(
      id: id ?? this.id,
      title: title ?? this.title,
      message: message ?? this.message,
      type: type ?? this.type,
      createdAt: createdAt ?? this.createdAt,
      isRead: isRead ?? this.isRead,
      icon: icon ?? this.icon,
      rawType: rawType ?? this.rawType,
      extraData: extraData ?? this.extraData,
    );
  }

  /// Creates a [NotificationItem] from a Supabase row map.
  ///
  /// Expected row schema:
  /// ```
  /// id          UUID
  /// user_id     UUID
  /// type        TEXT
  /// title       TEXT
  /// body        TEXT
  /// data        JSONB
  /// is_read     BOOLEAN
  /// created_at  TIMESTAMPTZ
  /// ```
  factory NotificationItem.fromJson(Map<String, dynamic> json) {
    return NotificationItem(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      message: json['body'] as String? ?? '',
      type: NotificationType.fromString(json['type'] as String?) ?? NotificationType.system,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      isRead: json['is_read'] as bool? ?? false,
      rawType: json['type'] as String?,
      extraData: json['data'] as Map<String, dynamic>?,
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
    this.hasMore = true,
  });

  /// The full list of notifications (before filtering).
  final List<NotificationItem> notifications;

  /// Whether notifications are being loaded.
  final bool isLoading;

  /// The most recent error message, or `null`.
  final String? error;

  /// The currently selected filter.
  final NotificationFilter filter;

  /// Whether more notifications can be loaded via pagination.
  final bool hasMore;

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
    bool? hasMore,
  }) {
    return NotificationState(
      notifications: notifications ?? this.notifications,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      filter: filter ?? this.filter,
      hasMore: hasMore ?? this.hasMore,
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// NOTIFICATION NOTIFIER
// ═══════════════════════════════════════════════════════════════════════

/// Riverpod [StateNotifier] that manages the notifications feature's state.
///
/// Fetches notifications from the `notifications` table in Supabase,
/// subscribes to real-time changes, and supports pagination, mark-as-read,
/// and delete operations.
class NotificationNotifier extends StateNotifier<NotificationState> {
  NotificationNotifier({
    required sb.SupabaseClient supabaseClient,
    required String userId,
  })  : _supabase = supabaseClient,
        _userId = userId,
        super(const NotificationState()) {
    _loadNotifications();
    _subscribeToRealtimeChanges();
  }

  final sb.SupabaseClient _supabase;
  final String _userId;

  // ─── Constants ─────────────────────────────────────────────────────

  static const _notificationsTable = 'notifications';
  static const _defaultPageSize = 20;

  // ─── Realtime subscription ─────────────────────────────────────────

  sb.RealtimeChannel? _realtimeChannel;

  // ─── Pagination tracking ───────────────────────────────────────────

  int _currentOffset = 0;

  // ─── Load Notifications ───────────────────────────────────────────

  /// Loads the first page of notifications from Supabase.
  Future<void> _loadNotifications() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      _currentOffset = 0;

      final response = await _supabase
          .from(_notificationsTable)
          .select()
          .eq('user_id', _userId)
          .order('created_at', ascending: false)
          .range(0, _defaultPageSize - 1);

      final notifications = (response as List<dynamic>)
          .map((row) => NotificationItem.fromJson(row as Map<String, dynamic>))
          .toList();

      _currentOffset = notifications.length;

      // If we got fewer than the page size, there are no more pages.
      final hasMore = notifications.length >= _defaultPageSize;

      state = state.copyWith(
        notifications: notifications,
        isLoading: false,
        error: null,
        hasMore: hasMore,
      );

      AppLogger.info('Loaded ${notifications.length} notifications for user $_userId');
    } on sb.PostgrestException catch (e) {
      AppLogger.error('Failed to load notifications (PostgrestException)', error: e);
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load notifications. Please try again.',
      );
    } catch (e) {
      AppLogger.error('Failed to load notifications', error: e);
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load notifications. Please try again.',
      );
    }
  }

  /// Loads the next page of notifications and appends them to the list.
  Future<void> loadMore() async {
    if (state.isLoading || !state.hasMore) return;

    try {
      final response = await _supabase
          .from(_notificationsTable)
          .select()
          .eq('user_id', _userId)
          .order('created_at', ascending: false)
          .range(_currentOffset, _currentOffset + _defaultPageSize - 1);

      final newNotifications = (response as List<dynamic>)
          .map((row) => NotificationItem.fromJson(row as Map<String, dynamic>))
          .toList();

      _currentOffset += newNotifications.length;

      final hasMore = newNotifications.length >= _defaultPageSize;

      state = state.copyWith(
        notifications: [...state.notifications, ...newNotifications],
        hasMore: hasMore,
      );

      AppLogger.info('Loaded ${newNotifications.length} more notifications (total: ${state.notifications.length})');
    } on sb.PostgrestException catch (e) {
      AppLogger.error('Failed to load more notifications (PostgrestException)', error: e);
      state = state.copyWith(
        error: 'Failed to load more notifications.',
      );
    } catch (e) {
      AppLogger.error('Failed to load more notifications', error: e);
      state = state.copyWith(
        error: 'Failed to load more notifications.',
      );
    }
  }

  // ─── Realtime Subscription ────────────────────────────────────────

  /// Subscribes to Supabase Realtime changes on the `notifications` table
  /// filtered by the current user's ID.
  void _subscribeToRealtimeChanges() {
    try {
      _realtimeChannel = _supabase.channel('notifications_realtime_$_userId');

      _realtimeChannel!.onPostgresChanges(
        event: sb.PostgresChangeEvent.insert,
        schema: 'public',
        table: _notificationsTable,
        filter: sb.PostgresChangeFilter(
          type: sb.PostgresChangeFilterType.eq,
          column: 'user_id',
          value: _userId,
        ),
        callback: (payload) {
          final newRow = payload.newRecord;
          final notification = NotificationItem.fromJson(newRow);
          // Prepend the new notification (newest first).
          state = state.copyWith(
            notifications: [notification, ...state.notifications],
          );
          AppLogger.debug('Realtime: new notification received — ${notification.id}');
        },
      );

      _realtimeChannel!.onPostgresChanges(
        event: sb.PostgresChangeEvent.update,
        schema: 'public',
        table: _notificationsTable,
        filter: sb.PostgresChangeFilter(
          type: sb.PostgresChangeFilterType.eq,
          column: 'user_id',
          value: _userId,
        ),
        callback: (payload) {
          final updatedRow = payload.newRecord;
          final updatedNotification = NotificationItem.fromJson(updatedRow);
          final updatedList = state.notifications.map((n) {
            if (n.id == updatedNotification.id) {
              return updatedNotification;
            }
            return n;
          }).toList();
          state = state.copyWith(notifications: updatedList);
          AppLogger.debug('Realtime: notification updated — ${updatedNotification.id}');
        },
      );

      _realtimeChannel!.onPostgresChanges(
        event: sb.PostgresChangeEvent.delete,
        schema: 'public',
        table: _notificationsTable,
        filter: sb.PostgresChangeFilter(
          type: sb.PostgresChangeFilterType.eq,
          column: 'user_id',
          value: _userId,
        ),
        callback: (payload) {
          final deletedId = payload.oldRecord['id'] as String?;
          if (deletedId != null) {
            final updatedList = state.notifications
                .where((n) => n.id != deletedId)
                .toList();
            state = state.copyWith(notifications: updatedList);
            AppLogger.debug('Realtime: notification deleted — $deletedId');
          }
        },
      );

      _realtimeChannel!.subscribe();

      AppLogger.info('Subscribed to realtime notifications for user $_userId');
    } catch (e) {
      AppLogger.error('Failed to subscribe to realtime notifications', error: e);
      // Non-fatal — the app can still function without realtime.
    }
  }

  // ─── Refresh ─────────────────────────────────────────────────────

  /// Refreshes the notifications list from Supabase.
  Future<void> refresh() async {
    await _loadNotifications();
  }

  // ─── Mark as Read ────────────────────────────────────────────────

  /// Marks a single notification as read by its [notificationId].
  ///
  /// Optimistically updates local state, then persists to Supabase.
  Future<void> markAsRead(String notificationId) async {
    // Optimistic update.
    final updated = state.notifications.map((n) {
      if (n.id == notificationId) {
        return n.copyWith(isRead: true);
      }
      return n;
    }).toList();

    state = state.copyWith(notifications: updated);

    try {
      await _supabase
          .from(_notificationsTable)
          .update({'is_read': true})
          .eq('id', notificationId)
          .eq('user_id', _userId);

      AppLogger.debug('Notification marked as read: $notificationId');
    } on sb.PostgrestException catch (e) {
      AppLogger.error('Failed to mark notification as read (PostgrestException)', error: e);
      _revertMarkAsRead(notificationId);
    } catch (e) {
      AppLogger.error('Failed to mark notification as read', error: e);
      _revertMarkAsRead(notificationId);
    }
  }

  /// Reverts an optimistic mark-as-read on failure.
  void _revertMarkAsRead(String notificationId) {
    final reverted = state.notifications.map((n) {
      if (n.id == notificationId) {
        return n.copyWith(isRead: false);
      }
      return n;
    }).toList();
    state = state.copyWith(
      notifications: reverted,
      error: 'Failed to mark notification as read.',
    );
  }

  // ─── Mark All as Read ────────────────────────────────────────────

  /// Marks all notifications as read.
  ///
  /// Optimistically updates local state, then persists to Supabase.
  Future<void> markAllAsRead() async {
    final unreadIds = state.notifications
        .where((n) => !n.isRead)
        .map((n) => n.id)
        .toList();

    if (unreadIds.isEmpty) return;

    // Optimistic update.
    final updated = state.notifications.map((n) {
      return n.copyWith(isRead: true);
    }).toList();

    state = state.copyWith(notifications: updated);

    try {
      await _supabase
          .from(_notificationsTable)
          .update({'is_read': true})
          .eq('user_id', _userId)
          .inFilter('id', unreadIds);

      AppLogger.info('All notifications marked as read');
    } on sb.PostgrestException catch (e) {
      AppLogger.error('Failed to mark all as read (PostgrestException)', error: e);
      _loadNotifications(); // Re-fetch to get correct state
    } catch (e) {
      AppLogger.error('Failed to mark all as read', error: e);
      _loadNotifications(); // Re-fetch to get correct state
    }
  }

  // ─── Delete Notification ─────────────────────────────────────────

  /// Deletes a single notification by its [notificationId].
  ///
  /// Optimistically removes from local state, then deletes from Supabase.
  Future<void> deleteNotification(String notificationId) async {
    // Store the removed item for potential revert.
    final removedItem = state.notifications.firstWhere(
      (n) => n.id == notificationId,
      orElse: () => throw StateError('Notification not found'),
    );

    // Optimistic update.
    final updated = state.notifications
        .where((n) => n.id != notificationId)
        .toList();
    state = state.copyWith(notifications: updated);

    try {
      await _supabase
          .from(_notificationsTable)
          .delete()
          .eq('id', notificationId)
          .eq('user_id', _userId);

      AppLogger.info('Notification deleted: $notificationId');
    } on sb.PostgrestException catch (e) {
      AppLogger.error('Failed to delete notification (PostgrestException)', error: e);
      _revertDelete(removedItem);
    } catch (e) {
      AppLogger.error('Failed to delete notification', error: e);
      _revertDelete(removedItem);
    }
  }

  /// Reverts an optimistic delete on failure.
  void _revertDelete(NotificationItem removedItem) {
    final reverted = [...state.notifications, removedItem]
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    state = state.copyWith(
      notifications: reverted,
      error: 'Failed to delete notification.',
    );
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

  // ─── Dispose ─────────────────────────────────────────────────────

  @override
  void dispose() {
    _disposeRealtimeChannel();
    super.dispose();
  }

  /// Unsubscribes from the Supabase Realtime channel.
  Future<void> _disposeRealtimeChannel() async {
    if (_realtimeChannel != null) {
      try {
        await _supabase.removeChannel(_realtimeChannel!);
        AppLogger.info('Unsubscribed from realtime notifications channel');
      } catch (e) {
        AppLogger.error('Failed to unsubscribe from realtime channel', error: e);
      }
      _realtimeChannel = null;
    }
  }
}

// ═══════════════════════════════════════════════════════════════════════
// PROVIDERS
// ═══════════════════════════════════════════════════════════════════════

/// Provider that holds the current [NotificationState].
///
/// Reads the [supabaseClientProvider] and [userIdProvider] to construct
/// the [NotificationNotifier] with the correct dependencies.
final notificationProvider =
    StateNotifierProvider<NotificationNotifier, NotificationState>(
  (ref) {
    final supabaseClient = ref.watch(supabaseClientProvider);
    final userId = ref.watch(userIdProvider);

    // If there is no authenticated user, return a notifier with an empty
    // state that won't attempt to fetch or subscribe.
    if (userId == null) {
      return NotificationNotifier(
        supabaseClient: supabaseClient,
        userId: '__no_user__',
      );
    }

    return NotificationNotifier(
      supabaseClient: supabaseClient,
      userId: userId,
    );
  },
);

/// Convenience provider that watches the unread count.
final notificationUnreadCountProvider = Provider<int>((ref) {
  return ref.watch(notificationProvider).unreadCount;
});

/// Convenience provider that watches the current filter.
final notificationFilterProvider = Provider<NotificationFilter>((ref) {
  return ref.watch(notificationProvider).filter;
});
