import 'package:flutter/material.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/themes/app_colors.dart';
import '../../../../core/themes/app_typography.dart';
import '../../../../core/themes/spacings.dart';
import '../../../question_bank/domain/entities/question_entities.dart';
import '../../../question_bank/presentation/widgets/difficulty_badge.dart';
import '../../../question_bank/presentation/widgets/question_type_badge.dart';
import '../../domain/entities/cbt_entities.dart';
import 'answer_input_widget.dart';

// ═══════════════════════════════════════════════════════════════════════
// QUESTION DISPLAY WIDGET
// ═══════════════════════════════════════════════════════════════════════

/// Displays a single question during exam-taking with question content,
/// answer input, flag/clear controls, and navigation buttons.
class QuestionDisplayWidget extends StatelessWidget {
  const QuestionDisplayWidget({
    super.key,
    required this.examQuestion,
    required this.questionIndex,
    required this.totalQuestions,
    required this.currentAnswer,
    this.isFlagged = false,
    this.isEnabled = true,
    this.onAnswerChanged,
    this.onFlagToggle,
    this.onClearAnswer,
    this.onPrevious,
    this.onNext,
    this.isFirst = false,
    this.isLast = false,
  });

  /// The exam question entity (with the full question loaded).
  final ExamQuestionEntity examQuestion;

  /// 0-based index of the current question.
  final int questionIndex;

  /// Total number of questions.
  final int totalQuestions;

  /// Current answer data.
  final Map<String, dynamic>? currentAnswer;

  /// Whether this question is flagged for review.
  final bool isFlagged;

  /// Whether the input is enabled (for review mode).
  final bool isEnabled;

  /// Callback when answer changes.
  final ValueChanged<Map<String, dynamic>>? onAnswerChanged;

  /// Callback when flag is toggled.
  final ValueChanged<bool>? onFlagToggle;

  /// Callback when answer is cleared.
  final VoidCallback? onClearAnswer;

  /// Navigate to previous question.
  final VoidCallback? onPrevious;

  /// Navigate to next question.
  final VoidCallback? onNext;

  /// Whether this is the first question.
  final bool isFirst;

  /// Whether this is the last question.
  final bool isLast;

  QuestionEntity? get _question => examQuestion.question;

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;
    final tt = context.textTheme;
    final question = _question;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(Spacings.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Question Header ──────────────────────────────────────────
          _buildQuestionHeader(context, cs, tt),

          const SizedBox(height: Spacings.lg),

          // ── Question Content ─────────────────────────────────────────
          if (question != null) ...[
            _buildQuestionContent(context, cs, tt, question),

            const SizedBox(height: Spacings.xl),

            // ── Attachments (images, audio, video) ───────────────────
            if (question.attachments.isNotEmpty)
              _buildAttachments(context, cs, tt, question.attachments.map((a) => a.url).toList()),

            if (question.attachments.isNotEmpty)
              const SizedBox(height: Spacings.xl),

            // ── Answer Input ──────────────────────────────────────────
            _buildAnswerInput(context, question),

            const SizedBox(height: Spacings.xl),
          ],

          // ── Controls: Flag / Clear ──────────────────────────────────
          _buildControlButtons(context, cs, tt),

          const SizedBox(height: Spacings.xl),

          // ── Navigation: Previous / Next ────────────────────────────
          _buildNavigationButtons(context, cs, tt),
        ],
      ),
    );
  }

  Widget _buildQuestionHeader(
    BuildContext context,
    ColorScheme cs,
    TextTheme tt,
  ) {
    final question = _question;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Question number badge
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: cs.primary.withValues(alpha: context.isDarkMode ? 0.20 : 0.10),
            borderRadius: BorderRadius.circular(Spacings.smRadius),
          ),
          child: Center(
            child: Text(
              '${questionIndex + 1}',
              style: tt.titleMedium?.copyWith(
                fontWeight: AppTypography.wBold,
                color: cs.primary,
              ),
            ),
          ),
        ),
        const SizedBox(width: Spacings.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    'Question ${questionIndex + 1} of $totalQuestions',
                    style: tt.titleSmall?.copyWith(
                      fontWeight: AppTypography.wSemiBold,
                      color: cs.onSurface,
                    ),
                  ),
                  const Spacer(),
                  // Marks badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: Spacings.sm,
                      vertical: Spacings.xs,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.infoOf(cs.brightness)
                          .withValues(alpha: context.isDarkMode ? 0.20 : 0.10),
                      borderRadius: BorderRadius.circular(Spacings.smRadius),
                    ),
                    child: Text(
                      '${examQuestion.marks.toInt()} mark${examQuestion.marks != 1 ? 's' : ''}',
                      style: tt.labelSmall?.copyWith(
                        fontWeight: AppTypography.wSemiBold,
                        color: AppColors.infoOf(cs.brightness),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: Spacings.xs),
              Row(
                children: [
                  if (question != null)
                    QuestionTypeBadge(
                      type: question.questionType,
                      variant: QuestionTypeBadgeVariant.labelOnly,
                    ),
                  const SizedBox(width: Spacings.sm),
                  if (question != null)
                    DifficultyBadge(difficulty: question.difficulty),
                  if (isFlagged) ...[
                    const SizedBox(width: Spacings.sm),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: Spacings.sm,
                        vertical: Spacings.xs,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.warningOf(cs.brightness)
                            .withValues(alpha: context.isDarkMode ? 0.25 : 0.12),
                        borderRadius: BorderRadius.circular(Spacings.smRadius),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.flag_rounded,
                            size: 12,
                            color: AppColors.warningOf(cs.brightness),
                          ),
                          const SizedBox(width: Spacings.xs),
                          Text(
                            'Flagged',
                            style: tt.labelSmall?.copyWith(
                              fontWeight: AppTypography.wSemiBold,
                              color: AppColors.warningOf(cs.brightness),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildQuestionContent(
    BuildContext context,
    ColorScheme cs,
    TextTheme tt,
    QuestionEntity question,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(Spacings.lg),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(Spacings.mdRadius),
        border: Border.all(
          color: cs.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: SelectableText(
        question.content,
        style: tt.bodyLarge?.copyWith(
          color: cs.onSurface,
          height: 1.7,
        ),
      ),
    );
  }

  Widget _buildAttachments(
    BuildContext context,
    ColorScheme cs,
    TextTheme tt,
    List<String> attachments,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Attachments',
          style: tt.labelLarge?.copyWith(
            fontWeight: AppTypography.wSemiBold,
            color: cs.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: Spacings.sm),
        Wrap(
          spacing: Spacings.sm,
          runSpacing: Spacings.sm,
          children: attachments.map((url) {
            final isImage = url.endsWith('.png') ||
                url.endsWith('.jpg') ||
                url.endsWith('.jpeg') ||
                url.endsWith('.gif');
            final isAudio = url.endsWith('.mp3') || url.endsWith('.wav');
            final isVideo = url.endsWith('.mp4') || url.endsWith('.mov');

            return Container(
              padding: const EdgeInsets.symmetric(
                horizontal: Spacings.md,
                vertical: Spacings.sm,
              ),
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(Spacings.smRadius),
                border: Border.all(
                  color: cs.outlineVariant.withValues(alpha: 0.5),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isImage
                        ? Icons.image_rounded
                        : isAudio
                            ? Icons.audiotrack_rounded
                            : isVideo
                                ? Icons.videocam_rounded
                                : Icons.attach_file_rounded,
                    size: Spacings.smIcon,
                    color: cs.onSurfaceVariant,
                  ),
                  const SizedBox(width: Spacings.xs),
                  Text(
                    isImage
                        ? 'Image'
                        : isAudio
                            ? 'Audio'
                            : isVideo
                                ? 'Video'
                                : 'File',
                    style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildAnswerInput(BuildContext context, QuestionEntity question) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Your Answer',
          style: context.textTheme.labelLarge?.copyWith(
            fontWeight: AppTypography.wSemiBold,
            color: context.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: Spacings.md),
        AnswerInputWidget(
          questionType: question.questionType,
          options: question.answerOptions,
          currentAnswer: currentAnswer,
          onAnswerChanged: onAnswerChanged,
          isEnabled: isEnabled,
          maxCharacters: question.questionType == QuestionType.essay ? 5000 : null,
          blanks: question.questionType == QuestionType.fillInBlank
              ? List.generate(
                  (question.metadata?['blank_count'] as int?) ?? 1,
                  (i) => 'Blank ${i + 1}',
                )
              : const [],
          matchingPairs: question.questionType == QuestionType.matching
              ? (question.metadata?['matching_pairs'] as List<Map<String, String>>?)
                      ?.cast<Map<String, String>>() ??
                  []
              : const [],
          orderItems: question.questionType == QuestionType.ordering
              ? question.answerOptions.map((o) => o.content).toList()
              : const [],
        ),
      ],
    );
  }

  Widget _buildControlButtons(
    BuildContext context,
    ColorScheme cs,
    TextTheme tt,
  ) {
    return Row(
      children: [
        // Flag for review toggle
        TextButton.icon(
          onPressed: isEnabled ? () => onFlagToggle?.call(!isFlagged) : null,
          icon: Icon(
            isFlagged ? Icons.flag_rounded : Icons.flag_outlined,
            size: Spacings.mdIcon,
            color: isFlagged
                ? AppColors.warningOf(cs.brightness)
                : cs.onSurfaceVariant,
          ),
          label: Text(
            isFlagged ? 'Unflag' : 'Flag for Review',
            style: tt.bodyMedium?.copyWith(
              color: isFlagged
                  ? AppColors.warningOf(cs.brightness)
                  : cs.onSurfaceVariant,
              fontWeight: AppTypography.wSemiBold,
            ),
          ),
        ),
        const Spacer(),
        // Clear answer
        TextButton.icon(
          onPressed: isEnabled && currentAnswer != null && currentAnswer!.isNotEmpty
              ? onClearAnswer
              : null,
          icon: Icon(
            Icons.clear_rounded,
            size: Spacings.mdIcon,
            color: cs.onSurfaceVariant,
          ),
          label: Text(
            'Clear Answer',
            style: tt.bodyMedium?.copyWith(
              color: cs.onSurfaceVariant,
              fontWeight: AppTypography.wSemiBold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNavigationButtons(
    BuildContext context,
    ColorScheme cs,
    TextTheme tt,
  ) {
    return Row(
      children: [
        // Previous
        Expanded(
          child: OutlinedButton.icon(
            onPressed: isFirst ? null : onPrevious,
            icon: const Icon(Icons.arrow_back_rounded),
            label: const Text('Previous'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: Spacings.md),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(Spacings.mdRadius),
              ),
            ),
          ),
        ),
        const SizedBox(width: Spacings.md),
        // Next
        Expanded(
          child: FilledButton.icon(
            onPressed: isLast ? null : onNext,
            icon: const Icon(Icons.arrow_forward_rounded),
            label: const Text('Next'),
            style: FilledButton.styleFrom(
              backgroundColor: cs.primary,
              foregroundColor: cs.onPrimary,
              padding: const EdgeInsets.symmetric(vertical: Spacings.md),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(Spacings.mdRadius),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
