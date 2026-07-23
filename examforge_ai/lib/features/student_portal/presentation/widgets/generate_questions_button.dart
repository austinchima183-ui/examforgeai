import 'package:flutter/material.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/themes/app_colors.dart';
import '../../../../core/themes/app_typography.dart';
import '../../../../core/themes/spacings.dart';

// ═══════════════════════════════════════════════════════════════════════
// GENERATE QUESTIONS BUTTON (Student Portal)
// ═══════════════════════════════════════════════════════════════════════

/// Integration button that sends content to the AI Question Generation
/// Engine from the student portal context.
///
/// Styled as a [FilledButton.tonal] with an auto_awesome icon.
/// While generating, it shows a loading indicator. After successful
/// generation, it transitions to a success state with a "View Questions"
/// option.
///
/// ```dart
/// GenerateQuestionsButton(
///   content: 'Chapter 5: Photosynthesis...',
///   subjectId: 'bio-101',
///   topicId: 'photosynthesis',
///   onGenerate: () => triggerGeneration(),
///   onViewQuestions: () => navigateToQuestions(),
/// )
/// ```
class GenerateQuestionsButton extends StatefulWidget {
  const GenerateQuestionsButton({
    super.key,
    required this.content,
    this.subjectId,
    this.topicId,
    this.onGenerate,
    this.onViewQuestions,
    this.isGenerating = false,
    this.isGenerated = false,
  });

  /// The content text to send for question generation.
  final String content;

  /// Optional subject ID for context-aware generation.
  final String? subjectId;

  /// Optional topic ID for context-aware generation.
  final String? topicId;

  /// Callback when the user taps "Generate Questions".
  final VoidCallback? onGenerate;

  /// Callback when the user taps "View Questions" after generation.
  final VoidCallback? onViewQuestions;

  /// Whether generation is currently in progress.
  final bool isGenerating;

  /// Whether questions have been successfully generated.
  final bool isGenerated;

  @override
  State<GenerateQuestionsButton> createState() => _GenerateQuestionsButtonState();
}

class _GenerateQuestionsButtonState extends State<GenerateQuestionsButton> {
  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;
    final tt = context.textTheme;

    // ── Success State ──────────────────────────────────────────────
    if (widget.isGenerated && !widget.isGenerating) {
      return _buildSuccessState(context, cs, tt);
    }

    // ── Generating State ───────────────────────────────────────────
    if (widget.isGenerating) {
      return _buildGeneratingState(context, cs, tt);
    }

    // ── Default State ──────────────────────────────────────────────
    return _buildDefaultState(context, cs, tt);
  }

  Widget _buildDefaultState(BuildContext context, ColorScheme cs, TextTheme tt) {
    return FilledButton.tonalIcon(
      onPressed: widget.onGenerate,
      icon: const Icon(Icons.auto_awesome_rounded, size: 20),
      label: const Text('Generate Questions'),
      style: FilledButton.styleFrom(
        padding: const EdgeInsets.symmetric(
          horizontal: Spacings.xl,
          vertical: Spacings.md,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Spacings.mdRadius),
        ),
        textStyle: tt.labelLarge?.copyWith(
          fontWeight: AppTypography.wSemiBold,
        ),
      ),
    );
  }

  Widget _buildGeneratingState(BuildContext context, ColorScheme cs, TextTheme tt) {
    return FilledButton.tonalIcon(
      onPressed: null,
      icon: SizedBox(
        width: 18,
        height: 18,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: cs.onSecondaryContainer,
        ),
      ),
      label: const Text('Generating...'),
      style: FilledButton.styleFrom(
        padding: const EdgeInsets.symmetric(
          horizontal: Spacings.xl,
          vertical: Spacings.md,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Spacings.mdRadius),
        ),
        textStyle: tt.labelLarge?.copyWith(
          fontWeight: AppTypography.wSemiBold,
        ),
      ),
    );
  }

  Widget _buildSuccessState(BuildContext context, ColorScheme cs, TextTheme tt) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Success indicator
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: Spacings.md,
            vertical: Spacings.sm,
          ),
          decoration: BoxDecoration(
            color: AppColors.success.withValues(alpha: context.isDarkMode ? 0.25 : 0.12),
            borderRadius: BorderRadius.circular(Spacings.mdRadius),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.check_circle_rounded,
                size: Spacings.mdIcon,
                color: AppColors.successOf(cs.brightness),
              ),
              const SizedBox(width: Spacings.sm),
              Text(
                'Questions Generated',
                style: tt.labelLarge?.copyWith(
                  fontWeight: AppTypography.wSemiBold,
                  color: AppColors.successOf(cs.brightness),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: Spacings.sm),
        // View Questions button
        FilledButton.tonalIcon(
          onPressed: widget.onViewQuestions,
          icon: const Icon(Icons.visibility_rounded, size: 18),
          label: const Text('View Questions'),
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(
              horizontal: Spacings.lg,
              vertical: Spacings.md,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(Spacings.mdRadius),
            ),
            textStyle: tt.labelLarge?.copyWith(
              fontWeight: AppTypography.wSemiBold,
            ),
          ),
        ),
      ],
    );
  }
}
