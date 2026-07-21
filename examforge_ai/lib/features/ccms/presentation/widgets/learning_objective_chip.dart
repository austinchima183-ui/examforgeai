import 'package:flutter/material.dart';

import '../../../../../core/core.dart';
import '../../domain/entities/ccms_entities.dart';

/// Chip displaying a learning objective with code prefix, description,
/// and Bloom level color dot.
///
/// Features:
/// - Code prefix (e.g., "LO-1", "OBJ-3.2")
/// - Description text (truncated to 2 lines)
/// - Bloom level color dot indicator
/// - Tap to show full details via dialog
class LearningObjectiveChip extends StatelessWidget {
  const LearningObjectiveChip({
    super.key,
    required this.objective,
    this.onTap,
    this.onRemove,
    this.showCode = true,
  });

  /// The learning objective to display.
  final LearningObjective objective;

  /// Callback when the chip is tapped (to show full details).
  final VoidCallback? onTap;

  /// Callback when the remove/delete icon is pressed.
  final VoidCallback? onRemove;

  /// Whether to display the code prefix.
  final bool showCode;

  // ─── Bloom Level Color ─────────────────────────────────────────────────

  Color _bloomColor(BloomTaxonomy bloom) {
    return switch (bloom) {
      BloomTaxonomy.remember => const Color(0xFF6366F1),
      BloomTaxonomy.understand => const Color(0xFF8B5CF6),
      BloomTaxonomy.apply => const Color(0xFF06B6D4),
      BloomTaxonomy.analyze => const Color(0xFFF59E0B),
      BloomTaxonomy.evaluate => const Color(0xFFEF4444),
      BloomTaxonomy.create => const Color(0xFFEC4899),
    };
  }

  // ─── Build ──────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final color = _bloomColor(objective.bloomLevel);
    final cs = context.colorScheme;
    final isDark = context.isDarkMode;

    return GestureDetector(
      onTap: onTap ?? () => _showDetailsDialog(context),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: Spacings.sm,
          vertical: Spacings.xs,
        ),
        decoration: BoxDecoration(
          color: color.withOpacity(isDark ? 0.15 : 0.08),
          borderRadius: Spacings.borderRadiusSm,
          border: Border.all(
            color: color.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Bloom level color dot
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color,
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(0.4),
                    blurRadius: 3,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
            ),
            const SizedBox(width: Spacings.sm),

            // Code prefix badge
            if (showCode && objective.code.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: Spacings.xs,
                  vertical: 1,
                ),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  objective.code,
                  style: AppTypography.labelSmall.copyWith(
                    color: color,
                    fontWeight: AppTypography.wBold,
                    fontSize: 10,
                  ),
                ),
              ),
              const SizedBox(width: Spacings.sm),
            ],

            // Description (truncated)
            Flexible(
              child: Text(
                objective.description,
                style: AppTypography.bodySmall.copyWith(
                  color: cs.onSurface,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),

            // Remove button
            if (onRemove != null) ...[
              const SizedBox(width: Spacings.xs),
              GestureDetector(
                onTap: onRemove,
                child: Icon(
                  Icons.close_rounded,
                  size: 14,
                  color: cs.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ─── Details Dialog ─────────────────────────────────────────────────────

  void _showDetailsDialog(BuildContext context) {
    final color = _bloomColor(objective.bloomLevel);
    final cs = context.colorScheme;
    final tt = context.textTheme;

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Row(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color,
              ),
            ),
            const SizedBox(width: Spacings.sm),
            Expanded(
              child: Text(
                objective.code.isNotEmpty
                    ? objective.code
                    : 'Learning Objective',
                style: tt.titleSmall?.copyWith(
                  fontWeight: AppTypography.wSemiBold,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Bloom level
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: Spacings.sm,
                vertical: Spacings.xs,
              ),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: Spacings.borderRadiusSm,
              ),
              child: Text(
                objective.bloomLevel.label,
                style: AppTypography.labelSmall.copyWith(
                  color: color,
                  fontWeight: AppTypography.wSemiBold,
                ),
              ),
            ),
            const SizedBox(height: Spacings.md),
            // Full description
            Text(
              objective.description,
              style: tt.bodyMedium?.copyWith(color: cs.onSurface),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
