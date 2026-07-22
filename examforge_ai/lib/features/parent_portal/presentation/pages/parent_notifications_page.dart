import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/themes/app_colors.dart';
import '../../../../core/themes/app_typography.dart';
import '../../../../core/themes/spacings.dart';
import '../../../../shared/widgets/app_app_bar.dart';
import '../../../../shared/widgets/app_empty_state.dart';
import '../../../../shared/widgets/app_error_state.dart';
import '../../../../shared/widgets/app_loading.dart';
import '../../domain/entities/parent_portal_entities.dart';
import '../providers/parent_notification_provider.dart';

// ═══════════════════════════════════════════════════════════════════════
// PARENT NOTIFICATIONS PAGE
// ═══════════════════════════════════════════════════════════════════════

/// Notifications page with filtering and batch actions.
///
/// Displays a filterable, dismissible list of notification cards with
/// category icons, unread indicators, time-ago stamps, and optional
/// action buttons. Supports pull-to-refresh, unread-only toggle,
/// and "Mark All Read" batch action.
///
/// Uses [ConsumerStatefulWidget] with a private [_State] class pattern,
/// loads data in [initState] via [WidgetsBinding.instance.addPostFrameCallback],
/// and renders a responsive layout using [Scaffold] with [AppAppBar].
class ParentNotificationsPage extends ConsumerStatefulWidget {
  const ParentNotificationsPage({super.key});

  @override
  ConsumerState<ParentNotificationsPage> createState() => _State();
}

class _State extends ConsumerState<ParentNotificationsPage> {
  // ─── State ──────────────────────────────────────────────────────────

  /// Whether to show unread notifications only.
  bool _showUnreadOnly = false;

  /// The currently selected category filter.
  String? _categoryFilter;

  /// Dismissed notification IDs (for local swipe-to-dismiss).
  final Set<String> _dismissedIds = {};

  // ─── Available filter chips.
  static const _filterChips = <_FilterChip>[
    _FilterChip(label: 'All', category: null),
    _FilterChip(label: 'Results', category: 'result'),
    _FilterChip(label: 'Attendance', category: 'attendance'),
    _FilterChip(label: 'Assignments', category: 'assignment'),
    _FilterChip(label: 'Announcements', category: 'announcement'),
    _FilterChip(label: 'Exams', category: 'exam'),
    _FilterChip(label: 'Messages', category: 'message'),
  ];

  // ─── Lifecycle ──────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(parentNotificationProvider.notifier).loadNotifications();
    });
  }

  // ─── Build ──────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final notificationState = ref.watch(parentNotificationProvider);

    return Scaffold(
      appBar: AppAppBar(
        title: 'Notifications',
        actions: [
          // Mark All Read
          if (notificationState.unreadCount > 0)
            TextButton(
              onPressed: () =>
                  ref.read(parentNotificationProvider.notifier).markAllAsRead(),
              child: Text(
                'Mark All Read',
                style: context.textTheme.labelMedium?.copyWith(
                  color: context.colorScheme.primary,
                  fontWeight: AppTypography.wSemiBold,
                ),
              ),
            ),
        ],
      ),
      body: _buildBody(context, notificationState),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // BODY
  // ═══════════════════════════════════════════════════════════════════════

  Widget _buildBody(BuildContext context, ParentNotificationState state) {
    // Loading state
    if (state.isLoading && state.notifications.isEmpty) {
      return _buildShimmerLoading(context);
    }

    // Error state
    if (state.error != null && state.notifications.isEmpty) {
      return AppErrorState.genericError(
        message: state.error,
        onRetry: () =>
            ref.read(parentNotificationProvider.notifier).loadNotifications(),
      );
    }

    final filteredNotifications = _filterNotifications(state.notifications);

    return Column(
      children: [
        // ─── Filter Chips ────────────────────────────────────────
        _buildFilterChips(context),

        // ─── Unread Only Toggle ──────────────────────────────────
        _buildUnreadToggle(context, state),

        // ─── Notifications List ──────────────────────────────────
        Expanded(
          child: filteredNotifications.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: () => ref
                      .read(parentNotificationProvider.notifier)
                      .loadNotifications(),
                  child: ListView.separated(
                    padding: const EdgeInsets.only(bottom: Spacings.xxl),
                    itemCount: filteredNotifications.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: Spacings.sm),
                    itemBuilder: (_, index) {
                      final notification = filteredNotifications[index];
                      return _buildDismissibleCard(
                        context,
                        notification,
                      );
                    },
                  ),
                ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // FILTER CHIPS
  // ═══════════════════════════════════════════════════════════════════════

  Widget _buildFilterChips(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(
          horizontal: Spacings.lg,
          vertical: Spacings.xs,
        ),
        children: _filterChips.map((chip) {
          final isSelected = _categoryFilter == chip.category;
          return Padding(
            padding: const EdgeInsets.only(right: Spacings.sm),
            child: FilterChip(
              label: Text(chip.label),
              selected: isSelected,
              onSelected: (_) {
                setState(() {
                  _categoryFilter =
                      isSelected ? null : chip.category;
                });
                ref
                    .read(parentNotificationProvider.notifier)
                    .setFilter(category: _categoryFilter);
              },
            ),
          );
        }).toList(),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // UNREAD ONLY TOGGLE
  // ═══════════════════════════════════════════════════════════════════════

  Widget _buildUnreadToggle(BuildContext context, ParentNotificationState state) {
    final cs = context.colorScheme;
    final tt = context.textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: Spacings.lg,
        vertical: Spacings.xs,
      ),
      child: Row(
        children: [
          Text(
            'Unread Only',
            style: tt.labelMedium?.copyWith(
              color: cs.onSurface,
              fontWeight: AppTypography.wMedium,
            ),
          ),
          const SizedBox(width: Spacings.sm),
          Switch(
            value: _showUnreadOnly,
            onChanged: (value) {
              setState(() => _showUnreadOnly = value);
              ref
                  .read(parentNotificationProvider.notifier)
                  .setFilter(isRead: value ? false : null);
            },
          ),
          const Spacer(),
          if (state.unreadCount > 0)
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: Spacings.sm,
                vertical: Spacings.xs,
              ),
              decoration: BoxDecoration(
                color: cs.primary,
                borderRadius: Spacings.borderRadiusFull,
              ),
              child: Text(
                '${state.unreadCount} unread',
                style: tt.labelSmall?.copyWith(
                  color: cs.onPrimary,
                  fontWeight: AppTypography.wSemiBold,
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // DISMISSIBLE NOTIFICATION CARD
  // ═══════════════════════════════════════════════════════════════════════

  Widget _buildDismissibleCard(
    BuildContext context,
    ParentNotificationEntity notification,
  ) {
    return Dismissible(
      key: ValueKey(notification.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) {
        setState(() => _dismissedIds.add(notification.id));
      },
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: Spacings.xl),
        color: AppColors.errorOf(context.colorScheme.brightness).withOpacity(0.1),
        child: Icon(
          Icons.archive_outlined,
          color: AppColors.errorOf(context.colorScheme.brightness),
        ),
      ),
      child: _buildNotificationCard(context, notification),
    );
  }

  // ─── Notification Card ──────────────────────────────────────────────

  Widget _buildNotificationCard(
    BuildContext context,
    ParentNotificationEntity notification,
  ) {
    final cs = context.colorScheme;
    final tt = context.textTheme;
    final isUnread = !notification.isRead;
    final categoryColor = _categoryColor(notification.category, cs.brightness);
    final categoryIcon = _categoryIcon(notification.category);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Spacings.lg),
      child: Card(
        elevation: Spacings.elevationNone,
        color: isUnread
            ? cs.primaryContainer.withOpacity(0.1)
            : cs.surfaceContainerLow,
        shape: RoundedRectangleBorder(
          borderRadius: Spacings.borderRadiusMd,
        ),
        child: InkWell(
          onTap: () {
            // Mark as read and navigate
            if (isUnread) {
              ref
                  .read(parentNotificationProvider.notifier)
                  .markAsRead(notification.id);
            }
            if (notification.actionUrl != null) {
              // TODO: Navigate to action URL
            }
          },
          borderRadius: Spacings.borderRadiusMd,
          child: Padding(
            padding: Spacings.paddingCard,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Unread indicator
                if (isUnread)
                  Container(
                    width: 8,
                    height: 8,
                    margin: const EdgeInsets.only(
                      top: Spacings.md,
                      right: Spacings.sm,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.infoOf(cs.brightness),
                      shape: BoxShape.circle,
                    ),
                  ),

                // Category icon
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: categoryColor.withOpacity(0.12),
                    borderRadius: Spacings.borderRadiusMd,
                  ),
                  child: Icon(
                    categoryIcon,
                    color: categoryColor,
                    size: Spacings.mdIcon,
                  ),
                ),
                const SizedBox(width: Spacings.md),

                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title
                      Text(
                        notification.title,
                        style: tt.titleSmall?.copyWith(
                          fontWeight: isUnread
                              ? AppTypography.wBold
                              : AppTypography.wSemiBold,
                          color: cs.onSurface,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: Spacings.xs),
                      // Body
                      Text(
                        notification.body,
                        style: tt.bodySmall?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: Spacings.sm),
                      // Time ago + action button row
                      Row(
                        children: [
                          Text(
                            _formatTimeAgo(notification.createdAt),
                            style: tt.labelSmall?.copyWith(
                              color: cs.onSurfaceVariant,
                            ),
                          ),
                          const Spacer(),
                          if (notification.actionLabel != null)
                            TextButton(
                              onPressed: () {
                                if (isUnread) {
                                  ref
                                      .read(parentNotificationProvider.notifier)
                                      .markAsRead(notification.id);
                                }
                                // TODO: Navigate to action
                              },
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: Spacings.sm,
                                ),
                                visualDensity: VisualDensity.compact,
                              ),
                              child: Text(
                                notification.actionLabel!,
                                style: tt.labelSmall?.copyWith(
                                  color: cs.primary,
                                  fontWeight: AppTypography.wSemiBold,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // SHIMMER LOADING
  // ═══════════════════════════════════════════════════════════════════════

  Widget _buildShimmerLoading(BuildContext context) {
    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      child: AppLoadingShimmer(
        child: Padding(
          padding: const EdgeInsets.all(Spacings.lg),
          child: Column(
            children: List.generate(
              6,
              (_) => Padding(
                padding: const EdgeInsets.only(bottom: Spacings.md),
                child: Row(
                  children: [
                    AppLoadingShimmer.box(
                      width: 40,
                      height: 40,
                      borderRadius: Spacings.borderRadiusMd,
                    ),
                    const SizedBox(width: Spacings.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AppLoadingShimmer.box(
                            width: 160,
                            height: 14,
                            borderRadius: Spacings.borderRadiusSm,
                          ),
                          const SizedBox(height: Spacings.sm),
                          AppLoadingShimmer.box(
                            height: 12,
                            borderRadius: Spacings.borderRadiusSm,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // EMPTY STATE
  // ═══════════════════════════════════════════════════════════════════════

  Widget _buildEmptyState() {
    final filterLabel = _categoryFilter != null
        ? _filterChips
            .firstWhere((c) => c.category == _categoryFilter)
            .label
        : 'All';

    if (_showUnreadOnly) {
      return AppEmptyState.noNotifications(
        title: 'No Unread Notifications',
        subtitle: 'You\'re all caught up! No unread $filterLabel notifications.',
      );
    }

    return AppEmptyState.noNotifications(
      title: 'No $filterLabel Notifications',
      subtitle: 'There are no $filterLabel notifications to display right now.',
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // FILTERING
  // ═══════════════════════════════════════════════════════════════════════

  /// Filters notifications by category, read status, and dismissed state.
  List<ParentNotificationEntity> _filterNotifications(
    List<ParentNotificationEntity> notifications,
  ) {
    return notifications.where((n) {
      // Skip dismissed
      if (_dismissedIds.contains(n.id)) return false;

      // Category filter
      if (_categoryFilter != null &&
          n.category.value != _categoryFilter) {
        return false;
      }

      // Unread only
      if (_showUnreadOnly && n.isRead) {
        return false;
      }

      return true;
    }).toList();
  }

  // ═══════════════════════════════════════════════════════════════════════
  // HELPER METHODS
  // ═══════════════════════════════════════════════════════════════════════

  /// Returns the colour for a notification category.
  Color _categoryColor(NotificationCategory category, Brightness brightness) {
    switch (category) {
      case NotificationCategory.result:
        return AppColors.successOf(brightness);
      case NotificationCategory.attendance:
        return AppColors.infoOf(brightness);
      case NotificationCategory.assignment:
        return AppColors.warningOf(brightness);
      case NotificationCategory.announcement:
        return const Color(0xFF7C3AED); // Purple
      case NotificationCategory.exam:
        return AppColors.errorOf(brightness);
      case NotificationCategory.message:
        return const Color(0xFF06B6D4); // Cyan
      case NotificationCategory.fee:
        return const Color(0xFFF97316); // Orange
      case NotificationCategory.general:
        return AppColors.infoOf(brightness);
    }
  }

  /// Returns the icon for a notification category.
  IconData _categoryIcon(NotificationCategory category) {
    switch (category) {
      case NotificationCategory.result:
        return Icons.bar_chart_outlined;
      case NotificationCategory.attendance:
        return Icons.calendar_today_outlined;
      case NotificationCategory.assignment:
        return Icons.assignment_outlined;
      case NotificationCategory.announcement:
        return Icons.campaign_outlined;
      case NotificationCategory.exam:
        return Icons.quiz_outlined;
      case NotificationCategory.message:
        return Icons.chat_outlined;
      case NotificationCategory.fee:
        return Icons.payment_outlined;
      case NotificationCategory.general:
        return Icons.notifications_outlined;
    }
  }

  /// Formats a [DateTime] as a relative time-ago string.
  String _formatTimeAgo(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);

    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
    if (diff.inHours < 24) return '${diff.inHours} hours ago';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays} days ago';
    const months = [
      '',
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[dt.month]} ${dt.day}, ${dt.year}';
  }
}

// ═══════════════════════════════════════════════════════════════════════
// PRIVATE HELPER CLASSES
// ═══════════════════════════════════════════════════════════════════════

/// A data holder for a filter chip entry.
class _FilterChip {
  const _FilterChip({
    required this.label,
    required this.category,
  });

  /// Display label for the chip.
  final String label;

  /// The category value to filter by, or `null` for "All".
  final String? category;
}
