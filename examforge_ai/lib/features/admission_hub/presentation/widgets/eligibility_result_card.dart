import 'package:flutter/material.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/themes/app_colors.dart';
import '../../domain/entities/admission_hub_entities.dart';

/// Card widget displaying the result of an admission eligibility check.
///
/// Features:
/// - Eligible / Not Eligible status badge
/// - Eligibility score percentage
/// - Checklist of criteria (JAMB score, O'Level, subject combination)
/// - Missing items list
/// - Recommendations
class EligibilityResultCard extends StatelessWidget {
  const EligibilityResultCard({super.key, required this.result});

  final EligibilityResult result;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: result.isEligible
              ? AppColors.success.withValues(alpha: 0.5)
              : AppColors.error.withValues(alpha: 0.5),
          width: 2,
        ),
        color: result.isEligible
            ? AppColors.success.withValues(alpha: 0.05)
            : AppColors.error.withValues(alpha: 0.05),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Icon(
                result.isEligible
                    ? Icons.check_circle_rounded
                    : Icons.cancel_rounded,
                color: result.isEligible ? AppColors.success : AppColors.error,
                size: 32,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      result.isEligible
                          ? 'You are Eligible!'
                          : 'Not Eligible Yet',
                      style: context.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: result.isEligible
                            ? AppColors.success
                            : AppColors.error,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Eligibility Score: ${result.eligibilityScore.toInt()}%',
                      style: context.textTheme.bodySmall?.copyWith(
                        color: context.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),

              // Score ring
              SizedBox(
                width: 56,
                height: 56,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    CircularProgressIndicator(
                      value: result.eligibilityScore / 100,
                      backgroundColor: context.colorScheme.outlineVariant,
                      color: result.isEligible
                          ? AppColors.success
                          : AppColors.error,
                      strokeWidth: 4,
                    ),
                    Center(
                      child: Text(
                        '${result.eligibilityScore.toInt()}',
                        style: context.textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: result.isEligible
                              ? AppColors.success
                              : AppColors.error,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Criteria checklist
          Text(
            'Criteria Breakdown',
            style: context.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          _CriterionTile(
            label: 'JAMB Score Requirement',
            isMet: result.jambScoreMet,
          ),
          _CriterionTile(
            label: "O'Level Requirements",
            isMet: result.oLevelRequirementsMet,
          ),
          _CriterionTile(
            label: 'Subject Combination',
            isMet: result.subjectCombinationCorrect,
          ),

          // Missing items
          if (result.missingSubjects.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              'Missing Subjects',
              style: context.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.error,
              ),
            ),
            const SizedBox(height: 4),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: result.missingSubjects.map((subject) {
                return Chip(
                  label: Text(subject),
                  avatar: Icon(Icons.close, size: 14, color: AppColors.error),
                  backgroundColor: AppColors.error.withValues(alpha: 0.1),
                  labelStyle: context.textTheme.bodySmall?.copyWith(
                    color: AppColors.error,
                  ),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  visualDensity: VisualDensity.compact,
                );
              }).toList(),
            ),
          ],

          if (result.missingOLevelGrades.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              "Missing O'Level Grades",
              style: context.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.error,
              ),
            ),
            const SizedBox(height: 4),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: result.missingOLevelGrades.map((grade) {
                return Chip(
                  label: Text(grade),
                  avatar: Icon(Icons.close, size: 14, color: AppColors.error),
                  backgroundColor: AppColors.error.withValues(alpha: 0.1),
                  labelStyle: context.textTheme.bodySmall?.copyWith(
                    color: AppColors.error,
                  ),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  visualDensity: VisualDensity.compact,
                );
              }).toList(),
            ),
          ],

          // Recommendations
          if (result.recommendations.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              'Recommendations',
              style: context.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.info,
              ),
            ),
            const SizedBox(height: 8),
            ...result.recommendations.map((rec) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.lightbulb_outline,
                        size: 16,
                        color: AppColors.info,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          rec,
                          style: context.textTheme.bodySmall,
                        ),
                      ),
                    ],
                  ),
                )),
          ],
        ],
      ),
    );
  }
}

/// Individual criterion tile with met/not-met indicator.
class _CriterionTile extends StatelessWidget {
  const _CriterionTile({required this.label, required this.isMet});

  final String label;
  final bool isMet;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(
            isMet ? Icons.check_circle : Icons.cancel,
            size: 20,
            color: isMet ? AppColors.success : AppColors.error,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: context.textTheme.bodyMedium?.copyWith(
                color: isMet
                    ? context.colorScheme.onSurface
                    : AppColors.error,
                decoration: isMet ? null : TextDecoration.lineThrough,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
