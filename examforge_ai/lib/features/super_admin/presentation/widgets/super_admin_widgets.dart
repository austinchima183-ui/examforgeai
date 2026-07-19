import 'package:flutter/material.dart';
import '../../../../../core/themes/app_colors.dart';
import '../../../../../core/themes/spacings.dart';
import '../../../../../core/themes/app_typography.dart';
import '../../domain/entities/super_admin_entities.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// METRIC CARD — Displays a single KPI on the dashboard
// ═══════════════════════════════════════════════════════════════════════════════

class MetricCard extends StatelessWidget {
  const MetricCard({
    super.key,
    required this.title,
    required this.value,
    this.icon,
    this.color,
    this.subtitle,
    this.trend,
    this.trendIsUp,
    this.onTap,
  });

  final String title;
  final String value;
  final IconData? icon;
  final Color? color;
  final String? subtitle;
  final String? trend;
  final bool? trendIsUp;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final effectiveColor = color ?? cs.primary;

    return Card(
      elevation: Spacings.elevationSm,
      shape: RoundedRectangleBorder(borderRadius: Spacings.borderRadiusMd),
      child: InkWell(
        onTap: onTap,
        borderRadius: Spacings.borderRadiusMd,
        child: Padding(
          padding: Spacings.paddingAll,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (icon != null)
                    Container(
                      padding: const EdgeInsets.all(Spacings.sm),
                      decoration: BoxDecoration(
                        color: effectiveColor.withValues(alpha: 0.1),
                        borderRadius: Spacings.borderRadiusSm,
                      ),
                      child: Icon(icon, color: effectiveColor, size: Spacings.mdIcon),
                    ),
                  const Spacer(),
                  if (trend != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: Spacings.sm, vertical: Spacings.xs),
                      decoration: BoxDecoration(
                        color: (trendIsUp == true ? AppColors.success : AppColors.error).withValues(alpha: 0.1),
                        borderRadius: Spacings.borderRadiusSm,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            trendIsUp == true ? Icons.trending_up : Icons.trending_down,
                            size: Spacings.smIcon,
                            color: trendIsUp == true ? AppColors.success : AppColors.error,
                          ),
                          const SizedBox(width: Spacings.xs),
                          Text(
                            trend!,
                            style: AppTypography.wSemiBold.copyWith(
                              fontSize: 11,
                              color: trendIsUp == true ? AppColors.success : AppColors.error,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              const SizedBox(height: Spacings.md),
              Text(
                value,
                style: AppTypography.wBold.copyWith(
                  fontSize: 24,
                  color: cs.onSurface,
                ),
              ),
              const SizedBox(height: Spacings.xs),
              Text(
                title,
                style: AppTypography.wRegular.copyWith(
                  fontSize: 12,
                  color: cs.onSurface.withValues(alpha: 0.6),
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: Spacings.xs),
                Text(
                  subtitle!,
                  style: AppTypography.wRegular.copyWith(
                    fontSize: 11,
                    color: cs.onSurface.withValues(alpha: 0.4),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// STATUS BADGE — Colored pill for status display
// ═══════════════════════════════════════════════════════════════════════════════

class StatusBadge extends StatelessWidget {
  const StatusBadge({super.key, required this.label, required this.color, this.icon});
  final String label;
  final Color color;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: Spacings.sm, vertical: Spacings.xs),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: Spacings.borderRadiusFull,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: color),
            const SizedBox(width: Spacings.xs),
          ],
          Text(
            label,
            style: AppTypography.wSemiBold.copyWith(fontSize: 11, color: color),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// HEALTH INDICATOR — Dot + label for infrastructure health
// ═══════════════════════════════════════════════════════════════════════════════

class HealthIndicator extends StatelessWidget {
  const HealthIndicator({super.key, required this.status, this.showLabel = true});
  final HealthStatus status;
  final bool showLabel;

  Color _color() {
    switch (status) {
      case HealthStatus.healthy: return AppColors.success;
      case HealthStatus.degraded: return AppColors.warning;
      case HealthStatus.unhealthy: return AppColors.error;
      case HealthStatus.down: return AppColors.error;
      case HealthStatus.maintenance: return AppColors.info;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _color();
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10, height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        if (showLabel) ...[
          const SizedBox(width: Spacings.sm),
          Text(
            status.label,
            style: AppTypography.wSemiBold.copyWith(fontSize: 12, color: color),
          ),
        ],
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// SEVERITY BADGE — For intelligence alerts
// ═══════════════════════════════════════════════════════════════════════════════

class SeverityBadge extends StatelessWidget {
  const SeverityBadge({super.key, required this.severity});
  final IntelligenceSeverity severity;

  Color _color() {
    switch (severity) {
      case IntelligenceSeverity.info: return AppColors.info;
      case IntelligenceSeverity.attention: return AppColors.warning;
      case IntelligenceSeverity.warning: return Colors.orange;
      case IntelligenceSeverity.critical: return AppColors.error;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _color();
    return StatusBadge(label: severity.label, color: color);
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// INTELLIGENCE ALERT CARD — AI insights display
// ═══════════════════════════════════════════════════════════════════════════════

class IntelligenceAlertCard extends StatelessWidget {
  const IntelligenceAlertCard({
    super.key,
    required this.alert,
    this.onAcknowledge,
    this.onResolve,
    this.onTap,
  });

  final IntelligenceAlert alert;
  final VoidCallback? onAcknowledge;
  final VoidCallback? onResolve;
  final VoidCallback? onTap;

  IconData _icon() {
    switch (alert.alertType) {
      case IntelligenceAlertType.churnPrediction: return Icons.person_off;
      case IntelligenceAlertType.anomalyDetection: return Icons.warning_amber;
      case IntelligenceAlertType.engagementDrop: return Icons.trending_down;
      case IntelligenceAlertType.upsellOpportunity: return Icons.attach_money;
      case IntelligenceAlertType.revenueForecast: return Icons.show_chart;
      case IntelligenceAlertType.costOptimization: return Icons.savings;
      case IntelligenceAlertType.infrastructureBottleneck: return Icons.speed;
      case IntelligenceAlertType.supportNeeded: return Icons.support_agent;
      case IntelligenceAlertType.unusualUsage: return Icons.analytics;
      case IntelligenceAlertType.growthOpportunity: return Icons.rocket_launch;
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      elevation: alert.isAcknowledged ? Spacings.elevationNone : Spacings.elevationSm,
      shape: RoundedRectangleBorder(borderRadius: Spacings.borderRadiusMd),
      child: InkWell(
        onTap: onTap,
        borderRadius: Spacings.borderRadiusMd,
        child: Padding(
          padding: Spacings.paddingAll,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(_icon(), color: cs.primary, size: Spacings.lgIcon),
                  const SizedBox(width: Spacings.sm),
                  Expanded(
                    child: Text(alert.title, style: AppTypography.wSemiBold.copyWith(fontSize: 14)),
                  ),
                  SeverityBadge(severity: alert.severity),
                ],
              ),
              const SizedBox(height: Spacings.sm),
              Text(
                alert.description,
                style: AppTypography.wRegular.copyWith(fontSize: 13, color: cs.onSurface.withValues(alpha: 0.7)),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              if (alert.confidenceScore != null) ...[
                const SizedBox(height: Spacings.sm),
                Row(
                  children: [
                    Text('Confidence: ', style: AppTypography.wRegular.copyWith(fontSize: 11, color: cs.onSurface.withValues(alpha: 0.5))),
                    Text('${alert.confidenceScore!.toStringAsFixed(0)}%',
                      style: AppTypography.wSemiBold.copyWith(fontSize: 11, color: cs.primary)),
                  ],
                ),
              ],
              if (!alert.isAcknowledged || !alert.isResolved) ...[
                const SizedBox(height: Spacings.md),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (!alert.isAcknowledged)
                      TextButton(
                        onPressed: onAcknowledge,
                        child: const Text('Acknowledge'),
                      ),
                    if (!alert.isResolved) ...[
                      const SizedBox(width: Spacings.sm),
                      FilledButton.tonal(
                        onPressed: onResolve,
                        child: const Text('Resolve'),
                      ),
                    ],
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// SECTION HEADER — Reusable section title with optional action
// ═══════════════════════════════════════════════════════════════════════════════

class SectionHeader extends StatelessWidget {
  const SectionHeader({super.key, required this.title, this.subtitle, this.action});
  final String title;
  final String? subtitle;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: AppTypography.wBold.copyWith(fontSize: 18)),
              if (subtitle != null)
                Text(subtitle!, style: AppTypography.wRegular.copyWith(fontSize: 13, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6))),
            ],
          ),
        ),
        if (action != null) action!,
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// FILTER CHIP GROUP — For filtering lists by enum values
// ═══════════════════════════════════════════════════════════════════════════════

class FilterChipGroup<T> extends StatelessWidget {
  const FilterChipGroup({
    super.key,
    required this.items,
    required this.selected,
    required this.onSelected,
    required this.labelBuilder,
    this.label = 'Filter',
  });
  final List<T> items;
  final T? selected;
  final ValueChanged<T?> onSelected;
  final String Function(T) labelBuilder;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: Spacings.sm,
      runSpacing: Spacings.sm,
      children: [
        FilterChip(
          label: Text('All'),
          selected: selected == null,
          onSelected: (_) => onSelected(null),
        ),
        ...items.map((item) => FilterChip(
          label: Text(labelBuilder(item)),
          selected: selected == item,
          onSelected: (_) => onSelected(selected == item ? null : item),
        )),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// SEARCH BAR — Reusable search input
// ═══════════════════════════════════════════════════════════════════════════════

class AdminSearchBar extends StatelessWidget {
  const AdminSearchBar({super.key, required this.onChanged, this.hint = 'Search...', this.controller});
  final ValueChanged<String> onChanged;
  final String hint;
  final TextEditingController? controller;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: const Icon(Icons.search, size: Spacings.mdIcon),
        border: OutlineInputBorder(borderRadius: Spacings.borderRadiusMd),
        contentPadding: Spacings.paddingInput,
        isDense: true,
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// EMPTY/ERROR/LOADING States
// ═══════════════════════════════════════════════════════════════════════════════

class AdminEmptyState extends StatelessWidget {
  const AdminEmptyState({super.key, required this.message, this.icon, this.action});
  final String message;
  final IconData? icon;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: Spacings.paddingXl,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon ?? Icons.inbox_outlined, size: 64, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.2)),
            const SizedBox(height: Spacings.lg),
            Text(message, style: AppTypography.wRegular.copyWith(fontSize: 14, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5)), textAlign: TextAlign.center),
            if (action != null) ...[const SizedBox(height: Spacings.lg), action!],
          ],
        ),
      ),
    );
  }
}
