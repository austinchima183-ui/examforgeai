import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/marketing_entities.dart';
import '../providers/marketing_provider.dart';
import '../widgets/referral_code_display.dart';

/// Referral program management page.
///
/// Shows active referral programs with codes and stats,
/// and allows creating new referral programs.
class ReferralProgramPage extends ConsumerStatefulWidget {
  const ReferralProgramPage({super.key});
  @override
  ConsumerState<ReferralProgramPage> createState() => _ReferralProgramPageState();
}

class _ReferralProgramPageState extends ConsumerState<ReferralProgramPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(marketingProvider).loadReferralPrograms();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Referral Programs'), centerTitle: true),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateProgramDialog(context),
        icon: const Icon(Icons.add),
        label: const Text('New Program'),
      ),
      body: Consumer(builder: (context, ref, _) {
          final provider = ref.watch(marketingProvider);
          if (provider.isLoading && provider.referralPrograms.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          if (provider.referralPrograms.isEmpty) {
            return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.card_giftcard, size: 64, color: Colors.grey.shade400),
              const SizedBox(height: 16),
              Text('No referral programs yet', style: theme.textTheme.bodyLarge),
            ]));
          }
          return RefreshIndicator(
            onRefresh: () => provider.loadReferralPrograms(),
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: provider.referralPrograms.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) => _buildProgramCard(context, provider.referralPrograms[index]),
            ),
          );
        },
      ),
    );
  }

  Widget _buildProgramCard(BuildContext context, ReferralProgram program) {
    final theme = Theme.of(context);
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Expanded(child: Text(program.name, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600))),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: program.isActive ? Colors.green.withOpacity(0.15) : Colors.grey.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(program.isActive ? 'ACTIVE' : 'INACTIVE', style: theme.textTheme.labelSmall?.copyWith(color: program.isActive ? Colors.green : Colors.grey, fontWeight: FontWeight.w600)),
              ),
            ]),
            const SizedBox(height: 8),
            Text(program.description, style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant), maxLines: 2, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 12),
            ReferralCodeDisplay(referralCode: program.referralCode),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildInfoChip(theme, Icons.people_outline, '${program.totalReferrals} referrals'),
                const SizedBox(width: 12),
                _buildInfoChip(theme, Icons.card_giftcard, '${program.rewardType}: ${program.rewardValue}'),
                if (program.maxReferrals != null) ...[
                  const SizedBox(width: 12),
                  _buildInfoChip(theme, Icons.limit, 'Max: ${program.maxReferrals}'),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip(ThemeData theme, IconData icon, String label) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 16, color: theme.colorScheme.onSurfaceVariant),
      const SizedBox(width: 4),
      Text(label, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
    ]);
  }

  void _showCreateProgramDialog(BuildContext context) {
    final nameCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final codeCtrl = TextEditingController();
    String rewardType = 'credit';
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Create Referral Program'),
          content: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Program Name', border: OutlineInputBorder())),
              const SizedBox(height: 12),
              TextField(controller: descCtrl, decoration: const InputDecoration(labelText: 'Description', border: OutlineInputBorder()), maxLines: 2),
              const SizedBox(height: 12),
              TextField(controller: codeCtrl, decoration: const InputDecoration(labelText: 'Referral Code', border: OutlineInputBorder())),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: rewardType,
                decoration: const InputDecoration(labelText: 'Reward Type', border: OutlineInputBorder()),
                items: ['credit', 'discount', 'cash', 'feature_access'].map((t) => DropdownMenuItem(value: t, child: Text(t[0].toUpperCase() + t.substring(1)))).toList(),
                onChanged: (v) => setDialogState(() => rewardType = v ?? 'credit'),
              ),
            ]),
          ),
          actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')), ElevatedButton(onPressed: () => Navigator.pop(ctx), child: const Text('Create'))],
        ),
      ),
    );
  }
}
