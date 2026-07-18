import 'package:flutter/material.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/themes/spacings.dart';

/// A compact stats card widget for displaying a single statistic.
///
/// Shows an icon inside a colored circle, a large bold value, and a small
/// title underneath. The card is tappable with a ripple effect.
class TeachingStatsCard extends StatelessWidget {
  /// The label displayed below the value.
  final String title;

  /// The main numeric or text value to display.
  final String value;

  /// The icon shown inside the colored circle.
  final IconData icon;

  /// The color used for the icon background circle.
  /// Defaults to the theme's primary color if not specified.
  final Color? color;

  /// Callback when the card is tapped.
  final VoidCallback? onTap;

  const TeachingStatsCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    final effectiveColor = color ?? colorScheme.primary;

    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: Spacings.elevationNone,
      shape: RoundedRectangleBorder(
        borderRadius: Spacings.borderRadiusMd,
        side: BorderSide(
          color: colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: Spacings.borderRadiusMd,
        child: Padding(
          padding: const EdgeInsets.all(Spacings.md),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // ── Icon Circle ────────────────────────────────────────────
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: effectiveColor.withValues(alpha: 0.12),
                  borderRadius: Spacings.borderRadiusMd,
                ),
                child: Icon(
                  icon,
                  color: effectiveColor,
                  size: Spacings.mdIcon,
                ),
              ),
              const SizedBox(height: Spacings.sm),

              // ── Value ──────────────────────────────────────────────────
              Text(
                value,
                style: context.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: colorScheme.onSurface,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: Spacings.xs),

              // ── Title ──────────────────────────────────────────────────
              Text(
                title,
                style: context.textTheme.labelSmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
