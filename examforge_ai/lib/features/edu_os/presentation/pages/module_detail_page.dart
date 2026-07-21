import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/edu_os_entities.dart';
import '../providers/edu_os_provider.dart';
import '../widgets/module_tier_badge.dart';

/// Module detail page with pricing, features, and subscription actions.
class ModuleDetailPage extends StatefulWidget {
  const ModuleDetailPage({super.key, this.moduleCode});
  
  /// Module code used to load the module from the provider.
  final String? moduleCode;

  @override
  State<ModuleDetailPage> createState() => _ModuleDetailPageState();
}

class _ModuleDetailPageState extends State<ModuleDetailPage> {
  bool _isYearly = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Consumer<EduOsProvider>(
      builder: (context, provider, _) {
        final module = provider.selectedModule;
        if (module == null) {
          return Scaffold(appBar: AppBar(title: const Text('Module')), body: const Center(child: Text('No module selected')));
        }
        final isSubscribed = provider.subscriptions.any((s) => s.moduleId == module.id && s.isEnabled);
        final price = _isYearly ? module.pricingYearly : module.pricingMonthly;

        return Scaffold(
          appBar: AppBar(title: Text(module.name), centerTitle: true),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [_getColorFromCode(module.colorCode), theme.colorScheme.primaryContainer], begin: Alignment.topLeft, end: Alignment.bottomRight),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        ModuleTierBadge(tier: module.moduleTier),
                        const SizedBox(width: 8),
                        _buildStatusChip(theme, module.moduleStatus),
                        const Spacer(),
                        if (module.isCore) Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(4)), child: const Text('CORE', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 10))),
                      ]),
                      const SizedBox(height: 16),
                      Text(module.name, style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold, color: Colors.white)),
                      const SizedBox(height: 4),
                      Text('v${module.version}', style: theme.textTheme.bodySmall?.copyWith(color: Colors.white70)),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Description
                Text('About', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Text(module.description, style: theme.textTheme.bodyLarge),
                const SizedBox(height: 20),

                // Features
                if (module.features.isNotEmpty) ...[
                  Text('Features', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  ...module.features.entries.map((entry) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(children: [
                      Icon(Icons.check_circle, size: 18, color: Colors.green.shade600),
                      const SizedBox(width: 8),
                      Expanded(child: Text('${entry.key}: ${entry.value}', style: theme.textTheme.bodyMedium)),
                    ]),
                  )),
                  const SizedBox(height: 20),
                ],

                // Dependencies
                if (module.dependencies.isNotEmpty) ...[
                  Text('Dependencies', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Wrap(spacing: 8, runSpacing: 4, children: module.dependencies.map((dep) => Chip(label: Text(dep), materialTapTargetSize: MaterialTapTargetSize.shrinkWrap, visualDensity: VisualDensity.compact)).toList()),
                  const SizedBox(height: 20),
                ],

                // Pricing
                if (module.isPremium) ...[
                  Text('Pricing', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 12),
                  SegmentedButton<bool>(
                    segments: const [ButtonSegment(value: false, label: Text('Monthly')), ButtonSegment(value: true, label: Text('Yearly'))],
                    selected: {_isYearly},
                    onSelectionChanged: (v) => setState(() => _isYearly = v.first),
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: Column(children: [
                      Text('\$${price.toStringAsFixed(2)}', style: theme.textTheme.displaySmall?.copyWith(fontWeight: FontWeight.bold, color: theme.colorScheme.primary)),
                      Text(_isYearly ? '/year (save ${((1 - module.pricingYearly / (module.pricingMonthly * 12)) * 100).toStringAsFixed(0)}%)' : '/month', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                    ]),
                  ),
                  const SizedBox(height: 24),
                ],

                // Action Button
                SizedBox(
                  width: double.infinity,
                  child: isSubscribed
                      ? OutlinedButton(
                          onPressed: () => _showManageDialog(context, provider, module),
                          style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                          child: const Text('Manage Subscription'),
                        )
                      : ElevatedButton(
                          onPressed: module.moduleStatus.isActive ? () => _handleSubscribe(provider, module) : null,
                          style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                          child: module.isPremium ? const Text('Subscribe Now') : const Text('Enable Module'),
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatusChip(ThemeData theme, ModuleStatus status) {
    Color color;
    switch (status) {
      case ModuleStatus.active: color = Colors.green; break;
      case ModuleStatus.beta: color = Colors.orange; break;
      case ModuleStatus.comingSoon: color = Colors.blue; break;
      case ModuleStatus.deprecated: color = Colors.red; break;
      case ModuleStatus.inactive: color = Colors.grey; break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(4)),
      child: Text(status.label, style: theme.textTheme.labelSmall?.copyWith(color: color, fontWeight: FontWeight.w600)),
    );
  }

  Color _getColorFromCode(String? colorCode) {
    if (colorCode == null) return Colors.teal;
    try { return Color(int.parse(colorCode.replaceFirst('#', '0xFF'))); } catch (_) { return Colors.teal; }
  }

  Future<void> _handleSubscribe(EduOsProvider provider, EduosModule module) async {
    final tier = module.isPremium ? module.moduleTier : ModuleTier.free;
    final success = await provider.subscribeToModule('current-school', module.id, tier);
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${module.name} has been enabled!')));
    }
  }

  void _showManageDialog(BuildContext context, EduOsProvider provider, EduosModule module) {
    final sub = provider.subscriptions.firstWhere((s) => s.moduleId == module.id);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Manage ${module.name}'),
        content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Status: ${sub.isEnabled ? "Enabled" : "Disabled"}'),
          Text('Tier: ${sub.moduleTier.label}'),
          if (sub.expiresAt != null) Text('Expires: ${sub.expiresAt!.toLocal().toString().substring(0, 10)}'),
        ]),
        actions: [
          TextButton(onPressed: () { Navigator.pop(ctx); provider.unsubscribeFromModule(sub.id); }, child: const Text('Unsubscribe', style: TextStyle(color: Colors.red))),
          TextButton(onPressed: () { Navigator.pop(ctx); provider.toggleModuleEnabled(sub.id, !sub.isEnabled); }, child: Text(sub.isEnabled ? 'Disable' : 'Enable')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx), child: const Text('Done')),
        ],
      ),
    );
  }
}
