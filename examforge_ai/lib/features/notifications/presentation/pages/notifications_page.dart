import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/themes/app_colors.dart';
import '../../../../core/themes/app_typography.dart';
import '../../../../core/themes/spacings.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../shared/widgets/widgets.dart';
import 'providers/notification_provider.dart';
import 'widgets/notification_item.dart';

// ═══════════════════════════════════════════════════════════════════════
// NOTIFICATIONS PAGE
// ═══════════════════════════════════════════════════════════════════════

/// Notifications page with filter tabs, notification list, pull-to-refresh,
/// mark-all-as-read, and empty state handling.
class NotificationsPage extends ConsumerWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = context.colorScheme;
    final tt = context.textTheme;
    final notificationState = ref.watch(notificationProvider);
    final unreadCount = notificationState.unreadCount;

    return Scaffold(
      appBar: AppAppBar(
        title: 'Notifications',
        actions: [
          if (unreadCount > 0)
            TextButton(
              onPressed: () {
                ref.read(notificationProvider.notifier).markAllAsRead();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('All notifications marked as read'),
                    backgroundColor: AppColors.success,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(Spacings.smRadius),
                    ),
                    duration: const Duration(seconds: 2),
                  ),
                );
              },
              child: Text(
                'Mark all read',
                style: tt.labelLarge?.copyWith(
                  color: cs.primary,
                ),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          // ── Filter Tabs ───────────────────────────────────────────
          _FilterTabs(
            currentFilter: notificationState.filter,
            onFilterChanged: (filter) {
              ref.read(notificationProvider.notifier).setFilter(filter);
            },
            unreadCount: unreadCount,
          ),

          // ── Content ──────────────────────────────────────────────
          Expanded(
            child: _buildContent(context, ref, notificationState),
          ),
        ],
      ),
    );
  }

  // ─── Content Builder ─────────────────────────────────────────────

  Widget _buildContent(
    BuildContext context,
    WidgetRef ref,
    NotificationState state,
  ) {
    // Loading state
    if (state.isLoading) {
      return const Center(
        child: AppLoadingSpinner(size: AppLoadingSpinnerSize.large),
      );
    }

    // Error state
    if (state.error != null) {
      return AppErrorState(
        icon: Icons.error_outline_rounded,
        title: 'Failed to Load',
        message: state.error,
        onRetry: () => ref.read(notificationProvider.notifier).refresh(),
      );
    }

    // Empty state (no notifications at all)
    if (state.isEmpty) {
      return AppEmptyState.noNotifications(
        title: 'No Notifications',
        subtitle: 'You\'ll see exam reminders, results, and updates here.',
      );
    }

    // Empty filter state
    if (state.isFilterEmpty) {
      return AppEmptyState.noResults(
        title: 'No ${state.filter.label} Notifications',
        subtitle: 'Try a different filter to see more notifications.',
        actionLabel: 'Show All',
        onAction: () {
          ref
              .read(notificationProvider.notifier)
              .setFilter(NotificationFilter.all);
        },
      );
    }

    // Notification list with pull-to-refresh
    return RefreshIndicator(
      color: context.colorScheme.primary,
      onRefresh: () => ref.read(notificationProvider.notifier).refresh(),
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(
          horizontal: Spacings.lg,
          vertical: Spacings.md,
        ),
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: state.filteredNotifications.length,
        separatorBuilder: (_, __) => const SizedBox(height: Spacings.sm),
        itemBuilder: (context, index) {
          final notification = state.filteredNotifications[index];
          return NotificationItemWidget(
            notification: notification,
            onTap: () {
              if (!notification.isRead) {
                ref
                    .read(notificationProvider.notifier)
                    .markAsRead(notification.id);
              }
              // In production, navigate to the relevant detail page
              // based on notification type
            },
            onDismiss: () {
              ref
                  .read(notificationProvider.notifier)
                  .deleteNotification(notification.id);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Notification dismissed'),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(Spacings.smRadius),
                  ),
                  duration: const Duration(seconds: 2),
                  action: SnackBarAction(
                    label: 'Undo',
                    onPressed: () {
                      // In production, restore the notification
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// FILTER TABS
// ═══════════════════════════════════════════════════════════════════════

/// Horizontal filter tabs for the notifications page.
class _FilterTabs extends StatelessWidget {
  const _FilterTabs({
    required this.currentFilter,
    required this.onFilterChanged,
    required this.unreadCount,
  });

  final NotificationFilter currentFilter;
  final ValueChanged<NotificationFilter> onFilterChanged;
  final int unreadCount;

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;

    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: cs.outlineVariant.withValues(alpha: 0.5),
            width: 1,
          ),
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(
          horizontal: Spacings.lg,
          vertical: Spacings.sm,
        ),
        child: Row(
          children: NotificationFilter.values.map((filter) {
            final isSelected = filter == currentFilter;
            return Padding(
              padding: const EdgeInsets.only(right: Spacings.sm),
              child: _FilterChip(
                filter: filter,
                isSelected: isSelected,
                unreadCount: filter == NotificationFilter.unread
                    ? unreadCount
                    : null,
                onTap: () => onFilterChanged(filter),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

/// Individual filter chip widget.
class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.filter,
    required this.isSelected,
    required this.onTap,
    this.unreadCount,
  });

  final NotificationFilter filter;
  final bool isSelected;
  final VoidCallback onTap;
  final int? unreadCount;

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;
    final tt = context.textTheme;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(
          horizontal: Spacings.lg,
          vertical: Spacings.sm,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? cs.primary
              : cs.surfaceContainerHighest.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(Spacings.xxxl),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              filter.label,
              style: tt.labelMedium?.copyWith(
                color: isSelected
                    ? cs.onPrimary
                    : cs.onSurfaceVariant,
                fontWeight: isSelected
                    ? AppTypography.wSemiBold
                    : AppTypography.wMedium,
              ),
            ),
            if (unreadCount != null && unreadCount! > 0) ...[
              const SizedBox(width: Spacings.xs),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: Spacings.sm,
                  vertical: Spacings.xs,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? cs.onPrimary.withValues(alpha: 0.2)
                      : cs.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(Spacings.xxxl),
                ),
                constraints: const BoxConstraints(minWidth: 18),
                child: Text(
                  '${unreadCount!}',
                  style: tt.labelSmall?.copyWith(
                    color: isSelected ? cs.onPrimary : cs.primary,
                    fontWeight: AppTypography.wSemiBold,
                    fontSize: 10,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
