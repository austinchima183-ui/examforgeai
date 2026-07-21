import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/themes/app_colors.dart';
import '../../../../core/themes/app_typography.dart';
import '../../../../core/themes/spacings.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../shared/widgets/widgets.dart';
import '../providers/student_portal_providers.dart';
import '../../domain/entities/student_portal_entities.dart';

/// Study planner page with calendar view, tasks, and AI suggestions.
///
/// Features:
/// - Plan list with active/inactive toggle
/// - Create plan dialog: Title, Frequency, Date range, Subject selection
/// - Plan detail: Calendar view with tasks, Task list for selected date,
///   Task status toggles, Create task dialog
/// - AI suggest plan button
/// - Date picker for navigation
class StudyPlannerPage extends ConsumerStatefulWidget {
  const StudyPlannerPage({super.key});

  @override
  ConsumerState<StudyPlannerPage> createState() =>
      _StudyPlannerPageState();
}

class _StudyPlannerPageState extends ConsumerState<StudyPlannerPage> {
  DateTime _selectedDate = DateTime.now();
  DateTime _focusedMonth = DateTime.now();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(studyPlannerProvider.notifier).loadPlans();
    });
  }

  @override
  Widget build(BuildContext context) {
    final plannerState = ref.watch(studyPlannerProvider);

    if (plannerState.currentPlan != null) {
      return _buildPlanDetail(context, plannerState);
    }

    return _buildPlanList(context, plannerState);
  }

  // ═══════════════════════════════════════════════════════════════════════
  // PLAN LIST
  // ═══════════════════════════════════════════════════════════════════════

  Widget _buildPlanList(BuildContext context, StudyPlannerState state) {
    final cs = context.colorScheme;
    final tt = context.textTheme;
    final inactivePlans =
        state.plans.where((p) => !p.isActive).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Study Planner')),
      body: state.isLoading && state.plans.isEmpty
          ? const Center(child: AppLoadingSpinner())
          : state.error != null && state.plans.isEmpty
              ? AppErrorState(
                  icon: Icons.error_outline_rounded,
                  title: 'Failed to Load Plans',
                  message: state.error,
                  onRetry: () =>
                      ref.read(studyPlannerProvider.notifier).loadPlans(),
                )
              : state.plans.isEmpty
                  ? AppEmptyState(
                      icon: Icons.calendar_month_outlined,
                      title: 'No Study Plans',
                      subtitle:
                          'Create a study plan or let AI suggest one for you.',
                      actionLabel: 'Create Plan',
                      onAction: () => _showCreatePlanDialog(context),
                    )
                  : ListView(
                      padding: Spacings.paddingScreen,
                      children: [
                        // AI suggest button
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: state.isSuggesting
                                ? null
                                : () {
                                    ref
                                        .read(studyPlannerProvider.notifier)
                                        .suggestPlan();
                                  },
                            icon: state.isSuggesting
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child:
                                        CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : const Icon(Icons.auto_awesome_outlined),
                            label: Text(
                              state.isSuggesting
                                  ? 'Generating...'
                                  : 'AI Suggest Plan',
                            ),
                          ),
                        ),
                        const SizedBox(height: Spacings.lg),

                        // Active plans
                        if (state.activePlans.isNotEmpty) ...[
                          _buildSectionTitle(context, 'Active Plans'),
                          const SizedBox(height: Spacings.sm),
                          ...state.activePlans.map(
                            (plan) => Padding(
                              padding:
                                  const EdgeInsets.only(bottom: Spacings.md),
                              child: _PlanCard(
                                plan: plan,
                                onTap: () {
                                  ref
                                      .read(studyPlannerProvider.notifier)
                                      .openPlan(plan.id);
                                },
                                onDelete: () {
                                  ref
                                      .read(studyPlannerProvider.notifier)
                                      .deletePlan(plan.id);
                                },
                              ),
                            ),
                          ),
                        ],

                        // Inactive plans
                        if (inactivePlans.isNotEmpty) ...[
                          const SizedBox(height: Spacings.lg),
                          _buildSectionTitle(context, 'Completed Plans'),
                          const SizedBox(height: Spacings.sm),
                          ...inactivePlans.map(
                            (plan) => Padding(
                              padding:
                                  const EdgeInsets.only(bottom: Spacings.md),
                              child: _PlanCard(
                                plan: plan,
                                onTap: () {
                                  ref
                                      .read(studyPlannerProvider.notifier)
                                      .openPlan(plan.id);
                                },
                                onDelete: () {
                                  ref
                                      .read(studyPlannerProvider.notifier)
                                      .deletePlan(plan.id);
                                },
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreatePlanDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // PLAN DETAIL
  // ═══════════════════════════════════════════════════════════════════════

  Widget _buildPlanDetail(BuildContext context, StudyPlannerState state) {
    final cs = context.colorScheme;
    final tt = context.textTheme;
    final plan = state.currentPlan!;

    return Scaffold(
      appBar: AppBar(
        title: Text(plan.title),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            ref.read(studyPlannerProvider.notifier).clearError();
          },
        ),
        actions: [
          if (plan.isAiSuggested)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: Spacings.sm),
              child: Chip(
                avatar: const Icon(Icons.auto_awesome, size: 16),
                label: const Text('AI Suggested'),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          // Calendar
          _buildMiniCalendar(context, state),

          const Divider(height: 1),

          // Task list for selected date
          Expanded(
            child: state.filteredTasks.isEmpty
                ? AppEmptyState(
                    icon: Icons.check_circle_outline,
                    title: 'No Tasks',
                    subtitle:
                        'No tasks for ${_formatDate(_selectedDate)}. Add one!',
                  )
                : ListView.builder(
                    padding: Spacings.paddingScreen,
                    itemCount: state.filteredTasks.length,
                    itemBuilder: (context, index) {
                      final task = state.filteredTasks[index];
                      return Padding(
                        padding:
                            const EdgeInsets.only(bottom: Spacings.md),
                        child: _TaskCard(
                          task: task,
                          onToggleStatus: () {
                            final newStatus =
                                task.status == StudyTaskStatus.completed
                                    ? StudyTaskStatus.pending
                                    : StudyTaskStatus.completed;
                            ref
                                .read(studyPlannerProvider.notifier)
                                .updateTaskStatus(
                                  task.id,
                                  status: newStatus,
                                  completionPct:
                                      newStatus ==
                                              StudyTaskStatus.completed
                                          ? 100
                                          : 0,
                                );
                          },
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreateTaskDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // MINI CALENDAR
  // ═══════════════════════════════════════════════════════════════════════

  Widget _buildMiniCalendar(BuildContext context, StudyPlannerState state) {
    final cs = context.colorScheme;
    final tt = context.textTheme;

    return Padding(
      padding: const EdgeInsets.all(Spacings.lg),
      child: Column(
        children: [
          // Month navigation
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: () {
                  setState(() {
                    _focusedMonth = DateTime(
                      _focusedMonth.year,
                      _focusedMonth.month - 1,
                    );
                  });
                },
              ),
              Text(
                '${_monthName(_focusedMonth.month)} ${_focusedMonth.year}',
                style: tt.titleMedium?.copyWith(
                  fontWeight: AppTypography.wSemiBold,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: () {
                  setState(() {
                    _focusedMonth = DateTime(
                      _focusedMonth.year,
                      _focusedMonth.month + 1,
                    );
                  });
                },
              ),
            ],
          ),

          // Day headers
          Row(
            children: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun']
                .map((day) => Expanded(
                      child: Center(
                        child: Text(
                          day,
                          style: tt.labelSmall?.copyWith(
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ))
                .toList(),
          ),
          const SizedBox(height: Spacings.sm),

          // Calendar grid
          _buildCalendarGrid(context, state),
        ],
      ),
    );
  }

  Widget _buildCalendarGrid(BuildContext context, StudyPlannerState state) {
    final cs = context.colorScheme;
    final firstDay = DateTime(_focusedMonth.year, _focusedMonth.month, 1);
    final lastDay = DateTime(_focusedMonth.year, _focusedMonth.month + 1, 0);
    final startWeekday = (firstDay.weekday - 1) % 7; // Monday = 0

    final days = <DateTime?>[];
    for (var i = 0; i < startWeekday; i++) {
      days.add(null);
    }
    for (var day = 1; day <= lastDay.day; day++) {
      days.add(DateTime(_focusedMonth.year, _focusedMonth.month, day));
    }

    return Wrap(
      spacing: 0,
      runSpacing: Spacings.xs,
      children: days.map((date) {
        if (date == null) {
          return SizedBox(
            width: (context.width - Spacings.xl * 2) / 7,
            height: 36,
          );
        }

        final isSelected = date.year == _selectedDate.year &&
            date.month == _selectedDate.month &&
            date.day == _selectedDate.day;
        final isToday = date.year == DateTime.now().year &&
            date.month == DateTime.now().month &&
            date.day == DateTime.now().day;

        final hasTasks = state.tasks.any((t) =>
            t.scheduledDate.year == date.year &&
            t.scheduledDate.month == date.month &&
            t.scheduledDate.day == date.day);

        return GestureDetector(
          onTap: () {
            setState(() => _selectedDate = date);
            ref.read(studyPlannerProvider.notifier).selectDate(date);
          },
          child: SizedBox(
            width: (context.width - Spacings.xl * 2) / 7,
            height: 36,
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected
                    ? cs.primary
                    : isToday
                        ? cs.primaryContainer
                        : null,
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Text(
                    '${date.day}',
                    style: context.textTheme.bodySmall?.copyWith(
                      color: isSelected
                          ? cs.onPrimary
                          : isToday
                              ? cs.primary
                              : cs.onSurface,
                      fontWeight: isSelected || isToday
                          ? AppTypography.wSemiBold
                          : null,
                    ),
                  ),
                  if (hasTasks && !isSelected)
                    Positioned(
                      bottom: 2,
                      child: Container(
                        width: 4,
                        height: 4,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isSelected
                              ? cs.onPrimary
                              : cs.primary,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
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

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  String _monthName(int month) {
    const months = [
      '', 'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return months[month];
  }

  void _showCreatePlanDialog(BuildContext context) {
    final titleController = TextEditingController();
    StudyPlanFrequency frequency = StudyPlanFrequency.daily;
    DateTime startDate = DateTime.now();
    DateTime? endDate;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Create Study Plan'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: titleController,
                    decoration: const InputDecoration(
                      labelText: 'Plan Title',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: Spacings.md),
                  DropdownButtonFormField<StudyPlanFrequency>(
                    value: frequency,
                    decoration: const InputDecoration(
                      labelText: 'Frequency',
                      border: OutlineInputBorder(),
                    ),
                    items: StudyPlanFrequency.values
                        .map((f) => DropdownMenuItem(
                              value: f,
                              child: Text(f.label),
                            ))
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setDialogState(() => frequency = value);
                      }
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () {
                    Navigator.pop(dialogContext);
                    ref.read(studyPlannerProvider.notifier).createPlan(
                      title: titleController.text.trim().isEmpty
                          ? 'New Study Plan'
                          : titleController.text.trim(),
                      frequency: frequency,
                      startDate: startDate,
                      endDate: endDate,
                    );
                  },
                  child: const Text('Create'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showCreateTaskDialog(BuildContext context) {
    final titleController = TextEditingController();
    String? selectedSubject;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Add Task'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: titleController,
                    decoration: const InputDecoration(
                      labelText: 'Task Title',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: Spacings.md),
                  DropdownButtonFormField<String>(
                    value: selectedSubject,
                    decoration: const InputDecoration(
                      labelText: 'Subject (optional)',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(
                          value: 'math', child: Text('Mathematics')),
                      DropdownMenuItem(
                          value: 'english', child: Text('English')),
                      DropdownMenuItem(
                          value: 'biology', child: Text('Biology')),
                    ],
                    onChanged: (value) {
                      setDialogState(() => selectedSubject = value);
                    },
                  ),
                  const SizedBox(height: Spacings.md),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.calendar_today),
                    title: Text('Scheduled: ${_formatDate(_selectedDate)}'),
                    dense: true,
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () {
                    Navigator.pop(dialogContext);
                    ref.read(studyPlannerProvider.notifier).createTask(
                      title: titleController.text.trim(),
                      subjectId: selectedSubject,
                      scheduledDate: _selectedDate,
                    );
                  },
                  child: const Text('Add'),
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
// PRIVATE HELPER WIDGETS
// ═══════════════════════════════════════════════════════════════════════

class _PlanCard extends StatelessWidget {
  const _PlanCard({
    required this.plan,
    required this.onTap,
    required this.onDelete,
  });

  final StudyPlanEntity plan;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;
    final tt = context.textTheme;

    final completedTasks =
        plan.tasks.where((t) => t.status == StudyTaskStatus.completed).length;
    final totalTasks = plan.tasks.length;

    return AppCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  plan.title,
                  style: tt.titleSmall?.copyWith(
                    fontWeight: AppTypography.wSemiBold,
                    color: cs.onSurface,
                  ),
                ),
              ),
              if (plan.isAiSuggested)
                Icon(
                  Icons.auto_awesome,
                  size: 18,
                  color: cs.primary,
                ),
              IconButton(
                icon: const Icon(Icons.delete_outline, size: 20),
                onPressed: onDelete,
              ),
            ],
          ),
          const SizedBox(height: Spacings.sm),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: Spacings.sm,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: cs.tertiaryContainer,
                  borderRadius:
                      BorderRadius.circular(Spacings.fullRadius),
                ),
                child: Text(
                  plan.frequency.label,
                  style: tt.labelSmall?.copyWith(
                    color: cs.onTertiaryContainer,
                  ),
                ),
              ),
              const SizedBox(width: Spacings.sm),
              Text(
                '${plan.startDate.day}/${plan.startDate.month}',
                style: tt.bodySmall?.copyWith(
                  color: cs.onSurfaceVariant,
                ),
              ),
              if (plan.endDate != null) ...[
                Text(
                  ' - ${plan.endDate!.day}/${plan.endDate!.month}',
                  style: tt.bodySmall?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          ),
          if (totalTasks > 0) ...[
            const SizedBox(height: Spacings.md),
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius:
                        BorderRadius.circular(Spacings.fullRadius),
                    child: LinearProgressIndicator(
                      value: completedTasks / totalTasks,
                      backgroundColor: cs.surfaceContainerHighest,
                    ),
                  ),
                ),
                const SizedBox(width: Spacings.sm),
                Text(
                  '$completedTasks/$totalTasks',
                  style: tt.bodySmall?.copyWith(
                    color: cs.onSurfaceVariant,
                    fontWeight: AppTypography.wSemiBold,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _TaskCard extends StatelessWidget {
  const _TaskCard({
    required this.task,
    required this.onToggleStatus,
  });

  final StudyTaskEntity task;
  final VoidCallback onToggleStatus;

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;
    final tt = context.textTheme;
    final isCompleted = task.status == StudyTaskStatus.completed;

    return AppCard(
      onTap: onToggleStatus,
      child: Row(
        children: [
          Checkbox(
            value: isCompleted,
            onChanged: (_) => onToggleStatus(),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(Spacings.xs),
            ),
          ),
          const SizedBox(width: Spacings.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task.title,
                  style: tt.bodyMedium?.copyWith(
                    color: isCompleted
                        ? cs.onSurfaceVariant
                        : cs.onSurface,
                    decoration: isCompleted
                        ? TextDecoration.lineThrough
                        : null,
                  ),
                ),
                if (task.subjectName != null)
                  Text(
                    task.subjectName!,
                    style: tt.bodySmall?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
          ),
          if (task.startTime != null)
            Text(
              '${task.startTime!.hour}:${task.startTime!.minute.toString().padLeft(2, '0')}',
              style: tt.bodySmall?.copyWith(
                color: cs.onSurfaceVariant,
              ),
            ),
        ],
      ),
    );
  }
}
