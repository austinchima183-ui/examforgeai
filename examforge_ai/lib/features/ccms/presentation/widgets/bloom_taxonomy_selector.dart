import 'package:flutter/material.dart';

import '../../../../../core/core.dart';
import '../../domain/entities/ccms_entities.dart';

/// Multi-select widget for Bloom's taxonomy levels.
///
/// Displays 6 cognitive levels as toggle chips with a progressive blue
/// gradient that gets deeper as the level increases:
/// - Remember  → lightest indigo
/// - Understand → light indigo
/// - Apply     → medium indigo
/// - Analyze   → deeper indigo
/// - Evaluate  → deep indigo
/// - Create    → deepest indigo / violet
///
/// Selected chips are filled with color; unselected chips show an outline.
class BloomTaxonomySelector extends StatefulWidget {
  const BloomTaxonomySelector({
    super.key,
    required this.selectedLevels,
    this.onSelectionChanged,
    this.allowMultiple = true,
  });

  /// Currently selected taxonomy levels.
  final Set<BloomTaxonomy> selectedLevels;

  /// Callback fired when the selection changes.
  final ValueChanged<Set<BloomTaxonomy>>? onSelectionChanged;

  /// Whether multiple levels can be selected at once.
  final bool allowMultiple;

  @override
  State<BloomTaxonomySelector> createState() => _BloomTaxonomySelectorState();
}

class _BloomTaxonomySelectorState extends State<BloomTaxonomySelector> {
  late Set<BloomTaxonomy> _selected;

  @override
  void initState() {
    super.initState();
    _selected = Set.from(widget.selectedLevels);
  }

  @override
  void didUpdateWidget(covariant BloomTaxonomySelector oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedLevels != widget.selectedLevels) {
      _selected = Set.from(widget.selectedLevels);
    }
  }

  /// Progressive blue gradient: lighter for lower levels, deeper for higher.
  Color _bloomColor(BloomTaxonomy bloom) {
    return switch (bloom) {
      BloomTaxonomy.remember => const Color(0xFF93C5FD), // blue-300
      BloomTaxonomy.understand => const Color(0xFF60A5FA), // blue-400
      BloomTaxonomy.apply => const Color(0xFF3B82F6), // blue-500
      BloomTaxonomy.analyze => const Color(0xFF2563EB), // blue-600
      BloomTaxonomy.evaluate => const Color(0xFF1D4ED8), // blue-700
      BloomTaxonomy.create => const Color(0xFF4F46E5), // indigo-600
    };
  }

  /// Icon for each taxonomy level.
  IconData _bloomIcon(BloomTaxonomy bloom) {
    return switch (bloom) {
      BloomTaxonomy.remember => Icons.psychology_outlined,
      BloomTaxonomy.understand => Icons.lightbulb_outline_rounded,
      BloomTaxonomy.apply => Icons.build_outlined,
      BloomTaxonomy.analyze => Icons.analytics_outlined,
      BloomTaxonomy.evaluate => Icons.gavel_outlined,
      BloomTaxonomy.create => Icons.auto_awesome_outlined,
    };
  }

  void _toggle(BloomTaxonomy level) {
    setState(() {
      if (_selected.contains(level)) {
        _selected.remove(level);
      } else {
        if (!widget.allowMultiple) _selected.clear();
        _selected.add(level);
      }
    });
    widget.onSelectionChanged?.call(Set.from(_selected));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Label
        Text(
          "Bloom's Taxonomy",
          style: AppTypography.labelMedium!.copyWith(
            color: context.colorScheme.onSurfaceVariant,
            fontWeight: AppTypography.wSemiBold,
          ),
        ),
        const SizedBox(height: Spacings.sm),
        // Chip grid
        Wrap(
          spacing: Spacings.sm,
          runSpacing: Spacings.sm,
          children: BloomTaxonomy.values.map((level) {
            final isSelected = _selected.contains(level);
            final color = _bloomColor(level);

            return GestureDetector(
              onTap: () => _toggle(level),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeInOut,
                padding: const EdgeInsets.symmetric(
                  horizontal: Spacings.md,
                  vertical: Spacings.sm,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? color.withValues(alpha: isDark ? 0.25 : 0.15)
                      : Colors.transparent,
                  borderRadius: Spacings.borderRadiusSm,
                  border: Border.all(
                    color: isSelected
                        ? color
                        : color.withValues(alpha: 0.4),
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Check icon or level icon
                    if (isSelected)
                      Padding(
                        padding: const EdgeInsets.only(right: Spacings.xs),
                        child: Icon(
                          Icons.check_rounded,
                          size: 14,
                          color: color,
                        ),
                      )
                    else
                      Padding(
                        padding: const EdgeInsets.only(right: Spacings.xs),
                        child: Icon(
                          _bloomIcon(level),
                          size: 14,
                          color: color.withValues(alpha: 0.6),
                        ),
                      ),
                    Text(
                      level.label,
                      style: AppTypography.labelMedium!.copyWith(
                        color: isSelected
                            ? color
                            : color.withValues(alpha: 0.7),
                        fontWeight: isSelected
                            ? AppTypography.wSemiBold
                            : AppTypography.wRegular,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
        // Selection count
        if (_selected.isNotEmpty) ...[
          const SizedBox(height: Spacings.xs),
          Text(
            '${_selected.length} level${_selected.length == 1 ? '' : 's'} selected',
            style: AppTypography.bodySmall!.copyWith(
              color: context.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );
  }
}
