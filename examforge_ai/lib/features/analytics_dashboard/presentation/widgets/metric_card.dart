import 'package:flutter/material.dart';

/// Card widget for displaying a single metric with optional trend indicator.
class MetricCard extends StatelessWidget {
  const MetricCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.subtitle,
    this.trend,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final String? subtitle;
  final double? trend;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(8)),
                  child: Icon(icon, color: color, size: 20),
                ),
                if (trend != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: (trend! >= 0 ? Colors.green : Colors.red).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(trend! >= 0 ? Icons.arrow_upward : Icons.arrow_downward, size: 12, color: trend! >= 0 ? Colors.green : Colors.red),
                      const SizedBox(width: 2),
                      Text('${trend!.abs().toStringAsFixed(1)}%', style: TextStyle(fontSize: 11, color: trend! >= 0 ? Colors.green : Colors.red, fontWeight: FontWeight.w600)),
                    ]),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Text(value, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 2),
            Text(title, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
            if (subtitle != null) ...[
              const SizedBox(height: 2),
              Text(subtitle!, style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
            ],
          ],
        ),
      ),
    );
  }
}
