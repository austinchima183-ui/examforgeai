import 'package:flutter/material.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/themes/app_typography.dart';
import '../../../../core/themes/spacings.dart';
import '../../domain/entities/student_portal_entities.dart';

// ═══════════════════════════════════════════════════════════════════════
// FLASHCARD RATING BUTTONS
// ═══════════════════════════════════════════════════════════════════════

/// Row of rating buttons for spaced repetition (SM-2 algorithm).
///
/// Displays four options: Again (red), Hard (orange), Good (green), Easy (blue).
/// Each button shows the next review interval (e.g., "10 min", "1 day").
///
/// ```dart
/// FlashcardRatingButtons(
///   onRate: (rating) => handleRating(rating),
///   intervals: {
///     FlashcardRating.again: Duration(minutes: 10),
///     FlashcardRating.hard: Duration(days: 1),
///     FlashcardRating.good: Duration(days: 3),
///     FlashcardRating.easy: Duration(days: 7),
///   },
/// )
/// ```
class FlashcardRatingButtons extends StatelessWidget {
  const FlashcardRatingButtons({
    super.key,
    required this.onRate,
    this.intervals,
  });

  /// Callback when a rating is selected.
  final ValueChanged<FlashcardRating> onRate;

  /// Optional map of next review intervals for each rating.
  /// If not provided, default intervals are shown.
  final Map<FlashcardRating, Duration>? intervals;

  static const Map<FlashcardRating, Duration> _defaultIntervals = {
    FlashcardRating.again: Duration(minutes: 10),
    FlashcardRating.hard: Duration(days: 1),
    FlashcardRating.good: Duration(days: 3),
    FlashcardRating.easy: Duration(days: 7),
  };

  String _formatInterval(Duration d) {
    if (d.inDays >= 7) {
      final weeks = d.inDays ~/ 7;
      return '$weeks wk${weeks > 1 ? 's' : ''}';
    }
    if (d.inDays >= 1) {
      return '${d.inDays} day${d.inDays > 1 ? 's' : ''}';
    }
    if (d.inHours >= 1) {
      return '${d.inHours} hr${d.inHours > 1 ? 's' : ''}';
    }
    final mins = d.inMinutes;
    return '$mins min${mins > 1 ? 's' : ''}';
  }

  Color _ratingColor(FlashcardRating rating) {
    return switch (rating) {
      FlashcardRating.again => const Color(0xFFDC2626), // Red
      FlashcardRating.hard => const Color(0xFFEA580C), // Orange
      FlashcardRating.good => const Color(0xFF16A34A), // Green
      FlashcardRating.easy => const Color(0xFF2563EB), // Blue
    };
  }

  IconData _ratingIcon(FlashcardRating rating) {
    return switch (rating) {
      FlashcardRating.again => Icons.refresh_rounded,
      FlashcardRating.hard => Icons.trending_up_rounded,
      FlashcardRating.good => Icons.check_circle_outline_rounded,
      FlashcardRating.easy => Icons.bolt_rounded,
    };
  }

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;
    final tt = context.textTheme;
    final effectiveIntervals = intervals ?? _defaultIntervals;

    const ratings = FlashcardRating.values;

    return Row(
      children: ratings.map((rating) {
        final color = _ratingColor(rating);
        final interval = effectiveIntervals[rating] ?? Duration.zero;
        final isDark = context.isDarkMode;

        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: Spacings.xs),
            child: Material(
              color: color.withValues(alpha: isDark ? 0.20 : 0.08),
              borderRadius: BorderRadius.circular(Spacings.mdRadius),
              child: InkWell(
                onTap: () => onRate(rating),
                borderRadius: BorderRadius.circular(Spacings.mdRadius),
                splashColor: color.withValues(alpha: 0.2),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: Spacings.xs,
                    vertical: Spacings.md,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(Spacings.mdRadius),
                    border: Border.all(
                      color: color.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _ratingIcon(rating),
                        size: Spacings.mdIcon,
                        color: isDark ? color.withValues(alpha: 0.9) : color,
                      ),
                      const SizedBox(height: Spacings.xs),
                      Text(
                        rating.label,
                        style: tt.labelMedium?.copyWith(
                          fontWeight: AppTypography.wBold,
                          color: isDark ? color.withValues(alpha: 0.9) : color,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _formatInterval(interval),
                        style: tt.labelSmall?.copyWith(
                          color: isDark
                              ? color.withValues(alpha: 0.7)
                              : color.withValues(alpha: 0.8),
                          fontWeight: AppTypography.wMedium,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
