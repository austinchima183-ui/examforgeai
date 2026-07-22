import 'package:flutter/material.dart';

import '../../../../../core/core.dart';
import '../../../../../shared/widgets/widgets.dart';
import '../../domain/entities/ccms_entities.dart';

/// Card for alert incidents with severity color, acknowledge/resolve buttons.
class AlertIncidentCard extends StatelessWidget {
  const AlertIncidentCard({
    super.key,
    required this.incident,
    this.onAcknowledge,
    this.onResolve,
  });

  final AlertIncident incident;
  final VoidCallback? onAcknowledge;
  final VoidCallback? onResolve;

  Color _severityColor(AlertSeverity severity) {
    return switch (severity) {
      AlertSeverity.info => AppColors.info,
      AlertSeverity.warning => AppColors.warning,
      AlertSeverity.critical => AppColors.error,
      AlertSeverity.emergency => const Color(0xFF7F1D1D),
    };
  }

  IconData _severityIcon(AlertSeverity severity) {
    return switch (severity) {
      AlertSeverity.info => Icons.info_outline_rounded,
      AlertSeverity.warning => Icons.warning_amber_rounded,
      AlertSeverity.critical => Icons.error_outline_rounded,
      AlertSeverity.emergency => Icons.dangerous_rounded,
    };
  }

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;
    final tt = context.textTheme;
    final color = _severityColor(incident.severity);

    return AppCard(
      borderColor: color.withOpacity(0.5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(Spacings.sm),
                decoration: BoxDecoration(
                  color: color.withOpacity(context.isDarkMode ? 0.20 : 0.12),
                  borderRadius: Spacings.borderRadiusSm,
                ),
                child: Icon(_severityIcon(incident.severity), size: Spacings.mdIcon, color: color),
              ),
              const SizedBox(width: Spacings.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Threshold exceeded: ${incident.currentValue} > ${incident.thresholdValue}',
                      style: tt.titleSmall?.copyWith(fontWeight: AppTypography.wSemiBold, color: cs.onSurface),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: Spacings.xs),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: Spacings.sm, vertical: 2),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.15),
                            borderRadius: Spacings.borderRadiusSm,
                          ),
                          child: Text(
                            incident.severity.label.toUpperCase(),
                            style: AppTypography.labelSmall!.copyWith(color: color, fontWeight: AppTypography.wBold),
                          ),
                        ),
                        const SizedBox(width: Spacings.sm),
                        Text(
                          _formatDate(incident.createdAt),
                          style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (incident.acknowledgedBy != null) ...[
            const SizedBox(height: Spacings.sm),
            Row(
              children: [
                Icon(Icons.person_outline_rounded, size: 14, color: cs.onSurfaceVariant),
                const SizedBox(width: Spacings.xs),
                Text(
                  'Acknowledged by ${incident.acknowledgedBy}',
                  style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                ),
              ],
            ),
          ],
          if (incident.resolvedAt != null) ...[
            const SizedBox(height: Spacings.xs),
            Row(
              children: [
                Icon(Icons.check_circle_outline_rounded, size: 14, color: AppColors.success),
                const SizedBox(width: Spacings.xs),
                Text(
                  'Resolved at ${_formatDate(incident.resolvedAt!)}',
                  style: tt.bodySmall?.copyWith(color: AppColors.success),
                ),
              ],
            ),
          ],
          if (onAcknowledge != null || onResolve != null) ...[
            const SizedBox(height: Spacings.md),
            Row(
              children: [
                if (onAcknowledge != null && incident.acknowledgedBy == null)
                  AppButton(
                    label: 'Acknowledge',
                    onPressed: onAcknowledge,
                    variant: AppButtonVariant.outlined,
                    size: AppButtonSize.small,
                    icon: Icons.check_rounded,
                  ),
                if (onResolve != null && incident.resolvedAt == null) ...[
                  const SizedBox(width: Spacings.sm),
                  AppButton(
                    label: 'Resolve',
                    onPressed: onResolve,
                    variant: AppButtonVariant.elevated,
                    size: AppButtonSize.small,
                    icon: Icons.done_all_rounded,
                  ),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}
