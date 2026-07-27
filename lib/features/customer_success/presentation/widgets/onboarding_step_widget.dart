import 'package:flutter/material.dart';
import '../../domain/entities/customer_success_entities.dart';

/// Widget that renders a single onboarding step with actions.
///
/// Displays the step title, description, content, and
/// complete/skip action buttons.
class OnboardingStepWidget extends StatelessWidget {
  const OnboardingStepWidget({
    super.key,
    required this.flow,
    this.progress,
    required this.onComplete,
    this.onSkip,
  });

  final OnboardingFlow flow;
  final OnboardingProgress? progress;
  final VoidCallback onComplete;
  final VoidCallback? onSkip;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isCompleted = progress?.isCompleted ?? false;
    final isSkipped = progress?.skippedAt != null;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: _getStepColor().withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _getStepIcon(),
                size: 40,
                color: _getStepColor(),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Center(
            child: Text(
              flow.title,
              style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 12),
          Center(
            child: Text(
              flow.description,
              style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
          ),
          if (flow.content.isNotEmpty) ...[
            const SizedBox(height: 24),
            _buildContentSection(theme),
          ],
          if (flow.actionRequired) ...[
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.tertiaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, size: 20, color: theme.colorScheme.tertiary),
                  const SizedBox(width: 8),
                  Expanded(child: Text('Action required to complete this step', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onTertiaryContainer))),
                ],
              ),
            ),
          ],
          const SizedBox(height: 32),
          if (isCompleted)
            Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check_circle, color: Colors.green.shade600),
                  const SizedBox(width: 8),
                  Text('Completed', style: theme.textTheme.titleMedium?.copyWith(color: Colors.green.shade600, fontWeight: FontWeight.w600)),
                ],
              ),
            )
          else if (isSkipped)
            Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.skip_next, color: Colors.orange.shade600),
                  const SizedBox(width: 8),
                  Text('Skipped', style: theme.textTheme.titleMedium?.copyWith(color: Colors.orange.shade600)),
                ],
              ),
            )
          else ...[
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onComplete,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Complete Step'),
              ),
            ),
            if (onSkip != null) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: onSkip,
                  child: const Text('Skip for now'),
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildContentSection(ThemeData theme) {
    final tips = flow.content['tips'] as List?;
    final links = flow.content['links'] as List?;
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (tips != null && tips.isNotEmpty) ...[
              Text('Tips', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              ...tips.map((tip) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('• '),
                    Expanded(child: Text(tip.toString(), style: theme.textTheme.bodyMedium)),
                  ],
                ),
              ),),
            ],
            if (links != null && links.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text('Useful Links', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              ...links.map((link) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: InkWell(
                  onTap: () {},
                  child: Row(children: [
                    const Icon(Icons.open_in_new, size: 16),
                    const SizedBox(width: 4),
                    Text(link.toString(), style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.primary)),
                  ],),
                ),
              ),),
            ],
          ],
        ),
      ),
    );
  }

  Color _getStepColor() {
    switch (flow.stepType) {
      case OnboardingStepType.welcome: return Colors.blue;
      case OnboardingStepType.roleSelection: return Colors.purple;
      case OnboardingStepType.schoolSetup: return Colors.teal;
      case OnboardingStepType.subjectConfig: return Colors.orange;
      case OnboardingStepType.featureTour: return Colors.indigo;
      case OnboardingStepType.firstContent: return Colors.green;
      case OnboardingStepType.complete: return Colors.amber;
    }
  }

  IconData _getStepIcon() {
    switch (flow.stepType) {
      case OnboardingStepType.welcome: return Icons.waving_hand;
      case OnboardingStepType.roleSelection: return Icons.person_outline;
      case OnboardingStepType.schoolSetup: return Icons.school_outlined;
      case OnboardingStepType.subjectConfig: return Icons.book_outlined;
      case OnboardingStepType.featureTour: return Icons.explore_outlined;
      case OnboardingStepType.firstContent: return Icons.create_outlined;
      case OnboardingStepType.complete: return Icons.celebration;
    }
  }
}
