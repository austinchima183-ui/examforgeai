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
import '../providers/conversation_provider.dart';

// ═══════════════════════════════════════════════════════════════════════
// CONVERSATION LIST PAGE
// ═══════════════════════════════════════════════════════════════════════

/// Lists all conversations with search/filter.
///
/// Features:
/// - Conversation type tabs: All, Direct, Groups, Classes, School-wide
/// - Each tile shows: name/avatars, last message preview, time, unread badge
/// - FAB to start new conversation
/// - Swipe actions: mute, archive, pin
/// - Pull-to-refresh
///
/// Uses [ConsumerStatefulWidget] with a private [_State] class pattern,
/// loads data in [initState] via [WidgetsBinding.instance.addPostFrameCallback].
class ConversationListPage extends ConsumerStatefulWidget {
  const ConversationListPage({super.key});

  @override
  ConsumerState<ConversationListPage> createState() => _State();
}

class _State extends ConsumerState<ConversationListPage> with SingleTickerProviderStateMixin {
  // ─── State ──────────────────────────────────────────────────────────

  late final TabController _tabController;
  String _searchQuery = '';
  final _searchController = TextEditingController();
  bool _isSearching = false;

  static const _tabs = [
    _TabData(label: 'All', type: null),
    _TabData(label: 'Direct', type: ConversationType.direct),
    _TabData(label: 'Groups', type: ConversationType.group),
    _TabData(label: 'Classes', type: ConversationType.classChat),
    _TabData(label: 'School', type: ConversationType.schoolWide),
  ];

  // ─── Lifecycle ──────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(conversationProvider.notifier).loadConversations();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  // ─── Build ──────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(conversationProvider);

    return Scaffold(
      appBar: AppAppBar(
        title: 'Messages',
        isSearchMode: _isSearching,
        searchController: _searchController,
        searchHint: 'Search conversations…',
        onSearchToggle: () => setState(() {
          _isSearching = !_isSearching;
          if (!_isSearching) {
            _searchQuery = '';
            _searchController.clear();
          }
        }),
        onSearchChanged: (q) => setState(() => _searchQuery = q),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          tabs: _tabs.map((t) => Tab(text: t.label)).toList(),
          onTap: (_) => setState(() {}),
        ),
        actions: _isSearching
            ? []
            : [
                IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: () => setState(() => _isSearching = true),
                  tooltip: 'Search',
                ),
              ],
      ),
      body: _buildBody(state),
      floatingActionButton: FloatingActionButton(
        onPressed: () {/* TODO: navigate to create conversation */},
        tooltip: 'New Conversation',
        child: const Icon(Icons.edit_outlined),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // BODY
  // ═══════════════════════════════════════════════════════════════════════

  Widget _buildBody(ConversationState state) {
    if (state.isLoading && state.conversations.isEmpty) {
      return _buildShimmerLoading();
    }

    if (state.error != null && state.conversations.isEmpty) {
      return AppErrorState.genericError(
        message: state.error,
        onRetry: () => ref.read(conversationProvider.notifier).loadConversations(),
      );
    }

    final filtered = _filterConversations(state.conversations);

    if (filtered.isEmpty) {
      return AppEmptyState.noMessages(
        subtitle: _searchQuery.isNotEmpty ? 'No conversations match your search.' : 'Start a new conversation.',
        actionLabel: 'New Message',
        onAction: () {/* TODO: navigate */},
      );
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(conversationProvider.notifier).loadConversations(),
      child: ListView.separated(
        padding: const EdgeInsets.only(bottom: Spacings.xxl),
        itemCount: filtered.length,
        separatorBuilder: (_, __) => const Divider(height: 1, indent: 72),
        itemBuilder: (_, index) => _buildSwipeTile(filtered[index]),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // FILTER
  // ═══════════════════════════════════════════════════════════════════════

  List<ConversationEntity> _filterConversations(List<ConversationEntity> convos) {
    final tabType = _tabs[_tabController.index].type;
    return convos.where((c) {
      if (tabType != null && c.type != tabType) return false;
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final name = (c.name ?? '').toLowerCase();
        final lastMsg = (c.lastMessageText ?? '').toLowerCase();
        if (!name.contains(q) && !lastMsg.contains(q)) return false;
      }
      return true;
    }).toList();
  }

  // ═══════════════════════════════════════════════════════════════════════
  // SWIPE TILE
  // ═══════════════════════════════════════════════════════════════════════

  Widget _buildSwipeTile(ConversationEntity conv) {
    final cs = Theme.of(context).colorScheme;

    return Dismissible(
      key: ValueKey(conv.id),
      background: Container(
        color: AppColors.warningOf(cs.brightness).withOpacity(0.1),
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: Spacings.xl),
        child: Icon(
          conv.isMuted ? Icons.volume_up_outlined : Icons.volume_off_outlined,
          color: AppColors.warningOf(cs.brightness),
        ),
      ),
      secondaryBackground: Container(
        color: AppColors.infoOf(cs.brightness).withOpacity(0.1),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: Spacings.xl),
        child: Icon(Icons.archive_outlined, color: AppColors.infoOf(cs.brightness)),
      ),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          ref.read(conversationProvider.notifier).muteConversation(conv.id);
          return false;
        }
        if (direction == DismissDirection.endToStart) {
          ref.read(conversationProvider.notifier).archiveConversation(conv.id);
          return false;
        }
        return false;
      },
      child: _buildConversationTile(conv),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // CONVERSATION TILE
  // ═══════════════════════════════════════════════════════════════════════

  Widget _buildConversationTile(ConversationEntity conv) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final name = conv.name ?? conv.participants.map((p) => p.userName ?? 'Unknown').join(', ');

    return ListTile(
      leading: Stack(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: cs.primaryContainer,
            child: Text(
              name.isNotEmpty ? name[0].toUpperCase() : '?',
              style: tt.titleMedium?.copyWith(color: cs.onPrimaryContainer),
            ),
          ),
          if (conv.isPinned)
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(color: cs.surface, shape: BoxShape.circle),
                child: Icon(Icons.push_pin, size: 12, color: cs.primary),
              ),
            ),
        ],
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(
              name,
              style: tt.titleSmall?.copyWith(
                fontWeight: conv.unreadCount > 0 ? AppTypography.wBold : AppTypography.wMedium,
                color: cs.onSurface,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (conv.isMuted)
            Padding(
              padding: const EdgeInsets.only(left: Spacings.xs),
              child: Icon(Icons.volume_off, size: Spacings.smIcon, color: cs.onSurfaceVariant),
            ),
        ],
      ),
      subtitle: Row(
        children: [
          Expanded(
            child: Text(
              conv.lastMessageText ?? 'No messages yet',
              style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (conv.lastMessageAt != null)
            Text(
              _formatTime(conv.lastMessageAt!),
              style: tt.labelSmall?.copyWith(
                color: conv.unreadCount > 0 ? cs.primary : cs.onSurfaceVariant,
                fontWeight: conv.unreadCount > 0 ? AppTypography.wSemiBold : AppTypography.wRegular,
              ),
            ),
          if (conv.unreadCount > 0) ...[
            const SizedBox(height: Spacings.xs),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: Spacings.sm, vertical: 2),
              decoration: BoxDecoration(color: cs.primary, borderRadius: Spacings.borderRadiusFull),
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
                  AppLoadingShimmer.box(width: 48, height: 48, shape: BoxShape.circle),
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
  // HELPERS
  // ═══════════════════════════════════════════════════════════════════════

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'Now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    if (diff.inDays < 7) return '${diff.inDays}d';
    return '${dt.day}/${dt.month}';
  }
}

// ═══════════════════════════════════════════════════════════════════════
// PRIVATE HELPER CLASSES
// ═══════════════════════════════════════════════════════════════════════

class _TabData {
  const _TabData({required this.label, this.type});
  final String label;
  final ConversationType? type;
}
