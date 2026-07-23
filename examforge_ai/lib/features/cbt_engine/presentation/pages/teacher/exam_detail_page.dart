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
import '../../../../../shared/widgets/app_empty_state.dart';
import '../../../../../shared/widgets/app_loading.dart';
import '../../../../question_bank/presentation/widgets/difficulty_badge.dart';
import '../../../../question_bank/presentation/widgets/question_type_badge.dart';
import '../../../domain/entities/cbt_entities.dart';



// ═══════════════════════════════════════════════════════════════════════
// EXAM DETAIL PAGE (Teacher)
// ═══════════════════════════════════════════════════════════════════════

/// Exam detail page for teachers showing exam info, stats,
/// questions, students, and actions.
class ExamDetailPage extends ConsumerWidget {
  const ExamDetailPage({super.key, required this.examId});

  final String examId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // In a full implementation, we'd use a dedicated exam detail provider.
    // For now, we use the list provider to find the exam.
    final state = ref.watch(examListProvider);
    final exam = state.exams.where((e) => e.id == examId).firstOrNull;

    if (exam == null && state.isLoading) {
      return const Scaffold(
        appBar: AppAppBar(title: 'Exam Details'),
        body: Center(
            child: AppLoadingSpinner(size: AppLoadingSpinnerSize.large),),
      );
    }

    if (exam == null) {
      return Scaffold(
        appBar: const AppAppBar(title: 'Exam Not Found'),
        body: Center(
          child: AppEmptyState(
            icon: Icons.error_outline_rounded,
            title: 'Exam Not Found',
            subtitle: 'The exam you are looking for does not exist.',
            actionLabel: 'Go Back',
            onAction: () => Navigator.of(context).pop(),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppAppBar(
        title: exam.title,
        actions: [
          if (exam.status.isEditable)
            AppButton(
              label: 'Edit',
              onPressed: () {},
              variant: AppButtonVariant.outlined,
              size: AppButtonSize.small,
              icon: Icons.edit_rounded,
            ),
          const SizedBox(width: Spacings.sm),
          PopupMenuButton<String>(
            onSelected: (action) {
              switch (action) {
                case 'monitor':
                  break;
                case 'publish':
                  break;
                case 'clone':
                  ref.read(examListProvider.notifier).cloneExam(examId);
                case 'archive':
                  ref.read(examListProvider.notifier).archiveExam(examId);
              }
            },
            itemBuilder: (context) => [
              if (exam.status == ExamStatus.active)
                const PopupMenuItem(
                  value: 'monitor',
                  child: Row(
                    children: [
                      Icon(Icons.visibility_rounded),
                      SizedBox(width: Spacings.sm),
                      Text('Monitor'),
                    ],
                  ),
                ),
              if (exam.status == ExamStatus.draft)
                const PopupMenuItem(
                  value: 'publish',
                  child: Row(
                    children: [
                      Icon(Icons.publish_rounded),
                      SizedBox(width: Spacings.sm),
                      Text('Publish'),
                    ],
                  ),
                ),
              const PopupMenuItem(
                value: 'clone',
                child: Row(
                  children: [
                    Icon(Icons.content_copy_rounded),
                    SizedBox(width: Spacings.sm),
                    Text('Clone'),
                  ],
                ),
              ),
              if (exam.status != ExamStatus.archived)
                const PopupMenuItem(
                  value: 'archive',
                  child: Row(
                    children: [
                      Icon(Icons.archive_rounded),
                      SizedBox(width: Spacings.sm),
                      Text('Archive'),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(width: Spacings.sm),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(Spacings.lg),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Exam Header ────────────────────────────────────────
                _buildExamHeader(context, exam),
                const SizedBox(height: Spacings.xl),

                // ── Quick Stats ────────────────────────────────────────
                _buildQuickStats(context, exam),
                const SizedBox(height: Spacings.xl),

                // ── Questions ──────────────────────────────────────────
                _buildQuestionsSection(context, exam),
                const SizedBox(height: Spacings.xl),

                // ── Results Summary (if completed) ─────────────────────
                if (exam.status == ExamStatus.completed)
                  _buildResultsSummary(context, exam),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildExamHeader(BuildContext context, ExamEntity exam) {
    final cs = context.colorScheme;
    final tt = context.textTheme;
    final statusColor = _statusColor(context, exam.status);

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  exam.title,
                  style: tt.headlineSmall?.copyWith(
                    fontWeight: AppTypography.wBold,
                    color: cs.onSurface,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: Spacings.md,
                  vertical: Spacings.sm,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: context.isDarkMode ? 0.25 : 0.12),
                  borderRadius: BorderRadius.circular(Spacings.smRadius),
                ),
                child: Text(
                  exam.status.label,
                  style: tt.labelLarge?.copyWith(
                    fontWeight: AppTypography.wBold,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
          if (exam.description != null && exam.description!.isNotEmpty) ...[
            const SizedBox(height: Spacings.sm),
            Text(
              exam.description!,
              style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
            ),
          ],
          const SizedBox(height: Spacings.md),
          Wrap(
            spacing: Spacings.lg,
            runSpacing: Spacings.sm,
            children: [
              _infoItem(context, Icons.subject_rounded, 'Subject', exam.subjectId),
              _infoItem(context, Icons.class_rounded, 'Class', exam.classId),
              _infoItem(context, Icons.category_rounded, 'Type', exam.examType.label),
              _infoItem(context, Icons.timer_rounded, 'Duration', '${exam.timeLimitMinutes} min'),
              _infoItem(context, Icons.assessment_rounded, 'Total Marks', '${exam.totalMarks.toInt()}'),
              _infoItem(context, Icons.check_circle_rounded, 'Pass Mark',
                  exam.passMarkType == 'percentage'
                      ? '${exam.passMark}%'
                      : '${exam.passMark.toInt()}',),
            ],
          ),
        ],
      ),
    );
  }

  Widget _infoItem(BuildContext context, IconData icon, String label, String value) {
    final cs = context.colorScheme;
    final tt = context.textTheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16.0, color: cs.onSurfaceVariant),
        const SizedBox(width: Spacings.xs),
        Text(
          '$label: ',
          style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
        ),
        Text(
          value,
          style: tt.bodySmall?.copyWith(
            fontWeight: AppTypography.wSemiBold,
            color: cs.onSurface,
          ),
        ),
      ],
    );
  }

  Widget _buildQuickStats(BuildContext context, ExamEntity exam) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossCount = constraints.maxWidth > 600 ? 4 : 2;
        return GridView.count(
          crossAxisCount: crossCount,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: Spacings.md,
          crossAxisSpacing: Spacings.md,
          childAspectRatio: 1.5,
          children: [
            AppStatCard(
              title: 'Questions',
              value: '${exam.questions.length}',
              icon: Icons.quiz_rounded,
            ),
            AppStatCard(
              title: 'Duration',
              value: '${exam.timeLimitMinutes}m',
              icon: Icons.timer_rounded,
            ),
            AppStatCard(
              title: 'Total Marks',
              value: '${exam.totalMarks.toInt()}',
              icon: Icons.assessment_rounded,
            ),
            AppStatCard(
              title: 'Attempts',
              value: '${exam.allowedAttempts}',
              icon: Icons.replay_rounded,
            ),
          ],
        );
      },
    );
  }

  Widget _buildQuestionsSection(BuildContext context, ExamEntity exam) {
    final cs = context.colorScheme;
    final tt = context.textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Questions (${exam.questions.length})',
          style: tt.titleMedium?.copyWith(
            fontWeight: AppTypography.wBold,
            color: cs.onSurface,
          ),
        ),
        const SizedBox(height: Spacings.md),
        if (exam.questions.isEmpty)
          const AppEmptyState(
            icon: Icons.quiz_outlined,
            title: 'No Questions',
            subtitle: 'This exam has no questions added yet.',
          )
        else
          ...exam.questions.map((eq) {
            final question = eq.question;
            return Padding(
              padding: const EdgeInsets.only(bottom: Spacings.sm),
              child: AppCard(
                child: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: cs.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(Spacings.smRadius),
                      ),
                      child: Center(
                        child: Text(
                          '${eq.sortOrder}',
                          style: tt.labelMedium?.copyWith(
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
                          if (question != null)
                            Text(
                              question.content,
                              style: tt.bodyMedium?.copyWith(color: cs.onSurface),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            )
                          else
                            Text(
                              'Question ${eq.sortOrder}',
                              style: tt.bodyMedium?.copyWith(
                                  color: cs.onSurfaceVariant,),
                            ),
                          const SizedBox(height: Spacings.xs),
                          Row(
                            children: [
                              if (question != null)
                                QuestionTypeBadge(
                                  type: question.questionType,
                                  variant: QuestionTypeBadgeVariant.labelOnly,
                                ),
                              const SizedBox(width: Spacings.sm),
                              if (question != null)
                                DifficultyBadge(difficulty: question.difficulty),
                              const Spacer(),
                              Text(
                                '${eq.marks.toInt()} marks',
                                style: tt.bodySmall?.copyWith(
                                  fontWeight: AppTypography.wSemiBold,
                                  color: AppColors.infoOf(cs.brightness),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
      ],
    );
  }

  Widget _buildResultsSummary(BuildContext context, ExamEntity exam) {
    final cs = context.colorScheme;
    final tt = context.textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Results',
          style: tt.titleMedium?.copyWith(
            fontWeight: AppTypography.wBold,
            color: cs.onSurface,
          ),
        ),
        const SizedBox(height: Spacings.md),
        Row(
          children: [
            Expanded(
              child: AppButton(
                label: 'View Full Results',
                onPressed: () {},
                variant: AppButtonVariant.elevated,
                icon: Icons.bar_chart_rounded,
                fullWidth: true,
              ),
            ),
            const SizedBox(width: Spacings.md),
            Expanded(
              child: AppButton(
                label: 'Release Results',
                onPressed: () {},
                variant: AppButtonVariant.tonal,
                icon: Icons.send_rounded,
                fullWidth: true,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Color _statusColor(BuildContext context, ExamStatus status) {
    return switch (status) {
      ExamStatus.draft => const Color(0xFF9CA3AF),
      ExamStatus.published => const Color(0xFF3B82F6),
      ExamStatus.active => const Color(0xFF22C55E),
      ExamStatus.completed => const Color(0xFF6366F1),
      ExamStatus.archived => const Color(0xFF78716C),
      ExamStatus.cancelled => const Color(0xFFEF4444),
    };
  }
}
