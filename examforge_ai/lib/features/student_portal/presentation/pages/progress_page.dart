import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/themes/app_colors.dart';
import '../../../../core/themes/app_typography.dart';
import '../../../../core/themes/spacings.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../shared/widgets/widgets.dart';
import '../providers/student_portal_providers.dart';
import '../../domain/entities/student_portal_entities.dart';

/// Progress analytics page.
///
/// Features:
/// - Period selector tabs (Weekly, Monthly, Termly)
/// - Subject filter dropdown
/// - Score trend chart (using Container heights for bars)
/// - Stats cards: Average Score, Questions Attempted, Practice Sessions, Study Time
/// - Weak topics list with improvement suggestions
/// - Strong topics list
/// - Learning streak calendar
/// - AI suggestions section
class ProgressPage extends ConsumerStatefulWidget {
  const ProgressPage({super.key});

  @override
  ConsumerState<ProgressPage> createState() => _ProgressPageState();
}

class _ProgressPageState extends ConsumerState<ProgressPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 3,
      vsync: this,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(progressProvider.notifier).loadProgress();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final progressState = ref.watch(progressProvider);
    final cs = context.colorScheme;
    final tt = context.textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Progress')),
      body: progressState.isLoading && progressState.progressHistory.isEmpty
          ? const Center(child: AppLoadingSpinner())
          : progressState.error != null &&
                  progressState.progressHistory.isEmpty
              ? AppErrorState(
                  icon: Icons.error_outline_rounded,
                  title: 'Failed to Load Progress',
                  message: progressState.error,
                  onRetry: () => ref
                      .read(progressProvider.notifier)
                      .loadProgress(),
                )
              : SingleChildScrollView(
                  padding: Spacings.paddingScreen,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Period selector tabs
                      Container(
                        decoration: BoxDecoration(
                          color: cs.surfaceContainerHighest,
                          borderRadius:
                              BorderRadius.circular(Spacings.lgRadius),
                        ),
                        child: TabBar(
                          controller: _tabController,
                          labelColor: cs.onPrimary,
                          unselectedLabelColor: cs.onSurfaceVariant,
                          indicatorSize: TabBarIndicatorSize.tab,
                          indicator: BoxDecoration(
                            color: cs.primary,
                            borderRadius: BorderRadius.circular(
                                Spacings.mdRadius),
                          ),
                          dividerColor: Colors.transparent,
                          tabs: const [
                            Tab(text: 'Weekly'),
                            Tab(text: 'Monthly'),
                            Tab(text: 'Termly'),
                          ],
                          onTap: (index) {
                            final period = switch (index) {
                              0 => ProgressPeriod.weekly,
                              1 => ProgressPeriod.monthly,
                              2 => ProgressPeriod.termly,
                              _ => ProgressPeriod.weekly,
                            };
                            ref
                                .read(progressProvider.notifier)
                                .selectPeriod(period);
                          },
                        ),
                      ),
                      Spacings.sectionGap,

                      // Stats cards row
                      _buildStatsRow(context, progressState),
                      Spacings.sectionGap,

                      // Score trend chart
                      _buildScoreTrendChart(context, progressState),
                      Spacings.sectionGap,

                      // Learning streak
                      _buildLearningStreak(context, progressState),
                      Spacings.sectionGap,

                      // Weak & Strong topics
                      if (progressState.latestProgress != null) ...[
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Weak topics
                            Expanded(
                              child: _buildTopicsList(
                                context,
                                'Weak Topics',
                                progressState
                                    .latestProgress!.weakTopics,
                                AppColors.error,
                                Icons.trending_down,
                              ),
                            ),
                            const SizedBox(width: Spacings.md),
                            // Strong topics
                            Expanded(
                              child: _buildTopicsList(
                                context,
                                'Strong Topics',
                                progressState
                                    .latestProgress!.strongTopics,
                                AppColors.success,
                                Icons.trending_up,
                              ),
                            ),
                          ],
                        ),
                        Spacings.sectionGap,

                        // AI suggestions
                        _buildAiSuggestions(
                            context, progressState.latestProgress!),
                      ],
                    ],
                  ),
                ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // STATS ROW
  // ═══════════════════════════════════════════════════════════════════════

  Widget _buildStatsRow(BuildContext context, ProgressState state) {
    return Row(
      children: [
        Expanded(
          child: AppStatCard(
            title: 'Avg Score',
            value:
                '${state.averageScore.toStringAsFixed(0)}%',
            icon: Icons.assessment_outlined,
            color: AppColors.info,
          ),
        ),
        const SizedBox(width: Spacings.sm),
        Expanded(
          child: AppStatCard(
            title: 'Questions',
            value: '${state.totalQuestionsAttempted}',
            icon: Icons.quiz_outlined,
            color: AppColors.success,
          ),
        ),
        const SizedBox(width: Spacings.sm),
        Expanded(
          child: AppStatCard(
            title: 'Sessions',
            value: state.latestProgress?.practiceSessions
                    .toString() ??
                '0',
            icon: Icons.auto_awesome_outlined,
            color: AppColors.warning,
          ),
        ),
        const SizedBox(width: Spacings.sm),
        Expanded(
          child: AppStatCard(
            title: 'Study Time',
            value:
                '${(state.totalStudyTime / 60).toStringAsFixed(1)}h',
            icon: Icons.timer_outlined,
            color: context.colorScheme.tertiary,
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // SCORE TREND CHART
  // ═══════════════════════════════════════════════════════════════════════

  Widget _buildScoreTrendChart(
      BuildContext context, ProgressState state) {
    final cs = context.colorScheme;
    final tt = context.textTheme;

    final history = state.progressHistory;
    if (history.isEmpty) {
      return AppCard(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(Spacings.xl),
            child: Text(
              'No data available yet',
              style: tt.bodyMedium?.copyWith(
                color: cs.onSurfaceVariant,
              ),
            ),
          ),
        ),
      );
    }

    final scores = history
        .where((p) => p.avgScore != null)
        .map((p) => p.avgScore!)
        .toList();

    if (scores.isEmpty) {
      return AppCard(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(Spacings.xl),
            child: Text(
              'No score data available',
              style: tt.bodyMedium?.copyWith(
                color: cs.onSurfaceVariant,
              ),
            ),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(context, 'Score Trend'),
        const SizedBox(height: Spacings.sm),
        AppCard(
          padding: const EdgeInsets.all(Spacings.lg),
          child: Column(
            children: [
              SizedBox(
                height: 200,
                child: CustomPaint(
                  size: Size(double.infinity, 200),
                  painter: _BarChartPainter(
                    scores: scores,
                    primaryColor: cs.primary,
                    backgroundColor: cs.surfaceContainerHighest,
                    textColor: cs.onSurfaceVariant,
                  ),
                ),
              ),
              const SizedBox(height: Spacings.sm),
              Text(
                'Your score trend over the selected period',
                style: tt.bodySmall?.copyWith(
                  color: cs.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // LEARNING STREAK
  // ═══════════════════════════════════════════════════════════════════════

  Widget _buildLearningStreak(
      BuildContext context, ProgressState state) {
    final cs = context.colorScheme;
    final tt = context.textTheme;
    final streak = state.learningStreak;

    return AppCard(
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(Spacings.lg),
            decoration: BoxDecoration(
              gradient: AppColors.warmGradient,
              borderRadius:
                  BorderRadius.circular(Spacings.mdRadius),
            ),
            child: Column(
              children: [
                Text(
                  '$streak',
                  style: tt.headlineMedium?.copyWith(
                    fontWeight: AppTypography.wBold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  '🔥',
                  style: const TextStyle(fontSize: 24),
                ),
              ],
            ),
          ),
          const SizedBox(width: Spacings.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Learning Streak',
                  style: tt.titleSmall?.copyWith(
                    fontWeight: AppTypography.wSemiBold,
                    color: cs.onSurface,
                  ),
                ),
                const SizedBox(height: Spacings.xs),
                Text(
                  streak > 0
                      ? 'You\'ve been studying for $streak days in a row! Keep it up!'
                      : 'Start your streak today by studying for at least 15 minutes.',
                  style: tt.bodySmall?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // TOPICS LISTS
  // ═══════════════════════════════════════════════════════════════════════

  Widget _buildTopicsList(
    BuildContext context,
    String title,
    List<TopicScoreInfo> topics,
    Color color,
    IconData icon,
  ) {
    final tt = context.textTheme;
    final cs = context.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: Spacings.xs),
            Text(
              title,
              style: tt.titleSmall?.copyWith(
                fontWeight: AppTypography.wSemiBold,
                color: cs.onSurface,
              ),
            ),
          ],
        ),
        const SizedBox(height: Spacings.sm),
        if (topics.isEmpty)
          AppCard(
            child: Padding(
              padding: const EdgeInsets.all(Spacings.md),
              child: Text(
                'No data yet',
                style: tt.bodySmall?.copyWith(
                  color: cs.onSurfaceVariant,
                ),
              ),
            ),
          )
        else
          ...topics.take(5).map(
            (topic) => Padding(
              padding: const EdgeInsets.only(bottom: Spacings.sm),
              child: AppCard(
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        topic.topicName,
                        style: tt.bodySmall?.copyWith(
                          color: cs.onSurface,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: Spacings.sm),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: Spacings.sm,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: color.withOpacity(context.isDarkMode ? 0.20 : 0.12,
                        ),
                        borderRadius: BorderRadius.circular(
                            Spacings.fullRadius),
                      ),
                      child: Text(
                        '${topic.scorePct.toStringAsFixed(0)}%',
                        style: tt.labelSmall?.copyWith(
                          color: color,
                          fontWeight: AppTypography.wSemiBold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // AI SUGGESTIONS
  // ═══════════════════════════════════════════════════════════════════════

  Widget _buildAiSuggestions(
      BuildContext context, StudentProgressEntity progress) {
    final cs = context.colorScheme;
    final tt = context.textTheme;

    if (progress.aiSuggestions.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.auto_awesome_rounded,
              size: Spacings.mdIcon,
              color: cs.primary,
            ),
            const SizedBox(width: Spacings.sm),
            _buildSectionTitle(context, 'AI Suggestions'),
          ],
        ),
        const SizedBox(height: Spacings.sm),
        ...progress.aiSuggestions.map(
          (suggestion) => Padding(
            padding: const EdgeInsets.only(bottom: Spacings.md),
            child: AppCard(
              child: Row(
                children: [
                  Icon(
                    _suggestionIcon(suggestion.type),
                    color: cs.primary,
                    size: Spacings.mdIcon,
                  ),
                  const SizedBox(width: Spacings.md),
                  Expanded(
                    child: Text(
                      suggestion.message,
                      style: tt.bodyMedium?.copyWith(
                        color: cs.onSurface,
                      ),
                    ),
                  ),
                  if (suggestion.actionLabel != null)
                    TextButton(
                      onPressed: () {},
                      child: Text(suggestion.actionLabel!),
                    ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ─── Helpers ────────────────────────────────────────────────────────

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Text(
      title,
      style: context.textTheme.titleSmall?.copyWith(
        fontWeight: AppTypography.wSemiBold,
        color: context.colorScheme.onSurface,
      ),
    );
  }

  IconData _suggestionIcon(String type) {
    return switch (type) {
      'study_tip' => Icons.lightbulb_outline,
      'practice_more' => Icons.quiz_outlined,
      'review_topic' => Icons.replay_outlined,
      _ => Icons.auto_awesome_outlined,
    };
  }
}

// ═══════════════════════════════════════════════════════════════════════
// BAR CHART PAINTER
// ═══════════════════════════════════════════════════════════════════════

class _BarChartPainter extends CustomPainter {
  _BarChartPainter({
    required this.scores,
    required this.primaryColor,
    required this.backgroundColor,
    required this.textColor,
  });

  final List<double> scores;
  final Color primaryColor;
  final Color backgroundColor;
  final Color textColor;

  @override
  void paint(Canvas canvas, Size size) {
    if (scores.isEmpty) return;

    final maxScore = scores.reduce((a, b) => a > b ? a : b);
    final minScore = scores.reduce((a, b) => a < b ? a : b);
    final range = maxScore - minScore;
    final adjustedMax = range == 0 ? maxScore + 10 : maxScore + 5;

    const barSpacing = 8.0;
    const bottomPadding = 24.0;
    const topPadding = 16.0;
    final chartHeight = size.height - bottomPadding - topPadding;
    final barWidth =
        (size.width - (scores.length + 1) * barSpacing) / scores.length;

    // Draw background grid lines
    final gridPaint = Paint()
      ..color = backgroundColor
      ..strokeWidth = 1;

    for (var i = 0; i <= 4; i++) {
      final y = topPadding + (chartHeight / 4) * i;
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        gridPaint,
      );
    }

    // Draw bars
    for (var i = 0; i < scores.length; i++) {
      final x = barSpacing + i * (barWidth + barSpacing);
      final barHeight =
          (scores[i] / adjustedMax) * chartHeight;
      final y = topPadding + chartHeight - barHeight;

      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, y, barWidth, barHeight),
        const Radius.circular(4),
      );

      canvas.drawRRect(
        rect,
        Paint()..color = primaryColor.withOpacity(0.8),
      );

      // Score label
      final textSpan = TextSpan(
        text: scores[i].toStringAsFixed(0),
        style: TextStyle(
          color: textColor,
          fontSize: 10,
        ),
      );
      final tp = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
      );
      tp.layout();
      tp.paint(
        canvas,
        Offset(x + barWidth / 2 - tp.width / 2, y - 14),
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
