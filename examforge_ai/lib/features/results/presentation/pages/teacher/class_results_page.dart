import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/themes/app_colors.dart';
import '../../../../../core/themes/app_typography.dart';
import '../../../../../core/themes/spacings.dart';
import '../../../../../core/extensions/context_extensions.dart';
import '../../../../../core/utils/result.dart';
import '../../../../../shared/widgets/app_app_bar.dart';
import '../../../../../shared/widgets/app_button.dart';
import '../../../../../shared/widgets/app_card.dart';
import '../../../../../shared/widgets/app_dialog.dart';
import '../../../../../shared/widgets/app_empty_state.dart';
import '../../../../../shared/widgets/app_loading.dart';
import '../../domain/entities/results_entities.dart';
import '../../providers/results_providers.dart';
import '../../../../../features/results/domain/entities/results_entities.dart';


// ═══════════════════════════════════════════════════════════════════════
// CLASS RESULTS PAGE
// ═══════════════════════════════════════════════════════════════════════

/// Page showing class-wide results and analytics for teachers.
///
/// Displays class statistics, student rankings, subject comparison
/// chart placeholder, and result publication controls.
class ClassResultsPage extends ConsumerStatefulWidget {
  const ClassResultsPage({
    super.key,
    required this.classId,
    required this.academicSessionId,
  });

  final String classId;
  final String academicSessionId;

  @override
  ConsumerState<ClassResultsPage> createState() => _ClassResultsPageState();
}

class _ClassResultsPageState extends ConsumerState<ClassResultsPage> {
  String? _selectedSubjectId;
  bool _isPublished = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(resultsDashboardProvider.notifier).loadDashboard(
            schoolId: 'current_school', // TODO: inject from auth
            classId: widget.classId,
            academicSessionId: widget.academicSessionId,
          );
      ref.read(resultManagementProvider.notifier).loadLockStatus(
            examId: '', // TODO: pass examId if needed
          );
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;
    final tt = context.textTheme;
    final dashState = ref.watch(resultsDashboardProvider);
    final mgmtState = ref.watch(resultManagementProvider);
    final exportState = ref.watch(reportExportProvider);
    final performance = dashState.classPerformance;

    return Scaffold(
      appBar: AppAppBar(
        title: 'Class Results',
        actions: [
          // Publish / Withhold toggle
          _buildPublishToggle(context, mgmtState),
          const SizedBox(width: Spacings.sm),
          // Export button
          AppButton(
            label: 'Export',
            onPressed: exportState.isGenerating
                ? null
                : () => _exportReport(context),
            variant: AppButtonVariant.outlined,
            size: AppButtonSize.small,
            icon: Icons.download_rounded,
            isLoading: exportState.isGenerating,
          ),
          const SizedBox(width: Spacings.md),
        ],
      ),
      body: dashState.isLoading
          ? const Center(
              child: AppLoadingSpinner(size: AppLoadingSpinnerSize.large))
          : _buildBody(context, dashState, performance),
    );
  }

  // ─── Body ──────────────────────────────────────────────────────────

  Widget _buildBody(
    BuildContext context,
    ResultsDashboardState dashState,
    ClassPerformanceEntity? performance,
  ) {
    if (dashState.error != null && performance == null) {
      return _buildErrorState(context, dashState.error!);
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(Spacings.lg),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Error banner ─────────────────────────────────────
              if (dashState.error != null)
                _buildErrorBanner(context, dashState.error!),

              // ── Success banner ───────────────────────────────────
              if (dashState.successMessage != null)
                _buildSuccessBanner(context, dashState.successMessage!),

              // ── Class Statistics ─────────────────────────────────
              if (performance != null) ...[
                _buildStatisticsSection(context, performance),
                const SizedBox(height: Spacings.xl),
              ] else ...[
                AppEmptyState(
                  icon: Icons.bar_chart_rounded,
                  title: 'No Performance Data',
                  subtitle:
                      'Class performance data is not available for this session yet.',
                ),
                const SizedBox(height: Spacings.xl),
              ],

              // ── Subject Filter ───────────────────────────────────
              _buildSubjectFilter(context),
              const SizedBox(height: Spacings.lg),

              // ── Student Rankings Table ───────────────────────────
              _buildStudentRankings(context, performance),
              const SizedBox(height: Spacings.xl),

              // ── Subject Comparison Chart Placeholder ─────────────
              _buildSubjectComparisonChart(context, performance),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Publish Toggle ────────────────────────────────────────────────

  Widget _buildPublishToggle(
      BuildContext context, ResultManagementState mgmtState) {
    final cs = context.colorScheme;

    return FilledButton.tonalIcon(
      onPressed: mgmtState.isPublishing
          ? null
          : () => _togglePublishResults(context, mgmtState),
      icon: Icon(
        _isPublished ? Icons.visibility_off_rounded : Icons.visibility_rounded,
        size: Spacings.smIcon,
      ),
      label: Text(
        _isPublished ? 'Withhold' : 'Publish',
        style: AppTypography.buttonSmall,
      ),
      style: FilledButton.styleFrom(
        backgroundColor: _isPublished
            ? AppColors.warningOf(cs.brightness).withValues(alpha: 0.15)
            : cs.primaryContainer,
        foregroundColor: _isPublished
            ? AppColors.warningOf(cs.brightness)
            : cs.onPrimaryContainer,
        padding: const EdgeInsets.symmetric(
            horizontal: Spacings.lg, vertical: Spacings.sm),
        minimumSize: const Size(0, 36),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Spacings.mdRadius),
        ),
      ),
    );
  }

  // ─── Statistics Section ────────────────────────────────────────────

  Widget _buildStatisticsSection(
      BuildContext context, ClassPerformanceEntity perf) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossCount = constraints.maxWidth > 800 ? 4 : 2;
        return GridView.count(
          crossAxisCount: crossCount,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: Spacings.md,
          crossAxisSpacing: Spacings.md,
          childAspectRatio: 1.5,
          children: [
            AppStatCard(
              title: 'Average',
              value: '${perf.averageScore.toStringAsFixed(1)}%',
              icon: Icons.bar_chart_rounded,
            ),
            AppStatCard(
              title: 'Pass Rate',
              value: '${(perf.passRate * 100).toStringAsFixed(1)}%',
              icon: Icons.check_circle_rounded,
              color: perf.passRate >= 0.5
                  ? AppColors.successOf(context.colorScheme.brightness)
                  : AppColors.warningOf(context.colorScheme.brightness),
            ),
            AppStatCard(
              title: 'Highest',
              value: '${perf.highestScore.toStringAsFixed(1)}%',
              icon: Icons.arrow_upward_rounded,
              color: AppColors.successOf(context.colorScheme.brightness),
            ),
            AppStatCard(
              title: 'Lowest',
              value: '${perf.lowestScore.toStringAsFixed(1)}%',
              icon: Icons.arrow_downward_rounded,
              color: AppColors.errorOf(context.colorScheme.brightness),
            ),
          ],
        );
      },
    );
  }

  // ─── Subject Filter ────────────────────────────────────────────────

  Widget _buildSubjectFilter(BuildContext context) {
    final cs = context.colorScheme;
    final tt = context.textTheme;

    return Row(
      children: [
        Text(
          'Filter by Subject',
          style: tt.labelMedium?.copyWith(
            color: cs.onSurfaceVariant,
            fontWeight: AppTypography.wSemiBold,
          ),
        ),
        const SizedBox(width: Spacings.md),
        SizedBox(
          width: 220,
          child: DropdownButtonFormField<String>(
            value: _selectedSubjectId,
            decoration: InputDecoration(
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: Spacings.md,
                vertical: Spacings.sm,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(Spacings.smRadius),
              ),
              hintText: 'All Subjects',
            ),
            items: const [
              DropdownMenuItem(value: null, child: Text('All Subjects')),
              // TODO: Populate from actual subjects
              DropdownMenuItem(value: 'math', child: Text('Mathematics')),
              DropdownMenuItem(value: 'english', child: Text('English')),
              DropdownMenuItem(value: 'science', child: Text('Science')),
            ],
            onChanged: (value) {
              setState(() => _selectedSubjectId = value);
              ref.read(resultsDashboardProvider.notifier).loadClassPerformance(
                    classId: widget.classId,
                    academicSessionId: widget.academicSessionId,
                    subjectId: value,
                  );
            },
          ),
        ),
      ],
    );
  }

  // ─── Student Rankings Table ────────────────────────────────────────

  Widget _buildStudentRankings(
      BuildContext context, ClassPerformanceEntity? perf) {
    final cs = context.colorScheme;
    final tt = context.textTheme;

    // TODO: Replace with actual student ranking data from provider
    // For now, display placeholder data structure
    final students = <_StudentRank>[]; // Will be populated from state

    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(Spacings.md),
            child: Row(
              children: [
                Icon(Icons.leaderboard_rounded,
                    color: cs.primary, size: Spacings.mdIcon),
                const SizedBox(width: Spacings.sm),
                Text(
                  'Student Rankings',
                  style: tt.titleMedium?.copyWith(
                    fontWeight: AppTypography.wSemiBold,
                    color: cs.onSurface,
                  ),
                ),
                const Spacer(),
                if (perf != null)
                  Text(
                    '${perf.totalStudents} students',
                    style: tt.bodySmall?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
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
                _tableHeaderCell('#', flex: 1),
                _tableHeaderCell('Student', flex: 4),
                _tableHeaderCell('Score', flex: 2),
                _tableHeaderCell('Grade', flex: 1),
                _tableHeaderCell('Status', flex: 2),
              ],
            ),
          ),

          // Student rows (placeholder)
          if (students.isEmpty)
            Padding(
              padding: const EdgeInsets.all(Spacings.xxl),
              child: AppEmptyState(
                icon: Icons.people_outline_rounded,
                title: 'No Student Data',
                subtitle:
                    'Student rankings will appear here once results are computed.',
              ),
            )
          else
            ...students.map((s) => _buildStudentRow(context, s)),
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

  Widget _buildStudentRow(BuildContext context, _StudentRank student) {
    final cs = context.colorScheme;
    final tt = context.textTheme;

    return InkWell(
      onTap: () {
        // TODO: Navigate to student detail
      },
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
            Expanded(
              flex: 1,
              child: Text(
                '${student.position}',
                style: tt.bodySmall?.copyWith(
                  fontWeight: AppTypography.wSemiBold,
                  color: cs.onSurfaceVariant,
                ),
              ),
            ),
            Expanded(
              flex: 4,
              child: Text(
                student.name,
                style: tt.bodyMedium?.copyWith(
                  fontWeight: AppTypography.wSemiBold,
                  color: cs.onSurface,
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                '${student.score.toStringAsFixed(1)}%',
                style: tt.bodyMedium?.copyWith(
                  fontWeight: AppTypography.wBold,
                  color: student.isPassed
                      ? AppColors.successOf(cs.brightness)
                      : AppColors.errorOf(cs.brightness),
                ),
              ),
            ),
            Expanded(
              flex: 1,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: Spacings.sm,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: cs.primary.withValues(
                      alpha: context.isDarkMode ? 0.20 : 0.10),
                  borderRadius: BorderRadius.circular(Spacings.smRadius),
                ),
                child: Text(
                  student.grade,
                  style: tt.labelSmall?.copyWith(
                    fontWeight: AppTypography.wBold,
                    color: cs.primary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: _statusChip(context, student.isPassed),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statusChip(BuildContext context, bool isPassed) {
    final cs = context.colorScheme;
    final tt = context.textTheme;
    final isDark = context.isDarkMode;

    final color = isPassed
        ? AppColors.successOf(cs.brightness)
        : AppColors.errorOf(cs.brightness);

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
        isPassed ? 'Passed' : 'Failed',
        style: tt.labelSmall?.copyWith(
          fontWeight: AppTypography.wSemiBold,
          color: color,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  // ─── Subject Comparison Chart Placeholder ──────────────────────────

  Widget _buildSubjectComparisonChart(
      BuildContext context, ClassPerformanceEntity? perf) {
    final cs = context.colorScheme;
    final tt = context.textTheme;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.compare_rounded,
                  color: cs.primary, size: Spacings.mdIcon),
              const SizedBox(width: Spacings.sm),
              Text(
                'Subject Comparison',
                style: tt.titleMedium?.copyWith(
                  fontWeight: AppTypography.wSemiBold,
                  color: cs.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: Spacings.xl),
          // Chart placeholder
          Container(
            height: 200,
            width: double.infinity,
            decoration: BoxDecoration(
              color: cs.surfaceContainerHighest.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(Spacings.mdRadius),
              border: Border.all(
                color: cs.outlineVariant.withValues(alpha: 0.5),
                strokeAlign: BorderSide.strokeAlignOutside,
              ),
            ),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.bar_chart_rounded,
                      size: Spacings.xlIcon,
                      color: cs.onSurfaceVariant.withValues(alpha: 0.5)),
                  const SizedBox(height: Spacings.sm),
                  Text(
                    'Subject comparison chart will render here',
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

  // ─── Error State ───────────────────────────────────────────────────

  Widget _buildErrorState(BuildContext context, String error) {
    return Center(
      child: AppEmptyState(
        icon: Icons.error_outline_rounded,
        title: 'Failed to Load Results',
        subtitle: error,
        actionLabel: 'Retry',
        onAction: () {
          ref.read(resultsDashboardProvider.notifier).loadDashboard(
                schoolId: 'current_school',
                classId: widget.classId,
                academicSessionId: widget.academicSessionId,
              );
        },
      ),
    );
  }

  // ─── Error Banner ──────────────────────────────────────────────────

  Widget _buildErrorBanner(BuildContext context, String error) {
    final cs = context.colorScheme;
    final tt = context.textTheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: Spacings.md),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(Spacings.md),
        decoration: BoxDecoration(
          color: AppColors.errorOf(cs.brightness)
              .withValues(alpha: context.isDarkMode ? 0.15 : 0.08),
          borderRadius: BorderRadius.circular(Spacings.smRadius),
        ),
        child: Row(
          children: [
            Icon(Icons.error_outline_rounded,
                color: AppColors.errorOf(cs.brightness)),
            const SizedBox(width: Spacings.sm),
            Expanded(
              child: Text(
                error,
                style: tt.bodySmall?.copyWith(
                  color: AppColors.errorOf(cs.brightness),
                ),
              ),
            ),
            AppButton(
              label: 'Retry',
              onPressed: () {
                ref.read(resultsDashboardProvider.notifier).loadDashboard(
                      schoolId: 'current_school',
                      classId: widget.classId,
                      academicSessionId: widget.academicSessionId,
                    );
              },
              variant: AppButtonVariant.text,
              size: AppButtonSize.small,
            ),
          ],
        ),
      ),
    );
  }

  // ─── Success Banner ────────────────────────────────────────────────

  Widget _buildSuccessBanner(BuildContext context, String message) {
    final cs = context.colorScheme;
    final tt = context.textTheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: Spacings.md),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(Spacings.md),
        decoration: BoxDecoration(
          color: AppColors.successOf(cs.brightness)
              .withValues(alpha: context.isDarkMode ? 0.15 : 0.08),
          borderRadius: BorderRadius.circular(Spacings.smRadius),
        ),
        child: Row(
          children: [
            Icon(Icons.check_circle_rounded,
                color: AppColors.successOf(cs.brightness)),
            const SizedBox(width: Spacings.sm),
            Expanded(
              child: Text(
                message,
                style: tt.bodyMedium?.copyWith(
                  color: AppColors.successOf(cs.brightness),
                  fontWeight: AppTypography.wSemiBold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Actions ───────────────────────────────────────────────────────

  Future<void> _togglePublishResults(
      BuildContext context, ResultManagementState mgmtState) async {
    if (_isPublished) {
      // Withhold
      final confirmed = await AppDialog.showConfirm(
        context: context,
        title: 'Withhold Results?',
        message:
            'This will hide results from all students. Students will no longer be able to view their scores.',
        confirmText: 'Withhold',
        isDestructive: true,
      );

      if (confirmed == true) {
        ref.read(resultManagementProvider.notifier).withholdResults(
              widget.classId,
              withholdRemote: (_) async => Success(null),
            );
        setState(() => _isPublished = false);
      }
    } else {
      // Publish
      final confirmed = await AppDialog.showConfirm(
        context: context,
        title: 'Publish Results?',
        message:
            'This will make results visible to all students. This action cannot be undone.',
        confirmText: 'Publish',
      );

      if (confirmed == true) {
        ref.read(resultManagementProvider.notifier).publishResults(
              widget.classId,
            );
        setState(() => _isPublished = true);
      }
    }
  }

  Future<void> _exportReport(BuildContext context) async {
    await ref.read(reportExportProvider.notifier).createReport(
          schoolId: 'current_school', // TODO: inject from auth
          requestedBy: 'current_teacher', // TODO: inject from auth
          reportType: ReportType.classReport,
          reportFormat: ReportFormat.pdf,
          title: 'Class Report - ${widget.classId}',
          parameters: {
            'classId': widget.classId,
            'academicSessionId': widget.academicSessionId,
            if (_selectedSubjectId != null)
              'subjectId': _selectedSubjectId,
          },
        );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// HELPER CLASS
// ═══════════════════════════════════════════════════════════════════════

/// Temporary model for student ranking display.
/// Will be replaced by actual data from state.
class _StudentRank {
  const _StudentRank({
    required this.position,
    required this.name,
    required this.score,
    required this.grade,
    required this.isPassed,
  });

  final int position;
  final String name;
  final double score;
  final String grade;
  final bool isPassed;
}
