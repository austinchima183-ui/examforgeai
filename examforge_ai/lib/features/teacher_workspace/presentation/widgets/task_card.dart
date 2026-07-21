import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/themes/app_colors.dart';
import '../../../../core/themes/spacings.dart';
import '../../domain/entities/workspace_expansion_entities.dart';

/// A reusable card widget for displaying a task.
///
/// Shows the task title, description preview, priority dot, due date,
/// category chip, subtask progress, and an optional completion checkbox.
/// Supports swipe-to-delete when [onDelete] is provided.
class TaskCard extends ConsumerWidget {
  /// The task to display.
  final TaskEntity task;

  /// Callback when the card is tapped.
  final VoidCallback? onTap;

  /// Callback when the completion checkbox changes.
  final ValueChanged<bool>? onCompletionChanged;

  /// Callback when the user requests deletion.
  final VoidCallback? onDelete;

  const TaskCard({
    super.key,
    required this.task,
    this.onTap,
    this.onCompletionChanged,
    this.onDelete,
  });

  // ─── Priority Colors ──────────────────────────────────────────────────

  static const Map<TaskPriority, Color> _priorityColors = {
    TaskPriority.low: AppColors.success,
    TaskPriority.medium: AppColors.warning,
    TaskPriority.high: Color(0xFFF97316), // Orange 500
    TaskPriority.urgent: AppColors.error,
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isCompleted = task.status == TaskStatus.completed;
    final isOverdue = task.dueDate != null &&
        task.dueDate!.isBefore(DateTime.now()) &&
        !isCompleted;

    return Dismissible(
      key: ValueKey(task.id),
      direction: onDelete != null
          ? DismissDirection.endToStart
          : DismissDirection.none,
      confirmDismiss: (_) async {
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Delete Task'),
            content: Text('Are you sure you want to delete "${task.title}"?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.error,
                ),
                child: const Text('Delete'),
              ),
            ],
          ),
        );
        return confirmed ?? false;
      },
      onDismissed: (_) => onDelete?.call(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: Spacings.xl),
        decoration: BoxDecoration(
          color: AppColors.error.withOpacity(0.1),
          borderRadius: Spacings.borderRadiusMd,
        ),
        child: Icon(Icons.delete, color: AppColors.error),
      ),
      child: _buildCard(context, isCompleted, isOverdue),
    );
  }

  // ─── Card ─────────────────────────────────────────────────────────────

  Widget _buildCard(BuildContext context, bool isCompleted, bool isOverdue) {
    final colorScheme = context.colorScheme;

    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: Spacings.elevationNone,
      shape: RoundedRectangleBorder(
        borderRadius: Spacings.borderRadiusMd,
        side: BorderSide(
          color: isOverdue
              ? AppColors.error.withOpacity(0.5)
              : colorScheme.outlineVariant.withOpacity(0.5),
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: Spacings.borderRadiusMd,
        child: Padding(
          padding: Spacings.paddingCard,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Checkbox ─────────────────────────────────────────────
              if (onCompletionChanged != null)
                Padding(
                  padding: const EdgeInsets.only(right: Spacings.sm, top: 2),
                  child: SizedBox(
                    width: Spacings.mdIcon + 4,
                    height: Spacings.mdIcon + 4,
                    child: Checkbox(
                      value: isCompleted,
                      onChanged: (value) =>
                          onCompletionChanged?.call(value ?? false),
                      shape: RoundedRectangleBorder(
                        borderRadius: Spacings.borderRadiusSm,
                      ),
                    ),
                  ),
                ),

              // ── Priority Dot ─────────────────────────────────────────
              Container(
                width: 4,
                height: 40,
                margin: const EdgeInsets.only(right: Spacings.md, top: 2),
                decoration: BoxDecoration(
                  color: _priorityColors[task.priority] ?? colorScheme.primary,
                  borderRadius: Spacings.borderRadiusSm,
                ),
              ),

              // ── Content ──────────────────────────────────────────────
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title row
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            task.title,
                            style: context.textTheme.titleSmall?.copyWith(
                              decoration:
                                  isCompleted ? TextDecoration.lineThrough : null,
                              color: isCompleted
                                  ? colorScheme.onSurfaceVariant
                                  : colorScheme.onSurface,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),

                    // Description preview
                    if (task.description != null &&
                        task.description!.isNotEmpty) ...[
                      const SizedBox(height: Spacings.xs),
                      Text(
                        task.description!,
                        style: context.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],

                    const SizedBox(height: Spacings.sm),

                    // Bottom row: category, due date, subtask progress
                    Row(
                      children: [
                        // Category chip
                        _CategoryChip(category: task.category),

                        const SizedBox(width: Spacings.sm),

                        // Due date
                        if (task.dueDate != null)
                          _DueDateChip(
                            dueDate: task.dueDate!,
                            isOverdue: isOverdue,
                            isCompleted: isCompleted,
                          ),

                        const Spacer(),

                        // Subtask progress
                        if (task.subtasks.isNotEmpty)
                          _SubtaskProgress(subtasks: task.subtasks),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// PRIVATE: Category Chip
// ═══════════════════════════════════════════════════════════════════════

class _CategoryChip extends StatelessWidget {
  final TaskCategory category;

  const _CategoryChip({required this.category});

  static const Map<TaskCategory, IconData> _categoryIcons = {
    TaskCategory.lesson: Icons.school,
    TaskCategory.grading: Icons.grade,
    TaskCategory.meeting: Icons.groups,
    TaskCategory.admin: Icons.admin_panel_settings,
    TaskCategory.personal: Icons.person,
    TaskCategory.general: Icons.label,
  };

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Spacings.sm,
        vertical: Spacings.xs,
      ),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withOpacity(0.5),
        borderRadius: Spacings.borderRadiusSm,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _categoryIcons[category] ?? Icons.label,
            size: Spacings.smIcon - 2,
            color: colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: Spacings.xs),
          Text(
            category.label,
            style: context.textTheme.labelSmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// PRIVATE: Due Date Chip
// ═══════════════════════════════════════════════════════════════════════

class _DueDateChip extends StatelessWidget {
  final DateTime dueDate;
  final bool isOverdue;
  final bool isCompleted;

  const _DueDateChip({
    required this.dueDate,
    required this.isOverdue,
    required this.isCompleted,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    final textColor = isOverdue
        ? AppColors.error
        : isCompleted
            ? AppColors.success
            : colorScheme.onSurfaceVariant;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          isOverdue ? Icons.warning_amber_rounded : Icons.schedule,
          size: Spacings.smIcon - 2,
          color: textColor,
        ),
        const SizedBox(width: Spacings.xs),
        Text(
          _formatDate(dueDate),
          style: context.textTheme.labelSmall?.copyWith(
            color: textColor,
            fontWeight: isOverdue ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(date.year, date.month, date.day);
    final diff = target.difference(today).inDays;

    if (diff == 0) return 'Today';
    if (diff == 1) return 'Tomorrow';
    if (diff == -1) return 'Yesterday';
    if (diff > 0 && diff <= 7) return 'In $diff days';
    return '${date.day}/${date.month}/${date.year}';
  }
}

// ═══════════════════════════════════════════════════════════════════════
// PRIVATE: Subtask Progress
// ═══════════════════════════════════════════════════════════════════════

class _SubtaskProgress extends StatelessWidget {
  final List<SubtaskEntity> subtasks;

  const _SubtaskProgress({required this.subtasks});

  @override
  Widget build(BuildContext context) {
    final completed = subtasks.where((s) => s.isCompleted).length;
    final total = subtasks.length;
    final progress = total > 0 ? completed / total : 0.0;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 32,
          height: 4,
          child: ClipRRect(
            borderRadius: Spacings.borderRadiusFull,
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor:
                  context.colorScheme.surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation<Color>(
                progress >= 1.0 ? AppColors.success : context.colorScheme.primary,
              ),
            ),
          ),
        ),
        const SizedBox(width: Spacings.xs),
        Text(
          '$completed/$total',
          style: context.textTheme.labelSmall?.copyWith(
            color: context.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
