import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/themes/app_colors.dart';
import '../../../../core/themes/app_typography.dart';
import '../../../../core/themes/spacings.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../shared/widgets/widgets.dart';
import '../../domain/entities/exam_ecosystem_entities.dart';
import '../providers/exam_ecosystem_provider.dart';
import '../widgets/study_streak_badge.dart';

/// Study planner page with plans, activities, streak tracking, and AI generation.
///
/// Features:
/// - Plan list with active/inactive toggle
/// - Create plan dialog
/// - Activity list for selected plan
/// - Activity completion with performance score
/// - AI-generated study plan
/// - Streak tracking with badge
/// - Calendar-like date view
class StudyPlannerPage extends ConsumerStatefulWidget {
  const StudyPlannerPage({super.key});

  @override
  ConsumerState<StudyPlannerPage> createState() => _StudyPlannerPageState();
}

class _StudyPlannerPageState extends ConsumerState<StudyPlannerPage> {
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(studyPlanProvider.notifier).loadPlans();
      ref.read(examEcosystemProvider.notifier).loadAll();
    });
  }

  @override
  Widget build(BuildContext context) {
    final planState = ref.watch(studyPlanProvider);
    final ecoState = ref.watch(examEcosystemProvider);
    final cs = context.colorScheme;
    final tt = context.textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Study Planner'),
        actions: [
          IconButton(
            icon: const Icon(Icons.auto_awesome_rounded),
            onPressed: () => _showAiGenerateDialog(context, ecoState),
            tooltip: 'AI Generate Plan',
          ),
        ],
      ),
      body: planState.isLoading && planState.plans.isEmpty
          ? const Center(child: AppLoadingSpinner())
          : planState.error != null && planState.plans.isEmpty
              ? AppErrorState(
                  icon: Icons.calendar_month_outlined,
                  title: 'Failed to Load Plans',
                  message: planState.error,
                  onRetry: () =>
                      ref.read(studyPlanProvider.notifier).loadPlans(),
                )
              : planState.plans.isEmpty
                  ? AppEmptyState(
                      icon: Icons.calendar_month_outlined,
                      title: 'No Study Plans',
                      subtitle:
                          'Create a study plan or let AI generate one for you.',
                      actionLabel: 'Create Plan',
                      onAction: () =>
                          _showCreatePlanDialog(context, ecoState),
                    )
                  : _buildPlannerContent(context, planState),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreatePlanDialog(context, ecoState),
        icon: const Icon(Icons.add_rounded),
        label: const Text('New Plan'),
      ),
    );
  }

  Widget _buildPlannerContent(BuildContext context, StudyPlanState planState) {
    final cs = context.colorScheme;
    final tt = context.textTheme;

    return Column(
      children: [
        // ─── Streak & Stats Bar ────────────────────────────────────
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: Spacings.lg,
            vertical: Spacings.md,
          ),
          color: cs.surfaceContainerLow,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              StudyStreakBadge(
                streak: planState.currentStreak,
                size: 56,
              ),
              _StatItem(
                label: 'Total Hours',
                value: '${planState.currentPlan?.studyHours ?? 0}h',
              ),
              _StatItem(
                label: 'Active Plans',
                value: '${planState.activePlans.length}',
              ),
              _StatItem(
                label: 'Today',
                value: '${planState.todayActivities.length}',
              ),
            ],
          ),
        ),

        // ─── Plan Selector ─────────────────────────────────────────
        if (planState.plans.length > 1)
          SizedBox(
            height: 48,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(
                horizontal: Spacings.lg,
                vertical: Spacings.xs,
              ),
              children: planState.plans.map((plan) {
                final isCurrent = plan.id == planState.currentPlan?.id;
                return Padding(
                  padding: const EdgeInsets.only(right: Spacings.xs),
                  child: ChoiceChip(
                    label: Text(plan.title),
                    selected: isCurrent,
                    onSelected: (_) {
                      ref.read(studyPlanProvider.notifier).selectPlan(plan);
                    },
                    visualDensity: VisualDensity.compact,
                  ),
                );
              }).toList(),
            ),
          ),

        // ─── Plan Header ───────────────────────────────────────────
        if (planState.currentPlan != null)
          Container(
            padding: Spacings.paddingCard,
            color: cs.surfaceContainerLow,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        planState.currentPlan!.title,
                        style: tt.titleMedium?.copyWith(
                          fontWeight: AppTypography.wSemiBold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (planState.currentPlan!.aiGenerated)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: Spacings.sm,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF8B5CF6).withValues(alpha: 0.1),
                          borderRadius: Spacings.borderRadiusFull,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.auto_awesome_rounded,
                              size: 12,
                              color: const Color(0xFF8B5CF6),
                            ),
                            const SizedBox(width: 2),
                            Text(
                              'AI',
                              style: tt.labelSmall?.copyWith(
                                fontWeight: AppTypography.wBold,
                                color: const Color(0xFF8B5CF6),
                              ),
                            ),
                          ],
                        ),
                      ),
                    IconButton(
                      icon: const Icon(Icons.more_vert_rounded, size: 20),
                      onPressed: () => _showPlanOptions(context, planState.currentPlan!),
                    ),
                  ],
                ),
                const SizedBox(height: Spacings.xs),
                Row(
                  children: [
                    Icon(Icons.schedule_rounded, size: 14, color: cs.onSurfaceVariant),
                    const SizedBox(width: Spacings.xs),
                    Text(
                      '${planState.currentPlan!.dailyStudyMinutes} min/day',
                      style: tt.bodySmall?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(width: Spacings.lg),
                    if (planState.currentPlan!.targetDate != null) ...[
                      Icon(Icons.event_rounded, size: 14, color: cs.onSurfaceVariant),
                      const SizedBox(width: Spacings.xs),
                      Text(
                        'Target: ${_formatDate(planState.currentPlan!.targetDate!)}',
                        style: tt.bodySmall?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),

        // ─── Date Selector ─────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: Spacings.lg,
            vertical: Spacings.sm,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left_rounded),
                onPressed: () {
                  setState(() {
                    _selectedDate = _selectedDate.subtract(
                      const Duration(days: 1),
                    );
                  });
                },
              ),
              Text(
                _formatDateFull(_selectedDate),
                style: tt.titleSmall?.copyWith(
                  fontWeight: AppTypography.wSemiBold,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right_rounded),
                onPressed: () {
                  setState(() {
                    _selectedDate = _selectedDate.add(
                      const Duration(days: 1),
                    );
                  });
                },
              ),
            ],
          ),
        ),

        // ─── Activities List ───────────────────────────────────────
        Expanded(
          child: planState.activities.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.event_available_outlined,
                        size: 48,
                        color: cs.onSurfaceVariant.withValues(alpha: 0.5),
                      ),
                      const SizedBox(height: Spacings.md),
                      Text(
                        'No activities for this date',
                        style: tt.bodyMedium?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.symmetric(
                    horizontal: Spacings.lg,
                    vertical: Spacings.sm,
                  ),
                  itemCount: planState.activities.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(height: Spacings.sm),
                  itemBuilder: (context, index) {
                    return _buildActivityCard(
                      context,
                      planState.activities[index],
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildActivityCard(BuildContext context, StudyPlanActivity activity) {
    final cs = context.colorScheme;
    final tt = context.textTheme;

    final activityIcon = _activityIcon(activity.activityType);
    final activityColor = _activityColor(activity.activityType);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: activity.isCompleted
            ? null
            : () => _completeActivity(activity),
        child: Padding(
          padding: Spacings.paddingCard,
          child: Row(
            children: [
              // Activity type icon
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: activityColor.withValues(alpha: 0.1),
                  borderRadius: Spacings.borderRadiusMd,
                ),
                child: Icon(
                  activity.isCompleted
                      ? Icons.check_circle_rounded
                      : activityIcon,
                  color: activity.isCompleted ? AppColors.success : activityColor,
                  size: 22,
                ),
              ),
              const SizedBox(width: Spacings.md),

              // Activity details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      activity.title,
                      style: tt.bodyMedium?.copyWith(
                        fontWeight: AppTypography.wMedium,
                        decoration: activity.isCompleted
                            ? TextDecoration.lineThrough
                            : null,
                        color: activity.isCompleted
                            ? cs.onSurfaceVariant
                            : cs.onSurface,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (activity.description != null)
                      Text(
                        activity.description!,
                        style: tt.bodySmall?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    const SizedBox(height: Spacings.xs),
                    Row(
                      children: [
                        Icon(
                          Icons.schedule_rounded,
                          size: 12,
                          color: cs.onSurfaceVariant,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          '${activity.durationMinutes ?? 30} min',
                          style: tt.labelSmall?.copyWith(
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(width: Spacings.md),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: Spacings.xs,
                            vertical: 1,
                          ),
                          decoration: BoxDecoration(
                            color: activityColor.withValues(alpha: 0.1),
                            borderRadius: Spacings.borderRadiusFull,
                          ),
                          child: Text(
                            activity.activityType.label,
                            style: tt.labelSmall?.copyWith(
                              color: activityColor,
                              fontSize: 10,
                            ),
                          ),
                        ),
                        if (activity.isOverdue) ...[
                          const SizedBox(width: Spacings.sm),
                          Text(
                            'Overdue',
                            style: tt.labelSmall?.copyWith(
                              color: AppColors.error,
                              fontWeight: AppTypography.wSemiBold,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),

              // Performance score (if completed)
              if (activity.isCompleted && activity.performanceScore != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: Spacings.sm,
                    vertical: Spacings.xs,
                  ),
                  decoration: BoxDecoration(
                    color: activity.performanceScore! >= 70
                        ? AppColors.success.withValues(alpha: 0.1)
                        : AppColors.warning.withValues(alpha: 0.1),
                    borderRadius: Spacings.borderRadiusFull,
                  ),
                  child: Text(
                    '${activity.performanceScore!.round()}%',
                    style: tt.labelSmall?.copyWith(
                      fontWeight: AppTypography.wBold,
                      color: activity.performanceScore! >= 70
                          ? AppColors.success
                          : AppColors.warning,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _completeActivity(StudyPlanActivity activity) async {
    final score = await showDialog<double>(
      context: context,
      builder: (context) => const _PerformanceScoreDialog(),
    );

    if (score != null && mounted) {
      ref.read(studyPlanProvider.notifier).completeActivity(
            activityId: activity.id,
            performanceScore: score,
          );
    }
  }

  void _showCreatePlanDialog(
    BuildContext context,
    ExamEcosystemState ecoState,
  ) {
    showDialog(
      context: context,
      builder: (context) => _CreatePlanDialog(
        examBodies: ecoState.bodies,
        onCreated: (plan) {
          ref.read(studyPlanProvider.notifier).createPlan(plan);
        },
      ),
    );
  }

  void _showAiGenerateDialog(
    BuildContext context,
    ExamEcosystemState ecoState,
  ) {
    showDialog(
      context: context,
      builder: (context) => _AiGenerateDialog(
        examBodies: ecoState.bodies,
        onGenerated: ({
          required examBodyId,
          subjectId,
          educationalLevelId,
          targetDate,
          dailyStudyMinutes,
        }) {
          ref.read(studyPlanProvider.notifier).generateAiPlan(
                examBodyId: examBodyId,
                subjectId: subjectId,
                educationalLevelId: educationalLevelId,
                targetDate: targetDate,
                dailyStudyMinutes: dailyStudyMinutes,
              );
        },
      ),
    );
  }

  void _showPlanOptions(BuildContext context, StudyPlan plan) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.delete_outline_rounded),
                title: const Text('Delete Plan'),
                onTap: () {
                  Navigator.pop(context);
                  ref.read(studyPlanProvider.notifier).deletePlan(plan.id);
                },
              ),
              ListTile(
                leading: const Icon(Icons.close_rounded),
                title: const Text('Cancel'),
                onTap: () => Navigator.pop(context),
              ),
            ],
          ),
        );
      },
    );
  }

  IconData _activityIcon(StudyActivityType type) {
    switch (type) {
      case StudyActivityType.practice:
        return Icons.edit_note_rounded;
      case StudyActivityType.reading:
        return Icons.menu_book_rounded;
      case StudyActivityType.video:
        return Icons.play_circle_outline_rounded;
      case StudyActivityType.quiz:
        return Icons.quiz_rounded;
      case StudyActivityType.revision:
        return Icons.replay_rounded;
      case StudyActivityType.mockExam:
        return Icons.assignment_rounded;
      case StudyActivityType.topicReview:
        return Icons.topic_rounded;
    }
  }

  Color _activityColor(StudyActivityType type) {
    switch (type) {
      case StudyActivityType.practice:
        return AppColors.info;
      case StudyActivityType.reading:
        return const Color(0xFF8B5CF6);
      case StudyActivityType.video:
        return AppColors.error;
      case StudyActivityType.quiz:
        return AppColors.success;
      case StudyActivityType.revision:
        return AppColors.warning;
      case StudyActivityType.mockExam:
        return const Color(0xFF06B6D4);
      case StudyActivityType.topicReview:
        return const Color(0xFFEC4899);
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  String _formatDateFull(DateTime date) {
    const months = [
      '', 'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December',
    ];
    return '${months[date.month]} ${date.day}, ${date.year}';
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: tt.titleMedium?.copyWith(
            fontWeight: AppTypography.wBold,
          ),
        ),
        Text(
          label,
          style: tt.labelSmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _PerformanceScoreDialog extends StatefulWidget {
  const _PerformanceScoreDialog();

  @override
  State<_PerformanceScoreDialog> createState() =>
      _PerformanceScoreDialogState();
}

class _PerformanceScoreDialogState extends State<_PerformanceScoreDialog> {
  double _score = 70;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Performance Score'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'How did you perform?',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: Spacings.lg),
          Text(
            '${_score.round()}%',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: AppTypography.wBold,
                  color: _score >= 70 ? AppColors.success : AppColors.warning,
                ),
          ),
          Slider(
            value: _score,
            min: 0,
            max: 100,
            divisions: 20,
            label: '${_score.round()}%',
            onChanged: (value) => setState(() => _score = value),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Skip'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, _score),
          child: const Text('Save'),
        ),
      ],
    );
  }
}

class _CreatePlanDialog extends StatefulWidget {
  const _CreatePlanDialog({
    required this.examBodies,
    required this.onCreated,
  });

  final List<ExaminationBody> examBodies;
  final void Function(StudyPlan plan) onCreated;

  @override
  State<_CreatePlanDialog> createState() => _CreatePlanDialogState();
}

class _CreatePlanDialogState extends State<_CreatePlanDialog> {
  final _titleController = TextEditingController();
  String? _selectedBodyId;
  int _dailyMinutes = 60;
  DateTime? _targetDate;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Create Study Plan'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Plan Title',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: Spacings.md),
            DropdownButtonFormField<String>(
              value: _selectedBodyId,
              decoration: const InputDecoration(
                labelText: 'Exam Body',
                border: OutlineInputBorder(),
              ),
              items: widget.examBodies
                  .map((b) => DropdownMenuItem(
                        value: b.id,
                        child: Text(b.name),
                      ))
                  .toList(),
              onChanged: (value) => setState(() => _selectedBodyId = value),
            ),
            const SizedBox(height: Spacings.md),
            Row(
              children: [
                const Text('Daily study: '),
                Expanded(
                  child: Slider(
                    value: _dailyMinutes.toDouble(),
                    min: 15,
                    max: 180,
                    divisions: 11,
                    label: '$_dailyMinutes min',
                    onChanged: (value) =>
                        setState(() => _dailyMinutes = value.round()),
                  ),
                ),
                Text('$_dailyMinutes min'),
              ],
            ),
            const SizedBox(height: Spacings.md),
            OutlinedButton.icon(
              onPressed: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now().add(const Duration(days: 30)),
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                );
                if (date != null) setState(() => _targetDate = date);
              },
              icon: const Icon(Icons.calendar_today_rounded, size: 18),
              label: Text(
                _targetDate != null
                    ? 'Target: ${_targetDate!.day}/${_targetDate!.month}/${_targetDate!.year}'
                    : 'Set Target Date',
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _titleController.text.isNotEmpty && _selectedBodyId != null
              ? () {
                  // Create a placeholder plan - the ID will be set by the server
                  final plan = StudyPlan(
                    id: '',
                    userId: '',
                    title: _titleController.text,
                    examBodyId: _selectedBodyId!,
                    dailyStudyMinutes: _dailyMinutes,
                    targetDate: _targetDate,
                    createdAt: DateTime.now(),
                    updatedAt: DateTime.now(),
                  );
                  widget.onCreated(plan);
                  Navigator.pop(context);
                }
              : null,
          child: const Text('Create'),
        ),
      ],
    );
  }
}

class _AiGenerateDialog extends StatefulWidget {
  const _AiGenerateDialog({
    required this.examBodies,
    required this.onGenerated,
  });

  final List<ExaminationBody> examBodies;
  final void Function({
    required String examBodyId,
    String? subjectId,
    String? educationalLevelId,
    DateTime? targetDate,
    int dailyStudyMinutes,
  }) onGenerated;

  @override
  State<_AiGenerateDialog> createState() => _AiGenerateDialogState();
}

class _AiGenerateDialogState extends State<_AiGenerateDialog> {
  String? _selectedBodyId;
  int _dailyMinutes = 60;
  DateTime? _targetDate;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.auto_awesome_rounded, color: Color(0xFF8B5CF6)),
          const SizedBox(width: Spacings.sm),
          const Text('AI Study Plan'),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Let AI create a personalized study plan based on your '
              'readiness level and exam requirements.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: Spacings.md),
            DropdownButtonFormField<String>(
              value: _selectedBodyId,
              decoration: const InputDecoration(
                labelText: 'Exam Body',
                border: OutlineInputBorder(),
              ),
              items: widget.examBodies
                  .map((b) => DropdownMenuItem(
                        value: b.id,
                        child: Text(b.name),
                      ))
                  .toList(),
              onChanged: (value) => setState(() => _selectedBodyId = value),
            ),
            const SizedBox(height: Spacings.md),
            Row(
              children: [
                const Text('Daily study: '),
                Expanded(
                  child: Slider(
                    value: _dailyMinutes.toDouble(),
                    min: 15,
                    max: 180,
                    divisions: 11,
                    label: '$_dailyMinutes min',
                    onChanged: (value) =>
                        setState(() => _dailyMinutes = value.round()),
                  ),
                ),
                Text('$_dailyMinutes min'),
              ],
            ),
            const SizedBox(height: Spacings.md),
            OutlinedButton.icon(
              onPressed: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now().add(const Duration(days: 30)),
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                );
                if (date != null) setState(() => _targetDate = date);
              },
              icon: const Icon(Icons.calendar_today_rounded, size: 18),
              label: Text(
                _targetDate != null
                    ? 'Target: ${_targetDate!.day}/${_targetDate!.month}/${_targetDate!.year}'
                    : 'Set Target Date',
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton.icon(
          onPressed: _selectedBodyId != null
              ? () {
                  widget.onGenerated(
                    examBodyId: _selectedBodyId!,
                    targetDate: _targetDate,
                    dailyStudyMinutes: _dailyMinutes,
                  );
                  Navigator.pop(context);
                }
              : null,
          icon: const Icon(Icons.auto_awesome_rounded, size: 18),
          label: const Text('Generate'),
        ),
      ],
    );
  }
}
