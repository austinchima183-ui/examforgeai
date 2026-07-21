import 'package:flutter/material.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/themes/spacings.dart';
import '../../domain/entities/workspace_expansion_entities.dart';

/// A reusable widget for selecting a presentation type.
///
/// Displays presentation types either as a 3-column grid (default) or as
/// horizontally scrollable chips ([isCompact] = true). Each type shows an
/// icon and label, with the selected item highlighted using the brand color
/// border.
class PresentationTypeSelector extends StatelessWidget {
  /// The currently selected presentation type, or `null` if none selected.
  final PresentationType? selectedType;

  /// Callback invoked when the user taps a presentation type.
  final ValueChanged<PresentationType> onTypeSelected;

  /// When `true`, render as a horizontal row of scrollable chips;
  /// otherwise render as a 3-column grid.
  final bool isCompact;

  const PresentationTypeSelector({
    super.key,
    this.selectedType,
    required this.onTypeSelected,
    this.isCompact = false,
  });

  // ─── Type Metadata ────────────────────────────────────────────────────

  static const Map<PresentationType, IconData> _typeIcons = {
    PresentationType.powerpoint: Icons.slideshow,
    PresentationType.teachingSlides: Icons.school,
    PresentationType.infographic: Icons.auto_graph,
    PresentationType.diagram: Icons.account_tree,
    PresentationType.flowchart: Icons.alt_route,
    PresentationType.mindMap: Icons.hub,
    PresentationType.summarySheet: Icons.summarize,
  };

  @override
  Widget build(BuildContext context) {
    if (isCompact) return _buildChips(context);
    return _buildGrid(context);
  }

  // ─── Grid Layout ─────────────────────────────────────────────────────

  Widget _buildGrid(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 1.1,
        mainAxisSpacing: Spacings.sm,
        crossAxisSpacing: Spacings.sm,
      ),
      itemCount: PresentationType.values.length,
      itemBuilder: (context, index) {
        final type = PresentationType.values[index];
        final isSelected = type == selectedType;
        return _TypeGridItem(
          type: type,
          icon: _typeIcons[type] ?? Icons.description,
          isSelected: isSelected,
          onTap: () => onTypeSelected(type),
        );
      },
    );
  }

  // ─── Chips Layout ────────────────────────────────────────────────────

  Widget _buildChips(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: PresentationType.values.map((type) {
          final isSelected = type == selectedType;
          return Padding(
            padding: const EdgeInsets.only(right: Spacings.sm),
            child: _TypeChip(
              type: type,
              icon: _typeIcons[type] ?? Icons.description,
              isSelected: isSelected,
              onTap: () => onTypeSelected(type),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// PRIVATE: Grid Item
// ═══════════════════════════════════════════════════════════════════════

class _TypeGridItem extends StatelessWidget {
  final PresentationType type;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _TypeGridItem({
    required this.type,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;

    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: Spacings.elevationNone,
      shape: RoundedRectangleBorder(
        borderRadius: Spacings.borderRadiusMd,
        side: BorderSide(
          color: isSelected
              ? colorScheme.primary
              : colorScheme.outlineVariant.withOpacity(0.5),
          width: isSelected ? 2.0 : 1.0,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: Spacings.borderRadiusMd,
        child: Padding(
          padding: const EdgeInsets.all(Spacings.md),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isSelected
                      ? colorScheme.primary.withOpacity(0.12)
                      : colorScheme.surfaceContainerHighest
                          .withOpacity(0.5),
                  borderRadius: Spacings.borderRadiusMd,
                ),
                child: Icon(
                  icon,
                  color: isSelected
                      ? colorScheme.primary
                      : colorScheme.onSurfaceVariant,
                  size: Spacings.mdIcon,
                ),
              ),
              const SizedBox(height: Spacings.sm),
              Text(
                type.label,
                style: context.textTheme.labelSmall?.copyWith(
                  color: isSelected
                      ? colorScheme.primary
                      : colorScheme.onSurfaceVariant,
                  fontWeight:
                      isSelected ? FontWeight.w600 : FontWeight.w500,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// PRIVATE: Chip Item
// ═══════════════════════════════════════════════════════════════════════

class _TypeChip extends StatelessWidget {
  final PresentationType type;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _TypeChip({
    required this.type,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;

    return InputChip(
      onPressed: onTap,
      selected: isSelected,
      avatar: Icon(
        icon,
        size: Spacings.smIcon,
        color: isSelected
            ? colorScheme.onPrimary
            : colorScheme.onSurfaceVariant,
      ),
      label: Text(type.label),
      selectedColor: colorScheme.primary,
      labelStyle: TextStyle(
        color: isSelected
            ? colorScheme.onPrimary
            : colorScheme.onSurfaceVariant,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
        fontSize: 12,
      ),
      side: isSelected
          ? BorderSide.none
          : BorderSide(
              color: colorScheme.outlineVariant.withOpacity(0.5),
            ),
      shape: RoundedRectangleBorder(
        borderRadius: Spacings.borderRadiusMd,
      ),
    );
  }
}
