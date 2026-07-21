import 'package:flutter/material.dart';

import '../../../../core/themes/app_colors.dart';
import '../../../../core/themes/app_typography.dart';
import '../../../../core/themes/spacings.dart';
import '../../../../core/extensions/context_extensions.dart';

// ═══════════════════════════════════════════════════════════════════════
// ENGAGEMENT METRIC CARD
// ═══════════════════════════════════════════════════════════════════════

/// Compact card for displaying an engagement metric on the admin dashboard.
///
/// Shows an icon inside a coloured circle, a large bold count number,
/// a title, and an optional subtitle in smaller grey text.
///
/// ```dart
/// EngagementMetricCard(
///   title: 'Messages Sent',
///   count: 142,
///   icon: Icons.chat_rounded,
///   color: AppColors.info,
///   subtitle: 'This month',
/// )
/// ```
class EngagementMetricCard extends StatelessWidget {
  const EngagementMetricCard({
    super.key,
    required this.title,
    required this.count,
    required this.icon,
    required this.color,
    this.subtitle,
  });

  /// Title of the metric.
  final String title;

  /// Numeric count to display.
  final int count;

  /// Icon representing the metric.
  final IconData icon;

  /// Theme colour for the icon background and accents.
  final Color color;

  /// Optional subtitle (e.g. time period).
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;
    final tt = context.textTheme;
    final isDark = context.isDarkMode;

    return Card(
      elevation: Spacings.elevationSm,
      shadowColor: cs.shadow.withOpacity(0.06),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Spacings.mdRadius),
      ),
      child: Padding(
        padding: const EdgeInsets.all(Spacings.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Icon + Count Row ────────────────────────────────────
            Row(
              children: [
                // Icon circle
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: color.withOpacity(isDark ? 0.20 : 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    size: Spacings.mdIcon - 4,
                    color: color,
                  ),
                ),
                const SizedBox(width: Spacings.md),

                // Count number
                Expanded(
                  child: Text(
                    _formatCount(count),
                    style: tt.headlineSmall?.copyWith(
                      fontWeight: AppTypography.wBold,
                      color: cs.onSurface,
                      height: 1.0,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: Spacings.sm),

            // ── Title ───────────────────────────────────────────────
            Text(
              title,
              style: tt.bodyMedium?.copyWith(
                fontWeight: AppTypography.wMedium,
                color: cs.onSurface,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),

            // ── Subtitle ────────────────────────────────────────────
            if (subtitle != null) ...[
              const SizedBox(height: Spacings.xs),
              Text(
                subtitle!,
                style: tt.labelSmall?.copyWith(
                  color: cs.onSurfaceVariant,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ─── Count Formatting ─────────────────────────────────────────────

  String _formatCount(int n) {
    if (n >= 1000000) {
      return '${(n / 1000000).toStringAsFixed(1)}M';
    }
    if (n >= 1000) {
      return '${(n / 1000).toStringAsFixed(1)}K';
    }
    return n.toString();
  }
}
