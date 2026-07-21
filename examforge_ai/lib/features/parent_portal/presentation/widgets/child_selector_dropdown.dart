import 'package:flutter/material.dart';

import '../../../../core/themes/app_colors.dart';
import '../../../../core/themes/app_typography.dart';
import '../../../../core/themes/spacings.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../domain/entities/parent_portal_entities.dart';

// ═══════════════════════════════════════════════════════════════════════
// CHILD SELECTOR DROPDOWN
// ═══════════════════════════════════════════════════════════════════════

/// Dropdown for selecting which child to view data for.
///
/// Shows an avatar circle with the first letter of the selected child's name,
/// the child's name and class, and a dropdown arrow. When opened, displays
/// a list of children with avatars. If only one child is linked, shows
/// their name without the dropdown functionality.
///
/// ```dart
/// ChildSelectorDropdown(
///   selectedStudentId: 'stu-1',
///   onChildSelected: (id) => setState(() => _selectedId = id),
///   children: myChildren,
/// )
/// ```
class ChildSelectorDropdown extends StatelessWidget {
  const ChildSelectorDropdown({
    super.key,
    this.selectedStudentId,
    required this.onChildSelected,
    required this.children,
  });

  /// Currently selected student ID.
  final String? selectedStudentId;

  /// Callback when a child is selected.
  final ValueChanged<String?> onChildSelected;

  /// List of children available for selection.
  final List<ChildSummaryEntity> children;

  ChildSummaryEntity? get _selectedChild {
    if (selectedStudentId == null) return null;
    try {
      return children.firstWhere((c) => c.studentId == selectedStudentId);
    } catch (_) {
      return children.isNotEmpty ? children.first : null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;
    final tt = context.textTheme;
    final isDark = context.isDarkMode;

    // Single child — just show their name
    if (children.length <= 1) {
      final child = children.isNotEmpty ? children.first : null;
      if (child == null) return const SizedBox.shrink();

      return _buildChildChip(context, child, cs, tt, isDark, enabled: false);
    }

    // Multiple children — show dropdown
    final selected = _selectedChild ?? children.first;

    return PopupMenuButton<String>(
      offset: const Offset(0, 52),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Spacings.mdRadius),
      ),
      elevation: Spacings.elevationMd,
      color: cs.surface,
      onSelected: onChildSelected,
      itemBuilder: (context) => children
          .map((child) => PopupMenuItem<String>(
                value: child.studentId,
                height: 48,
                child: Row(
                  children: [
                    _buildAvatarCircle(child, cs, isDark, size: 28),
                    const SizedBox(width: Spacings.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            child.studentName,
                            style: tt.bodyMedium?.copyWith(
                              fontWeight: AppTypography.wMedium,
                              color: cs.onSurface,
                            ),
                          ),
                          if (child.className != null)
                            Text(
                              child.className!,
                              style: tt.labelSmall?.copyWith(
                                color: cs.onSurfaceVariant,
                              ),
                            ),
                        ],
                      ),
                    ),
                    if (child.studentId == selected.studentId)
                      Icon(Icons.check_rounded, size: Spacings.mdIcon, color: cs.primary),
                  ],
                ),
              ))
          .toList(),
      child: _buildChildChip(context, selected, cs, tt, isDark, enabled: true),
    );
  }

  // ─── Child Chip / Button ───────────────────────────────────────────

  Widget _buildChildChip(
    BuildContext context,
    ChildSummaryEntity child,
    ColorScheme cs,
    TextTheme tt,
    bool isDark, {
    required bool enabled,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Spacings.md,
        vertical: Spacings.sm,
      ),
      decoration: BoxDecoration(
        color: cs.primary.withOpacity(isDark ? 0.15 : 0.08),
        borderRadius: BorderRadius.circular(Spacings.fullRadius),
        border: Border.all(
          color: cs.primary.withOpacity(0.2),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildAvatarCircle(child, cs, isDark),
          const SizedBox(width: Spacings.sm),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                child.studentName,
                style: tt.labelLarge?.copyWith(
                  fontWeight: AppTypography.wSemiBold,
                  color: cs.primary,
                ),
              ),
              if (child.className != null)
                Text(
                  child.className!,
                  style: tt.labelSmall?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
                ),
            ],
          ),
          if (enabled) ...[
            const SizedBox(width: Spacings.xs),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              size: Spacings.mdIcon,
              color: cs.primary,
            ),
          ],
        ],
      ),
    );
  }

  // ─── Avatar Circle ─────────────────────────────────────────────────

  Widget _buildAvatarCircle(
    ChildSummaryEntity child,
    ColorScheme cs,
    bool isDark, {
    double size = 32,
  }) {
    final initial = child.studentName.isNotEmpty
        ? child.studentName[0].toUpperCase()
        : '?';

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: cs.primary.withOpacity(isDark ? 0.25 : 0.15),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          initial,
          style: TextStyle(
            fontSize: size * 0.45,
            fontWeight: AppTypography.wBold,
            color: cs.primary,
            height: 1.0,
          ),
        ),
      ),
    );
  }
}
