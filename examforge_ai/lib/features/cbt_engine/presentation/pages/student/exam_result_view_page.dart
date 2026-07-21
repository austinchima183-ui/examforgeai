import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/themes/app_colors.dart';
import '../../../../../core/themes/app_typography.dart';
import '../../../../../core/themes/spacings.dart';
import '../../../../../core/extensions/context_extensions.dart';
import '../../../../../shared/widgets/app_app_bar.dart';
import '../../../../../shared/widgets/app_button.dart';
import '../../../../../shared/widgets/app_card.dart';
import '../../../../../shared/widgets/app_empty_state.dart';
import '../../../../../shared/widgets/app_loading.dart';
import '../../../../question_bank/presentation/widgets/question_type_badge.dart';
import '../../../domain/entities/cbt_entities.dart';
import '../../providers/exam_results_provider.dart';

// ═══════════════════════════════════════════════════════════════════════
// EXAM RESULT VIEW PAGE (Student)
// ═══════════════════════════════════════════════════════════════════════

/// Student result view page showing score card, question breakdown,
/// and comparison to class average.
class ExamResultViewPage extends ConsumerWidget {
  const ExamResultViewPage({
    super.key,
    required this.examId,
    this.studentId,
  });

  final String examId;
  final String? studentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(examResultsProvider);
    final result = state.currentResult;

    return Scaffold(
      appBar: AppAppBar(
        title: 'Exam Result',
      ),
      body: state.isLoading
          ? const Center(
              child: AppLoadingSpinner(size: AppLoadingSpinnerSize.large))
          : result == null
              ? Center(
                  child: AppEmptyState(
                    icon: Icons.assignment_outlined,
                    title: 'Result Not Available',
                    subtitle: state.error ?? 'Your result is not yet available.',
                    actionLabel: 'Go Back',
                    onAction: () => Navigator.of(context).pop(),
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(Spacings.lg),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 800),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // ── Score Card ────────────────────────────────
                          _buildScoreCard(context, result),
                          const SizedBox(height: Spacings.xl),

                          // ── Detail Stats ──────────────────────────────
                          _buildDetailStats(context, result),
                          const SizedBox(height: Spacings.xl),

                          // ── Subject Average Comparison ────────────────
                          if (result.subjectAverage != null)
                            _buildAverageComparison(context, result),
                          if (result.subjectAverage != null)
                            const SizedBox(height: Spacings.xl),

                          // ── Question Breakdown ────────────────────────
                          _buildQuestionBreakdown(context, result),
                          const SizedBox(height: Spacings.xl),

                          // ── Ranking ──────────────────────────────────
                          if (result.rank != null)
                            _buildRanking(context, result),
                        ],
                      ),
                    ),
                  ),
                ),
    );
  }

  // ─── Score Card ───────────────────────────────────────────────────────

  Widget _buildScoreCard(BuildContext context, ExamResultEntity result) {
    final cs = context.colorScheme;
    final tt = context.textTheme;
    final isDark = context.isDarkMode;
    final passColor = result.isPassed
        ? AppColors.successOf(cs.brightness)
        : AppColors.errorOf(cs.brightness);

    return AppCard(
      child: Column(
        children: [
          // Pass/Fail badge
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: Spacings.sm),
            decoration: BoxDecoration(
              color: passColor.withOpacity(isDark ? 0.15 : 0.08),
              borderRadius: BorderRadius.circular(Spacings.smRadius),
            ),
            child: Text(
              result.isPassed ? 'PASSED' : 'FAILED',
              textAlign: TextAlign.center,
              style: tt.titleLarge?.copyWith(
                fontWeight: AppTypography.wBold,
                color: passColor,
                letterSpacing: 2.0,
              ),
            ),
          ),

          const SizedBox(height: Spacings.xl),

          // Score circle
          Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: passColor.withOpacity(isDark ? 0.15 : 0.08),
              border: Border.all(color: passColor, width: 4),
            ),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${result.scorePercentage.toStringAsFixed(1)}%',
                    style: tt.headlineLarge?.copyWith(
                      fontWeight: AppTypography.wBold,
                      color: passColor,
                    ),
                  ),
                  Text(
                    'Score',
                    style: tt.labelMedium?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: Spacings.lg),

          // Marks and grade
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '${result.totalMarks.toStringAsFixed(1)} / ${result.totalPossible.toStringAsFixed(0)} marks',
                style: tt.titleMedium?.copyWith(
                  fontWeight: AppTypography.wSemiBold,
                  color: cs.onSurface,
                ),
              ),
              if (result.grade != null) ...[
                const SizedBox(width: Spacings.md),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: Spacings.md,
                    vertical: Spacings.xs,
                  ),
                  decoration: BoxDecoration(
                    color: cs.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(Spacings.smRadius),
                  ),
                  child: Text(
                    'Grade: ${result.grade}',
                    style: tt.titleSmall?.copyWith(
                      fontWeight: AppTypography.wBold,
                      color: cs.primary,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  // ─── Detail Stats ─────────────────────────────────────────────────────

  Widget _buildDetailStats(BuildContext context, ExamResultEntity result) {
    final cs = context.colorScheme;
    final tt = context.textTheme;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Details',
            style: tt.titleSmall?.copyWith(
              fontWeight: AppTypography.wSemiBold,
              color: cs.onSurface,
            ),
          ),
          const SizedBox(height: Spacings.md),
          _statRow(context, 'Total Marks', '${result.totalMarks.toStringAsFixed(1)} / ${result.totalPossible.toStringAsFixed(0)}'),
          _statRow(context, 'Percentage', '${result.scorePercentage.toStringAsFixed(1)}%'),
          if (result.grade != null)
            _statRow(context, 'Grade', result.grade!),
          _statRow(context, 'Status', result.isPassed ? 'Passed' : 'Failed'),
          _statRow(context, 'Time Spent', _formatTimeSpent(result.timeSpentSeconds)),
          _statRow(context, 'Grading', result.gradingStatus.label),
        ],
      ),
    );
  }

  Widget _statRow(BuildContext context, String label, String value) {
    final cs = context.colorScheme;
    final tt = context.textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: Spacings.sm),
      child: Row(
        children: [
          Text(
            label,
            style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
          ),
          const Spacer(),
          Text(
            value,
            style: tt.bodyMedium?.copyWith(
              fontWeight: AppTypography.wSemiBold,
              color: cs.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  // ─── Average Comparison ───────────────────────────────────────────────

  Widget _buildAverageComparison(BuildContext context, ExamResultEntity result) {
    final cs = context.colorScheme;
    final tt = context.textTheme;
    final avg = result.subjectAverage!;
    final diff = result.scorePercentage - avg;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Class Average Comparison',
            style: tt.titleSmall?.copyWith(
              fontWeight: AppTypography.wSemiBold,
              color: cs.onSurface,
            ),
          ),
          const SizedBox(height: Spacings.md),
          Row(
            children: [
              // Your score
              Expanded(
                child: Column(
                  children: [
                    Text(
                      '${result.scorePercentage.toStringAsFixed(1)}%',
                      style: tt.headlineSmall?.copyWith(
                        fontWeight: AppTypography.wBold,
                        color: cs.primary,
                      ),
                    ),
                    Text(
                      'Your Score',
                      style: tt.bodySmall?.copyWith(
                          color: cs.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              // VS
              Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: Spacings.sm,
                      vertical: Spacings.xs,
                    ),
                    decoration: BoxDecoration(
                      color: diff >= 0
                          ? AppColors.successOf(cs.brightness)
                              .withOpacity(context.isDarkMode ? 0.15 : 0.08)
                          : AppColors.errorOf(cs.brightness)
                              .withOpacity(context.isDarkMode ? 0.15 : 0.08),
                      borderRadius: BorderRadius.circular(Spacings.smRadius),
                    ),
                    child: Text(
                      '${diff >= 0 ? '+' : ''}${diff.toStringAsFixed(1)}%',
                      style: tt.labelLarge?.copyWith(
                        fontWeight: AppTypography.wBold,
                        color: diff >= 0
                            ? AppColors.successOf(cs.brightness)
                            : AppColors.errorOf(cs.brightness),
                      ),
                    ),
                  ),
                ],
              ),
              // Class average
              Expanded(
                child: Column(
                  children: [
                    Text(
                      '${avg.toStringAsFixed(1)}%',
                      style: tt.headlineSmall?.copyWith(
                        fontWeight: AppTypography.wBold,
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                    Text(
                      'Class Average',
                      style: tt.bodySmall?.copyWith(
                          color: cs.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── Question Breakdown ───────────────────────────────────────────────

  Widget _buildQuestionBreakdown(BuildContext context, ExamResultEntity result) {
    final cs = context.colorScheme;
    final tt = context.textTheme;

    // In a full implementation, this would use actual answer data from the result.
    // For now, we show a placeholder structure.
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Question Breakdown',
            style: tt.titleSmall?.copyWith(
              fontWeight: AppTypography.wSemiBold,
              color: cs.onSurface,
            ),
          ),
          const SizedBox(height: Spacings.md),
          // Placeholder - in production this would iterate over actual answers
          Center(
            child: Padding(
              padding: const EdgeInsets.all(Spacings.lg),
              child: Column(
                children: [
                  Icon(
                    Icons.checklist_rounded,
                    size: Spacings.xlIcon,
                    color: cs.onSurfaceVariant.withOpacity(0.5),
                  ),
                  const SizedBox(height: Spacings.md),
                  Text(
                    'Detailed breakdown will be available when results are fully graded and released.',
                    style: tt.bodyMedium?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Ranking ──────────────────────────────────────────────────────────

  Widget _buildRanking(BuildContext context, ExamResultEntity result) {
    final cs = context.colorScheme;
    final tt = context.textTheme;

    return AppCard(
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: cs.primary.withOpacity(context.isDarkMode ? 0.20 : 0.10),
              borderRadius: BorderRadius.circular(Spacings.mdRadius),
            ),
            child: Center(
              child: Text(
                '#${result.rank}',
                style: tt.headlineSmall?.copyWith(
                  fontWeight: AppTypography.wBold,
                  color: cs.primary,
                ),
              ),
            ),
          ),
          const SizedBox(width: Spacings.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Your Ranking',
                  style: tt.titleSmall?.copyWith(
                    fontWeight: AppTypography.wSemiBold,
                    color: cs.onSurface,
                  ),
                ),
                const SizedBox(height: Spacings.xs),
                Text(
                  'You ranked #${result.rank} in this exam',
                  style: tt.bodyMedium?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.emoji_events_rounded,
            size: Spacings.lgIcon,
            color: (result.rank ?? 999) <= 3
                ? const Color(0xFFF59E0B)
                : cs.onSurfaceVariant,
          ),
        ],
      ),
    );
  }

  String _formatTimeSpent(int seconds) {
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    final s = seconds % 60;
    if (h > 0) return '${h}h ${m}m ${s}s';
    if (m > 0) return '${m}m ${s}s';
    return '${s}s';
  }
}
