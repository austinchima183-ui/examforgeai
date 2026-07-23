import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/themes/app_colors.dart';
import '../../../../core/themes/app_typography.dart';
import '../../../../core/themes/spacings.dart';
import '../../../../shared/widgets/widgets.dart';
import '../../domain/entities/exam_ecosystem_entities.dart';
import '../providers/exam_ecosystem_provider.dart';
import '../widgets/exam_body_card.dart';
import '../widgets/readiness_score_ring.dart';
import '../widgets/study_streak_badge.dart';

/// Dashboard showing exam bodies, mock exams, readiness scores, and quick actions.
///
/// Features:
/// - Exam body cards with type badges
/// - Readiness score ring for overall readiness
/// - Study streak badge
/// - Quick action buttons (Start Mock, Check Readiness, Study Plan)
/// - Recent mock exam results summary
class ExamEcosystemDashboardPage extends ConsumerStatefulWidget {
  const ExamEcosystemDashboardPage({super.key});

  @override
  ConsumerState<ExamEcosystemDashboardPage> createState() =>
      _ExamEcosystemDashboardPageState();
}

class _ExamEcosystemDashboardPageState
    extends ConsumerState<ExamEcosystemDashboardPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(examEcosystemProvider.notifier).loadAll();
      ref.read(readinessProvider.notifier).loadReadiness();
      ref.read(studyPlanProvider.notifier).loadPlans();
    });
  }

  @override
  Widget build(BuildContext context) {
    final ecoState = ref.watch(examEcosystemProvider);
    final readinessState = ref.watch(readinessProvider);
    final studyPlanState = ref.watch(studyPlanProvider);
    final cs = context.colorScheme;
    final tt = context.textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Exam Ecosystem'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () {
              ref.read(examEcosystemProvider.notifier).refresh();
            },
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: ecoState.isLoading && ecoState.bodies.isEmpty
          ? const Center(child: AppLoadingSpinner())
          : ecoState.error != null && ecoState.bodies.isEmpty
              ? AppErrorState(
                  icon: Icons.error_outline_rounded,
                  title: 'Failed to Load',
                  message: ecoState.error,
                  onRetry: () =>
                      ref.read(examEcosystemProvider.notifier).loadAll(),
                )
              : RefreshIndicator(
                  onRefresh: () =>
                      ref.read(examEcosystemProvider.notifier).refresh(),
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: Spacings.paddingScreen,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ─── Readiness & Streak Row ─────────────────────
                        Row(
                          children: [
                            Expanded(
                              child: ReadinessScoreRing(
                                score: readinessState.overallReadinessScore,
                                level: readinessState.overallReadinessLevel,
                              ),
                            ),
                            const SizedBox(width: Spacings.lg),
                            Expanded(
                              child: Column(
                                children: [
                                  StudyStreakBadge(
                                    streak: studyPlanState.currentStreak,
                                    label: 'Current Streak',
                                  ),
                                  const SizedBox(height: Spacings.sm),
                                  Text(
                                    '${studyPlanState.longestStreak} days best',
                                    style: tt.labelSmall?.copyWith(
                                      color: cs.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        Spacings.sectionGap,

                        // ─── Quick Actions ─────────────────────────────
                        Text(
                          'Quick Actions',
                          style: tt.titleMedium?.copyWith(
                            fontWeight: AppTypography.wSemiBold,
                          ),
                        ),
                        const SizedBox(height: Spacings.sm),
                        _buildQuickActions(context),
                        Spacings.sectionGap,

                        // ─── Exam Bodies ───────────────────────────────
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Examination Bodies',
                              style: tt.titleMedium?.copyWith(
                                fontWeight: AppTypography.wSemiBold,
                              ),
                            ),
                            TextButton(
                              onPressed: () {/* Navigate to full list */},
                              child: const Text('View All'),
                            ),
                          ],
                        ),
                        const SizedBox(height: Spacings.sm),
                        SizedBox(
                          height: 140,
                          child: ecoState.bodies.isEmpty
                              ? Center(
                                  child: Text(
                                    'No exam bodies available',
                                    style: tt.bodyMedium?.copyWith(
                                      color: cs.onSurfaceVariant,
                                    ),
                                  ),
                                )
                              : ListView.separated(
                                  scrollDirection: Axis.horizontal,
                                  itemCount: ecoState.bodies.length,
                                  separatorBuilder: (_, __) =>
                                      const SizedBox(width: Spacings.md),
                                  itemBuilder: (context, index) {
                                    return SizedBox(
                                      width: 160,
                                      child: ExamBodyCard(
                                        body: ecoState.bodies[index],
                                        onTap: () => ref
                                            .read(examEcosystemProvider.notifier)
                                            .selectBody(
                                              ecoState.bodies[index].id,
                                            ),
                                      ),
                                    );
                                  },
                                ),
                        ),
                        Spacings.sectionGap,

                        // ─── Recent Mock Exams ─────────────────────────
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Available Mock Exams',
                              style: tt.titleMedium?.copyWith(
                                fontWeight: AppTypography.wSemiBold,
                              ),
                            ),
                            TextButton(
                              onPressed: () {/* Navigate to mock list */},
                              child: const Text('View All'),
                            ),
                          ],
                        ),
                        const SizedBox(height: Spacings.sm),
                        ...ecoState.filteredMockExams.take(5).map(
                              (exam) => _buildMockExamTile(context, exam),
                            ),
                        if (ecoState.filteredMockExams.isEmpty)
                          Padding(
                            padding: Spacings.paddingAll,
                            child: Center(
                              child: Text(
                                'No mock exams available',
                                style: tt.bodyMedium?.copyWith(
                                  color: cs.onSurfaceVariant,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    final tt = context.textTheme;

    final actions = [
      _QuickAction(
        icon: Icons.quiz_rounded,
        label: 'Start Mock',
        color: AppColors.info,
        onTap: () {/* Navigate to mock exam list */},
      ),
      _QuickAction(
        icon: Icons.assessment_rounded,
        label: 'Check Readiness',
        color: AppColors.success,
        onTap: () {/* Navigate to readiness */},
      ),
      _QuickAction(
        icon: Icons.calendar_month_rounded,
        label: 'Study Plan',
        color: AppColors.warning,
        onTap: () {/* Navigate to study planner */},
      ),
      _QuickAction(
        icon: Icons.auto_awesome_rounded,
        label: 'AI Study',
        color: const Color(0xFF8B5CF6),
        onTap: () {/* Generate AI plan */},
      ),
    ];

    return Row(
      children: actions.map((action) {
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: Spacings.xs),
            child: Material(
              color: action.color.withValues(alpha: 0.1),
              borderRadius: Spacings.borderRadiusMd,
              child: InkWell(
                onTap: action.onTap,
                borderRadius: Spacings.borderRadiusMd,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: Spacings.md,
                    horizontal: Spacings.sm,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(action.icon, color: action.color, size: 28),
                      const SizedBox(height: Spacings.xs),
                      Text(
                        action.label,
                        style: tt.labelSmall?.copyWith(
                          fontWeight: AppTypography.wMedium,
                          color: action.color,
                        ),
                        textAlign: TextAlign.center,
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

  Widget _buildMockExamTile(BuildContext context, MockExam exam) {
    final cs = context.colorScheme;
    final tt = context.textTheme;

    return Card(
      margin: const EdgeInsets.only(bottom: Spacings.sm),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppColors.info.withValues(alpha: 0.1),
          child: const Icon(
            Icons.quiz_rounded,
            color: AppColors.info,
            size: 20,
          ),
        ),
        title: Text(
          exam.title,
          style: tt.bodyMedium?.copyWith(
            fontWeight: AppTypography.wMedium,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          '${exam.examBodyType.label} · ${exam.durationMinutes} min · ${exam.totalQuestions} Qs',
          style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
        ),
        trailing: _buildStatusChip(exam.status),
        onTap: () {/* Navigate to mock exam detail */},
      ),
    );
  }

  Widget _buildStatusChip(MockExamStatus status) {
    Color color;
    switch (status) {
      case MockExamStatus.published:
        color = AppColors.success;
        break;
      case MockExamStatus.inProgress:
        color = AppColors.info;
        break;
      case MockExamStatus.completed:
        color = AppColors.warning;
        break;
      case MockExamStatus.draft:
        color = Colors.grey;
        break;
      case MockExamStatus.archived:
        color = Colors.grey.shade600;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Spacings.sm,
        vertical: Spacings.xs,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: Spacings.borderRadiusFull,
      ),
      child: Text(
        status.label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: AppTypography.wSemiBold,
          color: color,
        ),
      ),
    );
  }
}

class _QuickAction {
  const _QuickAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
}
