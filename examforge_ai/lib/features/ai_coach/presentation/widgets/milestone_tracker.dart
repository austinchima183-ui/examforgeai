import 'package:flutter/material.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/themes/app_colors.dart';

/// Milestone tracker widget showing study plan progress.
///
/// Features:
/// - Vertical timeline of milestones
/// - Completion status for each milestone
/// - Progress percentage
/// - Date labels
/// - Current milestone highlight
class MilestoneTracker extends StatelessWidget {
  const MilestoneTracker({
    super.key,
    required this.milestones,
  });

  final List<Map<String, dynamic>> milestones;

  @override
  Widget build(BuildContext context) {
    if (milestones.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          'No milestones yet. Generate a study plan to see milestones.',
          style: context.textTheme.bodySmall?.copyWith(
            color: context.colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }

    // Calculate progress
    final completedCount = milestones
        .where((m) => m['is_completed'] as bool? ?? false)
        .length;
    final progressPct =
        milestones.isEmpty ? 0.0 : (completedCount / milestones.length) * 100;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Progress header
        Row(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progressPct / 100,
                  backgroundColor:
                      context.colorScheme.outlineVariant.withValues(alpha: 0.3),
                  color: AppColors.primary,
                  minHeight: 8,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              '${progressPct.toInt()}%',
              style: context.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Milestone timeline
        ...milestones.asMap().entries.map((entry) {
          final index = entry.key;
          final milestone = entry.value;
          final isCompleted = milestone['is_completed'] as bool? ?? false;
          final isCurrent = !isCompleted &&
              (index == 0 ||
                  (milestones[index - 1]['is_completed'] as bool? ?? false));
          final title = milestone['title'] as String? ?? 'Milestone ${index + 1}';
          final description = milestone['description'] as String?;
          final dateStr = milestone['target_date'] as String?;

          return _MilestoneTile(
            title: title,
            description: description,
            dateStr: dateStr,
            isCompleted: isCompleted,
            isCurrent: isCurrent,
            isLast: index == milestones.length - 1,
          );
        }),
      ],
    );
  }
}

/// Individual milestone tile in the timeline.
class _MilestoneTile extends StatelessWidget {
  const _MilestoneTile({
    required this.title,
    this.description,
    this.dateStr,
    required this.isCompleted,
    required this.isCurrent,
    required this.isLast,
  });

  final String title;
  final String? description;
  final String? dateStr;
  final bool isCompleted;
  final bool isCurrent;
  final bool isLast;

  Color _statusColor(BuildContext context) {
    if (isCompleted) return AppColors.success;
    if (isCurrent) return AppColors.primary;
    return context.colorScheme.onSurfaceVariant;
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(context);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline indicator
          SizedBox(
            width: 32,
            child: Column(
              children: [
                // Circle
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isCompleted
                        ? AppColors.success
                        : isCurrent
                            ? AppColors.primary
                            : Colors.transparent,
                    border: Border.all(
                      color: statusColor,
                      width: 2,
                    ),
                  ),
                  child: isCompleted
                      ? const Icon(
                          Icons.check,
                          size: 14,
                          color: Colors.white,
                        )
                      : isCurrent
                          ? Container(
                              margin: const EdgeInsets.all(6),
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                            )
                          : null,
                ),

                // Connecting line
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: isCompleted
                          ? AppColors.success
                          : context.colorScheme.outlineVariant
                              .withValues(alpha: 0.5),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),

          // Content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: context.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: isCompleted
                          ? context.colorScheme.onSurfaceVariant
                          : context.colorScheme.onSurface,
                      decoration: isCompleted ? TextDecoration.lineThrough : null,
                    ),
                  ),
                  if (description != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      description!,
                      style: context.textTheme.bodySmall?.copyWith(
                        color: context.colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  if (dateStr != null) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.schedule,
                          size: 12,
                          color: statusColor,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          dateStr!,
                          style: context.textTheme.labelSmall?.copyWith(
                            color: statusColor,
                          ),
                        ),
                      ],
                    ),
                  ],
                  if (isCurrent) ...[
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'IN PROGRESS',
                        style: context.textTheme.labelSmall?.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 9,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
