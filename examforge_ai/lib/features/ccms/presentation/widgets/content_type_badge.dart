import 'package:flutter/material.dart';

import '../../../../../core/core.dart';
import '../../domain/entities/ccms_entities.dart';

/// Small colored badge widget for content type.
///
/// Each content type has a distinct color and icon for quick visual
/// identification in lists and detail views.
///
/// Colors by type:
/// - question: blue
/// - explanation: green
/// - markingScheme: orange
/// - teacherNote: purple
/// - lessonNote: teal
/// - worksheet: indigo
/// - practicalGuide: brown
/// - readingMaterial: cyan
/// - videoScript: pink
/// - assessmentRubric: deepOrange
class ContentTypeBadge extends StatelessWidget {
  const ContentTypeBadge({
    super.key,
    required this.contentType,
    this.small = false,
    this.onTap,
  });

  /// The content type to display.
  final ContentType contentType;

  /// When true, renders a compact version with smaller text and padding.
  final bool small;

  /// Optional tap handler for the badge.
  final VoidCallback? onTap;

  // ─── Color Mapping ──────────────────────────────────────────────────────

  Color _color() {
    return switch (contentType) {
      ContentType.question => const Color(0xFF3B82F6), // blue
      ContentType.explanation => const Color(0xFF10B981), // green
      ContentType.markingScheme => const Color(0xFFF59E0B), // orange
      ContentType.teacherNote => const Color(0xFF8B5CF6), // purple
      ContentType.lessonNote => const Color(0xFF14B8A6), // teal
      ContentType.worksheet => const Color(0xFF6366F1), // indigo
      ContentType.practicalGuide => const Color(0xFF92400E), // brown
      ContentType.readingMaterial => const Color(0xFF06B6D4), // cyan
      ContentType.videoScript => const Color(0xFFEC4899), // pink
      ContentType.assessmentRubric => const Color(0xFFEA580C), // deepOrange
    };
  }

  // ─── Icon Mapping ───────────────────────────────────────────────────────

  IconData _icon() {
    return switch (contentType) {
      ContentType.question => Icons.help_outline_rounded,
      ContentType.explanation => Icons.lightbulb_outline_rounded,
      ContentType.markingScheme => Icons.grading_rounded,
      ContentType.teacherNote => Icons.sticky_note_2_outlined,
      ContentType.lessonNote => Icons.menu_book_rounded,
      ContentType.worksheet => Icons.assignment_outlined,
      ContentType.practicalGuide => Icons.science_outlined,
      ContentType.readingMaterial => Icons.auto_stories_rounded,
      ContentType.videoScript => Icons.videocam_outlined,
      ContentType.assessmentRubric => Icons.checklist_rtl_rounded,
    };
  }

  @override
  Widget build(BuildContext context) {
    final color = _color();
    final isDark = context.isDarkMode;
    final fontSize = small ? 10.0 : 11.0;
    final iconSize = small ? 12.0 : 14.0;
    final hPadding = small ? Spacings.xs : Spacings.sm;
    final vPadding = small ? 1.0 : 3.0;

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
              contentType.label,
              style: AppTypography.labelSmall!.copyWith(
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
