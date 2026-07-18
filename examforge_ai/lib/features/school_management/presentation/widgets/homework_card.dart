import 'package:flutter/material.dart';
import '../../domain/entities/school_management_entities.dart';

class HomeworkCard extends StatelessWidget {
  const HomeworkCard({
    super.key,
    required this.homework,
    required this.onTap,
  });

  final HomeworkEntity homework;
  final VoidCallback onTap;

  Color _statusColor(HomeworkStatus status) {
    switch (status) {
      case HomeworkStatus.draft:
        return Colors.grey;
      case HomeworkStatus.published:
        return Colors.blue;
      case HomeworkStatus.closed:
        return Colors.orange;
      case HomeworkStatus.graded:
        return Colors.green;
    }
  }

  String _formatDeadline(DateTime? deadline) {
    if (deadline == null) return 'No deadline';
    final now = DateTime.now();
    final diff = deadline.difference(now);
    if (diff.isNegative) return 'Overdue';
    if (diff.inDays == 0) return 'Due today';
    if (diff.inDays == 1) return 'Due tomorrow';
    return 'Due in ${diff.inDays} days';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isOverdue = homework.deadline != null && homework.deadline!.isBefore(DateTime.now());

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(child: Text(homework.title, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis)),
                  Chip(
                    label: Text(homework.status.label, style: TextStyle(fontSize: 10, color: _statusColor(homework.status))),
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  if (homework.subjectName != null)
                    Chip(
                      label: Text(homework.subjectName!, style: const TextStyle(fontSize: 10)),
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.zero,
                    ),
                  const SizedBox(width: 8),
                  if (homework.className != null) ...[
                    Icon(Icons.class_outlined, size: 14, color: theme.colorScheme.onSurfaceVariant),
                    const SizedBox(width: 2),
                    Text(homework.className!, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline)),
                  ],
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Icon(isOverdue ? Icons.warning_amber : Icons.schedule, size: 14, color: isOverdue ? Colors.red : theme.colorScheme.onSurfaceVariant),
                  const SizedBox(width: 4),
                  Text(_formatDeadline(homework.deadline), style: theme.textTheme.bodySmall?.copyWith(color: isOverdue ? Colors.red : theme.colorScheme.outline)),
                  const Spacer(),
                  Icon(Icons.assignment_turned_in_outlined, size: 14, color: theme.colorScheme.onSurfaceVariant),
                  const SizedBox(width: 4),
                  Text('${homework.submissionCount ?? homework.submissions.length} submitted', style: theme.textTheme.labelSmall),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
