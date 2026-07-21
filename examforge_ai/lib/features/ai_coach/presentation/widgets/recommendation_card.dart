import 'package:flutter/material.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/themes/app_colors.dart';
import '../../domain/entities/ai_coach_entities.dart';

/// Card widget displaying an AI Coach recommendation.
///
/// Features:
/// - Title and description
/// - Priority badge (low, medium, high, urgent)
/// - Action type icon
/// - Dismiss button
/// - Tap to act on recommendation
class RecommendationCard extends StatelessWidget {
  const RecommendationCard({
    super.key,
    required this.recommendation,
    this.onDismiss,
    this.onTap,
  });

  final AiCoachRecommendation recommendation;
  final VoidCallback? onDismiss;
  final VoidCallback? onTap;

  Color _priorityColor() {
    switch (recommendation.priority) {
      case RecommendationPriority.urgent:
        return AppColors.error;
      case RecommendationPriority.high:
        return AppColors.warning;
      case RecommendationPriority.medium:
        return AppColors.info;
      case RecommendationPriority.low:
        return Colors.grey;
    }
  }

  IconData _actionIcon() {
    switch (recommendation.actionType) {
      case RecommendationActionType.studyTopic:
        return Icons.menu_book_outlined;
      case RecommendationActionType.practiceQuestion:
        return Icons.quiz_outlined;
      case RecommendationActionType.reviewMaterial:
        return Icons.replay_outlined;
      case RecommendationActionType.takeTest:
        return Icons.assignment_outlined;
      case RecommendationActionType.adjustPlan:
        return Icons.tune;
      case RecommendationActionType.motivationalBoost:
        return Icons.favorite_outline;
      case null:
        return Icons.lightbulb_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    final priorityColor = _priorityColor();

    return Container(
      width: 260,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: context.colorScheme.surface,
        border: Border.all(
          color: priorityColor.withOpacity(0.3),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header row with priority badge
                Row(
                  children: [
                    Icon(
                      _actionIcon(),
                      size: 20,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        recommendation.title,
                        style: context.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    // Dismiss button
                    if (onDismiss != null)
                      InkWell(
                        onTap: onDismiss,
                        borderRadius: BorderRadius.circular(12),
                        child: Icon(
                          Icons.close,
                          size: 16,
                          color: context.colorScheme.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),

                // Priority badge
                const SizedBox(height: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: priorityColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    recommendation.priority.label.toUpperCase(),
                    style: context.textTheme.labelSmall?.copyWith(
                      color: priorityColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 9,
                    ),
                  ),
                ),

                // Description
                if (recommendation.description != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    recommendation.description!,
                    style: context.textTheme.bodySmall?.copyWith(
                      color: context.colorScheme.onSurfaceVariant,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],

                const Spacer(),

                // Action button
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.tonal(
                    onPressed: onTap,
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      textStyle: context.textTheme.labelMedium,
                    ),
                    child: Text(
                      recommendation.actionType?.label ?? 'View Details',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
