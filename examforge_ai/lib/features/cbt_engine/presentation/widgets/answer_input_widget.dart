import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/themes/app_colors.dart';
import '../../../../core/themes/app_typography.dart';
import '../../../../core/themes/spacings.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../question_bank/domain/entities/question_entities.dart';

// ═══════════════════════════════════════════════════════════════════════
// ANSWER INPUT WIDGET
// ═══════════════════════════════════════════════════════════════════════

/// Dynamic answer input that renders differently based on [QuestionType].
///
/// Supports:
/// - MCQ: Radio button list
/// - Multiple Select: Checkbox list
/// - True/False: Two option buttons
/// - Fill in Blank: Text fields for each blank
/// - Matching: Two-column dropdown pairs
/// - Ordering: Reorderable list
/// - Short Answer: Multi-line text field
/// - Essay: Large text area with character count
/// - Numerical: Number input field
class AnswerInputWidget extends StatelessWidget {
  const AnswerInputWidget({
    super.key,
    required this.questionType,
    this.options = const [],
    this.currentAnswer,
    this.onAnswerChanged,
    this.isEnabled = true,
    this.maxCharacters,
    this.blanks = const [],
    this.matchingPairs = const [],
    this.orderItems = const [],
  });

  /// The type of question, determines which input to render.
  final QuestionType questionType;

  /// Answer options (for MCQ, Multiple Select, True/False).
  final List<AnswerOptionEntity> options;

  /// Current answer data.
  final Map<String, dynamic>? currentAnswer;

  /// Callback when answer changes.
  final ValueChanged<Map<String, dynamic>>? onAnswerChanged;

  /// Whether the input is enabled (for review mode).
  final bool isEnabled;

  /// Maximum characters for essay answers.
  final int? maxCharacters;

  /// Number of blanks for fill-in-blank questions.
  final List<String> blanks;

  /// Matching pairs: list of {left: ..., right: ...}.
  final List<Map<String, String>> matchingPairs;

  /// Items to order.
  final List<String> orderItems;

  @override
  Widget build(BuildContext context) {
    return switch (questionType) {
      QuestionType.multipleChoice => _buildMCQ(context),
      QuestionType.multipleResponse => _buildMultipleSelect(context),
      QuestionType.trueFalse => _buildTrueFalse(context),
      QuestionType.fillInBlank => _buildFillInBlank(context),
      QuestionType.matching => _buildMatching(context),
      QuestionType.ordering => _buildOrdering(context),
      QuestionType.shortAnswer => _buildShortAnswer(context),
      QuestionType.essay => _buildEssay(context),
      QuestionType.numerical => _buildNumerical(context),
      _ => _buildShortAnswer(context),
    };
  }

  // ─── MCQ ─────────────────────────────────────────────────────────────

  Widget _buildMCQ(BuildContext context) {
    final cs = context.colorScheme;
    final tt = context.textTheme;
    final selectedOptionId = currentAnswer?['selected_option_id'] as String?;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: options.map((option) {
        final isSelected = selectedOptionId == option.id;
        final optionLabel = String.fromCharCode(65 + options.indexOf(option));

        return Padding(
          padding: const EdgeInsets.only(bottom: Spacings.sm),
          child: Material(
            color: isSelected
                ? cs.primary.withOpacity(context.isDarkMode ? 0.20 : 0.08)
                : cs.surfaceContainerHighest.withOpacity(0.5),
            borderRadius: BorderRadius.circular(Spacings.mdRadius),
            child: InkWell(
              onTap: isEnabled
                  ? () => onAnswerChanged
                      ?.call({'selected_option_id': option.id})
                  : null,
              borderRadius: BorderRadius.circular(Spacings.mdRadius),
              child: Padding(
                padding: const EdgeInsets.all(Spacings.md),
                child: Row(
                  children: [
                    Radio<String>(
                      value: option.id,
                      groupValue: selectedOptionId,
                      onChanged: isEnabled
                          ? (v) => onAnswerChanged
                              ?.call({'selected_option_id': v})
                          : null,
                      activeColor: cs.primary,
                    ),
                    const SizedBox(width: Spacings.sm),
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? cs.primary
                            : cs.surfaceContainerHigh,
                        borderRadius: BorderRadius.circular(Spacings.smRadius),
                      ),
                      child: Center(
                        child: Text(
                          optionLabel,
                          style: tt.labelMedium?.copyWith(
                            fontWeight: AppTypography.wBold,
                            color: isSelected ? cs.onPrimary : cs.onSurface,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: Spacings.md),
                    Expanded(
                      child: Text(
                        option.content,
                        style: tt.bodyLarge?.copyWith(
                          color: cs.onSurface,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  // ─── Multiple Select ─────────────────────────────────────────────────

  Widget _buildMultipleSelect(BuildContext context) {
    final cs = context.colorScheme;
    final tt = context.textTheme;
    final selectedIds = (currentAnswer?['selected_option_ids'] as List<dynamic>?)
            ?.cast<String>() ??
        <String>[];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: options.map((option) {
        final isSelected = selectedIds.contains(option.id);
        final optionLabel = String.fromCharCode(65 + options.indexOf(option));

        return Padding(
          padding: const EdgeInsets.only(bottom: Spacings.sm),
          child: Material(
            color: isSelected
                ? cs.primary.withOpacity(context.isDarkMode ? 0.20 : 0.08)
                : cs.surfaceContainerHighest.withOpacity(0.5),
            borderRadius: BorderRadius.circular(Spacings.mdRadius),
            child: InkWell(
              onTap: isEnabled ? () => _toggleOption(option.id, selectedIds) : null,
              borderRadius: BorderRadius.circular(Spacings.mdRadius),
              child: Padding(
                padding: const EdgeInsets.all(Spacings.md),
                child: Row(
                  children: [
                    Checkbox(
                      value: isSelected,
                      onChanged: isEnabled
                          ? (v) => _toggleOption(option.id, selectedIds)
                          : null,
                      activeColor: cs.primary,
                    ),
                    const SizedBox(width: Spacings.sm),
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? cs.primary
                            : cs.surfaceContainerHigh,
                        borderRadius: BorderRadius.circular(Spacings.smRadius),
                      ),
                      child: Center(
                        child: Text(
                          optionLabel,
                          style: tt.labelMedium?.copyWith(
                            fontWeight: AppTypography.wBold,
                            color: isSelected ? cs.onPrimary : cs.onSurface,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: Spacings.md),
                    Expanded(
                      child: Text(
                        option.content,
                        style: tt.bodyLarge?.copyWith(color: cs.onSurface),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  void _toggleOption(String optionId, List<String> current) {
    if (!isEnabled) return;
    final updated = List<String>.from(current);
    if (updated.contains(optionId)) {
      updated.remove(optionId);
    } else {
      updated.add(optionId);
    }
    onAnswerChanged?.call({'selected_option_ids': updated});
  }

  // ─── True / False ────────────────────────────────────────────────────

  Widget _buildTrueFalse(BuildContext context) {
    final cs = context.colorScheme;
    final tt = context.textTheme;
    final selected = currentAnswer?['selected_option_id'] as String?;

    return Row(
      children: [
        Expanded(
          child: _buildOptionButton(
            context: context,
            label: 'True',
            icon: Icons.check_circle_outline_rounded,
            isSelected: selected == 'true',
            color: AppColors.successOf(cs.brightness),
            onTap: isEnabled
                ? () => onAnswerChanged?.call({'selected_option_id': 'true'})
                : null,
          ),
        ),
        const SizedBox(width: Spacings.md),
        Expanded(
          child: _buildOptionButton(
            context: context,
            label: 'False',
            icon: Icons.cancel_outlined,
            isSelected: selected == 'false',
            color: AppColors.errorOf(cs.brightness),
            onTap: isEnabled
                ? () => onAnswerChanged?.call({'selected_option_id': 'false'})
                : null,
          ),
        ),
      ],
    );
  }

  Widget _buildOptionButton({
    required BuildContext context,
    required String label,
    required IconData icon,
    required bool isSelected,
    required Color color,
    required VoidCallback? onTap,
  }) {
    final cs = context.colorScheme;
    final tt = context.textTheme;
    final isDark = context.isDarkMode;

    return Material(
      color: isSelected
          ? color.withOpacity(isDark ? 0.25 : 0.12)
          : cs.surfaceContainerHighest.withOpacity(0.5),
      borderRadius: BorderRadius.circular(Spacings.mdRadius),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(Spacings.mdRadius),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: Spacings.lg,
            vertical: Spacings.md,
          ),
          decoration: isSelected
              ? BoxDecoration(
                  borderRadius: BorderRadius.circular(Spacings.mdRadius),
                  border: Border.all(color: color, width: 2.0),
                )
              : null,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: Spacings.mdIcon, color: isSelected ? color : cs.onSurfaceVariant),
              const SizedBox(width: Spacings.sm),
              Text(
                label,
                style: tt.titleSmall?.copyWith(
                  fontWeight: isSelected
                      ? AppTypography.wBold
                      : AppTypography.wSemiBold,
                  color: isSelected ? color : cs.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Fill in Blank ───────────────────────────────────────────────────

  Widget _buildFillInBlank(BuildContext context) {
    final cs = context.colorScheme;
    final existingBlanks =
        (currentAnswer?['blanks'] as List<dynamic>?)?.cast<Map<String, dynamic>>() ??
            <Map<String, dynamic>>[];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: List.generate(blanks.length, (index) {
        final existingAnswer = existingBlanks.where((b) => b['index'] == index).firstOrNull;
        final controller = TextEditingController(
          text: existingAnswer?['answer'] as String? ?? '',
        );

        return Padding(
          padding: const EdgeInsets.only(bottom: Spacings.md),
          child: TextField(
            controller: controller,
            enabled: isEnabled,
            decoration: InputDecoration(
              labelText: 'Blank ${index + 1}',
              hintText: 'Enter your answer for blank ${index + 1}',
              prefixIcon: Text(
                '  ${index + 1}.',
                style: TextStyle(
                  fontWeight: AppTypography.wBold,
                  color: cs.onSurfaceVariant,
                ),
              ),
              prefixIconConstraints: const BoxConstraints(minWidth: 40),
            ),
            onChanged: (value) {
              final updated = List<Map<String, dynamic>>.from(
                existingBlanks.where((b) => b['index'] != index),
              );
              updated.add({'index': index, 'answer': value});
              onAnswerChanged?.call({'blanks': updated});
            },
          ),
        );
      }),
    );
  }

  // ─── Matching ────────────────────────────────────────────────────────

  Widget _buildMatching(BuildContext context) {
    final cs = context.colorScheme;
    final tt = context.textTheme;
    final existingPairs =
        (currentAnswer?['pairs'] as List<dynamic>?)?.cast<Map<String, dynamic>>() ??
            <Map<String, dynamic>>[];

    final leftItems = matchingPairs.map((p) => p['left']!).toList();
    final rightItems = matchingPairs.map((p) => p['right']!).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: List.generate(leftItems.length, (index) {
        final currentRightId = existingPairs
            .where((p) => p['left_id'] == 'l$index')
            .firstOrNull?['right_id'] as String?;

        return Padding(
          padding: const EdgeInsets.only(bottom: Spacings.md),
          child: Row(
            children: [
              // Left item
              Expanded(
                flex: 2,
                child: Container(
                  padding: const EdgeInsets.all(Spacings.md),
                  decoration: BoxDecoration(
                    color: cs.primary.withOpacity(context.isDarkMode ? 0.15 : 0.08),
                    borderRadius: BorderRadius.circular(Spacings.smRadius),
                  ),
                  child: Text(
                    leftItems[index],
                    style: tt.bodyMedium?.copyWith(
                      fontWeight: AppTypography.wSemiBold,
                      color: cs.onSurface,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: Spacings.sm),
              // Arrow icon
              Icon(Icons.arrow_forward_rounded, color: cs.onSurfaceVariant),
              const SizedBox(width: Spacings.sm),
              // Right dropdown
              Expanded(
                flex: 2,
                child: DropdownButtonFormField<String>(
                  value: currentRightId,
                  hint: Text('Select match', style: tt.bodyMedium),
                  items: rightItems.asMap().entries.map((entry) {
                    return DropdownMenuItem<String>(
                      value: 'r${entry.key}',
                      child: Text(
                        entry.value,
                        style: tt.bodyMedium?.copyWith(color: cs.onSurface),
                      ),
                    );
                  }).toList(),
                  onChanged: isEnabled
                      ? (value) {
                          final updated = List<Map<String, dynamic>>.from(
                            existingPairs.where((p) => p['left_id'] != 'l$index'),
                          );
                          if (value != null) {
                            updated.add({'left_id': 'l$index', 'right_id': value});
                          }
                          onAnswerChanged?.call({'pairs': updated});
                        }
                      : null,
                  decoration: const InputDecoration(
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: Spacings.md,
                      vertical: Spacings.sm,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  // ─── Ordering ────────────────────────────────────────────────────────

  Widget _buildOrdering(BuildContext context) {
    final cs = context.colorScheme;
    final tt = context.textTheme;
    final currentOrder = (currentAnswer?['ordered_ids'] as List<dynamic>?)
            ?.cast<String>() ??
        orderItems;

    return ReorderableListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: currentOrder.length,
      onReorder: isEnabled
          ? (oldIndex, newIndex) {
              final updated = List<String>.from(currentOrder);
              if (oldIndex < newIndex) newIndex -= 1;
              final item = updated.removeAt(oldIndex);
              updated.insert(newIndex, item);
              onAnswerChanged?.call({'ordered_ids': updated});
            }
          : (_, __) {},
      itemBuilder: (context, index) {
        return Container(
          key: ValueKey('order_$index'),
          margin: const EdgeInsets.only(bottom: Spacings.sm),
          padding: const EdgeInsets.all(Spacings.md),
          decoration: BoxDecoration(
            color: cs.surfaceContainerHighest.withOpacity(0.5),
            borderRadius: BorderRadius.circular(Spacings.smRadius),
            border: Border.all(
              color: cs.outlineVariant.withOpacity(0.5),
            ),
          ),
          child: Row(
            children: [
              Icon(Icons.drag_handle_rounded, color: cs.onSurfaceVariant),
              const SizedBox(width: Spacings.sm),
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: cs.primary.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(Spacings.smRadius),
                ),
                child: Center(
                  child: Text(
                    '${index + 1}',
                    style: tt.labelMedium?.copyWith(
                      fontWeight: AppTypography.wBold,
                      color: cs.primary,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: Spacings.md),
              Expanded(
                child: Text(
                  currentOrder[index],
                  style: tt.bodyMedium?.copyWith(color: cs.onSurface),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ─── Short Answer ────────────────────────────────────────────────────

  Widget _buildShortAnswer(BuildContext context) {
    final currentText = currentAnswer?['text'] as String? ?? '';
    final controller = TextEditingController(text: currentText);

    return TextField(
      controller: controller,
      enabled: isEnabled,
      maxLines: 4,
      minLines: 3,
      decoration: const InputDecoration(
        labelText: 'Your Answer',
        hintText: 'Type your answer here…',
        alignLabelWithHint: true,
      ),
      onChanged: (value) {
        onAnswerChanged?.call({'text': value});
      },
    );
  }

  // ─── Essay ───────────────────────────────────────────────────────────

  Widget _buildEssay(BuildContext context) {
    final cs = context.colorScheme;
    final tt = context.textTheme;
    final currentText = currentAnswer?['text'] as String? ?? '';
    final controller = TextEditingController(text: currentText);
    final charLimit = maxCharacters ?? 5000;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        TextField(
          controller: controller,
          enabled: isEnabled,
          maxLines: 12,
          minLines: 8,
          maxLength: charLimit,
          decoration: const InputDecoration(
            labelText: 'Essay Response',
            hintText: 'Write your essay response here…',
            alignLabelWithHint: true,
          ),
          onChanged: (value) {
            onAnswerChanged?.call({'text': value});
          },
        ),
        const SizedBox(height: Spacings.xs),
        Text(
          '${currentText.length} / $charLimit characters',
          style: tt.bodySmall?.copyWith(
            color: currentText.length > charLimit
                ? AppColors.errorOf(cs.brightness)
                : cs.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  // ─── Numerical ───────────────────────────────────────────────────────

  Widget _buildNumerical(BuildContext context) {
    final currentValue = currentAnswer?['value']?.toString() ?? '';
    final controller = TextEditingController(text: currentValue);

    return TextField(
      controller: controller,
      enabled: isEnabled,
      keyboardType: const TextInputType.numberWithOptions(
        decimal: true,
        signed: true,
      ),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'^-?\d*\.?\d*')),
      ],
      decoration: const InputDecoration(
        labelText: 'Numerical Answer',
        hintText: 'Enter a number',
        prefixIcon: const Icon(Icons.calculate_rounded),
      ),
      onChanged: (value) {
        final numValue = double.tryParse(value);
        if (numValue != null || value.isEmpty) {
          onAnswerChanged?.call({
            'value': numValue,
            'text': value,
          });
        }
      },
    );
  }
}
