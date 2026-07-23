import 'package:flutter/material.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/themes/app_typography.dart';
import '../../../../core/themes/spacings.dart';

// ═══════════════════════════════════════════════════════════════════════
// SUBJECT SELECTOR
// ═══════════════════════════════════════════════════════════════════════

/// A subject item used by [SubjectSelector].
class SubjectItem {
  const SubjectItem({required this.id, required this.name});

  final String id;
  final String name;
}

/// Dropdown / chip selector for subjects.
///
/// Takes a list of [SubjectItem] objects and a [selectedId], and fires
/// [onChanged] when the user selects a different subject.
///
/// ```dart
/// SubjectSelector(
///   subjects: [
///     SubjectItem(id: 'math', name: 'Mathematics'),
///     SubjectItem(id: 'eng', name: 'English'),
///   ],
///   selectedId: 'math',
///   onChanged: (id) => print(id),
/// )
/// ```
class SubjectSelector extends StatelessWidget {
  const SubjectSelector({
    super.key,
    required this.subjects,
    this.selectedId,
    this.onChanged,
    this.label,
    this.chipMode = false,
  });

  /// List of subjects to choose from.
  final List<SubjectItem> subjects;

  /// Currently selected subject ID (null for no selection).
  final String? selectedId;

  /// Callback when the user selects a subject.
  final ValueChanged<String?>? onChanged;

  /// Optional label displayed above the selector.
  final String? label;

  /// When true, displays a horizontal chip row instead of a dropdown.
  final bool chipMode;

  @override
  Widget build(BuildContext context) {
    if (chipMode) return _buildChipMode(context);
    return _buildDropdownMode(context);
  }

  // ─── Dropdown Mode ─────────────────────────────────────────────────

  Widget _buildDropdownMode(BuildContext context) {
    final cs = context.colorScheme;
    final tt = context.textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (label != null) ...[
          Text(
            label!,
            style: tt.labelLarge?.copyWith(
              fontWeight: AppTypography.wSemiBold,
              color: cs.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: Spacings.sm),
        ],
        DropdownButtonFormField<String>(
          initialValue: selectedId,
          decoration: InputDecoration(
            hintText: 'Select a subject',
            hintStyle: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
            prefixIcon: Icon(
              Icons.book_outlined,
              size: Spacings.mdIcon,
              color: cs.onSurfaceVariant,
            ),
            filled: true,
            fillColor: cs.surfaceContainerLow,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(Spacings.mdRadius),
              borderSide: BorderSide(color: cs.outlineVariant),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(Spacings.mdRadius),
              borderSide: BorderSide(color: cs.outlineVariant),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(Spacings.mdRadius),
              borderSide: BorderSide(color: cs.primary, width: 2),
            ),
            contentPadding: Spacings.paddingInput,
          ),
          items: subjects.map((s) {
            return DropdownMenuItem<String>(
              value: s.id,
              child: Text(
                s.name,
                style: tt.bodyMedium?.copyWith(color: cs.onSurface),
              ),
            );
          }).toList(),
          onChanged: onChanged,
          icon: Icon(Icons.expand_more_rounded, color: cs.onSurfaceVariant),
        ),
      ],
    );
  }

  // ─── Chip Mode ─────────────────────────────────────────────────────

  Widget _buildChipMode(BuildContext context) {
    final cs = context.colorScheme;
    final tt = context.textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (label != null) ...[
          Text(
            label!,
            style: tt.labelLarge?.copyWith(
              fontWeight: AppTypography.wSemiBold,
              color: cs.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: Spacings.sm),
        ],
        Wrap(
          spacing: Spacings.sm,
          runSpacing: Spacings.sm,
          children: subjects.map((s) {
            final isSelected = s.id == selectedId;
            return ChoiceChip(
              label: Text(s.name),
              selected: isSelected,
              onSelected: (_) => onChanged?.call(s.id),
              labelStyle: tt.labelMedium?.copyWith(
                fontWeight:
                    isSelected ? AppTypography.wBold : AppTypography.wMedium,
                color: isSelected
                    ? cs.onPrimary
                    : cs.onSurface,
              ),
              selectedColor: cs.primary,
              backgroundColor: cs.surfaceContainerLow,
              side: BorderSide(
                color: isSelected
                    ? cs.primary
                    : cs.outlineVariant,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(Spacings.smRadius),
              ),
              showCheckmark: false,
            );
          }).toList(),
        ),
      ],
    );
  }
}
