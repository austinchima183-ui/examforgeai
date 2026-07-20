import 'package:flutter/material.dart';

import '../../../../../core/core.dart';
import '../../../../../shared/widgets/widgets.dart';
import '../../domain/entities/ccms_entities.dart';

/// Card widget showing a level category (Early Childhood, Primary, etc.)
/// with its child levels.
///
/// Features:
/// - Category name as header with themed icon
/// - List of levels with name, age range, toggle for enabled/disabled
/// - Custom name display if set in school configuration
/// - onTap callback for level selection
class LevelCategoryCard extends StatelessWidget {
  const LevelCategoryCard({
    super.key,
    required this.category,
    required this.levels,
    this.schoolLevels = const [],
    this.onToggleLevel,
    this.onCustomNameChanged,
    this.onLevelTap,
  });

  /// The educational level category to display.
  final EducationalLevelCategory category;

  /// All levels belonging to this category.
  final List<EducationalLevel> levels;

  /// School-specific level configurations (for enabled state and custom names).
  final List<SchoolLevelConfiguration> schoolLevels;

  /// Callback when a level's enabled toggle changes. Receives the level ID.
  final ValueChanged<String>? onToggleLevel;

  /// Callback when a level's custom name changes. Receives the level ID.
  final ValueChanged<String>? onCustomNameChanged;

  /// Callback when a level row is tapped. Receives the level ID.
  final ValueChanged<String>? onLevelTap;

  // ─── Helpers ────────────────────────────────────────────────────────────

  SchoolLevelConfiguration? _getConfig(String levelId) {
    return schoolLevels
        .where((c) => c.educationalLevelId == levelId)
        .firstOrNull;
  }

  IconData _categoryIcon() {
    return switch (category) {
      EducationalLevelCategory.earlyChildhood => Icons.child_care_rounded,
      EducationalLevelCategory.primary => Icons.school_rounded,
      EducationalLevelCategory.juniorSecondary => Icons.menu_book_rounded,
      EducationalLevelCategory.seniorSecondary => Icons.auto_stories_rounded,
      EducationalLevelCategory.technical => Icons.build_rounded,
      EducationalLevelCategory.tertiaryCollege => Icons.account_balance_rounded,
      EducationalLevelCategory.tertiaryUniversity => Icons.military_tech_rounded,
    };
  }

  Color _categoryAccent() {
    return switch (category) {
      EducationalLevelCategory.earlyChildhood => const Color(0xFFF472B6), // pink
      EducationalLevelCategory.primary => const Color(0xFF34D399), // emerald
      EducationalLevelCategory.juniorSecondary => const Color(0xFF60A5FA), // blue
      EducationalLevelCategory.seniorSecondary => const Color(0xFFA78BFA), // violet
      EducationalLevelCategory.technical => const Color(0xFFFBBF24), // amber
      EducationalLevelCategory.tertiaryCollege => const Color(0xFFFB923C), // orange
      EducationalLevelCategory.tertiaryUniversity => const Color(0xFF4F46E5), // indigo
    };
  }

  String _ageRange(EducationalLevel level) {
    if (level.minAge != null && level.maxAge != null) {
      return 'Ages ${level.minAge}–${level.maxAge}';
    }
    if (level.minAge != null) return 'Ages ${level.minAge}+';
    if (level.maxAge != null) return 'Up to age ${level.maxAge}';
    return '';
  }

  // ─── Build ──────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;
    final tt = context.textTheme;
    final isDark = context.isDarkMode;
    final accent = _categoryAccent();

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ──────────────────────────────────────────────────
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(Spacings.sm),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: isDark ? 0.20 : 0.12),
                  borderRadius: Spacings.borderRadiusSm,
                ),
                child: Icon(
                  _categoryIcon(),
                  size: Spacings.mdIcon,
                  color: accent,
                ),
              ),
              const SizedBox(width: Spacings.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      category.label,
                      style: tt.titleMedium?.copyWith(
                        fontWeight: AppTypography.wSemiBold,
                        color: cs.onSurface,
                      ),
                    ),
                    Text(
                      '${levels.length} level${levels.length == 1 ? '' : 's'}',
                      style: tt.bodySmall?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              // Count badge
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: Spacings.sm,
                  vertical: Spacings.xs,
                ),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: isDark ? 0.20 : 0.12),
                  borderRadius: Spacings.borderRadiusFull,
                ),
                child: Text(
                  '${schoolLevels.where((c) => c.isEnabled).length}',
                  style: AppTypography.labelSmall.copyWith(
                    color: accent,
                    fontWeight: AppTypography.wBold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: Spacings.md),
          const Divider(height: 1),
          const SizedBox(height: Spacings.sm),

          // ── Level list ──────────────────────────────────────────────
          if (levels.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: Spacings.md),
              child: Center(
                child: Text(
                  'No levels in this category',
                  style: tt.bodySmall?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
                ),
              ),
            )
          else
            ...levels.map((level) {
              final config = _getConfig(level.id);
              final isEnabled = config?.isEnabled ?? false;
              final displayName = config?.customName?.isNotEmpty == true
                  ? config!.customName!
                  : level.name;
              final hasCustomName =
                  config?.customName?.isNotEmpty == true;

              return _LevelRow(
                level: level,
                displayName: displayName,
                hasCustomName: hasCustomName,
                isEnabled: isEnabled,
                accent: accent,
                onToggle: onToggleLevel != null
                    ? () => onToggleLevel!(level.id)
                    : null,
                onTap: onLevelTap != null
                    ? () => onLevelTap!(level.id)
                    : null,
                onCustomNameEdit:
                    onCustomNameChanged != null && hasCustomName
                        ? () => onCustomNameChanged!(level.id)
                        : null,
              );
            }),
        ],
      ),
    );
  }
}

// ─── Level Row Widget ────────────────────────────────────────────────────────

class _LevelRow extends StatelessWidget {
  const _LevelRow({
    required this.level,
    required this.displayName,
    required this.hasCustomName,
    required this.isEnabled,
    required this.accent,
    this.onToggle,
    this.onTap,
    this.onCustomNameEdit,
  });

  final EducationalLevel level;
  final String displayName;
  final bool hasCustomName;
  final bool isEnabled;
  final Color accent;
  final VoidCallback? onToggle;
  final VoidCallback? onTap;
  final VoidCallback? onCustomNameEdit;

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;
    final tt = context.textTheme;
    final isDark = context.isDarkMode;

    return InkWell(
      onTap: onTap,
      borderRadius: Spacings.borderRadiusSm,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          vertical: Spacings.sm,
          horizontal: Spacings.xs,
        ),
        child: Row(
          children: [
            // Status indicator dot
            Container(
              width: 6,
              height: 6,
              margin: const EdgeInsets.only(right: Spacings.sm),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isEnabled ? AppColors.success : cs.outlineVariant,
              ),
            ),

            // Level info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          displayName,
                          style: tt.bodyMedium?.copyWith(
                            color: isEnabled
                                ? cs.onSurface
                                : cs.onSurfaceVariant,
                            fontWeight: AppTypography.wMedium,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (hasCustomName) ...[
                        const SizedBox(width: Spacings.xs),
                        GestureDetector(
                          onTap: onCustomNameEdit,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: Spacings.xs,
                              vertical: 1,
                            ),
                            decoration: BoxDecoration(
                              color: accent.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'Custom',
                              style: AppTypography.caption.copyWith(
                                color: accent,
                                fontWeight: AppTypography.wSemiBold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  // Age range and order
                  Row(
                    children: [
                      if (level.minAge != null || level.maxAge != null) ...[
                        Icon(
                          Icons.cake_outlined,
                          size: 12,
                          color: cs.onSurfaceVariant.withValues(alpha: 0.7),
                        ),
                        const SizedBox(width: 2),
                        Text(
                          _ageRange(),
                          style: tt.bodySmall?.copyWith(
                            color: cs.onSurfaceVariant,
                            fontSize: 11,
                          ),
                        ),
                        const SizedBox(width: Spacings.sm),
                      ],
                      Text(
                        'Order ${level.levelOrder}',
                        style: tt.bodySmall?.copyWith(
                          color: cs.onSurfaceVariant,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Toggle switch
            Switch(
              value: isEnabled,
              onChanged: onToggle != null ? (_) => onToggle!() : null,
              activeColor: accent,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ],
        ),
      ),
    );
  }

  String _ageRange() {
    if (level.minAge != null && level.maxAge != null) {
      return '${level.minAge}–${level.maxAge} yrs';
    }
    if (level.minAge != null) return '${level.minAge}+ yrs';
    if (level.maxAge != null) return '≤${level.maxAge} yrs';
    return '';
  }
}
