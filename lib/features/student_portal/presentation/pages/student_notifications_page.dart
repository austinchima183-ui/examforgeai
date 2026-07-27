import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/themes/app_colors.dart';
import '../../../../core/themes/app_typography.dart';
import '../../../../core/themes/spacings.dart';
import '../../../../shared/widgets/widgets.dart';
import '../../domain/entities/student_portal_entities.dart';
import '../providers/student_portal_providers.dart';

/// Student notifications page.
///
/// Features:
/// - Notification list with type icons and badges
/// - Unread indicator
/// - Mark as read on tap
/// - Mark all as read button
/// - Notification type filter chips
/// - Empty state
class StudentNotificationsPage extends ConsumerStatefulWidget {
  const StudentNotificationsPage({super.key});

  @override
  ConsumerState<StudentNotificationsPage> createState() =>
      _StudentNotificationsPageState();
}

class _StudentNotificationsPageState
    extends ConsumerState<StudentNotificationsPage> {
  StudentNotificationType? _filterType;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(studentNotificationProvider.notifier).loadNotifications();
    });
  }

  @override
  Widget build(BuildContext context) {
    final notifState = ref.watch(studentNotificationProvider);
    final cs = context.colorScheme;
    final tt = context.textTheme;

    final filteredNotifications = _filterType != null
        ? notifState.notifications
            .where((n) => n.type == _filterType)
            .toList()
        : notifState.notifications;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          if (notifState.unreadCount > 0)
            TextButton(
              onPressed: () {
                ref
                    .read(studentNotificationProvider.notifier)
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
      body: Column(
        children: [
          // Unread count banner
          if (notifState.unreadCount > 0)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                horizontal: Spacings.lg,
                vertical: Spacings.md,
              ),
              color: cs.primaryContainer.withValues(alpha: 0.5),
              child: Row(
                children: [
                  Icon(
                    Icons.notifications_active_outlined,
                    size: Spacings.mdIcon,
                    color: cs.primary,
                  ),
                  const SizedBox(width: Spacings.sm),
                  Text(
                    '${notifState.unreadCount} unread notification${notifState.unreadCount > 1 ? 's' : ''}',
                    style: tt.bodyMedium?.copyWith(
                      color: cs.primary,
                      fontWeight: AppTypography.wSemiBold,
                    ),
                  ),
                ],
              ),
            ),

          // Filter chips
          SizedBox(
            height: 48,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(
                horizontal: Spacings.lg,
                vertical: Spacings.sm,
              ),
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: Spacings.sm),
                  child: FilterChip(
                    label: const Text('All'),
                    selected: _filterType == null,
                    onSelected: (_) {
                      setState(() => _filterType = null);
                    },
                  ),
                ),
                ...StudentNotificationType.values.map(
                  (type) => Padding(
                    padding: const EdgeInsets.only(right: Spacings.sm),
                    child: FilterChip(
                      label: Text(type.label),
                      selected: _filterType == type,
                      onSelected: (selected) {
                        setState(() =>
                            _filterType = selected ? type : null,);
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Notification list
          Expanded(
            child: notifState.isLoading &&
                    notifState.notifications.isEmpty
                ? const Center(child: AppLoadingSpinner())
                : notifState.error != null &&
                        notifState.notifications.isEmpty
                    ? AppErrorState(
                        icon: Icons.error_outline_rounded,
                        title: 'Failed to Load Notifications',
                        message: notifState.error,
                        onRetry: () => ref
                            .read(studentNotificationProvider.notifier)
                            .loadNotifications(),
                      )
                    : filteredNotifications.isEmpty
                        ? AppEmptyState(
                            icon: Icons.notifications_none_rounded,
                            title: 'No Notifications',
                            subtitle: _filterType != null
                                ? 'No ${_filterType!.label} notifications.'
                                : "You're all caught up!",
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(
                              horizontal: Spacings.lg,
                              vertical: Spacings.sm,
                            ),
                            itemCount: filteredNotifications.length,
                            itemBuilder: (context, index) {
                              final notification =
                                  filteredNotifications[index];
                              return Padding(
                                padding: const EdgeInsets.only(
                                  bottom: Spacings.sm,
                                ),
                                child: _NotificationCard(
                                  notification: notification,
                                  onTap: () {
                                    if (!notification.isRead) {
                                      ref
                                          .read(
                                              studentNotificationProvider
                                                  .notifier,)
                                          .markAsRead(notification.id);
                                    }
                                  },
                                ),
                              );
                            },
                          ),
          ),
        ],
      ),
    );
  }

  // ─── Helpers ────────────────────────────────────────────────────────

  IconData _notificationIcon(StudentNotificationType type) {
    return switch (type) {
      StudentNotificationType.newAssignment =>
        Icons.assignment_outlined,
      StudentNotificationType.upcomingExam =>
        Icons.event_outlined,
      StudentNotificationType.resultPublished =>
        Icons.assessment_outlined,
      StudentNotificationType.teacherAnnouncement =>
        Icons.campaign_outlined,
      StudentNotificationType.studyReminder =>
        Icons.alarm_outlined,
      StudentNotificationType.deadlineApproaching =>
        Icons.schedule_outlined,
      StudentNotificationType.feedbackReceived =>
        Icons.feedback_outlined,
    };
  }

  Color _notificationColor(StudentNotificationType type) {
    return switch (type) {
      StudentNotificationType.newAssignment => AppColors.info,
      StudentNotificationType.upcomingExam => AppColors.warning,
      StudentNotificationType.resultPublished => AppColors.success,
      StudentNotificationType.teacherAnnouncement => AppColors.info,
      StudentNotificationType.studyReminder => AppColors.warning,
      StudentNotificationType.deadlineApproaching => AppColors.error,
      StudentNotificationType.feedbackReceived => AppColors.success,
    };
  }
}

// ═══════════════════════════════════════════════════════════════════════
// PRIVATE HELPER WIDGETS
// ═══════════════════════════════════════════════════════════════════════

class _NotificationCard extends StatelessWidget {
  const _NotificationCard({
    required this.notification,
    required this.onTap,
  });

  final StudentNotificationEntity notification;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;
    final tt = context.textTheme;
    final isUnread = !notification.isRead;

    final typeIcon = _getTypeIcon(notification.type);
    final typeColor = _getTypeColor(notification.type);

    return AppCard(
      onTap: onTap,
      borderColor: isUnread ? cs.primary.withValues(alpha: 0.3) : null,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Type icon
          Container(
            padding: const EdgeInsets.all(Spacings.md),
            decoration: BoxDecoration(
              color: typeColor.withValues(alpha: context.isDarkMode ? 0.20 : 0.12,
              ),
              borderRadius: BorderRadius.circular(Spacings.mdRadius),
            ),
            child: Icon(
              typeIcon,
              size: Spacings.mdIcon,
              color: typeColor,
            ),
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
                          fontWeight: isUnread
                              ? AppTypography.wBold
                              : AppTypography.wSemiBold,
                          color: cs.onSurface,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isUnread)
                      Container(
                        width: 8,
                        height: 8,
                        margin: const EdgeInsets.only(left: Spacings.sm),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: cs.primary,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: Spacings.xs),
                Text(
                  notification.message,
                  style: tt.bodySmall?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: Spacings.sm),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: Spacings.sm,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: typeColor.withValues(alpha: context.isDarkMode ? 0.20 : 0.12,
                        ),
                        borderRadius: BorderRadius.circular(
                            Spacings.fullRadius,),
                      ),
                      child: Text(
                        notification.type.label,
                        style: tt.labelSmall?.copyWith(
                          color: typeColor,
                          fontWeight: AppTypography.wMedium,
                        ),
                      ),
                    ),
                    const SizedBox(width: Spacings.md),
                    Text(
                      _formatTimeAgo(notification.createdAt),
                      style: tt.labelSmall?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _getTypeIcon(StudentNotificationType type) {
    return switch (type) {
      StudentNotificationType.newAssignment =>
        Icons.assignment_outlined,
      StudentNotificationType.upcomingExam =>
        Icons.event_outlined,
      StudentNotificationType.resultPublished =>
        Icons.assessment_outlined,
      StudentNotificationType.teacherAnnouncement =>
        Icons.campaign_outlined,
      StudentNotificationType.studyReminder =>
        Icons.alarm_outlined,
      StudentNotificationType.deadlineApproaching =>
        Icons.schedule_outlined,
      StudentNotificationType.feedbackReceived =>
        Icons.feedback_outlined,
    };
  }

  Color _getTypeColor(StudentNotificationType type) {
    return switch (type) {
      StudentNotificationType.newAssignment => AppColors.info,
      StudentNotificationType.upcomingExam => AppColors.warning,
      StudentNotificationType.resultPublished => AppColors.success,
      StudentNotificationType.teacherAnnouncement => AppColors.info,
      StudentNotificationType.studyReminder => AppColors.warning,
      StudentNotificationType.deadlineApproaching => AppColors.error,
      StudentNotificationType.feedbackReceived => AppColors.success,
    };
  }

  String _formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);

    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
  }
}
