import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/themes/app_colors.dart';
import '../../../../core/themes/spacings.dart';
import '../../domain/entities/workspace_expansion_entities.dart';
import '../../domain/usecases/add_comment_usecase.dart';
import '../providers/collaboration_provider.dart';

/// A widget for displaying and adding comments on a resource.
///
/// Shows a list of threaded comments with author info, timestamps, reply
/// and resolve buttons, and a text field at the bottom for adding new
/// comments. Follows Material 3 design patterns.
class CommentsSection extends ConsumerStatefulWidget {
  /// The type of resource being commented on (e.g. 'lesson_plan').
  final String resourceType;

  /// The unique ID of the resource.
  final String resourceId;

  const CommentsSection({
    super.key,
    required this.resourceType,
    required this.resourceId,
  });

  @override
  ConsumerState<CommentsSection> createState() => _CommentsSectionState();
}

class _CommentsSectionState extends ConsumerState<CommentsSection> {
  final _commentController = TextEditingController();
  String? _replyingToCommentId;

  @override
  void initState() {
    super.initState();
    // Load comments on init.
    Future.microtask(() {
      ref.read(collaborationProvider.notifier).loadComments(
            widget.resourceType,
            widget.resourceId,
          );
    });
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  // ─── Build ────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    final state = ref.watch(collaborationProvider);
    final comments = state.comments;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // ── Section Header ────────────────────────────────────────────
        Row(
          children: [
            Icon(
              Icons.chat_bubble_outline,
              size: Spacings.mdIcon - 4,
              color: colorScheme.primary,
            ),
            const SizedBox(width: Spacings.sm),
            Text(
              'Comments (${comments.length})',
              style: context.textTheme.titleSmall,
            ),
          ],
        ),
        const SizedBox(height: Spacings.md),

        // ── Comments List ─────────────────────────────────────────────
        if (state.isLoading)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(Spacings.xl),
              child: CircularProgressIndicator(),
            ),
          )
        else if (comments.isEmpty)
          _buildEmptyState(context)
        else
          _buildCommentsList(context, comments),

        const SizedBox(height: Spacings.md),

        // ── Add Comment ───────────────────────────────────────────────
        _buildAddCommentField(context, state),
      ],
    );
  }

  // ─── Empty State ─────────────────────────────────────────────────────

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(Spacings.xl),
        child: Column(
          children: [
            Icon(
              Icons.chat_outlined,
              size: Spacings.xlIcon,
              color: context.colorScheme.onSurfaceVariant.withOpacity(0.5),
            ),
            const SizedBox(height: Spacings.md),
            Text(
              'No comments yet',
              style: context.textTheme.bodyMedium?.copyWith(
                color: context.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: Spacings.xs),
            Text(
              'Start the conversation by adding a comment.',
              style: context.textTheme.bodySmall?.copyWith(
                color: context.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // ─── Comments List ───────────────────────────────────────────────────

  Widget _buildCommentsList(
    BuildContext context,
    List<CollaborationCommentEntity> comments,
  ) {
    // Separate top-level comments and replies.
    final topLevelComments =
        comments.where((c) => c.parentCommentId == null).toList();
    final replyMap = <String, List<CollaborationCommentEntity>>{};
    for (final comment in comments) {
      if (comment.parentCommentId != null) {
        replyMap
            .putIfAbsent(comment.parentCommentId!, () => [])
            .add(comment);
      }
    }

    return ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: 400),
      child: ListView.separated(
        shrinkWrap: true,
        itemCount: topLevelComments.length,
        separatorBuilder: (_, __) => const Divider(height: Spacings.lg),
        itemBuilder: (context, index) {
          final comment = topLevelComments[index];
          final replies = replyMap[comment.id] ?? [];
          return _CommentTile(
            comment: comment,
            replies: replies,
            onReply: () {
              setState(() {
                _replyingToCommentId = comment.id;
              });
              _commentController.requestFocus();
            },
            onResolve: () =>
                ref.read(collaborationProvider.notifier).resolveComment(comment.id),
          );
        },
      ),
    );
  }

  // ─── Add Comment Field ───────────────────────────────────────────────

  Widget _buildAddCommentField(BuildContext context, CollaborationState state) {
    final colorScheme = context.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Replying indicator
        if (_replyingToCommentId != null)
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: Spacings.md,
              vertical: Spacings.sm,
            ),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest.withOpacity(0.5),
              borderRadius: Spacings.borderRadiusMd,
            ),
            child: Row(
              children: [
                Icon(
                  Icons.reply,
                  size: Spacings.smIcon,
                  color: colorScheme.primary,
                ),
                const SizedBox(width: Spacings.xs),
                Text(
                  'Replying to comment',
                  style: context.textTheme.labelSmall?.copyWith(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _replyingToCommentId = null;
                    });
                  },
                  child: Icon(
                    Icons.close,
                    size: Spacings.smIcon,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        if (_replyingToCommentId != null)
          const SizedBox(height: Spacings.sm),

        // Input row
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: TextField(
                controller: _commentController,
                maxLines: 3,
                minLines: 1,
                textInputAction: TextInputAction.newline,
                decoration: InputDecoration(
                  hintText: _replyingToCommentId != null
                      ? 'Write a reply...'
                      : 'Add a comment...',
                  isDense: true,
                  contentPadding: Spacings.paddingInput,
                  border: OutlineInputBorder(
                    borderRadius: Spacings.borderRadiusMd,
                  ),
                ),
              ),
            ),
            const SizedBox(width: Spacings.sm),
            FilledButton(
              onPressed: state.isCommenting ? null : _onSubmit,
              style: FilledButton.styleFrom(
                minimumSize: const Size(44, 44),
                padding: EdgeInsets.zero,
                shape: RoundedRectangleBorder(
                  borderRadius: Spacings.borderRadiusMd,
                ),
              ),
              child: state.isCommenting
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.send, size: 20),
            ),
          ],
        ),
      ],
    );
  }

  // ─── Submit Handler ───────────────────────────────────────────────────

  Future<void> _onSubmit() async {
    final content = _commentController.text.trim();
    if (content.isEmpty) return;

    await ref.read(collaborationProvider.notifier).addComment(
          AddCommentParams(
            resourceType: widget.resourceType,
            resourceId: widget.resourceId,
            content: content,
            parentCommentId: _replyingToCommentId,
          ),
        );

    if (mounted) {
      final state = ref.read(collaborationProvider);
      if (state.error == null) {
        _commentController.clear();
        setState(() {
          _replyingToCommentId = null;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(state.error ?? 'Failed to add comment'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }
}

// ═══════════════════════════════════════════════════════════════════════
// PRIVATE: Comment Tile
// ═══════════════════════════════════════════════════════════════════════

class _CommentTile extends StatelessWidget {
  final CollaborationCommentEntity comment;
  final List<CollaborationCommentEntity> replies;
  final VoidCallback onReply;
  final VoidCallback onResolve;

  const _CommentTile({
    required this.comment,
    required this.replies,
    required this.onReply,
    required this.onResolve,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Main Comment ──────────────────────────────────────────────
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Avatar
            CircleAvatar(
              radius: 16,
              backgroundColor: colorScheme.primary.withOpacity(0.12),
              child: Text(
                comment.authorId.isNotEmpty
                    ? comment.authorId.substring(0, 1).toUpperCase()
                    : '?',
                style: context.textTheme.labelMedium?.copyWith(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: Spacings.md),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Author + timestamp
                  Row(
                    children: [
                      Text(
                        comment.authorId,
                        style: context.textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: Spacings.sm),
                      Text(
                        _formatTimestamp(comment.createdAt),
                        style: context.textTheme.labelSmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      if (comment.isResolved) ...[
                        const SizedBox(width: Spacings.sm),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: Spacings.sm,
                            vertical: Spacings.xs,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.success.withOpacity(0.1),
                            borderRadius: Spacings.borderRadiusSm,
                          ),
                          child: Text(
                            'Resolved',
                            style: context.textTheme.labelSmall?.copyWith(
                              color: AppColors.success,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: Spacings.xs),

                  // Comment text
                  Text(
                    comment.content,
                    style: context.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: Spacings.sm),

                  // Action buttons
                  Row(
                    children: [
                      _ActionButton(
                        icon: Icons.reply,
                        label: 'Reply',
                        onTap: onReply,
                      ),
                      if (comment.parentCommentId == null && !comment.isResolved)
                        Padding(
                          padding: const EdgeInsets.only(left: Spacings.md),
                          child: _ActionButton(
                            icon: Icons.check_circle_outline,
                            label: 'Resolve',
                            onTap: onResolve,
                            color: AppColors.success,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),

        // ── Replies ───────────────────────────────────────────────────
        if (replies.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(left: Spacings.xxl),
            child: Column(
              children: replies.map((reply) {
                return Padding(
                  padding: const EdgeInsets.only(top: Spacings.md),
                  child: _ReplyTile(reply: reply),
                );
              }).toList(),
            ),
          ),
      ],
    );
  }

  String _formatTimestamp(DateTime dateTime) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);

    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
  }
}

// ═══════════════════════════════════════════════════════════════════════
// PRIVATE: Reply Tile
// ═══════════════════════════════════════════════════════════════════════

class _ReplyTile extends StatelessWidget {
  final CollaborationCommentEntity reply;

  const _ReplyTile({required this.reply});

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: 12,
          backgroundColor: colorScheme.tertiary.withOpacity(0.12),
          child: Text(
            reply.authorId.isNotEmpty
                ? reply.authorId.substring(0, 1).toUpperCase()
                : '?',
            style: context.textTheme.labelSmall?.copyWith(
              color: colorScheme.tertiary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(width: Spacings.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    reply.authorId,
                    style: context.textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: Spacings.sm),
                  Text(
                    _formatTimestamp(reply.createdAt),
                    style: context.textTheme.labelSmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: Spacings.xs),
              Text(reply.content, style: context.textTheme.bodySmall),
            ],
          ),
        ),
      ],
    );
  }

  String _formatTimestamp(DateTime dateTime) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
  }
}

// ═══════════════════════════════════════════════════════════════════════
// PRIVATE: Action Button
// ═══════════════════════════════════════════════════════════════════════

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? context.colorScheme.onSurfaceVariant;

    return InkWell(
      onTap: onTap,
      borderRadius: Spacings.borderRadiusSm,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: Spacings.sm,
          vertical: Spacings.xs,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: effectiveColor),
            const SizedBox(width: Spacings.xs),
            Text(
              label,
              style: context.textTheme.labelSmall?.copyWith(
                color: effectiveColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
