import 'package:flutter/material.dart';

import '../../../../core/themes/app_colors.dart';
import '../../../../core/themes/app_typography.dart';
import '../../../../core/themes/spacings.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../domain/entities/communication_entities.dart';

// ─── ForumPostCard ────────────────────────────────────────────────────────────

/// A card widget for displaying a forum post preview with title, body
/// excerpt, author info, time, comment count, like count, and pinned
/// indicator.
///
/// ```dart
/// ForumPostCard(
///   post: forumPost,
///   onTap: () => openPost(forumPost.id),
/// )
/// ```
class ForumPostCard extends StatelessWidget {
  const ForumPostCard({
    super.key,
    required this.post,
    this.onTap,
  });

  final ForumPostEntity post;
  final VoidCallback? onTap;

  // ─── Helpers ───────────────────────────────────────────────────────────

  String _relativeTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${dt.day}/${dt.month}';
  }

  String _authorInitial() {
    if (post.authorName.isEmpty) return '?';
    return post.authorName[0].toUpperCase();
  }

  // ─── Author Avatar ────────────────────────────────────────────────────

  Widget _buildAuthorAvatar(BuildContext context) {
    final cs = context.colorScheme;
    final isDark = context.isDarkMode;

    if (post.authorAvatar != null) {
      return CircleAvatar(
        radius: 14,
        backgroundImage: NetworkImage(post.authorAvatar!),
      );
    }

    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: cs.primary.withOpacity(isDark ? 0.25 : 0.12),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          _authorInitial(),
          style: TextStyle(
            fontSize: 12,
            fontWeight: AppTypography.wBold,
            color: cs.primary,
            height: 1.0,
          ),
        ),
      ),
    );
  }

  // ─── Build ─────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;
    final tt = context.textTheme;

    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(Spacings.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Top Row: Author + Time + Pinned ───────────────────────
          Row(
            children: [
              _buildAuthorAvatar(context),
              const SizedBox(width: Spacings.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      post.authorName,
                      style: tt.labelMedium?.copyWith(
                        fontWeight: AppTypography.wSemiBold,
                        color: cs.onSurface,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      post.authorRole,
                      style: tt.labelSmall?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              if (post.isPinned) ...[
                Icon(Icons.push_pin_rounded,
                    size: Spacings.smIcon, color: AppColors.seed),
                const SizedBox(width: Spacings.xs),
              ],
              if (post.isLocked)
                Icon(Icons.lock_outline_rounded,
                    size: Spacings.smIcon, color: cs.onSurfaceVariant),
              const SizedBox(width: Spacings.sm),
              Text(
                _relativeTime(post.createdAt),
                style: tt.labelSmall?.copyWith(
                  color: cs.onSurfaceVariant,
                ),
              ),
            ],
          ),

          const SizedBox(height: Spacings.md),

          // ── Title ─────────────────────────────────────────────────
          Text(
            post.title,
            style: tt.titleSmall?.copyWith(
              fontWeight: AppTypography.wSemiBold,
              color: cs.onSurface,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),

          const SizedBox(height: Spacings.sm),

          // ── Body Excerpt ──────────────────────────────────────────
          Text(
            post.body,
            style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),

          const SizedBox(height: Spacings.md),

          // ── Footer: Comments + Likes ──────────────────────────────
          Row(
            children: [
              Icon(Icons.chat_bubble_outline_rounded,
                  size: Spacings.smIcon, color: cs.onSurfaceVariant),
              const SizedBox(width: Spacings.xs),
              Text(
                '${post.commentCount}',
                style: tt.labelSmall?.copyWith(
                  color: cs.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: Spacings.lg),
              Icon(Icons.thumb_up_outlined,
                  size: Spacings.smIcon, color: cs.onSurfaceVariant),
              const SizedBox(width: Spacings.xs),
              Text(
                '${post.likeCount}',
                style: tt.labelSmall?.copyWith(
                  color: cs.onSurfaceVariant,
                ),
              ),
              if (post.attachments.isNotEmpty) ...[
                const SizedBox(width: Spacings.lg),
                Icon(Icons.attach_file_rounded,
                    size: Spacings.smIcon, color: cs.onSurfaceVariant),
                const SizedBox(width: Spacings.xs),
                Text(
                  '${post.attachments.length}',
                  style: tt.labelSmall?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
