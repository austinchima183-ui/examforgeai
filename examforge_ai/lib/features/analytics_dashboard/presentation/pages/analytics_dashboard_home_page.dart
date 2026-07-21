import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/analytics_dashboard_provider.dart';
import '../widgets/metric_card.dart';
import 'user_acquisition_page.dart';
import 'revenue_analytics_page.dart';
import 'release_notes_page.dart';

/// Main analytics dashboard page with charts and key metrics.
class AnalyticsDashboardHomePage extends StatefulWidget {
  const AnalyticsDashboardHomePage({super.key});
  @override
  State<AnalyticsDashboardHomePage> createState() => _AnalyticsDashboardHomePageState();
}

class _AnalyticsDashboardHomePageState extends State<AnalyticsDashboardHomePage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AnalyticsDashboardProvider>().loadAll();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Analytics Dashboard'), centerTitle: true),
      body: Consumer<AnalyticsDashboardProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading && provider.analyticsSummary == null) {
            return const Center(child: CircularProgressIndicator());
          }
          if (provider.error != null && provider.analyticsSummary == null) {
            return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.error_outline, size: 48, color: theme.colorScheme.error),
              const SizedBox(height: 16),
              Text(provider.error!, style: theme.textTheme.bodyLarge),
              const SizedBox(height: 16),
              ElevatedButton(onPressed: () => provider.loadAll(), child: const Text('Retry')),
            ]));
          }

          final summary = provider.analyticsSummary ?? {};
          final totalUsers = summary['total_users'] as int? ?? 0;
          final activeUsers = summary['active_users'] as int? ?? 0;
          final totalSchools = summary['total_schools'] as int? ?? 0;
          final mrr = (summary['mrr'] as num?)?.toDouble() ?? 0.0;
          final churnRate = (summary['churn_rate'] as num?)?.toDouble() ?? 0.0;
          final avgSessionDuration = (summary['avg_session_duration_minutes'] as num?)?.toDouble() ?? 0.0;
          final userGrowth = (summary['user_growth_percentage'] as num?)?.toDouble() ?? 0.0;

          return RefreshIndicator(
            onRefresh: () => provider.loadAll(),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text('Analytics Overview', style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text('Key performance metrics at a glance', style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                const SizedBox(height: 20),

                // Key Metrics Row 1
                Row(
                  children: [
                    Expanded(child: MetricCard(title: 'Total Users', value: _formatNumber(totalUsers), icon: Icons.people_outline, color: Colors.teal, trend: userGrowth)),
                    const SizedBox(width: 12),
                    Expanded(child: MetricCard(title: 'Active Users', value: _formatNumber(activeUsers), icon: Icons.person_outline, color: Colors.green, subtitle: '${totalUsers > 0 ? ((activeUsers / totalUsers) * 100).toStringAsFixed(1) : 0}% of total')),
                  ],
                ),
                const SizedBox(height: 12),

                // Key Metrics Row 2
                Row(
                  children: [
                    Expanded(child: MetricCard(title: 'Total Schools', value: _formatNumber(totalSchools), icon: Icons.school_outlined, color: Colors.indigo)),
                    const SizedBox(width: 12),
                    Expanded(child: MetricCard(title: 'MRR', value: '\$${_formatNumber(mrr.toInt())}', icon: Icons.attach_money, color: Colors.amber)),
                  ],
                ),
                const SizedBox(height: 12),

                // Key Metrics Row 3
                Row(
                  children: [
                    Expanded(child: MetricCard(title: 'Churn Rate', value: '${churnRate.toStringAsFixed(1)}%', icon: Icons.trending_down, color: churnRate > 5 ? Colors.red : Colors.green)),
                    const SizedBox(width: 12),
                    Expanded(child: MetricCard(title: 'Avg Session', value: '${avgSessionDuration.toStringAsFixed(1)}m', icon: Icons.timer_outlined, color: Colors.purple)),
                  ],
                ),
                const SizedBox(height: 24),

                // Quick Navigation
                Text('Detailed Reports', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 12),
                _buildNavTile(context, 'User Acquisition', 'Track user signups, activation & growth', Icons.person_add_outlined, Colors.teal, () {
                  Navigator.of(context).push(MaterialPageRoute(builder: (_) => const UserAcquisitionPage()));
                }),
                _buildNavTile(context, 'Revenue Analytics', 'MRR, ARR, and financial metrics', Icons.account_balance_outlined, Colors.amber, () {
                  Navigator.of(context).push(MaterialPageRoute(builder: (_) => const RevenueAnalyticsPage()));
                }),
                _buildNavTile(context, 'Release Notes', 'Product updates and changelog', Icons.new_releases_outlined, Colors.deepPurple, () {
                  Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ReleaseNotesPage()));
                }),
                const SizedBox(height: 24),

                // Event Counts
                if (provider.eventCounts != null) ...[
                  Text('Recent Events', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 12),
                  ...provider.eventCounts!.entries.take(5).map((entry) => Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: ListTile(
                      leading: const Icon(Icons.event_outlined),
                      title: Text(entry.key, style: theme.textTheme.titleSmall),
                      trailing: Text(_formatNumber((entry.value as num?)?.toInt() ?? 0), style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                    ),
                  )),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildNavTile(BuildContext context, String title, String subtitle, IconData icon, Color color, VoidCallback onTap) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, color: color, size: 20),
        ),
        title: Text(title),
        subtitle: Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }

  String _formatNumber(int num) {
    if (num >= 1000000) return '${(num / 1000000).toStringAsFixed(1)}M';
    if (num >= 1000) return '${(num / 1000).toStringAsFixed(1)}K';
    return num.toString();
  }
}
