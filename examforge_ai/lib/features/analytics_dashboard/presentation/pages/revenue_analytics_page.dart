import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/analytics_dashboard_provider.dart';
import '../widgets/metric_card.dart';
import '../widgets/trend_chart.dart';

/// Revenue analytics page showing MRR, ARR, and financial metrics.
class RevenueAnalyticsPage extends ConsumerStatefulWidget {
  const RevenueAnalyticsPage({super.key});
  @override
  ConsumerState<RevenueAnalyticsPage> createState() => _RevenueAnalyticsPageState();
}

class _RevenueAnalyticsPageState extends ConsumerState<RevenueAnalyticsPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = ref.read(analyticsDashboardProvider);
      final now = DateTime.now();
      provider.loadRevenueMetrics(startDate: now.subtract(const Duration(days: 90)), endDate: now);
      provider.loadChurnData();
      provider.loadDailyMetrics(schoolId: 'all', metricName: 'revenue', startDate: now.subtract(const Duration(days: 30)), endDate: now);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Revenue Analytics'), centerTitle: true),
      body: Consumer(builder: (context, ref, _) {
          final provider = ref.watch(analyticsDashboardProvider);
          final revenue = provider.revenueMetrics ?? {};
          final mrr = (revenue['mrr'] as num?)?.toDouble() ?? 0.0;
          final arr = (revenue['arr'] as num?)?.toDouble() ?? 0.0;
          final arpu = (revenue['arpu'] as num?)?.toDouble() ?? 0.0;
          final ltv = (revenue['ltv'] as num?)?.toDouble() ?? 0.0;
          final cac = (revenue['cac'] as num?)?.toDouble() ?? 0.0;
          final mrrGrowth = (revenue['mrr_growth_percentage'] as num?)?.toDouble() ?? 0.0;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Revenue Overview', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),

                Row(children: [
                  Expanded(child: MetricCard(title: 'MRR', value: '\$${_formatMoney(mrr)}', icon: Icons.trending_up, color: Colors.green, trend: mrrGrowth)),
                  const SizedBox(width: 12),
                  Expanded(child: MetricCard(title: 'ARR', value: '\$${_formatMoney(arr)}', icon: Icons.show_chart, color: Colors.teal)),
                ]),
                const SizedBox(height: 12),

                Row(children: [
                  Expanded(child: MetricCard(title: 'ARPU', value: '\$${arpu.toStringAsFixed(2)}', icon: Icons.person_outline, color: Colors.purple)),
                  const SizedBox(width: 12),
                  Expanded(child: MetricCard(title: 'LTV', value: '\$${_formatMoney(ltv)}', icon: Icons.account_balance_wallet_outlined, color: Colors.amber)),
                ]),
                const SizedBox(height: 12),

                Row(children: [
                  Expanded(child: MetricCard(title: 'CAC', value: '\$${_formatMoney(cac)}', icon: Icons.campaign_outlined, color: Colors.orange)),
                  const SizedBox(width: 12),
                  Expanded(child: MetricCard(title: 'LTV:CAC', value: cac > 0 ? '${(ltv / cac).toStringAsFixed(1)}x' : 'N/A', icon: Icons.balance, color: ltv / cac > 3 ? Colors.green : Colors.red)),
                ]),
                const SizedBox(height: 24),

                // Revenue Trend
                if (provider.dailyMetrics.isNotEmpty) ...[
                  Text('Revenue Trend (30 days)', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 12),
                  TrendChart(
                    title: 'Daily Revenue',
                    data: provider.dailyMetrics.map((m) => ChartDataPoint(date: m.date, value: m.value)).toList(),
                    color: Colors.green,
                    prefix: '\$',
                  ),
                  const SizedBox(height: 24),
                ],

                // Churn Data
                if (provider.churnData != null) ...[
                  Text('Churn Analysis', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 12),
                  Card(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          _buildChurnRow('Monthly Churn', '${((provider.churnData!['monthly_churn_rate'] as num?)?.toDouble() ?? 0 * 100).toStringAsFixed(1)}%'),
                          _buildChurnRow('Revenue Churn', '${((provider.churnData!['revenue_churn_rate'] as num?)?.toDouble() ?? 0 * 100).toStringAsFixed(1)}%'),
                          _buildChurnRow('Voluntary Churn', '${((provider.churnData!['voluntary_churn_rate'] as num?)?.toDouble() ?? 0 * 100).toStringAsFixed(1)}%'),
                          _buildChurnRow('Involuntary Churn', '${((provider.churnData!['involuntary_churn_rate'] as num?)?.toDouble() ?? 0 * 100).toStringAsFixed(1)}%'),
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

  Widget _buildChurnRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(label), Text(value, style: const TextStyle(fontWeight: FontWeight.w600))]),
    );
  }

  String _formatMoney(double value) {
    if (value >= 1000000) return '${(value / 1000000).toStringAsFixed(1)}M';
    if (value >= 1000) return '${(value / 1000).toStringAsFixed(1)}K';
    return value.toStringAsFixed(0);
  }
}
