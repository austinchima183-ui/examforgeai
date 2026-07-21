import 'package:flutter/material.dart';

import '../../../../core/themes/app_colors.dart';
import '../../../../core/themes/app_typography.dart';
import '../../../../core/themes/spacings.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../domain/entities/exam_template_entities.dart';

// ═══════════════════════════════════════════════════════════════════════
// EXAM TEMPLATE CARD
// ═══════════════════════════════════════════════════════════════════════

/// Card for displaying exam templates in a list or grid layout.
///
/// Shows the template name, description, category badge, subject/class
/// info, time limit, total marks, usage count, and a "Use Template"
/// quick action button.
class ExamTemplateCard extends StatelessWidget {
  const ExamTemplateCard({
    super.key,
    required this.template,
    this.onUseTemplate,
    this.onTap,
    this.onDelete,
  });

  /// The exam template entity to display.
  final ExamTemplateEntity template;

  /// Callback when the "Use Template" button is tapped.
  final VoidCallback? onUseTemplate;

  /// Callback when the card itself is tapped.
  final VoidCallback? onTap;

  /// Callback when the delete action is triggered.
  final VoidCallback? onDelete;

  // ─── Category Color Mapping ────────────────────────────────────────────

  Color _categoryColor(BuildContext context) {
    final isDark = context.isDarkMode;
    return switch (template.category) {
      TemplateCategory.waecPrep => const Color(0xFF059669),
      TemplateCategory.necoPrep => const Color(0xFFD97706),
      TemplateCategory.jambPrep => const Color(0xFF2563EB),
      TemplateCategory.becePrep => const Color(0xFF7C3AED),
      TemplateCategory.certification => const Color(0xFFDC2626),
      TemplateCategory.schoolExam => isDark
          ? AppColors.lightScheme.primary
          : AppColors.seed,
      TemplateCategory.custom => const Color(0xFF6B7280),
    };
  }

  IconData _categoryIcon() {
    return switch (template.category) {
      TemplateCategory.waecPrep => Icons.emoji_events_rounded,
      TemplateCategory.necoPrep => Icons.military_tech_rounded,
      TemplateCategory.jambPrep => Icons.track_changes_rounded,
      TemplateCategory.becePrep => Icons.menu_book_rounded,
      TemplateCategory.certification => Icons.verified_rounded,
      TemplateCategory.schoolExam => Icons.school_rounded,
      TemplateCategory.custom => Icons.tune_rounded,
    };
  }

  String _formatDate(DateTime dt) {
    const months = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[dt.month]} ${dt.day}, ${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;
    final tt = context.textTheme;
    final isDark = context.isDarkMode;
    final categoryColor = _categoryColor(context);

    return AppCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Top Row: Name + Category Badge ──────────────────────────
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  template.name,
                  style: tt.titleMedium?.copyWith(
                    fontWeight: AppTypography.wSemiBold,
                    color: cs.onSurface,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: Spacings.sm),
              _buildCategoryBadge(context, categoryColor),
            ],
          ),

          // ── Description ─────────────────────────────────────────────
          if (template.description != null &&
              template.description!.isNotEmpty) ...[
            const SizedBox(height: Spacings.xs),
            Text(
              template.description!,
              style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],

          const SizedBox(height: Spacings.md),

          // ── Info Chips ──────────────────────────────────────────────
          Wrap(
            spacing: Spacings.sm,
            runSpacing: Spacings.sm,
            children: [
              _buildInfoChip(
                context,
                icon: Icons.subject_rounded,
                label: template.subjectId,
              ),
              _buildInfoChip(
                context,
                icon: Icons.class_rounded,
                label: template.classId,
              ),
              _buildInfoChip(
                context,
                icon: Icons.timer_rounded,
                label: '${template.timeLimitMinutes} min',
              ),
              _buildInfoChip(
                context,
                icon: Icons.assignment_rounded,
                label: '${template.passMark.toInt()}% pass',
              ),
            ],
          ),

          const SizedBox(height: Spacings.md),

          // ── Bottom Row: Usage + Actions ─────────────────────────────
          Row(
            children: [
              // Usage count
              Icon(
                Icons.content_copy_rounded,
                size: Spacings.smIcon,
                color: cs.onSurfaceVariant,
              ),
              const SizedBox(width: Spacings.xs),
              Text(
                'Used ${template.usageCount} ${template.usageCount == 1 ? 'time' : 'times'}',
                style: tt.bodySmall?.copyWith(
                  color: cs.onSurfaceVariant,
                  fontWeight: AppTypography.wSemiBold,
                ),
              ),

              // Public badge
              if (template.isPublic) ...[
                const SizedBox(width: Spacings.sm),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: Spacings.xs,
                    vertical: 2.0,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.infoOf(cs.brightness)
                        .withOpacity(isDark ? 0.25 : 0.10),
                    borderRadius: BorderRadius.circular(Spacings.smRadius),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.public_rounded,
                        size: 12.0,
                        color: AppColors.infoOf(cs.brightness),
                      ),
                      const SizedBox(width: 2.0),
                      Text(
                        'Public',
                        style: tt.labelSmall?.copyWith(
                          color: AppColors.infoOf(cs.brightness),
                          fontWeight: AppTypography.wSemiBold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const Spacer(),

              // Delete button
              if (onDelete != null)
                IconButton(
                  onPressed: onDelete,
                  icon: Icon(
                    Icons.delete_outline_rounded,
                    size: Spacings.mdIcon,
                    color: AppColors.errorOf(cs.brightness),
                  ),
                  visualDensity: VisualDensity.compact,
                  tooltip: 'Delete template',
                ),

              // Use Template button
              if (onUseTemplate != null)
                AppButton(
                  label: 'Use Template',
                  onPressed: onUseTemplate,
                  variant: AppButtonVariant.tonal,
                  size: AppButtonSize.small,
                  icon: Icons.play_arrow_rounded,
                ),
            ],
          ),

          // ── Created date ────────────────────────────────────────────
          const SizedBox(height: Spacings.xs),
          Text(
            'Created ${_formatDate(template.createdAt)}',
            style: tt.labelSmall?.copyWith(color: cs.onSurfaceVariant),
          ),
        ],
      ),
    );
  }

  // ─── Category Badge ──────────────────────────────────────────────────

  Widget _buildCategoryBadge(BuildContext context, Color color) {
    final tt = context.textTheme;
    final isDark = context.isDarkMode;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Spacings.sm,
        vertical: Spacings.xs,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(isDark ? 0.25 : 0.12),
        borderRadius: BorderRadius.circular(Spacings.smRadius),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_categoryIcon(), size: 14.0, color: color),
          const SizedBox(width: Spacings.xs),
          Text(
            template.category.label,
            style: tt.labelSmall?.copyWith(
              fontWeight: AppTypography.wSemiBold,
              color: isDark ? color.withOpacity(0.9) : color,
            ),
          ),
        ],
      ),
    );
  }

  // ─── Info Chip ───────────────────────────────────────────────────────

  Widget _buildInfoChip(
    BuildContext context, {
    required IconData icon,
    required String label,
  }) {
    final cs = context.colorScheme;
    final tt = context.textTheme;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Spacings.sm,
        vertical: Spacings.xs,
      ),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(Spacings.smRadius),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14.0, color: cs.onSurfaceVariant),
          const SizedBox(width: Spacings.xs),
          Text(
            label,
            style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}
