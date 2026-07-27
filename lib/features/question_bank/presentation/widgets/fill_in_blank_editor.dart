import 'package:flutter/material.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/themes/app_typography.dart';
import '../../../../core/themes/spacings.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../domain/entities/question_entities.dart';

// ─── BlankEntryRow ────────────────────────────────────────────────────────────

/// A single editable blank entry displayed within [FillInBlankEditor].
class _BlankEntryRow extends StatelessWidget {
  const _BlankEntryRow({
    required this.blankIndex,
    required this.blank,
    required this.onAnswersChanged,
    required this.onCaseSensitivityChanged,
    required this.onMarksChanged,
    required this.onDelete,
    this.canDelete = true,
  });

  final int blankIndex;
  final FillInBlankAnswerEntity blank;
  final ValueChanged<String> onAnswersChanged;
  final ValueChanged<bool> onCaseSensitivityChanged;
  final ValueChanged<double> onMarksChanged;
  final VoidCallback? onDelete;
  final bool canDelete;

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;
    final tt = context.textTheme;
    final isDark = context.isDarkMode;

    return Container(
      padding: const EdgeInsets.all(Spacings.md),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(Spacings.mdRadius),
        border: Border.all(
          color: cs.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header Row ────────────────────────────────────────────
          Row(
            children: [
              // Blank index badge
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: Spacings.md,
                  vertical: Spacings.xs,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFD97706).withValues(alpha: isDark ? 0.25 : 0.12),
                  borderRadius: BorderRadius.circular(Spacings.smRadius),
                ),
                child: Text(
                  'Blank ${blankIndex + 1}',
                  style: tt.labelMedium?.copyWith(
                    color: const Color(0xFFD97706),
                    fontWeight: AppTypography.wSemiBold,
                  ),
                ),
              ),
              const Spacer(),

              // Case sensitivity toggle
              InkWell(
                onTap: () => onCaseSensitivityChanged(!blank.isCaseSensitive),
                borderRadius: BorderRadius.circular(Spacings.smRadius),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: Spacings.sm,
                    vertical: Spacings.xs,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        blank.isCaseSensitive
                            ? Icons.text_fields
                            : Icons.text_fields_rounded,
                        size: Spacings.mdIcon,
                        color: blank.isCaseSensitive
                            ? const Color(0xFFD97706)
                            : cs.onSurfaceVariant.withValues(alpha: 0.5),
                      ),
                      const SizedBox(width: Spacings.xs),
                      Text(
                        blank.isCaseSensitive ? 'Case Sensitive' : 'Case Insensitive',
                        style: tt.bodySmall?.copyWith(
                          color: blank.isCaseSensitive
                              ? const Color(0xFFD97706)
                              : cs.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Delete button
              if (canDelete && onDelete != null)
                IconButton(
                  icon: Icon(
                    Icons.close_rounded,
                    size: Spacings.mdIcon,
                    color: cs.onSurfaceVariant.withValues(alpha: 0.5),
                  ),
                  onPressed: onDelete,
                  tooltip: 'Remove blank',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                ),
            ],
          ),

          const SizedBox(height: Spacings.md),

          // ── Acceptable Answers ────────────────────────────────────
          Text(
            'Acceptable Answers (comma-separated)',
            style: tt.labelSmall?.copyWith(
              color: cs.onSurfaceVariant,
              fontWeight: AppTypography.wMedium,
            ),
          ),
          const SizedBox(height: Spacings.xs),
          TextFormField(
            initialValue: blank.acceptableAnswers.join(', '),
            onChanged: onAnswersChanged,
            style: tt.bodyMedium?.copyWith(color: cs.onSurface),
            maxLines: 2,
            minLines: 1,
            decoration: InputDecoration(
              hintText: 'e.g., photosynthesis, Photosynthesis',
              hintStyle: tt.bodySmall?.copyWith(
                color: cs.onSurfaceVariant.withValues(alpha: 0.5),
              ),
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
                  color: cs.outlineVariant.withValues(alpha: 0.5),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(Spacings.smRadius),
                borderSide: BorderSide(color: cs.primary, width: 1.5),
              ),
            ),
          ),

          const SizedBox(height: Spacings.md),

          // ── Marks ─────────────────────────────────────────────────
          Row(
            children: [
              SizedBox(
                width: 120.0,
                child: TextFormField(
                  initialValue: blank.marks > 0 ? blank.marks.toString() : '',
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
      ),
    );
  }
}

// ─── FillInBlankEditor ────────────────────────────────────────────────────────

/// An editor widget for fill-in-the-blank type questions. Each blank entry
/// has an index, a comma-separated list of acceptable answers, a case
/// sensitivity toggle, and a marks field. Supports add/remove blank entries.
///
/// ```dart
/// FillInBlankEditor(
///   blanks: myBlanks,
///   onBlanksChanged: (newBlanks) => updateState(newBlanks),
/// )
/// ```
class FillInBlankEditor extends StatefulWidget {
  const FillInBlankEditor({
    super.key,
    required this.blanks,
    this.onBlanksChanged,
    this.isEnabled = true,
  });

  /// The current list of fill-in-blank answer entries.
  final List<FillInBlankAnswerEntity> blanks;

  /// Called when the blanks list changes.
  final ValueChanged<List<FillInBlankAnswerEntity>>? onBlanksChanged;

  /// Whether the editor is interactive.
  final bool isEnabled;

  @override
  State<FillInBlankEditor> createState() => _FillInBlankEditorState();
}

class _FillInBlankEditorState extends State<FillInBlankEditor> {
  late List<FillInBlankAnswerEntity> _blanks;

  @override
  void initState() {
    super.initState();
    _blanks = List.from(widget.blanks);
  }

  @override
  void didUpdateWidget(covariant FillInBlankEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.blanks != widget.blanks) {
      _blanks = List.from(widget.blanks);
    }
  }

  void _notifyChanged() {
    widget.onBlanksChanged?.call(List.from(_blanks));
  }

  void _addBlank() {
    final now = DateTime.now();
    final newBlank = FillInBlankAnswerEntity(
      id: 'new_${DateTime.now().millisecondsSinceEpoch}',
      questionId: '',
      blankIndex: _blanks.length,
      acceptableAnswers: const [],
      isCaseSensitive: false,
      marks: 0.0,
      createdAt: now,
    );
    setState(() {
      _blanks.add(newBlank);
    });
    _notifyChanged();
  }

  void _removeBlank(int index) {
    if (_blanks.isEmpty) return;
    setState(() {
      _blanks.removeAt(index);
      // Re-index blanks
      for (var i = 0; i < _blanks.length; i++) {
        _blanks[i] = _blanks[i].copyWith(blankIndex: i);
      }
    });
    _notifyChanged();
  }

  void _updateAnswers(int index, String rawAnswers) {
    final answers = rawAnswers
        .split(',')
        .map((a) => a.trim())
        .where((a) => a.isNotEmpty)
        .toList();
    _blanks[index] = _blanks[index].copyWith(acceptableAnswers: answers);
    _notifyChanged();
  }

  void _updateCaseSensitivity(int index, bool isCaseSensitive) {
    setState(() {
      _blanks[index] = _blanks[index].copyWith(isCaseSensitive: isCaseSensitive);
    });
    _notifyChanged();
  }

  void _updateMarks(int index, double marks) {
    _blanks[index] = _blanks[index].copyWith(marks: marks);
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
              Icons.edit_note_rounded,
              size: Spacings.mdIcon,
              color: cs.primary,
            ),
            const SizedBox(width: Spacings.sm),
            Text(
              'Fill in the Blanks',
              style: tt.titleSmall?.copyWith(
                fontWeight: AppTypography.wSemiBold,
                color: cs.onSurface,
              ),
            ),
            const Spacer(),
            Text(
              '${_blanks.length} blank${_blanks.length == 1 ? '' : 's'}',
              style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
            ),
          ],
        ),

        const SizedBox(height: Spacings.md),

        // ── Blanks List ───────────────────────────────────────────
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _blanks.length,
          separatorBuilder: (_, __) => const SizedBox(height: Spacings.sm),
          itemBuilder: (context, index) {
            final blank = _blanks[index];
            return _BlankEntryRow(
              blankIndex: index,
              blank: blank,
              onAnswersChanged: widget.isEnabled
                  ? (v) => _updateAnswers(index, v)
                  : (_) {},
              onCaseSensitivityChanged: widget.isEnabled
                  ? (v) => _updateCaseSensitivity(index, v)
                  : (_) {},
              onMarksChanged: widget.isEnabled
                  ? (v) => _updateMarks(index, v)
                  : (_) {},
              onDelete: widget.isEnabled ? () => _removeBlank(index) : null,
              canDelete: _blanks.length > 1,
            );
          },
        ),

        const SizedBox(height: Spacings.sm),

        // ── Add Blank Button ──────────────────────────────────────
        if (widget.isEnabled)
          Center(
            child: AppButton(
              label: 'Add Blank',
              onPressed: _addBlank,
              variant: AppButtonVariant.outlined,
              icon: Icons.add_rounded,
              size: AppButtonSize.small,
            ),
          ),

        const SizedBox(height: Spacings.sm),
        Text(
          'Enter acceptable answers separated by commas. Toggle case sensitivity per blank.',
          style: tt.bodySmall?.copyWith(
            color: cs.onSurfaceVariant,
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    );
  }
}
