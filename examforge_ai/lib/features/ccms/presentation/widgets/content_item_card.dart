import 'package:flutter/material.dart';

import '../../../../../core/core.dart';
import '../../../../../shared/widgets/widgets.dart';
import '../../domain/entities/ccms_entities.dart';
import 'content_type_badge.dart';
import 'difficulty_indicator.dart';
import 'quality_score_indicator.dart';

/// Card for content library list items.
///
/// Features:
/// - Title (max 2 lines, overflow ellipsis)
/// - Content type badge (colored by type)
/// - Difficulty indicator (color gradient green→red)
/// - Status badge (Draft=grey, Review=amber, Published=green, Archived=red)
/// - Quality score stars (1–5)
/// - Usage count
/// - Created date
/// - AI-generated badge if applicable
/// - Past question badge with year
/// - onTap callback
class ContentItemCard extends StatelessWidget {
  const ContentItemCard({
    super.key,
    required this.content,
    this.onTap,
    this.onEdit,
    this.onPublish,
    this.onArchive,
    this.onAddToCollection,
  });

  /// The content item to display.
  final ContentItem content;

  /// Callback when the card is tapped.
  final VoidCallback? onTap;

  /// Callback when edit is selected.
  final VoidCallback? onEdit;

  /// Callback when publish is selected.
  final VoidCallback? onPublish;

  /// Callback when archive is selected.
  final VoidCallback? onArchive;

  /// Callback when add-to-collection is selected.
  final VoidCallback? onAddToCollection;

  // ─── Color Helpers ──────────────────────────────────────────────────────

  Color _statusColor(ContentStatus status) {
    return switch (status) {
      ContentStatus.draft => const Color(0xFF6B7280), // grey
      ContentStatus.review => const Color(0xFFF59E0B), // amber
      ContentStatus.published => const Color(0xFF16A34A), // green
      ContentStatus.archived => const Color(0xFFEF4444), // red
      ContentStatus.deprecated => const Color(0xFF9333EA), // purple
    };
  }

  IconData _statusIcon(ContentStatus status) {
    return switch (status) {
      ContentStatus.draft => Icons.edit_note_rounded,
      ContentStatus.review => Icons.visibility_rounded,
      ContentStatus.published => Icons.check_circle_rounded,
      ContentStatus.archived => Icons.archive_rounded,
      ContentStatus.deprecated => Icons.block_rounded,
    };
  }

  // ─── Date Formatter ─────────────────────────────────────────────────────

  String _formatDate(DateTime date) {
    const months = [
      '',
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${date.day} ${months[date.month]} ${date.year}';
  }

  // ─── Build ──────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;
    final tt = context.textTheme;
    final isDark = context.isDarkMode;
    final statusColor = _statusColor(content.status);
    final isAiGenerated = content.isAiGenerated ?? false;
    final isPastQuestion = content.isPastQuestion ?? false;

    return AppCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Top row: type badge + status + AI/past badges + menu ────
          Row(
            children: [
              ContentTypeBadge(contentType: content.contentType),
              const SizedBox(width: Spacings.sm),
              // Status badge
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: Spacings.sm,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: isDark ? 0.20 : 0.12),
                  borderRadius: Spacings.borderRadiusSm,
                  border: Border.all(
                    color: statusColor.withValues(alpha: 0.25),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _statusIcon(content.status),
                      size: 12,
                      color: statusColor,
                    ),
                    const SizedBox(width: 2),
                    Text(
                      content.status.label,
                      style: AppTypography.labelSmall!.copyWith(
                        color: statusColor,
                        fontWeight: AppTypography.wSemiBold,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),

              // AI-generated badge
              if (isAiGenerated)
                Tooltip(
                  message: 'AI Generated',
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: Spacings.xs,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.seed.withValues(alpha: 0.12),
                      borderRadius: Spacings.borderRadiusSm,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.auto_awesome_rounded,
                          size: 12,
                          color: AppColors.seed,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          'AI',
                          style: AppTypography.labelSmall!.copyWith(
                            color: AppColors.seed,
                            fontWeight: AppTypography.wSemiBold,
                            fontSize: 9,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              // Past question badge with year
              if (isPastQuestion) ...[
                const SizedBox(width: Spacings.xs),
                Tooltip(
                  message: content.pastExamYear != null
                      ? 'Past Question ${content.pastExamYear}'
                      : 'Past Question',
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: Spacings.xs,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.warning.withValues(alpha: 0.12),
                      borderRadius: Spacings.borderRadiusSm,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.history_edu_rounded,
                          size: 12,
                          color: AppColors.warning,
                        ),
                        if (content.pastExamYear != null) ...[
                          const SizedBox(width: 2),
                          Text(
                            content.pastExamYear!,
                            style: AppTypography.labelSmall!.copyWith(
                              color: AppColors.warning,
                              fontWeight: AppTypography.wSemiBold,
                              fontSize: 9,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],

              // Action menu
              PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'edit' && onEdit != null) onEdit!();
                  if (value == 'publish' && onPublish != null) onPublish!();
                  if (value == 'archive' && onArchive != null) onArchive!();
                  if (value == 'collection' && onAddToCollection != null) {
                    onAddToCollection!();
                  }
                },
                itemBuilder: (context) => [
                  if (onEdit != null)
                    const PopupMenuItem(
                      value: 'edit',
                      child: Text('Edit'),
                    ),
                  if (onPublish != null &&
                      content.status != ContentStatus.published)
                    const PopupMenuItem(
                      value: 'publish',
                      child: Text('Publish'),
                    ),
                  if (onArchive != null &&
                      content.status != ContentStatus.archived)
                    const PopupMenuItem(
                      value: 'archive',
                      child: Text('Archive'),
                    ),
                  if (onAddToCollection != null)
                    const PopupMenuItem(
                      value: 'collection',
                      child: Text('Add to Collection'),
                    ),
                ],
              ),
            ],
          ),
          const SizedBox(height: Spacings.sm),

          // ── Title ───────────────────────────────────────────────────
          Text(
            content.title,
            style: tt.titleSmall?.copyWith(
              fontWeight: AppTypography.wSemiBold,
              color: cs.onSurface,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: Spacings.sm),

          // ── Bottom row: difficulty + quality + usage + date ──────────
          Row(
            children: [
              // Difficulty indicator
              if (content.difficultyLevel != null)
                DifficultyIndicator(
                  level: content.difficultyLevel!,
                  compact: true,
                ),
              if (content.difficultyLevel != null)
                const SizedBox(width: Spacings.md),

              // Quality score
              if (content.averageQualityScore != null) ...[
                QualityScoreIndicator(
                  score: content.averageQualityScore!,
                  size: QualityScoreSize.small,
                ),
                const SizedBox(width: Spacings.md),
              ],

              // Usage count
              if (content.usageCount != null && content.usageCount! > 0) ...[
                Icon(
                  Icons.visibility_outlined,
                  size: 14,
                  color: cs.onSurfaceVariant,
                ),
                const SizedBox(width: 2),
                Text(
                  '${content.usageCount}',
                  style: tt.bodySmall?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
                ),
                const SizedBox(width: Spacings.md),
              ],

              const Spacer(),

              // Created date
              Icon(
                Icons.calendar_today_outlined,
                size: 12,
                color: cs.onSurfaceVariant.withValues(alpha: 0.6),
              ),
              const SizedBox(width: 2),
              Text(
                _formatDate(content.createdAt),
                style: tt.bodySmall?.copyWith(
                  color: cs.onSurfaceVariant,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
