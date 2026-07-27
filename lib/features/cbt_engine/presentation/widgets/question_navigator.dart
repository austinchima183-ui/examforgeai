import 'package:flutter/material.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/themes/app_colors.dart';
import '../../../../core/themes/app_typography.dart';
import '../../../../core/themes/spacings.dart';

// ═══════════════════════════════════════════════════════════════════════
// QUESTION NAVIGATION PANEL
// ═══════════════════════════════════════════════════════════════════════

/// Status of a question in the navigator.
enum QuestionNavStatus {
  /// Not yet answered.
  unanswered,

  /// Currently being viewed.
  current,

  /// Answer has been provided.
  answered,

  /// Flagged for review.
  flagged,
}

/// A question navigation panel with a grid of numbered buttons.
///
/// Color coding:
/// - **Answered** → green
/// - **Current** → primary
/// - **Unanswered** → grey
/// - **Flagged** → amber
///
/// On desktop, appears as a compact sidebar; on mobile, as a bottom sheet.
class QuestionNavigator extends StatelessWidget {
  const QuestionNavigator({
    super.key,
    required this.totalQuestions,
    required this.currentIndex,
    required this.answeredIndices,
    required this.flaggedIndices,
    required this.onQuestionTap,
    this.isDesktop = true,
  });

  /// Total number of questions.
  final int totalQuestions;

  /// Index of the currently viewed question (0-based).
  final int currentIndex;

  /// Set of question indices that have been answered.
  final Set<int> answeredIndices;

  /// Set of question indices that are flagged.
  final Set<int> flaggedIndices;

  /// Callback when a question number is tapped.
  final ValueChanged<int> onQuestionTap;

  /// Whether to use the desktop sidebar layout.
  final bool isDesktop;

  int get _answeredCount => answeredIndices.length;
  int get _flaggedCount => flaggedIndices.length;

  QuestionNavStatus _statusForIndex(int index) {
    if (index == currentIndex) return QuestionNavStatus.current;
    if (flaggedIndices.contains(index)) return QuestionNavStatus.flagged;
    if (answeredIndices.contains(index)) return QuestionNavStatus.answered;
    return QuestionNavStatus.unanswered;
  }

  Color _buttonColor(BuildContext context, QuestionNavStatus status) {
    final cs = context.colorScheme;
    switch (status) {
      case QuestionNavStatus.answered:
        return AppColors.successOf(cs.brightness);
      case QuestionNavStatus.current:
        return cs.primary;
      case QuestionNavStatus.unanswered:
        return cs.onSurfaceVariant.withValues(alpha: 0.3);
      case QuestionNavStatus.flagged:
        return AppColors.warningOf(cs.brightness);
    }
  }

  Color _buttonTextColor(BuildContext context, QuestionNavStatus status) {
    final cs = context.colorScheme;
    switch (status) {
      case QuestionNavStatus.answered:
      case QuestionNavStatus.current:
        return cs.onPrimary;
      case QuestionNavStatus.unanswered:
        return cs.onSurfaceVariant;
      case QuestionNavStatus.flagged:
        return cs.onSurface;
    }
  }

  Color _buttonBgColor(BuildContext context, QuestionNavStatus status) {
    final cs = context.colorScheme;
    final isDark = context.isDarkMode;
    switch (status) {
      case QuestionNavStatus.answered:
        return AppColors.successOf(cs.brightness)
            .withValues(alpha: isDark ? 0.25 : 0.15);
      case QuestionNavStatus.current:
        return cs.primary.withValues(alpha: isDark ? 0.25 : 0.15);
      case QuestionNavStatus.unanswered:
        return cs.surfaceContainerHighest;
      case QuestionNavStatus.flagged:
        return AppColors.warningOf(cs.brightness)
            .withValues(alpha: isDark ? 0.25 : 0.15);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;
    final tt = context.textTheme;

    final header = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Questions',
          style: tt.titleSmall?.copyWith(
            fontWeight: AppTypography.wSemiBold,
            color: cs.onSurface,
          ),
        ),
        const SizedBox(height: Spacings.sm),
        Row(
          children: [
            _buildStatChip(
              context,
              icon: Icons.check_circle_rounded,
              label: '$_answeredCount/ $totalQuestions',
              color: AppColors.successOf(cs.brightness),
            ),
            const SizedBox(width: Spacings.sm),
            _buildStatChip(
              context,
              icon: Icons.flag_rounded,
              label: '$_flaggedCount',
              color: AppColors.warningOf(cs.brightness),
            ),
          ],
        ),
      ],
    );

    final grid = GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 5,
        mainAxisSpacing: Spacings.xs,
        crossAxisSpacing: Spacings.xs,
        childAspectRatio: 1.0,
      ),
      itemCount: totalQuestions,
      itemBuilder: (context, index) {
        final status = _statusForIndex(index);
        final bgColor = _buttonBgColor(context, status);
        final fgColor = _buttonColor(context, status);
        final textColor = _buttonTextColor(context, status);
        final isCurrent = status == QuestionNavStatus.current;

        return Material(
          color: bgColor,
          borderRadius: BorderRadius.circular(Spacings.smRadius),
          child: InkWell(
            onTap: () => onQuestionTap(index),
            borderRadius: BorderRadius.circular(Spacings.smRadius),
            child: Container(
              decoration: isCurrent
                  ? BoxDecoration(
                      borderRadius: BorderRadius.circular(Spacings.smRadius),
                      border: Border.all(color: fgColor, width: 2.0),
                    )
                  : null,
              child: Center(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Text(
                      '${index + 1}',
                      style: tt.labelMedium?.copyWith(
                        fontWeight: isCurrent
                            ? AppTypography.wBold
                            : AppTypography.wSemiBold,
                        color: textColor,
                      ),
                    ),
                    if (status == QuestionNavStatus.flagged)
                      Positioned(
                        top: 2,
                        right: 2,
                        child: Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: fgColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );

    final legend = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: Spacings.sm),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _legendItem(context, Colors.grey, 'Unanswered'),
            const SizedBox(width: Spacings.md),
            _legendItem(
                context, AppColors.successOf(cs.brightness), 'Answered',),
            const SizedBox(width: Spacings.md),
            _legendItem(
                context, AppColors.warningOf(cs.brightness), 'Flagged',),
          ],
        ),
      ],
    );

    if (isDesktop) {
      return Container(
        constraints: const BoxConstraints(maxWidth: 240),
        padding: const EdgeInsets.all(Spacings.md),
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(Spacings.mdRadius),
          border: Border.all(
            color: cs.outlineVariant.withValues(alpha: 0.5),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            header,
            const SizedBox(height: Spacings.md),
            Flexible(child: grid),
            legend,
          ],
        ),
      );
    }

    // Mobile layout: compact version
    return Container(
      padding: const EdgeInsets.all(Spacings.md),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(Spacings.lgRadius),
        ),
        border: Border.all(
          color: cs.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          header,
          const SizedBox(height: Spacings.md),
          SizedBox(
            height: 200,
            child: grid,
          ),
          legend,
        ],
      ),
    );
  }

  Widget _buildStatChip(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
  }) {
    final isDark = context.isDarkMode;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Spacings.sm,
        vertical: Spacings.xs,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.20 : 0.10),
        borderRadius: BorderRadius.circular(Spacings.smRadius),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14.0, color: color),
          const SizedBox(width: Spacings.xs),
          Text(
            label,
            style: TextStyle(
              fontSize: 12.0,
              fontWeight: AppTypography.wSemiBold,
              color: isDark ? color.withValues(alpha: 0.9) : color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _legendItem(BuildContext context, Color color, String label) {
    final tt = context.textTheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.3),
            shape: BoxShape.circle,
            border: Border.all(color: color, width: 1.5),
          ),
        ),
        const SizedBox(width: Spacings.xs),
        Text(
          label,
          style: tt.bodySmall?.copyWith(
            color: context.colorScheme.onSurfaceVariant,
            fontSize: 10.0,
          ),
        ),
      ],
    );
  }
}
