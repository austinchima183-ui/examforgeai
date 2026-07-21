import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/marketing_provider.dart';
import 'blog_management_page.dart';
import 'referral_program_page.dart';
import 'affiliate_program_page.dart';

/// Main dashboard page for the Marketing feature.
///
/// Shows summary cards for blog posts, campaigns, referral programs,
/// and affiliate activity with quick navigation.
class MarketingDashboardPage extends ConsumerStatefulWidget {
  const MarketingDashboardPage({super.key});
  @override
  ConsumerState<MarketingDashboardPage> createState() => _MarketingDashboardPageState();
}

class _MarketingDashboardPageState extends ConsumerState<MarketingDashboardPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(marketingProvider).loadAll();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final provider = ref.watch(marketingProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Marketing Hub'), centerTitle: true),
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
            onRefresh: () => ref.read(marketingProvider).loadAll(),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text('Marketing Overview', style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text('Manage your marketing efforts in one place', style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(child: _buildStatCard(context, 'Blog Posts', '${provider.blogPosts.length}', Icons.article_outlined, Colors.teal, () {
                      Navigator.of(context).push(MaterialPageRoute(builder: (_) => const BlogManagementPage()));
                    })),
                    const SizedBox(width: 12),
                    Expanded(child: _buildStatCard(context, 'Campaigns', '${provider.emailCampaigns.length}', Icons.campaign_outlined, Colors.deepPurple, null)),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: _buildStatCard(context, 'Referrals', '${provider.referralPrograms.length}', Icons.card_giftcard, Colors.orange, () {
                      Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ReferralProgramPage()));
                    })),
                    const SizedBox(width: 12),
                    Expanded(child: _buildStatCard(context, 'Affiliates', '${provider.affiliates.length}', Icons.handshake_outlined, Colors.indigo, () {
                      Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AffiliateProgramPage()));
                    })),
                  ],
                ),
                const SizedBox(height: 24),
                if (provider.emailCampaigns.isNotEmpty) ...[
                  Text('Recent Campaigns', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 12),
                  ...provider.emailCampaigns.take(3).map((c) => Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: ListTile(
                      leading: Icon(Icons.campaign_outlined, color: _getCampaignStatusColor(c.status)),
                      title: Text(c.name, style: theme.textTheme.titleSmall),
                      subtitle: Text('${c.campaignType.label} • ${c.recipientCount} recipients • ${(c.openRate * 100).toStringAsFixed(1)}% open rate'),
                      trailing: _buildCampaignStatusChip(theme, c.status),
                    ),
                  )),
                ],
                const SizedBox(height: 24),
                if (provider.blogPosts.isNotEmpty) ...[
                  Text('Recent Blog Posts', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 12),
                  ...provider.blogPosts.take(3).map((post) => Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: ListTile(
                      leading: Icon(post.isFeatured ? Icons.star : Icons.article_outlined, color: post.isFeatured ? Colors.amber : null),
                      title: Text(post.title, style: theme.textTheme.titleSmall),
                      subtitle: Text('${post.category} • ${post.viewsCount} views'),
                      trailing: _buildBlogStatusChip(theme, post.status),
                    ),
                  )),
                ],
              ],
            ),
          ),
    );
  }

  Widget _buildStatCard(BuildContext context, String title, String value, IconData icon, Color color, VoidCallback? onTap) {
    final theme = Theme.of(context);
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
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
      ),
    );
  }

  Widget _buildCampaignStatusChip(ThemeData theme, String status) {
    final color = _getCampaignStatusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(6)),
      child: Text(status.toUpperCase(), style: theme.textTheme.labelSmall?.copyWith(color: color, fontWeight: FontWeight.w600)),
    );
  }

  Widget _buildBlogStatusChip(ThemeData theme, String status) {
    Color color;
    switch (status) {
      case 'published': color = Colors.green; break;
      case 'draft': color = Colors.grey; break;
      case 'review': color = Colors.orange; break;
      default: color = Colors.grey;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(6)),
      child: Text(status.toUpperCase(), style: theme.textTheme.labelSmall?.copyWith(color: color, fontWeight: FontWeight.w600)),
    );
  }

  Color _getCampaignStatusColor(String status) {
    switch (status) {
      case 'draft': return Colors.grey;
      case 'scheduled': return Colors.blue;
      case 'sending': return Colors.orange;
      case 'sent': return Colors.green;
      default: return Colors.grey;
    }
  }
}
