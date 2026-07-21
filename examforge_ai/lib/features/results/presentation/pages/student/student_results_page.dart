import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/themes/app_colors.dart';
import '../../../../../core/themes/app_typography.dart';
import '../../../../../core/themes/spacings.dart';
import '../../../../../core/extensions/context_extensions.dart';
import '../../../../../shared/widgets/app_app_bar.dart';
import '../../../../../shared/widgets/app_card.dart';
import '../../../../../shared/widgets/app_empty_state.dart';
import '../../../../../shared/widgets/app_loading.dart';
import '../../../domain/entities/results_entities.dart';
import '../../providers/results_providers.dart';
import '../../providers/results_page_providers.dart';

// ═══════════════════════════════════════════════════════════════════════
// STUDENT RESULTS PAGE
// ═══════════════════════════════════════════════════════════════════════

/// Student's personal results dashboard showing overall score, subject
/// breakdowns, performance trends, strengths/weaknesses, AI study
/// recommendations, and teacher comments.
class StudentResultsPage extends ConsumerStatefulWidget {
  const StudentResultsPage({
    super.key,
    required this.studentId,
    required this.classId,
    required this.academicSessionId,
  });

  final String studentId;
  final String classId;
  final String academicSessionId;

  @override
  ConsumerState<StudentResultsPage> createState() => _StudentResultsPageState();
}

class _StudentResultsPageState extends ConsumerState<StudentResultsPage> {
  @override
  void initState() {
    super.initState();
    // Load data after the first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadResults();
    });
  }

  void _loadResults() {
    ref.read(studentResultsProvider.notifier).loadOverallResult(
          studentId: widget.studentId,
          classId: widget.classId,
          academicSessionId: widget.academicSessionId,
        );
    ref.read(studentResultsProvider.notifier).loadSubjectResults(
          studentId: widget.studentId,
          academicSessionId: widget.academicSessionId,
        );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(studentResultsProvider);

    return Scaffold(
      appBar: const AppAppBar(
        title: 'My Results',
      ),
      body: state.isLoading
          ? const Center(
              child: AppLoadingSpinner(size: AppLoadingSpinnerSize.large))
          : state.error != null
              ? Center(
                  child: AppEmptyState(
                    icon: Icons.error_outline_rounded,
                    title: 'Something went wrong',
                    subtitle: state.error,
                    actionLabel: 'Retry',
                    onAction: _loadResults,
                  ),
                )
              : _buildContent(context, state),
    );
  }

  // ─── Main Content ────────────────────────────────────────────────────

  Widget _buildContent(BuildContext context, StudentResultsState state) {
    final overall = state.overallResult;
    final subjects = state.subjectResults;

    if (overall == null && subjects.isEmpty) {
      return Center(
        child: AppEmptyState(
          icon: Icons.assignment_outlined,
          title: 'No Results Yet',
          subtitle: 'Your results will appear here once exams are graded.',
          actionLabel: 'Refresh',
          onAction: _loadResults,
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(Spacings.lg),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Overall Score Card ────────────────────────────────
              if (overall != null) _buildOverallScoreCard(context, overall),
              if (overall != null) const SizedBox(height: Spacings.xl),

              // ── Subject Breakdown ─────────────────────────────────
              _buildSubjectBreakdown(context, subjects),
              const SizedBox(height: Spacings.xl),

              // ── Performance Trend ─────────────────────────────────
              _buildPerformanceTrend(context, overall),
              const SizedBox(height: Spacings.xl),

              // ── Strengths & Weaknesses ────────────────────────────
              _buildStrengthsWeaknesses(context, subjects),
              const SizedBox(height: Spacings.xl),

              // ── AI Study Recommendations ──────────────────────────
              if (overall != null &&
                  overall.aiStudyRecommendations.isNotEmpty)
                _buildAiRecommendations(context, overall),
              if (overall != null &&
                  overall.aiStudyRecommendations.isNotEmpty)
                const SizedBox(height: Spacings.xl),

              // ── Teacher Comment ──────────────────────────────────
              if (overall != null && overall.teacherComment != null)
                _buildTeacherComment(context, overall),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Overall Score Card ──────────────────────────────────────────────

  Widget _buildOverallScoreCard(
      BuildContext context, StudentOverallResultEntity overall) {
    final cs = context.colorScheme;
    final tt = context.textTheme;
    final isDark = context.isDarkMode;
    final isPassed = overall.subjectsFailed == 0;

    final statusColor = isPassed
        ? AppColors.successOf(cs.brightness)
        : AppColors.errorOf(cs.brightness);

    return AppCard(
      child: Column(
        children: [
          // Pass/Fail banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: Spacings.sm),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(isDark ? 0.15 : 0.08),
              borderRadius: BorderRadius.circular(Spacings.smRadius),
            ),
            child: Text(
              isPassed ? 'PASSED' : 'FAILED',
              textAlign: TextAlign.center,
              style: tt.titleLarge?.copyWith(
                fontWeight: AppTypography.wBold,
                color: statusColor,
                letterSpacing: 2.0,
              ),
            ),
          ),

          const SizedBox(height: Spacings.xl),

          // Score circle + key stats
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Score circle
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: cs.primary.withOpacity(isDark ? 0.15 : 0.08),
                  border: Border.all(color: cs.primary, width: 3),
                ),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${overall.overallPercentage.toStringAsFixed(1)}%',
                        style: tt.headlineSmall?.copyWith(
                          fontWeight: AppTypography.wBold,
                          color: cs.primary,
                        ),
                      ),
                      Text(
                        'Overall',
                        style: tt.labelSmall?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(width: Spacings.xl),

              // Key stats
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (overall.overallGrade != null)
                      _statRow(context, 'Grade', overall.overallGrade!),
                    if (overall.overallGpa != null)
                      _statRow(context, 'GPA',
                          overall.overallGpa!.toStringAsFixed(2)),
                    _statRow(context, 'Position', overall.positionLabel),
                    _statRow(
                        context, 'Subjects Passed', '${overall.subjectsPassed}'),
                    _statRow(
                        context, 'Subjects Failed', '${overall.subjectsFailed}'),
                    if (overall.isPromoted != null)
                      _statRow(context, 'Promoted',
                          overall.isPromoted! ? 'Yes' : 'No'),
                  ],
                ),
              ),
            ],
          ),
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

  // ─── Subject Breakdown ───────────────────────────────────────────────

  Widget _buildSubjectBreakdown(
      BuildContext context, List<StudentSubjectResultEntity> subjects) {
    final cs = context.colorScheme;
    final tt = context.textTheme;

    if (subjects.isEmpty) {
      return AppCard(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(Spacings.xl),
            child: Text(
              'No subject results available yet.',
              style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
            ),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Subject Breakdown',
          style: tt.titleMedium?.copyWith(
            fontWeight: AppTypography.wSemiBold,
            color: cs.onSurface,
          ),
        ),
        const SizedBox(height: Spacings.md),
        ...subjects.map((subject) => Padding(
              padding: const EdgeInsets.only(bottom: Spacings.md),
              child: _buildSubjectCard(context, subject),
            )),
      ],
    );
  }

  Widget _buildSubjectCard(
      BuildContext context, StudentSubjectResultEntity subject) {
    final cs = context.colorScheme;
    final tt = context.textTheme;
    final isDark = context.isDarkMode;

    final passColor = subject.isPassed
        ? AppColors.successOf(cs.brightness)
        : AppColors.errorOf(cs.brightness);

    final trendIcon = switch (subject.performanceTrend) {
      PerformanceTrend.improving => Icons.trending_up_rounded,
      PerformanceTrend.stable => Icons.trending_flat_rounded,
      PerformanceTrend.declining => Icons.trending_down_rounded,
    };

    final trendColor = switch (subject.performanceTrend) {
      PerformanceTrend.improving => AppColors.successOf(cs.brightness),
      PerformanceTrend.stable => cs.onSurfaceVariant,
      PerformanceTrend.declining => AppColors.errorOf(cs.brightness),
    };

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top row: subject name + trend
          Row(
            children: [
              Expanded(
                child: Text(
                  subject.metadata['subjectName'] as String? ??
                      subject.subjectId,
                  style: tt.titleSmall?.copyWith(
                    fontWeight: AppTypography.wSemiBold,
                    color: cs.onSurface,
                  ),
                ),
              ),
              Icon(trendIcon, size: Spacings.mdIcon, color: trendColor),
            ],
          ),
          const SizedBox(height: Spacings.md),

          // Score + grade row
          Row(
            children: [
              // Score percentage
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: passColor.withOpacity(isDark ? 0.15 : 0.08),
                  border: Border.all(color: passColor, width: 2),
                ),
                child: Center(
                  child: Text(
                    '${subject.percentage.toStringAsFixed(0)}%',
                    style: tt.labelLarge?.copyWith(
                      fontWeight: AppTypography.wBold,
                      color: passColor,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: Spacings.md),

              // Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        if (subject.grade != null) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: Spacings.sm,
                              vertical: Spacings.xs,
                            ),
                            decoration: BoxDecoration(
                              color:
                                  cs.primary.withOpacity(0.1),
                              borderRadius:
                                  BorderRadius.circular(Spacings.smRadius),
                            ),
                            child: Text(
                              subject.grade!,
                              style: tt.labelMedium?.copyWith(
                                fontWeight: AppTypography.wBold,
                                color: cs.primary,
                              ),
                            ),
                          ),
                          const SizedBox(width: Spacings.sm),
                        ],
                        Text(
                          subject.isPassed ? 'Passed' : 'Failed',
                          style: tt.bodySmall?.copyWith(
                            color: passColor,
                            fontWeight: AppTypography.wSemiBold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: Spacings.xs),
                    Text(
                      'Position: ${subject.positionLabel}',
                      style: tt.bodySmall?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),

              // Class average comparison
              if (subject.classAverage != null)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Class Avg',
                      style: tt.labelSmall?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                    Text(
                      '${subject.classAverage!.toStringAsFixed(1)}%',
                      style: tt.bodyMedium?.copyWith(
                        fontWeight: AppTypography.wSemiBold,
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                    if (subject.deviationFromClassAverage != null) ...[
                      const SizedBox(height: Spacings.xs),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: Spacings.sm,
                          vertical: Spacings.xs,
                        ),
                        decoration: BoxDecoration(
                          color: subject.deviationFromClassAverage! >= 0
                              ? AppColors.successOf(cs.brightness)
                                  .withOpacity(isDark ? 0.15 : 0.08)
                              : AppColors.errorOf(cs.brightness)
                                  .withOpacity(isDark ? 0.15 : 0.08),
                          borderRadius:
                              BorderRadius.circular(Spacings.smRadius),
                        ),
                        child: Text(
                          '${subject.deviationFromClassAverage! >= 0 ? '+' : ''}${subject.deviationFromClassAverage!.toStringAsFixed(1)}%',
                          style: tt.labelSmall?.copyWith(
                            fontWeight: AppTypography.wBold,
                            color: subject.deviationFromClassAverage! >= 0
                                ? AppColors.successOf(cs.brightness)
                                : AppColors.errorOf(cs.brightness),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── Performance Trend ───────────────────────────────────────────────

  Widget _buildPerformanceTrend(
      BuildContext context, StudentOverallResultEntity? overall) {
    final cs = context.colorScheme;
    final tt = context.textTheme;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.show_chart_rounded,
                  size: Spacings.mdIcon, color: cs.primary),
              const SizedBox(width: Spacings.sm),
              Text(
                'Performance Trend',
                style: tt.titleSmall?.copyWith(
                  fontWeight: AppTypography.wSemiBold,
                  color: cs.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: Spacings.lg),

          // Placeholder for chart
          Container(
            width: double.infinity,
            height: 180,
            decoration: BoxDecoration(
              color: cs.surfaceContainerHighest.withOpacity(0.3),
              borderRadius: BorderRadius.circular(Spacings.mdRadius),
              border: Border.all(
                color: cs.outlineVariant.withOpacity(0.5),
                style: BorderStyle.solid,
              ),
            ),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.insert_chart_outlined_rounded,
                    size: Spacings.xlIcon,
                    color: cs.onSurfaceVariant.withOpacity(0.4),
                  ),
                  const SizedBox(height: Spacings.sm),
                  Text(
                    'Performance trend chart will appear here',
                    style: tt.bodySmall?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Strengths & Weaknesses ──────────────────────────────────────────

  Widget _buildStrengthsWeaknesses(
      BuildContext context, List<StudentSubjectResultEntity> subjects) {
    final cs = context.colorScheme;
    final tt = context.textTheme;

    // Aggregate strengths and weaknesses from all subjects
    final allStrengths = <String>[];
    final allWeaknesses = <String>[];
    for (final subject in subjects) {
      allStrengths.addAll(subject.strengths);
      allWeaknesses.addAll(subject.weaknesses);
    }

    if (allStrengths.isEmpty && allWeaknesses.isEmpty) {
      return const SizedBox.shrink();
    }

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Strengths & Weaknesses',
            style: tt.titleSmall?.copyWith(
              fontWeight: AppTypography.wSemiBold,
              color: cs.onSurface,
            ),
          ),
          const SizedBox(height: Spacings.md),

          // Strengths
          if (allStrengths.isNotEmpty) ...[
            Row(
              children: [
                Icon(Icons.thumb_up_outlined,
                    size: Spacings.smIcon,
                    color: AppColors.successOf(cs.brightness)),
                const SizedBox(width: Spacings.sm),
                Text(
                  'Strengths',
                  style: tt.labelLarge?.copyWith(
                    fontWeight: AppTypography.wSemiBold,
                    color: AppColors.successOf(cs.brightness),
                  ),
                ),
              ],
            ),
            const SizedBox(height: Spacings.sm),
            ...allStrengths.take(5).map((strength) => Padding(
                  padding: const EdgeInsets.only(
                      left: Spacings.lg, bottom: Spacings.xs),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '\u2022',
                        style: tt.bodyMedium?.copyWith(
                          color: AppColors.successOf(cs.brightness),
                        ),
                      ),
                      const SizedBox(width: Spacings.sm),
                      Expanded(
                        child: Text(
                          strength,
                          style: tt.bodyMedium?.copyWith(
                            color: cs.onSurface,
                          ),
                        ),
                      ),
                    ],
                  ),
                )),
          ],

          if (allStrengths.isNotEmpty && allWeaknesses.isNotEmpty)
            const SizedBox(height: Spacings.md),

          // Weaknesses
          if (allWeaknesses.isNotEmpty) ...[
            Row(
              children: [
                Icon(Icons.warning_amber_rounded,
                    size: Spacings.smIcon,
                    color: AppColors.errorOf(cs.brightness)),
                const SizedBox(width: Spacings.sm),
                Text(
                  'Areas for Improvement',
                  style: tt.labelLarge?.copyWith(
                    fontWeight: AppTypography.wSemiBold,
                    color: AppColors.errorOf(cs.brightness),
                  ),
                ),
              ],
            ),
            const SizedBox(height: Spacings.sm),
            ...allWeaknesses.take(5).map((weakness) => Padding(
                  padding: const EdgeInsets.only(
                      left: Spacings.lg, bottom: Spacings.xs),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '\u2022',
                        style: tt.bodyMedium?.copyWith(
                          color: AppColors.errorOf(cs.brightness),
                        ),
                      ),
                      const SizedBox(width: Spacings.sm),
                      Expanded(
                        child: Text(
                          weakness,
                          style: tt.bodyMedium?.copyWith(
                            color: cs.onSurface,
                          ),
                        ),
                      ),
                    ],
                  ),
                )),
          ],
        ],
      ),
    );
  }

  // ─── AI Study Recommendations ────────────────────────────────────────

  Widget _buildAiRecommendations(
      BuildContext context, StudentOverallResultEntity overall) {
    final cs = context.colorScheme;
    final tt = context.textTheme;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.auto_awesome_rounded,
                  size: Spacings.mdIcon, color: cs.primary),
              const SizedBox(width: Spacings.sm),
              Text(
                'AI Study Recommendations',
                style: tt.titleSmall?.copyWith(
                  fontWeight: AppTypography.wSemiBold,
                  color: cs.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: Spacings.md),
          ...overall.aiStudyRecommendations.map((rec) => Padding(
                padding: const EdgeInsets.only(bottom: Spacings.sm),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      margin: const EdgeInsets.only(top: 4),
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: cs.primary,
                      ),
                    ),
                    const SizedBox(width: Spacings.sm),
                    Expanded(
                      child: Text(
                        rec,
                        style: tt.bodyMedium?.copyWith(
                          color: cs.onSurface,
                        ),
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  // ─── Teacher Comment ─────────────────────────────────────────────────

  Widget _buildTeacherComment(
      BuildContext context, StudentOverallResultEntity overall) {
    final cs = context.colorScheme;
    final tt = context.textTheme;
    final isDark = context.isDarkMode;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.rate_review_outlined,
                  size: Spacings.mdIcon, color: cs.tertiary),
              const SizedBox(width: Spacings.sm),
              Text(
                'Teacher\'s Comment',
                style: tt.titleSmall?.copyWith(
                  fontWeight: AppTypography.wSemiBold,
                  color: cs.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: Spacings.md),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(Spacings.md),
            decoration: BoxDecoration(
              color: cs.tertiary.withOpacity(isDark ? 0.10 : 0.05),
              borderRadius: BorderRadius.circular(Spacings.mdRadius),
              border: Border.all(
                color: cs.tertiary.withOpacity(0.2),
              ),
            ),
            child: Text(
              overall.teacherComment!,
              style: tt.bodyMedium?.copyWith(
                color: cs.onSurface,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
