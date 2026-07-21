import 'package:flutter/material.dart';

import '../../../../core/themes/app_colors.dart';
import '../../../../core/themes/app_typography.dart';
import '../../../../core/themes/spacings.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../question_bank/presentation/widgets/question_type_badge.dart';
import '../../domain/entities/cbt_entities.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../features/cbt_engine/domain/entities/cbt_entities.dart';


// ═══════════════════════════════════════════════════════════════════════
// EXAM CARD
// ═══════════════════════════════════════════════════════════════════════

/// Card for exam listing showing title, subject, status, timing,
/// duration, marks, student stats, and action buttons.
class ExamCard extends StatelessWidget {
  const ExamCard({
    super.key,
    required this.exam,
    this.totalStudents = 0,
    this.completedStudents = 0,
    this.onEdit,
    this.onMonitor,
    this.onResults,
    this.onClone,
    this.onArchive,
    this.onTap,
  });

  final ExamEntity exam;
  final int totalStudents;
  final int completedStudents;
  final VoidCallback? onEdit;
  final VoidCallback? onMonitor;
  final VoidCallback? onResults;
  final VoidCallback? onClone;
  final VoidCallback? onArchive;
  final VoidCallback? onTap;

  Color _statusColor(BuildContext context) {
    final isDark = context.isDarkMode;
    return switch (exam.status) {
      ExamStatus.draft => const Color(0xFF9CA3AF),
      ExamStatus.published => const Color(0xFF3B82F6),
      ExamStatus.active => const Color(0xFF22C55E),
      ExamStatus.completed => const Color(0xFF6366F1),
      ExamStatus.archived => const Color(0xFF78716C),
      ExamStatus.cancelled => const Color(0xFFEF4444),
    };
  }

  IconData _statusIcon() {
    return switch (exam.status) {
      ExamStatus.draft => Icons.edit_note_rounded,
      ExamStatus.published => Icons.publish_rounded,
      ExamStatus.active => Icons.play_circle_rounded,
      ExamStatus.completed => Icons.check_circle_rounded,
      ExamStatus.archived => Icons.archive_rounded,
      ExamStatus.cancelled => Icons.cancel_rounded,
    };
  }

  String _formatDate(DateTime dt) {
    const months = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[dt.month]} ${dt.day}, ${dt.year}';
  }

  String _formatTime(DateTime dt) {
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  double get _completionRate =>
      totalStudents > 0 ? completedStudents / totalStudents : 0.0;

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;
    final tt = context.textTheme;
    final isDark = context.isDarkMode;
    final statusColor = _statusColor(context);

    return AppCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Top Row: Title + Status Badge ───────────────────────────
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  exam.title,
                  style: tt.titleMedium?.copyWith(
                    fontWeight: AppTypography.wSemiBold,
                    color: cs.onSurface,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: Spacings.sm),
              _buildStatusBadge(context, statusColor),
            ],
          ),

          if (exam.description != null && exam.description!.isNotEmpty) ...[
            const SizedBox(height: Spacings.xs),
            Text(
              exam.description!,
              style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],

          const SizedBox(height: Spacings.md),

          // ── Info Chips ──────────────────────────────────────────────
          Wrap(
            spacing: Spacings.sm,
            runSpacing: Spacings.sm,
            children: [
              _buildInfoChip(
                context,
                icon: Icons.subject_rounded,
                label: exam.subjectId,
              ),
              _buildInfoChip(
                context,
                icon: Icons.class_rounded,
                label: exam.classId,
              ),
              _buildInfoChip(
                context,
                icon: Icons.timer_rounded,
                label: '${exam.timeLimitMinutes} min',
              ),
              _buildInfoChip(
                context,
                icon: Icons.assessment_rounded,
                label: '${exam.totalMarks.toInt()} marks',
              ),
            ],
          ),

          const SizedBox(height: Spacings.md),

          // ── Schedule ────────────────────────────────────────────────
          Row(
            children: [
              Icon(Icons.calendar_today_rounded,
                  size: Spacings.smIcon, color: cs.onSurfaceVariant),
              const SizedBox(width: Spacings.xs),
              Text(
                '${_formatDate(exam.startTime)} · ${_formatTime(exam.startTime)} – ${_formatTime(exam.endTime)}',
                style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
              ),
            ],
          ),

          // ── Student Progress ────────────────────────────────────────
          if (totalStudents > 0) ...[
            const SizedBox(height: Spacings.md),
            Row(
              children: [
                Icon(Icons.people_rounded,
                    size: Spacings.smIcon, color: cs.onSurfaceVariant),
                const SizedBox(width: Spacings.xs),
                Text(
                  '$completedStudents / $totalStudents completed',
                  style: tt.bodySmall?.copyWith(
                    fontWeight: AppTypography.wSemiBold,
                    color: cs.onSurfaceVariant,
                  ),
                ),
                const SizedBox(width: Spacings.sm),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(Spacings.smRadius),
                    child: LinearProgressIndicator(
                      value: _completionRate,
                      minHeight: 4.0,
                      backgroundColor: cs.surfaceContainerHighest,
                      color: AppColors.successOf(cs.brightness),
                      borderRadius: BorderRadius.circular(Spacings.smRadius),
                    ),
                  ),
                ),
              ],
            ),
          ],

          const SizedBox(height: Spacings.md),

          // ── Action Buttons ──────────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (exam.status.isEditable && onEdit != null)
                _actionButton(
                  context,
                  icon: Icons.edit_rounded,
                  label: 'Edit',
                  onTap: onEdit!,
                ),
              if (exam.status == ExamStatus.active && onMonitor != null) ...[
                const SizedBox(width: Spacings.sm),
                _actionButton(
                  context,
                  icon: Icons.visibility_rounded,
                  label: 'Monitor',
                  onTap: onMonitor!,
                  color: AppColors.successOf(cs.brightness),
                ),
              ],
              if (exam.status == ExamStatus.completed && onResults != null) ...[
                const SizedBox(width: Spacings.sm),
                _actionButton(
                  context,
                  icon: Icons.bar_chart_rounded,
                  label: 'Results',
                  onTap: onResults!,
                  color: AppColors.infoOf(cs.brightness),
                ),
              ],
              if (onClone != null) ...[
                const SizedBox(width: Spacings.sm),
                _actionButton(
                  context,
                  icon: Icons.content_copy_rounded,
                  label: 'Clone',
                  onTap: onClone!,
                ),
              ],
              if (exam.status != ExamStatus.archived && onArchive != null) ...[
                const SizedBox(width: Spacings.sm),
                _actionButton(
                  context,
                  icon: Icons.archive_outlined,
                  label: 'Archive',
                  onTap: onArchive!,
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(BuildContext context, Color color) {
    final tt = context.textTheme;
    final isDark = context.isDarkMode;
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
          Icon(_statusIcon(), size: 14.0, color: color),
          const SizedBox(width: Spacings.xs),
          Text(
            exam.status.label,
            style: tt.labelSmall?.copyWith(
              fontWeight: AppTypography.wSemiBold,
              color: isDark ? color.withValues(alpha: 0.9) : color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(
    BuildContext context, {
    required IconData icon,
    required String label,
  }) {
    final cs = context.colorScheme;
    final tt = context.textTheme;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Spacings.sm,
        vertical: Spacings.xs,
      ),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(Spacings.smRadius),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14.0, color: cs.onSurfaceVariant),
          const SizedBox(width: Spacings.xs),
          Text(
            label,
            style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
          ),
        ],
      ),
    );
  }

  Widget _actionButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color? color,
  }) {
    final cs = context.colorScheme;
    final effectiveColor = color ?? cs.onSurfaceVariant;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(Spacings.smRadius),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: Spacings.sm,
          vertical: Spacings.xs,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(Spacings.smRadius),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16.0, color: effectiveColor),
            const SizedBox(width: Spacings.xs),
            Text(
              label,
              style: TextStyle(
                fontSize: 12.0,
                fontWeight: AppTypography.wSemiBold,
                color: effectiveColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
