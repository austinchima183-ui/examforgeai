import 'package:flutter/material.dart';

import '../../../../../core/core.dart';
import '../../../../../shared/widgets/widgets.dart';
import '../../../../features/analytics_dashboard/domain/entities/analytics_dashboard_entities.dart';


/// Single stat card for dashboard display.
///
/// Features:
/// - Icon with color accent background
/// - Value (large number)
/// - Label
/// - Optional trend indicator (up/down arrow with percentage)
/// - Color accent
class StatOverviewCard extends StatelessWidget {
  const StatOverviewCard({
    super.key,
    required this.title,
    required this.value,
    this.icon,
    this.trend = TrendDirection.neutral,
    this.trendValue,
    this.color,
    this.subtitle,
    this.onTap,
  });

  /// Short descriptive label for the statistic.
  final String title;

  /// The primary numeric or text value.
  final String value;

  /// Optional leading icon.
  final IconData? icon;

  /// Trend direction (up, down, or neutral).
  final TrendDirection trend;

  /// Trend text (e.g., "+12.5%", "-3").
  final String? trendValue;

  /// Optional accent color applied to icon, background tint, and trend.
  final Color? color;

  /// Optional subtitle text below the value.
  final String? subtitle;

  /// Optional tap handler.
  final VoidCallback? onTap;

  // ─── Trend Helpers ──────────────────────────────────────────────────────

  Color _trendColor(ColorScheme cs) {
    return switch (trend) {
      TrendDirection.up => AppColors.successOf(cs.brightness),
      TrendDirection.down => AppColors.errorOf(cs.brightness),
      TrendDirection.neutral => cs.onSurfaceVariant,
    };
  }

  IconData _trendIcon() {
    return switch (trend) {
      TrendDirection.up => Icons.trending_up_rounded,
      TrendDirection.down => Icons.trending_down_rounded,
      TrendDirection.neutral => Icons.trending_flat_rounded,
    };
  }

  // ─── Build ──────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;
    final tt = context.textTheme;
    final isDark = context.isDarkMode;
    final accentColor = color ?? cs.primary;
    final iconBgColor =
        accentColor.withValues(alpha: isDark ? 0.20 : 0.12);
    final trendColor = _trendColor(cs);

    return AppCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Top row: icon + trend indicator ──────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (icon != null)
                Container(
                  padding: const EdgeInsets.all(Spacings.sm),
                  decoration: BoxDecoration(
                    color: iconBgColor,
                    borderRadius: BorderRadius.circular(Spacings.smRadius),
                  ),
                  child: Icon(
                    icon,
                    size: Spacings.mdIcon,
                    color: accentColor,
                  ),
                )
              else
                const SizedBox.shrink(),

              // Trend indicator
              if (trendValue != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: Spacings.sm,
                    vertical: Spacings.xs,
                  ),
                  decoration: BoxDecoration(
                    color: trendColor.withValues(alpha: isDark ? 0.15 : 0.08),
                    borderRadius: Spacings.borderRadiusSm,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _trendIcon(),
                        size: 14,
                        color: trendColor,
                      ),
                      const SizedBox(width: Spacings.xs),
                      Text(
                        trendValue!,
                        style: tt.bodySmall?.copyWith(
                          color: trendColor,
                          fontWeight: AppTypography.wSemiBold,
                        ),
                      ),
                    ],
                  ),
                )
              else
                const SizedBox.shrink(),
            ],
          ),
          const SizedBox(height: Spacings.md),

          // ── Value ────────────────────────────────────────────────────
          Text(
            value,
            style: tt.headlineSmall?.copyWith(
              fontWeight: AppTypography.wBold,
              color: cs.onSurface,
            ),
          ),
          const SizedBox(height: Spacings.xs),

          // ── Label ────────────────────────────────────────────────────
          Text(
            title,
            style: tt.bodySmall?.copyWith(
              color: cs.onSurfaceVariant,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),

          // ── Subtitle ─────────────────────────────────────────────────
          if (subtitle != null) ...[
            const SizedBox(height: Spacings.xs),
            Text(
              subtitle!,
              style: tt.bodySmall?.copyWith(
                color: cs.onSurfaceVariant.withValues(alpha: 0.7),
                fontSize: 11,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],

          // ── Accent bar at the bottom ─────────────────────────────────
          const SizedBox(height: Spacings.md),
          Container(
            height: 3,
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.3),
              borderRadius: Spacings.borderRadiusSm,
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: _barWidth(),
              child: Container(
                decoration: BoxDecoration(
                  color: accentColor,
                  borderRadius: Spacings.borderRadiusSm,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Calculates the accent bar width based on trend direction.
  double _barWidth() {
    return switch (trend) {
      TrendDirection.up => 0.8,
      TrendDirection.neutral => 0.5,
      TrendDirection.down => 0.3,
    };
  }
}
