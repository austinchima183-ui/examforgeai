import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/analytics_dashboard_provider.dart';
import '../widgets/trend_chart.dart';

/// User acquisition analytics page.
///
/// Shows user signup trends, activation rates, and growth metrics.
class UserAcquisitionPage extends ConsumerStatefulWidget {
  const UserAcquisitionPage({super.key});
  @override
  ConsumerState<UserAcquisitionPage> createState() => _UserAcquisitionPageState();
}

class _UserAcquisitionPageState extends ConsumerState<UserAcquisitionPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = ref.read(analyticsDashboardProvider);
      final now = DateTime.now();
      provider.loadDailyMetrics(schoolId: 'all', metricName: 'user_signups', startDate: now.subtract(const Duration(days: 30)), endDate: now);
      provider.loadFeatureAdoption();
      provider.loadRetentionData();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('User Acquisition'), centerTitle: true),
      body: Consumer(builder: (context, ref, _) {
          final provider = ref.watch(analyticsDashboardProvider);
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('User Growth Trends', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text('Last 30 days', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                const SizedBox(height: 16),

                // Signups Chart
                if (provider.dailyMetrics.isNotEmpty)
                  TrendChart(
                    title: 'Daily Signups',
                    data: provider.dailyMetrics.map((m) => ChartDataPoint(date: m.date, value: m.value)).toList(),
                    color: Colors.teal,
                  )
                else
                  Container(
                    height: 200,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Center(child: Text('No signup data available')),
                  ),
                const SizedBox(height: 24),

                // Feature Adoption
                if (provider.featureAdoption != null) ...[
                  Text('Feature Adoption', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 12),
                  ...provider.featureAdoption!.entries.map((entry) {
                    final rate = (entry.value as num?)?.toDouble() ?? 0.0;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                            Text(entry.key, style: theme.textTheme.bodyMedium),
                            Text('${(rate * 100).toStringAsFixed(1)}%', style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                          ],),
                          const SizedBox(height: 4),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(value: rate, minHeight: 8, backgroundColor: theme.colorScheme.surfaceContainerHighest),
                          ),
                        ],
                      ),
                    );
                  }),
                  const SizedBox(height: 24),
                ],

                // Retention
                if (provider.retentionData != null) ...[
                  Text('Retention Cohorts', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 12),
                  Card(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          const Row(children: [
                            Expanded(child: Text('Cohort', style: TextStyle(fontWeight: FontWeight.w600))),
                            Expanded(child: Text('Day 1', style: TextStyle(fontWeight: FontWeight.w600), textAlign: TextAlign.center)),
                            Expanded(child: Text('Day 7', style: TextStyle(fontWeight: FontWeight.w600), textAlign: TextAlign.center)),
                            Expanded(child: Text('Day 30', style: TextStyle(fontWeight: FontWeight.w600), textAlign: TextAlign.center)),
                          ],),
                          const Divider(),
                          ..._buildRetentionRows(provider.retentionData!),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  List<Widget> _buildRetentionRows(Map<String, dynamic> data) {
    final cohorts = data['cohorts'] as List? ?? [];
    return cohorts.map<Widget>((cohort) {
      if (cohort is! Map<String, dynamic>) return const SizedBox.shrink();
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(children: [
          Expanded(child: Text(cohort['name']?.toString() ?? '', style: const TextStyle(fontSize: 13))),
          Expanded(child: Text('${((cohort['day1'] as num?)?.toDouble() ?? 0 * 100).toStringAsFixed(0)}%', textAlign: TextAlign.center, style: const TextStyle(fontSize: 13))),
          Expanded(child: Text('${((cohort['day7'] as num?)?.toDouble() ?? 0 * 100).toStringAsFixed(0)}%', textAlign: TextAlign.center, style: const TextStyle(fontSize: 13))),
          Expanded(child: Text('${((cohort['day30'] as num?)?.toDouble() ?? 0 * 100).toStringAsFixed(0)}%', textAlign: TextAlign.center, style: const TextStyle(fontSize: 13))),
        ],),
      );
    }).toList();
  }
}
