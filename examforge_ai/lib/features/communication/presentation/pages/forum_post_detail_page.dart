import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/themes/app_typography.dart';
import '../../../../core/themes/spacings.dart';
import '../../../../shared/widgets/app_app_bar.dart';
import '../../../../shared/widgets/app_error_state.dart';
import '../../../../shared/widgets/app_loading.dart';
import '../../domain/entities/communication_entities.dart';
import '../../domain/usecases/create_forum_comment_usecase.dart';
import '../providers/forum_provider.dart';

// ═══════════════════════════════════════════════════════════════════════
// FORUM POST DETAIL PAGE
// ═══════════════════════════════════════════════════════════════════════

/// Full post view with comments.
///
/// Features:
/// - Post: title, body, author info, attachments, like button, report button
/// - Comments section with threaded replies
/// - Add comment input
/// - Sort comments: Newest, Oldest
///
/// Uses [ConsumerStatefulWidget] with a private [_State] class pattern.
class ForumPostDetailPage extends ConsumerStatefulWidget {
  const ForumPostDetailPage({
    super.key,
    required this.forumId,
    required this.postId,
  });

  final String forumId;
  final String postId;

  @override
  ConsumerState<ForumPostDetailPage> createState() => _State();
}

class _State extends ConsumerState<ForumPostDetailPage> {
  // ─── State ──────────────────────────────────────────────────────────

  final _commentController = TextEditingController();
  String _commentSort = 'newest';
  bool _isLiked = false;

  // ─── Lifecycle ──────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(forumProvider.notifier).loadForumPosts(widget.forumId);
      ref.read(forumProvider.notifier).loadForumComments(widget.postId);
    });
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  // ─── Build ──────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(forumProvider);
    final post = state.forumPosts.where((p) => p.id == widget.postId).firstOrNull;

    return Scaffold(
      appBar: AppAppBar(
        title: 'Post',
        actions: [
          PopupMenuButton<String>(
            onSelected: (v) => setState(() => _commentSort = v),
            itemBuilder: (_) => [
              PopupMenuItem(value: 'newest', child: Row(children: [if (_commentSort == 'newest') Icon(Icons.check, size: Spacings.smIcon, color: Theme.of(context).colorScheme.primary), const SizedBox(width: Spacings.sm), const Text('Newest')])),
              PopupMenuItem(value: 'oldest', child: Row(children: [if (_commentSort == 'oldest') Icon(Icons.check, size: Spacings.smIcon, color: Theme.of(context).colorScheme.primary), const SizedBox(width: Spacings.sm), const Text('Oldest')])),
            ],
          ),
        ],
      ),
      body: _buildBody(state, post),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // BODY
  // ═══════════════════════════════════════════════════════════════════════

  Widget _buildBody(ForumState state, ForumPostEntity? post) {
    if (state.isLoading && post == null) {
      return const Center(child: AppLoadingSpinner(size: AppLoadingSpinnerSize.large));
    }

    if (post == null) {
      return AppErrorState.notFoundError(
        onRetry: () => ref.read(forumProvider.notifier).loadForumPosts(widget.forumId),
      );
    }

    final comments = _sortComments(state.forumComments);

    return Column(
      children: [
        Expanded(
          child: RefreshIndicator(
            onRefresh: () => ref.read(forumProvider.notifier).loadForumComments(widget.postId),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(Spacings.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ─── Post Content ────────────────────────────────
                  _buildPostContent(post),
                  const SizedBox(height: Spacings.xl),

                  // ─── Comments Section ────────────────────────────
                  _buildCommentsSection(comments),
                ],
              ),
            ),
          ),
        ),

        // ─── Add Comment Input ───────────────────────────────────
        _buildCommentInput(state),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // POST CONTENT
  // ═══════════════════════════════════════════════════════════════════════

  Widget _buildPostContent(ForumPostEntity post) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ─── Author Row ──────────────────────────────────────
        Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: cs.primaryContainer,
              child: Text(
                post.authorName.isNotEmpty ? post.authorName[0].toUpperCase() : '?',
                style: tt.labelLarge?.copyWith(color: cs.onPrimaryContainer),
              ),
            ),
            const SizedBox(width: Spacings.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(post.authorName, style: tt.titleSmall?.copyWith(fontWeight: AppTypography.wSemiBold, color: cs.onSurface)),
                  Text('${post.authorRole} · ${_formatTimeAgo(post.createdAt)}', style: tt.labelSmall?.copyWith(color: cs.onSurfaceVariant)),
                ],
              ),
            ),
            if (post.isPinned)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: Spacings.sm, vertical: Spacings.xs),
                decoration: BoxDecoration(color: cs.primaryContainer.withValues(alpha: 0.3), borderRadius: Spacings.borderRadiusSm),
                child: Row(children: [Icon(Icons.push_pin, size: Spacings.smIcon, color: cs.primary), const SizedBox(width: Spacings.xs), Text('Pinned', style: tt.labelSmall?.copyWith(color: cs.primary))]),
              ),
          ],
        ),
        const SizedBox(height: Spacings.lg),

        // ─── Title ───────────────────────────────────────────
        Text(post.title, style: tt.headlineSmall?.copyWith(fontWeight: AppTypography.wBold, color: cs.onSurface)),

        const SizedBox(height: Spacings.md),

        // ─── Body ────────────────────────────────────────────
        Text(post.body, style: tt.bodyLarge?.copyWith(color: cs.onSurface, height: 1.6)),

        // ─── Attachments ─────────────────────────────────────
        if (post.attachments.isNotEmpty) ...[
          const SizedBox(height: Spacings.lg),
          Text('Attachments', style: tt.titleSmall?.copyWith(fontWeight: AppTypography.wSemiBold, color: cs.onSurface)),
          const SizedBox(height: Spacings.sm),
          ...post.attachments.map((att) => Card(
            elevation: Spacings.elevationNone,
            color: cs.surfaceContainerHigh,
            child: ListTile(
              leading: Icon(Icons.insert_drive_file_outlined, color: cs.primary),
              title: Text(att['fileName'] ?? 'Attachment', style: tt.bodySmall, maxLines: 1, overflow: TextOverflow.ellipsis),
              trailing: Icon(Icons.download_outlined, color: cs.primary),
              contentPadding: const EdgeInsets.symmetric(horizontal: Spacings.md),
            ),
          ),),
        ],

        // ─── Actions ─────────────────────────────────────────
        const SizedBox(height: Spacings.lg),
        Row(
          children: [
            TextButton.icon(
              onPressed: () => setState(() => _isLiked = !_isLiked),
              icon: Icon(_isLiked ? Icons.thumb_up : Icons.thumb_up_outlined, size: Spacings.mdIcon, color: _isLiked ? cs.primary : cs.onSurfaceVariant),
              label: Text('${post.likeCount + (_isLiked ? 1 : 0)}', style: tt.labelMedium?.copyWith(color: _isLiked ? cs.primary : cs.onSurfaceVariant)),
            ),
            const SizedBox(width: Spacings.md),
            TextButton.icon(
              onPressed: () {/* TODO: report */},
              icon: Icon(Icons.flag_outlined, size: Spacings.mdIcon, color: cs.onSurfaceVariant),
              label: Text('Report', style: tt.labelMedium?.copyWith(color: cs.onSurfaceVariant)),
            ),
          ],
        ),

        const Divider(),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // COMMENTS SECTION
  // ═══════════════════════════════════════════════════════════════════════

  Widget _buildCommentsSection(List<ForumCommentEntity> comments) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Comments (${comments.length})', style: tt.titleMedium?.copyWith(fontWeight: AppTypography.wSemiBold, color: cs.onSurface)),
        const SizedBox(height: Spacings.md),
        if (comments.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: Spacings.xxl),
              child: Text('No comments yet. Be the first to respond!', style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant)),
            ),
          )
        else
          ...comments.map((c) => _buildCommentTile(c)),
      ],
    );
  }

  Widget _buildCommentTile(ForumCommentEntity comment) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final isReply = comment.parentCommentId != null;

    return Padding(
      padding: EdgeInsets.only(left: isReply ? Spacings.xl : 0, bottom: Spacings.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 14,
                backgroundColor: cs.secondaryContainer,
                child: Text(
                  comment.authorName.isNotEmpty ? comment.authorName[0].toUpperCase() : '?',
                  style: tt.labelSmall?.copyWith(color: cs.onSecondaryContainer),
                ),
              ),
              const SizedBox(width: Spacings.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(comment.authorName, style: tt.labelMedium?.copyWith(fontWeight: AppTypography.wSemiBold, color: cs.onSurface)),
                        const SizedBox(width: Spacings.sm),
                        Text(_formatTimeAgo(comment.createdAt), style: tt.labelSmall?.copyWith(color: cs.onSurfaceVariant)),
                      ],
                    ),
                    const SizedBox(height: Spacings.xs),
                    Text(comment.body, style: tt.bodyMedium?.copyWith(color: cs.onSurface, height: 1.5)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // COMMENT INPUT
  // ═══════════════════════════════════════════════════════════════════════

  Widget _buildCommentInput(ForumState state) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: Spacings.lg, vertical: Spacings.md),
      decoration: BoxDecoration(
        color: cs.surface,
        border: Border(top: BorderSide(color: cs.outlineVariant)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _commentController,
                decoration: InputDecoration(
                  hintText: 'Add a comment…',
                  border: const OutlineInputBorder(
                    borderRadius: Spacings.borderRadiusXl,
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: cs.surfaceContainerHigh,
                  contentPadding: const EdgeInsets.symmetric(horizontal: Spacings.md, vertical: Spacings.sm),
                ),
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _submitComment(),
              ),
            ),
            const SizedBox(width: Spacings.sm),
            IconButton(
              icon: state.isCreating
                  ? const SizedBox(width: 24, height: 24, child: AppLoadingSpinner(size: AppLoadingSpinnerSize.small))
                  : const Icon(Icons.send_rounded),
              onPressed: state.isCreating ? null : _submitComment,
              color: cs.primary,
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // ACTIONS
  // ═══════════════════════════════════════════════════════════════════════

  void _submitComment() {
    final text = _commentController.text.trim();
    if (text.isEmpty) return;

    ref.read(forumProvider.notifier).createForumComment(
      CreateForumCommentParams(
        postId: widget.postId,
        forumId: widget.forumId,
        body: text,
      ),
    );
    _commentController.clear();
  }

  // ═══════════════════════════════════════════════════════════════════════
  // SORT & HELPERS
  // ═══════════════════════════════════════════════════════════════════════

  List<ForumCommentEntity> _sortComments(List<ForumCommentEntity> comments) {
    final sorted = List<ForumCommentEntity>.from(comments);
    if (_commentSort == 'newest') {
      sorted.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    } else {
      sorted.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    }
    return sorted;
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
