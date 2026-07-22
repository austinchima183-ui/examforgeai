import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../config/dependency_injection.dart';
import '../../domain/entities/edu_os_entities.dart';
import '../providers/edu_os_provider.dart';
import '../widgets/module_card.dart';
import '../widgets/module_tier_badge.dart';

/// Page showing a school's active modules and subscription status.
class SchoolModulesPage extends ConsumerWidget {
  const SchoolModulesPage({
    super.key,
    this.schoolId,
    this.subscriptions,
    this.allModules,
  });

  final String? schoolId;
  final List<EduosModuleSubscription>? subscriptions;
  final List<EduosModule>? allModules;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    if (subscriptions == null || subscriptions!.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.widgets_outlined, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text('No active modules', style: theme.textTheme.bodyLarge),
            const SizedBox(height: 8),
            Text('Browse the marketplace to enable modules', style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          ],
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: subscriptions!.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final sub = subscriptions![index];
        final module = allModules?.where((m) => m.id == sub.moduleId).firstOrNull;
        return _buildSubscriptionCard(context, ref, sub, module, theme);
      },
    );
  }

  Widget _buildSubscriptionCard(BuildContext context, WidgetRef ref, EduosModuleSubscription sub, EduosModule? module, ThemeData theme) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: _getColorFromCode(module?.colorCode).withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(child: Text(module?.name.substring(0, 2).toUpperCase() ?? '??', style: TextStyle(fontWeight: FontWeight.bold, color: _getColorFromCode(module?.colorCode)))),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Text(module?.name ?? 'Unknown Module', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
                    const SizedBox(width: 8),
                    if (module != null) ModuleTierBadge(tier: module.moduleTier),
                  ]),
                  const SizedBox(height: 4),
                  Text('${sub.moduleTier.label} tier • ${sub.isEnabled ? "Active" : "Disabled"}', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                  if (sub.expiresAt != null)
                    Text('Expires: ${sub.expiresAt!.toLocal().toString().substring(0, 10)}', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                ],
              ),
            ),
            Switch(
              value: sub.isEnabled,
              onChanged: (value) {
                ref.read(eduOsProvider).toggleModuleEnabled(sub.id, value);
              },
            ),
          ],
        ),
      ),
    );
  }

  Color _getColorFromCode(String? colorCode) {
    if (colorCode == null) return Colors.teal;
    try { return Color(int.parse(colorCode.replaceFirst('#', '0xFF'))); } catch (_) { return Colors.teal; }
  }
}
