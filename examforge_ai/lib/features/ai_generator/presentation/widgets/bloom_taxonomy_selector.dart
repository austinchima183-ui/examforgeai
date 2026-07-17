import 'package:flutter/material.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/themes/app_colors.dart';
import '../../../../core/themes/app_typography.dart';
import '../../../../core/themes/spacings.dart';
import '../../domain/entities/ai_entities.dart';

// ═══════════════════════════════════════════════════════════════════════
// BLOOM TAXONOMY SELECTOR
// ═══════════════════════════════════════════════════════════════════════

/// Widget for selecting a Bloom's Taxonomy level. Displays 6 level cards
/// in a horizontal scroll. Each card shows the level name, description,
/// and keywords. The selected state is highlighted with a color accent.
///
/// Can be used in generation input forms and prompt template editors.
///
/// ```dart
/// BloomTaxonomySelector(
///   selectedLevel: BloomTaxonomy.apply,
///   onLevelSelected: (level) => setState(() => _bloom = level),
/// )
/// ```
class BloomTaxonomySelector extends StatelessWidget {
  const BloomTaxonomySelector({
    super.key,
    this.selectedLevel,
    required this.onLevelSelected,
    this.showKeywords = true,
    this.isCompact = false,
  });

  /// The currently selected Bloom's Taxonomy level.
  final BloomTaxonomy? selectedLevel;

  /// Callback when a level is selected.
  final ValueChanged<BloomTaxonomy?> onLevelSelected;

  /// Whether to show keyword chips on each card.
  final bool showKeywords;

  /// When `true`, uses a more compact layout.
  final bool isCompact;

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;
    final tt = context.textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Label
        Row(
          children: [
            Text(
              "Bloom's Taxonomy Level",
              style: tt.titleSmall?.copyWith(
                fontWeight: AppTypography.wSemiBold,
                color: cs.onSurface,
              ),
            ),
            const SizedBox(width: Spacings.sm),
            if (selectedLevel != null)
              InkWell(
                onTap: () => onLevelSelected(null),
                borderRadius: BorderRadius.circular(Spacings.smRadius),
                child: Container(
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
                      Icon(
                        Icons.clear_rounded,
                        size: Spacings.smIcon,
                        color: cs.onSurfaceVariant,
                      ),
                      const SizedBox(width: Spacings.xs),
                      Text(
                        'Clear',
                        style: tt.labelSmall?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: Spacings.sm),

        // Level cards in horizontal scroll
        SizedBox(
          height: isCompact ? 110.0 : 160.0,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: BloomTaxonomy.values.length,
            separatorBuilder: (_, __) => const SizedBox(width: Spacings.sm),
            itemBuilder: (context, index) {
              final level = BloomTaxonomy.values[index];
              final isSelected = level == selectedLevel;
              return _BloomLevelCard(
                level: level,
                isSelected: isSelected,
                onTap: () => onLevelSelected(isSelected ? null : level),
                showKeywords: showKeywords && !isCompact,
                isCompact: isCompact,
              );
            },
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// PRIVATE: BLOOM LEVEL CARD
// ═══════════════════════════════════════════════════════════════════════

class _BloomLevelCard extends StatelessWidget {
  const _BloomLevelCard({
    required this.level,
    required this.isSelected,
    required this.onTap,
    this.showKeywords = true,
    this.isCompact = false,
  });

  final BloomTaxonomy level;
  final bool isSelected;
  final VoidCallback onTap;
  final bool showKeywords;
  final bool isCompact;

  /// Assigns a gradient of colors from lower-order (cool) to
  /// higher-order (warm) thinking.
  Color _levelColor(BloomTaxonomy lvl, ColorScheme cs) {
    return switch (lvl) {
      BloomTaxonomy.remember => const Color(0xFF06B6D4), // Cyan
      BloomTaxonomy.understand => const Color(0xFF10B981), // Emerald
      BloomTaxonomy.apply => const Color(0xFF22C55E), // Green
      BloomTaxonomy.analyze => const Color(0xFFF59E0B), // Amber
      BloomTaxonomy.evaluate => const Color(0xFFF97316), // Orange
      BloomTaxonomy.create => const Color(0xFFEC4899), // Pink
    };
  }

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;
    final tt = context.textTheme;
    final isDark = context.isDarkMode;
    final color = _levelColor(level, cs);

    final cardWidth = isCompact ? 110.0 : 150.0;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: cardWidth,
        padding: const EdgeInsets.all(Spacings.md),
        decoration: BoxDecoration(
          color: isSelected
              ? color.withValues(alpha: isDark ? 0.25 : 0.15)
              : cs.surfaceContainerHighest.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(Spacings.mdRadius),
          border: Border.all(
            color: isSelected ? color : cs.outlineVariant.withValues(alpha: 0.5),
            width: isSelected ? 2.0 : 1.0,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Level index + name
            Row(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? color
                        : color.withValues(alpha: isDark ? 0.20 : 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '${BloomTaxonomy.values.indexOf(level) + 1}',
                      style: tt.labelSmall?.copyWith(
                        color: isSelected
                            ? Colors.white
                            : color,
                        fontWeight: AppTypography.wBold,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: Spacings.sm),
                Expanded(
                  child: Text(
                    level.label,
                    style: tt.labelMedium?.copyWith(
                      color: isSelected ? color : cs.onSurface,
                      fontWeight: AppTypography.wSemiBold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),

            // Description (truncated)
            if (!isCompact) ...[
              const SizedBox(height: Spacings.xs),
              Text(
                level.description,
                style: tt.bodySmall?.copyWith(
                  color: cs.onSurfaceVariant,
                  height: 1.2,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],

            // Keywords
            if (showKeywords && !isCompact) ...[
              const SizedBox(height: Spacings.xs),
              Wrap(
                spacing: Spacings.xs,
                runSpacing: 2,
                children: level.keywords.take(3).map((kw) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: Spacings.xs,
                      vertical: 1,
                    ),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: isDark ? 0.15 : 0.10),
                      borderRadius: BorderRadius.circular(Spacings.xs),
                    ),
                    child: Text(
                      kw,
                      style: tt.labelSmall?.copyWith(
                        color: color,
                        fontSize: 9,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
