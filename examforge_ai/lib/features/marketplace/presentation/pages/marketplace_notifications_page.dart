import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/themes/app_colors.dart';
import '../../../../core/themes/app_typography.dart';
import '../../../../core/themes/spacings.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../../shared/widgets/widgets.dart';
import '../../domain/entities/marketplace_entities.dart';
import '../providers/marketplace_notification_provider.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// MARKETPLACE NOTIFICATIONS PAGE
// ═══════════════════════════════════════════════════════════════════════════════

/// Marketplace notification center with filter chips, swipe-to-dismiss,
/// pull-to-refresh, and load-more-on-scroll.
///
/// ```dart
/// Navigator.push(
///   context,
///   MaterialPageRoute(builder: (_) => MarketplaceNotificationsPage()),
/// );
/// ```
class MarketplaceNotificationsPage extends ConsumerStatefulWidget {
  const MarketplaceNotificationsPage({super.key});

  @override
  ConsumerState<MarketplaceNotificationsPage> createState() =>
      _MarketplaceNotificationsPageState();
}

class _MarketplaceNotificationsPageState
    extends ConsumerState<MarketplaceNotificationsPage> {
  _NotificationFilter _activeFilter = _NotificationFilter.all;
  final ScrollController _scrollController = ScrollController();
  bool _isLoadingMore = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadNotifications());
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadNotifications() async {
    await ref
        .read(marketplaceNotificationProvider.notifier)
        .loadNotifications(userId: 'current_user');
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !_isLoadingMore) {
      _loadMore();
    }
  }

  Future<void> _loadMore() async {
    setState(() => _isLoadingMore = true);
    // Simulate loading more notifications
    await Future.delayed(const Duration(seconds: 1));
    if (mounted) {
      setState(() => _isLoadingMore = false);
    }
  }

  Future<void> _onRefresh() async {
    await _loadNotifications();
  }

  void _markAllRead() {
    ref.read(marketplaceNotificationProvider.notifier).markAllRead();
    context.scaffoldMessenger.showSnackBar(
      const SnackBar(
        content: Text('All notifications marked as read'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showSnackBar(String message, {bool isError = false}) {
    context.scaffoldMessenger.showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppColors.error : null,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  List<MarketplaceNotificationEntity> _filterNotifications(
    List<MarketplaceNotificationEntity> notifications,
  ) {
    switch (_activeFilter) {
      case _NotificationFilter.all:
        return notifications;
      case _NotificationFilter.purchases:
        return notifications
            .where((n) =>
                n.type == MarketplaceNotificationType.purchaseSuccess ||
                n.type == MarketplaceNotificationType.wishlistDiscount)
            .toList();
      case _NotificationFilter.sales:
        return notifications
            .where((n) =>
                n.type == MarketplaceNotificationType.newSale ||
                n.type == MarketplaceNotificationType.commissionPaid)
            .toList();
      case _NotificationFilter.reviews:
        return notifications
            .where((n) => n.type == MarketplaceNotificationType.productReview)
            .toList();
      case _NotificationFilter.products:
        return notifications
            .where((n) =>
                n.type == MarketplaceNotificationType.productApproval ||
                n.type == MarketplaceNotificationType.productRejection ||
                n.type == MarketplaceNotificationType.featuredProduct ||
                n.type == MarketplaceNotificationType.priceChange ||
                n.type == MarketplaceNotificationType.qualityCheckComplete)
            .toList();
      case _NotificationFilter.system:
        return notifications
            .where((n) =>
                n.type == MarketplaceNotificationType.disputeUpdate ||
                n.type == MarketplaceNotificationType.sellerVerified)
            .toList();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(marketplaceNotificationProvider);

    ref.listen<MarketplaceNotificationState>(
      marketplaceNotificationProvider,
      (prev, next) {
        if (next.error != null && prev?.error != next.error) {
          _showSnackBar(next.error!, isError: true);
          ref.read(marketplaceNotificationProvider.notifier).clearError();
        }
      },
    );

    final filteredNotifications = _filterNotifications(state.notifications);

    return Scaffold(
      appBar: AppAppBar(
        title: 'Notifications',
        actions: [
          if (state.hasUnread)
            TextButton(
              onPressed: _markAllRead,
              child: Text(
                'Mark All Read',
                style: context.textTheme.labelLarge?.copyWith(
                  color: context.colorScheme.primary,
                ),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          // ── Filter Chips ─────────────────────────────────────────────
          _FilterChipsBar(
            activeFilter: _activeFilter,
            onFilterChanged: (filter) =>
                setState(() => _activeFilter = filter),
          ),

          // ── Notification List ────────────────────────────────────────
          Expanded(
            child: _buildBody(state, filteredNotifications),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(
    MarketplaceNotificationState state,
    List<MarketplaceNotificationEntity> filteredNotifications,
  ) {
    if (state.isLoading && state.notifications.isEmpty) {
      return const Center(child: AppLoadingSpinner());
    }

    if (state.error != null && state.notifications.isEmpty) {
      return AppErrorState.genericError(
        message: state.error,
        onRetry: _loadNotifications,
      );
    }

    if (filteredNotifications.isEmpty) {
      return AppEmptyState.noNotifications(
        title: 'No Notifications',
        subtitle: _activeFilter == _NotificationFilter.all
            ? "You're all caught up!"
            : 'No ${_activeFilter.label.toLowerCase()} notifications',
      );
    }

    return RefreshIndicator(
      onRefresh: _onRefresh,
      child: ListView.builder(
        controller: _scrollController,
        padding: Spacings.paddingScreen,
        itemCount: filteredNotifications.length + (_isLoadingMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == filteredNotifications.length) {
            return const Padding(
              padding: EdgeInsets.all(Spacings.lg),
              child: Center(child: AppLoadingSpinner(size: AppLoadingSpinnerSize.small)),
            );
          }

          final notification = filteredNotifications[index];
          return _NotificationTile(
            notification: notification,
            onTap: () => _onNotificationTap(notification),
            onDismiss: () => _onDismissNotification(notification),
          );
        },
      ),
    );
  }

  void _onNotificationTap(MarketplaceNotificationEntity notification) {
    if (!notification.isRead) {
      ref
          .read(marketplaceNotificationProvider.notifier)
          .markRead(notificationId: notification.id);
    }
    // Navigate to relevant page based on notification type
    // This is a placeholder for navigation logic
  }

  void _onDismissNotification(MarketplaceNotificationEntity notification) {
    // Remove from local state (placeholder for actual delete)
    context.scaffoldMessenger.showSnackBar(
      SnackBar(
        content: Text('Notification dismissed'),
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () {
            // Placeholder for undo
          },
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// ENUMS & HELPERS
// ═══════════════════════════════════════════════════════════════════════════════

enum _NotificationFilter {
  all(label: 'All', icon: Icons.all_inclusive),
  purchases(label: 'Purchases', icon: Icons.shopping_bag_outlined),
  sales(label: 'Sales', icon: Icons.sell_outlined),
  reviews(label: 'Reviews', icon: Icons.rate_review_outlined),
  products(label: 'Products', icon: Icons.inventory_2_outlined),
  system(label: 'System', icon: Icons.info_outlined);

  const _NotificationFilter({required this.label, required this.icon});
  final String label;
  final IconData icon;
}

/// Maps a [MarketplaceNotificationType] to a visual configuration.
_NotificationVisual _notificationVisual(MarketplaceNotificationType type) {
  return switch (type) {
    MarketplaceNotificationType.purchaseSuccess => _NotificationVisual(
        icon: Icons.shopping_bag_outlined,
        color: AppColors.success,
        label: 'Purchase',
      ),
    MarketplaceNotificationType.newSale => _NotificationVisual(
        icon: Icons.sell_outlined,
        color: AppColors.info,
        label: 'Sale',
      ),
    MarketplaceNotificationType.productReview => _NotificationVisual(
        icon: Icons.rate_review_outlined,
        color: AppColors.warning,
        label: 'Review',
      ),
    MarketplaceNotificationType.productApproval => _NotificationVisual(
        icon: Icons.check_circle_outline,
        color: const Color(0xFF8B5CF6), // Purple
        label: 'Product',
      ),
    MarketplaceNotificationType.productRejection => _NotificationVisual(
        icon: Icons.cancel_outlined,
        color: const Color(0xFF8B5CF6),
        label: 'Product',
      ),
    MarketplaceNotificationType.featuredProduct => _NotificationVisual(
        icon: Icons.star_outline,
        color: const Color(0xFF8B5CF6),
        label: 'Product',
      ),
    MarketplaceNotificationType.priceChange => _NotificationVisual(
        icon: Icons.price_change_outlined,
        color: const Color(0xFF8B5CF6),
        label: 'Product',
      ),
    MarketplaceNotificationType.wishlistDiscount => _NotificationVisual(
        icon: Icons.local_offer_outlined,
        color: AppColors.success,
        label: 'Purchase',
      ),
    MarketplaceNotificationType.commissionPaid => _NotificationVisual(
        icon: Icons.account_balance_outlined,
        color: AppColors.info,
        label: 'Sale',
      ),
    MarketplaceNotificationType.qualityCheckComplete => _NotificationVisual(
        icon: Icons.verified_outlined,
        color: const Color(0xFF8B5CF6),
        label: 'Product',
      ),
    MarketplaceNotificationType.disputeUpdate => _NotificationVisual(
        icon: Icons.gavel_outlined,
        color: AppColors.error,
        label: 'System',
      ),
    MarketplaceNotificationType.sellerVerified => _NotificationVisual(
        icon: Icons.verified_user_outlined,
        color: AppColors.error,
        label: 'System',
      ),
  };
}

/// Returns a human-readable relative time string (e.g. "2 hours ago").
String _timeAgo(DateTime dateTime) {
  final now = DateTime.now();
  final diff = now.difference(dateTime);

  if (diff.inSeconds < 60) return 'Just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
  if (diff.inHours < 24) return '${diff.inHours}h ago';
  if (diff.inDays < 7) return '${diff.inDays}d ago';
  if (diff.inDays < 30) return '${(diff.inDays / 7).floor()}w ago';
  if (diff.inDays < 365) return '${(diff.inDays / 30).floor()}mo ago';
  return '${(diff.inDays / 365).floor()}y ago';
}

class _NotificationVisual {
  const _NotificationVisual({
    required this.icon,
    required this.color,
    required this.label,
  });

  final IconData icon;
  final Color color;
  final String label;
}

// ═══════════════════════════════════════════════════════════════════════════════
// FILTER CHIPS BAR
// ═══════════════════════════════════════════════════════════════════════════════

class _FilterChipsBar extends StatelessWidget {
  const _FilterChipsBar({
    required this.activeFilter,
    required this.onFilterChanged,
  });

  final _NotificationFilter activeFilter;
  final ValueChanged<_NotificationFilter> onFilterChanged;

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Spacings.lg,
        vertical: Spacings.sm,
      ),
      color: cs.surfaceContainerLow,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: _NotificationFilter.values.map((filter) {
            final isSelected = filter == activeFilter;
            return Padding(
              padding: const EdgeInsets.only(right: Spacings.sm),
              child: FilterChip(
                label: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      filter.icon,
                      size: Spacings.smIcon,
                    ),
                    const SizedBox(width: Spacings.xs),
                    Text(filter.label),
                  ],
                ),
                selected: isSelected,
                onSelected: (_) => onFilterChanged(filter),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// NOTIFICATION TILE
// ═══════════════════════════════════════════════════════════════════════════════

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({
    required this.notification,
    required this.onTap,
    required this.onDismiss,
  });

  final MarketplaceNotificationEntity notification;
  final VoidCallback onTap;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final visual = _notificationVisual(notification.type);

    return Dismissible(
      key: ValueKey(notification.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDismiss(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: Spacings.xl),
        margin: const EdgeInsets.only(bottom: Spacings.sm),
        decoration: BoxDecoration(
          color: AppColors.error.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(Spacings.mdRadius),
        ),
        child: Icon(
          Icons.delete_outline,
          color: AppColors.error,
        ),
      ),
      child: AppCard(
        margin: const EdgeInsets.only(bottom: Spacings.sm),
        onTap: onTap,
        color: notification.isRead
            ? null
            : context.colorScheme.primaryContainer.withValues(alpha: 0.08),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Type Icon ────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(Spacings.sm),
              decoration: BoxDecoration(
                color: visual.color.withValues(
                  alpha: context.isDarkMode ? 0.20 : 0.12,
                ),
                borderRadius: BorderRadius.circular(Spacings.smRadius),
              ),
              child: Icon(
                visual.icon,
                size: Spacings.mdIcon,
                color: visual.color,
              ),
            ),
            const SizedBox(width: Spacings.md),

            // ── Content ─────────────────────────────────────────────
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title row with unread indicator
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          notification.title,
                          style: context.textTheme.titleSmall?.copyWith(
                            fontWeight: notification.isRead
                                ? AppTypography.wMedium
                                : AppTypography.wBold,
                            color: context.colorScheme.onSurface,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (!notification.isRead) ...[
                        const SizedBox(width: Spacings.sm),
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: context.colorScheme.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: Spacings.xs),

                  // Message
                  Text(
                    notification.message,
                    style: context.textTheme.bodySmall?.copyWith(
                      color: context.colorScheme.onSurfaceVariant,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: Spacings.xs),

                  // Time ago & type label
                  Row(
                    children: [
                      Text(
                        _timeAgo(notification.createdAt),
                        style: context.textTheme.labelSmall?.copyWith(
                          color: context.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(width: Spacings.sm),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: Spacings.sm,
                          vertical: 1.0,
                        ),
                        decoration: BoxDecoration(
                          color: visual.color.withValues(
                            alpha: context.isDarkMode ? 0.20 : 0.12,
                          ),
                          borderRadius:
                              BorderRadius.circular(Spacings.fullRadius),
                        ),
                        child: Text(
                          visual.label,
                          style: context.textTheme.labelSmall?.copyWith(
                            color: visual.color,
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
    );
  }
}
