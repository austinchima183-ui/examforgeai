import 'package:flutter/material.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/themes/app_colors.dart';
import '../../../../core/themes/app_typography.dart';
import '../../../../core/themes/spacings.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../domain/entities/cbt_entities.dart';

// ═══════════════════════════════════════════════════════════════════════
// STUDENT PROGRESS CARD
// ═══════════════════════════════════════════════════════════════════════

/// Card for monitoring - shows one student's progress during an active exam.
///
/// Displays:
/// - Student name, avatar
/// - Current question / total questions
/// - Progress bar
/// - Time spent / time remaining
/// - Connection status indicator
/// - Violation count badge
/// - Flag for suspicious activity
/// - Force submit button
class StudentProgressCard extends StatelessWidget {
  const StudentProgressCard({
    super.key,
    required this.session,
    this.studentName = 'Student',
    this.totalQuestions = 0,
    this.timeSpent = Duration.zero,
    this.timeRemaining = Duration.zero,
    this.violationCount = 0,
    this.isSuspicious = false,
    this.onForceSubmit,
  });

  /// The active session for this student.
  final ExamSessionEntity session;

  /// Student display name.
  final String studentName;

  /// Total number of questions in the exam.
  final int totalQuestions;

  /// Time the student has spent on the exam so far.
  final Duration timeSpent;

  /// Time remaining for the student.
  final Duration timeRemaining;

  /// Number of monitoring violations detected.
  final int violationCount;

  /// Whether suspicious activity has been flagged.
  final bool isSuspicious;

  /// Callback to force-submit this student's exam.
  final VoidCallback? onForceSubmit;

  bool get _isConnected => session.connectionStatus == 'connected';
  bool get _isDisconnected => session.connectionStatus == 'disconnected';

  double get _progress => totalQuestions > 0
      ? session.questionsAnswered / totalQuestions
      : 0.0;

  String _formatDuration(Duration d) {
    final h = d.inHours.toString().padLeft(2, '0');
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;
    final tt = context.textTheme;
    final isDark = context.isDarkMode;

    return AppCard(
      borderColor: isSuspicious
          ? AppColors.errorOf(cs.brightness).withValues(alpha: 0.5)
          : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header: Avatar + Name + Status ─────────────────────────
          Row(
            children: [
              // Avatar with connection indicator
              Stack(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: cs.primary.withValues(alpha: 0.15),
                    child: Text(
                      studentName.isNotEmpty
                          ? studentName[0].toUpperCase()
                          : '?',
                      style: tt.titleMedium?.copyWith(
                        fontWeight: AppTypography.wBold,
                        color: cs.primary,
                      ),
                    ),
                  ),
                  // Connection dot
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: _isConnected
                            ? AppColors.successOf(cs.brightness)
                            : AppColors.errorOf(cs.brightness),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: cs.surface,
                          width: 2.0,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: Spacings.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            studentName,
                            style: tt.titleSmall?.copyWith(
                              fontWeight: AppTypography.wSemiBold,
                              color: cs.onSurface,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        // Violation badge
                        if (violationCount > 0)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: Spacings.sm,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.errorOf(cs.brightness)
                                  .withValues(alpha: isDark ? 0.25 : 0.12),
                              borderRadius:
                                  BorderRadius.circular(Spacings.smRadius),
                            ),
                            child: Text(
                              '$violationCount violation${violationCount > 1 ? 's' : ''}',
                              style: tt.labelSmall?.copyWith(
                                fontWeight: AppTypography.wBold,
                                color: AppColors.errorOf(cs.brightness),
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: Spacings.xs),
                    Text(
                      _isConnected
                          ? 'Connected'
                          : _isDisconnected
                              ? 'Disconnected'
                              : 'Reconnecting…',
                      style: tt.bodySmall?.copyWith(
                        color: _isConnected
                            ? AppColors.successOf(cs.brightness)
                            : _isDisconnected
                                ? AppColors.errorOf(cs.brightness)
                                : AppColors.warningOf(cs.brightness),
                        fontWeight: AppTypography.wSemiBold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // ── Suspicious activity banner ─────────────────────────────
          if (isSuspicious) ...[
            const SizedBox(height: Spacings.sm),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(Spacings.sm),
              decoration: BoxDecoration(
                color: AppColors.errorOf(cs.brightness)
                    .withValues(alpha: isDark ? 0.15 : 0.08),
                borderRadius: BorderRadius.circular(Spacings.smRadius),
                border: Border.all(
                  color: AppColors.errorOf(cs.brightness)
                      .withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    size: Spacings.smIcon,
                    color: AppColors.errorOf(cs.brightness),
                  ),
                  const SizedBox(width: Spacings.xs),
                  Expanded(
                    child: Text(
                      'Suspicious activity detected',
                      style: tt.bodySmall?.copyWith(
                        fontWeight: AppTypography.wSemiBold,
                        color: AppColors.errorOf(cs.brightness),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: Spacings.md),

          // ── Progress Info ──────────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Question ${session.currentQuestionIndex + 1} / $totalQuestions',
                style: tt.bodySmall?.copyWith(
                  fontWeight: AppTypography.wSemiBold,
                  color: cs.onSurface,
                ),
              ),
              Text(
                '${session.questionsAnswered} answered',
                style: tt.bodySmall?.copyWith(
                  color: cs.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: Spacings.xs),

          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(Spacings.smRadius),
            child: LinearProgressIndicator(
              value: _progress,
              minHeight: 6.0,
              backgroundColor: cs.surfaceContainerHighest,
              color: isSuspicious
                  ? AppColors.errorOf(cs.brightness)
                  : AppColors.successOf(cs.brightness),
              borderRadius: BorderRadius.circular(Spacings.smRadius),
            ),
          ),

          const SizedBox(height: Spacings.md),

          // ── Time Info ──────────────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _timeChip(
                context,
                icon: Icons.schedule_rounded,
                label: 'Spent',
                value: _formatDuration(timeSpent),
              ),
              _timeChip(
                context,
                icon: Icons.timer_rounded,
                label: 'Remaining',
                value: _formatDuration(timeRemaining),
                color: timeRemaining.inMinutes < 5
                    ? AppColors.warningOf(cs.brightness)
                    : null,
              ),
            ],
          ),

          // ── Flagged count ──────────────────────────────────────────
          if (session.questionsFlagged > 0) ...[
            const SizedBox(height: Spacings.sm),
            Row(
              children: [
                Icon(
                  Icons.flag_rounded,
                  size: Spacings.smIcon,
                  color: AppColors.warningOf(cs.brightness),
                ),
                const SizedBox(width: Spacings.xs),
                Text(
                  '${session.questionsFlagged} flagged',
                  style: tt.bodySmall?.copyWith(
                    color: AppColors.warningOf(cs.brightness),
                    fontWeight: AppTypography.wSemiBold,
                  ),
                ),
              ],
            ),
          ],

          // ── Force Submit Button ────────────────────────────────────
          if (onForceSubmit != null) ...[
            const SizedBox(height: Spacings.md),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onForceSubmit,
                icon: Icon(
                  Icons.stop_circle_outlined,
                  size: Spacings.smIcon,
                  color: AppColors.errorOf(cs.brightness),
                ),
                label: Text(
                  'Force Submit',
                  style: tt.labelMedium?.copyWith(
                    fontWeight: AppTypography.wSemiBold,
                    color: AppColors.errorOf(cs.brightness),
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(
                    color: AppColors.errorOf(cs.brightness).withValues(alpha: 0.5),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(Spacings.smRadius),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: Spacings.sm),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _timeChip(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    Color? color,
  }) {
    final cs = context.colorScheme;
    final tt = context.textTheme;
    final effectiveColor = color ?? cs.onSurface;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14.0, color: effectiveColor),
        const SizedBox(width: Spacings.xs),
        Text(
          '$label: ',
          style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
        ),
        Text(
          value,
          style: tt.bodySmall?.copyWith(
            fontWeight: AppTypography.wSemiBold,
            fontFamily: 'monospace',
            color: effectiveColor,
          ),
        ),
      ],
    );
  }
}
