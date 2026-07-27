import 'package:flutter/material.dart';
import '../../domain/entities/edu_os_entities.dart';
import 'module_tier_badge.dart';

/// Card widget for displaying an EduOS module in the marketplace.
class ModuleCard extends StatelessWidget {
  const ModuleCard({super.key, required this.module, required this.onTap});
  final EduosModule module;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: _getColorFromCode(module.colorCode).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(child: Text(module.name.substring(0, 2).toUpperCase(), style: TextStyle(fontWeight: FontWeight.bold, color: _getColorFromCode(module.colorCode), fontSize: 14))),
                  ),
                  const Spacer(),
                  if (module.isPremium)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(color: Colors.amber.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(4)),
                      child: const Text('PRO', style: TextStyle(color: Colors.amber, fontWeight: FontWeight.w600, fontSize: 10)),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              Text(module.name, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 4),
              Text(module.description, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant), maxLines: 2, overflow: TextOverflow.ellipsis),
              const Spacer(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ModuleTierBadge(tier: module.moduleTier),
                  Text(
                    module.isPremium ? '\$${module.pricingMonthly.toStringAsFixed(0)}/mo' : 'Free',
                    style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600, color: module.isPremium ? theme.colorScheme.primary : Colors.green),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getColorFromCode(String? colorCode) {
    if (colorCode == null) return Colors.teal;
    try { return Color(int.parse(colorCode.replaceFirst('#', '0xFF'))); } catch (_) { return Colors.teal; }
  }
}
