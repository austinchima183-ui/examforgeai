import 'package:flutter/material.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/themes/app_typography.dart';
import '../../../../core/themes/spacings.dart';
import '../../domain/entities/question_entities.dart';

// ─── DifficultyBadge ──────────────────────────────────────────────────────────

/// A small chip-style badge that displays a [DifficultyLevel] with a
/// colour-coded label and optional dot indicator.
///
/// Easy = green, Medium = amber, Hard = orange/red, Expert = purple/red.
///
/// ```dart
/// DifficultyBadge(difficulty: DifficultyLevel.hard)
/// DifficultyBadge(difficulty: DifficultyLevel.easy, showDot: false)
/// ```
class DifficultyBadge extends StatelessWidget {
  const DifficultyBadge({
    super.key,
    required this.difficulty,
    this.showDot = true,
  });

  /// The difficulty level to display.
  final DifficultyLevel difficulty;

  /// Whether to show a small coloured dot before the label.
  final bool showDot;

  // ─── Color Mapping ──────────────────────────────────────────────────

  Color _badgeColor() {
    return switch (difficulty) {
      DifficultyLevel.easy => const Color(0xFF16A34A), // Green
      DifficultyLevel.medium => const Color(0xFFF59E0B), // Amber
      DifficultyLevel.hard => const Color(0xFFEA580C), // Orange
      DifficultyLevel.expert => const Color(0xFFDC2626), // Red
    };
  }

  Color _backgroundColor(BuildContext context) {
    final isDark = context.isDarkMode;
    final color = _badgeColor();
    return color.withValues(alpha: isDark ? 0.25 : 0.12);
  }

  Color _foregroundColor(BuildContext context) {
    final isDark = context.isDarkMode;
    final color = _badgeColor();
    return isDark ? color.withValues(alpha: 0.9) : color;
  }

  // ─── Build ──────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final bgColor = _backgroundColor(context);
    final fgColor = _foregroundColor(context);
    final dotColor = _badgeColor();

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Spacings.sm,
        vertical: Spacings.xs,
      ),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(Spacings.smRadius),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showDot) ...[
            Container(
              width: 6.0,
              height: 6.0,
              decoration: BoxDecoration(
                color: dotColor,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: Spacings.xs),
          ],
          Text(
            difficulty.label,
            style: TextStyle(
              fontFamily: AppTypography.fontFamily,
              fontSize: 11.0,
              fontWeight: AppTypography.wSemiBold,
              letterSpacing: AppTypography.lsLabel,
              height: 1.33,
              color: fgColor,
            ),
          ),
        ],
      ),
    );
  }
}
