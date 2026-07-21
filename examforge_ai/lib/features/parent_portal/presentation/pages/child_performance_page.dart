import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/themes/app_colors.dart';
import '../../../../core/themes/app_typography.dart';
import '../../../../core/themes/spacings.dart';
import '../../../../routing/route_names.dart';
import '../../../../shared/widgets/app_app_bar.dart';
import '../../../../shared/widgets/app_empty_state.dart';
import '../../../../shared/widgets/app_error_state.dart';
import '../../../../shared/widgets/app_loading.dart';
import '../../domain/entities/parent_portal_entities.dart';
import '../providers/child_performance_provider.dart';

// ═══════════════════════════════════════════════════════════════════════
// CHILD PERFORMANCE PAGE
// ═══════════════════════════════════════════════════════════════════════

/// Academic performance page for a specific child in the Parent Portal.
///
/// Displays comprehensive academic information including:
/// - Overall performance card with average score and attendance rate
/// - Subject performance list with colour-coded scores
/// - Performance chart placeholder
/// - Teacher remarks section
/// - Download report card button with format options
///
/// Receives [studentId] as a route parameter and loads performance
/// data using [childPerformanceProvider].
class ChildPerformancePage extends ConsumerStatefulWidget {
  const ChildPerformancePage({
    super.key,
    required this.studentId,
  });

  /// Unique identifier of the student whose performance is displayed.
  final String studentId;

  @override
  ConsumerState<ChildPerformancePage> createState() => _State();
}

class _State extends ConsumerState<ChildPerformancePage> {
  // ─── Lifecycle ──────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(childPerformanceProvider.notifier)
          .loadPerformance(widget.studentId);
    });
  }

  // ─── Build ──────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final performanceState = ref.watch(childPerformanceProvider);

    return Scaffold(
      appBar: const AppAppBar(title: 'Academic Performance'),
      body: _buildBody(context, performanceState),
    );
  }

  // ─── Body Router ────────────────────────────────────────────────────

  Widget _buildBody(BuildContext context, ChildPerformanceState state) {
    // Loading state
    if (state.isLoading && state.performance == null) {
      return _buildShimmerLoading(context);
    }

    // Error state
    if (state.error != null && state.performance == null) {
      return AppErrorState.genericError(
        message: state.error,
        onRetry: () => ref
            .read(childPerformanceProvider.notifier)
            .loadPerformance(widget.studentId),
      );
    }

    // Empty state
    final performance = state.performance;
    if (performance == null) {
      return AppEmptyState.noData(
        title: 'No Performance Data',
        subtitle:
            'Academic performance data will appear here once available.',
        actionLabel: 'Retry',
        onAction: () => ref
            .read(childPerformanceProvider.notifier)
            .loadPerformance(widget.studentId),
      );
    }

    // Success — render performance
    return RefreshIndicator(
      onRefresh: () => ref
          .read(childPerformanceProvider.notifier)
          .refreshPerformance(widget.studentId),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(bottom: Spacings.xxl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ─── Overall Performance Card ───────────────────────────
            _buildOverallPerformanceCard(context, performance),

            const SizedBox(height: Spacings.xl),

            // ─── Subject Performance List ───────────────────────────
            _buildSubjectPerformanceList(context, performance),

            const SizedBox(height: Spacings.xl),

            // ─── Performance Chart Placeholder ──────────────────────
            _buildChartPlaceholder(context),

            const SizedBox(height: Spacings.xl),

            // ─── Teacher Remarks Section ────────────────────────────
            _buildTeacherRemarksSection(context, performance),

            const SizedBox(height: Spacings.xl),

            // ─── Download Report Card Button ────────────────────────
            _buildDownloadReportButton(context),

            const SizedBox(height: Spacings.lg),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // SHIMMER LOADING
  // ═══════════════════════════════════════════════════════════════════════

  Widget _buildShimmerLoading(BuildContext context) {
    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      child: AppLoadingShimmer(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(Spacings.lg),
              child: Column(
                children: [
                  // Overall card shimmer
                  AppLoadingShimmer.box(
                    height: 180,
                    borderRadius: Spacings.borderRadiusLg,
                  ),
                  const SizedBox(height: Spacings.xl),
                  // Subject items shimmer
                  ...List.generate(
                    4,
                    (_) => Padding(
                      padding: const EdgeInsets.only(bottom: Spacings.md),
                      child: AppLoadingShimmer.box(
                        height: 72,
                        borderRadius: Spacings.borderRadiusMd,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // OVERALL PERFORMANCE CARD
  // ═══════════════════════════════════════════════════════════════════════

  Widget _buildOverallPerformanceCard(
    BuildContext context,
    ChildPerformanceEntity performance,
  ) {
    final cs = context.colorScheme;
    final tt = context.textTheme;
    final overallAvg = performance.overallAverage ?? 0.0;
    final classAvg = performance.classAverage ?? 0.0;
    final attendanceRate = performance.attendanceRate ?? 0.0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Spacings.lg),
      child: Card(
        elevation: Spacings.elevationSm,
        shape: RoundedRectangleBorder(
          borderRadius: Spacings.borderRadiusLg,
        ),
        child: Padding(
          padding: const EdgeInsets.all(Spacings.xl),
          child: Column(
            children: [
              Text(
                'Overall Performance',
                style: tt.titleMedium?.copyWith(
                  fontWeight: AppTypography.wSemiBold,
                  color: cs.onSurface,
                ),
              ),
              const SizedBox(height: Spacings.lg),
              // Circular progress + average score
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Average score
                  Column(
                    children: [
                      SizedBox(
                        width: 100,
                        height: 100,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            CircularProgressIndicator(
                              value: overallAvg / 100,
                              strokeWidth: 8,
                              backgroundColor:
                                  cs.surfaceContainerHighest,
                              color: _scoreColor(overallAvg, cs.brightness),
                            ),
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  overallAvg.toStringAsFixed(1),
                                  style: tt.headlineSmall?.copyWith(
                                    fontWeight: AppTypography.wBold,
                                    color: cs.onSurface,
                                  ),
                                ),
                                Text(
                                  'Average',
                                  style: tt.labelSmall?.copyWith(
                                    color: cs.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  // Class average & attendance
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildStatItem(
                        context,
                        label: 'Class Average',
                        value: classAvg.toStringAsFixed(1),
                        icon: Icons.groups_outlined,
                        color: AppColors.infoOf(cs.brightness),
                      ),
                      const SizedBox(height: Spacings.md),
                      _buildStatItem(
                        context,
                        label: 'Attendance',
                        value:
                            '${(attendanceRate * 100).toStringAsFixed(1)}%',
                        icon: Icons.check_circle_outline,
                        color: AppColors.successOf(cs.brightness),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(
    BuildContext context, {
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    final tt = context.textTheme;
    return Row(
      children: [
        Icon(icon, size: Spacings.mdIcon, color: color),
        const SizedBox(width: Spacings.sm),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: tt.labelSmall?.copyWith(
                color: context.colorScheme.onSurfaceVariant,
              ),
            ),
            Text(
              value,
              style: tt.titleSmall?.copyWith(
                fontWeight: AppTypography.wSemiBold,
                color: context.colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // SUBJECT PERFORMANCE LIST
  // ═══════════════════════════════════════════════════════════════════════

  Widget _buildSubjectPerformanceList(
    BuildContext context,
    ChildPerformanceEntity performance,
  ) {
    final cs = context.colorScheme;
    final tt = context.textTheme;
    final subjects = performance.subjects;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Spacings.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Subject Performance',
            style: tt.titleMedium?.copyWith(
              fontWeight: AppTypography.wSemiBold,
              color: cs.onSurface,
            ),
          ),
          const SizedBox(height: Spacings.sm),
          if (subjects.isEmpty)
            Card(
              elevation: Spacings.elevationNone,
              color: cs.surfaceContainerLow,
              shape: RoundedRectangleBorder(
                borderRadius: Spacings.borderRadiusMd,
              ),
              child: Padding(
                padding: const EdgeInsets.all(Spacings.xl),
                child: Center(
                  child: Text(
                    'No subject data available',
                    style: tt.bodyMedium?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
            )
          else
            ...subjects.map((subject) => Padding(
                  padding: const EdgeInsets.only(bottom: Spacings.sm),
                  child: _buildSubjectCard(context, subject),
                )),
        ],
      ),
    );
  }

  Widget _buildSubjectCard(
    BuildContext context,
    SubjectPerformanceEntity subject,
  ) {
    final cs = context.colorScheme;
    final tt = context.textTheme;
    final avgScore = subject.averageScore ?? 0.0;
    final latestScore = subject.latestScore;
    final scoreColor = _scoreColor(avgScore, cs.brightness);
    final scoreBg = _scoreBackgroundColor(avgScore, cs.brightness);

    return Card(
      elevation: Spacings.elevationNone,
      color: cs.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: Spacings.borderRadiusMd,
      ),
      child: Padding(
        padding: Spacings.paddingCard,
        child: Row(
          children: [
            // Score badge
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: scoreBg,
                borderRadius: Spacings.borderRadiusMd,
              ),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      avgScore.toStringAsFixed(0),
                      style: tt.titleMedium?.copyWith(
                        fontWeight: AppTypography.wBold,
                        color: scoreColor,
                      ),
                    ),
                    if (subject.grade != null)
                      Text(
                        subject.grade!,
                        style: tt.labelSmall?.copyWith(
                          color: scoreColor,
                          fontWeight: AppTypography.wSemiBold,
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: Spacings.md),
            // Subject details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    subject.subjectName,
                    style: tt.titleSmall?.copyWith(
                      fontWeight: AppTypography.wSemiBold,
                      color: cs.onSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (subject.teacherName != null) ...[
                    const SizedBox(height: Spacings.xs),
                    Text(
                      subject.teacherName!,
                      style: tt.bodySmall?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  if (latestScore != null) ...[
                    const SizedBox(height: Spacings.xs),
                    Text(
                      'Latest: ${latestScore.toStringAsFixed(1)}',
                      style: tt.labelSmall?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            // Average label
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'Avg',
                  style: tt.labelSmall?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
                ),
                Text(
                  avgScore.toStringAsFixed(1),
                  style: tt.titleSmall?.copyWith(
                    fontWeight: AppTypography.wBold,
                    color: scoreColor,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // PERFORMANCE CHART PLACEHOLDER
  // ═══════════════════════════════════════════════════════════════════════

  Widget _buildChartPlaceholder(BuildContext context) {
    final cs = context.colorScheme;
    final tt = context.textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Spacings.lg),
      child: Card(
        elevation: Spacings.elevationNone,
        color: cs.surfaceContainerLow,
        shape: RoundedRectangleBorder(
          borderRadius: Spacings.borderRadiusMd,
        ),
        child: Padding(
          padding: const EdgeInsets.all(Spacings.xl),
          child: Column(
            children: [
              Icon(
                Icons.show_chart_outlined,
                size: Spacings.xlIcon,
                color: cs.onSurfaceVariant.withOpacity(0.4),
              ),
              const SizedBox(height: Spacings.md),
              Text(
                'Performance trend chart will be available after more assessments',
                style: tt.bodyMedium?.copyWith(
                  color: cs.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // TEACHER REMARKS SECTION
  // ═══════════════════════════════════════════════════════════════════════

  Widget _buildTeacherRemarksSection(
    BuildContext context,
    ChildPerformanceEntity performance,
  ) {
    final cs = context.colorScheme;
    final tt = context.textTheme;
    final remarks = performance.teacherRemarks;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Spacings.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Teacher Remarks',
            style: tt.titleMedium?.copyWith(
              fontWeight: AppTypography.wSemiBold,
              color: cs.onSurface,
            ),
          ),
          const SizedBox(height: Spacings.sm),
          if (remarks.isEmpty)
            Card(
              elevation: Spacings.elevationNone,
              color: cs.surfaceContainerLow,
              shape: RoundedRectangleBorder(
                borderRadius: Spacings.borderRadiusMd,
              ),
              child: Padding(
                padding: const EdgeInsets.all(Spacings.xl),
                child: Center(
                  child: Text(
                    'No remarks yet',
                    style: tt.bodyMedium?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
            )
          else
            ...remarks.map((remark) => Padding(
                  padding: const EdgeInsets.only(bottom: Spacings.sm),
                  child: _buildRemarkCard(context, remark),
                )),
        ],
      ),
    );
  }

  Widget _buildRemarkCard(
    BuildContext context,
    TeacherRemarkEntity remark,
  ) {
    final cs = context.colorScheme;
    final tt = context.textTheme;

    return Card(
      elevation: Spacings.elevationNone,
      color: cs.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: Spacings.borderRadiusMd,
      ),
      child: Padding(
        padding: Spacings.paddingCard,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.person_outline,
                  size: Spacings.smIcon,
                  color: cs.primary,
                ),
                const SizedBox(width: Spacings.xs),
                Expanded(
                  child: Text(
                    remark.teacherName,
                    style: tt.titleSmall?.copyWith(
                      fontWeight: AppTypography.wSemiBold,
                      color: cs.onSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                // Subject badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: Spacings.sm,
                    vertical: Spacings.xs,
                  ),
                  decoration: BoxDecoration(
                    color: cs.secondaryContainer,
                    borderRadius: Spacings.borderRadiusSm,
                  ),
                  child: Text(
                    remark.subject,
                    style: tt.labelSmall?.copyWith(
                      color: cs.onSecondaryContainer,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: Spacings.sm),
            Text(
              remark.remark,
              style: tt.bodyMedium?.copyWith(
                color: cs.onSurface,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: Spacings.sm),
            Text(
              _formatDate(remark.date),
              style: tt.labelSmall?.copyWith(
                color: cs.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // DOWNLOAD REPORT CARD BUTTON
  // ═══════════════════════════════════════════════════════════════════════

  Widget _buildDownloadReportButton(BuildContext context) {
    final cs = context.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Spacings.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FilledButton.icon(
            onPressed: () => _showDownloadFormatDialog(context),
            icon: const Icon(Icons.download_outlined),
            label: const Text('Download Report Card'),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(
                vertical: Spacings.md,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: Spacings.borderRadiusMd,
              ),
            ),
          ),
          const SizedBox(height: Spacings.sm),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildFormatChip(context, 'PDF', Icons.picture_as_pdf_outlined),
              const SizedBox(width: Spacings.sm),
              _buildFormatChip(context, 'Excel', Icons.table_chart_outlined),
              const SizedBox(width: Spacings.sm),
              _buildFormatChip(
                  context, 'Printable', Icons.print_outlined),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFormatChip(
    BuildContext context,
    String label,
    IconData icon,
  ) {
    final cs = context.colorScheme;
    final tt = context.textTheme;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Spacings.sm,
        vertical: Spacings.xs,
      ),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: Spacings.borderRadiusSm,
        border: Border.all(
          color: cs.outline.withOpacity(0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: cs.onSurfaceVariant),
          const SizedBox(width: Spacings.xs),
          Text(
            label,
            style: tt.labelSmall?.copyWith(
              color: cs.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // DIALOGS
  // ═══════════════════════════════════════════════════════════════════════

  /// Shows a dialog for selecting the report download format.
  void _showDownloadFormatDialog(BuildContext context) {
    final cs = context.colorScheme;
    final tt = context.textTheme;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(Spacings.lgRadius),
        ),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(Spacings.xl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Download Report Card',
                  style: tt.titleMedium?.copyWith(
                    fontWeight: AppTypography.wSemiBold,
                    color: cs.onSurface,
                  ),
                ),
                const SizedBox(height: Spacings.md),
                ListTile(
                  leading: const Icon(Icons.picture_as_pdf_outlined),
                  title: const Text('PDF Format'),
                  subtitle: const Text('Best for printing and sharing'),
                  onTap: () {
                    Navigator.pop(context);
                    // TODO: Trigger PDF download
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.table_chart_outlined),
                  title: const Text('Excel Format'),
                  subtitle: const Text('Best for data analysis'),
                  onTap: () {
                    Navigator.pop(context);
                    // TODO: Trigger Excel download
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.print_outlined),
                  title: const Text('Printable View'),
                  subtitle: const Text('Optimised for direct printing'),
                  onTap: () {
                    Navigator.pop(context);
                    // TODO: Trigger printable view
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // HELPER METHODS
  // ═══════════════════════════════════════════════════════════════════════

  /// Returns a colour based on the score percentage.
  ///
  /// Green for >70%, amber for 50–70%, red for <50%.
  Color _scoreColor(double score, Brightness brightness) {
    if (score > 70) return AppColors.successOf(brightness);
    if (score >= 50) return AppColors.warningOf(brightness);
    return AppColors.errorOf(brightness);
  }

  /// Returns a background colour based on the score percentage.
  Color _scoreBackgroundColor(double score, Brightness brightness) {
    if (score > 70) return AppColors.successLight;
    if (score >= 50) return AppColors.warningLight;
    return AppColors.errorLight;
  }

  /// Formats a [DateTime] as a short date string.
  String _formatDate(DateTime dt) {
    const months = [
      '',
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[dt.month]} ${dt.day}, ${dt.year}';
  }
}
