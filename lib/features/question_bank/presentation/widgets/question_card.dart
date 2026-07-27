import 'package:flutter/material.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/themes/app_colors.dart';
import '../../../../core/themes/app_typography.dart';
import '../../../../core/themes/spacings.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../domain/entities/question_entities.dart';
import 'difficulty_badge.dart';
import 'question_content_renderer.dart';
import 'question_type_badge.dart';

// ─── QuestionCardMode ─────────────────────────────────────────────────────────

/// Display mode for [QuestionCard].
enum QuestionCardMode {
  /// Compact layout for dense list views.
  compact,

  /// Expanded layout with more detail visible.
  expanded,
}

// ─── QuestionCard ─────────────────────────────────────────────────────────────

/// A card widget for displaying a question in a list. Shows the question
/// content (truncated), type badge, difficulty badge, subject name, marks,
/// exam type, status indicators, favourite toggle, tag chips, usage count,
/// created-by info, and a popup menu for edit/duplicate/archive/delete.
///
/// ```dart
/// QuestionCard(
///   question: question,
///   subjectName: 'Mathematics',
///   onTap: () => navigateToDetail(question.id),
///   onEdit: () => editQuestion(question.id),
///   onDuplicate: () => duplicateQuestion(question.id),
///   onArchive: () => archiveQuestion(question.id),
///   onDelete: () => deleteQuestion(question.id),
///   onFavouriteToggle: () => toggleFavourite(question.id),
/// )
/// ```
class QuestionCard extends StatelessWidget {
  const QuestionCard({
    super.key,
    required this.question,
    this.subjectName,
    this.topicName,
    this.isFavorited = false,
    this.mode = QuestionCardMode.compact,
    this.onTap,
    this.onEdit,
    this.onDuplicate,
    this.onArchive,
    this.onDelete,
    this.onFavouriteToggle,
  });

  /// The question entity to display.
  final QuestionEntity question;

  /// Display name for the question's subject.
  final String? subjectName;

  /// Display name for the question's topic.
  final String? topicName;

  /// Whether the question is marked as a favourite.
  final bool isFavorited;

  /// Display mode: compact or expanded.
  final QuestionCardMode mode;

  /// Tap callback for the entire card.
  final VoidCallback? onTap;

  /// Edit callback from the popup menu.
  final VoidCallback? onEdit;

  /// Duplicate callback from the popup menu.
  final VoidCallback? onDuplicate;

  /// Archive callback from the popup menu.
  final VoidCallback? onArchive;

  /// Delete callback from the popup menu.
  final VoidCallback? onDelete;

  /// Favourite toggle callback.
  final VoidCallback? onFavouriteToggle;

  // ─── Relative Time Helper ──────────────────────────────────────────

  String _relativeTime(DateTime dateTime) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);

    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    if (diff.inDays < 30) return '${(diff.inDays / 7).floor()}w ago';
    if (diff.inDays < 365) return '${(diff.inDays / 30).floor()}mo ago';
    return '${(diff.inDays / 365).floor()}y ago';
  }

  // ─── Status Badge ──────────────────────────────────────────────────

  Widget _buildStatusBadge(BuildContext context) {
    final cs = context.colorScheme;
    final isDark = context.isDarkMode;

    if (question.isArchived) {
      return _StatusChip(
        label: 'Archived',
        color: const Color(0xFF6B7280),
        isDark: isDark,
      );
    }
    if (question.isPublished) {
      return _StatusChip(
        label: 'Published',
        color: AppColors.success,
        isDark: isDark,
      );
    }
    return _StatusChip(
      label: 'Draft',
      color: AppColors.warning,
      isDark: isDark,
    );
  }

  // ─── Tag Chips ─────────────────────────────────────────────────────

  Widget _buildTagChips(BuildContext context) {
    final cs = context.colorScheme;
    final tags = question.tags;
    const maxVisible = 3;
    final visibleTags = tags.take(maxVisible).toList();
    final remaining = tags.length - maxVisible;

    if (tags.isEmpty) return const SizedBox.shrink();

    return Wrap(
      spacing: Spacings.xs,
      runSpacing: Spacings.xs,
      children: [
        ...visibleTags.map((tag) => Container(
              padding: const EdgeInsets.symmetric(
                horizontal: Spacings.sm,
                vertical: 2.0,
              ),
              decoration: BoxDecoration(
                color: cs.secondaryContainer.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(Spacings.smRadius),
              ),
              child: Text(
                tag.name,
                style: TextStyle(
                  fontFamily: AppTypography.fontFamily,
                  fontSize: 10.0,
                  fontWeight: AppTypography.wMedium,
                  letterSpacing: AppTypography.lsCaption,
                  color: cs.onSecondaryContainer,
                ),
              ),
            ),),
        if (remaining > 0)
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: Spacings.sm,
              vertical: 2.0,
            ),
            decoration: BoxDecoration(
              color: cs.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(Spacings.smRadius),
            ),
            child: Text(
              '+$remaining more',
              style: TextStyle(
                fontFamily: AppTypography.fontFamily,
                fontSize: 10.0,
                fontWeight: AppTypography.wMedium,
                letterSpacing: AppTypography.lsCaption,
                color: cs.onSurfaceVariant,
              ),
            ),
          ),
      ],
    );
  }

  // ─── Popup Menu ────────────────────────────────────────────────────

  Widget _buildPopupMenu(BuildContext context) {
    final cs = context.colorScheme;
    return PopupMenuButton<String>(
      icon: Icon(
        Icons.more_vert_rounded,
        size: Spacings.mdIcon,
        color: cs.onSurfaceVariant,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Spacings.mdRadius),
      ),
      position: PopupMenuPosition.under,
      onSelected: (value) {
        switch (value) {
          case 'edit':
            onEdit?.call();
          case 'duplicate':
            onDuplicate?.call();
          case 'archive':
            onArchive?.call();
          case 'delete':
            onDelete?.call();
        }
      },
      itemBuilder: (ctx) => [
        PopupMenuItem(
          value: 'edit',
          child: Row(
            children: [
              Icon(Icons.edit_outlined, size: Spacings.mdIcon, color: cs.onSurfaceVariant),
              const SizedBox(width: Spacings.md),
              Text('Edit', style: ctx.textTheme.bodyMedium),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'duplicate',
          child: Row(
            children: [
              Icon(Icons.content_copy_rounded, size: Spacings.mdIcon, color: cs.onSurfaceVariant),
              const SizedBox(width: Spacings.md),
              Text('Duplicate', style: ctx.textTheme.bodyMedium),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'archive',
          child: Row(
            children: [
              Icon(
                question.isArchived ? Icons.unarchive_rounded : Icons.archive_outlined,
                size: Spacings.mdIcon,
                color: cs.onSurfaceVariant,
              ),
              const SizedBox(width: Spacings.md),
              Text(
                question.isArchived ? 'Restore' : 'Archive',
                style: ctx.textTheme.bodyMedium,
              ),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'delete',
          child: Row(
            children: [
              Icon(Icons.delete_outline_rounded, size: Spacings.mdIcon, color: AppColors.errorOf(cs.brightness)),
              const SizedBox(width: Spacings.md),
              Text(
                'Delete',
                style: ctx.textTheme.bodyMedium?.copyWith(
                  color: AppColors.errorOf(cs.brightness),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ─── Build ─────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;
    final tt = context.textTheme;
    final isCompact = mode == QuestionCardMode.compact;

    return AppCard(
      onTap: onTap,
      elevation: isCompact ? Spacings.elevationNone : Spacings.elevationSm,
      padding: isCompact
          ? const EdgeInsets.all(Spacings.md)
          : const EdgeInsets.all(Spacings.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Top Row: Badges + Favourite + Menu ────────────────────
          Row(
            children: [
              QuestionTypeBadge(
                type: question.questionType,
                variant: isCompact
                    ? QuestionTypeBadgeVariant.iconOnly
                    : QuestionTypeBadgeVariant.both,
                size: isCompact
                    ? QuestionTypeBadgeSize.small
                    : QuestionTypeBadgeSize.large,
              ),
              const SizedBox(width: Spacings.sm),
              DifficultyBadge(difficulty: question.difficulty),
              const SizedBox(width: Spacings.sm),
              _buildStatusBadge(context),
              const Spacer(),
              // Favourite toggle
              GestureDetector(
                onTap: onFavouriteToggle,
                child: Icon(
                  isFavorited ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                  size: Spacings.mdIcon,
                  color: isFavorited
                      ? const Color(0xFFE11D48)
                      : cs.onSurfaceVariant.withValues(alpha: 0.5),
                ),
              ),
              const SizedBox(width: Spacings.xs),
              _buildPopupMenu(context),
            ],
          ),

          const SizedBox(height: Spacings.md),

          // ── Question Content ──────────────────────────────────────
          QuestionContentRenderer(
            content: question.content,
            attachments: isCompact ? const [] : question.attachments,
            maxLines: isCompact ? 2 : 5,
          ),

          const SizedBox(height: Spacings.md),

          // ── Metadata Row ──────────────────────────────────────────
          Wrap(
            spacing: Spacings.md,
            runSpacing: Spacings.sm,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              // Subject name
              if (subjectName != null)
                _MetadataChip(
                  icon: Icons.book_outlined,
                  label: subjectName!,
                ),
              // Topic name
              if (topicName != null)
                _MetadataChip(
                  icon: Icons.topic_outlined,
                  label: topicName!,
                ),
              // Marks
              _MetadataChip(
                icon: Icons.star_outline_rounded,
                label: '${question.marks} marks',
              ),
              // Exam type
              if (question.examType != null)
                _MetadataChip(
                  icon: Icons.quiz_outlined,
                  label: question.examType!.label,
                ),
              // Usage count
              if (question.usageCount > 0)
                _MetadataChip(
                  icon: Icons.bar_chart_outlined,
                  label: 'Used ${question.usageCount}×',
                ),
            ],
          ),

          // ── Tags ──────────────────────────────────────────────────
          if (question.tags.isNotEmpty) ...[
            const SizedBox(height: Spacings.sm),
            _buildTagChips(context),
          ],

          // ── Footer: Created by + Timestamp ────────────────────────
          if (!isCompact) ...[
            const SizedBox(height: Spacings.md),
            Row(
              children: [
                Icon(
                  Icons.person_outline_rounded,
                  size: Spacings.smIcon,
                  color: cs.onSurfaceVariant.withValues(alpha: 0.6),
                ),
                const SizedBox(width: Spacings.xs),
                Text(
                  question.createdBy ?? 'Unknown',
                  style: tt.bodySmall?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
                ),
                const SizedBox(width: Spacings.md),
                Icon(
                  Icons.access_time_rounded,
                  size: Spacings.smIcon,
                  color: cs.onSurfaceVariant.withValues(alpha: 0.6),
                ),
                const SizedBox(width: Spacings.xs),
                Text(
                  _relativeTime(question.createdAt),
                  style: tt.bodySmall?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Status Chip ──────────────────────────────────────────────────────────────

class _StatusChip extends StatelessWidget {
  const _StatusChip({
    required this.label,
    required this.color,
    required this.isDark,
  });

  final String label;
  final Color color;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Spacings.sm,
        vertical: Spacings.xs,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.25 : 0.12),
        borderRadius: BorderRadius.circular(Spacings.smRadius),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: AppTypography.fontFamily,
          fontSize: 10.0,
          fontWeight: AppTypography.wSemiBold,
          letterSpacing: AppTypography.lsCaption,
          height: 1.40,
          color: isDark ? color.withValues(alpha: 0.9) : color,
        ),
      ),
    );
  }
}

// ─── Metadata Chip ────────────────────────────────────────────────────────────

class _MetadataChip extends StatelessWidget {
  const _MetadataChip({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13.0, color: cs.onSurfaceVariant.withValues(alpha: 0.7)),
        const SizedBox(width: Spacings.xs),
        Text(
          label,
          style: context.textTheme.bodySmall?.copyWith(
            color: cs.onSurfaceVariant,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}
