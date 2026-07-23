import 'package:flutter/material.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/themes/app_colors.dart';
import '../../../../core/themes/app_typography.dart';
import '../../../../core/themes/spacings.dart';
import '../../../../shared/widgets/widgets.dart';
import '../../domain/entities/ai_entities.dart';

// ═══════════════════════════════════════════════════════════════════════
// PROMPT TEMPLATE CARD
// ═══════════════════════════════════════════════════════════════════════

/// Card for prompt template management. Shows template name, type,
/// description, quality score bar, usage count, success rate, provider
/// badge, curriculum/subject info, active/default badges, and
/// edit/duplicate/delete actions.
///
/// ```dart
/// PromptTemplateCard(
///   template: myTemplate,
///   onEdit: () => editTemplate(t.id),
///   onDuplicate: () => duplicateTemplate(t.id),
///   onDelete: () => deleteTemplate(t.id),
/// )
/// ```
class PromptTemplateCard extends StatelessWidget {
  const PromptTemplateCard({
    super.key,
    required this.template,
    this.onEdit,
    this.onDuplicate,
    this.onDelete,
    this.onTap,
  });

  final PromptTemplateEntity template;
  final VoidCallback? onEdit;
  final VoidCallback? onDuplicate;
  final VoidCallback? onDelete;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;
    final tt = context.textTheme;
    final isDark = context.isDarkMode;
    final t = template;

    return AppCard(
      onTap: onTap,
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header: Name + badges ──────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(
              Spacings.lg, Spacings.lg, Spacings.lg, Spacings.sm,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        t.name,
                        style: tt.titleSmall?.copyWith(
                          fontWeight: AppTypography.wSemiBold,
                          color: cs.onSurface,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (t.description != null) ...[
                        const SizedBox(height: Spacings.xs),
                        Text(
                          t.description!,
                          style: tt.bodySmall?.copyWith(
                            color: cs.onSurfaceVariant,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: Spacings.sm),
                // Badges
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (t.isDefault)
                      _Badge(
                        label: 'Default',
                        color: AppColors.successOf(cs.brightness),
                        isDark: isDark,
                      ),
                    if (!t.isActive)
                      _Badge(
                        label: 'Inactive',
                        color: AppColors.errorOf(cs.brightness),
                        isDark: isDark,
                      ),
                    if (t.isActive && !t.isDefault)
                      _Badge(
                        label: 'Active',
                        color: AppColors.infoOf(cs.brightness),
                        isDark: isDark,
                      ),
                  ],
                ),
              ],
            ),
          ),

          // ── Type + Provider badges ─────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: Spacings.lg),
            child: Wrap(
              spacing: Spacings.sm,
              runSpacing: Spacings.xs,
              children: [
                _InfoChip(
                  icon: Icons.category_outlined,
                  label: t.promptType.label,
                  color: cs.primary,
                  isDark: isDark,
                ),
                if (t.provider != null)
                  _InfoChip(
                    icon: Icons.smart_toy_outlined,
                    label: t.provider!.displayName,
                    color: cs.tertiary,
                    isDark: isDark,
                  ),
                if (t.curriculum != null)
                  _InfoChip(
                    icon: Icons.menu_book_outlined,
                    label: t.curriculum!.label,
                    color: cs.secondary,
                    isDark: isDark,
                  ),
              ],
            ),
          ),

          const SizedBox(height: Spacings.md),

          // ── Quality score bar ──────────────────────────────────────
          if (t.qualityScore != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: Spacings.lg),
              child: Row(
                children: [
                  Text(
                    'Quality',
                    style: tt.labelSmall?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(width: Spacings.sm),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(Spacings.xs),
                      child: LinearProgressIndicator(
                        value: t.qualityScore!.clamp(0.0, 1.0),
                        minHeight: 6,
                        backgroundColor: cs.surfaceContainerHighest,
                        color: _qualityColor(t.qualityScore!, cs.brightness),
                        borderRadius: BorderRadius.circular(Spacings.xs),
                      ),
                    ),
                  ),
                  const SizedBox(width: Spacings.sm),
                  Text(
                    '${(t.qualityScore! * 100).toStringAsFixed(0)}%',
                    style: tt.labelSmall?.copyWith(
                      color: _qualityColor(t.qualityScore!, cs.brightness),
                      fontWeight: AppTypography.wSemiBold,
                    ),
                  ),
                ],
              ),
            ),

          // ── Usage stats ────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(
              Spacings.lg, Spacings.md, Spacings.lg, Spacings.lg,
            ),
            child: Row(
              children: [
                _StatItem(
                  icon: Icons.format_list_numbered_rounded,
                  value: '${t.usageCount}',
                  label: 'Uses',
                  color: cs.onSurfaceVariant,
                ),
                const SizedBox(width: Spacings.lg),
                if (t.successRate != null)
                  _StatItem(
                    icon: Icons.trending_up_rounded,
                    value: '${(t.successRate! * 100).toStringAsFixed(0)}%',
                    label: 'Success',
                    color: AppColors.successOf(cs.brightness),
                  ),
                const SizedBox(width: Spacings.lg),
                _StatItem(
                  icon: Icons.history_rounded,
                  value: 'v${t.version}',
                  label: 'Version',
                  color: cs.onSurfaceVariant,
                ),
              ],
            ),
          ),

          // ── Actions ────────────────────────────────────────────────
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              Spacings.sm, Spacings.sm, Spacings.sm, Spacings.sm,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (onEdit != null)
                  AppIconButton(
                    icon: Icons.edit_outlined,
                    onPressed: onEdit,
                    variant: AppIconButtonVariant.standard,
                    tooltip: 'Edit template',
                  ),
                if (onDuplicate != null)
                  AppIconButton(
                    icon: Icons.content_copy_rounded,
                    onPressed: onDuplicate,
                    variant: AppIconButtonVariant.standard,
                    tooltip: 'Duplicate template',
                  ),
                if (onDelete != null)
                  AppIconButton(
                    icon: Icons.delete_outline_rounded,
                    onPressed: onDelete,
                    variant: AppIconButtonVariant.standard,
                    tooltip: 'Delete template',
                    color: AppColors.errorOf(cs.brightness),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _qualityColor(double score, Brightness brightness) {
    if (score >= 0.8) return AppColors.successOf(brightness);
    if (score >= 0.6) return AppColors.warningOf(brightness);
    return AppColors.errorOf(brightness);
  }
}

// ═══════════════════════════════════════════════════════════════════════
// PRIVATE HELPERS
// ═══════════════════════════════════════════════════════════════════════

class _Badge extends StatelessWidget {
  const _Badge({
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
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.20 : 0.12),
        borderRadius: BorderRadius.circular(Spacings.xs),
      ),
      child: Text(
        label,
        style: context.textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: AppTypography.wSemiBold,
          fontSize: 10,
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({
    required this.icon,
    required this.label,
    required this.color,
    required this.isDark,
  });
  final IconData icon;
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
        color: color.withValues(alpha: isDark ? 0.15 : 0.10),
        borderRadius: BorderRadius.circular(Spacings.smRadius),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: Spacings.xs),
          Text(
            label,
            style: context.textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: AppTypography.wMedium,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: Spacings.smIcon, color: color),
        const SizedBox(width: Spacings.xs),
        Text(
          value,
          style: context.textTheme.labelMedium?.copyWith(
            fontWeight: AppTypography.wSemiBold,
            color: context.colorScheme.onSurface,
          ),
        ),
        const SizedBox(width: Spacings.xs),
        Text(
          label,
          style: context.textTheme.bodySmall?.copyWith(
            color: color,
          ),
        ),
      ],
    );
  }
}
