import 'package:flutter/material.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/themes/app_colors.dart';
import '../../../../core/themes/app_typography.dart';
import '../../../../core/themes/spacings.dart';
import '../../domain/entities/parent_portal_entities.dart';

// ═══════════════════════════════════════════════════════════════════════
// CHILD SUMMARY CARD
// ═══════════════════════════════════════════════════════════════════════

/// Card widget showing a child's summary for the parent dashboard.
///
/// Displays a large avatar, child name, class, relationship badge,
/// attendance rate progress bar, pending assignments count, and a few
/// latest result score badges. Tapping navigates to the child's profile.
///
/// ```dart
/// ChildSummaryCard(
///   child: myChildSummary,
///   onTap: () => navigateToProfile(child.studentId),
/// )
/// ```
class ChildSummaryCard extends StatelessWidget {
  const ChildSummaryCard({
    super.key,
    required this.child,
    this.onTap,
  });

  /// The child summary data to display.
  final ChildSummaryEntity child;

  /// Callback when the card is tapped.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;
    final tt = context.textTheme;
    final isDark = context.isDarkMode;

    return Card(
      elevation: Spacings.elevationSm,
      shadowColor: cs.shadow.withValues(alpha: 0.08),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Spacings.lgRadius),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(Spacings.lgRadius),
        child: Padding(
          padding: const EdgeInsets.all(Spacings.lg),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Left: Avatar + Info ───────────────────────────────
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Avatar row
                    Row(
                      children: [
                        _buildLargeAvatar(cs, isDark),
                        const SizedBox(width: Spacings.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Name
                              Text(
                                child.studentName,
                                style: tt.titleMedium?.copyWith(
                                  fontWeight: AppTypography.wBold,
                                  color: cs.onSurface,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: Spacings.xs),
                              // Class
                              if (child.className != null)
                                Text(
                                  child.className!,
                                  style: tt.bodySmall?.copyWith(
                                    color: cs.onSurfaceVariant,
                                  ),
                                ),
                              const SizedBox(height: Spacings.xs),
                              // Relationship badge
                              _buildRelationshipBadge(cs, isDark),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: Spacings.md),

                    // ── Attendance Rate ─────────────────────────────
                    _buildAttendanceRow(cs, tt, isDark),

                    const SizedBox(height: Spacings.md),

                    // ── Pending Assignments ─────────────────────────
                    if (child.pendingAssignmentsCount > 0)
                      _buildPendingRow(cs, tt)
                    else
                      _buildNoPendingRow(cs, tt),

                    // ── Latest Results ─────────────────────────────
                    if (child.latestResults.isNotEmpty) ...[
                      const SizedBox(height: Spacings.md),
                      _buildLatestResults(cs, tt, isDark),
                    ],
                  ],
                ),
              ),

              // ── Right: Arrow ──────────────────────────────────────
              const SizedBox(width: Spacings.sm),
              Icon(
                Icons.chevron_right_rounded,
                color: cs.onSurfaceVariant,
                size: Spacings.lgIcon,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Large Avatar ─────────────────────────────────────────────────

  Widget _buildLargeAvatar(ColorScheme cs, bool isDark) {
    final initial = child.studentName.isNotEmpty
        ? child.studentName[0].toUpperCase()
        : '?';

    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        color: cs.primary.withValues(alpha: isDark ? 0.25 : 0.12),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          initial,
          style: TextStyle(
            fontSize: 22,
            fontWeight: AppTypography.wBold,
            color: cs.primary,
            height: 1.0,
          ),
        ),
      ),
    );
  }

  // ─── Relationship Badge ───────────────────────────────────────────

  Widget _buildRelationshipBadge(ColorScheme cs, bool isDark) {
    final isParent = child.relationship.toLowerCase() == 'father' ||
        child.relationship.toLowerCase() == 'mother';
    final color = isParent ? AppColors.info : AppColors.warning;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Spacings.sm,
        vertical: Spacings.xs,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.20 : 0.12),
        borderRadius: BorderRadius.circular(Spacings.fullRadius),
      ),
      child: Text(
        child.relationship,
        style: TextStyle(
          fontSize: 10,
          fontWeight: AppTypography.wSemiBold,
          color: color,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  // ─── Attendance Row ───────────────────────────────────────────────

  Widget _buildAttendanceRow(ColorScheme cs, TextTheme tt, bool isDark) {
    final rate = child.attendanceSummary.attendanceRate;
    final pct = (rate * 100).round();
    final barColor = pct >= 75
        ? AppColors.success
        : pct >= 50
            ? AppColors.warning
            : AppColors.error;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Attendance',
              style: tt.labelMedium?.copyWith(
                color: cs.onSurfaceVariant,
                fontWeight: AppTypography.wMedium,
              ),
            ),
            Text(
              '$pct%',
              style: tt.labelLarge?.copyWith(
                fontWeight: AppTypography.wBold,
                color: barColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: Spacings.xs),
        ClipRRect(
          borderRadius: BorderRadius.circular(Spacings.fullRadius),
          child: LinearProgressIndicator(
            value: rate.clamp(0.0, 1.0),
            backgroundColor: barColor.withValues(alpha: isDark ? 0.15 : 0.12),
            valueColor: AlwaysStoppedAnimation<Color>(barColor),
            minHeight: 6,
          ),
        ),
      ],
    );
  }

  // ─── Pending Assignments Row ──────────────────────────────────────

  Widget _buildPendingRow(ColorScheme cs, TextTheme tt) {
    return Row(
      children: [
        const Icon(
          Icons.assignment_outlined,
          size: Spacings.smIcon,
          color: AppColors.warning,
        ),
        const SizedBox(width: Spacings.xs),
        Text(
          '${child.pendingAssignmentsCount} pending assignment${child.pendingAssignmentsCount == 1 ? '' : 's'}',
          style: tt.bodySmall?.copyWith(
            color: AppColors.warning,
            fontWeight: AppTypography.wMedium,
          ),
        ),
      ],
    );
  }

  Widget _buildNoPendingRow(ColorScheme cs, TextTheme tt) {
    return Row(
      children: [
        const Icon(
          Icons.check_circle_outline_rounded,
          size: Spacings.smIcon,
          color: AppColors.success,
        ),
        const SizedBox(width: Spacings.xs),
        Text(
          'No pending assignments',
          style: tt.bodySmall?.copyWith(
            color: AppColors.success,
            fontWeight: AppTypography.wMedium,
          ),
        ),
      ],
    );
  }

  // ─── Latest Results ───────────────────────────────────────────────

  Widget _buildLatestResults(ColorScheme cs, TextTheme tt, bool isDark) {
    final results = child.latestResults.take(3).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Latest Results',
          style: tt.labelMedium?.copyWith(
            color: cs.onSurfaceVariant,
            fontWeight: AppTypography.wMedium,
          ),
        ),
        const SizedBox(height: Spacings.sm),
        Wrap(
          spacing: Spacings.sm,
          runSpacing: Spacings.sm,
          children: results.map((r) => _buildScoreBadge(r, cs, tt, isDark)).toList(),
        ),
      ],
    );
  }

  Widget _buildScoreBadge(
    ChildResultEntity result,
    ColorScheme cs,
    TextTheme tt,
    bool isDark,
  ) {
    final pct = result.totalMarks > 0
        ? (result.score / result.totalMarks) * 100
        : result.score;
    final color = pct >= 70
        ? AppColors.success
        : pct >= 50
            ? AppColors.warning
            : AppColors.error;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Spacings.sm,
        vertical: Spacings.xs,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.20 : 0.10),
        borderRadius: BorderRadius.circular(Spacings.smRadius),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (result.subjectName != null) ...[
            Text(
              result.subjectName!,
              style: tt.labelSmall?.copyWith(
                color: color,
                fontWeight: AppTypography.wMedium,
              ),
            ),
            const SizedBox(width: Spacings.xs),
          ],
          Text(
            result.grade,
            style: tt.labelMedium?.copyWith(
              color: color,
              fontWeight: AppTypography.wBold,
            ),
          ),
        ],
      ),
    );
  }
}
