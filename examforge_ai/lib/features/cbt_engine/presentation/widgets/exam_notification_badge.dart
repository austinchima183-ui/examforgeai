import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../config/dependency_injection.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/themes/app_colors.dart';
import '../../../../core/themes/app_typography.dart';
import '../../../../core/themes/spacings.dart';
import '../providers/exam_notification_provider.dart';

// ═══════════════════════════════════════════════════════════════════════
// EXAM NOTIFICATION BADGE
// ═══════════════════════════════════════════════════════════════════════

/// A notification badge widget for the exam module that displays a bell
/// icon with an unread count indicator.
///
/// When tapped, it opens a notifications bottom sheet showing recent
/// exam notifications. The badge animates in when the unread count
/// changes from zero to non-zero.
///
/// ```dart
/// ExamNotificationBadge(
///   onTap: () => openNotifications(),
/// )
/// ```
class ExamNotificationBadge extends ConsumerStatefulWidget {
  const ExamNotificationBadge({
    super.key,
    this.onTap,
    this.size = 24.0,
  });

  /// Optional tap handler. If `null`, tapping the badge opens the
  /// default notification bottom sheet.
  final VoidCallback? onTap;

  /// The size of the bell icon. Defaults to 24.
  final double size;

  @override
  ConsumerState<ExamNotificationBadge> createState() =>
      _ExamNotificationBadgeState();
}

class _ExamNotificationBadgeState extends ConsumerState<ExamNotificationBadge>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.3).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;
    final state = ref.watch(examNotificationProvider);
    final unreadCount = state.unreadCount;

    // Pulse animation when unread count changes from 0 to > 0
    ref.listen<ExamNotificationState>(examNotificationProvider, (prev, next) {
      if ((prev?.unreadCount ?? 0) == 0 && next.unreadCount > 0) {
        _pulseController.forward(from: 0.0).then((_) {
          if (mounted) _pulseController.reverse();
        });
      }
    });

    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Bell icon button
        IconButton(
          onPressed: widget.onTap ?? () => _openNotifications(context),
          icon: ScaleTransition(
            scale: _pulseAnimation,
            child: Icon(
              unreadCount > 0
                  ? Icons.notifications_active_rounded
                  : Icons.notifications_none_rounded,
              size: widget.size,
              color: unreadCount > 0 ? cs.primary : cs.onSurfaceVariant,
            ),
          ),
          tooltip: unreadCount > 0
              ? '$unreadCount unread notifications'
              : 'No new notifications',
          visualDensity: VisualDensity.compact,
        ),

        // Unread count badge
        if (unreadCount > 0)
          Positioned(
            top: 4.0,
            right: 4.0,
            child: _buildCountBadge(context, unreadCount),
          ),
      ],
    );
  }

  // ─── Count Badge ──────────────────────────────────────────────────────

  Widget _buildCountBadge(BuildContext context, int count) {
    final cs = context.colorScheme;
    final tt = context.textTheme;
    final isDark = context.isDarkMode;

    final displayCount = count > 99 ? '99+' : '$count';

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Spacings.xs,
        vertical: 1.0,
      ),
      constraints: const BoxConstraints(minWidth: 18.0, minHeight: 18.0),
      decoration: BoxDecoration(
        color: AppColors.errorOf(cs.brightness),
        borderRadius: BorderRadius.circular(Spacings.fullRadius),
        border: Border.all(
          color: isDark ? AppColors.surfaceCardDark : AppColors.surfaceCardLight,
          width: 2.0,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.errorOf(cs.brightness).withValues(alpha: 0.3),
            blurRadius: 4.0,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Center(
        child: Text(
          displayCount,
          style: tt.labelSmall?.copyWith(
            fontWeight: AppTypography.wBold,
            color: Colors.white,
            fontSize: 10.0,
            height: 1.2,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  // ─── Notifications Bottom Sheet ───────────────────────────────────────

  void _openNotifications(BuildContext context) {
    final cs = context.colorScheme;
    final tt = context.textTheme;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(Spacings.lgRadius),
        ),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) {
          final state = ref.read(examNotificationProvider);
          final notifications = state.notifications;

          return Column(
            children: [
              // Handle
              Container(
                margin: const EdgeInsets.only(top: Spacings.sm),
                width: 40.0,
                height: 4.0,
                decoration: BoxDecoration(
                  color: cs.onSurfaceVariant.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(Spacings.fullRadius),
                ),
              ),

              // Header
              Padding(
                padding: const EdgeInsets.all(Spacings.lg),
                child: Row(
                  children: [
                    Text(
                      'Notifications',
                      style: tt.titleLarge?.copyWith(
                        fontWeight: AppTypography.wSemiBold,
                        color: cs.onSurface,
                      ),
                    ),
                    const Spacer(),
                    if (state.hasUnread)
                      TextButton(
                        onPressed: () {
                          ref
                              .read(examNotificationProvider.notifier)
                              .markAllAsRead();
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
              ),

              // Notifications list
              Expanded(
                child: notifications.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.notifications_none_rounded,
                              size: Spacings.xlIcon,
                              color: cs.onSurfaceVariant
                                  .withValues(alpha: 0.5),
                            ),
                            const SizedBox(height: Spacings.md),
                            Text(
                              'No notifications yet',
                              style: tt.bodyMedium?.copyWith(
                                color: cs.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        controller: scrollController,
                        padding: const EdgeInsets.symmetric(
                          horizontal: Spacings.lg,
                        ),
                        itemCount: notifications.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: Spacings.sm),
                        itemBuilder: (context, index) {
                          final notification = notifications[index];
                          return _NotificationTile(
                            notification: notification,
                            onTap: () {
                              if (!notification.isRead) {
                                ref
                                    .read(examNotificationProvider.notifier)
                                    .markAsRead(notification.id);
                              }
                              Navigator.of(context).pop();
                              // TODO: Navigate to relevant exam/notification target
                            },
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// NOTIFICATION TILE (Private)
// ═══════════════════════════════════════════════════════════════════════

/// A single notification list tile inside the bottom sheet.
class _NotificationTile extends StatelessWidget {
  const _NotificationTile({
    required this.notification,
    this.onTap,
  });

  final ExamNotificationEntity notification;
  final VoidCallback? onTap;

  IconData _typeIcon() {
    return switch (notification.type) {
      ExamNotificationType.examPublished => Icons.publish_rounded,
      ExamNotificationType.examStarting => Icons.play_circle_rounded,
      ExamNotificationType.examCompleted => Icons.check_circle_rounded,
      ExamNotificationType.resultsAvailable => Icons.bar_chart_rounded,
      ExamNotificationType.examCancelled => Icons.cancel_rounded,
      ExamNotificationType.templateShared => Icons.share_rounded,
      ExamNotificationType.general => Icons.info_rounded,
    };
  }

  Color _typeColor(BuildContext context) {
    final cs = context.colorScheme;
    return switch (notification.type) {
      ExamNotificationType.examPublished => AppColors.infoOf(cs.brightness),
      ExamNotificationType.examStarting =>
        AppColors.successOf(cs.brightness),
      ExamNotificationType.examCompleted => cs.primary,
      ExamNotificationType.resultsAvailable =>
        AppColors.successOf(cs.brightness),
      ExamNotificationType.examCancelled =>
        AppColors.errorOf(cs.brightness),
      ExamNotificationType.templateShared => cs.tertiary,
      ExamNotificationType.general => cs.onSurfaceVariant,
    };
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    const months = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[dt.month]} ${dt.day}';
  }

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;
    final tt = context.textTheme;
    final isDark = context.isDarkMode;
    final color = _typeColor(context);

    return ListTile(
      onTap: onTap,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Spacings.mdRadius),
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: Spacings.md,
        vertical: Spacings.xs,
      ),
      tileColor: notification.isRead
          ? null
          : cs.primary.withValues(alpha: isDark ? 0.08 : 0.04),
      leading: Container(
        padding: const EdgeInsets.all(Spacings.sm),
        decoration: BoxDecoration(
          color: color.withValues(alpha: isDark ? 0.20 : 0.12),
          borderRadius: BorderRadius.circular(Spacings.smRadius),
        ),
        child: Icon(_typeIcon(), size: Spacings.mdIcon, color: color),
      ),
      title: Text(
        notification.title,
        style: tt.bodyMedium?.copyWith(
          fontWeight: notification.isRead
              ? AppTypography.wRegular
              : AppTypography.wSemiBold,
          color: cs.onSurface,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        notification.body,
        style: tt.bodySmall?.copyWith(
          color: cs.onSurfaceVariant,
        ),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            _timeAgo(notification.createdAt),
            style: tt.labelSmall?.copyWith(
              color: cs.onSurfaceVariant,
            ),
          ),
          if (!notification.isRead) ...[
            const SizedBox(height: Spacings.xs),
            Container(
              width: 8.0,
              height: 8.0,
              decoration: BoxDecoration(
                color: cs.primary,
                shape: BoxShape.circle,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
