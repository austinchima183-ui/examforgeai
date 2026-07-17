import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/themes/app_colors.dart';
import '../../../../core/themes/app_typography.dart';
import '../../../../core/themes/spacings.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../shared/widgets/widgets.dart';
import '../providers/student_portal_providers.dart';
import '../../domain/entities/student_portal_entities.dart';

/// Student goals page with progress tracking.
///
/// Features:
/// - Goal list with progress bars
/// - Create goal dialog: Title, Subject, Target value, Deadline, Priority
/// - Goal detail: Progress visualization, Update progress, Mark as achieved
/// - Filter by status
class GoalsPage extends ConsumerStatefulWidget {
  const GoalsPage({super.key});

  @override
  ConsumerState<GoalsPage> createState() => _GoalsPageState();
}

class _GoalsPageState extends ConsumerState<GoalsPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(goalsProvider.notifier).loadGoals();
    });
  }

  @override
  Widget build(BuildContext context) {
    final goalsState = ref.watch(goalsProvider);
    final cs = context.colorScheme;
    final tt = context.textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Goals'),
        actions: [
          PopupMenuButton<GoalStatus?>(
            onSelected: (status) {
              ref.read(goalsProvider.notifier).filterByStatus(status);
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: null, child: Text('All Goals')),
              ...GoalStatus.values.map(
                (status) => PopupMenuItem(
                  value: status,
                  child: Text(status.label),
                ),
              ),
            ],
            icon: const Icon(Icons.filter_list),
          ),
        ],
      ),
      body: goalsState.isLoading && goalsState.goals.isEmpty
          ? const Center(child: AppLoadingSpinner())
          : goalsState.error != null && goalsState.goals.isEmpty
              ? AppErrorState(
                  icon: Icons.error_outline_rounded,
                  title: 'Failed to Load Goals',
                  message: goalsState.error,
                  onRetry: () =>
                      ref.read(goalsProvider.notifier).loadGoals(),
                )
              : goalsState.filteredGoals.isEmpty
                  ? AppEmptyState(
                      icon: Icons.flag_outlined,
                      title: 'No Goals',
                      subtitle: goalsState.filterStatus != null
                          ? 'No goals with status "${goalsState.filterStatus!.label}".'
                          : 'Set learning goals to track your progress!',
                      actionLabel: 'Create Goal',
                      onAction: () => _showCreateGoalDialog(context),
                    )
                  : Column(
                      children: [
                        // Summary cards
                        if (goalsState.goals.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.all(Spacings.lg),
                            color: cs.surfaceContainerLow,
                            child: Row(
                              children: [
                                Expanded(
                                  child: _SummaryMiniCard(
                                    label: 'Active',
                                    value:
                                        '${goalsState.activeGoalCount}',
                                    icon: Icons.flag_outlined,
                                    color: AppColors.info,
                                  ),
                                ),
                                const SizedBox(width: Spacings.md),
                                Expanded(
                                  child: _SummaryMiniCard(
                                    label: 'Achieved',
                                    value:
                                        '${goalsState.achievedGoalCount}',
                                    icon: Icons.emoji_events_outlined,
                                    color: AppColors.success,
                                  ),
                                ),
                                const SizedBox(width: Spacings.md),
                                Expanded(
                                  child: _SummaryMiniCard(
                                    label: 'Avg Progress',
                                    value:
                                        '${goalsState.averageProgress.toStringAsFixed(0)}%',
                                    icon: Icons.trending_up_outlined,
                                    color: AppColors.warning,
                                  ),
                                ),
                              ],
                            ),
                          ),

                        // Goal list
                        Expanded(
                          child: ListView.builder(
                            padding: Spacings.paddingScreen,
                            itemCount: goalsState.filteredGoals.length,
                            itemBuilder: (context, index) {
                              final goal = goalsState.filteredGoals[index];
                              return Padding(
                                padding:
                                    const EdgeInsets.only(bottom: Spacings.md),
                                child: _GoalCard(
                                  goal: goal,
                                  onUpdateProgress: () =>
                                      _showUpdateProgressDialog(
                                          context, goal),
                                  onMarkAchieved: () {
                                    ref
                                        .read(goalsProvider.notifier)
                                        .updateGoal(
                                          goal.id,
                                          status: GoalStatus.achieved,
                                        );
                                  },
                                  onDelete: () {
                                    ref
                                        .read(goalsProvider.notifier)
                                        .deleteGoal(goal.id);
                                  },
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreateGoalDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  // ─── Dialogs ────────────────────────────────────────────────────────

  void _showCreateGoalDialog(BuildContext context) {
    final titleController = TextEditingController();
    final targetController = TextEditingController();
    String? selectedSubject;
    GoalPriority priority = GoalPriority.medium;
    DateTime? deadline;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Create Goal'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: titleController,
                      decoration: const InputDecoration(
                        labelText: 'Goal Title',
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
                        DropdownMenuItem(
                            value: 'physics', child: Text('Physics')),
                      ],
                      onChanged: (value) {
                        setDialogState(() => selectedSubject = value);
                      },
                    ),
                    const SizedBox(height: Spacings.md),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: targetController,
                            decoration: const InputDecoration(
                              labelText: 'Target',
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        const SizedBox(width: Spacings.md),
                        SizedBox(
                          width: 80,
                          child: DropdownButtonFormField<String>(
                            value: '%',
                            items: const [
                              DropdownMenuItem(value: '%', child: Text('%')),
                              DropdownMenuItem(
                                  value: 'pts', child: Text('pts')),
                              DropdownMenuItem(
                                  value: 'hrs', child: Text('hrs')),
                            ],
                            onChanged: (value) {},
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: Spacings.md),
                    DropdownButtonFormField<GoalPriority>(
                      value: priority,
                      decoration: const InputDecoration(
                        labelText: 'Priority',
                        border: OutlineInputBorder(),
                      ),
                      items: GoalPriority.values
                          .map((p) => DropdownMenuItem(
                                value: p,
                                child: Text(p.label),
                              ))
                          .toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setDialogState(() => priority = value);
                        }
                      },
                    ),
                    const SizedBox(height: Spacings.md),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.calendar_today),
                      title: Text(deadline != null
                          ? 'Deadline: ${deadline!.day}/${deadline!.month}/${deadline!.year}'
                          : 'Set Deadline (optional)'),
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now().add(
                              const Duration(days: 30)),
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now()
                              .add(const Duration(days: 365)),
                        );
                        if (picked != null) {
                          setDialogState(() => deadline = picked);
                        }
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () {
                    Navigator.pop(dialogContext);
                    ref.read(goalsProvider.notifier).createGoal(
                      title: titleController.text.trim().isEmpty
                          ? 'New Goal'
                          : titleController.text.trim(),
                      subjectId: selectedSubject,
                      targetValue: targetController.text.trim().isEmpty
                          ? null
                          : double.tryParse(
                              targetController.text.trim()),
                      priority: priority,
                      deadline: deadline,
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

  void _showUpdateProgressDialog(
      BuildContext context, StudentGoalEntity goal) {
    final controller = TextEditingController(
      text: goal.currentValue.toStringAsFixed(1),
    );

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text('Update: ${goal.title}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Current: ${goal.currentValue} / ${goal.targetValue ?? '?'} ${goal.unit}',
              ),
              const SizedBox(height: Spacings.md),
              TextField(
                controller: controller,
                decoration: InputDecoration(
                  labelText: 'New Value (${goal.unit})',
                  border: const OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
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
                final value = double.tryParse(controller.text.trim());
                if (value != null) {
                  ref.read(goalsProvider.notifier).updateGoal(
                    goal.id,
                    currentValue: value,
                    status: goal.targetValue != null &&
                            value >= goal.targetValue!
                        ? GoalStatus.achieved
                        : null,
                  );
                }
              },
              child: const Text('Update'),
            ),
          ],
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// PRIVATE HELPER WIDGETS
// ═══════════════════════════════════════════════════════════════════════

class _GoalCard extends StatelessWidget {
  const _GoalCard({
    required this.goal,
    required this.onUpdateProgress,
    required this.onMarkAchieved,
    required this.onDelete,
  });

  final StudentGoalEntity goal;
  final VoidCallback onUpdateProgress;
  final VoidCallback onMarkAchieved;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;
    final tt = context.textTheme;

    final priorityColor = switch (goal.priority) {
      GoalPriority.urgent => AppColors.error,
      GoalPriority.high => AppColors.warning,
      GoalPriority.medium => AppColors.info,
      GoalPriority.low => cs.onSurfaceVariant,
    };

    final statusColor = switch (goal.status) {
      GoalStatus.notStarted => cs.onSurfaceVariant,
      GoalStatus.inProgress => AppColors.info,
      GoalStatus.achieved => AppColors.success,
      GoalStatus.abandoned => AppColors.error,
    };

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  goal.title,
                  style: tt.titleSmall?.copyWith(
                    fontWeight: AppTypography.wSemiBold,
                    color: cs.onSurface,
                  ),
                ),
              ),
              PopupMenuButton<String>(
                onSelected: (value) {
                  switch (value) {
                    case 'update':
                      onUpdateProgress();
                    case 'achieved':
                      onMarkAchieved();
                    case 'delete':
                      onDelete;
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'update',
                    child: Text('Update Progress'),
                  ),
                  if (goal.status != GoalStatus.achieved)
                    const PopupMenuItem(
                      value: 'achieved',
                      child: Text('Mark as Achieved'),
                    ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Text('Delete'),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: Spacings.sm),

          // Status and priority badges
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: Spacings.sm,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withValues(
                    alpha: context.isDarkMode ? 0.20 : 0.12,
                  ),
                  borderRadius:
                      BorderRadius.circular(Spacings.fullRadius),
                ),
                child: Text(
                  goal.status.label,
                  style: tt.labelSmall?.copyWith(
                    color: statusColor,
                    fontWeight: AppTypography.wSemiBold,
                  ),
                ),
              ),
              const SizedBox(width: Spacings.sm),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: Spacings.sm,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: priorityColor.withValues(
                    alpha: context.isDarkMode ? 0.20 : 0.12,
                  ),
                  borderRadius:
                      BorderRadius.circular(Spacings.fullRadius),
                ),
                child: Text(
                  goal.priority.label,
                  style: tt.labelSmall?.copyWith(
                    color: priorityColor,
                    fontWeight: AppTypography.wSemiBold,
                  ),
                ),
              ),
              if (goal.subjectName != null) ...[
                const SizedBox(width: Spacings.sm),
                Text(
                  goal.subjectName!,
                  style: tt.bodySmall?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: Spacings.md),

          // Progress bar
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius:
                      BorderRadius.circular(Spacings.fullRadius),
                  child: LinearProgressIndicator(
                    value: goal.progressPct / 100,
                    backgroundColor: cs.surfaceContainerHighest,
                    color: goal.status == GoalStatus.achieved
                        ? AppColors.success
                        : cs.primary,
                    minHeight: 8,
                  ),
                ),
              ),
              const SizedBox(width: Spacings.md),
              Text(
                '${goal.progressPct.toStringAsFixed(0)}%',
                style: tt.titleSmall?.copyWith(
                  fontWeight: AppTypography.wSemiBold,
                  color: goal.status == GoalStatus.achieved
                      ? AppColors.success
                      : cs.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: Spacings.xs),
          Text(
            '${goal.currentValue} / ${goal.targetValue ?? '?'} ${goal.unit}',
            style: tt.bodySmall?.copyWith(
              color: cs.onSurfaceVariant,
            ),
          ),

          // Deadline
          if (goal.deadline != null) ...[
            const SizedBox(height: Spacings.sm),
            Row(
              children: [
                Icon(
                  Icons.calendar_today_outlined,
                  size: Spacings.smIcon,
                  color: cs.onSurfaceVariant,
                ),
                const SizedBox(width: Spacings.xs),
                Text(
                  'Due: ${goal.deadline!.day}/${goal.deadline!.month}/${goal.deadline!.year}',
                  style: tt.bodySmall?.copyWith(
                    color: cs.onSurfaceVariant,
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

class _SummaryMiniCard extends StatelessWidget {
  const _SummaryMiniCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final tt = context.textTheme;

    return Column(
      children: [
        Icon(icon, size: Spacings.mdIcon, color: color),
        const SizedBox(height: Spacings.xs),
        Text(
          value,
          style: tt.titleMedium?.copyWith(
            fontWeight: AppTypography.wBold,
            color: color,
          ),
        ),
        Text(
          label,
          style: context.textTheme.labelSmall?.copyWith(
            color: context.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
