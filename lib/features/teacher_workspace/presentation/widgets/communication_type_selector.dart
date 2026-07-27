import 'package:flutter/material.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/themes/spacings.dart';
import '../../domain/entities/workspace_expansion_entities.dart';

/// A reusable widget for selecting a communication type and tone.
///
/// Displays communication types as a 2×4 grid with icons, and tones as a
/// horizontal row of selectable chips. Follows Material 3 styling with
/// the brand color for the selected state.
class CommunicationTypeSelector extends StatelessWidget {
  /// The currently selected communication type, or `null`.
  final CommunicationType? selectedType;

  /// Callback invoked when the user taps a communication type.
  final ValueChanged<CommunicationType> onTypeSelected;

  /// The currently selected communication tone, or `null`.
  final CommunicationTone? selectedTone;

  /// Callback invoked when the user taps a tone chip.
  final ValueChanged<CommunicationTone> onToneSelected;

  const CommunicationTypeSelector({
    super.key,
    this.selectedType,
    required this.onTypeSelected,
    this.selectedTone,
    required this.onToneSelected,
  });

  // ─── Type Icons ───────────────────────────────────────────────────────

  static const Map<CommunicationType, IconData> _typeIcons = {
    CommunicationType.parentLetter: Icons.mail,
    CommunicationType.studentFeedback: Icons.feedback,
    CommunicationType.email: Icons.email,
    CommunicationType.sms: Icons.sms,
    CommunicationType.announcement: Icons.campaign,
    CommunicationType.meetingInvitation: Icons.event,
    CommunicationType.permissionLetter: Icons.description,
    CommunicationType.certificate: Icons.workspace_premium,
  };

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Communication Type Grid ──────────────────────────────────
        Text(
          'Communication Type',
          style: context.textTheme.titleSmall,
        ),
        const SizedBox(height: Spacings.sm),
        _buildTypeGrid(context),
        const SizedBox(height: Spacings.lg),

        // ── Tone Chips ───────────────────────────────────────────────
        Text(
          'Tone',
          style: context.textTheme.titleSmall,
        ),
        const SizedBox(height: Spacings.sm),
        _buildToneChips(context),
      ],
    );
  }

  // ─── Type Grid (2×4) ─────────────────────────────────────────────────

  Widget _buildTypeGrid(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 2.4,
        mainAxisSpacing: Spacings.sm,
        crossAxisSpacing: Spacings.sm,
      ),
      itemCount: CommunicationType.values.length,
      itemBuilder: (context, index) {
        final type = CommunicationType.values[index];
        final isSelected = type == selectedType;
        return _CommunicationTypeCard(
          type: type,
          icon: _typeIcons[type] ?? Icons.article,
          isSelected: isSelected,
          onTap: () => onTypeSelected(type),
        );
      },
    );
  }

  // ─── Tone Chips ──────────────────────────────────────────────────────

  Widget _buildToneChips(BuildContext context) {
    return Wrap(
      spacing: Spacings.sm,
      runSpacing: Spacings.sm,
      children: CommunicationTone.values.map((tone) {
        final isSelected = tone == selectedTone;
        return _ToneChip(
          tone: tone,
          isSelected: isSelected,
          onTap: () => onToneSelected(tone),
        );
      }).toList(),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// PRIVATE: Communication Type Card
// ═══════════════════════════════════════════════════════════════════════

class _CommunicationTypeCard extends StatelessWidget {
  final CommunicationType type;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _CommunicationTypeCard({
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
              : colorScheme.outlineVariant.withValues(alpha: 0.5),
          width: isSelected ? 2.0 : 1.0,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: Spacings.borderRadiusMd,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: Spacings.md,
            vertical: Spacings.sm,
          ),
          child: Row(
            children: [
              Icon(
                icon,
                size: Spacings.mdIcon - 4,
                color: isSelected
                    ? colorScheme.primary
                    : colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: Spacings.sm),
              Expanded(
                child: Text(
                  type.label,
                  style: context.textTheme.labelSmall?.copyWith(
                    color: isSelected
                        ? colorScheme.primary
                        : colorScheme.onSurfaceVariant,
                    fontWeight:
                        isSelected ? FontWeight.w600 : FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// PRIVATE: Tone Chip
// ═══════════════════════════════════════════════════════════════════════

class _ToneChip extends StatelessWidget {
  final CommunicationTone tone;
  final bool isSelected;
  final VoidCallback onTap;

  const _ToneChip({
    required this.tone,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;

    return ChoiceChip(
      label: Text(tone.label),
      selected: isSelected,
      onSelected: (_) => onTap(),
      selectedColor: colorScheme.primary.withValues(alpha: 0.12),
      labelStyle: TextStyle(
        color: isSelected
            ? colorScheme.primary
            : colorScheme.onSurfaceVariant,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
        fontSize: 12,
      ),
      side: isSelected
          ? BorderSide(color: colorScheme.primary, width: 1.5)
          : BorderSide(
              color: colorScheme.outlineVariant.withValues(alpha: 0.5),
            ),
      shape: const RoundedRectangleBorder(
        borderRadius: Spacings.borderRadiusMd,
      ),
      visualDensity: VisualDensity.compact,
    );
  }
}
