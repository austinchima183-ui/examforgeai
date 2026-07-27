import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/themes/app_colors.dart';
import '../../../../core/themes/app_typography.dart';
import '../../../../core/themes/spacings.dart';
import '../../../../shared/widgets/widgets.dart';
import '../../domain/entities/exam_ecosystem_entities.dart';
import '../providers/exam_ecosystem_provider.dart';
import '../widgets/readiness_score_ring.dart';

/// Readiness dashboard showing scores, weak topics, strong topics,
/// and recommendations.
///
/// Features:
/// - Overall readiness score ring
/// - Per-subject readiness breakdown
/// - Weak topics list with severity indicators
/// - Strong topics list
/// - AI-powered recommendations
/// - Recalculate button
class ReadinessDashboardPage extends ConsumerStatefulWidget {
  const ReadinessDashboardPage({super.key});

  @override
  ConsumerState<ReadinessDashboardPage> createState() =>
      _ReadinessDashboardPageState();
}

class _ReadinessDashboardPageState
    extends ConsumerState<ReadinessDashboardPage> {
  String? _selectedExamBodyId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(readinessProvider.notifier).loadReadiness();
      ref.read(examEcosystemProvider.notifier).loadAll();
    });
  }

  @override
  Widget build(BuildContext context) {
    final readinessState = ref.watch(readinessProvider);
    final ecoState = ref.watch(examEcosystemProvider);
    final cs = context.colorScheme;
    final tt = context.textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Exam Readiness'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () {
              ref.read(readinessProvider.notifier).loadReadiness(
                    examBodyId: _selectedExamBodyId,
                  );
            },
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: readinessState.isLoading && readinessState.assessments.isEmpty
          ? const Center(child: AppLoadingSpinner())
          : readinessState.error != null &&
                  readinessState.assessments.isEmpty
              ? AppErrorState(
                  icon: Icons.assessment_outlined,
                  title: 'Failed to Load Readiness',
                  message: readinessState.error,
                  onRetry: () => ref
                      .read(readinessProvider.notifier)
                      .loadReadiness(),
                )
              : SingleChildScrollView(
                  padding: Spacings.paddingScreen,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ─── Exam Body Selector ────────────────────────────
                      if (ecoState.bodies.isNotEmpty) ...[
                        Text(
                          'Select Exam Body',
                          style: tt.labelMedium?.copyWith(
                            fontWeight: AppTypography.wSemiBold,
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: Spacings.xs),
                        SizedBox(
                          height: 40,
                          child: ListView(
                            scrollDirection: Axis.horizontal,
                            children: [
                              _buildBodyChip(
                                label: 'All',
                                selected: _selectedExamBodyId == null,
                                onSelected: () {
                                  setState(() => _selectedExamBodyId = null);
                                  ref
                                      .read(readinessProvider.notifier)
                                      .loadReadiness();
                                },
                              ),
                              ...ecoState.bodies.map(
                                (body) => _buildBodyChip(
                                  label: body.name,
                                  selected:
                                      _selectedExamBodyId == body.id,
                                  onSelected: () {
                                    setState(() =>
                                        _selectedExamBodyId = body.id,);
                                    ref
                                        .read(readinessProvider.notifier)
                                        .loadReadiness(
                                            examBodyId: body.id,);
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                        Spacings.sectionGap,
                      ],

                      // ─── Overall Readiness Score ──────────────────────
                      Center(
                        child: ReadinessScoreRing(
                          score: readinessState.overallReadinessScore,
                          level: readinessState.overallReadinessLevel,
                          size: 160,
                          strokeWidth: 14,
                        ),
                      ),
                      Spacings.sectionGap,

                      // ─── Per-Subject Breakdown ───────────────────────
                      if (readinessState.assessments.isNotEmpty) ...[
                        Text(
                          'Subject Breakdown',
                          style: tt.titleMedium?.copyWith(
                            fontWeight: AppTypography.wSemiBold,
                          ),
                        ),
                        const SizedBox(height: Spacings.sm),
                        ...readinessState.assessments.map(
                          (assessment) => _buildSubjectCard(
                            context,
                            assessment,
                          ),
                        ),
                        Spacings.sectionGap,
                      ],

                      // ─── Weak Topics ──────────────────────────────────
                      if (readinessState.allWeakTopics.isNotEmpty) ...[
                        Text(
                          'Weak Topics',
                          style: tt.titleMedium?.copyWith(
                            fontWeight: AppTypography.wSemiBold,
                            color: AppColors.error,
                          ),
                        ),
                        const SizedBox(height: Spacings.sm),
                        Container(
                          width: double.infinity,
                          padding: Spacings.paddingCard,
                          decoration: BoxDecoration(
                            color: AppColors.errorLight.withValues(alpha: 0.3,
                            ),
                            borderRadius: Spacings.borderRadiusMd,
                            border: Border.all(
                              color: AppColors.error.withValues(alpha: 0.2),
                            ),
                          ),
                          child: Wrap(
                            spacing: Spacings.sm,
                            runSpacing: Spacings.sm,
                            children: readinessState.allWeakTopics
                                .map(
                                  (topic) => Chip(
                                    label: Text(topic),
                                    avatar: const Icon(
                                      Icons.warning_amber_rounded,
                                      size: 16,
                                    ),
                                    materialTapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                    visualDensity: VisualDensity.compact,
                                  ),
                                )
                                .toList(),
                          ),
                        ),
                        Spacings.sectionGap,
                      ],

                      // ─── Strong Topics ────────────────────────────────
                      if (readinessState.allStrongTopics.isNotEmpty) ...[
                        Text(
                          'Strong Topics',
                          style: tt.titleMedium?.copyWith(
                            fontWeight: AppTypography.wSemiBold,
                            color: AppColors.success,
                          ),
                        ),
                        const SizedBox(height: Spacings.sm),
                        Container(
                          width: double.infinity,
                          padding: Spacings.paddingCard,
                          decoration: BoxDecoration(
                            color: AppColors.successLight.withValues(alpha: 0.3,
                            ),
                            borderRadius: Spacings.borderRadiusMd,
                            border: Border.all(
                              color:
                                  AppColors.success.withValues(alpha: 0.2),
                            ),
                          ),
                          child: Wrap(
                            spacing: Spacings.sm,
                            runSpacing: Spacings.sm,
                            children: readinessState.allStrongTopics
                                .map(
                                  (topic) => Chip(
                                    label: Text(topic),
                                    avatar: const Icon(
                                      Icons.check_circle_outline_rounded,
                                      size: 16,
                                    ),
                                    materialTapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                    visualDensity: VisualDensity.compact,
                                  ),
                                )
                                .toList(),
                          ),
                        ),
                        Spacings.sectionGap,
                      ],

                      // ─── Recommendations ──────────────────────────────
                      if (readinessState.allRecommendations.isNotEmpty) ...[
                        Text(
                          'Recommendations',
                          style: tt.titleMedium?.copyWith(
                            fontWeight: AppTypography.wSemiBold,
                          ),
                        ),
                        const SizedBox(height: Spacings.sm),
                        ...readinessState.allRecommendations.map(
                          (rec) => _buildRecommendationTile(context, rec),
                        ),
                        Spacings.sectionGap,
                      ],

                      // ─── Recalculate Button ───────────────────────────
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: _selectedExamBodyId != null
                              ? () {
                                  ref
                                      .read(readinessProvider.notifier)
                                      .calculateReadiness(
                                        examBodyId: _selectedExamBodyId!,
                                      );
                                }
                              : null,
                          icon: const Icon(Icons.auto_fix_high_rounded),
                          label: const Text('Recalculate Readiness'),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildBodyChip({
    required String label,
    required bool selected,
    required VoidCallback onSelected,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: Spacings.xs),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onSelected(),
        visualDensity: VisualDensity.compact,
      ),
    );
  }

  Widget _buildSubjectCard(BuildContext context, ReadinessAssessment assessment) {
    final cs = context.colorScheme;
    final tt = context.textTheme;

    return Card(
      margin: const EdgeInsets.only(bottom: Spacings.sm),
      child: Padding(
        padding: Spacings.paddingCard,
        child: Row(
          children: [
            // Mini score ring
            SizedBox(
              width: 56,
              height: 56,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CircularProgressIndicator(
                    value: assessment.readinessScore / 100,
                    strokeWidth: 4,
                    backgroundColor: cs.surfaceContainerHighest,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      _readinessColor(assessment.readinessScore),
                    ),
                  ),
                  Center(
                    child: Text(
                      '${assessment.readinessScore.round()}%',
                      style: tt.labelSmall?.copyWith(
                        fontWeight: AppTypography.wBold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: Spacings.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: Spacings.sm,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: _readinessLevelColor(
                            assessment.readinessLevel,
                          ).withValues(alpha: 0.1),
                          borderRadius: Spacings.borderRadiusFull,
                        ),
                        child: Text(
                          assessment.readinessLevel.label,
                          style: tt.labelSmall?.copyWith(
                            fontWeight: AppTypography.wSemiBold,
                            color: _readinessLevelColor(
                              assessment.readinessLevel,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: Spacings.xs),
                  Text(
                    '${assessment.topicsMastered}/${assessment.topicsTotal} topics mastered',
                    style: tt.bodySmall?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                  if (assessment.weakTopics.isNotEmpty)
                    Text(
                      '${assessment.weakTopics.length} weak topic${assessment.weakTopics.length != 1 ? 's' : ''}',
                      style: tt.bodySmall?.copyWith(
                        color: AppColors.error,
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

  Widget _buildRecommendationTile(BuildContext context, String recommendation) {
    final tt = Theme.of(context).textTheme;

    return ListTile(
      dense: true,
      leading: const Icon(Icons.lightbulb_outline_rounded, size: 20),
      title: Text(
        recommendation,
        style: tt.bodySmall,
      ),
      contentPadding: EdgeInsets.zero,
    );
  }

  Color _readinessColor(double score) {
    if (score >= 80) return AppColors.success;
    if (score >= 60) return AppColors.info;
    if (score >= 40) return AppColors.warning;
    return AppColors.error;
  }

  Color _readinessLevelColor(ReadinessLevel level) {
    switch (level) {
      case ReadinessLevel.examReady:
        return AppColors.success;
      case ReadinessLevel.advanced:
        return AppColors.info;
      case ReadinessLevel.proficient:
        return const Color(0xFF06B6D4);
      case ReadinessLevel.developing:
        return AppColors.warning;
      case ReadinessLevel.beginning:
        return const Color(0xFFEA580C);
      case ReadinessLevel.notStarted:
        return AppColors.error;
    }
  }
}
