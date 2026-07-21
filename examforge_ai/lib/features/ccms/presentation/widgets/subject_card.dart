import 'package:flutter/material.dart';

import '../../../../../core/core.dart';
import '../../../../../shared/widgets/widgets.dart';
import '../../domain/entities/ccms_entities.dart';

/// Type classification for a subject, derived from its boolean flags.
enum SubjectType {
  core(value: 'core', label: 'Core'),
  elective(value: 'elective', label: 'Elective'),
  vocational(value: 'vocational', label: 'Vocational');

  const SubjectType({required this.value, required this.label});
  final String value;
  final String label;

  /// Derive the type from a [Subject] entity.
  static SubjectType fromSubject(Subject subject) {
    if (subject.isVocational) return SubjectType.vocational;
    if (subject.isElective) return SubjectType.elective;
    return SubjectType.core;
  }
}

/// Card showing subject information.
///
/// Features:
/// - Subject name and code
/// - Subject group badge (Language=blue, Science=green, Mathematics=purple, etc.)
/// - Core/Elective/Vocational badges
/// - Level indicator
/// - Custom badge if isCustom=true
/// - onTap callback
class SubjectCard extends StatelessWidget {
  const SubjectCard({
    super.key,
    required this.subject,
    this.onTap,
    this.onEdit,
    this.onDelete,
  });

  /// The subject entity to display.
  final Subject subject;

  /// Callback when the card is tapped.
  final VoidCallback? onTap;

  /// Callback when edit is selected from the menu.
  final VoidCallback? onEdit;

  /// Callback when delete is selected from the menu.
  final VoidCallback? onDelete;

  // ─── Color Helpers ──────────────────────────────────────────────────────

  Color _typeColor(SubjectType type) {
    return switch (type) {
      SubjectType.core => AppColors.info,
      SubjectType.elective => AppColors.warning,
      SubjectType.vocational => AppColors.success,
    };
  }

  /// Subject group color mapping.
  Color _groupColor(String group) {
    final lower = group.toLowerCase();
    if (lower.contains('language') || lower.contains('lang')) {
      return const Color(0xFF3B82F6); // blue
    }
    if (lower.contains('science')) {
      return const Color(0xFF10B981); // green
    }
    if (lower.contains('math') || lower.contains('numeracy')) {
      return const Color(0xFF8B5CF6); // purple
    }
    if (lower.contains('art') || lower.contains('creative')) {
      return const Color(0xFFF97316); // orange
    }
    if (lower.contains('social') || lower.contains('humanities')) {
      return const Color(0xFFEC4899); // pink
    }
    if (lower.contains('technical') || lower.contains('tech')) {
      return const Color(0xFF14B8A6); // teal
    }
    if (lower.contains('religious') || lower.contains('religion')) {
      return const Color(0xFF6366F1); // indigo
    }
    if (lower.contains('physical') || lower.contains('sport')) {
      return const Color(0xFFEF4444); // red
    }
    if (lower.contains('business') || lower.contains('commercial')) {
      return const Color(0xFFF59E0B); // amber
    }
    return AppColors.seed; // default indigo
  }

  IconData _groupIcon(String group) {
    final lower = group.toLowerCase();
    if (lower.contains('language') || lower.contains('lang')) {
      return Icons.translate_rounded;
    }
    if (lower.contains('science')) return Icons.science_rounded;
    if (lower.contains('math') || lower.contains('numeracy')) {
      return Icons.calculate_rounded;
    }
    if (lower.contains('art') || lower.contains('creative')) {
      return Icons.palette_rounded;
    }
    if (lower.contains('social') || lower.contains('humanities')) {
      return Icons.groups_rounded;
    }
    if (lower.contains('technical') || lower.contains('tech')) {
      return Icons.precision_manufacturing_rounded;
    }
    if (lower.contains('religious') || lower.contains('religion')) {
      return Icons.church_rounded;
    }
    if (lower.contains('physical') || lower.contains('sport')) {
      return Icons.fitness_center_rounded;
    }
    if (lower.contains('business') || lower.contains('commercial')) {
      return Icons.business_center_rounded;
    }
    return Icons.book_rounded;
  }

  // ─── Build ──────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;
    final tt = context.textTheme;
    final isDark = context.isDarkMode;
    final subjectType = SubjectType.fromSubject(subject);
    final typeColor = _typeColor(subjectType);
    final groupColor = (subject.subjectGroup != null &&
            subject.subjectGroup!.isNotEmpty)
        ? _groupColor(subject.subjectGroup!)
        : null;

    return AppCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Top row: badges + menu ──────────────────────────────────
          Row(
            children: [
              // Subject type badge (Core/Elective/Vocational)
              _Badge(
                label: subjectType.label,
                color: typeColor,
              ),
              const SizedBox(width: Spacings.sm),

              // Custom badge
              if (subject.isCustom)
                _Badge(
                  label: 'Custom',
                  color: AppColors.seed,
                  icon: Icons.tune_rounded,
                ),

              const Spacer(),

              // Action menu
              if (onEdit != null || onDelete != null)
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'edit' && onEdit != null) onEdit!();
                    if (value == 'delete' && onDelete != null) onDelete!();
                  },
                  itemBuilder: (context) => [
                    if (onEdit != null)
                      const PopupMenuItem(
                        value: 'edit',
                        child: Text('Edit'),
                      ),
                    if (onDelete != null)
                      const PopupMenuItem(
                        value: 'delete',
                        child: Text('Delete'),
                      ),
                  ],
                ),
            ],
          ),
          const SizedBox(height: Spacings.sm),

          // ── Subject name ────────────────────────────────────────────
          Text(
            subject.name,
            style: tt.titleSmall?.copyWith(
              fontWeight: AppTypography.wSemiBold,
              color: cs.onSurface,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: Spacings.xs),

          // ── Code + Group row ────────────────────────────────────────
          Row(
            children: [
              // Code badge
              if (subject.code.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: Spacings.sm,
                    vertical: Spacings.xs,
                  ),
                  decoration: BoxDecoration(
                    color: cs.surfaceContainerHighest,
                    borderRadius: Spacings.borderRadiusSm,
                  ),
                  child: Text(
                    subject.code,
                    style: tt.labelSmall?.copyWith(
                      color: cs.onSurfaceVariant,
                      fontWeight: AppTypography.wSemiBold,
                    ),
                  ),
                ),
                const SizedBox(width: Spacings.sm),
              ],
              // Subject group badge
              if (subject.subjectGroup != null &&
                  subject.subjectGroup!.isNotEmpty &&
                  groupColor != null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: Spacings.sm,
                    vertical: Spacings.xs,
                  ),
                  decoration: BoxDecoration(
                    color: groupColor.withOpacity(isDark ? 0.20 : 0.12),
                    borderRadius: Spacings.borderRadiusSm,
                    border: Border.all(
                      color: groupColor.withOpacity(0.25),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _groupIcon(subject.subjectGroup!),
                        size: 12,
                        color: groupColor,
                      ),
                      const SizedBox(width: Spacings.xs),
                      Text(
                        subject.subjectGroup!,
                        style: AppTypography.labelSmall.copyWith(
                          color: groupColor,
                          fontWeight: AppTypography.wSemiBold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),

          // ── Level indicator ─────────────────────────────────────────
          if (subject.educationalLevelId.isNotEmpty) ...[
            const SizedBox(height: Spacings.sm),
            Row(
              children: [
                Icon(
                  Icons.layers_outlined,
                  size: 14,
                  color: cs.onSurfaceVariant,
                ),
                const SizedBox(width: Spacings.xs),
                Text(
                  'Level: ${subject.educationalLevelId}',
                  style: tt.bodySmall?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ],

          // ── Description ─────────────────────────────────────────────
          if (subject.description != null &&
              subject.description!.isNotEmpty) ...[
            const SizedBox(height: Spacings.xs),
            Text(
              subject.description!,
              style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Badge Widget ─────────────────────────────────────────────────────────────

class _Badge extends StatelessWidget {
  const _Badge({
    required this.label,
    required this.color,
    this.icon,
  });

  final String label;
  final Color color;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Spacings.sm,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(isDark ? 0.20 : 0.12),
        borderRadius: Spacings.borderRadiusSm,
        border: Border.all(
          color: color.withOpacity(0.25),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: color),
            const SizedBox(width: 2),
          ],
          Text(
            label,
            style: AppTypography.labelSmall.copyWith(
              color: color,
              fontWeight: AppTypography.wSemiBold,
            ),
          ),
        ],
      ),
    );
  }
}
