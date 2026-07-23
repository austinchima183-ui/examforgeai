import 'package:flutter/material.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/themes/app_typography.dart';
import '../../../../core/themes/spacings.dart';
import '../../domain/entities/student_portal_entities.dart';

// ═══════════════════════════════════════════════════════════════════════
// ASSIGNMENT STATUS BADGE
// ═══════════════════════════════════════════════════════════════════════

/// Status badge for assignment submissions.
///
/// Displays a color-coded chip for each [SubmissionStatus]:
/// - Draft (gray)
/// - Submitted (blue)
/// - Late (orange)
/// - Graded (green)
/// - Returned (purple)
/// - Resubmitted (amber)
///
/// ```dart
/// AssignmentStatusBadge(status: SubmissionStatus.graded)
/// AssignmentStatusBadge(status: SubmissionStatus.lateSubmitted, showIcon: false)
/// ```
class AssignmentStatusBadge extends StatelessWidget {
  const AssignmentStatusBadge({
    super.key,
    required this.status,
    this.showIcon = true,
  });

  /// The submission status to display.
  final SubmissionStatus status;

  /// Whether to include an icon in the badge.
  final bool showIcon;

  // ─── Color Mapping ─────────────────────────────────────────────────

  Color _statusColor() {
    return switch (status) {
      SubmissionStatus.draft => const Color(0xFF6B7280), // Gray
      SubmissionStatus.submitted => const Color(0xFF2563EB), // Blue
      SubmissionStatus.lateSubmitted => const Color(0xFFEA580C), // Orange
      SubmissionStatus.graded => const Color(0xFF16A34A), // Green
      SubmissionStatus.returned => const Color(0xFF7C3AED), // Purple
      SubmissionStatus.resubmitted => const Color(0xFFF59E0B), // Amber
    };
  }

  IconData _statusIcon() {
    return switch (status) {
      SubmissionStatus.draft => Icons.edit_note_rounded,
      SubmissionStatus.submitted => Icons.send_rounded,
      SubmissionStatus.lateSubmitted => Icons.schedule_rounded,
      SubmissionStatus.graded => Icons.grading_rounded,
      SubmissionStatus.returned => Icons.assignment_return_rounded,
      SubmissionStatus.resubmitted => Icons.replay_rounded,
    };
  }

  // ─── Build ─────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    final color = _statusColor();
    final bgColor = color.withValues(alpha: isDark ? 0.25 : 0.12);
    final fgColor = isDark ? color.withValues(alpha: 0.9) : color;

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
            Icon(_statusIcon(), size: 14, color: fgColor),
            const SizedBox(width: Spacings.xs),
          ],
          Text(
            status.label,
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
