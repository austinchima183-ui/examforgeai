import 'package:flutter/material.dart';

import '../../../../core/themes/app_colors.dart';
import '../../../../core/themes/app_typography.dart';
import '../../../../core/themes/spacings.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../domain/entities/communication_entities.dart';

// ─── NotificationTile ─────────────────────────────────────────────────────────

/// A list tile for displaying a communication notification with category
/// icon, title, body preview, time, and read/unread dot indicator.
/// Color-coded by notification category.
///
/// ```dart
/// NotificationTile(
///   notification: notif,
///   onTap: () => openNotification(notif.id),
///   onMarkRead: () => markRead(notif.id),
/// )
/// ```
class NotificationTile extends StatelessWidget {
  const NotificationTile({
    super.key,
    required this.notification,
    this.onTap,
    this.onMarkRead,
  });

  /// The notification entity to display.
  final CommunicationNotificationEntity notification;

  /// Tap callback.
  final VoidCallback? onTap;

  /// Mark-as-read callback.
  final VoidCallback? onMarkRead;

  // ─── Category Helpers ─────────────────────────────────────────────────

  IconData _categoryIcon(NotificationCategory category) {
    return switch (category) {
      NotificationCategory.message => Icons.chat_bubble_outline_rounded,
      NotificationCategory.assignment => Icons.assignment_outlined,
      NotificationCategory.exam => Icons.quiz_outlined,
      NotificationCategory.result => Icons.bar_chart_outlined,
      NotificationCategory.attendance => Icons.event_available_outlined,
      NotificationCategory.announcement => Icons.campaign_outlined,
      NotificationCategory.system => Icons.info_outline_rounded,
      NotificationCategory.payment => Icons.payment_outlined,
      NotificationCategory.general => Icons.notifications_outlined,
    };
  }

  Color _categoryColor(NotificationCategory category) {
    return switch (category) {
      NotificationCategory.message => AppColors.seed,
      NotificationCategory.assignment => const Color(0xFFEA580C),
      NotificationCategory.exam => const Color(0xFF7C3AED),
      NotificationCategory.result => AppColors.success,
      NotificationCategory.attendance => const Color(0xFF0891B2),
      NotificationCategory.announcement => AppColors.info,
      NotificationCategory.system => const Color(0xFF6B7280),
      NotificationCategory.payment => const Color(0xFFCA8A04),
      NotificationCategory.general => AppColors.seed,
    };
  }

  // ─── Time Helper ──────────────────────────────────────────────────────

  String _relativeTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${dt.day}/${dt.month}';
  }

  // ─── Build ─────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;
    final tt = context.textTheme;
    final isDark = context.isDarkMode;

    final catColor = _categoryColor(notification.category);
    final catIcon = _categoryIcon(notification.category);

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: Spacings.lg,
          vertical: Spacings.md,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Category icon
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: catColor.withValues(alpha: isDark ? 0.25 : 0.12),
                borderRadius: BorderRadius.circular(Spacings.mdRadius),
              ),
              child: Icon(catIcon,
                  size: Spacings.mdIcon, color: catColor),
            ),
            const SizedBox(width: Spacings.md),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
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
                      ),
                      const SizedBox(width: Spacings.sm),
                      // Unread dot
                      if (!notification.isRead)
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: AppColors.seed,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: Spacings.xs),
                  Text(
                    notification.body,
                    style: tt.bodySmall?.copyWith(
                      color: cs.onSurfaceVariant,
                      fontWeight: notification.isRead
                          ? AppTypography.wRegular
                          : AppTypography.wMedium,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: Spacings.xs),
                  Row(
                    children: [
                      Text(
                        _relativeTime(notification.createdAt),
                        style: tt.labelSmall?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                      if (!notification.isRead && onMarkRead != null) ...[
                        const SizedBox(width: Spacings.md),
                        GestureDetector(
                          onTap: onMarkRead,
                          child: Text(
                            'Mark read',
                            style: tt.labelSmall?.copyWith(
                              color: AppColors.seed,
                              fontWeight: AppTypography.wSemiBold,
                            ),
                          ),
                        ),
                      ],
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
