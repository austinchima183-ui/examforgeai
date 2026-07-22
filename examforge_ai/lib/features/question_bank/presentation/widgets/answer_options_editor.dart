import 'package:flutter/material.dart';

import '../../../../core/themes/app_colors.dart';
import '../../../../core/themes/app_typography.dart';
import '../../../../core/themes/spacings.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../domain/entities/question_entities.dart';

// ─── AnswerOptionItem ─────────────────────────────────────────────────────────

/// A single editable answer option displayed within [AnswerOptionsEditor].
class _AnswerOptionItem extends StatelessWidget {
  const _AnswerOptionItem({
    required this.index,
    required this.option,
    required this.isMultiSelect,
    required this.onContentChanged,
    required this.onCorrectChanged,
    required this.onMarksChanged,
    required this.onExplanationChanged,
    this.onDelete,
    this.showDragHandle = true,
  });

  final int index;
  final AnswerOptionEntity option;
  final bool isMultiSelect;
  final ValueChanged<String> onContentChanged;
  final ValueChanged<bool> onCorrectChanged;
  final ValueChanged<double> onMarksChanged;
  final ValueChanged<String> onExplanationChanged;
  final VoidCallback? onDelete;
  final bool showDragHandle;

  String get _optionLetter => String.fromCharCode(65 + index); // A, B, C...

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;
    final tt = context.textTheme;
    final isDark = context.isDarkMode;

    final correctColor = option.isCorrect
        ? AppColors.successOf(cs.brightness)
        : cs.onSurfaceVariant;

    return Container(
      padding: const EdgeInsets.all(Spacings.md),
      decoration: BoxDecoration(
        color: option.isCorrect
            ? AppColors.success.withOpacity(isDark ? 0.15 : 0.06)
            : cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(Spacings.mdRadius),
        border: Border.all(
          color: option.isCorrect
              ? AppColors.success.withOpacity(0.4)
              : cs.outlineVariant.withOpacity(0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Top Row: Drag handle + Letter + Correct toggle + Delete ─
          Row(
            children: [
              if (showDragHandle)
                Padding(
                  padding: const EdgeInsets.only(right: Spacings.sm),
                  child: Icon(
                    Icons.drag_indicator_rounded,
                    size: Spacings.mdIcon,
                    color: cs.onSurfaceVariant.withOpacity(0.4),
                  ),
                ),

              // Option letter badge
              Container(
                width: 28.0,
                height: 28.0,
                decoration: BoxDecoration(
                  color: correctColor.withOpacity(isDark ? 0.25 : 0.12),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    _optionLetter,
                    style: tt.labelMedium?.copyWith(
                      color: correctColor,
                      fontWeight: AppTypography.wBold,
                    ),
                  ),
                ),
              ),

              const SizedBox(width: Spacings.sm),

              // Correct answer toggle
              if (isMultiSelect)
                SizedBox(
                  height: 28.0,
                  child: Checkbox(
                    value: option.isCorrect,
                    onChanged: (v) => onCorrectChanged(v ?? false),
                    activeColor: AppColors.success,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                )
              else
                SizedBox(
                  height: 28.0,
                  child: Radio<bool>(
                    value: true,
                    groupValue: option.isCorrect,
                    onChanged: (v) => onCorrectChanged(true),
                    activeColor: AppColors.success,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),

              const SizedBox(width: Spacings.xs),
              Text(
                'Correct',
                style: tt.bodySmall?.copyWith(
                  color: correctColor,
                  fontWeight: option.isCorrect
                      ? AppTypography.wSemiBold
                      : AppTypography.wRegular,
                ),
              ),

              const Spacer(),

              // Delete button
              IconButton(
                icon: Icon(
                  Icons.close_rounded,
                  size: Spacings.mdIcon,
                  color: cs.onSurfaceVariant.withOpacity(0.5),
                ),
                onPressed: onDelete,
                tooltip: 'Remove option',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(
                  minWidth: 32.0,
                  minHeight: 32.0,
                ),
              ),
            ],
          ),

          const SizedBox(height: Spacings.sm),

          // ── Content Field ────────────────────────────────────────
          TextFormField(
            initialValue: option.content,
            onChanged: onContentChanged,
            style: tt.bodyMedium?.copyWith(color: cs.onSurface),
            maxLines: 2,
            minLines: 1,
            decoration: InputDecoration(
              hintText: 'Enter option $_optionLetter content…',
              hintStyle: tt.bodyMedium?.copyWith(
                color: cs.onSurfaceVariant.withOpacity(0.5),
              ),
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: Spacings.md,
                vertical: Spacings.sm,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(Spacings.smRadius),
                borderSide: BorderSide(color: cs.outlineVariant),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(Spacings.smRadius),
                borderSide: BorderSide(
                  color: cs.outlineVariant.withOpacity(0.5),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(Spacings.smRadius),
                borderSide: BorderSide(color: cs.primary, width: 1.5),
              ),
            ),
          ),

          // ── Partial Marks + Explanation (for multiple response) ───
          if (isMultiSelect) ...[
            const SizedBox(height: Spacings.sm),
            Row(
              children: [
                // Partial marks
                SizedBox(
                  width: 100.0,
                  child: TextFormField(
                    initialValue: option.marks > 0 ? option.marks.toString() : '',
                    onChanged: (v) {
                      final val = double.tryParse(v);
                      if (val != null) onMarksChanged(val);
                    },
                    keyboardType: TextInputType.number,
                    style: tt.bodySmall?.copyWith(color: cs.onSurface),
                    decoration: InputDecoration(
                      labelText: 'Marks',
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: Spacings.sm,
                        vertical: Spacings.xs,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(Spacings.smRadius),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],

          // ── Explanation per option ────────────────────────────────
          const SizedBox(height: Spacings.sm),
          TextFormField(
            initialValue: option.explanation ?? '',
            onChanged: onExplanationChanged,
            style: tt.bodySmall?.copyWith(color: cs.onSurface),
            maxLines: 2,
            minLines: 1,
            decoration: InputDecoration(
              labelText: 'Explanation (optional)',
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: Spacings.md,
                vertical: Spacings.sm,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(Spacings.smRadius),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(Spacings.smRadius),
                borderSide: BorderSide(
                  color: cs.outlineVariant.withOpacity(0.5),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(Spacings.smRadius),
                borderSide: BorderSide(color: cs.primary, width: 1.5),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── AnswerOptionsEditor ──────────────────────────────────────────────────────

/// An editor widget for answer options supporting both multiple choice
/// (single correct) and multiple response (multiple correct) modes.
///
/// Features:
/// - Add/remove options (min 2, max 10)
/// - Rich text input for each option
/// - Correct answer toggle (radio/checkbox)
/// - Partial marks for multi-select
/// - Drag handles for reordering
/// - Explanation field per option
///
/// ```dart
/// AnswerOptionsEditor(
///   options: myOptions,
///   isMultiSelect: false,
///   onOptionsChanged: (newOptions) => updateState(newOptions),
/// )
/// ```
class AnswerOptionsEditor extends StatefulWidget {
  const AnswerOptionsEditor({
    super.key,
    required this.options,
    required this.isMultiSelect,
    this.onOptionsChanged,
    this.isEnabled = true,
  });

  /// The current list of answer options.
  final List<AnswerOptionEntity> options;

  /// Whether multiple correct answers are allowed.
  final bool isMultiSelect;

  /// Called when the options list changes.
  final ValueChanged<List<AnswerOptionEntity>>? onOptionsChanged;

  /// Whether the editor is interactive.
  final bool isEnabled;

  @override
  State<AnswerOptionsEditor> createState() => _AnswerOptionsEditorState();
}

class _AnswerOptionsEditorState extends State<AnswerOptionsEditor> {
  late List<AnswerOptionEntity> _options;
  static const int _minOptions = 2;
  static const int _maxOptions = 10;

  @override
  void initState() {
    super.initState();
    _options = List.from(widget.options);
  }

  @override
  void didUpdateWidget(covariant AnswerOptionsEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.options != widget.options) {
      _options = List.from(widget.options);
    }
  }

  void _notifyChanged() {
    widget.onOptionsChanged?.call(List.from(_options));
  }

  void _addOption() {
    if (_options.length >= _maxOptions) return;
    final now = DateTime.now();
    final newOption = AnswerOptionEntity(
      id: 'new_${DateTime.now().millisecondsSinceEpoch}',
      questionId: '',
      content: '',
      isCorrect: false,
      marks: 0.0,
      sortOrder: _options.length,
      explanation: null,
      createdAt: now,
      updatedAt: now,
    );
    setState(() {
      _options.add(newOption);
    });
    _notifyChanged();
  }

  void _removeOption(int index) {
    if (_options.length <= _minOptions) return;
    setState(() {
      _options.removeAt(index);
      // Re-index sort order
      for (var i = 0; i < _options.length; i++) {
        _options[i] = _options[i].copyWith(sortOrder: i);
      }
    });
    _notifyChanged();
  }

  void _updateOptionContent(int index, String content) {
    _options[index] = _options[index].copyWith(content: content);
    _notifyChanged();
  }

  void _updateOptionCorrect(int index, bool isCorrect) {
    setState(() {
      if (!widget.isMultiSelect) {
        // Single select: deselect all others
        for (var i = 0; i < _options.length; i++) {
          _options[i] = _options[i].copyWith(isCorrect: i == index);
        }
      } else {
        _options[index] = _options[index].copyWith(isCorrect: isCorrect);
      }
    });
    _notifyChanged();
  }

  void _updateOptionMarks(int index, double marks) {
    _options[index] = _options[index].copyWith(marks: marks);
    _notifyChanged();
  }

  void _updateOptionExplanation(int index, String explanation) {
    _options[index] = _options[index].copyWith(
      explanation: explanation.isEmpty ? null : explanation,
    );
    _notifyChanged();
  }

  void _reorderOptions(int oldIndex, int newIndex) {
    if (oldIndex < newIndex) newIndex -= 1;
    setState(() {
      final item = _options.removeAt(oldIndex);
      _options.insert(newIndex, item);
      for (var i = 0; i < _options.length; i++) {
        _options[i] = _options[i].copyWith(sortOrder: i);
      }
    });
    _notifyChanged();
  }

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;
    final tt = context.textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // ── Header ────────────────────────────────────────────────
        Row(
          children: [
            Icon(
              widget.isMultiSelect ? Icons.check_box_rounded : Icons.radio_button_checked_rounded,
              size: Spacings.mdIcon,
              color: cs.primary,
            ),
            const SizedBox(width: Spacings.sm),
            Text(
              widget.isMultiSelect ? 'Answer Options (Multiple Response)' : 'Answer Options (Single Choice)',
              style: tt.titleSmall?.copyWith(
                fontWeight: AppTypography.wSemiBold,
                color: cs.onSurface,
              ),
            ),
            const Spacer(),
            Text(
              '${_options.length}/$_maxOptions',
              style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
            ),
          ],
        ),

        const SizedBox(height: Spacings.md),

        // ── Options List (Reorderable) ────────────────────────────
        ReorderableListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _options.length,
          onReorder: widget.isEnabled ? _reorderOptions : (_, __) {},
          proxyDecorator: (child, index, animation) {
            return AnimatedBuilder(
              animation: animation,
              builder: (context, _) {
                final t = Curves.easeInOut.transform(animation.value);
                return Transform.scale(
                  scale: 1.0 + (0.02 * t),
                  child: Opacity(
                    opacity: 0.85,
                    child: Material(
                      elevation: Spacings.elevationMd * t,
                      borderRadius: BorderRadius.circular(Spacings.mdRadius),
                      child: child,
                    ),
                  ),
                );
              },
            );
          },
          itemBuilder: (context, index) {
            final option = _options[index];
            return Padding(
              key: ValueKey(option.id),
              padding: const EdgeInsets.only(bottom: Spacings.sm),
              child: _AnswerOptionItem(
                index: index,
                option: option,
                isMultiSelect: widget.isMultiSelect,
                onContentChanged: widget.isEnabled
                    ? (v) => _updateOptionContent(index, v)
                    : (_) {},
                onCorrectChanged: widget.isEnabled
                    ? (v) => _updateOptionCorrect(index, v)
                    : (_) {},
                onMarksChanged: widget.isEnabled
                    ? (v) => _updateOptionMarks(index, v)
                    : (_) {},
                onExplanationChanged: widget.isEnabled
                    ? (v) => _updateOptionExplanation(index, v)
                    : (_) {},
                onDelete: widget.isEnabled && _options.length > _minOptions
                    ? () => _removeOption(index)
                    : null,
              ),
            );
          },
        ),

        const SizedBox(height: Spacings.sm),

        // ── Add Option Button ─────────────────────────────────────
        if (widget.isEnabled && _options.length < _maxOptions)
          Center(
            child: AppButton(
              label: 'Add Option',
              onPressed: _addOption,
              variant: AppButtonVariant.outlined,
              icon: Icons.add_rounded,
              size: AppButtonSize.small,
            ),
          ),

        // ── Helper Text ───────────────────────────────────────────
        const SizedBox(height: Spacings.sm),
        Text(
          widget.isMultiSelect
              ? 'Select all correct answers. Min $_minOptions, max $_maxOptions options.'
              : 'Select the one correct answer. Min $_minOptions, max $_maxOptions options.',
          style: tt.bodySmall?.copyWith(
            color: cs.onSurfaceVariant,
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    );
  }
}
