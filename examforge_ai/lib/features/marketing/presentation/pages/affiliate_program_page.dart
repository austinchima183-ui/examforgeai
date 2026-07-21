import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/marketing_entities.dart';
import '../providers/marketing_provider.dart';

/// Affiliate program management page.
///
/// Displays list of affiliates with their stats and
/// allows managing affiliate statuses.
class AffiliateProgramPage extends StatefulWidget {
  const AffiliateProgramPage({super.key});
  @override
  State<AffiliateProgramPage> createState() => _AffiliateProgramPageState();
}

class _AffiliateProgramPageState extends State<AffiliateProgramPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MarketingProvider>().loadAffiliates();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Affiliate Program'), centerTitle: true),
      body: Consumer<MarketingProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading && provider.affiliates.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          if (provider.affiliates.isEmpty) {
            return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.handshake_outlined, size: 64, color: Colors.grey.shade400),
              const SizedBox(height: 16),
              Text('No affiliates yet', style: theme.textTheme.bodyLarge),
              const SizedBox(height: 8),
              Text('Invite partners to join your affiliate program', style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
            ]));
          }
          return RefreshIndicator(
            onRefresh: () => provider.loadAffiliates(),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      _buildSummaryStat(theme, 'Total', '${provider.affiliates.length}', Icons.people_outline, Colors.teal),
                      const SizedBox(width: 12),
                      _buildSummaryStat(theme, 'Active', '${provider.affiliates.where((a) => a.status == AffiliateStatus.active).length}', Icons.check_circle_outline, Colors.green),
                      const SizedBox(width: 12),
                      _buildSummaryStat(theme, 'Earnings', '\$${provider.affiliates.fold<double>(0, (sum, a) => sum + a.totalEarnings).toStringAsFixed(2)}', Icons.attach_money, Colors.amber),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: provider.affiliates.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) => _buildAffiliateCard(context, provider.affiliates[index]),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSummaryStat(ThemeData theme, String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Icon(icon, size: 24, color: color),
              const SizedBox(height: 4),
              Text(value, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              Text(label, style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAffiliateCard(BuildContext context, Affiliate affiliate) {
    final theme = Theme.of(context);
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: _getStatusColor(affiliate.status).withOpacity(0.15),
                  child: Text(affiliate.affiliateCode.substring(0, 2).toUpperCase(), style: TextStyle(color: _getStatusColor(affiliate.status), fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Code: ${affiliate.affiliateCode}', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
                    Text('${affiliate.referralsCount} referrals • ${affiliate.commissionRate}% commission', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                  ]),
                ),
                _buildStatusChip(theme, affiliate.status),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _buildEarningStat(theme, 'Total', '\$${affiliate.totalEarnings.toStringAsFixed(2)}')),
                Expanded(child: _buildEarningStat(theme, 'Pending', '\$${affiliate.pendingEarnings.toStringAsFixed(2)}')),
                Expanded(child: _buildEarningStat(theme, 'Paid', '\$${affiliate.paidEarnings.toStringAsFixed(2)}')),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEarningStat(ThemeData theme, String label, String value) {
    return Column(
      children: [
        Text(value, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
        Text(label, style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
      ],
    );
  }

  Widget _buildStatusChip(ThemeData theme, AffiliateStatus status) {
    final color = _getStatusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(6)),
      child: Text(status.label.toUpperCase(), style: theme.textTheme.labelSmall?.copyWith(color: color, fontWeight: FontWeight.w600)),
    );
  }

  Color _getStatusColor(AffiliateStatus status) {
    switch (status) {
      case AffiliateStatus.pending: return Colors.orange;
      case AffiliateStatus.active: return Colors.green;
      case AffiliateStatus.suspended: return Colors.red;
      case AffiliateStatus.terminated: return Colors.grey;
    }
  }
}
