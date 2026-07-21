import 'package:flutter/material.dart';

import '../../../../../core/core.dart';
import '../../../../../shared/widgets/widgets.dart';
import '../../domain/entities/ccms_entities.dart';

/// Widget displaying an answer entry with expandable sections.
///
/// Features:
/// - Correct answer(s) highlighted in green
/// - Step-by-step explanation in expandable section
/// - Marking scheme in expandable section
/// - Common mistakes in warning-style section
/// - Alternative answers
/// - Verification badge
/// - Teacher notes in expandable section
class AnswerDisplay extends StatelessWidget {
  const AnswerDisplay({
    super.key,
    required this.entry,
    this.onVerify,
    this.onEdit,
  });

  /// The answer repository entry to display.
  final AnswerRepositoryEntry entry;

  /// Callback when verify is pressed.
  final VoidCallback? onVerify;

  /// Callback when edit is pressed.
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;
    final tt = context.textTheme;
    final isDark = context.isDarkMode;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header with verification status ──────────────────────────
          Row(
            children: [
              Icon(
                Icons.assignment_turned_in_rounded,
                size: Spacings.mdIcon,
                color: cs.primary,
              ),
              const SizedBox(width: Spacings.sm),
              Expanded(
                child: Text(
                  'Answer Repository Entry',
                  style: tt.titleSmall?.copyWith(
                    fontWeight: AppTypography.wSemiBold,
                    color: cs.onSurface,
                  ),
                ),
              ),
              _VerificationBadge(isVerified: entry.isVerified),
            ],
          ),
          const SizedBox(height: Spacings.lg),

          // ── Correct Answers (highlighted in green) ───────────────────
          if (entry.correctAnswers.isNotEmpty)
            _CorrectAnswersSection(answers: entry.correctAnswers),

          // ── Step-by-step explanation (expandable) ────────────────────
          if (entry.stepByStepExplanation != null &&
              entry.stepByStepExplanation!.isNotEmpty)
            _ExpandableSection(
              title: 'Step-by-Step Explanation',
              icon: Icons.format_list_numbered_rounded,
              color: cs.primary,
              isDark: isDark,
              child: Text(
                entry.stepByStepExplanation!,
                style: tt.bodyMedium?.copyWith(color: cs.onSurface),
              ),
            ),

          // ── Marking scheme (expandable) ──────────────────────────────
          if (entry.markingScheme != null)
            _ExpandableSection(
              title: 'Marking Scheme',
              icon: Icons.grading_rounded,
              color: AppColors.info,
              isDark: isDark,
              child: _MapDisplay(data: entry.markingScheme!),
            ),

          // ── Common mistakes (warning-style) ──────────────────────────
          if (entry.commonMistakes != null &&
              entry.commonMistakes!.isNotEmpty) ...[
            const SizedBox(height: Spacings.md),
            _WarningSection(
              title: 'Common Mistakes',
              icon: Icons.warning_amber_rounded,
              mistakes: entry.commonMistakes!,
            ),
          ],

          // ── Alternative answers ──────────────────────────────────────
          if (entry.alternativeAnswers != null &&
              entry.alternativeAnswers!.isNotEmpty) ...[
            const SizedBox(height: Spacings.md),
            _AlternativeAnswersSection(
              answers: entry.alternativeAnswers!,
            ),
          ],

          // ── Teacher notes (expandable) ───────────────────────────────
          if (entry.teacherNotes != null &&
              entry.teacherNotes!.isNotEmpty) ...[
            const SizedBox(height: Spacings.md),
            _ExpandableSection(
              title: 'Teacher Notes',
              icon: Icons.sticky_note_2_outlined,
              color: const Color(0xFF8B5CF6), // purple
              isDark: isDark,
              child: Text(
                entry.teacherNotes!,
                style: tt.bodyMedium?.copyWith(
                  color: cs.onSurface,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ],

          // ── Action buttons ───────────────────────────────────────────
          const SizedBox(height: Spacings.lg),
          Row(
            children: [
              if (onVerify != null && !entry.isVerified)
                AppButton(
                  label: 'Verify',
                  onPressed: onVerify,
                  variant: AppButtonVariant.elevated,
                  icon: Icons.verified_rounded,
                  size: AppButtonSize.small,
                ),
              if (onVerify != null && !entry.isVerified && onEdit != null)
                const SizedBox(width: Spacings.sm),
              if (onEdit != null)
                AppButton(
                  label: 'Edit',
                  onPressed: onEdit,
                  variant: AppButtonVariant.outlined,
                  icon: Icons.edit_rounded,
                  size: AppButtonSize.small,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Verification Badge ───────────────────────────────────────────────────────

class _VerificationBadge extends StatelessWidget {
  const _VerificationBadge({required this.isVerified});

  final bool isVerified;

  @override
  Widget build(BuildContext context) {
    final color = isVerified ? AppColors.success : AppColors.warning;
    final isDark = context.isDarkMode;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Spacings.sm,
        vertical: Spacings.xs,
      ),
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
          Icon(
            isVerified ? Icons.verified_rounded : Icons.pending_rounded,
            size: 14,
            color: color,
          ),
          const SizedBox(width: Spacings.xs),
          Text(
            isVerified ? 'Verified' : 'Unverified',
            style: AppTypography.labelSmall.copyWith(
              color: color,
              fontWeight: AppTypography.wSemiBold,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Correct Answers Section (Green Highlighted) ──────────────────────────────

class _CorrectAnswersSection extends StatelessWidget {
  const _CorrectAnswersSection({required this.answers});

  final List<Map<String, dynamic>> answers;

  @override
  Widget build(BuildContext context) {
    final tt = context.textTheme;
    final cs = context.colorScheme;
    final isDark = context.isDarkMode;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(Spacings.md),
      decoration: BoxDecoration(
        color: AppColors.success.withOpacity(isDark ? 0.15 : 0.08),
        borderRadius: Spacings.borderRadiusMd,
        border: Border.all(
          color: AppColors.success.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.check_circle_outline_rounded,
                size: 16,
                color: AppColors.success,
              ),
              const SizedBox(width: Spacings.xs),
              Text(
                answers.length == 1
                    ? 'Correct Answer'
                    : 'Correct Answers (${answers.length})',
                style: tt.labelMedium?.copyWith(
                  color: AppColors.success,
                  fontWeight: AppTypography.wSemiBold,
                ),
              ),
            ],
          ),
          const SizedBox(height: Spacings.sm),
          ...answers.map((answer) {
            final answerText = answer['text']?.toString() ??
                answer['answer']?.toString() ??
                answer['value']?.toString() ??
                answer.toString();
            return Padding(
              padding: const EdgeInsets.only(bottom: Spacings.xs),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (answers.length > 1) ...[
                    Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        color: AppColors.success.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '${answers.indexOf(answer) + 1}',
                          style: AppTypography.labelSmall.copyWith(
                            color: AppColors.success,
                            fontWeight: AppTypography.wBold,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: Spacings.sm),
                  ],
                  Expanded(
                    child: Text(
                      answerText,
                      style: tt.bodyLarge?.copyWith(
                        color: cs.onSurface,
                        fontWeight: AppTypography.wSemiBold,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

// ─── Expandable Section ───────────────────────────────────────────────────────

class _ExpandableSection extends StatefulWidget {
  const _ExpandableSection({
    required this.title,
    required this.icon,
    required this.color,
    required this.isDark,
    required this.child,
  });

  final String title;
  final IconData icon;
  final Color color;
  final bool isDark;
  final Widget child;

  @override
  State<_ExpandableSection> createState() => _ExpandableSectionState();
}

class _ExpandableSectionState extends State<_ExpandableSection> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final tt = context.textTheme;

    return Padding(
      padding: const EdgeInsets.only(top: Spacings.md),
      child: Container(
        decoration: BoxDecoration(
          color: widget.color.withOpacity(widget.isDark ? 0.08 : 0.04),
          borderRadius: Spacings.borderRadiusMd,
          border: Border.all(
            color: widget.color.withOpacity(0.15),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InkWell(
              onTap: () => setState(() => _isExpanded = !_isExpanded),
              borderRadius: Spacings.borderRadiusMd,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: Spacings.md,
                  vertical: Spacings.sm,
                ),
                child: Row(
                  children: [
                    Icon(widget.icon, size: 16, color: widget.color),
                    const SizedBox(width: Spacings.xs),
                    Text(
                      widget.title,
                      style: tt.labelMedium?.copyWith(
                        color: widget.color,
                        fontWeight: AppTypography.wSemiBold,
                      ),
                    ),
                    const Spacer(),
                    AnimatedRotation(
                      turns: _isExpanded ? 0.25 : 0,
                      duration: const Duration(milliseconds: 200),
                      child: Icon(
                        Icons.chevron_right_rounded,
                        size: 16,
                        color: widget.color,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (_isExpanded)
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  Spacings.md,
                  0,
                  Spacings.md,
                  Spacings.md,
                ),
                child: widget.child,
              ),
          ],
        ),
      ),
    );
  }
}

// ─── Warning Section (Common Mistakes) ────────────────────────────────────────

class _WarningSection extends StatelessWidget {
  const _WarningSection({
    required this.title,
    required this.icon,
    required this.mistakes,
  });

  final String title;
  final IconData icon;
  final List<Map<String, dynamic>> mistakes;

  @override
  Widget build(BuildContext context) {
    final tt = context.textTheme;
    final cs = context.colorScheme;
    final isDark = context.isDarkMode;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(Spacings.md),
      decoration: BoxDecoration(
        color: AppColors.warning.withOpacity(isDark ? 0.12 : 0.06),
        borderRadius: Spacings.borderRadiusMd,
        border: Border.all(
          color: AppColors.warning.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: AppColors.warning),
              const SizedBox(width: Spacings.xs),
              Text(
                title,
                style: tt.labelMedium?.copyWith(
                  color: AppColors.warning,
                  fontWeight: AppTypography.wSemiBold,
                ),
              ),
            ],
          ),
          const SizedBox(height: Spacings.sm),
          ...mistakes.map((m) {
            final mistakeText = m['text']?.toString() ??
                m['description']?.toString() ??
                m['mistake']?.toString() ??
                m.toString();
            return Padding(
              padding: const EdgeInsets.only(bottom: Spacings.sm),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.close_rounded,
                    size: 14,
                    color: AppColors.error,
                  ),
                  const SizedBox(width: Spacings.sm),
                  Expanded(
                    child: Text(
                      mistakeText,
                      style: tt.bodySmall?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

// ─── Alternative Answers Section ──────────────────────────────────────────────

class _AlternativeAnswersSection extends StatelessWidget {
  const _AlternativeAnswersSection({required this.answers});

  final List<Map<String, dynamic>> answers;

  @override
  Widget build(BuildContext context) {
    final tt = context.textTheme;
    final cs = context.colorScheme;
    final isDark = context.isDarkMode;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.alt_route_rounded,
              size: 16,
              color: cs.primary,
            ),
            const SizedBox(width: Spacings.xs),
            Text(
              'Alternative Answers',
              style: tt.labelMedium?.copyWith(
                color: cs.primary,
                fontWeight: AppTypography.wSemiBold,
              ),
            ),
          ],
        ),
        const SizedBox(height: Spacings.sm),
        Wrap(
          spacing: Spacings.sm,
          runSpacing: Spacings.xs,
          children: answers
              .map((a) {
                final text = a['text']?.toString() ??
                    a['answer']?.toString() ??
                    a['value']?.toString() ??
                    a.toString();
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: Spacings.md,
                    vertical: Spacings.sm,
                  ),
                  decoration: BoxDecoration(
                    color: cs.primary
                        .withOpacity(isDark ? 0.15 : 0.08),
                    borderRadius: Spacings.borderRadiusSm,
                    border: Border.all(
                      color: cs.primary.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    text,
                    style: tt.bodySmall?.copyWith(color: cs.onSurface),
                  ),
                );
              })
              .toList(),
        ),
      ],
    );
  }
}

// ─── Map Display (for marking scheme etc.) ────────────────────────────────────

class _MapDisplay extends StatelessWidget {
  const _MapDisplay({required this.data});

  final Map<String, dynamic> data;

  @override
  Widget build(BuildContext context) {
    final tt = context.textTheme;
    final cs = context.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: data.entries.map((e) {
        final value = e.value;
        // Recursively handle nested maps
        if (value is Map<String, dynamic>) {
          return Padding(
            padding: const EdgeInsets.only(bottom: Spacings.sm),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  e.key,
                  style: tt.labelMedium?.copyWith(
                    color: cs.primary,
                    fontWeight: AppTypography.wSemiBold,
                  ),
                ),
                const SizedBox(height: Spacings.xs),
                _MapDisplay(data: value),
              ],
            ),
          );
        }
        return Padding(
          padding: const EdgeInsets.only(bottom: Spacings.xs),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${e.key}: ',
                style: tt.bodySmall?.copyWith(
                  color: cs.onSurfaceVariant,
                  fontWeight: AppTypography.wSemiBold,
                ),
              ),
              Expanded(
                child: Text(
                  value.toString(),
                  style: tt.bodySmall?.copyWith(color: cs.onSurface),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
