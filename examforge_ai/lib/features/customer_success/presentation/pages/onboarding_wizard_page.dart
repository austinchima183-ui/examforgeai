import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/customer_success_entities.dart';
import '../providers/customer_success_provider.dart';
import '../widgets/onboarding_step_widget.dart';

/// Step-by-step onboarding wizard page.
///
/// Guides users through the onboarding flow with interactive steps.
class OnboardingWizardPage extends StatefulWidget {
  const OnboardingWizardPage({super.key});

  @override
  State<OnboardingWizardPage> createState() => _OnboardingWizardPageState();
}

class _OnboardingWizardPageState extends State<OnboardingWizardPage> {
  final PageController _pageController = PageController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<CustomerSuccessProvider>();
      if (provider.onboardingFlows.isEmpty) {
        provider.loadOnboardingFlows('teacher');
      }
      provider.loadOnboardingProgress('current-user');
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Getting Started'),
        centerTitle: true,
      ),
      body: Consumer<CustomerSuccessProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && provider.onboardingFlows.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          final flows = provider.onboardingFlows;
          if (flows.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check_circle_outline, size: 64, color: Colors.green.shade400),
                  const SizedBox(height: 16),
                  Text('All caught up!', style: theme.textTheme.headlineSmall),
                  const SizedBox(height: 8),
                  Text('No onboarding steps remaining.', style: theme.textTheme.bodyMedium),
                ],
              ),
            );
          }
          final currentStep = provider.currentOnboardingStep;
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: List.generate(flows.length, (index) {
                    final progress = provider.onboardingProgress.where((p) => p.onboardingFlowId == flows[index].id).firstOrNull;
                    final isCompleted = progress?.isCompleted ?? false;
                    final isSkipped = progress?.skippedAt != null;
                    final isCurrent = index == currentStep;
                    return Expanded(
                      child: Container(
                        height: 4,
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        decoration: BoxDecoration(
                          color: isCompleted || isSkipped
                              ? Colors.green
                              : isCurrent
                                  ? theme.colorScheme.primary
                                  : theme.colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    );
                  }),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Step ${currentStep + 1} of ${flows.length}',
                      style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                    ),
                    Text(
                      '${(provider.onboardingCompletionPercentage * 100).toInt()}%',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: flows.length,
                  onPageChanged: (index) {
                    provider.setCurrentOnboardingStep(index);
                  },
                  itemBuilder: (context, index) {
                    final flow = flows[index];
                    final progress = provider.onboardingProgress.where((p) => p.onboardingFlowId == flow.id).firstOrNull;
                    return OnboardingStepWidget(
                      flow: flow,
                      progress: progress,
                      onComplete: () => _handleComplete(provider, flow.id),
                      onSkip: flow.isSkippable ? () => _handleSkip(provider, flow.id) : null,
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _handleComplete(CustomerSuccessProvider provider, String flowId) async {
    await provider.completeStep('current-user', flowId);
    _advancePage(provider);
  }

  Future<void> _handleSkip(CustomerSuccessProvider provider, String flowId) async {
    await provider.skipStep('current-user', flowId);
    _advancePage(provider);
  }

  void _advancePage(CustomerSuccessProvider provider) {
    if (provider.currentOnboardingStep < provider.onboardingFlows.length) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Onboarding complete! Welcome to ExamForge AI.')),
      );
      Navigator.of(context).pop();
    }
  }
}
