import 'package:flutter/material.dart';

import '../../../../core/themes/app_colors.dart';
import '../../../../core/themes/app_typography.dart';
import '../../../../core/themes/spacings.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../domain/entities/student_portal_entities.dart';

// ═══════════════════════════════════════════════════════════════════════
// RESOURCE TYPE BADGE
// ═══════════════════════════════════════════════════════════════════════

/// Type badge for learning resources.
///
/// Displays an icon + label chip with a type-specific color for each
/// [StudentResourceType].
///
/// ```dart
/// ResourceTypeBadge(type: StudentResourceType.videoLink)
/// ResourceTypeBadge(type: StudentResourceType.pastQuestion, showIcon: false)
/// ```
class ResourceTypeBadge extends StatelessWidget {
  const ResourceTypeBadge({
    super.key,
    required this.type,
    this.showIcon = true,
  });

  /// The resource type to display.
  final StudentResourceType type;

  /// Whether to include the type icon.
  final bool showIcon;

  // ─── Color Mapping ─────────────────────────────────────────────────

  Color _typeColor() {
    return switch (type) {
      StudentResourceType.lessonNote => const Color(0xFF2563EB), // Blue
      StudentResourceType.worksheet => const Color(0xFF059669), // Emerald
      StudentResourceType.studyGuide => const Color(0xFF7C3AED), // Violet
      StudentResourceType.slide => const Color(0xFFEA580C), // Orange
      StudentResourceType.handout => const Color(0xFF0891B2), // Cyan
      StudentResourceType.recommendedReading => const Color(0xFF9333EA), // Purple
      StudentResourceType.videoLink => const Color(0xFFDC2626), // Red
      StudentResourceType.pastQuestion => const Color(0xFFD97706), // Amber
    };
  }

  IconData _typeIcon() {
    return switch (type) {
      StudentResourceType.lessonNote => Icons.note_rounded,
      StudentResourceType.worksheet => Icons.assignment_rounded,
      StudentResourceType.studyGuide => Icons.menu_book_rounded,
      StudentResourceType.slide => Icons.slideshow_rounded,
      StudentResourceType.handout => Icons.description_rounded,
      StudentResourceType.recommendedReading => Icons.auto_stories_rounded,
      StudentResourceType.videoLink => Icons.play_circle_outline_rounded,
      StudentResourceType.pastQuestion => Icons.history_edu_rounded,
    };
  }

  // ─── Build ─────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    final color = _typeColor();
    final bgColor = color.withOpacity(isDark ? 0.25 : 0.12);
    final fgColor = isDark ? color.withOpacity(0.9) : color;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Spacings.sm,
        vertical: Spacings.xs,
      ),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(Spacings.smRadius),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showIcon) ...[
            Icon(_typeIcon(), size: 14, color: fgColor),
            const SizedBox(width: Spacings.xs),
          ],
          Text(
            type.label,
            style: TextStyle(
              fontFamily: AppTypography.fontFamily,
              fontSize: 11,
              fontWeight: AppTypography.wSemiBold,
              letterSpacing: AppTypography.lsLabel,
              height: 1.33,
              color: fgColor,
            ),
          ),
        ],
      ),
    );
  }
}
