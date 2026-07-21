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
import '../providers/forum_provider.dart';

// ═══════════════════════════════════════════════════════════════════════
// FORUM DETAIL PAGE
// ═══════════════════════════════════════════════════════════════════════

/// Shows forum info + posts list.
///
/// Features:
/// - Forum header: name, description, type, member count, moderator badges
/// - Posts list: title, author, date, comment count, like count, pinned
/// - FAB to create new post
/// - Sort: Latest, Popular, Pinned
/// - Pull-to-refresh
///
/// Uses [ConsumerStatefulWidget] with a private [_State] class pattern.
class ForumDetailPage extends ConsumerStatefulWidget {
  const ForumDetailPage({super.key, required this.forumId});

  final String forumId;

  @override
  ConsumerState<ForumDetailPage> createState() => _State();
}

class _State extends ConsumerState<ForumDetailPage> {
  // ─── State ──────────────────────────────────────────────────────────

  String _sortBy = 'latest';

  static const _sortOptions = [
    _SortOption(key: 'latest', label: 'Latest'),
    _SortOption(key: 'popular', label: 'Popular'),
    _SortOption(key: 'pinned', label: 'Pinned'),
  ];

  // ─── Lifecycle ──────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(forumProvider.notifier).loadForum(widget.forumId);
      ref.read(forumProvider.notifier).loadForumPosts(widget.forumId);
    });
  }

  // ─── Build ──────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(forumProvider);
    final forum = state.currentForum;

    return Scaffold(
      appBar: AppAppBar(
        title: forum?.name ?? 'Forum',
        actions: [
          PopupMenuButton<String>(
            onSelected: (v) => setState(() => _sortBy = v),
            itemBuilder: (_) => _sortOptions.map((o) => PopupMenuItem(
              value: o.key,
              child: Row(
                children: [
                  if (_sortBy == o.key) Icon(Icons.check, size: Spacings.smIcon, color: Theme.of(context).colorScheme.primary),
                  if (_sortBy == o.key) const SizedBox(width: Spacings.sm),
                  Text(o.label),
                ],
              ),
            )).toList(),
            icon: const Icon(Icons.sort),
          ),
        ],
      ),
      body: _buildBody(state),
      floatingActionButton: FloatingActionButton(
        onPressed: () {/* TODO: navigate to create post */},
        tooltip: 'New Post',
        child: const Icon(Icons.edit_outlined),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // BODY
  // ═══════════════════════════════════════════════════════════════════════

  Widget _buildBody(ForumState state) {
    if (state.isLoading && state.currentForum == null) {
      return const Center(child: AppLoadingSpinner(size: AppLoadingSpinnerSize.large));
    }

    if (state.error != null && state.currentForum == null) {
      return AppErrorState.genericError(
        message: state.error,
        onRetry: () {
          ref.read(forumProvider.notifier).loadForum(widget.forumId);
          ref.read(forumProvider.notifier).loadForumPosts(widget.forumId);
        },
      );
    }

    final forum = state.currentForum;
    final posts = _sortPosts(state.forumPosts);

    return RefreshIndicator(
      onRefresh: () async {
        await ref.read(forumProvider.notifier).loadForumPosts(widget.forumId);
      },
      child: CustomScrollView(
        slivers: [
          // ─── Forum Header ───────────────────────────────────────
          if (forum != null) SliverToBoxAdapter(child: _buildForumHeader(forum)),

          // ─── Posts List ─────────────────────────────────────────
          if (posts.isEmpty)
            SliverFillRemaining(
              child: AppEmptyState.noData(
                title: 'No Posts',
                subtitle: 'Be the first to start a discussion in this forum.',
                actionLabel: 'Create Post',
                onAction: () {/* TODO */},
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: Spacings.lg),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (_, i) => _buildPostCard(posts[i]),
                  childCount: posts.length,
                ),
              ),
            ),

          const SliverPadding(padding: EdgeInsets.only(bottom: Spacings.xxl)),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // FORUM HEADER
  // ═══════════════════════════════════════════════════════════════════════

  Widget _buildForumHeader(DiscussionForumEntity forum) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final typeColor = _forumTypeColor(forum.forumType, cs.brightness);

    return Container(
      padding: const EdgeInsets.all(Spacings.lg),
      color: cs.surfaceContainerLow,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Name + Type
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: typeColor.withOpacity(0.12),
                child: Icon(_forumTypeIcon(forum.forumType), color: typeColor, size: Spacings.lgIcon),
              ),
              const SizedBox(width: Spacings.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(forum.name, style: tt.titleLarge?.copyWith(fontWeight: AppTypography.wBold, color: cs.onSurface)),
                    const SizedBox(height: Spacings.xs),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: Spacings.sm, vertical: 2),
                      decoration: BoxDecoration(
                        color: typeColor.withOpacity(0.12),
                        borderRadius: Spacings.borderRadiusSm,
                      ),
                      child: Text(forum.forumType.label, style: tt.labelSmall?.copyWith(color: typeColor, fontWeight: AppTypography.wMedium)),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Description
          if (forum.description != null && forum.description!.isNotEmpty) ...[
            const SizedBox(height: Spacings.md),
            Text(forum.description!, style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant)),
          ],

          // Stats
          const SizedBox(height: Spacings.md),
          Row(
            children: [
              Icon(Icons.people_outline, size: Spacings.smIcon, color: cs.onSurfaceVariant),
              const SizedBox(width: Spacings.xs),
              Text('${forum.memberCount} members', style: tt.labelSmall?.copyWith(color: cs.onSurfaceVariant)),
              const SizedBox(width: Spacings.lg),
              Icon(Icons.article_outlined, size: Spacings.smIcon, color: cs.onSurfaceVariant),
              const SizedBox(width: Spacings.xs),
              Text('${forum.postCount} posts', style: tt.labelSmall?.copyWith(color: cs.onSurfaceVariant)),
            ],
          ),

          // Moderators
          if (forum.moderatorIds.isNotEmpty) ...[
            const SizedBox(height: Spacings.sm),
            Row(
              children: [
                Icon(Icons.shield_outlined, size: Spacings.smIcon, color: AppColors.warningOf(cs.brightness)),
                const SizedBox(width: Spacings.xs),
                Text('${forum.moderatorIds.length} moderator${forum.moderatorIds.length > 1 ? 's' : ''}', style: tt.labelSmall?.copyWith(color: cs.onSurfaceVariant)),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // POST CARD
  // ═══════════════════════════════════════════════════════════════════════

  Widget _buildPostCard(ForumPostEntity post) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Card(
      elevation: Spacings.elevationNone,
      color: cs.surfaceContainerLow,
      margin: const EdgeInsets.only(bottom: Spacings.md),
      shape: RoundedRectangleBorder(borderRadius: Spacings.borderRadiusMd),
      child: InkWell(
        onTap: () {/* TODO: navigate to post detail */},
        borderRadius: Spacings.borderRadiusMd,
        child: Padding(
          padding: Spacings.paddingCard,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ─── Header ──────────────────────────────────────────
              Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: cs.primaryContainer,
                    child: Text(
                      post.authorName.isNotEmpty ? post.authorName[0].toUpperCase() : '?',
                      style: tt.labelMedium?.copyWith(color: cs.onPrimaryContainer),
                    ),
                  ),
                  const SizedBox(width: Spacings.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(post.authorName, style: tt.labelMedium?.copyWith(fontWeight: AppTypography.wSemiBold, color: cs.onSurface)),
                        Text('${post.authorRole} · ${_formatTimeAgo(post.createdAt)}', style: tt.labelSmall?.copyWith(color: cs.onSurfaceVariant)),
                      ],
                    ),
                  ),
                  if (post.isPinned)
                    Icon(Icons.push_pin, size: Spacings.smIcon, color: cs.primary),
                ],
              ),
              const SizedBox(height: Spacings.md),

              // ─── Title ───────────────────────────────────────────
              Text(
                post.title,
                style: tt.titleSmall?.copyWith(fontWeight: AppTypography.wSemiBold, color: cs.onSurface),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: Spacings.sm),

              // ─── Stats Row ───────────────────────────────────────
              Row(
                children: [
                  Icon(Icons.chat_bubble_outline, size: Spacings.smIcon, color: cs.onSurfaceVariant),
                  const SizedBox(width: Spacings.xs),
                  Text('${post.commentCount}', style: tt.labelSmall?.copyWith(color: cs.onSurfaceVariant)),
                  const SizedBox(width: Spacings.lg),
                  Icon(Icons.thumb_up_outlined, size: Spacings.smIcon, color: cs.onSurfaceVariant),
                  const SizedBox(width: Spacings.xs),
                  Text('${post.likeCount}', style: tt.labelSmall?.copyWith(color: cs.onSurfaceVariant)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // SORT
  // ═══════════════════════════════════════════════════════════════════════

  List<ForumPostEntity> _sortPosts(List<ForumPostEntity> posts) {
    final sorted = List<ForumPostEntity>.from(posts);
    switch (_sortBy) {
      case 'latest':
        sorted.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      case 'popular':
        sorted.sort((a, b) => b.likeCount.compareTo(a.likeCount));
      case 'pinned':
        sorted.sort((a, b) {
          if (a.isPinned != b.isPinned) return a.isPinned ? -1 : 1;
          return b.createdAt.compareTo(a.createdAt);
        });
    }
    return sorted;
  }

  // ═══════════════════════════════════════════════════════════════════════
  // HELPERS
  // ═══════════════════════════════════════════════════════════════════════

  Color _forumTypeColor(ForumType type, Brightness brightness) {
    switch (type) {
      case ForumType.schoolCommunity:
        return AppColors.infoOf(brightness);
      case ForumType.subject:
        return const Color(0xFF7C3AED);
      case ForumType.classForum:
        return AppColors.warningOf(brightness);
      case ForumType.club:
        return AppColors.successOf(brightness);
      case ForumType.department:
        return const Color(0xFF06B6D4);
    }
  }

  IconData _forumTypeIcon(ForumType type) {
    switch (type) {
      case ForumType.schoolCommunity:
        return Icons.groups_outlined;
      case ForumType.subject:
        return Icons.menu_book_outlined;
      case ForumType.classForum:
        return Icons.class_outlined;
      case ForumType.club:
        return Icons.sports_esports_outlined;
      case ForumType.department:
        return Icons.business_outlined;
    }
  }

  String _formatTimeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}

// ═══════════════════════════════════════════════════════════════════════
// PRIVATE HELPER CLASSES
// ═══════════════════════════════════════════════════════════════════════

class _SortOption {
  const _SortOption({required this.key, required this.label});
  final String key;
  final String label;
}
