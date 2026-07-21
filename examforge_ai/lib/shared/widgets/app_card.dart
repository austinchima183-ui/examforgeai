import 'package:flutter/material.dart';

import '../../core/themes/app_colors.dart';
import '../../core/themes/app_typography.dart';
import '../../core/themes/spacings.dart';
import '../../core/extensions/context_extensions.dart';
import '../../features/analytics_dashboard/domain/entities/analytics_dashboard_entities.dart';


// ─── Trend Direction ──────────────────────────────────────────────────────────

/// Direction of a statistic trend for [AppStatCard].
enum TrendDirection {
  /// Value is trending upward.
  up,

  /// Value is trending downward.
  down,

  /// Value is flat / no significant change.
  neutral,
}

// ─── AppCard ──────────────────────────────────────────────────────────────────

/// A configurable card widget following Material 3 styling with support for
/// custom padding, margin, elevation, border, shadow, and tap handling.
///
/// ```dart
/// AppCard(
///   onTap: () => navigate(),
///   child: Text('Card content'),
/// )
/// ```
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.borderRadius,
    this.elevation,
    this.color,
    this.borderColor,
    this.onTap,
    this.semanticLabel,
    this.shadow,
    this.clipBehavior,
  });

  /// The widget displayed inside the card.
  final Widget child;

  /// Inner padding. Defaults to [Spacings.paddingCard] (`16`).
  final EdgeInsetsGeometry? padding;

  /// Outer margin. Defaults to `EdgeInsets.zero` (theme default).
  final EdgeInsetsGeometry? margin;

  /// Border radius. Defaults to [Spacings.mdRadius] (`12`).
  final double? borderRadius;

  /// Card elevation. Defaults to `0` (Material 3 default).
  final double? elevation;

  /// Card background colour override.
  final Color? color;

  /// Border colour override. Pass [Colors.transparent] to hide border.
  final Color? borderColor;

  /// Optional callback making the card tappable with ink splash.
  final VoidCallback? onTap;

  /// Semantic label for the card when tappable. Required for accessibility
  /// when [onTap] is provided.
  final String? semanticLabel;

  /// Optional shadow colour.
  final Color? shadow;

  /// Clip behaviour for the card content.
  final Clip? clipBehavior;

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;
    final isDark = context.isDarkMode;
    final radius = borderRadius ?? Spacings.mdRadius;
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(radius),
      side: BorderSide(
        color: borderColor ?? cs.outlineVariant.withValues(alpha: 0.5),
      ),
    );

    final cardColor = color ??
        (isDark ? AppColors.surfaceCardDark : AppColors.surfaceCardLight);

    return Semantics(
      button: onTap != null,
      label: semanticLabel,
      child: Card(
      elevation: elevation ?? 0,
      color: cardColor,
      shadowColor: shadow ?? Colors.transparent,
      shape: shape,
      margin: margin ?? EdgeInsets.zero,
      clipBehavior: clipBehavior ?? Clip.antiAlias,
      surfaceTintColor: cs.surfaceTint,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(radius),
        child: Padding(
          padding: padding ?? Spacings.paddingCard,
          child: child,
        ),
      ),
      ),
    );
  }
}

// ─── AppStatCard ──────────────────────────────────────────────────────────────

/// A statistics card displaying a title, value, icon, and optional trend
/// indicator.
///
/// ```dart
/// AppStatCard(
///   title: 'Total Exams',
///   value: '1,284',
///   icon: Icons.quiz,
///   trend: TrendDirection.up,
///   trendValue: '+12.5%',
/// )
/// ```
class AppStatCard extends StatelessWidget {
  const AppStatCard({
    super.key,
    required this.title,
    required this.value,
    this.icon,
    this.trend = TrendDirection.neutral,
    this.trendValue,
    this.color,
    this.onTap,
    this.padding,
    this.margin,
  });

  /// Short descriptive label.
  final String title;

  /// The primary numeric or text value.
  final String value;

  /// Optional leading icon.
  final IconData? icon;

  /// Trend direction.
  final TrendDirection trend;

  /// Trend text (e.g. `"+12.5%"`, `"-3"`).
  final String? trendValue;

  /// Optional accent colour applied to the icon and trend indicator.
  final Color? color;

  /// Optional tap handler.
  final VoidCallback? onTap;

  /// Inner padding override.
  final EdgeInsetsGeometry? padding;

  /// Outer margin override.
  final EdgeInsetsGeometry? margin;

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;
    final tt = context.textTheme;
    final isDark = context.isDarkMode;

    final accentColor = color ?? cs.primary;
    final iconBgColor = accentColor.withValues(alpha: isDark ? 0.20 : 0.12);

    // Trend colour
    final trendColor = switch (trend) {
      TrendDirection.up => AppColors.successOf(cs.brightness),
      TrendDirection.down => AppColors.errorOf(cs.brightness),
      TrendDirection.neutral => cs.onSurfaceVariant,
    };

    final trendIcon = switch (trend) {
      TrendDirection.up => Icons.trending_up_rounded,
      TrendDirection.down => Icons.trending_down_rounded,
      TrendDirection.neutral => Icons.trending_flat_rounded,
    };

    return AppCard(
      onTap: onTap,
      margin: margin,
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Top row: icon + trend ──────────────────────────────────
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
                  child: Icon(icon, size: Spacings.mdIcon, color: accentColor),
                )
              else
                const SizedBox.shrink(),
              if (trendValue != null)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(trendIcon, size: Spacings.mdIcon, color: trendColor),
                    const SizedBox(width: Spacings.xs),
                    Text(
                      trendValue!,
                      style: tt.bodySmall?.copyWith(
                        color: trendColor,
                        fontWeight: AppTypography.wSemiBold,
                      ),
                    ),
                  ],
                )
              else
                const SizedBox.shrink(),
            ],
          ),
          const SizedBox(height: Spacings.md),
          // ── Value ──────────────────────────────────────────────────
          Text(
            value,
            style: tt.headlineSmall?.copyWith(
              fontWeight: AppTypography.wBold,
              color: cs.onSurface,
            ),
          ),
          const SizedBox(height: Spacings.xs),
          // ── Title ──────────────────────────────────────────────────
          Text(
            title,
            style: tt.bodySmall?.copyWith(
              color: cs.onSurfaceVariant,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

// ─── AppInfoCard ──────────────────────────────────────────────────────────────

/// An informational card with a title, subtitle, optional leading icon, and
/// optional trailing widget.
///
/// ```dart
/// AppInfoCard(
///   title: 'Biology 101',
///   subtitle: '12 questions · 30 min',
///   icon: Icons.science,
///   trailing: Icon(Icons.chevron_right),
///   onTap: () => openExam(),
/// )
/// ```
class AppInfoCard extends StatelessWidget {
  const AppInfoCard({
    super.key,
    required this.title,
    this.subtitle,
    this.icon,
    this.trailing,
    this.onTap,
    this.padding,
    this.margin,
    this.iconColor,
  });

  /// Primary title text.
  final String title;

  /// Optional subtitle text.
  final String? subtitle;

  /// Optional leading icon.
  final IconData? icon;

  /// Optional trailing widget (e.g. chevron, badge).
  final Widget? trailing;

  /// Optional tap handler.
  final VoidCallback? onTap;

  /// Inner padding override.
  final EdgeInsetsGeometry? padding;

  /// Outer margin override.
  final EdgeInsetsGeometry? margin;

  /// Optional colour for the leading icon.
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;
    final tt = context.textTheme;

    return AppCard(
      onTap: onTap,
      margin: margin,
      padding: padding,
      child: Row(
        children: [
          if (icon != null) ...[
            Container(
              padding: const EdgeInsets.all(Spacings.sm),
              decoration: BoxDecoration(
                color: (iconColor ?? cs.primary).withValues(
                  alpha: context.isDarkMode ? 0.20 : 0.12,
                ),
                borderRadius: BorderRadius.circular(Spacings.smRadius),
              ),
              child: Icon(
                icon,
                size: Spacings.mdIcon,
                color: iconColor ?? cs.primary,
              ),
            ),
            const SizedBox(width: Spacings.md),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: tt.titleSmall?.copyWith(
                    fontWeight: AppTypography.wSemiBold,
                    color: cs.onSurface,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: Spacings.xs),
                  Text(
                    subtitle!,
                    style: tt.bodySmall?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: Spacings.sm),
            trailing!,
          ],
        ],
      ),
    );
  }
}

// ─── AppActionCard ────────────────────────────────────────────────────────────

/// A tappable action card with an icon, title, subtitle, and optional accent
/// colour.
///
/// ```dart
/// AppActionCard(
///   title: 'Create Exam',
///   subtitle: 'Build a new exam with AI',
///   icon: Icons.add_circle,
///   color: AppColors.info,
///   onTap: () => createExam(),
/// )
/// ```
class AppActionCard extends StatelessWidget {
  const AppActionCard({
    super.key,
    required this.title,
    this.subtitle,
    required this.icon,
    this.onTap,
    this.color,
    this.padding,
    this.margin,
  });

  /// Primary title text.
  final String title;

  /// Optional subtitle text.
  final String? subtitle;

  /// Leading icon.
  final IconData icon;

  /// Tap handler.
  final VoidCallback? onTap;

  /// Optional accent colour applied to icon and background tint.
  final Color? color;

  /// Inner padding override.
  final EdgeInsetsGeometry? padding;

  /// Outer margin override.
  final EdgeInsetsGeometry? margin;

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;
    final tt = context.textTheme;
    final isDark = context.isDarkMode;

    final accentColor = color ?? cs.primary;
    final iconBgColor = accentColor.withValues(alpha: isDark ? 0.20 : 0.12);

    return AppCard(
      onTap: onTap,
      margin: margin,
      padding: padding,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(Spacings.md),
            decoration: BoxDecoration(
              color: iconBgColor,
              borderRadius: BorderRadius.circular(Spacings.mdRadius),
            ),
            child: Icon(icon, size: Spacings.lgIcon, color: accentColor),
          ),
          const SizedBox(width: Spacings.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: tt.titleSmall?.copyWith(
                    fontWeight: AppTypography.wSemiBold,
                    color: cs.onSurface,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: Spacings.xs),
                  Text(
                    subtitle!,
                    style: tt.bodySmall?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          Icon(
            Icons.chevron_right_rounded,
            color: cs.onSurfaceVariant,
            size: Spacings.mdIcon,
          ),
        ],
      ),
    );
  }
}
