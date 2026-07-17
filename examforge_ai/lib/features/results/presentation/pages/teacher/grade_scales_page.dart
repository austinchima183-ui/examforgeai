import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/themes/app_colors.dart';
import '../../../../../core/themes/app_typography.dart';
import '../../../../../core/themes/spacings.dart';
import '../../../../../core/extensions/context_extensions.dart';
import '../../../../../core/utils/result.dart';
import '../../../../../shared/widgets/app_app_bar.dart';
import '../../../../../shared/widgets/app_button.dart';
import '../../../../../shared/widgets/app_card.dart';
import '../../../../../shared/widgets/app_dialog.dart';
import '../../../../../shared/widgets/app_empty_state.dart';
import '../../../../../shared/widgets/app_loading.dart';
import '../../domain/entities/results_entities.dart';
import '../providers/results_providers.dart';

// ═══════════════════════════════════════════════════════════════════════
// GRADE SCALES PAGE
// ═══════════════════════════════════════════════════════════════════════

/// Page for managing grade scales (create, edit, delete).
///
/// Lists all grade scales for the school, with FAB to create a new
/// scale and tap-to-edit dialogs for each scale.
class GradeScalesPage extends ConsumerStatefulWidget {
  const GradeScalesPage({super.key, required this.schoolId});

  final String schoolId;

  @override
  ConsumerState<GradeScalesPage> createState() => _GradeScalesPageState();
}

class _GradeScalesPageState extends ConsumerState<GradeScalesPage> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref
          .read(gradeScaleProvider.notifier)
          .loadGradeScales(widget.schoolId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;
    final tt = context.textTheme;
    final state = ref.watch(gradeScaleProvider);

    return Scaffold(
      appBar: AppAppBar(
        title: 'Grade Scales',
      ),
      body: state.isLoading
          ? const Center(
              child: AppLoadingSpinner(size: AppLoadingSpinnerSize.large))
          : _buildBody(context, state),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateDialog(context),
        icon: const Icon(Icons.add_rounded),
        label: Text(
          'New Scale',
          style: AppTypography.button
              .copyWith(color: cs.onPrimaryContainer),
        ),
        backgroundColor: cs.primaryContainer,
        foregroundColor: cs.onPrimaryContainer,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Spacings.lgRadius),
        ),
      ),
    );
  }

  // ─── Body ──────────────────────────────────────────────────────────

  Widget _buildBody(BuildContext context, GradeScaleState state) {
    if (state.gradeScales.isEmpty) {
      return AppEmptyState(
        icon: Icons.straighten_rounded,
        title: 'No Grade Scales',
        subtitle:
            'Create your first grade scale to start converting scores to grades.',
        actionLabel: 'Create Scale',
        onAction: () => _showCreateDialog(context),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(Spacings.lg),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Summary ──────────────────────────────────────────
              _buildSummary(context, state),
              const SizedBox(height: Spacings.xl),

              // ── Error banner ─────────────────────────────────────
              if (state.error != null)
                _buildErrorBanner(context, state.error!),

              // ── Success banner ───────────────────────────────────
              if (state.successMessage != null)
                _buildSuccessBanner(context, state.successMessage!),

              // ── Scale cards ──────────────────────────────────────
              ...state.gradeScales.map(
                (scale) => Padding(
                  padding: const EdgeInsets.only(bottom: Spacings.md),
                  child: _GradeScaleCard(
                    scale: scale,
                    onEdit: () => _showEditDialog(context, scale),
                    onDelete: () => _confirmDelete(context, scale),
                    onApply: () => _applyScale(context, scale),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Summary ───────────────────────────────────────────────────────

  Widget _buildSummary(BuildContext context, GradeScaleState state) {
    final cs = context.colorScheme;
    final tt = context.textTheme;
    final isDark = context.isDarkMode;

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: Spacings.md,
            vertical: Spacings.sm,
          ),
          decoration: BoxDecoration(
            color: cs.primary.withValues(alpha: isDark ? 0.20 : 0.10),
            borderRadius: BorderRadius.circular(Spacings.mdRadius),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.straighten_rounded,
                  size: Spacings.mdIcon, color: cs.primary),
              const SizedBox(width: Spacings.sm),
              Text(
                '${state.scaleCount} scale${state.scaleCount != 1 ? 's' : ''}',
                style: tt.titleSmall?.copyWith(
                  fontWeight: AppTypography.wBold,
                  color: cs.primary,
                ),
              ),
            ],
          ),
        ),
        const Spacer(),
        if (state.defaultScale != null)
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: Spacings.md,
              vertical: Spacings.sm,
            ),
            decoration: BoxDecoration(
              color: AppColors.successOf(cs.brightness)
                  .withValues(alpha: isDark ? 0.15 : 0.08),
              borderRadius: BorderRadius.circular(Spacings.mdRadius),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.star_rounded,
                    size: Spacings.mdIcon,
                    color: AppColors.successOf(cs.brightness)),
                const SizedBox(width: Spacings.sm),
                Text(
                  'Default: ${state.defaultScale!.name}',
                  style: tt.bodySmall?.copyWith(
                    fontWeight: AppTypography.wSemiBold,
                    color: AppColors.successOf(cs.brightness),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  // ─── Create Dialog ─────────────────────────────────────────────────

  Future<void> _showCreateDialog(BuildContext context) async {
    final result = await AppDialog.showCustom<GradeScaleEntity>(
      context: context,
      builder: (ctx) => const _GradeScaleFormDialog(),
    );

    if (result != null) {
      ref.read(gradeScaleProvider.notifier).createGradeScale(
            result.copyWith(schoolId: widget.schoolId),
          );
    }
  }

  // ─── Edit Dialog ───────────────────────────────────────────────────

  Future<void> _showEditDialog(
      BuildContext context, GradeScaleEntity scale) async {
    final result = await AppDialog.showCustom<GradeScaleEntity>(
      context: context,
      builder: (ctx) => _GradeScaleFormDialog(scale: scale),
    );

    if (result != null) {
      ref.read(gradeScaleProvider.notifier).updateGradeScale(result);
    }
  }

  // ─── Delete Confirmation ───────────────────────────────────────────

  Future<void> _confirmDelete(
      BuildContext context, GradeScaleEntity scale) async {
    final confirmed = await AppDialog.showConfirm(
      context: context,
      title: 'Delete "${scale.name}"?',
      message:
          'This grade scale and all its entries will be permanently removed. This cannot be undone.',
      confirmText: 'Delete',
      isDestructive: true,
    );

    if (confirmed == true) {
      ref.read(gradeScaleProvider.notifier).deleteGradeScale(
            scale.id,
            deleteRemote: (id) async => Success(null),
          );
    }
  }

  // ─── Apply Scale ───────────────────────────────────────────────────

  void _applyScale(BuildContext context, GradeScaleEntity scale) {
    // Demonstrate applying the scale to a sample percentage
    ref.read(gradeScaleProvider.notifier).applyGradeScale(
          75.0, // sample percentage
          scale.id,
        );
  }

  // ─── Error Banner ──────────────────────────────────────────────────

  Widget _buildErrorBanner(BuildContext context, String error) {
    final cs = context.colorScheme;
    final tt = context.textTheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: Spacings.md),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(Spacings.md),
        decoration: BoxDecoration(
          color: AppColors.errorOf(cs.brightness)
              .withValues(alpha: context.isDarkMode ? 0.15 : 0.08),
          borderRadius: BorderRadius.circular(Spacings.smRadius),
        ),
        child: Row(
          children: [
            Icon(Icons.error_outline_rounded,
                color: AppColors.errorOf(cs.brightness)),
            const SizedBox(width: Spacings.sm),
            Expanded(
              child: Text(
                error,
                style: tt.bodySmall?.copyWith(
                  color: AppColors.errorOf(cs.brightness),
                ),
              ),
            ),
            AppButton(
              label: 'Retry',
              onPressed: () {
                ref
                    .read(gradeScaleProvider.notifier)
                    .loadGradeScales(widget.schoolId);
              },
              variant: AppButtonVariant.text,
              size: AppButtonSize.small,
            ),
          ],
        ),
      ),
    );
  }

  // ─── Success Banner ────────────────────────────────────────────────

  Widget _buildSuccessBanner(BuildContext context, String message) {
    final cs = context.colorScheme;
    final tt = context.textTheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: Spacings.md),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(Spacings.md),
        decoration: BoxDecoration(
          color: AppColors.successOf(cs.brightness)
              .withValues(alpha: context.isDarkMode ? 0.15 : 0.08),
          borderRadius: BorderRadius.circular(Spacings.smRadius),
        ),
        child: Row(
          children: [
            Icon(Icons.check_circle_rounded,
                color: AppColors.successOf(cs.brightness)),
            const SizedBox(width: Spacings.sm),
            Expanded(
              child: Text(
                message,
                style: tt.bodyMedium?.copyWith(
                  color: AppColors.successOf(cs.brightness),
                  fontWeight: AppTypography.wSemiBold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// GRADE SCALE CARD
// ═══════════════════════════════════════════════════════════════════════

/// Card displaying a single grade scale with its entries and actions.
class _GradeScaleCard extends StatelessWidget {
  const _GradeScaleCard({
    required this.scale,
    required this.onEdit,
    required this.onDelete,
    required this.onApply,
  });

  final GradeScaleEntity scale;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onApply;

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;
    final tt = context.textTheme;
    final isDark = context.isDarkMode;

    return AppCard(
      onTap: onEdit,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ───────────────────────────────────────────────
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(Spacings.sm),
                      decoration: BoxDecoration(
                        color: cs.primary
                            .withValues(alpha: isDark ? 0.20 : 0.12),
                        borderRadius:
                            BorderRadius.circular(Spacings.smRadius),
                      ),
                      child: Icon(
                        Icons.straighten_rounded,
                        size: Spacings.mdIcon,
                        color: cs.primary,
                      ),
                    ),
                    const SizedBox(width: Spacings.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            scale.name,
                            style: tt.titleSmall?.copyWith(
                              fontWeight: AppTypography.wSemiBold,
                              color: cs.onSurface,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: Spacings.xs),
                          Row(
                            children: [
                              Text(
                                scale.gradeType.label,
                                style: tt.bodySmall?.copyWith(
                                  color: cs.onSurfaceVariant,
                                ),
                              ),
                              const SizedBox(width: Spacings.sm),
                              Text(
                                '·',
                                style: tt.bodySmall?.copyWith(
                                  color: cs.onSurfaceVariant,
                                ),
                              ),
                              const SizedBox(width: Spacings.sm),
                              Text(
                                '${scale.scaleEntries.length} entries',
                                style: tt.bodySmall?.copyWith(
                                  color: cs.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // Default badge
              if (scale.isDefault)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: Spacings.sm,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.successOf(cs.brightness)
                        .withValues(alpha: isDark ? 0.20 : 0.10),
                    borderRadius:
                        BorderRadius.circular(Spacings.smRadius),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.star_rounded,
                          size: 12,
                          color: AppColors.successOf(cs.brightness)),
                      const SizedBox(width: 2),
                      Text(
                        'Default',
                        style: tt.labelSmall?.copyWith(
                          fontWeight: AppTypography.wSemiBold,
                          color: AppColors.successOf(cs.brightness),
                        ),
                      ),
                    ],
                  ),
                ),
              // Action buttons
              IconButton(
                icon: const Icon(Icons.play_arrow_rounded),
                tooltip: 'Apply Scale',
                onPressed: onApply,
                iconSize: Spacings.mdIcon,
                color: cs.primary,
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline_rounded),
                tooltip: 'Delete',
                onPressed: onDelete,
                iconSize: Spacings.mdIcon,
                color: AppColors.errorOf(cs.brightness),
              ),
            ],
          ),

          // ── Entry List ───────────────────────────────────────────
          if (scale.scaleEntries.isNotEmpty) ...[
            const SizedBox(height: Spacings.md),
            const Divider(height: 1),
            const SizedBox(height: Spacings.md),
            Wrap(
              spacing: Spacings.sm,
              runSpacing: Spacings.sm,
              children: scale.scaleEntries.map((entry) {
                final entryColor = entry.isPassing
                    ? AppColors.successOf(cs.brightness)
                    : AppColors.errorOf(cs.brightness);

                return Chip(
                  avatar: Text(
                    entry.grade,
                    style: tt.labelSmall?.copyWith(
                      fontWeight: AppTypography.wBold,
                      color: entryColor,
                    ),
                  ),
                  label: Text(
                    '${entry.minPercentage.toStringAsFixed(0)}–${entry.maxPercentage.toStringAsFixed(0)}%',
                    style: tt.bodySmall?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                  side: BorderSide(
                    color: cs.outlineVariant.withValues(alpha: 0.5),
                  ),
                  backgroundColor: entryColor.withValues(
                      alpha: isDark ? 0.08 : 0.04),
                  visualDensity: VisualDensity.compact,
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// GRADE SCALE FORM DIALOG
// ═══════════════════════════════════════════════════════════════════════

/// Dialog for creating or editing a grade scale.
class _GradeScaleFormDialog extends StatefulWidget {
  const _GradeScaleFormDialog({this.scale});

  final GradeScaleEntity? scale;

  @override
  State<_GradeScaleFormDialog> createState() => _GradeScaleFormDialogState();
}

class _GradeScaleFormDialogState extends State<_GradeScaleFormDialog> {
  late TextEditingController _nameController;
  GradeType _selectedType = GradeType.letter;
  bool _isDefault = false;
  final List<_EntryDraft> _entries = [];

  @override
  void initState() {
    super.initState();
    _nameController =
        TextEditingController(text: widget.scale?.name ?? '');
    _selectedType = widget.scale?.gradeType ?? GradeType.letter;
    _isDefault = widget.scale?.isDefault ?? false;

    if (widget.scale != null) {
      _entries.addAll(
        widget.scale!.scaleEntries.map(
          (e) => _EntryDraft(
            grade: e.grade,
            minPercentage: e.minPercentage,
            maxPercentage: e.maxPercentage,
            isPassing: e.isPassing,
            gpaValue: e.gpaValue,
          ),
        ),
      );
    } else {
      // Default entries for a new letter-grade scale
      _entries.addAll([
        _EntryDraft(grade: 'A', minPercentage: 70, maxPercentage: 100, isPassing: true),
        _EntryDraft(grade: 'B', minPercentage: 60, maxPercentage: 69, isPassing: true),
        _EntryDraft(grade: 'C', minPercentage: 50, maxPercentage: 59, isPassing: true),
        _EntryDraft(grade: 'D', minPercentage: 40, maxPercentage: 49, isPassing: true),
        _EntryDraft(grade: 'F', minPercentage: 0, maxPercentage: 39, isPassing: false),
      ]);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;
    final tt = context.textTheme;
    final isEditing = widget.scale != null;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title
        Text(
          isEditing ? 'Edit Grade Scale' : 'New Grade Scale',
          style: tt.titleLarge?.copyWith(
            fontWeight: AppTypography.wSemiBold,
            color: cs.onSurface,
          ),
        ),
        const SizedBox(height: Spacings.xl),

        // Name field
        TextField(
          controller: _nameController,
          decoration: InputDecoration(
            labelText: 'Scale Name',
            hintText: 'e.g., WAEC Grading Scale',
            prefixIcon: const Icon(Icons.label_rounded),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(Spacings.smRadius),
            ),
          ),
        ),
        const SizedBox(height: Spacings.md),

        // Type dropdown
        DropdownButtonFormField<GradeType>(
          value: _selectedType,
          decoration: InputDecoration(
            labelText: 'Grade Type',
            prefixIcon: const Icon(Icons.category_rounded),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(Spacings.smRadius),
            ),
          ),
          items: GradeType.values
              .map((t) => DropdownMenuItem(
                    value: t,
                    child: Text(t.label),
                  ))
              .toList(),
          onChanged: (v) {
            if (v != null) setState(() => _selectedType = v);
          },
        ),
        const SizedBox(height: Spacings.md),

        // Is Default
        SwitchListTile(
          value: _isDefault,
          onChanged: (v) => setState(() => _isDefault = v),
          title: Text(
            'Set as default scale',
            style: tt.bodyMedium,
          ),
          secondary: const Icon(Icons.star_rounded),
          contentPadding: EdgeInsets.zero,
          dense: true,
        ),
        const SizedBox(height: Spacings.lg),

        // Entries header
        Row(
          children: [
            Text(
              'Entries',
              style: tt.titleSmall?.copyWith(
                fontWeight: AppTypography.wSemiBold,
                color: cs.onSurface,
              ),
            ),
            const Spacer(),
            IconButton(
              icon: const Icon(Icons.add_circle_outline_rounded),
              tooltip: 'Add Entry',
              onPressed: () {
                setState(() {
                  _entries.add(_EntryDraft(
                    grade: '',
                    minPercentage: 0,
                    maxPercentage: 100,
                    isPassing: true,
                  ));
                });
              },
              iconSize: Spacings.mdIcon,
              color: cs.primary,
            ),
          ],
        ),
        const SizedBox(height: Spacings.sm),

        // Entries list
        ..._entries.asMap().entries.map((mapEntry) {
          final i = mapEntry.key;
          final entry = mapEntry.value;
          return _buildEntryRow(context, i, entry);
        }),

        const SizedBox(height: Spacings.xl),

        // Actions
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            AppButton(
              label: 'Cancel',
              onPressed: () => Navigator.of(context).pop(),
              variant: AppButtonVariant.text,
            ),
            const SizedBox(width: Spacings.sm),
            AppButton(
              label: isEditing ? 'Save Changes' : 'Create Scale',
              onPressed: _save,
              variant: AppButtonVariant.elevated,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildEntryRow(BuildContext context, int index, _EntryDraft entry) {
    final cs = context.colorScheme;
    final tt = context.textTheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: Spacings.sm),
      child: Row(
        children: [
          // Grade
          SizedBox(
            width: 60,
            child: TextField(
              controller: TextEditingController(text: entry.grade),
              decoration: const InputDecoration(
                labelText: 'Grade',
                isDense: true,
              ),
              onChanged: (v) => entry.grade = v,
            ),
          ),
          const SizedBox(width: Spacings.sm),
          // Min
          SizedBox(
            width: 70,
            child: TextField(
              controller: TextEditingController(
                  text: entry.minPercentage.toStringAsFixed(0)),
              decoration: const InputDecoration(
                labelText: 'Min %',
                isDense: true,
              ),
              keyboardType: TextInputType.number,
              onChanged: (v) =>
                  entry.minPercentage = double.tryParse(v) ?? 0,
            ),
          ),
          const SizedBox(width: Spacings.sm),
          // Max
          SizedBox(
            width: 70,
            child: TextField(
              controller: TextEditingController(
                  text: entry.maxPercentage.toStringAsFixed(0)),
              decoration: const InputDecoration(
                labelText: 'Max %',
                isDense: true,
              ),
              keyboardType: TextInputType.number,
              onChanged: (v) =>
                  entry.maxPercentage = double.tryParse(v) ?? 0,
            ),
          ),
          const SizedBox(width: Spacings.sm),
          // Passing toggle
          SizedBox(
            width: 70,
            child: GestureDetector(
              onTap: () => setState(() => entry.isPassing = !entry.isPassing),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: Spacings.sm,
                  vertical: Spacings.xs,
                ),
                decoration: BoxDecoration(
                  color: (entry.isPassing
                          ? AppColors.successOf(cs.brightness)
                          : AppColors.errorOf(cs.brightness))
                      .withValues(alpha: context.isDarkMode ? 0.15 : 0.08),
                  borderRadius:
                      BorderRadius.circular(Spacings.smRadius),
                ),
                child: Text(
                  entry.isPassing ? 'Pass' : 'Fail',
                  style: tt.labelSmall?.copyWith(
                    fontWeight: AppTypography.wSemiBold,
                    color: entry.isPassing
                        ? AppColors.successOf(cs.brightness)
                        : AppColors.errorOf(cs.brightness),
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
          const SizedBox(width: Spacings.sm),
          // Delete entry
          IconButton(
            icon: const Icon(Icons.close_rounded, size: 18),
            onPressed: () {
              setState(() => _entries.removeAt(index));
            },
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          ),
        ],
      ),
    );
  }

  void _save() {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a scale name')),
      );
      return;
    }

    final now = DateTime.now();
    final scale = GradeScaleEntity(
      id: widget.scale?.id ?? '',
      schoolId: widget.scale?.schoolId ?? '',
      name: _nameController.text.trim(),
      gradeType: _selectedType,
      isDefault: _isDefault,
      scaleEntries: _entries
          .asMap()
          .entries
          .map((e) => GradeScaleEntryEntity(
                id: '${e.key}',
                minPercentage: e.value.minPercentage,
                maxPercentage: e.value.maxPercentage,
                grade: e.value.grade,
                gpaValue: e.value.gpaValue,
                isPassing: e.value.isPassing,
                sortOrder: e.key,
              ))
          .toList(),
      createdAt: widget.scale?.createdAt ?? now,
      updatedAt: now,
    );

    Navigator.of(context).pop(scale);
  }
}

// ═══════════════════════════════════════════════════════════════════════
// ENTRY DRAFT HELPER
// ═══════════════════════════════════════════════════════════════════════

/// Mutable draft for grade scale entries during editing.
class _EntryDraft {
  _EntryDraft({
    required this.grade,
    required this.minPercentage,
    required this.maxPercentage,
    required this.isPassing,
    this.gpaValue,
  });

  String grade;
  double minPercentage;
  double maxPercentage;
  bool isPassing;
  double? gpaValue;
}
