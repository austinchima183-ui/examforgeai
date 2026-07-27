import 'package:flutter/material.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/extensions/datetime_extensions.dart';
import '../../../../core/themes/app_colors.dart';
import '../../../../core/themes/app_typography.dart';
import '../../../../core/themes/spacings.dart';
import '../providers/notification_provider.dart';

// ═══════════════════════════════════════════════════════════════════════
// NOTIFICATION ITEM WIDGET
// ═══════════════════════════════════════════════════════════════════════

/// A single notification item widget with Material 3 styling.
///
/// Displays a leading icon with color, title, message preview,
/// relative timestamp, unread dot indicator, tap-to-read, and
/// swipe-to-dismiss for deletion.
///
/// ```dart
/// NotificationItemWidget(
///   notification: myNotification,
///   onTap: () => markAsRead(notification.id),
///   onDismiss: () => deleteNotification(notification.id),
/// )
/// ```
class NotificationItemWidget extends StatelessWidget {
  const NotificationItemWidget({
    super.key,
    required this.notification,
    this.onTap,
    this.onDismiss,
  });

  /// The notification data to display.
  final NotificationItem notification;

  /// Callback when the notification is tapped.
  final VoidCallback? onTap;

  /// Callback when the notification is swiped to dismiss.
  final VoidCallback? onDismiss;

  // ─── Icon & Color for Notification Type ──────────────────────────

  IconData _typeIcon() {
    return switch (notification.type) {
      NotificationType.exam => Icons.quiz_outlined,
      NotificationType.result => Icons.assessment_outlined,
      NotificationType.reminder => Icons.notifications_active_outlined,
      NotificationType.system => Icons.info_outline_rounded,
    };
  }

  Color _typeColor(ColorScheme cs) {
    return switch (notification.type) {
      NotificationType.exam => AppColors.info,
      NotificationType.result => AppColors.success,
      NotificationType.reminder => AppColors.warning,
      NotificationType.system => cs.onSurfaceVariant,
    };
  }

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;
    final tt = context.textTheme;
    final isDark = context.isDarkMode;
    final typeColor = _typeColor(cs);

    final content = InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(Spacings.mdRadius),
      child: Ink(
        decoration: BoxDecoration(
          color: notification.isRead
              ? Colors.transparent
              : cs.primary.withValues(alpha: isDark ? 0.08 : 0.05),
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
              // ── Leading Icon ─────────────────────────────────────
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: typeColor.withValues(alpha: isDark ? 0.20 : 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _typeIcon(),
                  size: Spacings.mdIcon,
                  color: typeColor,
                ),
              ),
              const SizedBox(width: Spacings.md),

              // ── Content ──────────────────────────────────────────
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
                        if (!notification.isRead) ...[
                          const SizedBox(width: Spacings.sm),
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: cs.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: Spacings.xs),

                    // Message preview
                    Text(
                      notification.message,
                      style: tt.bodySmall?.copyWith(
                        color: cs.onSurfaceVariant,
                        height: 1.4,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: Spacings.sm),

                    // Timestamp
                    Text(
                      notification.createdAt.timeAgo,
                      style: tt.labelSmall?.copyWith(
                        color: cs.onSurfaceVariant.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );

    // Wrap with Dismissible for swipe-to-delete
    return Dismissible(
      key: ValueKey(notification.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDismiss?.call(),
      confirmDismiss: (direction) async {
        // Show a brief confirmation
        return true;
      },
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: Spacings.xl),
        decoration: BoxDecoration(
          color: AppColors.error.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(Spacings.mdRadius),
        ),
        child: const Icon(
          Icons.delete_outline_rounded,
          color: AppColors.error,
          size: Spacings.lgIcon,
        ),
      ),
      child: content,
    );
  }
}
