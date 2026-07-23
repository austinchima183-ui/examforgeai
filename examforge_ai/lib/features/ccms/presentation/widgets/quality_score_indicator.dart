import 'package:flutter/material.dart';

import '../../../../../core/core.dart';

/// Star/number display for content quality score.
///
/// Displays a 5-star rating with a numeric score (e.g. "4.2").
///
/// Color logic (on a 1–5 scale):
/// - red    when score < 2.5
/// - amber  when 2.5 ≤ score ≤ 3.5
/// - green  when score > 3.5
class QualityScoreIndicator extends StatelessWidget {
  const QualityScoreIndicator({
    super.key,
    required this.score,
    this.maxScore = 5.0,
    this.showStars = true,
    this.showNumeric = true,
    this.size = QualityScoreSize.medium,
    this.onTap,
  });

  /// The quality score value.
  final double score;

  /// Maximum possible score (defaults to 5 for star-based scoring).
  final double maxScore;

  /// Whether to show the star icons.
  final bool showStars;

  /// Whether to show the numeric score text.
  final bool showNumeric;

  /// Size preset for the indicator.
  final QualityScoreSize size;

  /// Optional tap handler.
  final VoidCallback? onTap;

  // ─── Color Logic ────────────────────────────────────────────────────────

  /// Determines color based on score thresholds.
  /// Uses the 1–5 scale: red < 2.5, amber 2.5–3.5, green > 3.5.
  Color _scoreColor() {
    if (score < 2.5) return AppColors.error;
    if (score <= 3.5) return AppColors.warning;
    return AppColors.success;
  }

  // ─── Size Helpers ───────────────────────────────────────────────────────

  double _starSize() {
    return switch (size) {
      QualityScoreSize.small => 12.0,
      QualityScoreSize.medium => 16.0,
      QualityScoreSize.large => 20.0,
    };
  }

  double _fontSize() {
    return switch (size) {
      QualityScoreSize.small => 10.0,
      QualityScoreSize.medium => 12.0,
      QualityScoreSize.large => 14.0,
    };
  }

  // ─── Build ──────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final color = _scoreColor();
    final tt = context.textTheme;
    final cs = context.colorScheme;
    final starCount = (score / maxScore * 5).round().clamp(0, 5);
    final isDark = context.isDarkMode;

    // ── Numeric only mode ────────────────────────────────────────────────
    if (!showStars) {
      return GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: Spacings.sm,
            vertical: 2,
          ),
          decoration: BoxDecoration(
            color: color.withValues(alpha: isDark ? 0.20 : 0.12),
            borderRadius: Spacings.borderRadiusSm,
            border: Border.all(
              color: color.withValues(alpha: 0.25),
              width: 1,
            ),
          ),
          child: Text(
            score.toStringAsFixed(1),
            style: AppTypography.labelSmall!.copyWith(
              color: color,
              fontWeight: AppTypography.wSemiBold,
            ),
          ),
        ),
      );
    }

    // ── Stars + numeric display ──────────────────────────────────────────
    return GestureDetector(
      onTap: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Stars
          ...List.generate(5, (index) {
            final isFilled = index < starCount;
            final isHalfFilled = !isFilled &&
                index == starCount &&
                (score / maxScore * 5) % 1 >= 0.25;

            if (isHalfFilled) {
              return Icon(
                Icons.star_half_rounded,
                size: _starSize(),
                color: color,
              );
            }
            return AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              child: Icon(
                isFilled
                    ? Icons.star_rounded
                    : Icons.star_outline_rounded,
                size: _starSize(),
                color: isFilled
                    ? color
                    : cs.outlineVariant.withValues(alpha: 0.4),
              ),
            );
          }),

          // Numeric score
          if (showNumeric) ...[
            const SizedBox(width: Spacings.xs),
            Text(
              score.toStringAsFixed(1),
              style: tt.bodySmall?.copyWith(
                color: color,
                fontWeight: AppTypography.wSemiBold,
                fontSize: _fontSize(),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Size presets for [QualityScoreIndicator].
enum QualityScoreSize {
  /// Compact indicator for use in lists and cards.
  small,

  /// Default indicator size.
  medium,

  /// Larger indicator for detail views.
  large,
}
