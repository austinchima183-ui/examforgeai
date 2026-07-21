import 'package:flutter/material.dart';

import '../../../../core/themes/app_colors.dart';
import '../../../../core/themes/app_typography.dart';
import '../../../../core/themes/spacings.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/extensions/datetime_extensions.dart';
import '../../domain/entities/parent_portal_entities.dart';

// ═══════════════════════════════════════════════════════════════════════
// NOTIFICATION LIST TILE
// ═══════════════════════════════════════════════════════════════════════

/// List tile for a notification in the parent portal.
///
/// Displays a category icon (colour-coded), unread dot indicator,
/// title (bold if unread), body preview (1 line, grey), time ago,
/// an optional action button, and supports swipe-to-dismiss.
///
/// ```dart
/// NotificationListTile(
///   notification: myNotification,
///   onTap: () => markAsRead(notification.id),
///   onDismiss: () => deleteNotification(notification.id),
/// )
/// ```
class NotificationListTile extends StatelessWidget {
  const NotificationListTile({
    super.key,
    required this.notification,
    this.onTap,
    this.onDismiss,
  });

  /// The notification data to display.
  final ParentNotificationEntity notification;

  /// Callback when the tile is tapped.
  final VoidCallback? onTap;

  /// Callback when swiped to dismiss.
  final VoidCallback? onDismiss;

  // ─── Category → Icon ──────────────────────────────────────────────

  IconData _categoryIcon() {
    return switch (notification.category) {
      NotificationCategory.result => Icons.trending_up_rounded,
      NotificationCategory.attendance => Icons.calendar_today_rounded,
      NotificationCategory.assignment => Icons.assignment_rounded,
      NotificationCategory.announcement => Icons.campaign_rounded,
      NotificationCategory.exam => Icons.quiz_rounded,
      NotificationCategory.message => Icons.chat_rounded,
      NotificationCategory.fee => Icons.payments_rounded,
      NotificationCategory.general => Icons.info_outline_rounded,
    };
  }

  // ─── Category → Colour ────────────────────────────────────────────

  Color _categoryColor() {
    return switch (notification.category) {
      NotificationCategory.result => AppColors.success,
      NotificationCategory.attendance => AppColors.info,
      NotificationCategory.assignment => AppColors.warning,
      NotificationCategory.announcement => cs_primaryProxy,
      NotificationCategory.exam => AppColors.info,
      NotificationCategory.message => cs_primaryProxy,
      NotificationCategory.fee => AppColors.warning,
      NotificationCategory.general => const Color(0xFF6B7280),
    };
  }

  // Placeholder for primary colour (cannot access context here)
  static const Color cs_primaryProxy = Color(0xFF4F46E5);

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;
    final tt = context.textTheme;
    final isDark = context.isDarkMode;
    final typeColor = _categoryColor();

    final content = InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(Spacings.mdRadius),
      child: Ink(
        decoration: BoxDecoration(
          color: notification.isRead
              ? Colors.transparent
              : cs.primary.withOpacity(isDark ? 0.08 : 0.05),
          borderRadius: BorderRadius.circular(Spacings.mdRadius),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: Spacings.lg,
            vertical: Spacings.md,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Unread dot + Category Icon ────────────────────────
              Column(
                children: [
                  const SizedBox(height: Spacings.sm),
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: typeColor.withOpacity(isDark ? 0.20 : 0.12,
                          ),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _categoryIcon(),
                          size: Spacings.mdIcon,
                          color: typeColor,
                        ),
                      ),
                      if (!notification.isRead)
                        Positioned(
                          left: -2,
                          top: -2,
                          child: Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: cs.primary,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: cs.surface,
                                width: 2,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
              const SizedBox(width: Spacings.md),

              // ── Title + Body + Action ──────────────────────────────
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title row
                    Text(
                      notification.title,
                      style: tt.titleSmall?.copyWith(
                        fontWeight: notification.isRead
                            ? AppTypography.wMedium
                            : AppTypography.wSemiBold,
                        color: cs.onSurface,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: Spacings.xs),

                    // Body preview
                    Text(
                      notification.body,
                      style: tt.bodySmall?.copyWith(
                        color: cs.onSurfaceVariant,
                        height: 1.4,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: Spacings.sm),

                    // Bottom row: time + action
                    Row(
                      children: [
                        Text(
                          notification.createdAt.timeAgo,
                          style: tt.labelSmall?.copyWith(
                            color: cs.onSurfaceVariant.withOpacity(0.7),
                          ),
                        ),
                        const Spacer(),
                        if (notification.actionUrl != null &&
                            notification.actionLabel != null)
                          _buildActionButton(cs, tt),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );

    // Wrap with Dismissible for swipe-to-dismiss
    return Dismissible(
      key: ValueKey(notification.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDismiss?.call(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: Spacings.xl),
        margin: const EdgeInsets.symmetric(vertical: Spacings.xs),
        decoration: BoxDecoration(
          color: AppColors.error.withOpacity(0.1),
          borderRadius: BorderRadius.circular(Spacings.mdRadius),
        ),
        child: Icon(
          Icons.delete_outline_rounded,
          color: AppColors.error,
          size: Spacings.lgIcon,
        ),
      ),
      child: content,
    );
  }

  // ─── Action Button ────────────────────────────────────────────────

  Widget _buildActionButton(ColorScheme cs, TextTheme tt) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Spacings.md,
        vertical: Spacings.xs,
      ),
      decoration: BoxDecoration(
        color: cs.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(Spacings.fullRadius),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            notification.actionLabel!,
            style: tt.labelSmall?.copyWith(
              fontWeight: AppTypography.wSemiBold,
              color: cs.primary,
            ),
          ),
          const SizedBox(width: Spacings.xs),
          Icon(
            Icons.arrow_forward_rounded,
            size: 14,
            color: cs.primary,
          ),
        ],
      ),
    );
  }
}
