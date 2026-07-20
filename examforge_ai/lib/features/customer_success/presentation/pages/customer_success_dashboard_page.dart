import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/customer_success_provider.dart';
import 'onboarding_wizard_page.dart';
import 'help_center_page.dart';
import 'feedback_page.dart';
import 'feature_requests_page.dart';

/// Main dashboard page for the Customer Success feature.
///
/// Shows overview cards for onboarding status, help articles,
/// video tutorials, feedback, and feature requests.
class CustomerSuccessDashboardPage extends StatefulWidget {
  const CustomerSuccessDashboardPage({super.key});

  @override
  State<CustomerSuccessDashboardPage> createState() => _CustomerSuccessDashboardPageState();
}

class _CustomerSuccessDashboardPageState extends State<CustomerSuccessDashboardPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<CustomerSuccessProvider>();
      provider.loadOnboardingFlows('teacher');
      provider.loadHelpArticles();
      provider.loadVideoTutorials();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Customer Success'),
        centerTitle: true,
      ),
      body: Consumer<CustomerSuccessProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (provider.error != null) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.error_outline, size: 48, color: theme.colorScheme.error),
                  const SizedBox(height: 16),
                  Text(provider.error!, style: theme.textTheme.bodyLarge),
                  const SizedBox(height: 16),
                  ElevatedButton(onPressed: () => _refresh(provider), child: const Text('Retry')),
                ],
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: () => _refresh(provider),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text('Welcome to ExamForge AI', style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text('Get started with your learning journey', style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                const SizedBox(height: 24),
                _buildOnboardingCard(context, provider),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(child: _buildStatCard(context, 'Help Articles', '${provider.helpArticles.length}', Icons.article_outlined, Colors.teal)),
                    const SizedBox(width: 12),
                    Expanded(child: _buildStatCard(context, 'Video Tutorials', '${provider.videoTutorials.length}', Icons.play_circle_outline, Colors.orange)),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: _buildStatCard(context, 'Feedback', '${provider.feedbackSubmissions.length}', Icons.feedback_outlined, Colors.purple)),
                    const SizedBox(width: 12),
                    Expanded(child: _buildStatCard(context, 'Feature Requests', '${provider.featureRequests.length}', Icons.lightbulb_outline, Colors.amber)),
                  ],
                ),
                const SizedBox(height: 24),
                Text('Quick Actions', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 12),
                _buildActionTile(context, 'Start Onboarding', 'Complete your setup wizard', Icons.rocket_launch_outlined, () {
                  Navigator.of(context).push(MaterialPageRoute(builder: (_) => const OnboardingWizardPage()));
                }),
                _buildActionTile(context, 'Help Center', 'Browse knowledge base', Icons.help_outline, () {
                  Navigator.of(context).push(MaterialPageRoute(builder: (_) => const HelpCenterPage()));
                }),
                _buildActionTile(context, 'Submit Feedback', 'Share your thoughts', Icons.rate_review_outlined, () {
                  Navigator.of(context).push(MaterialPageRoute(builder: (_) => const FeedbackPage()));
                }),
                _buildActionTile(context, 'Feature Requests', 'Vote and suggest features', Icons.lightbulb_outline, () {
                  Navigator.of(context).push(MaterialPageRoute(builder: (_) => const FeatureRequestsPage()));
                }),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildOnboardingCard(BuildContext context, CustomerSuccessProvider provider) {
    final theme = Theme.of(context);
    final percentage = provider.onboardingCompletionPercentage;
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Icon(Icons.school_outlined, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              Text('Onboarding Progress', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
            ]),
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: percentage,
                minHeight: 8,
                backgroundColor: theme.colorScheme.surfaceContainerHighest,
              ),
            ),
            const SizedBox(height: 8),
            Text('${(percentage * 100).toInt()}% complete', style: theme.textTheme.bodySmall),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).push(MaterialPageRoute(builder: (_) => const OnboardingWizardPage()));
                },
                child: Text(percentage >= 1.0 ? 'Review Setup' : 'Continue Onboarding'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(BuildContext context, String title, String value, IconData icon, Color color) {
    final theme = Theme.of(context);
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(value, style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
            Text(title, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          ],
        ),
      ),
    );
  }

  Widget _buildActionTile(BuildContext context, String title, String subtitle, IconData icon, VoidCallback onTap) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }

  Future<void> _refresh(CustomerSuccessProvider provider) async {
    await Future.wait([
      provider.loadOnboardingFlows('teacher'),
      provider.loadHelpArticles(),
      provider.loadVideoTutorials(),
    ]);
  }
}
