import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/extensions/context_extensions.dart';
import '../../../../../core/themes/app_colors.dart';
import '../../../../../core/themes/app_typography.dart';
import '../../../../../core/themes/spacings.dart';
import '../../../../../shared/widgets/app_app_bar.dart';
import '../../../../../shared/widgets/app_card.dart';
import '../../../../../shared/widgets/app_empty_state.dart';
import '../../../../../shared/widgets/app_loading.dart';
import '../../../domain/entities/results_entities.dart';
import '../../providers/results_page_providers.dart';
import '../../providers/results_providers.dart';


// ═══════════════════════════════════════════════════════════════════════
// SCHOOL ANALYTICS PAGE
// ═══════════════════════════════════════════════════════════════════════

/// School-wide analytics dashboard for administrators.
///
/// Displays configurable widget cards showing KPIs, pass rates,
/// score distributions, subject comparisons, top performers,
/// difficult topics, historical trends, class rankings, and exam
/// participation.
class SchoolAnalyticsPage extends ConsumerStatefulWidget {
  const SchoolAnalyticsPage({
    super.key,
    required this.schoolId,
    required this.academicSessionId,
  });

  final String schoolId;
  final String academicSessionId;

  @override
  ConsumerState<SchoolAnalyticsPage> createState() =>
      _SchoolAnalyticsPageState();
}

class _SchoolAnalyticsPageState extends ConsumerState<SchoolAnalyticsPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadAnalytics();
    });
  }

  void _loadAnalytics() {
    ref.read(analyticsProvider.notifier).loadSchoolPerformance(
          schoolId: widget.schoolId,
          academicSessionId: widget.academicSessionId,
        );
    ref.read(analyticsProvider.notifier).loadDashboard(
          schoolId: widget.schoolId,
          role: 'admin',
          academicSessionId: widget.academicSessionId,
          snapshotType: 'school_summary',
        );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(analyticsProvider);

    return Scaffold(
      appBar: AppAppBar(
        title: 'School Analytics',
        actions: [
          IconButton(
            icon: const Icon(Icons.dashboard_customize_outlined),
            tooltip: 'Customize Dashboard',
            onPressed: () => _showCustomizeDialog(context, state),
          ),
        ],
      ),
      body: state.isLoading
          ? const Center(
              child: AppLoadingSpinner(size: AppLoadingSpinnerSize.large),)
          : state.error != null
              ? Center(
                  child: AppEmptyState(
                    icon: Icons.error_outline_rounded,
                    title: 'Something went wrong',
                    subtitle: state.error,
                    actionLabel: 'Retry',
                    onAction: _loadAnalytics,
                  ),
                )
              : _buildContent(context, state),
    );
  }

  // ─── Main Content ────────────────────────────────────────────────────

  Widget _buildContent(BuildContext context, AnalyticsState state) {
    final schoolPerf = state.schoolPerformance;
    final config = state.dashboardConfig;

    if (schoolPerf == null && config == null) {
      return Center(
        child: AppEmptyState(
          icon: Icons.analytics_outlined,
          title: 'No Analytics Data',
          subtitle: 'Analytics data will appear once results are available.',
          actionLabel: 'Refresh',
          onAction: _loadAnalytics,
        ),
      );
    }

    final visibleWidgets = config?.widgets.where((w) => w.isVisible).toList() ??
        _defaultWidgetConfigs();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(Spacings.lg),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Top KPI Row ──────────────────────────────────────
              _buildKpiRow(context, schoolPerf),
              const SizedBox(height: Spacings.xl),

              // ── Dashboard Widget Grid ────────────────────────────
              _buildWidgetGrid(context, visibleWidgets, schoolPerf),
            ],
          ),
        ),
      ),
    );
  }

  // ─── KPI Row ─────────────────────────────────────────────────────────

  Widget _buildKpiRow(
      BuildContext context, SchoolPerformanceEntity? schoolPerf,) {
    final totalStudents = schoolPerf?.totalStudents ?? 0;
    final avgScore = schoolPerf?.averageScore ?? 0;
    final passRate = schoolPerf?.passRate ?? 0;
    final distinctionRate = schoolPerf?.distinctionRate ?? 0;

    return LayoutBuilder(builder: (context, constraints) {
      final isNarrow = constraints.maxWidth < 600;
      if (isNarrow) {
        return Column(
          children: [
            Row(children: [
              Expanded(
                  child: _buildKpiCard(context, 'Total Students',
                      '$totalStudents', Icons.people_rounded, null,),),
              const SizedBox(width: Spacings.sm),
              Expanded(
                  child: _buildKpiCard(context, 'Average Score',
                      '${avgScore.toStringAsFixed(1)}%', Icons.score_rounded, null,),),
            ],),
            const SizedBox(height: Spacings.sm),
            Row(children: [
              Expanded(
                  child: _buildKpiCard(
                      context,
                      'Pass Rate',
                      '${passRate.toStringAsFixed(1)}%',
                      Icons.check_circle_outline_rounded,
                      AppColors.successOf(context.colorScheme.brightness),),),
              const SizedBox(width: Spacings.sm),
              Expanded(
                  child: _buildKpiCard(
                      context,
                      'Distinction Rate',
                      '${distinctionRate.toStringAsFixed(1)}%',
                      Icons.emoji_events_outlined,
                      const Color(0xFFF59E0B),),),
            ],),
          ],
        );
      }

      return Row(
        children: [
          Expanded(
              child: _buildKpiCard(context, 'Total Students',
                  '$totalStudents', Icons.people_rounded, null,),),
          const SizedBox(width: Spacings.sm),
          Expanded(
              child: _buildKpiCard(context, 'Average Score',
                  '${avgScore.toStringAsFixed(1)}%', Icons.score_rounded, null,),),
          const SizedBox(width: Spacings.sm),
          Expanded(
              child: _buildKpiCard(
                  context,
                  'Pass Rate',
                  '${passRate.toStringAsFixed(1)}%',
                  Icons.check_circle_outline_rounded,
                  AppColors.successOf(context.colorScheme.brightness),),),
          const SizedBox(width: Spacings.sm),
          Expanded(
              child: _buildKpiCard(
                  context,
                  'Distinction Rate',
                  '${distinctionRate.toStringAsFixed(1)}%',
                  Icons.emoji_events_outlined,
                  const Color(0xFFF59E0B),),),
        ],
      );
    },);
  }

  Widget _buildKpiCard(
    BuildContext context,
    String title,
    String value,
    IconData icon,
    Color? accentColor,
  ) {
    final cs = context.colorScheme;
    final tt = context.textTheme;
    final isDark = context.isDarkMode;
    final color = accentColor ?? cs.primary;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(Spacings.sm),
            decoration: BoxDecoration(
              color: color.withValues(alpha: isDark ? 0.20 : 0.12),
              borderRadius: BorderRadius.circular(Spacings.smRadius),
            ),
            child: Icon(icon, size: Spacings.mdIcon, color: color),
          ),
          const SizedBox(height: Spacings.md),
          Text(
            value,
            style: tt.headlineSmall?.copyWith(
              fontWeight: AppTypography.wBold,
              color: cs.onSurface,
            ),
          ),
          const SizedBox(height: Spacings.xs),
          Text(
            title,
            style: tt.bodySmall?.copyWith(
              color: cs.onSurfaceVariant,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  // ─── Dashboard Widget Grid ───────────────────────────────────────────

  Widget _buildWidgetGrid(
    BuildContext context,
    List<DashboardWidgetConfigEntity> widgets,
    SchoolPerformanceEntity? schoolPerf,
  ) {
    return LayoutBuilder(builder: (context, constraints) {
      final isDesktop = constraints.maxWidth >= 900;
      final isTablet = constraints.maxWidth >= 600 && !isDesktop;

      return Wrap(
        spacing: Spacings.md,
        runSpacing: Spacings.md,
        children: widgets.map((widgetConfig) {
          final width = isDesktop
              ? (constraints.maxWidth - Spacings.md * 2) / 3
              : isTablet
                  ? (constraints.maxWidth - Spacings.md) / 2
                  : constraints.maxWidth;

          return SizedBox(
            width: width,
            child: _buildWidgetCard(context, widgetConfig, schoolPerf),
          );
        }).toList(),
      );
    },);
  }

  Widget _buildWidgetCard(
    BuildContext context,
    DashboardWidgetConfigEntity widgetConfig,
    SchoolPerformanceEntity? schoolPerf,
  ) {
    return switch (widgetConfig.widgetType) {
      DashboardWidgetType.passRate => _buildPassRateWidget(context, schoolPerf),
      DashboardWidgetType.scoreDistribution =>
        _buildScoreDistributionWidget(context),
      DashboardWidgetType.subjectComparison =>
        _buildSubjectComparisonWidget(context, schoolPerf),
      DashboardWidgetType.topPerformers =>
        _buildTopPerformersWidget(context, schoolPerf),
      DashboardWidgetType.difficultTopics =>
        _buildDifficultTopicsWidget(context, schoolPerf),
      DashboardWidgetType.historicalTrend =>
        _buildHistoricalTrendWidget(context),
      DashboardWidgetType.classRanking =>
        _buildClassRankingWidget(context, schoolPerf),
      DashboardWidgetType.examParticipation =>
        _buildExamParticipationWidget(context, schoolPerf),
      _ => _buildPlaceholderWidget(context, widgetConfig),
    };
  }

  // ─── Pass Rate Widget ────────────────────────────────────────────────

  Widget _buildPassRateWidget(
      BuildContext context, SchoolPerformanceEntity? schoolPerf,) {
    final cs = context.colorScheme;
    final tt = context.textTheme;
    final isDark = context.isDarkMode;
    final passRate = schoolPerf?.passRate ?? 0;
    final passColor = AppColors.successOf(cs.brightness);

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Pass Rate',
            style: tt.titleSmall?.copyWith(
              fontWeight: AppTypography.wSemiBold,
              color: cs.onSurface,
            ),
          ),
          const SizedBox(height: Spacings.lg),
          Center(
            child: SizedBox(
              width: 120,
              height: 120,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CircularProgressIndicator(
                    value: passRate / 100,
                    strokeWidth: 8,
                    backgroundColor: cs.surfaceContainerHighest,
                    color: passColor,
                  ),
                  Center(
                    child: Text(
                      '${passRate.toStringAsFixed(1)}%',
                      style: tt.headlineSmall?.copyWith(
                        fontWeight: AppTypography.wBold,
                        color: passColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: Spacings.md),
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: Spacings.md,
                vertical: Spacings.xs,
              ),
              decoration: BoxDecoration(
                color: passColor.withValues(alpha: isDark ? 0.15 : 0.08),
                borderRadius: BorderRadius.circular(Spacings.smRadius),
              ),
              child: Text(
                passRate >= 70 ? 'Above Target' : 'Below Target',
                style: tt.labelMedium?.copyWith(
                  fontWeight: AppTypography.wSemiBold,
                  color: passColor,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Score Distribution Widget ───────────────────────────────────────

  Widget _buildScoreDistributionWidget(BuildContext context) {
    final cs = context.colorScheme;
    final tt = context.textTheme;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Score Distribution',
            style: tt.titleSmall?.copyWith(
              fontWeight: AppTypography.wSemiBold,
              color: cs.onSurface,
            ),
          ),
          const SizedBox(height: Spacings.lg),
          // Bar chart placeholder
          Container(
            width: double.infinity,
            height: 160,
            decoration: BoxDecoration(
              color: cs.surfaceContainerHighest.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(Spacings.mdRadius),
              border: Border.all(
                color: cs.outlineVariant.withValues(alpha: 0.5),
              ),
            ),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.bar_chart_rounded,
                      size: Spacings.xlIcon,
                      color: cs.onSurfaceVariant.withValues(alpha: 0.4),),
                  const SizedBox(height: Spacings.sm),
                  Text(
                    'Score distribution chart',
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

  // ─── Subject Comparison Widget ───────────────────────────────────────

  Widget _buildSubjectComparisonWidget(
      BuildContext context, SchoolPerformanceEntity? schoolPerf,) {
    final cs = context.colorScheme;
    final tt = context.textTheme;
    final isDark = context.isDarkMode;

    // Extract subject rankings from school performance data
    final subjectRankings = schoolPerf?.subjectRankings ?? [];
    // Each ranking entry is expected to be a Map with 'name' and 'score'
    final displayItems = subjectRankings.take(6).toList();

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Subject Comparison',
            style: tt.titleSmall?.copyWith(
              fontWeight: AppTypography.wSemiBold,
              color: cs.onSurface,
            ),
          ),
          const SizedBox(height: Spacings.md),
          if (displayItems.isEmpty)
            Padding(
              padding: const EdgeInsets.all(Spacings.lg),
              child: Center(
                child: Text(
                  'No subject comparison data available',
                  style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                ),
              ),
            )
          else
            ...displayItems.map((item) {
              final name = (item is Map<String, dynamic>)
                  ? item['name'] as String? ?? 'Subject'
                  : item.toString();
              final score = (item is Map<String, dynamic>)
                  ? (item['score'] as num?)?.toDouble() ?? 0
                  : 0.0;
              return Padding(
                padding: const EdgeInsets.only(bottom: Spacings.sm),
                child: Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: Text(
                        name,
                        style: tt.bodySmall?.copyWith(
                          color: cs.onSurface,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: Spacings.sm),
                    Expanded(
                      flex: 3,
                      child: ClipRRect(
                        borderRadius:
                            BorderRadius.circular(Spacings.smRadius),
                        child: LinearProgressIndicator(
                          value: score / 100,
                          minHeight: 8,
                          backgroundColor: cs.surfaceContainerHighest,
                          color: cs.primary,
                          borderRadius:
                              BorderRadius.circular(Spacings.smRadius),
                        ),
                      ),
                    ),
                    const SizedBox(width: Spacings.sm),
                    SizedBox(
                      width: 40,
                      child: Text(
                        '${score.toStringAsFixed(0)}%',
                        style: tt.labelSmall?.copyWith(
                          fontWeight: AppTypography.wSemiBold,
                          color: cs.onSurface,
                        ),
                        textAlign: TextAlign.end,
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  // ─── Top Performers Widget ───────────────────────────────────────────

  Widget _buildTopPerformersWidget(
      BuildContext context, SchoolPerformanceEntity? schoolPerf,) {
    final cs = context.colorScheme;
    final tt = context.textTheme;

    // Placeholder: In production, this would come from an API call
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.emoji_events_rounded,
                  size: Spacings.mdIcon, color: Color(0xFFF59E0B),),
              const SizedBox(width: Spacings.sm),
              Text(
                'Top Performers',
                style: tt.titleSmall?.copyWith(
                  fontWeight: AppTypography.wSemiBold,
                  color: cs.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: Spacings.md),
          // Leaderboard placeholder
          ...List.generate(5, (index) {
            final medalColor = switch (index) {
              0 => const Color(0xFFFFD700), // Gold
              1 => const Color(0xFFC0C0C0), // Silver
              2 => const Color(0xFFCD7F32), // Bronze
              _ => cs.onSurfaceVariant,
            };
            return Padding(
              padding: const EdgeInsets.only(bottom: Spacings.sm),
              child: Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: medalColor.withValues(alpha: 0.2),
                    ),
                    child: Center(
                      child: Text(
                        '${index + 1}',
                        style: tt.labelSmall?.copyWith(
                          fontWeight: AppTypography.wBold,
                          color: medalColor,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: Spacings.sm),
                  Expanded(
                    child: Text(
                      'Student ${index + 1}',
                      style: tt.bodyMedium?.copyWith(color: cs.onSurface),
                    ),
                  ),
                  Text(
                    '${(95 - index * 5).toStringAsFixed(0)}%',
                    style: tt.bodyMedium?.copyWith(
                      fontWeight: AppTypography.wSemiBold,
                      color: cs.onSurface,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  // ─── Difficult Topics Widget ─────────────────────────────────────────

  Widget _buildDifficultTopicsWidget(
      BuildContext context, SchoolPerformanceEntity? schoolPerf,) {
    final cs = context.colorScheme;
    final tt = context.textTheme;
    final isDark = context.isDarkMode;

    // Placeholder: In production, this would come from topic performance data
    final difficultTopics = [
      {'name': 'Quadratic Equations', 'accuracy': 32.0},
      {'name': 'Organic Chemistry', 'accuracy': 38.0},
      {'name': 'Calculus Integration', 'accuracy': 42.0},
      {'name': 'Electromagnetic Theory', 'accuracy': 45.0},
      {'name': 'Thermodynamics', 'accuracy': 48.0},
    ];

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.warning_amber_rounded,
                  size: Spacings.mdIcon,
                  color: AppColors.warningOf(cs.brightness),),
              const SizedBox(width: Spacings.sm),
              Text(
                'Difficult Topics',
                style: tt.titleSmall?.copyWith(
                  fontWeight: AppTypography.wSemiBold,
                  color: cs.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: Spacings.md),
          ...difficultTopics.map((topic) {
            final accuracy = topic['accuracy'] as double;
            final barColor = accuracy < 40
                ? AppColors.errorOf(cs.brightness)
                : AppColors.warningOf(cs.brightness);

            return Padding(
              padding: const EdgeInsets.only(bottom: Spacings.sm),
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: Text(
                      topic['name'] as String,
                      style: tt.bodySmall?.copyWith(color: cs.onSurface),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: Spacings.sm),
                  Expanded(
                    flex: 2,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(Spacings.smRadius),
                      child: LinearProgressIndicator(
                        value: accuracy / 100,
                        minHeight: 6,
                        backgroundColor: cs.surfaceContainerHighest,
                        color: barColor,
                        borderRadius: BorderRadius.circular(Spacings.smRadius),
                      ),
                    ),
                  ),
                  const SizedBox(width: Spacings.sm),
                  SizedBox(
                    width: 36,
                    child: Text(
                      '${accuracy.toStringAsFixed(0)}%',
                      style: tt.labelSmall?.copyWith(
                        fontWeight: AppTypography.wSemiBold,
                        color: barColor,
                      ),
                      textAlign: TextAlign.end,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  // ─── Historical Trend Widget ─────────────────────────────────────────

  Widget _buildHistoricalTrendWidget(BuildContext context) {
    final cs = context.colorScheme;
    final tt = context.textTheme;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Historical Trend',
            style: tt.titleSmall?.copyWith(
              fontWeight: AppTypography.wSemiBold,
              color: cs.onSurface,
            ),
          ),
          const SizedBox(height: Spacings.lg),
          Container(
            width: double.infinity,
            height: 160,
            decoration: BoxDecoration(
              color: cs.surfaceContainerHighest.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(Spacings.mdRadius),
              border: Border.all(
                color: cs.outlineVariant.withValues(alpha: 0.5),
              ),
            ),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.show_chart_rounded,
                      size: Spacings.xlIcon,
                      color: cs.onSurfaceVariant.withValues(alpha: 0.4),),
                  const SizedBox(height: Spacings.sm),
                  Text(
                    'Historical trend line chart',
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

  // ─── Class Ranking Widget ────────────────────────────────────────────

  Widget _buildClassRankingWidget(
      BuildContext context, SchoolPerformanceEntity? schoolPerf,) {
    final cs = context.colorScheme;
    final tt = context.textTheme;

    final classRankings = schoolPerf?.classRankings ?? [];
    final displayItems = classRankings.take(8).toList();

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Class Ranking',
            style: tt.titleSmall?.copyWith(
              fontWeight: AppTypography.wSemiBold,
              color: cs.onSurface,
            ),
          ),
          const SizedBox(height: Spacings.md),
          if (displayItems.isEmpty)
            Padding(
              padding: const EdgeInsets.all(Spacings.lg),
              child: Center(
                child: Text(
                  'No class ranking data available',
                  style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                ),
              ),
            )
          else
            Table(
              columnWidths: const {
                0: FlexColumnWidth(0.5),
                1: FlexColumnWidth(2),
                2: FlexColumnWidth(1),
                3: FlexColumnWidth(1),
              },
              defaultVerticalAlignment: TableCellVerticalAlignment.middle,
              children: [
                // Header
                TableRow(
                  children: [
                    _tableHeader(context, '#'),
                    _tableHeader(context, 'Class'),
                    _tableHeader(context, 'Avg Score'),
                    _tableHeader(context, 'Pass Rate'),
                  ],
                ),
                // Data rows
                ...displayItems.asMap().entries.map((entry) {
                  final index = entry.key;
                  final item = entry.value;
                  final className = (item is Map<String, dynamic>)
                      ? item['name'] as String? ?? 'Class ${index + 1}'
                      : item.toString();
                  final avgScore = (item is Map<String, dynamic>)
                      ? (item['averageScore'] as num?)?.toDouble() ?? 0.0
                      : 0.0;
                  final passRate = (item is Map<String, dynamic>)
                      ? (item['passRate'] as num?)?.toDouble() ?? 0.0
                      : 0.0;
                  return TableRow(
                    children: [
                      _tableCell(context, '${index + 1}'),
                      _tableCell(context, className),
                      _tableCell(context,
                          '${avgScore.toStringAsFixed(1)}%',),
                      _tableCell(context,
                          '${passRate.toStringAsFixed(1)}%',),
                    ],
                  );
                }),
              ],
            ),
        ],
      ),
    );
  }

  Widget _tableHeader(BuildContext context, String text) {
    final tt = context.textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Spacings.sm),
      child: Text(
        text,
        style: tt.labelSmall?.copyWith(
          fontWeight: AppTypography.wBold,
          color: context.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }

  Widget _tableCell(BuildContext context, String text) {
    final tt = context.textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Spacings.sm),
      child: Text(
        text,
        style: tt.bodySmall?.copyWith(
          color: context.colorScheme.onSurface,
        ),
      ),
    );
  }

  // ─── Exam Participation Widget ───────────────────────────────────────

  Widget _buildExamParticipationWidget(
      BuildContext context, SchoolPerformanceEntity? schoolPerf,) {
    final cs = context.colorScheme;
    final tt = context.textTheme;
    final isDark = context.isDarkMode;
    final totalExams = schoolPerf?.totalExams ?? 0;

    // Placeholder donut chart
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Exam Participation',
            style: tt.titleSmall?.copyWith(
              fontWeight: AppTypography.wSemiBold,
              color: cs.onSurface,
            ),
          ),
          const SizedBox(height: Spacings.lg),
          Center(
            child: SizedBox(
              width: 120,
              height: 120,
              child: CustomPaint(
                painter: _DonutChartPainter(
                  value: 0.78,
                  color: cs.primary,
                  backgroundColor: cs.surfaceContainerHighest,
                  strokeWidth: 12,
                ),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '78%',
                        style: tt.headlineSmall?.copyWith(
                          fontWeight: AppTypography.wBold,
                          color: cs.primary,
                        ),
                      ),
                      Text(
                        'Participated',
                        style: tt.labelSmall?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: Spacings.md),
          Center(
            child: Text(
              '$totalExams exams conducted',
              style: tt.bodySmall?.copyWith(
                color: cs.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Placeholder Widget (for unimplemented types) ────────────────────

  Widget _buildPlaceholderWidget(
      BuildContext context, DashboardWidgetConfigEntity widgetConfig,) {
    final cs = context.colorScheme;
    final tt = context.textTheme;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widgetConfig.title,
            style: tt.titleSmall?.copyWith(
              fontWeight: AppTypography.wSemiBold,
              color: cs.onSurface,
            ),
          ),
          const SizedBox(height: Spacings.lg),
          Container(
            width: double.infinity,
            height: 120,
            decoration: BoxDecoration(
              color: cs.surfaceContainerHighest.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(Spacings.mdRadius),
            ),
            child: Center(
              child: Text(
                widgetConfig.widgetType.label,
                style: tt.bodySmall?.copyWith(
                  color: cs.onSurfaceVariant,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Default Widget Configs ──────────────────────────────────────────

  List<DashboardWidgetConfigEntity> _defaultWidgetConfigs() {
    final now = DateTime.now();
    return [
      DashboardWidgetConfigEntity(
        id: 'default_pass_rate',
        dashboardId: 'default',
        widgetType: DashboardWidgetType.passRate,
        title: 'Pass Rate',
        isVisible: true,
        sortOrder: 0,
        createdAt: now,
        updatedAt: now,
      ),
      DashboardWidgetConfigEntity(
        id: 'default_score_dist',
        dashboardId: 'default',
        widgetType: DashboardWidgetType.scoreDistribution,
        title: 'Score Distribution',
        isVisible: true,
        sortOrder: 1,
        createdAt: now,
        updatedAt: now,
      ),
      DashboardWidgetConfigEntity(
        id: 'default_subject_comp',
        dashboardId: 'default',
        widgetType: DashboardWidgetType.subjectComparison,
        title: 'Subject Comparison',
        isVisible: true,
        sortOrder: 2,
        createdAt: now,
        updatedAt: now,
      ),
      DashboardWidgetConfigEntity(
        id: 'default_top_performers',
        dashboardId: 'default',
        widgetType: DashboardWidgetType.topPerformers,
        title: 'Top Performers',
        isVisible: true,
        sortOrder: 3,
        createdAt: now,
        updatedAt: now,
      ),
      DashboardWidgetConfigEntity(
        id: 'default_difficult_topics',
        dashboardId: 'default',
        widgetType: DashboardWidgetType.difficultTopics,
        title: 'Difficult Topics',
        isVisible: true,
        sortOrder: 4,
        createdAt: now,
        updatedAt: now,
      ),
      DashboardWidgetConfigEntity(
        id: 'default_historical_trend',
        dashboardId: 'default',
        widgetType: DashboardWidgetType.historicalTrend,
        title: 'Historical Trend',
        isVisible: true,
        sortOrder: 5,
        createdAt: now,
        updatedAt: now,
      ),
      DashboardWidgetConfigEntity(
        id: 'default_class_ranking',
        dashboardId: 'default',
        widgetType: DashboardWidgetType.classRanking,
        title: 'Class Ranking',
        isVisible: true,
        sortOrder: 6,
        createdAt: now,
        updatedAt: now,
      ),
      DashboardWidgetConfigEntity(
        id: 'default_exam_participation',
        dashboardId: 'default',
        widgetType: DashboardWidgetType.examParticipation,
        title: 'Exam Participation',
        isVisible: true,
        sortOrder: 7,
        createdAt: now,
        updatedAt: now,
      ),
    ];
  }

  // ─── Customize Dashboard Dialog ──────────────────────────────────────

  void _showCustomizeDialog(BuildContext context, AnalyticsState state) {
    final config = state.dashboardConfig;
    final widgets = config?.widgets.toList() ?? _defaultWidgetConfigs();
    final visibilityMap = <String, bool>{
      for (final w in widgets) w.id: w.isVisible,
    };

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Customize Dashboard'),
              content: SizedBox(
                width: 400,
                child: ListView(
                  shrinkWrap: true,
                  children: widgets.map((w) {
                    return CheckboxListTile(
                      value: visibilityMap[w.id] ?? w.isVisible,
                      title: Text(w.title),
                      subtitle: Text(w.widgetType.label),
                      controlAffinity:
                          ListTileControlAffinity.leading,
                      onChanged: (value) {
                        setDialogState(() {
                          visibilityMap[w.id] = value ?? true;
                        });
                      },
                    );
                  }).toList(),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () {
                    // Apply visibility changes
                    final updatedWidgets = widgets
                        .map((w) => w.copyWith(
                              isVisible: visibilityMap[w.id] ?? w.isVisible,
                            ),)
                        .toList();

                    if (config != null) {
                      final updatedConfig =
                          config.copyWith(widgets: updatedWidgets);
                      ref
                          .read(analyticsProvider.notifier)
                          .updateDashboardWidgets(updatedConfig);
                    }

                    Navigator.of(dialogContext).pop();
                  },
                  child: const Text('Apply'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// DONUT CHART PAINTER
// ═══════════════════════════════════════════════════════════════════════

class _DonutChartPainter extends CustomPainter {
  _DonutChartPainter({
    required this.value,
    required this.color,
    required this.backgroundColor,
    required this.strokeWidth,
  });

  final double value;
  final Color color;
  final Color backgroundColor;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (math.min(size.width, size.height) / 2) - strokeWidth / 2;

    // Background arc
    final bgPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    canvas.drawCircle(center, radius, bgPaint);

    // Value arc
    final valuePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    const startAngle = -math.pi / 2;
    final sweepAngle = 2 * math.pi * value;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      valuePaint,
    );
  }

  @override
  bool shouldRepaint(covariant _DonutChartPainter oldDelegate) {
    return oldDelegate.value != value || oldDelegate.color != color;
  }
}
