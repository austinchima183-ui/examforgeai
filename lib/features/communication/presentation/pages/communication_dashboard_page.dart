import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/themes/app_colors.dart';
import '../../../../core/themes/app_typography.dart';
import '../../../../core/themes/spacings.dart';
import '../../../../routing/route_names.dart';
import '../../../../shared/widgets/app_app_bar.dart';
import '../../../../shared/widgets/app_empty_state.dart';
import '../../../../shared/widgets/app_error_state.dart';
import '../../../../shared/widgets/app_loading.dart';
import '../../domain/entities/communication_entities.dart';
import '../../domain/usecases/get_announcements_usecase.dart';
import '../providers/announcement_provider.dart';
import '../providers/communication_dashboard_provider.dart';
import '../providers/conversation_provider.dart';

// ═══════════════════════════════════════════════════════════════════════
// COMMUNICATION DASHBOARD PAGE
// ═══════════════════════════════════════════════════════════════════════

/// Main communication hub page.
///
/// Presents a dashboard with:
/// - Stat cards (conversations, active chats, messages today, announcements,
///   unread notifications, upcoming events, active forums)
/// - Quick action cards (New Message, New Announcement, View Forums,
///   Calendar, AI Assistant)
/// - Recent conversations list (last 5)
/// - Recent announcements list (last 3)
///
/// Uses [ConsumerStatefulWidget] with a private [_State] class pattern,
/// loads data in [initState] via [WidgetsBinding.instance.addPostFrameCallback],
/// and renders a responsive layout using [CustomScrollView] with slivers.
class CommunicationDashboardPage extends ConsumerStatefulWidget {
  const CommunicationDashboardPage({super.key});

  @override
  ConsumerState<CommunicationDashboardPage> createState() => _State();
}

class _State extends ConsumerState<CommunicationDashboardPage> {
  // ─── Lifecycle ──────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(communicationDashboardProvider.notifier).loadDashboard();
      ref.read(conversationProvider.notifier).loadConversations();
      ref.read(announcementProvider.notifier).loadAnnouncements(
        const GetAnnouncementsParams(page: 1, perPage: 5),
      );
    });
  }

  // ─── Build ──────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final dashboardState = ref.watch(communicationDashboardProvider);
    final conversationState = ref.watch(conversationProvider);
    final announcementState = ref.watch(announcementProvider);

    return Scaffold(
      appBar: AppAppBar(
        title: 'Communication Hub',
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () => context.push(RouteNames.notifications),
            tooltip: 'Notifications',
          ),
        ],
      ),
      body: _buildBody(dashboardState, conversationState, announcementState),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // BODY
  // ═══════════════════════════════════════════════════════════════════════

  Widget _buildBody(
    CommunicationDashboardState dashState,
    ConversationState convState,
    AnnouncementState annState,
  ) {
    if (dashState.isLoading && dashState.dashboardData == null) {
      return const Center(child: AppLoadingSpinner(size: AppLoadingSpinnerSize.large));
    }

    if (dashState.error != null && dashState.dashboardData == null) {
      return AppErrorState.genericError(
        message: dashState.error,
        onRetry: () =>
            ref.read(communicationDashboardProvider.notifier).loadDashboard(),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        await Future.wait([
          ref.read(communicationDashboardProvider.notifier).loadDashboard(),
          ref.read(conversationProvider.notifier).loadConversations(),
          ref.read(announcementProvider.notifier).loadAnnouncements(
            const GetAnnouncementsParams(page: 1, perPage: 5),
          ),
        ]);
      },
      child: CustomScrollView(
        slivers: [
          // ─── Stats Grid ─────────────────────────────────────────
          SliverToBoxAdapter(child: _buildStatsGrid(dashState)),

          // ─── Quick Actions ──────────────────────────────────────
          SliverToBoxAdapter(child: _buildQuickActions(context)),

          // ─── Recent Conversations ───────────────────────────────
          SliverToBoxAdapter(
            child: _buildRecentConversations(context, convState),
          ),

          // ─── Recent Announcements ───────────────────────────────
          SliverToBoxAdapter(
            child: _buildRecentAnnouncements(context, annState),
          ),

          const SliverPadding(padding: EdgeInsets.only(bottom: Spacings.xxl)),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // STATS GRID
  // ═══════════════════════════════════════════════════════════════════════

  Widget _buildStatsGrid(CommunicationDashboardState state) {
    final data = state.dashboardData;
    if (data == null) return const SizedBox.shrink();

    final stats = [
      _StatItem(icon: Icons.chat_bubble_outline, label: 'Conversations', value: data.totalConversations, color: AppColors.seed),
      _StatItem(icon: Icons.circle_outlined, label: 'Active Chats', value: data.activeConversations, color: AppColors.success),
      _StatItem(icon: Icons.message_outlined, label: 'Messages Today', value: data.totalMessagesToday, color: AppColors.info),
      _StatItem(icon: Icons.campaign_outlined, label: 'Announcements', value: data.totalAnnouncements, color: const Color(0xFF7C3AED)),
      _StatItem(icon: Icons.notifications_active_outlined, label: 'Unread', value: data.unreadNotifications, color: AppColors.warning),
      _StatItem(icon: Icons.event_outlined, label: 'Upcoming Events', value: data.upcomingEvents.length, color: AppColors.error),
      _StatItem(icon: Icons.forum_outlined, label: 'Active Forums', value: data.activeForums, color: const Color(0xFF06B6D4)),
    ];

    return Padding(
      padding: const EdgeInsets.all(Spacings.lg),
      child: Wrap(
        spacing: Spacings.md,
        runSpacing: Spacings.md,
        children: stats.map((s) => _buildStatCard(s)).toList(),
      ),
    );
  }

  Widget _buildStatCard(_StatItem stat) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Container(
      width: (MediaQuery.of(context).size.width - Spacings.lg * 2 - Spacings.md * 2) / 3,
      constraints: const BoxConstraints(minWidth: 100, maxWidth: 160),
      padding: Spacings.paddingCard,
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: Spacings.borderRadiusMd,
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.3)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(stat.icon, color: stat.color, size: Spacings.lgIcon),
          const SizedBox(height: Spacings.sm),
          Text(
            '${stat.value}',
            style: tt.headlineSmall?.copyWith(
              fontWeight: AppTypography.wBold,
              color: cs.onSurface,
            ),
          ),
          const SizedBox(height: Spacings.xs),
          Text(
            stat.label,
            style: tt.labelSmall?.copyWith(color: cs.onSurfaceVariant),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // QUICK ACTIONS
  // ═══════════════════════════════════════════════════════════════════════

  Widget _buildQuickActions(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    final actions = [
      _QuickAction(icon: Icons.edit_outlined, label: 'New Message', onTap: () {/* TODO: navigate */}),
      _QuickAction(icon: Icons.campaign_outlined, label: 'New Announcement', onTap: () {/* TODO: navigate */}),
      _QuickAction(icon: Icons.forum_outlined, label: 'View Forums', onTap: () {/* TODO: navigate */}),
      _QuickAction(icon: Icons.calendar_month_outlined, label: 'Calendar', onTap: () {/* TODO: navigate */}),
      _QuickAction(icon: Icons.auto_awesome_outlined, label: 'AI Assistant', onTap: () {/* TODO: navigate */}),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: Spacings.lg),
          child: Text(
            'Quick Actions',
            style: tt.titleMedium?.copyWith(
              fontWeight: AppTypography.wSemiBold,
              color: cs.onSurface,
            ),
          ),
        ),
        const SizedBox(height: Spacings.md),
        SizedBox(
          height: 88,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: Spacings.lg),
            itemCount: actions.length,
            separatorBuilder: (_, __) => const SizedBox(width: Spacings.md),
            itemBuilder: (_, i) => _buildQuickActionCard(actions[i]),
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActionCard(_QuickAction action) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Material(
      color: cs.primaryContainer.withValues(alpha: 0.15),
      borderRadius: Spacings.borderRadiusMd,
      child: InkWell(
        onTap: action.onTap,
        borderRadius: Spacings.borderRadiusMd,
        child: Container(
          width: 88,
          padding: const EdgeInsets.symmetric(vertical: Spacings.md, horizontal: Spacings.sm),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(action.icon, color: cs.primary, size: Spacings.mdIcon),
              const SizedBox(height: Spacings.xs),
              Text(
                action.label,
                style: tt.labelSmall?.copyWith(
                  color: cs.onSurface,
                  fontWeight: AppTypography.wMedium,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // RECENT CONVERSATIONS
  // ═══════════════════════════════════════════════════════════════════════

  Widget _buildRecentConversations(BuildContext context, ConversationState state) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final conversations = state.conversations.take(5).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(Spacings.lg, Spacings.xl, Spacings.lg, Spacings.md),
          child: Row(
            children: [
              Text(
                'Recent Conversations',
                style: tt.titleMedium?.copyWith(
                  fontWeight: AppTypography.wSemiBold,
                  color: cs.onSurface,
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: () {/* TODO: navigate to full list */},
                child: Text('See All', style: tt.labelMedium?.copyWith(color: cs.primary)),
              ),
            ],
          ),
        ),
        if (conversations.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: Spacings.lg),
            child: AppEmptyState.noMessages(subtitle: 'Start a conversation to get going.'),
          )
        else
          ...conversations.map((c) => _buildConversationTile(context, c)),
      ],
    );
  }

  Widget _buildConversationTile(BuildContext context, ConversationEntity conv) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final name = conv.name ?? conv.participants.map((p) => p.userName ?? 'Unknown').join(', ');

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: cs.primaryContainer,
        child: Text(
          name.isNotEmpty ? name[0].toUpperCase() : '?',
          style: tt.labelLarge?.copyWith(color: cs.onPrimaryContainer),
        ),
      ),
      title: Text(
        name,
        style: tt.titleSmall?.copyWith(
          fontWeight: conv.unreadCount > 0 ? AppTypography.wBold : AppTypography.wMedium,
          color: cs.onSurface,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        conv.lastMessageText ?? 'No messages yet',
        style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (conv.lastMessageAt != null)
            Text(
              _formatTime(conv.lastMessageAt!),
              style: tt.labelSmall?.copyWith(color: cs.onSurfaceVariant),
            ),
          if (conv.unreadCount > 0) ...[
            const SizedBox(height: Spacings.xs),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: Spacings.sm, vertical: Spacings.xs),
              decoration: BoxDecoration(
                color: cs.primary,
                borderRadius: Spacings.borderRadiusFull,
              ),
              child: Text(
                '${conv.unreadCount}',
                style: tt.labelSmall?.copyWith(color: cs.onPrimary, fontWeight: AppTypography.wBold),
              ),
            ),
          ],
        ],
      ),
      onTap: () {/* TODO: navigate to chat */},
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // RECENT ANNOUNCEMENTS
  // ═══════════════════════════════════════════════════════════════════════

  Widget _buildRecentAnnouncements(BuildContext context, AnnouncementState state) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final announcements = state.announcements.take(3).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(Spacings.lg, Spacings.xl, Spacings.lg, Spacings.md),
          child: Row(
            children: [
              Text(
                'Recent Announcements',
                style: tt.titleMedium?.copyWith(
                  fontWeight: AppTypography.wSemiBold,
                  color: cs.onSurface,
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: () {/* TODO: navigate to full list */},
                child: Text('See All', style: tt.labelMedium?.copyWith(color: cs.primary)),
              ),
            ],
          ),
        ),
        if (announcements.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: Spacings.lg),
            child: AppEmptyState.noData(title: 'No Announcements', subtitle: 'No announcements have been posted yet.'),
          )
        else
          ...announcements.map((a) => _buildAnnouncementTile(context, a)),
      ],
    );
  }

  Widget _buildAnnouncementTile(BuildContext context, AnnouncementEntity ann) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final priorityColor = _priorityColor(ann.priority, cs.brightness);

    return ListTile(
      leading: Container(
        width: 4,
        decoration: BoxDecoration(
          color: priorityColor,
          borderRadius: Spacings.borderRadiusFull,
        ),
      ),
      title: Text(
        ann.title,
        style: tt.titleSmall?.copyWith(
          fontWeight: AppTypography.wSemiBold,
          color: cs.onSurface,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        '${ann.authorName} · ${_formatTime(ann.createdAt)}',
        style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
        maxLines: 1,
      ),
      trailing: ann.isPinned ? Icon(Icons.push_pin, size: Spacings.smIcon, color: cs.onSurfaceVariant) : null,
      onTap: () {/* TODO: navigate to detail */},
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // HELPERS
  // ═══════════════════════════════════════════════════════════════════════

  Color _priorityColor(AnnouncementPriority priority, Brightness brightness) {
    switch (priority) {
      case AnnouncementPriority.urgent:
        return AppColors.errorOf(brightness);
      case AnnouncementPriority.high:
        return AppColors.warningOf(brightness);
      case AnnouncementPriority.normal:
        return AppColors.infoOf(brightness);
      case AnnouncementPriority.low:
        return const Color(0xFF9CA3AF);
    }
  }

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
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

class _StatItem {
  const _StatItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });
  final IconData icon;
  final String label;
  final int value;
  final Color color;
}

class _QuickAction {
  const _QuickAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final VoidCallback onTap;
}
