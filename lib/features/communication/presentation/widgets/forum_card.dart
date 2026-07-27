import 'package:flutter/material.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/themes/app_colors.dart';
import '../../../../core/themes/app_typography.dart';
import '../../../../core/themes/spacings.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../domain/entities/communication_entities.dart';

// ─── ForumCard ────────────────────────────────────────────────────────────────

/// A card widget for displaying a discussion forum preview with name,
/// description, type badge, member count, post count, and last activity time.
///
/// ```dart
/// ForumCard(
///   forum: forumEntity,
///   onTap: () => openForum(forumEntity.id),
/// )
/// ```
class ForumCard extends StatelessWidget {
  const ForumCard({
    super.key,
    required this.forum,
    this.onTap,
  });

  final DiscussionForumEntity forum;
  final VoidCallback? onTap;

  // ─── Helpers ───────────────────────────────────────────────────────────

  String _relativeTime(DateTime? dt) {
    if (dt == null) return 'No activity';
    final diff = DateTime.now().difference(dt);
    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${dt.day}/${dt.month}';
  }

  Color _typeColor(ForumType type) {
    return switch (type) {
      ForumType.schoolCommunity => AppColors.seed,
      ForumType.subject => const Color(0xFF7C3AED),
      ForumType.classForum => const Color(0xFF0891B2),
      ForumType.club => const Color(0xFFEA580C),
      ForumType.department => const Color(0xFF16A34A),
    };
  }

  IconData _typeIcon(ForumType type) {
    return switch (type) {
      ForumType.schoolCommunity => Icons.groups_rounded,
      ForumType.subject => Icons.menu_book_outlined,
      ForumType.classForum => Icons.class_outlined,
      ForumType.club => Icons.emoji_events_outlined,
      ForumType.department => Icons.corporate_fare_rounded,
    };
  }

  // ─── Type Badge Builder ───────────────────────────────────────────────

  Widget _buildTypeBadge(BuildContext context) {
    final isDark = context.isDarkMode;
    final color = _typeColor(forum.forumType);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Spacings.sm,
        vertical: Spacings.xs,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.25 : 0.12),
        borderRadius: BorderRadius.circular(Spacings.smRadius),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_typeIcon(forum.forumType), size: 12, color: color),
          const SizedBox(width: Spacings.xs),
          Text(
            forum.forumType.label,
            style: TextStyle(
              fontFamily: AppTypography.fontFamily,
              fontSize: 10,
              fontWeight: AppTypography.wSemiBold,
              letterSpacing: AppTypography.lsCaption,
              color: isDark ? color.withValues(alpha: 0.9) : color,
            ),
          ),
        ],
      ),
    );
  }

  // ─── Build ─────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;
    final tt = context.textTheme;
    final isDark = context.isDarkMode;

    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(Spacings.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Top Row: Type badge + Locked ──────────────────────────
          Row(
            children: [
              _buildTypeBadge(context),
              const Spacer(),
              if (forum.isPinned)
                Icon(Icons.push_pin_rounded,
                    size: Spacings.smIcon, color: cs.onSurfaceVariant,),
              if (forum.isLocked) ...[
                const SizedBox(width: Spacings.xs),
                Icon(Icons.lock_outline_rounded,
                    size: Spacings.smIcon, color: cs.onSurfaceVariant,),
              ],
            ],
          ),

          const SizedBox(height: Spacings.md),

          // ── Name ──────────────────────────────────────────────────
          Row(
            children: [
              Expanded(
                child: Text(
                  forum.name,
                  style: tt.titleSmall?.copyWith(
                    fontWeight: AppTypography.wSemiBold,
                    color: cs.onSurface,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),

          // ── Description ───────────────────────────────────────────
          if (forum.description != null &&
              forum.description!.isNotEmpty) ...[
            const SizedBox(height: Spacings.sm),
            Text(
              forum.description!,
              style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],

          const SizedBox(height: Spacings.md),

          // ── Footer: Members + Posts + Last Activity ───────────────
          Row(
            children: [
              Icon(Icons.people_outline_rounded,
                  size: Spacings.smIcon, color: cs.onSurfaceVariant,),
              const SizedBox(width: Spacings.xs),
              Text(
                '${forum.memberCount}',
                style: tt.labelSmall?.copyWith(
                  color: cs.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: Spacings.md),
              Icon(Icons.article_outlined,
                  size: Spacings.smIcon, color: cs.onSurfaceVariant,),
              const SizedBox(width: Spacings.xs),
              Text(
                '${forum.postCount} posts',
                style: tt.labelSmall?.copyWith(
                  color: cs.onSurfaceVariant,
                ),
              ),
              const Spacer(),
              Icon(Icons.access_time_rounded,
                  size: Spacings.smIcon, color: cs.onSurfaceVariant,),
              const SizedBox(width: Spacings.xs),
              Text(
                _relativeTime(forum.lastActivityAt),
                style: tt.labelSmall?.copyWith(
                  color: cs.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
