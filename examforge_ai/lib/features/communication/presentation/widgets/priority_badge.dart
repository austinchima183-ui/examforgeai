import 'package:flutter/material.dart';

import '../../../../core/themes/app_typography.dart';
import '../../../../core/themes/spacings.dart';
import '../../../../core/extensions/context_extensions.dart';

// ─── PriorityBadge ────────────────────────────────────────────────────────────

/// A color-coded priority indicator badge.
///
/// - **low** → grey
/// - **normal** → blue
/// - **high** → orange
/// - **urgent** → red
///
/// ```dart
/// PriorityBadge(priority: 'urgent')
/// PriorityBadge(priority: 'normal', showDot: false)
/// ```
class PriorityBadge extends StatelessWidget {
  const PriorityBadge({
    super.key,
    required this.priority,
    this.showDot = true,
  });

  /// Priority level string: 'low', 'normal', 'high', or 'urgent'.
  final String priority;

  /// Whether to show a small coloured dot before the label.
  final bool showDot;

  // ─── Color Mapping ────────────────────────────────────────────────────

  Color _badgeColor() {
    return switch (priority.toLowerCase()) {
      'low' => const Color(0xFF6B7280),
      'normal' => const Color(0xFF2563EB),
      'high' => const Color(0xFFEA580C),
      'urgent' => const Color(0xFFDC2626),
      _ => const Color(0xFF6B7280),
    };
  }

  String _label() {
    return switch (priority.toLowerCase()) {
      'low' => 'Low',
      'normal' => 'Normal',
      'high' => 'High',
      'urgent' => 'Urgent',
      _ => priority.isNotEmpty
          ? '${priority[0].toUpperCase()}${priority.substring(1)}'
          : 'Normal',
    };
  }

  // ─── Build ─────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    final color = _badgeColor();

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Spacings.sm,
        vertical: Spacings.xs,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.25 : 0.12),
        borderRadius: BorderRadius.circular(Spacings.smRadius),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showDot) ...[
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: Spacings.xs),
          ],
          Text(
            _label(),
            style: TextStyle(
              fontFamily: AppTypography.fontFamily,
              fontSize: 10,
              fontWeight: AppTypography.wSemiBold,
              letterSpacing: AppTypography.lsCaption,
              height: 1.4,
              color: isDark ? color.withValues(alpha: 0.9) : color,
            ),
          ),
          if (priority.toLowerCase() == 'urgent') ...[
            const SizedBox(width: Spacings.xs),
            Icon(
              Icons.priority_high_rounded,
              size: 10,
              color: isDark ? color.withValues(alpha: 0.9) : color,
            ),
          ],
        ],
      ),
    );
  }
}
