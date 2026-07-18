import 'package:flutter/material.dart';

import '../../../../core/themes/app_colors.dart';
import '../../../../core/themes/app_typography.dart';
import '../../../../core/themes/spacings.dart';
import '../../../../core/extensions/context_extensions.dart';

// ═══════════════════════════════════════════════════════════════════════
// QUESTION DISPLAY CARD
// ═══════════════════════════════════════════════════════════════════════

/// Renders a question card for the practice mode.
///
/// Displays question text prominently with type and difficulty badges.
/// Supports multiple choice (options list), true/false, and fill-in-blank
/// question types.
///
/// The [question] map is expected to contain:
/// - `text` (String): The question text.
/// - `type` (String): 'multiple_choice', 'true_false', or 'fill_in_blank'.
/// - `difficulty` (String): 'easy', 'medium', 'hard', or 'expert'.
/// - `options` (List<String>?): Options for multiple choice.
/// - `correct_option` (int?): Index of the correct option.
/// - `selected_option` (int?): Currently selected option index.
/// - `blank_count` (int?): Number of blanks for fill-in-blank.
///
/// ```dart
/// QuestionDisplayCard(
///   question: {
///     'text': 'What is 2+2?',
///     'type': 'multiple_choice',
///     'difficulty': 'easy',
///     'options': ['3', '4', '5', '6'],
///   },
///   onOptionSelected: (i) => print(i),
/// )
/// ```
class QuestionDisplayCard extends StatelessWidget {
  const QuestionDisplayCard({
    super.key,
    required this.question,
    this.onOptionSelected,
    this.showCorrectAnswer = false,
    this.isEnabled = true,
  });

  /// The question data map from a practice session.
  final Map<String, dynamic> question;

  /// Callback when a multiple-choice option is selected.
  final ValueChanged<int>? onOptionSelected;

  /// Whether to reveal the correct answer (review mode).
  final bool showCorrectAnswer;

  /// Whether the card accepts interactions.
  final bool isEnabled;

  String get _text => question['text'] as String? ?? '';
  String get _type => question['type'] as String? ?? 'multiple_choice';
  String get _difficulty => question['difficulty'] as String? ?? 'medium';
  List<String> get _options =>
      (question['options'] as List<dynamic>?)?.cast<String>() ?? [];
  int? get _correctIndex => question['correct_option'] as int?;
  int? get _selectedIndex => question['selected_option'] as int?;

  // ─── Type Badge Data ───────────────────────────────────────────────

  (IconData, String, Color) _typeInfo() {
    return switch (_type) {
      'multiple_choice' => (Icons.radio_button_checked_rounded, 'Multiple Choice', const Color(0xFF2563EB)),
      'true_false' => (Icons.toggle_on_rounded, 'True / False', const Color(0xFF059669)),
      'fill_in_blank' => (Icons.edit_note_rounded, 'Fill in Blank', const Color(0xFFD97706)),
      _ => (Icons.help_outline_rounded, _type, const Color(0xFF6B7280)),
    };
  }

  // ─── Difficulty Badge Data ─────────────────────────────────────────

  Color _difficultyColor() {
    return switch (_difficulty) {
      'easy' => const Color(0xFF16A34A),
      'medium' => const Color(0xFFF59E0B),
      'hard' => const Color(0xFFDC2626),
      'expert' => const Color(0xFF7C3AED),
      _ => const Color(0xFF6B7280),
    };
  }

  String _difficultyLabel() {
    return switch (_difficulty) {
      'easy' => 'Easy',
      'medium' => 'Medium',
      'hard' => 'Hard',
      'expert' => 'Expert',
      _ => _difficulty,
    };
  }

  // ─── Build ─────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;
    final tt = context.textTheme;

    return Card(
      elevation: Spacings.elevationSm,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Spacings.mdRadius),
      ),
      child: Padding(
        padding: Spacings.paddingCard,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Badges Row ────────────────────────────────────────────
            _buildBadges(context),
            const SizedBox(height: Spacings.md),

            // ── Question Text ─────────────────────────────────────────
            SelectableText(
              _text,
              style: tt.bodyLarge?.copyWith(
                color: cs.onSurface,
                height: 1.7,
                fontWeight: AppTypography.wMedium,
              ),
            ),
            const SizedBox(height: Spacings.xl),

            // ── Answer Options ────────────────────────────────────────
            _buildAnswerSection(context),
          ],
        ),
      ),
    );
  }

  // ─── Badges ────────────────────────────────────────────────────────

  Widget _buildBadges(BuildContext context) {
    final (icon, label, typeColor) = _typeInfo();
    final diffColor = _difficultyColor();
    final isDark = context.isDarkMode;

    return Wrap(
      spacing: Spacings.sm,
      runSpacing: Spacings.sm,
      children: [
        // Type badge
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: Spacings.sm,
            vertical: Spacings.xs,
          ),
          decoration: BoxDecoration(
            color: typeColor.withValues(alpha: isDark ? 0.25 : 0.12),
            borderRadius: BorderRadius.circular(Spacings.smRadius),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: isDark ? typeColor.withValues(alpha: 0.9) : typeColor),
              const SizedBox(width: Spacings.xs),
              Text(
                label,
                style: TextStyle(
                  fontFamily: AppTypography.fontFamily,
                  fontSize: 11,
                  fontWeight: AppTypography.wSemiBold,
                  letterSpacing: AppTypography.lsLabel,
                  color: isDark ? typeColor.withValues(alpha: 0.9) : typeColor,
                ),
              ),
            ],
          ),
        ),

        // Difficulty badge
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: Spacings.sm,
            vertical: Spacings.xs,
          ),
          decoration: BoxDecoration(
            color: diffColor.withValues(alpha: isDark ? 0.25 : 0.12),
            borderRadius: BorderRadius.circular(Spacings.smRadius),
          ),
          child: Text(
            _difficultyLabel(),
            style: TextStyle(
              fontFamily: AppTypography.fontFamily,
              fontSize: 11,
              fontWeight: AppTypography.wSemiBold,
              letterSpacing: AppTypography.lsLabel,
              color: isDark ? diffColor.withValues(alpha: 0.9) : diffColor,
            ),
          ),
        ),
      ],
    );
  }

  // ─── Answer Section ────────────────────────────────────────────────

  Widget _buildAnswerSection(BuildContext context) {
    return switch (_type) {
      'multiple_choice' => _buildMultipleChoice(context),
      'true_false' => _buildTrueFalse(context),
      'fill_in_blank' => _buildFillInBlank(context),
      _ => const SizedBox.shrink(),
    };
  }

  Widget _buildMultipleChoice(BuildContext context) {
    final cs = context.colorScheme;
    final tt = context.textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: List.generate(_options.length, (i) {
        final isSelected = _selectedIndex == i;
        final isCorrect = showCorrectAnswer && _correctIndex == i;
        final isWrong = showCorrectAnswer && isSelected && _correctIndex != i;

        Color? bgColor;
        Color? borderColor;
        Color? textColor;

        if (isCorrect) {
          bgColor = AppColors.successLight.withValues(alpha: context.isDarkMode ? 0.25 : 1.0);
          borderColor = AppColors.success;
          textColor = AppColors.success;
        } else if (isWrong) {
          bgColor = AppColors.errorLight.withValues(alpha: context.isDarkMode ? 0.25 : 1.0);
          borderColor = AppColors.error;
          textColor = AppColors.error;
        } else if (isSelected) {
          bgColor = cs.primary.withValues(alpha: context.isDarkMode ? 0.20 : 0.10);
          borderColor = cs.primary;
          textColor = cs.primary;
        } else {
          bgColor = cs.surfaceContainerLow;
          borderColor = cs.outlineVariant;
          textColor = cs.onSurface;
        }

        return Padding(
          padding: const EdgeInsets.only(bottom: Spacings.sm),
          child: InkWell(
            onTap: isEnabled ? () => onOptionSelected?.call(i) : null,
            borderRadius: BorderRadius.circular(Spacings.smRadius),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(Spacings.md),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(Spacings.smRadius),
                border: Border.all(color: borderColor, width: isSelected || isCorrect || isWrong ? 2.0 : 1.0),
              ),
              child: Row(
                children: [
                  // Radio/checkbox indicator
                  if (_type == 'multiple_choice')
                    Icon(
                      isSelected
                          ? Icons.radio_button_checked_rounded
                          : Icons.radio_button_unchecked_rounded,
                      size: Spacings.mdIcon,
                      color: textColor,
                    )
                  else
                    Icon(
                      isSelected
                          ? Icons.check_box_rounded
                          : Icons.check_box_outline_blank_rounded,
                      size: Spacings.mdIcon,
                      color: textColor,
                    ),
                  const SizedBox(width: Spacings.md),
                  Expanded(
                    child: Text(
                      _options[i],
                      style: tt.bodyMedium?.copyWith(
                        color: textColor,
                        fontWeight: isSelected ? AppTypography.wSemiBold : AppTypography.wRegular,
                      ),
                    ),
                  ),
                  if (isCorrect)
                    Icon(Icons.check_circle_rounded, size: Spacings.mdIcon, color: AppColors.success),
                  if (isWrong)
                    Icon(Icons.cancel_rounded, size: Spacings.mdIcon, color: AppColors.error),
                ],
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildTrueFalse(BuildContext context) {
    final cs = context.colorScheme;
    final tt = context.textTheme;
    final selected = _selectedIndex;

    return Row(
      children: [
        Expanded(
          child: _buildTfOption(
            context: context,
            label: 'True',
            index: 0,
            isSelected: selected == 0,
            isCorrect: showCorrectAnswer && _correctIndex == 0,
            tt: tt,
            cs: cs,
          ),
        ),
        const SizedBox(width: Spacings.md),
        Expanded(
          child: _buildTfOption(
            context: context,
            label: 'False',
            index: 1,
            isSelected: selected == 1,
            isCorrect: showCorrectAnswer && _correctIndex == 1,
            tt: tt,
            cs: cs,
          ),
        ),
      ],
    );
  }

  Widget _buildTfOption({
    required BuildContext context,
    required String label,
    required int index,
    required bool isSelected,
    required bool isCorrect,
    required TextTheme tt,
    required ColorScheme cs,
  }) {
    final isWrong = showCorrectAnswer && isSelected && !isCorrect;
    Color bgColor = cs.surfaceContainerLow;
    Color borderColor = cs.outlineVariant;
    Color textColor = cs.onSurface;

    if (isCorrect) {
      bgColor = AppColors.successLight.withValues(alpha: context.isDarkMode ? 0.25 : 1.0);
      borderColor = AppColors.success;
      textColor = AppColors.success;
    } else if (isWrong) {
      bgColor = AppColors.errorLight.withValues(alpha: context.isDarkMode ? 0.25 : 1.0);
      borderColor = AppColors.error;
      textColor = AppColors.error;
    } else if (isSelected) {
      bgColor = cs.primary.withValues(alpha: context.isDarkMode ? 0.20 : 0.10);
      borderColor = cs.primary;
      textColor = cs.primary;
    }

    return InkWell(
      onTap: isEnabled ? () => onOptionSelected?.call(index) : null,
      borderRadius: BorderRadius.circular(Spacings.smRadius),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: Spacings.lg,
          vertical: Spacings.md,
        ),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(Spacings.smRadius),
          border: Border.all(color: borderColor, width: isSelected || isCorrect || isWrong ? 2.0 : 1.0),
        ),
        child: Center(
          child: Text(
            label,
            style: tt.titleMedium?.copyWith(
              fontWeight: AppTypography.wSemiBold,
              color: textColor,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFillInBlank(BuildContext context) {
    final cs = context.colorScheme;
    final tt = context.textTheme;
    final blankCount = question['blank_count'] as int? ?? 1;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: List.generate(blankCount, (i) {
        return Padding(
          padding: const EdgeInsets.only(bottom: Spacings.md),
          child: TextField(
            enabled: isEnabled,
            decoration: InputDecoration(
              labelText: 'Blank ${i + 1}',
              labelStyle: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
              filled: true,
              fillColor: cs.surfaceContainerLow,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(Spacings.smRadius),
                borderSide: BorderSide(color: cs.outlineVariant),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(Spacings.smRadius),
                borderSide: BorderSide(color: cs.outlineVariant),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(Spacings.smRadius),
                borderSide: BorderSide(color: cs.primary, width: 2),
              ),
              contentPadding: Spacings.paddingInput,
            ),
          ),
        );
      }),
    );
  }
}
