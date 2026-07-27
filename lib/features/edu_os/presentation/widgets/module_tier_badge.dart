import 'package:flutter/material.dart';
import '../../domain/entities/edu_os_entities.dart';

/// Badge widget showing a module's tier (Free, Starter, Professional, Enterprise).
class ModuleTierBadge extends StatelessWidget {
  const ModuleTierBadge({super.key, required this.tier});
  final ModuleTier tier;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: tier.displayColor.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: tier.displayColor.withValues(alpha: 0.3)),
      ),
      child: Text(
        tier.label,
        style: theme.textTheme.labelSmall?.copyWith(
          color: tier.displayColor,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
