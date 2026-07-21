import 'package:flutter/material.dart';

import '../../../../core/themes/app_colors.dart';
import '../../../../core/themes/app_typography.dart';
import '../../../../core/themes/spacings.dart';
import '../../../../core/extensions/context_extensions.dart';

// ═══════════════════════════════════════════════════════════════════════
// DIFFICULTY SELECTOR
// ═══════════════════════════════════════════════════════════════════════

/// Horizontal chip group for difficulty selection.
///
/// Presents Easy (green), Medium (amber), Hard (red), Expert (purple) as
/// selectable chips. The currently selected difficulty is highlighted.
///
/// ```dart
/// DifficultySelector(
///   selected: 'medium',
///   onChanged: (val) => print(val),
/// )
/// ```
class DifficultySelector extends StatelessWidget {
  const DifficultySelector({
    super.key,
    required this.selected,
    required this.onChanged,
    this.label,
  });

  /// Currently selected difficulty string: 'easy', 'medium', 'hard', 'expert'.
  final String selected;

  /// Callback when a new difficulty is selected.
  final ValueChanged<String> onChanged;

  /// Optional label above the chips.
  final String? label;

  static const List<_DifficultyOption> _options = [
    _DifficultyOption(value: 'easy', label: 'Easy', color: Color(0xFF16A34A)),
    _DifficultyOption(value: 'medium', label: 'Medium', color: Color(0xFFF59E0B)),
    _DifficultyOption(value: 'hard', label: 'Hard', color: Color(0xFFDC2626)),
    _DifficultyOption(value: 'expert', label: 'Expert', color: Color(0xFF7C3AED)),
  ];

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;
    final tt = context.textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (label != null) ...[
          Text(
            label!,
            style: tt.labelLarge?.copyWith(
              fontWeight: AppTypography.wSemiBold,
              color: cs.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: Spacings.sm),
        ],
        Wrap(
          spacing: Spacings.sm,
          runSpacing: Spacings.sm,
          children: _options.map((opt) {
            final isSelected = opt.value == selected;
            return _DifficultyChip(
              option: opt,
              isSelected: isSelected,
              onTap: () => onChanged(opt.value),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _DifficultyOption {
  const _DifficultyOption({
    required this.value,
    required this.label,
    required this.color,
  });

  final String value;
  final String label;
  final Color color;
}

class _DifficultyChip extends StatelessWidget {
  const _DifficultyChip({
    required this.option,
    required this.isSelected,
    required this.onTap,
  });

  final _DifficultyOption option;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;
    final tt = context.textTheme;
    final isDark = context.isDarkMode;

    final bgColor = isSelected
        ? option.color
        : option.color.withOpacity(isDark ? 0.20 : 0.10);
    final fgColor = isSelected
        ? Colors.white
        : isDark
            ? option.color.withOpacity(0.9)
            : option.color;
    final borderColor = isSelected
        ? option.color
        : option.color.withOpacity(0.3);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(
          horizontal: Spacings.md,
          vertical: Spacings.sm,
        ),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(Spacings.fullRadius),
          border: Border.all(color: borderColor, width: isSelected ? 2.0 : 1.0),
        ),
        child: Text(
          option.label,
          style: tt.labelMedium?.copyWith(
            fontWeight: isSelected ? AppTypography.wBold : AppTypography.wMedium,
            color: fgColor,
          ),
        ),
      ),
    );
  }
}
