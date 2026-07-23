import 'package:flutter/material.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/extensions/datetime_extensions.dart';
import '../../../../core/themes/app_colors.dart';
import '../../../../core/themes/app_typography.dart';
import '../../../../core/themes/spacings.dart';
import '../../../../shared/widgets/app_card.dart';
import '../providers/dashboard_provider.dart';

// ═══════════════════════════════════════════════════════════════════════
// NOTIFICATION SUMMARY
// ═══════════════════════════════════════════════════════════════════════

/// A compact notification summary widget showing:
/// - Unread count badge
/// - Quick preview of the latest notifications
/// - "View all" link to the full notifications page
///
/// ```dart
/// NotificationSummary(
///   notifications: dashboardState.notifications,
///   onViewAll: () => context.go('/notifications'),
/// )
/// ```
class NotificationSummary extends StatefulWidget {
  const NotificationSummary({
    required this.notifications,
    this.onViewAll,
    this.maxPreview = 3,
    super.key,
  });

  /// List of notification items.
  final List<NotificationItem> notifications;

  /// Callback for "View all" link.
  final VoidCallback? onViewAll;

  /// Maximum number of notifications to preview.
  final int maxPreview;

  @override
  State<NotificationSummary> createState() => _NotificationSummaryState();
}

class _NotificationSummaryState extends State<NotificationSummary>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  int get _unreadCount =>
      widget.notifications.where((n) => !n.isRead).length;

  bool get _hasUnread => _unreadCount > 0;

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;
    final tt = context.textTheme;
    final isDark = context.isDarkMode;

    final preview = widget.notifications.take(widget.maxPreview).toList();

    return FadeTransition(
      opacity: _fadeAnimation,
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Header Row ────────────────────────────────────────────
            Row(
              children: [
                Icon(
                  Icons.notifications_outlined,
                  size: Spacings.mdIcon,
                  color: cs.primary,
                ),
                const SizedBox(width: Spacings.sm),
                Text(
                  'Notifications',
                  style: tt.titleSmall?.copyWith(
                    fontWeight: AppTypography.wSemiBold,
                    color: cs.onSurface,
                  ),
                ),
                const Spacer(),
                if (_hasUnread)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: Spacings.sm,
                      vertical: Spacings.xs / 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.errorOf(cs.brightness),
                      borderRadius:
                          BorderRadius.circular(Spacings.fullRadius),
                    ),
                    child: Text(
                      _unreadCount > 99 ? '99+' : '$_unreadCount',
                      style: tt.labelSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: AppTypography.wSemiBold,
                      ),
                    ),
                  ),
                if (widget.onViewAll != null) ...[
                  const SizedBox(width: Spacings.sm),
                  TextButton(
                    onPressed: widget.onViewAll,
                    style: TextButton.styleFrom(
                      minimumSize: Size.zero,
                      padding: const EdgeInsets.symmetric(
                        horizontal: Spacings.sm,
                        vertical: Spacings.xs,
                      ),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(
                      'View All',
                      style: tt.labelMedium?.copyWith(
                        color: cs.primary,
                        fontWeight: AppTypography.wSemiBold,
                      ),
                    ),
                  ),
                ],
              ],
            ),

            if (preview.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: Spacings.xl),
                child: Center(
                  child: Text(
                    'No notifications',
                    style: tt.bodyMedium?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                ),
              )
            else ...[
              const SizedBox(height: Spacings.md),
              const Divider(height: 1),
              // ── Notification Items ──────────────────────────────────
              for (int i = 0; i < preview.length; i++) ...[
                _NotificationTile(
                  item: preview[i],
                  isLast: i == preview.length - 1,
                ),
                if (i < preview.length - 1)
                  const Divider(height: 1, indent: Spacings.xxl),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// NOTIFICATION TILE (private)
// ═══════════════════════════════════════════════════════════════════════

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({
    required this.item,
    this.isLast = false,
  });

  final NotificationItem item;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;
    final tt = context.textTheme;
    final isDark = context.isDarkMode;
    final accentColor = item.isRead ? cs.onSurfaceVariant : cs.primary;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Spacings.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Unread Indicator ────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.only(
              top: Spacings.md,
              right: Spacings.sm,
            ),
            child: Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: item.isRead
                    ? Colors.transparent
                    : AppColors.errorOf(cs.brightness),
              ),
            ),
          ),
          // ── Icon ────────────────────────────────────────────────────
          if (item.icon != null)
            Container(
              margin: const EdgeInsets.only(right: Spacings.md),
              padding: const EdgeInsets.all(Spacings.sm),
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: isDark ? 0.20 : 0.12),
                borderRadius: BorderRadius.circular(Spacings.smRadius),
              ),
              child: Icon(
                item.icon,
                size: Spacings.mdIcon,
                color: accentColor,
              ),
            ),
          // ── Content ────────────────────────────────────────────────
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  item.title,
                  style: tt.bodyMedium?.copyWith(
                    color: cs.onSurface,
                    fontWeight: item.isRead
                        ? AppTypography.wRegular
                        : AppTypography.wSemiBold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (item.subtitle != null) ...[
                  const SizedBox(height: Spacings.xs / 2),
                  Text(
                    item.subtitle!,
                    style: tt.bodySmall?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: Spacings.xs),
                Text(
                  item.timestamp.timeAgo,
                  style: tt.labelSmall?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
