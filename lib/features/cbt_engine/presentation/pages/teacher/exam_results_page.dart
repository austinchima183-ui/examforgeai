import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../config/dependency_injection.dart';
import '../../../../../core/extensions/context_extensions.dart';
import '../../../../../core/themes/app_colors.dart';
import '../../../../../core/themes/app_typography.dart';
import '../../../../../core/themes/spacings.dart';
import '../../../../../shared/widgets/app_app_bar.dart';
import '../../../../../shared/widgets/app_button.dart';
import '../../../../../shared/widgets/app_card.dart';
import '../../../../../shared/widgets/app_dialog.dart';
import '../../../../../shared/widgets/app_empty_state.dart';
import '../../../../../shared/widgets/app_loading.dart';
import '../../../domain/entities/cbt_entities.dart';
import '../../providers/exam_results_provider.dart';

// ═══════════════════════════════════════════════════════════════════════
// EXAM RESULTS PAGE (Teacher)
// ═══════════════════════════════════════════════════════════════════════

/// Results and grading page for a completed exam.
class ExamResultsPage extends ConsumerStatefulWidget {
  const ExamResultsPage({super.key, required this.examId});

  final String examId;

  @override
  ConsumerState<ExamResultsPage> createState() => _ExamResultsPageState();
}

class _ExamResultsPageState extends ConsumerState<ExamResultsPage> {
  ResultsSortField _sortField = ResultsSortField.score;
  bool _sortAscending = false;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(examResultsProvider.notifier).loadResults(widget.examId);
      ref.read(examResultsProvider.notifier).loadStatistics(widget.examId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;
    final tt = context.textTheme;
    final state = ref.watch(examResultsProvider);
    final stats = state.statistics;

    return Scaffold(
      appBar: AppAppBar(
        title: 'Exam Results',
        actions: [
          AppButton(
            label: 'Release Results',
            onPressed: state.isReleasing
                ? null
                : () => _releaseResults(),
            variant: AppButtonVariant.tonal,
            size: AppButtonSize.small,
            icon: Icons.send_rounded,
            isLoading: state.isReleasing,
          ),
          const SizedBox(width: Spacings.sm),
          AppButton(
            label: 'Export',
            onPressed: () {},
            variant: AppButtonVariant.outlined,
            size: AppButtonSize.small,
            icon: Icons.download_rounded,
          ),
          const SizedBox(width: Spacings.md),
        ],
      ),
      body: state.isLoading
          ? const Center(
              child: AppLoadingSpinner(size: AppLoadingSpinnerSize.large),)
          : SingleChildScrollView(
              padding: const EdgeInsets.all(Spacings.lg),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1000),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Statistics Summary ─────────────────────────────
                      if (stats != null) ...[
                        _buildStatsSummary(context, stats),
                        const SizedBox(height: Spacings.xl),
                      ],

                      // ── Results Table ──────────────────────────────────
                      _buildResultsTable(context, state),

                      // ── Error state ───────────────────────────────────
                      if (state.error != null)
                        Padding(
                          padding: const EdgeInsets.only(top: Spacings.md),
                          child: Text(
                            state.error!,
                            style: tt.bodySmall?.copyWith(
                              color: AppColors.errorOf(cs.brightness),
                            ),
                          ),
                        ),

                      // ── Success message ────────────────────────────────
                      if (state.successMessage != null)
                        Padding(
                          padding: const EdgeInsets.only(top: Spacings.md),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(Spacings.md),
                            decoration: BoxDecoration(
                              color: AppColors.successOf(cs.brightness)
                                  .withValues(alpha: context.isDarkMode ? 0.15 : 0.08),
                              borderRadius:
                                  BorderRadius.circular(Spacings.smRadius),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.check_circle_rounded,
                                    color: AppColors.successOf(cs.brightness),),
                                const SizedBox(width: Spacings.sm),
                                Text(
                                  state.successMessage!,
                                  style: tt.bodyMedium?.copyWith(
                                    color: AppColors.successOf(cs.brightness),
                                    fontWeight: AppTypography.wSemiBold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildStatsSummary(BuildContext context, ExamStatistics stats) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossCount = constraints.maxWidth > 700 ? 5 : 3;
        return GridView.count(
          crossAxisCount: crossCount,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: Spacings.md,
          crossAxisSpacing: Spacings.md,
          childAspectRatio: 1.4,
          children: [
            AppStatCard(
              title: 'Average',
              value: '${stats.averageScore.toStringAsFixed(1)}%',
              icon: Icons.bar_chart_rounded,
            ),
            AppStatCard(
              title: 'Highest',
              value: '${stats.highestScore.toStringAsFixed(1)}%',
              icon: Icons.arrow_upward_rounded,
              color: AppColors.successOf(context.colorScheme.brightness),
            ),
            AppStatCard(
              title: 'Lowest',
              value: '${stats.lowestScore.toStringAsFixed(1)}%',
              icon: Icons.arrow_downward_rounded,
              color: AppColors.errorOf(context.colorScheme.brightness),
            ),
            AppStatCard(
              title: 'Pass Rate',
              value: '${(stats.passRate * 100).toStringAsFixed(1)}%',
              icon: Icons.check_circle_rounded,
              color: stats.passRate >= 0.5
                  ? AppColors.successOf(context.colorScheme.brightness)
                  : AppColors.warningOf(context.colorScheme.brightness),
            ),
            AppStatCard(
              title: 'Grading',
              value: '${(stats.gradingCompletionPercentage * 100).toStringAsFixed(0)}%',
              icon: Icons.grade_rounded,
            ),
          ],
        );
      },
    );
  }

  Widget _buildResultsTable(BuildContext context, ExamResultsState state) {
    final cs = context.colorScheme;
    final tt = context.textTheme;
    final results = _sortAndFilterResults(state.results);

    if (results.isEmpty) {
      return const AppEmptyState(
        icon: Icons.assignment_outlined,
        title: 'No Results Yet',
        subtitle: 'Results will appear here once students submit their exams.',
      );
    }

    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search + sort bar
          Padding(
            padding: const EdgeInsets.all(Spacings.md),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: const InputDecoration(
                      hintText: 'Search by student name…',
                      prefixIcon: Icon(Icons.search_rounded),
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: Spacings.md,
                        vertical: Spacings.sm,
                      ),
                    ),
                    onChanged: (v) => setState(() => _searchQuery = v),
                  ),
                ),
                const SizedBox(width: Spacings.md),
                PopupMenuButton<ResultsSortField>(
                  onSelected: (field) {
                    setState(() {
                      if (_sortField == field) {
                        _sortAscending = !_sortAscending;
                      } else {
                        _sortField = field;
                        _sortAscending = true;
                      }
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: Spacings.md,
                      vertical: Spacings.sm,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(color: cs.outlineVariant),
                      borderRadius: BorderRadius.circular(Spacings.smRadius),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.sort_rounded,
                            size: Spacings.smIcon, color: cs.onSurfaceVariant,),
                        const SizedBox(width: Spacings.xs),
                        Text(
                          'Sort: ${_sortField.label}',
                          style: tt.bodySmall?.copyWith(
                            color: cs.onSurfaceVariant,
                            fontWeight: AppTypography.wSemiBold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  itemBuilder: (context) => ResultsSortField.values
                      .map((f) => PopupMenuItem(
                            value: f,
                            child: Row(
                              children: [
                                if (_sortField == f)
                                  Icon(_sortAscending
                                      ? Icons.arrow_upward_rounded
                                      : Icons.arrow_downward_rounded,
                                      size: 16,)
                                else
                                  const SizedBox(width: 16),
                                const SizedBox(width: Spacings.sm),
                                Text(f.label),
                              ],
                            ),
                          ),)
                      .toList(),
                ),
              ],
            ),
          ),

          // Table header
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: Spacings.md,
              vertical: Spacings.sm,
            ),
            decoration: BoxDecoration(
              color: cs.surfaceContainerHighest,
            ),
            child: Row(
              children: [
                const SizedBox(width: 40),
                const Expanded(flex: 3, child: Text('Student')),
                _tableHeaderCell('Score', flex: 1),
                _tableHeaderCell('%', flex: 1),
                _tableHeaderCell('Grade', flex: 1),
                _tableHeaderCell('Status', flex: 1),
                _tableHeaderCell('Time', flex: 1),
              ],
            ),
          ),

          // Results list
          ...results.map((result) => _buildResultRow(context, result)),
        ],
      ),
    );
  }

  Widget _tableHeaderCell(String label, {int flex = 1}) {
    return Expanded(
      flex: flex,
      child: Text(
        label,
        style: context.textTheme.labelSmall?.copyWith(
          fontWeight: AppTypography.wBold,
          color: context.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }

  Widget _buildResultRow(BuildContext context, ExamResultEntity result) {
    final cs = context.colorScheme;
    final tt = context.textTheme;

    return InkWell(
      onTap: () => _showResultDetail(context, result),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: Spacings.md,
          vertical: Spacings.md,
        ),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: cs.outlineVariant.withValues(alpha: 0.3),
            ),
          ),
        ),
        child: Row(
          children: [
            // Rank/number
            SizedBox(
              width: 40,
              child: Text(
                '#${result.rank ?? '-'}',
                style: tt.bodySmall?.copyWith(
                  fontWeight: AppTypography.wSemiBold,
                  color: cs.onSurfaceVariant,
                ),
              ),
            ),
            // Student name
            Expanded(
              flex: 3,
              child: Text(
                'Student ${result.studentId.substring(0, 6)}',
                style: tt.bodyMedium?.copyWith(
                  fontWeight: AppTypography.wSemiBold,
                  color: cs.onSurface,
                ),
              ),
            ),
            // Score
            Expanded(
              flex: 1,
              child: Text(
                '${result.totalMarks.toStringAsFixed(1)}/${result.totalPossible.toStringAsFixed(0)}',
                style: tt.bodyMedium?.copyWith(color: cs.onSurface),
              ),
            ),
            // Percentage
            Expanded(
              flex: 1,
              child: Text(
                '${result.scorePercentage.toStringAsFixed(1)}%',
                style: tt.bodyMedium?.copyWith(
                  fontWeight: AppTypography.wBold,
                  color: result.isPassed
                      ? AppColors.successOf(cs.brightness)
                      : AppColors.errorOf(cs.brightness),
                ),
              ),
            ),
            // Grade
            Expanded(
              flex: 1,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: Spacings.sm,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: (result.grade != null
                          ? cs.primary
                          : cs.onSurfaceVariant)
                      .withValues(alpha: context.isDarkMode ? 0.20 : 0.10),
                  borderRadius: BorderRadius.circular(Spacings.smRadius),
                ),
                child: Text(
                  result.grade ?? '-',
                  style: tt.labelSmall?.copyWith(
                    fontWeight: AppTypography.wBold,
                    color: result.grade != null ? cs.primary : cs.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            // Status
            Expanded(
              flex: 1,
              child: _gradingStatusChip(context, result.gradingStatus),
            ),
            // Time
            Expanded(
              flex: 1,
              child: Text(
                _formatTimeSpent(result.timeSpentSeconds),
                style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _gradingStatusChip(BuildContext context, GradingStatus status) {
    final cs = context.colorScheme;
    final tt = context.textTheme;
    final isDark = context.isDarkMode;

    final color = status.isComplete
        ? AppColors.successOf(cs.brightness)
        : AppColors.warningOf(cs.brightness);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Spacings.sm,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.20 : 0.10),
        borderRadius: BorderRadius.circular(Spacings.smRadius),
      ),
      child: Text(
        status.label,
        style: tt.labelSmall?.copyWith(
          fontWeight: AppTypography.wSemiBold,
          color: color,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  List<ExamResultEntity> _sortAndFilterResults(List<ExamResultEntity> results) {
    var filtered = results;

    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filtered = filtered
          .where((r) => r.studentId.toLowerCase().contains(query))
          .toList();
    }

    final sorted = List<ExamResultEntity>.from(filtered);
    sorted.sort((a, b) {
      int cmp;
      switch (_sortField) {
        case ResultsSortField.score:
          cmp = a.scorePercentage.compareTo(b.scorePercentage);
        case ResultsSortField.name:
          cmp = a.studentId.compareTo(b.studentId);
        case ResultsSortField.time:
          cmp = a.timeSpentSeconds.compareTo(b.timeSpentSeconds);
      }
      return _sortAscending ? cmp : -cmp;
    });

    return sorted;
  }

  String _formatTimeSpent(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m}m ${s}s';
  }

  void _showResultDetail(BuildContext context, ExamResultEntity result) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(Spacings.lgRadius),
        ),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) {
          return _ResultDetailSheet(
            result: result,
            scrollController: scrollController,
          );
        },
      ),
    );
  }

  Future<void> _releaseResults() async {
    final confirmed = await AppDialog.showConfirm(
      context: context,
      title: 'Release Results?',
      message: 'This will make results visible to all students. This action cannot be undone.',
      confirmText: 'Release',
    );

    if (confirmed == true) {
      ref.read(examResultsProvider.notifier).releaseResults(widget.examId);
    }
  }
}

// ─── Result Detail Bottom Sheet ─────────────────────────────────────────

class _ResultDetailSheet extends StatelessWidget {
  const _ResultDetailSheet({
    required this.result,
    required this.scrollController,
  });

  final ExamResultEntity result;
  final ScrollController scrollController;

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;
    final tt = context.textTheme;

    return SingleChildScrollView(
      controller: scrollController,
      padding: const EdgeInsets.all(Spacings.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: cs.onSurfaceVariant.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: Spacings.xl),

          // Score card
          Center(
            child: Column(
              children: [
                Text(
                  '${result.scorePercentage.toStringAsFixed(1)}%',
                  style: tt.displayLarge?.copyWith(
                    fontWeight: AppTypography.wBold,
                    color: result.isPassed
                        ? AppColors.successOf(cs.brightness)
                        : AppColors.errorOf(cs.brightness),
                  ),
                ),
                const SizedBox(height: Spacings.sm),
                Text(
                  result.isPassed ? 'PASSED' : 'FAILED',
                  style: tt.titleMedium?.copyWith(
                    fontWeight: AppTypography.wBold,
                    color: result.isPassed
                        ? AppColors.successOf(cs.brightness)
                        : AppColors.errorOf(cs.brightness),
                    letterSpacing: AppTypography.lsLabel,
                  ),
                ),
                const SizedBox(height: Spacings.md),
                Text(
                  '${result.totalMarks.toStringAsFixed(1)} / ${result.totalPossible.toStringAsFixed(0)} marks',
                  style: tt.bodyLarge?.copyWith(color: cs.onSurfaceVariant),
                ),
                if (result.grade != null) ...[
                  const SizedBox(height: Spacings.sm),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: Spacings.lg,
                      vertical: Spacings.sm,
                    ),
                    decoration: BoxDecoration(
                      color: cs.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(Spacings.mdRadius),
                    ),
                    child: Text(
                      'Grade: ${result.grade}',
                      style: tt.titleLarge?.copyWith(
                        fontWeight: AppTypography.wBold,
                        color: cs.primary,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Sort Fields ────────────────────────────────────────────────────────

enum ResultsSortField {
  score('Score'),
  name('Name'),
  time('Time');

  const ResultsSortField(this.label);
  final String label;
}
