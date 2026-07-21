import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/themes/app_colors.dart';
import '../../../../core/themes/app_typography.dart';
import '../../../../core/themes/spacings.dart';
import '../../../../shared/widgets/app_app_bar.dart';
import '../../../../shared/widgets/app_empty_state.dart';
import '../../../../shared/widgets/app_error_state.dart';
import '../../../../shared/widgets/app_loading.dart';
import '../../domain/entities/communication_entities.dart';
import '../providers/notification_provider.dart';

// ═══════════════════════════════════════════════════════════════════════
// NOTIFICATION CENTER PAGE
// ═══════════════════════════════════════════════════════════════════════

/// Centralized notification list.
///
/// Features:
/// - Filter by category: All, Messages, Assignments, Exams, Results,
///   Attendance, Announcements, System
/// - Filter by read/unread
/// - Mark all as read button
/// - Each tile: icon by category, title, body preview, time, read/unread
/// - Tap to navigate to source (deep link via actionUrl)
/// - Notification preferences gear icon
/// - Pull-to-refresh
///
/// Uses [ConsumerStatefulWidget] with a private [_State] class pattern.
class NotificationCenterPage extends ConsumerStatefulWidget {
  const NotificationCenterPage({super.key});

  @override
  ConsumerState<NotificationCenterPage> createState() => _State();
}

class _State extends ConsumerState<NotificationCenterPage> {
  // ─── State ──────────────────────────────────────────────────────────

  String? _categoryFilter;
  bool _showUnreadOnly = false;
  final Set<String> _dismissedIds = {};

  static const _filterChips = <_FilterChip>[
    _FilterChip(label: 'All', category: null),
    _FilterChip(label: 'Messages', category: 'message'),
    _FilterChip(label: 'Assignments', category: 'assignment'),
    _FilterChip(label: 'Exams', category: 'exam'),
    _FilterChip(label: 'Results', category: 'result'),
    _FilterChip(label: 'Attendance', category: 'attendance'),
    _FilterChip(label: 'Announcements', category: 'announcement'),
    _FilterChip(label: 'System', category: 'system'),
  ];

  // ─── Lifecycle ──────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(notificationProvider.notifier).loadNotifications(
        const GetNotificationsParams(page: 1, perPage: 50),
      );
    });
  }

  // ─── Build ──────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(notificationProvider);

    return Scaffold(
      appBar: AppAppBar(
        title: 'Notifications',
        actions: [
          if (state.unreadCount > 0)
            TextButton(
              onPressed: () => ref.read(notificationProvider.notifier).markAllRead(),
              child: Text(
                'Mark All Read',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: AppTypography.wSemiBold,
                ),
              ),
            ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () {/* TODO: navigate to notification preferences */},
            tooltip: 'Preferences',
          ),
        ],
      ),
      body: _buildBody(state),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // BODY
  // ═══════════════════════════════════════════════════════════════════════

  Widget _buildBody(NotificationState state) {
    if (state.isLoading && state.notifications.isEmpty) {
      return _buildShimmerLoading();
    }

    if (state.error != null && state.notifications.isEmpty) {
      return AppErrorState.genericError(
        message: state.error,
        onRetry: () => ref.read(notificationProvider.notifier).loadNotifications(
          const GetNotificationsParams(page: 1, perPage: 50),
        ),
      );
    }

    final filtered = _filterNotifications(state.notifications);

    return Column(
      children: [
        // ─── Filter Chips ────────────────────────────────────────
        _buildFilterChips(),

        // ─── Unread Toggle ───────────────────────────────────────
        _buildUnreadToggle(state),

        // ─── Notifications List ──────────────────────────────────
        Expanded(
          child: filtered.isEmpty
              ? AppEmptyState.noNotifications(
                  title: _showUnreadOnly ? 'No Unread Notifications' : 'No Notifications',
                  subtitle: _showUnreadOnly ? "You're all caught up!" : 'There are no notifications to display.',
                )
              : RefreshIndicator(
                  onRefresh: () => ref.read(notificationProvider.notifier).loadNotifications(
                    const GetNotificationsParams(page: 1, perPage: 50),
                  ),
                  child: ListView.separated(
                    padding: const EdgeInsets.only(bottom: Spacings.xxl),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const Divider(height: 1, indent: 72),
                    itemBuilder: (_, i) => _buildNotificationTile(filtered[i]),
                  ),
                ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // FILTER CHIPS
  // ═══════════════════════════════════════════════════════════════════════

  Widget _buildFilterChips() {
    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: Spacings.lg, vertical: Spacings.xs),
        children: _filterChips.map((chip) {
          final isSelected = _categoryFilter == chip.category;
          return Padding(
            padding: const EdgeInsets.only(right: Spacings.sm),
            child: FilterChip(
              label: Text(chip.label),
              selected: isSelected,
              onSelected: (_) {
                setState(() => _categoryFilter = isSelected ? null : chip.category);
              },
            ),
          );
        }).toList(),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // UNREAD TOGGLE
  // ═══════════════════════════════════════════════════════════════════════

  Widget _buildUnreadToggle(NotificationState state) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Spacings.lg, vertical: Spacings.xs),
      child: Row(
        children: [
          Text('Unread Only', style: tt.labelMedium?.copyWith(color: cs.onSurface, fontWeight: AppTypography.wMedium)),
          const SizedBox(width: Spacings.sm),
          Switch(
            value: _showUnreadOnly,
            onChanged: (v) => setState(() => _showUnreadOnly = v),
          ),
          const Spacer(),
          if (state.unreadCount > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: Spacings.sm, vertical: Spacings.xs),
              decoration: BoxDecoration(color: cs.primary, borderRadius: Spacings.borderRadiusFull),
              child: Text('${state.unreadCount} unread', style: tt.labelSmall?.copyWith(color: cs.onPrimary, fontWeight: AppTypography.wSemiBold)),
            ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // NOTIFICATION TILE
  // ═══════════════════════════════════════════════════════════════════════

  Widget _buildNotificationTile(CommunicationNotificationEntity notification) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final isUnread = !notification.isRead;
    final categoryColor = _categoryColor(notification.category, cs.brightness);
    final categoryIcon = _categoryIcon(notification.category);

    return ListTile(
      leading: Stack(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: categoryColor.withOpacity(0.12),
              borderRadius: Spacings.borderRadiusMd,
            ),
            child: Icon(categoryIcon, color: categoryColor, size: Spacings.mdIcon),
          ),
          if (isUnread)
            Positioned(
              right: 0,
              top: 0,
              child: Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(color: cs.primary, shape: BoxShape.circle, border: Border.all(color: cs.surface, width: 2)),
              ),
            ),
        ],
      ),
      title: Text(
        notification.title,
        style: tt.titleSmall?.copyWith(
          fontWeight: isUnread ? AppTypography.wBold : AppTypography.wSemiBold,
          color: cs.onSurface,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: Spacings.xs),
          Text(notification.body, style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant), maxLines: 2, overflow: TextOverflow.ellipsis),
          const SizedBox(height: Spacings.xs),
          Row(
            children: [
              Text(_formatTimeAgo(notification.createdAt), style: tt.labelSmall?.copyWith(color: cs.onSurfaceVariant)),
              if (notification.actionLabel != null) ...[
                const Spacer(),
                TextButton(
                  onPressed: () {
                    if (isUnread) ref.read(notificationProvider.notifier).markRead(notification.id);
                    if (notification.actionUrl != null) {/* TODO: deep link navigate */}
                  },
                  style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: Spacings.sm), visualDensity: VisualDensity.compact),
                  child: Text(notification.actionLabel!, style: tt.labelSmall?.copyWith(color: cs.primary, fontWeight: AppTypography.wSemiBold)),
                ),
              ],
            ],
          ),
        ],
      ),
      onTap: () {
        if (isUnread) ref.read(notificationProvider.notifier).markRead(notification.id);
        if (notification.actionUrl != null) {/* TODO: deep link navigate */}
      },
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // SHIMMER LOADING
  // ═══════════════════════════════════════════════════════════════════════

  Widget _buildShimmerLoading() {
    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      child: AppLoadingShimmer(
        child: Padding(
          padding: const EdgeInsets.all(Spacings.lg),
          child: Column(
            children: List.generate(8, (_) => Padding(
              padding: const EdgeInsets.only(bottom: Spacings.lg),
              child: Row(
                children: [
                  AppLoadingShimmer.box(width: 40, height: 40, borderRadius: Spacings.borderRadiusMd),
                  const SizedBox(width: Spacings.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AppLoadingShimmer.box(width: 160, height: 14, borderRadius: Spacings.borderRadiusSm),
                        const SizedBox(height: Spacings.sm),
                        AppLoadingShimmer.box(height: 12, borderRadius: Spacings.borderRadiusSm),
                      ],
                    ),
                  ),
                ],
              ),
            )),
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // FILTERING
  // ═══════════════════════════════════════════════════════════════════════

  List<CommunicationNotificationEntity> _filterNotifications(List<CommunicationNotificationEntity> notifications) {
    return notifications.where((n) {
      if (_dismissedIds.contains(n.id)) return false;
      if (_categoryFilter != null && n.category.value != _categoryFilter) return false;
      if (_showUnreadOnly && n.isRead) return false;
      return true;
    }).toList();
  }

  // ═══════════════════════════════════════════════════════════════════════
  // HELPERS
  // ═══════════════════════════════════════════════════════════════════════

  Color _categoryColor(NotificationCategory category, Brightness brightness) {
    switch (category) {
      case NotificationCategory.message:
        return const Color(0xFF06B6D4);
      case NotificationCategory.assignment:
        return AppColors.warningOf(brightness);
      case NotificationCategory.exam:
        return AppColors.errorOf(brightness);
      case NotificationCategory.result:
        return AppColors.successOf(brightness);
      case NotificationCategory.attendance:
        return AppColors.infoOf(brightness);
      case NotificationCategory.announcement:
        return const Color(0xFF7C3AED);
      case NotificationCategory.system:
        return const Color(0xFF9CA3AF);
      case NotificationCategory.payment:
        return const Color(0xFFF97316);
      case NotificationCategory.general:
        return AppColors.infoOf(brightness);
    }
  }

  IconData _categoryIcon(NotificationCategory category) {
    switch (category) {
      case NotificationCategory.message:
        return Icons.chat_outlined;
      case NotificationCategory.assignment:
        return Icons.assignment_outlined;
      case NotificationCategory.exam:
        return Icons.quiz_outlined;
      case NotificationCategory.result:
        return Icons.bar_chart_outlined;
      case NotificationCategory.attendance:
        return Icons.calendar_today_outlined;
      case NotificationCategory.announcement:
        return Icons.campaign_outlined;
      case NotificationCategory.system:
        return Icons.info_outline;
      case NotificationCategory.payment:
        return Icons.payment_outlined;
      case NotificationCategory.general:
        return Icons.notifications_outlined;
    }
  }

  String _formatTimeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}

// ═══════════════════════════════════════════════════════════════════════
// PRIVATE HELPER CLASSES
// ═══════════════════════════════════════════════════════════════════════

class _FilterChip {
  const _FilterChip({required this.label, this.category});
  final String label;
  final String? category;
}
