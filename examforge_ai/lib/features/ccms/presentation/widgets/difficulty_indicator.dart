import 'package:flutter/material.dart';

import '../../../../../core/core.dart';
import '../../domain/entities/ccms_entities.dart';

/// Visual difficulty level indicator with colored dots and label.
///
/// Shows a row of 5 colored circles (filled up to the difficulty level)
/// with a text label. Also supports a compact badge-only mode.
///
/// Colors:
/// - Beginner: green
/// - Elementary: light green
/// - Intermediate: yellow
/// - Advanced: orange
/// - Expert: red
class DifficultyIndicator extends StatelessWidget {
  const DifficultyIndicator({
    super.key,
    required this.level,
    this.compact = false,
    this.showLabel = true,
  });

  /// The difficulty level to display.
  final DifficultyLevel level;

  /// When true, renders only a small badge without the dot bar.
  final bool compact;

  /// Whether to show the text label alongside the dots.
  final bool showLabel;

  // ─── Color Mapping ──────────────────────────────────────────────────────

  Color _color() {
    return switch (level) {
      DifficultyLevel.beginner => const Color(0xFF22C55E), // green
      DifficultyLevel.elementary => const Color(0xFF84CC16), // light green
      DifficultyLevel.intermediate => const Color(0xFFEAB308), // yellow
      DifficultyLevel.advanced => const Color(0xFFF97316), // orange
      DifficultyLevel.expert => const Color(0xFFEF4444), // red
    };
  }

  /// Numeric index for dot fill level (1–5).
  int _levelIndex() {
    return switch (level) {
      DifficultyLevel.beginner => 1,
      DifficultyLevel.elementary => 2,
      DifficultyLevel.intermediate => 3,
      DifficultyLevel.advanced => 4,
      DifficultyLevel.expert => 5,
    };
  }

  /// Description tooltip for accessibility.
  String _tooltip() {
    return switch (level) {
      DifficultyLevel.beginner => 'Beginner – Entry level content',
      DifficultyLevel.elementary => 'Elementary – Basic understanding required',
      DifficultyLevel.intermediate => 'Intermediate – Moderate complexity',
      DifficultyLevel.advanced => 'Advanced – High complexity',
      DifficultyLevel.expert => 'Expert – Maximum difficulty',
    };
  }

  @override
  Widget build(BuildContext context) {
    final color = _color();
    final cs = context.colorScheme;
    final isDark = context.isDarkMode;

    // ── Compact badge mode ───────────────────────────────────────────────
    if (compact) {
      return Tooltip(
        message: _tooltip(),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: Spacings.sm,
            vertical: 2,
          ),
          decoration: BoxDecoration(
            color: color.withOpacity(isDark ? 0.20 : 0.12),
            borderRadius: Spacings.borderRadiusSm,
            border: Border.all(
              color: color.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Text(
            level.label,
            style: AppTypography.labelSmall!.copyWith(
              color: color,
              fontWeight: AppTypography.wSemiBold,
            ),
          ),
        ),
      );
    }

    // ── Full indicator with dots + label + colored bar ───────────────────
    return Tooltip(
      message: _tooltip(),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Colored dots (5 circles, filled up to level index)
          ...List.generate(5, (index) {
            final filled = index < _levelIndex();
            return Padding(
              padding: const EdgeInsets.only(right: 3),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                width: filled ? 10 : 8,
                height: filled ? 10 : 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: filled
                      ? color
                      : cs.outlineVariant.withOpacity(0.4),
                  border: filled
                      ? null
                      : Border.all(
                          color: color.withOpacity(0.3),
                          width: 1,
                        ),
                  boxShadow: filled
                      ? [
                          BoxShadow(
                            color: color.withOpacity(0.4),
                            blurRadius: 3,
                            offset: const Offset(0, 1),
                          ),
                        ]
                      : null,
                ),
              ),
            );
          }),
          if (showLabel) ...[
            const SizedBox(width: Spacings.xs),
            Text(
              level.label,
              style: AppTypography.labelSmall!.copyWith(
                color: color,
                fontWeight: AppTypography.wSemiBold,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
