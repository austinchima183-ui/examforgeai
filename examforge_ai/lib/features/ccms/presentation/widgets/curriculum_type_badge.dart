import 'package:flutter/material.dart';

import '../../../../../core/core.dart';
import '../../domain/entities/ccms_entities.dart';

/// Badge showing curriculum type with distinct colors.
///
/// Colors:
/// - NERDC: green
/// - WAEC: blue
/// - NECO: orange
/// - NABTEB: purple
/// - Custom: grey
/// - International: teal
class CurriculumTypeBadge extends StatelessWidget {
  const CurriculumTypeBadge({
    super.key,
    required this.type,
    this.small = false,
    this.onTap,
  });

  /// The curriculum type to display.
  final CurriculumType type;

  /// When true, renders a compact version.
  final bool small;

  /// Optional tap handler.
  final VoidCallback? onTap;

  // ─── Color Mapping ──────────────────────────────────────────────────────

  Color _color() {
    return switch (type) {
      CurriculumType.nerdc => const Color(0xFF059669), // green
      CurriculumType.waec => const Color(0xFF2563EB), // blue
      CurriculumType.neco => const Color(0xFFF59E0B), // orange
      CurriculumType.nabteb => const Color(0xFF7C3AED), // purple
      CurriculumType.custom => const Color(0xFF6B7280), // grey
      CurriculumType.international => const Color(0xFF0891B2), // teal
    };
  }

  // ─── Icon Mapping ───────────────────────────────────────────────────────

  IconData _icon() {
    return switch (type) {
      CurriculumType.nerdc => Icons.policy_rounded,
      CurriculumType.waec => Icons.school_rounded,
      CurriculumType.neco => Icons.workspace_premium_rounded,
      CurriculumType.nabteb => Icons.engineering_rounded,
      CurriculumType.custom => Icons.tune_rounded,
      CurriculumType.international => Icons.public_rounded,
    };
  }

  @override
  Widget build(BuildContext context) {
    final color = _color();
    final isDark = context.isDarkMode;
    final hPadding = small ? Spacings.xs : Spacings.sm;
    final vPadding = small ? 1.0 : 3.0;
    final iconSize = small ? 12.0 : 14.0;
    final fontSize = small ? 10.0 : 11.0;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: hPadding, vertical: vPadding),
        decoration: BoxDecoration(
          color: color.withOpacity(isDark ? 0.20 : 0.12),
          borderRadius: Spacings.borderRadiusSm,
          border: Border.all(
            color: color.withOpacity(0.25),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(_icon(), size: iconSize, color: color),
            SizedBox(width: small ? 2 : Spacings.xs),
            Text(
              type.label,
              style: AppTypography.labelSmall.copyWith(
                color: color,
                fontWeight: AppTypography.wSemiBold,
                fontSize: fontSize,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
