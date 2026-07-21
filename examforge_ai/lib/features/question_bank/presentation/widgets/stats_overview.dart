import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/themes/app_colors.dart';
import '../../../../core/themes/app_typography.dart';
import '../../../../core/themes/spacings.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/app_loading.dart';
import '../../../../shared/widgets/app_empty_state.dart';
import '../../domain/entities/question_entities.dart';
import '../../../../features/analytics_dashboard/domain/entities/analytics_dashboard_entities.dart';


// ─── StatsOverview ────────────────────────────────────────────────────────────

/// A dashboard widget for the question bank that displays:
/// - Grid of stat cards (total, published, draft, archived)
/// - Subject distribution horizontal bar chart
/// - Difficulty distribution donut chart (simple colored segments)
/// - Question type breakdown
/// - Recent activity timeline
///
/// Uses [AppStatCard] from shared widgets.
///
/// ```dart
/// StatsOverview(stats: questionBankStats)
/// ```
class StatsOverview extends StatelessWidget {
  const StatsOverview({
    super.key,
    required this.stats,
    this.isLoading = false,
    this.onRefresh,
  });

  /// The aggregated question bank statistics.
  final QuestionBankStatsEntity? stats;

  /// Whether the stats are currently loading.
  final bool isLoading;

  /// Pull-to-refresh callback.
  final VoidCallback? onRefresh;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(
        child: AppLoadingSpinner(size: AppLoadingSpinnerSize.large),
      );
    }

    if (stats == null) {
      return AppEmptyState.noData(
        title: 'No Statistics',
        subtitle: 'Statistics will appear once questions are added.',
        actionLabel: onRefresh != null ? 'Refresh' : null,
        onAction: onRefresh,
      );
    }

    return RefreshIndicator(
      onRefresh: () async => onRefresh?.call(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(Spacings.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Stat Cards Grid ──────────────────────────────────────
            _buildStatCardsGrid(context),

            const SizedBox(height: Spacings.xl),

            // ── Charts Row: Subject Distribution + Difficulty Donut ──
            if (context.isMobile)
              Column(
                children: [
                  _buildSubjectDistributionChart(context),
                  const SizedBox(height: Spacings.xl),
                  _buildDifficultyDonutChart(context),
                ],
              )
            else
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _buildSubjectDistributionChart(context)),
                  const SizedBox(width: Spacings.xl),
                  Expanded(child: _buildDifficultyDonutChart(context)),
                ],
              ),

            const SizedBox(height: Spacings.xl),

            // ── Question Type Breakdown ──────────────────────────────
            _buildQuestionTypeBreakdown(context),

            const SizedBox(height: Spacings.xl),

            // ── Recent Activity ──────────────────────────────────────
            _buildRecentActivity(context),
          ],
        ),
      ),
    );
  }

  // ─── Stat Cards Grid ───────────────────────────────────────────────

  Widget _buildStatCardsGrid(BuildContext context) {
    final s = stats!;
    final cs = context.colorScheme;

    final cards = [
      _StatCardData(
        title: 'Total Questions',
        value: _formatNumber(s.totalQuestions),
        icon: Icons.quiz_outlined,
        color: cs.primary,
        trend: TrendDirection.up,
        trendValue: '+${s.recentQuestions} this week',
      ),
      _StatCardData(
        title: 'Published',
        value: _formatNumber(s.publishedQuestions),
        icon: Icons.check_circle_outline_rounded,
        color: AppColors.success,
        trend: TrendDirection.neutral,
      ),
      _StatCardData(
        title: 'Draft',
        value: _formatNumber(s.draftQuestions),
        icon: Icons.edit_note_rounded,
        color: AppColors.warning,
        trend: TrendDirection.neutral,
      ),
      _StatCardData(
        title: 'Archived',
        value: _formatNumber(s.archivedQuestions),
        icon: Icons.archive_outlined,
        color: const Color(0xFF6B7280),
        trend: TrendDirection.neutral,
      ),
    ];

    // 2 columns on mobile, 4 on desktop
    final crossAxisCount = context.isMobile ? 2 : 4;

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: crossAxisCount,
      childAspectRatio: context.isMobile ? 0.85 : 1.1,
      crossAxisSpacing: Spacings.md,
      mainAxisSpacing: Spacings.md,
      children: cards.map((data) {
        return AppStatCard(
          title: data.title,
          value: data.value,
          icon: data.icon,
          color: data.color,
          trend: data.trend,
          trendValue: data.trendValue,
        );
      }).toList(),
    );
  }

  // ─── Subject Distribution Bar Chart ────────────────────────────────

  Widget _buildSubjectDistributionChart(BuildContext context) {
    final cs = context.colorScheme;
    final tt = context.textTheme;
    final s = stats!;

    final subjectEntries = s.questionsBySubject.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    if (subjectEntries.isEmpty) {
      return const SizedBox.shrink();
    }

    final maxCount = subjectEntries.first.value.toDouble().clamp(1, double.infinity);

    // Color palette for bars
    const barColors = [
      Color(0xFF2563EB),
      Color(0xFF059669),
      Color(0xFFD97706),
      Color(0xFF7C3AED),
      Color(0xFFDC2626),
      Color(0xFF0891B2),
      Color(0xFFBE185D),
      Color(0xFF65A30D),
    ];

    return AppCard(
      padding: const EdgeInsets.all(Spacings.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.bar_chart_rounded,
                size: Spacings.mdIcon,
                color: cs.primary,
              ),
              const SizedBox(width: Spacings.sm),
              Text(
                'Subject Distribution',
                style: tt.titleSmall?.copyWith(
                  fontWeight: AppTypography.wSemiBold,
                  color: cs.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: Spacings.lg),
          ...subjectEntries.asMap().entries.map((entry) {
            final index = entry.key;
            final subject = entry.value;
            final barColor = barColors[index % barColors.length];
            final percent = (subject.value / maxCount).clamp(0.0, 1.0);

            return Padding(
              padding: const EdgeInsets.only(bottom: Spacings.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Text(
                          subject.key,
                          style: tt.bodySmall?.copyWith(
                            color: cs.onSurface,
                            fontWeight: AppTypography.wMedium,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        '${subject.value}',
                        style: tt.bodySmall?.copyWith(
                          color: cs.onSurfaceVariant,
                          fontWeight: AppTypography.wSemiBold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: Spacings.xs),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(Spacings.smRadius),
                    child: LinearProgressIndicator(
                      value: percent,
                      minHeight: 8.0,
                      backgroundColor: cs.surfaceContainerHighest,
                      color: barColor,
                      borderRadius: BorderRadius.circular(Spacings.smRadius),
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

  // ─── Difficulty Donut Chart ────────────────────────────────────────

  Widget _buildDifficultyDonutChart(BuildContext context) {
    final cs = context.colorScheme;
    final tt = context.textTheme;
    final s = stats!;

    final diffEntries = s.questionsByDifficulty.entries.toList();
    if (diffEntries.isEmpty) return const SizedBox.shrink();

    final total = diffEntries.fold<int>(0, (sum, e) => sum + e.value);
    if (total == 0) return const SizedBox.shrink();

    // Color mapping for difficulty
    const diffColors = {
      'easy': Color(0xFF16A34A),
      'medium': Color(0xFFF59E0B),
      'hard': Color(0xFFEA580C),
      'expert': Color(0xFFDC2626),
    };

    const diffLabels = {
      'easy': 'Easy',
      'medium': 'Medium',
      'hard': 'Hard',
      'expert': 'Expert',
    };

    return AppCard(
      padding: const EdgeInsets.all(Spacings.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.donut_large_rounded,
                size: Spacings.mdIcon,
                color: cs.primary,
              ),
              const SizedBox(width: Spacings.sm),
              Text(
                'Difficulty Distribution',
                style: tt.titleSmall?.copyWith(
                  fontWeight: AppTypography.wSemiBold,
                  color: cs.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: Spacings.xl),

          // Donut chart
          Center(
            child: SizedBox(
              width: 160.0,
              height: 160.0,
              child: CustomPaint(
                painter: _DonutChartPainter(
                  segments: diffEntries.map((e) {
                    final color = diffColors[e.key.toLowerCase()] ?? cs.onSurfaceVariant;
                    return _ChartSegment(
                      value: e.value,
                      color: color,
                    );
                  }).toList(),
                  total: total,
                ),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '$total',
                        style: tt.headlineSmall?.copyWith(
                          fontWeight: AppTypography.wBold,
                          color: cs.onSurface,
                        ),
                      ),
                      Text(
                        'Total',
                        style: tt.bodySmall?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: Spacings.lg),

          // Legend
          Wrap(
            spacing: Spacings.lg,
            runSpacing: Spacings.sm,
            alignment: WrapAlignment.center,
            children: diffEntries.map((e) {
              final color = diffColors[e.key.toLowerCase()] ?? cs.onSurfaceVariant;
              final label = diffLabels[e.key.toLowerCase()] ?? e.key;
              final percent = total > 0 ? ((e.value / total) * 100).round() : 0;

              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 10.0,
                    height: 10.0,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: Spacings.xs),
                  Text(
                    '$label ($percent%)',
                    style: tt.bodySmall?.copyWith(color: cs.onSurface),
                  ),
                ],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // ─── Question Type Breakdown ───────────────────────────────────────

  Widget _buildQuestionTypeBreakdown(BuildContext context) {
    final cs = context.colorScheme;
    final tt = context.textTheme;
    final s = stats!;

    final typeEntries = s.questionsByType.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    if (typeEntries.isEmpty) return const SizedBox.shrink();

    return AppCard(
      padding: const EdgeInsets.all(Spacings.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.category_rounded,
                size: Spacings.mdIcon,
                color: cs.primary,
              ),
              const SizedBox(width: Spacings.sm),
              Text(
                'Question Type Breakdown',
                style: tt.titleSmall?.copyWith(
                  fontWeight: AppTypography.wSemiBold,
                  color: cs.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: Spacings.lg),
          Wrap(
            spacing: Spacings.md,
            runSpacing: Spacings.sm,
            children: typeEntries.map((entry) {
              // Find matching QuestionType for icon
              QuestionType? qType;
              for (final t in QuestionType.values) {
                if (t.value == entry.key || t.label == entry.key) {
                  qType = t;
                  break;
                }
              }

              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: Spacings.md,
                  vertical: Spacings.sm,
                ),
                decoration: BoxDecoration(
                  color: cs.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(Spacings.smRadius),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (qType != null)
                      QuestionTypeBadge(
                        type: qType,
                        variant: QuestionTypeBadgeVariant.iconOnly,
                        size: QuestionTypeBadgeSize.small,
                      )
                    else
                      Icon(
                        Icons.label_outline_rounded,
                        size: Spacings.smIcon,
                        color: cs.onSurfaceVariant,
                      ),
                    const SizedBox(width: Spacings.sm),
                    Text(
                      entry.key,
                      style: tt.bodySmall?.copyWith(
                        color: cs.onSurface,
                        fontWeight: AppTypography.wMedium,
                      ),
                    ),
                    const SizedBox(width: Spacings.sm),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: Spacings.sm,
                        vertical: 2.0,
                      ),
                      decoration: BoxDecoration(
                        color: cs.primaryContainer,
                        borderRadius: BorderRadius.circular(Spacings.fullRadius),
                      ),
                      child: Text(
                        '${entry.value}',
                        style: tt.labelSmall?.copyWith(
                          color: cs.onPrimaryContainer,
                          fontWeight: AppTypography.wBold,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // ─── Recent Activity ───────────────────────────────────────────────

  Widget _buildRecentActivity(BuildContext context) {
    final cs = context.colorScheme;
    final tt = context.textTheme;
    final s = stats!;

    return AppCard(
      padding: const EdgeInsets.all(Spacings.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.history_rounded,
                size: Spacings.mdIcon,
                color: cs.primary,
              ),
              const SizedBox(width: Spacings.sm),
              Text(
                'Recent Activity',
                style: tt.titleSmall?.copyWith(
                  fontWeight: AppTypography.wSemiBold,
                  color: cs.onSurface,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: Spacings.sm,
                  vertical: Spacings.xs,
                ),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(Spacings.fullRadius),
                ),
                child: Text(
                  '+${s.recentQuestions} this week',
                  style: tt.bodySmall?.copyWith(
                    color: AppColors.success,
                    fontWeight: AppTypography.wSemiBold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: Spacings.lg),

          // Activity items
          _ActivityItem(
            icon: Icons.add_circle_outline_rounded,
            color: AppColors.success,
            title: '${s.recentQuestions} new questions',
            subtitle: 'Created in the last 7 days',
          ),
          const SizedBox(height: Spacings.md),
          _ActivityItem(
            icon: Icons.collections_bookmark_outlined,
            color: cs.primary,
            title: '${s.totalCollections} collections',
            subtitle: 'Question sets organized by teachers',
          ),
          const SizedBox(height: Spacings.md),
          _ActivityItem(
            icon: Icons.favorite_outline_rounded,
            color: const Color(0xFFE11D48),
            title: '${s.totalFavorites} favorites',
            subtitle: 'Most-bookmarked questions',
          ),
        ],
      ),
    );
  }

  // ─── Number Formatter ──────────────────────────────────────────────

  String _formatNumber(int value) {
    if (value >= 1000000) return '${(value / 1000000).toStringAsFixed(1)}M';
    if (value >= 1000) return '${(value / 1000).toStringAsFixed(1)}K';
    return value.toString();
  }
}

// ─── Stat Card Data ───────────────────────────────────────────────────────────

class _StatCardData {
  const _StatCardData({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    required this.trend,
    this.trendValue,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final TrendDirection trend;
  final String? trendValue;
}

// ─── Activity Item ────────────────────────────────────────────────────────────

class _ActivityItem extends StatelessWidget {
  const _ActivityItem({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;
    final tt = context.textTheme;
    final isDark = context.isDarkMode;

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(Spacings.sm),
          decoration: BoxDecoration(
            color: color.withValues(alpha: isDark ? 0.25 : 0.12),
            borderRadius: BorderRadius.circular(Spacings.smRadius),
          ),
          child: Icon(icon, size: Spacings.mdIcon, color: color),
        ),
        const SizedBox(width: Spacings.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: tt.bodyMedium?.copyWith(
                  color: cs.onSurface,
                  fontWeight: AppTypography.wSemiBold,
                ),
              ),
              Text(
                subtitle,
                style: tt.bodySmall?.copyWith(
                  color: cs.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── Donut Chart Painter ──────────────────────────────────────────────────────

class _ChartSegment {
  const _ChartSegment({required this.value, required this.color});
  final int value;
  final Color color;
}

class _DonutChartPainter extends CustomPainter {
  _DonutChartPainter({
    required this.segments,
    required this.total,
  });

  final List<_ChartSegment> segments;
  final int total;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2;
    final strokeWidth = radius * 0.35;

    var startAngle = -math.pi / 2; // Start from top

    for (final segment in segments) {
      final sweepAngle = 2 * math.pi * (segment.value / total);

      final paint = Paint()
        ..color = segment.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius - strokeWidth / 2),
        startAngle,
        sweepAngle,
        false,
        paint,
      );

      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutChartPainter oldDelegate) {
    return segments != oldDelegate.segments || total != oldDelegate.total;
  }
}
