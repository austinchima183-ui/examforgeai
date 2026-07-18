import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/themes/spacings.dart';
import '../../../../core/themes/app_typography.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../../shared/widgets/app_loading.dart';
import '../../../../shared/widgets/app_app_bar.dart';
import '../../../../shared/widgets/app_empty_state.dart';
import '../../domain/entities/teacher_workspace_entities.dart';
import '../../domain/entities/workspace_expansion_entities.dart';
import '../../domain/usecases/generate_rubric_usecase.dart';
import '../../domain/usecases/create_rubric_usecase.dart';
import '../providers/rubric_provider.dart';

// ═══════════════════════════════════════════════════════════════════════
// RUBRIC GENERATOR PAGE
// ═══════════════════════════════════════════════════════════════════════

/// AI Rubric Generator page where teachers fill in parameters and AI
/// generates a complete rubric with criteria and performance levels.
///
/// Has two states: input form (no rubric generated yet) and generated result
/// (editable rubric with criteria × levels grid).
class RubricGeneratorPage extends ConsumerStatefulWidget {
  const RubricGeneratorPage({super.key});

  @override
  ConsumerState<RubricGeneratorPage> createState() =>
      _RubricGeneratorPageState();
}

class _RubricGeneratorPageState extends ConsumerState<RubricGeneratorPage> {
  // ─── Form Controllers ────────────────────────────────────────────────

  final _formKey = GlobalKey<FormState>();
  final _topicCtrl = TextEditingController();
  final _totalPointsCtrl = TextEditingController(text: '100');
  final _customInstructionsCtrl = TextEditingController();

  String? _selectedSubject;
  String? _selectedClass;
  double _criteriaCount = 4;
  bool _useAsTemplate = false;

  // ─── Edit State ──────────────────────────────────────────────────────

  bool _isEditing = false;
  final _rubricTitleCtrl = TextEditingController();
  final List<TextEditingController> _criterionNameControllers = [];
  final List<TextEditingController> _criterionWeightControllers = [];
  final Map<String, Map<RubricCriterionLevel, TextEditingController>>
      _cellControllers = {};

  static const List<String> _subjects = [
    'Mathematics',
    'English',
    'Physics',
    'Chemistry',
    'Biology',
    'History',
    'Geography',
    'Economics',
    'Literature',
    'Computer Science',
  ];

  static const List<String> _classes = [
    'JSS1',
    'JSS2',
    'JSS3',
    'SS1',
    'SS2',
    'SS3',
    'Primary 4',
    'Primary 5',
    'Primary 6',
  ];

  @override
  void dispose() {
    _topicCtrl.dispose();
    _totalPointsCtrl.dispose();
    _customInstructionsCtrl.dispose();
    _rubricTitleCtrl.dispose();
    for (final c in _criterionNameControllers) {
      c.dispose();
    }
    for (final c in _criterionWeightControllers) {
      c.dispose();
    }
    for (final row in _cellControllers.values) {
      for (final ctrl in row.values) {
        ctrl.dispose();
      }
    }
    super.dispose();
  }

  // ─── Helpers ─────────────────────────────────────────────────────────

  void _listenForMessages() {
    final state = ref.read(rubricProvider);
    if (state.successMessage != null) {
      _showSnackBar(state.successMessage!, isError: false);
      ref.read(rubricProvider.notifier).clearSuccessMessage();
    }
    if (state.error != null) {
      _showSnackBar(state.error!, isError: true);
      ref.read(rubricProvider.notifier).clearError();
    }
  }

  void _showSnackBar(String message, {required bool isError}) {
    if (!mounted) return;
    final cs = context.colorScheme;
    context.scaffoldMessenger.showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? cs.error : cs.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Spacings.smRadius),
        ),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _initEditControllers(RubricEntity rubric) {
    _rubricTitleCtrl.text = rubric.title;

    // Clear old controllers
    for (final c in _criterionNameControllers) {
      c.dispose();
    }
    _criterionNameControllers.clear();
    for (final c in _criterionWeightControllers) {
      c.dispose();
    }
    _criterionWeightControllers.clear();
    for (final row in _cellControllers.values) {
      for (final ctrl in row.values) {
        ctrl.dispose();
      }
    }
    _cellControllers.clear();

    // Create new controllers for each criterion
    for (int i = 0; i < rubric.criteria.length; i++) {
      final criterion = rubric.criteria[i];
      _criterionNameControllers
          .add(TextEditingController(text: criterion.criterion));
      _criterionWeightControllers
          .add(TextEditingController(text: criterion.weight.toString()));

      final levelControllers = <RubricCriterionLevel, TextEditingController>{};
      for (final level in criterion.levels) {
        levelControllers[level.level] =
            TextEditingController(text: level.description);
      }
      // Ensure all levels have controllers even if missing
      for (final levelValue in RubricCriterionLevel.values) {
        levelControllers.putIfAbsent(
          levelValue,
          () => TextEditingController(text: ''),
        );
      }
      _cellControllers[criterion.criterion] = levelControllers;
    }
  }

  Future<void> _handleGenerate() async {
    if (!_formKey.currentState!.validate()) return;

    await ref.read(rubricProvider.notifier).generateRubric(
      GenerateRubricParams(
        subjectId: _selectedSubject,
        topic: _topicCtrl.text.trim(),
        criteriaCount: _criteriaCount.round(),
        totalPoints: double.tryParse(_totalPointsCtrl.text) ?? 100,
      ),
    );

    _listenForMessages();

    final rubric = ref.read(rubricProvider).currentRubric;
    if (rubric != null) {
      _initEditControllers(rubric);
    }
  }

  void _handleSaveDraft() {
    final rubric = ref.read(rubricProvider).currentRubric;
    if (rubric == null) return;
    _showSnackBar('Rubric saved as draft', isError: false);
  }

  void _handleSaveAndPublish() {
    final rubric = ref.read(rubricProvider).currentRubric;
    if (rubric == null) return;
    _showSnackBar('Rubric published successfully', isError: false);
  }

  void _handleExport(String format) {
    _showSnackBar('Exporting rubric as $format...', isError: false);
  }

  void _handleShare() {
    _showSnackBar('Share dialog opened', isError: false);
  }

  void _handleAddCriterion() {
    final rubric = ref.read(rubricProvider).currentRubric;
    if (rubric == null) return;

    final newCriterion = RubricCriterionEntity(
      criterion: 'New Criterion',
      weight: 1.0,
      levels: RubricCriterionLevel.values
          .map((level) => RubricLevelEntity(
                level: level,
                description: '',
                score: 0,
              ))
          .toList(),
    );

    final updatedRubric = rubric.copyWith(
      criteria: [...rubric.criteria, newCriterion],
    );
    ref.read(rubricProvider.notifier).setCurrentRubric(updatedRubric);
    _initEditControllers(updatedRubric);
    setState(() {});
  }

  void _handleRemoveCriterion(int index) {
    final rubric = ref.read(rubricProvider).currentRubric;
    if (rubric == null || rubric.criteria.length <= 1) return;

    final updatedCriteria = List<RubricCriterionEntity>.from(rubric.criteria)
      ..removeAt(index);
    final updatedRubric = rubric.copyWith(criteria: updatedCriteria);
    ref.read(rubricProvider.notifier).setCurrentRubric(updatedRubric);
    _initEditControllers(updatedRubric);
    setState(() {});
  }

  void _handleReset() {
    ref.read(rubricProvider.notifier).setCurrentRubric(null);
    _rubricTitleCtrl.clear();
    for (final c in _criterionNameControllers) {
      c.dispose();
    }
    _criterionNameControllers.clear();
    for (final c in _criterionWeightControllers) {
      c.dispose();
    }
    _criterionWeightControllers.clear();
    for (final row in _cellControllers.values) {
      for (final ctrl in row.values) {
        ctrl.dispose();
      }
    }
    _cellControllers.clear();
    setState(() => _isEditing = false);
  }

  void _handleCellTap(String criterionName, RubricCriterionLevel level) {
    setState(() => _isEditing = true);
  }

  // ─── Build ───────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(rubricProvider);
    final rubric = state.currentRubric;

    return Scaffold(
      appBar: AppAppBar(
        title: rubric != null ? 'Generated Rubric' : 'AI Rubric Generator',
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
        actions: [
          if (rubric != null)
            AppIconButton(
              icon: Icons.restart_alt_rounded,
              onPressed: _handleReset,
              tooltip: 'Start Over',
              variant: AppIconButtonVariant.standard,
            ),
        ],
      ),
      body: state.isGenerating
          ? _buildGeneratingState()
          : rubric != null
              ? _buildGeneratedResult(rubric)
              : _buildInputForm(),
    );
  }

  // ─── Input Form ──────────────────────────────────────────────────────

  Widget _buildInputForm() {
    final cs = context.colorScheme;

    return SingleChildScrollView(
      padding: Spacings.paddingScreen,
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Text(
              'Create a Rubric with AI',
              style: context.textTheme.headlineSmall?.copyWith(
                fontWeight: AppTypography.wBold,
                color: cs.onSurface,
              ),
            ),
            const SizedBox(height: Spacings.sm),
            Text(
              'Fill in the details below and let AI generate a comprehensive rubric with criteria and performance levels.',
              style: context.textTheme.bodyMedium?.copyWith(
                color: cs.onSurfaceVariant,
              ),
            ),
            Spacings.sectionGap,

            // Subject dropdown
            _buildDropdownField(
              label: 'Subject',
              hint: 'Select a subject',
              value: _selectedSubject,
              items: _subjects,
              prefixIcon: Icons.book_outlined,
              isRequired: true,
              onChanged: (v) => setState(() => _selectedSubject = v),
            ),
            Spacings.itemGap,

            // Class dropdown
            _buildDropdownField(
              label: 'Class',
              hint: 'Select a class',
              value: _selectedClass,
              items: _classes,
              prefixIcon: Icons.school_outlined,
              onChanged: (v) => setState(() => _selectedClass = v),
            ),
            Spacings.itemGap,

            // Topic
            AppTextField(
              label: 'Topic',
              hint: 'e.g. Essay Writing, Lab Report, Group Presentation',
              controller: _topicCtrl,
              prefixIcon: Icons.topic_outlined,
              isRequired: true,
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Topic is required' : null,
            ),
            Spacings.itemGap,

            // Number of Criteria (Slider)
            _buildSliderField(
              label: 'Number of Criteria',
              value: _criteriaCount,
              min: 2,
              max: 8,
              divisions: 6,
              valueLabel: _criteriaCount.round().toString(),
            ),
            Spacings.itemGap,

            // Total Points
            AppTextField(
              label: 'Total Points',
              hint: 'e.g. 100',
              controller: _totalPointsCtrl,
              prefixIcon: Icons.star_outlined,
              keyboardType: TextInputType.number,
            ),
            Spacings.itemGap,

            // Custom Instructions
            AppTextField(
              label: 'Custom Instructions',
              hint: 'Any specific instructions for the AI rubric generator...',
              controller: _customInstructionsCtrl,
              prefixIcon: Icons.edit_note_rounded,
              maxLines: 4,
              minLines: 2,
            ),
            Spacings.sectionGap,

            // Generate Button
            AppButton(
              label: 'Generate Rubric',
              onPressed: _handleGenerate,
              variant: AppButtonVariant.elevated,
              icon: Icons.auto_awesome,
              isLoading: ref.watch(rubricProvider).isGenerating,
              fullWidth: true,
              size: AppButtonSize.large,
            ),
            const SizedBox(height: Spacings.xxl),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdownField({
    required String label,
    required String hint,
    required String? value,
    required List<String> items,
    required IconData prefixIcon,
    bool isRequired = false,
    required ValueChanged<String?> onChanged,
  }) {
    final cs = context.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(prefixIcon, size: Spacings.smIcon, color: cs.onSurfaceVariant),
            const SizedBox(width: Spacings.xs),
            Text(
              label + (isRequired ? ' *' : ''),
              style: context.textTheme.labelLarge?.copyWith(
                color: cs.onSurfaceVariant,
              ),
            ),
          ],
        ),
        const SizedBox(height: Spacings.xs),
        DropdownButtonFormField<String>(
          value: value,
          hint: Text(hint),
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(Spacings.smRadius),
            ),
            contentPadding: Spacings.paddingInput,
          ),
          items: items
              .map((item) => DropdownMenuItem(
                    value: item,
                    child: Text(item),
                  ))
              .toList(),
          onChanged: onChanged,
          validator: isRequired
              ? (v) => v == null ? '$label is required' : null
              : null,
        ),
      ],
    );
  }

  Widget _buildSliderField({
    required String label,
    required double value,
    required double min,
    required double max,
    required int divisions,
    required String valueLabel,
  }) {
    final cs = context.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.tune_rounded, size: Spacings.smIcon, color: cs.onSurfaceVariant),
            const SizedBox(width: Spacings.xs),
            Text(
              label,
              style: context.textTheme.labelLarge?.copyWith(
                color: cs.onSurfaceVariant,
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: Spacings.sm,
                vertical: 2,
              ),
              decoration: BoxDecoration(
                color: cs.primaryContainer,
                borderRadius: BorderRadius.circular(Spacings.fullRadius),
              ),
              child: Text(
                valueLabel,
                style: context.textTheme.labelMedium?.copyWith(
                  color: cs.onPrimaryContainer,
                  fontWeight: AppTypography.wSemiBold,
                ),
              ),
            ),
          ],
        ),
        Slider(
          value: value,
          min: min,
          max: max,
          divisions: divisions,
          label: valueLabel,
          onChanged: (v) => setState(() => _criteriaCount = v),
        ),
      ],
    );
  }

  // ─── Generating State ────────────────────────────────────────────────

  Widget _buildGeneratingState() {
    final cs = context.colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(Spacings.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const AppLoadingSpinner(size: AppLoadingSpinnerSize.large),
            const SizedBox(height: Spacings.xl),
            Text(
              'Generating Your Rubric...',
              style: context.textTheme.titleMedium?.copyWith(
                fontWeight: AppTypography.wSemiBold,
                color: cs.onSurface,
              ),
            ),
            const SizedBox(height: Spacings.sm),
            Text(
              'AI is crafting a comprehensive rubric based on your parameters. This may take a moment.',
              style: context.textTheme.bodyMedium?.copyWith(
                color: cs.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // ─── Generated Result ────────────────────────────────────────────────

  Widget _buildGeneratedResult(RubricEntity rubric) {
    return SingleChildScrollView(
      padding: Spacings.paddingScreen,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // AI badge
          if (rubric.isAiGenerated) _buildAiBadge(),
          const SizedBox(height: Spacings.md),

          // Preview card
          _buildPreviewCard(rubric),
          Spacings.itemGap,

          // Rubric grid table
          _buildRubricGrid(rubric),
          Spacings.itemGap,

          // Add/Remove criteria buttons
          _buildCriteriaActions(),
          Spacings.itemGap,

          // Use as Template toggle
          _buildTemplateToggle(),
          Spacings.sectionGap,

          // Action buttons
          _buildActionButtons(),
          const SizedBox(height: Spacings.xxl),
        ],
      ),
    );
  }

  Widget _buildAiBadge() {
    final cs = context.colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Spacings.md,
        vertical: Spacings.sm,
      ),
      decoration: BoxDecoration(
        color: cs.tertiaryContainer,
        borderRadius: BorderRadius.circular(Spacings.fullRadius),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.auto_awesome, size: Spacings.smIcon, color: cs.onTertiaryContainer),
          const SizedBox(width: Spacings.xs),
          Text(
            'AI Generated',
            style: context.textTheme.labelSmall?.copyWith(
              color: cs.onTertiaryContainer,
              fontWeight: AppTypography.wSemiBold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewCard(RubricEntity rubric) {
    final cs = context.colorScheme;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title row
          Row(
            children: [
              Icon(Icons.grid_on_rounded, size: Spacings.mdIcon, color: cs.primary),
              const SizedBox(width: Spacings.sm),
              Expanded(
                child: Text(
                  rubric.title,
                  style: context.textTheme.titleMedium?.copyWith(
                    fontWeight: AppTypography.wSemiBold,
                    color: cs.onSurface,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: Spacings.md),

          // Stats row
          Row(
            children: [
              _buildStatChip(
                icon: Icons.star_outline_rounded,
                label: '${rubric.totalPoints.toInt()} pts',
                color: cs.primary,
              ),
              const SizedBox(width: Spacings.sm),
              _buildStatChip(
                icon: Icons.checklist_rounded,
                label: '${rubric.criteria.length} criteria',
                color: cs.tertiary,
              ),
              if (rubric.topic != null) ...[
                const SizedBox(width: Spacings.sm),
                _buildStatChip(
                  icon: Icons.topic_outlined,
                  label: rubric.topic!,
                  color: cs.secondary,
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    final isDark = context.isDarkMode;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Spacings.sm,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.20 : 0.10),
        borderRadius: BorderRadius.circular(Spacings.fullRadius),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 2),
          Text(
            label,
            style: context.textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: AppTypography.wMedium,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRubricGrid(RubricEntity rubric) {
    final cs = context.colorScheme;
    final levels = RubricCriterionLevel.values;

    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Padding(
            padding: const EdgeInsets.all(Spacings.md),
            child: Row(
              children: [
                Text(
                  'Rubric Criteria & Levels',
                  style: context.textTheme.titleSmall?.copyWith(
                    fontWeight: AppTypography.wSemiBold,
                    color: cs.onSurface,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Column headers
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: _buildGridTable(rubric, levels),
          ),
        ],
      ),
    );
  }

  Widget _buildGridTable(
    RubricEntity rubric,
    List<RubricCriterionLevel> levels,
  ) {
    final cs = context.colorScheme;
    const colWidth = 140.0;
    const criterionWidth = 120.0;

    return DataTable(
      headingRowHeight: 48,
      dataRowHeight: null,
      columnSpacing: Spacings.sm,
      horizontalMargin: Spacings.md,
      columns: [
        const DataColumn(
          label: SizedBox(
            width: criterionWidth,
            child: Text('Criterion'),
          ),
        ),
        const DataColumn(label: Text('Weight')),
        ...levels.map((level) => DataColumn(
              label: SizedBox(
                width: colWidth,
                child: Text(
                  level.label,
                  style: context.textTheme.labelSmall?.copyWith(
                    fontWeight: AppTypography.wSemiBold,
                  ),
                ),
              ),
            )),
        const DataColumn(label: Text('')),
      ],
      rows: rubric.criteria.asMap().entries.map((entry) {
        final index = entry.key;
        final criterion = entry.value;
        final levelMap = <RubricCriterionLevel, String>{};
        for (final l in criterion.levels) {
          levelMap[l.level] = l.description;
        }

        return DataRow(
          cells: [
            // Criterion name
            DataCell(
              SizedBox(
                width: criterionWidth,
                child: _isEditing
                    ? TextFormField(
                        controller: _criterionNameControllers.isNotEmpty &&
                                index < _criterionNameControllers.length
                            ? _criterionNameControllers[index]
                            : null,
                        style: context.textTheme.bodySmall,
                        decoration: const InputDecoration(
                          isDense: true,
                          border: InputBorder.none,
                        ),
                      )
                    : Text(
                        criterion.criterion,
                        style: context.textTheme.bodySmall?.copyWith(
                          fontWeight: AppTypography.wMedium,
                        ),
                      ),
              ),
              onTap: () => _handleCellTap(
                criterion.criterion,
                RubricCriterionLevel.beginning,
              ),
            ),
            // Weight
            DataCell(
              _isEditing &&
                      _criterionWeightControllers.isNotEmpty &&
                      index < _criterionWeightControllers.length
                  ? SizedBox(
                      width: 50,
                      child: TextFormField(
                        controller: _criterionWeightControllers[index],
                        style: context.textTheme.bodySmall,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          isDense: true,
                          border: InputBorder.none,
                        ),
                      ),
                    )
                  : Text(
                      '${criterion.weight}',
                      style: context.textTheme.bodySmall,
                    ),
            ),
            // Level cells
            ...levels.map((level) {
              final description = levelMap[level] ?? '';
              final controller =
                  _cellControllers[criterion.criterion]?[level];

              return DataCell(
                SizedBox(
                  width: colWidth,
                  child: _isEditing && controller != null
                      ? TextFormField(
                          controller: controller,
                          style: context.textTheme.bodySmall?.copyWith(
                            fontSize: 11,
                          ),
                          maxLines: 3,
                          minLines: 1,
                          decoration: const InputDecoration(
                            isDense: true,
                            border: InputBorder.none,
                          ),
                        )
                      : Text(
                          description,
                          style: context.textTheme.bodySmall?.copyWith(
                            fontSize: 11,
                          ),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                ),
                onTap: () =>
                    _handleCellTap(criterion.criterion, level),
              );
            }),
            // Delete button
            DataCell(
              IconButton(
                icon: Icon(
                  Icons.delete_outline_rounded,
                  size: Spacings.smIcon,
                  color: cs.error,
                ),
                onPressed: rubric.criteria.length > 1
                    ? () => _handleRemoveCriterion(index)
                    : null,
                tooltip: 'Remove Criterion',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildCriteriaActions() {
    return Row(
      children: [
        AppButton(
          label: 'Add Criterion',
          onPressed: _handleAddCriterion,
          variant: AppButtonVariant.tonal,
          icon: Icons.add_rounded,
          size: AppButtonSize.small,
        ),
        const SizedBox(width: Spacings.sm),
        AppButton(
          label: _isEditing ? 'Done Editing' : 'Edit Cells',
          onPressed: () => setState(() => _isEditing = !_isEditing),
          variant: AppButtonVariant.outlined,
          icon: _isEditing ? Icons.check_rounded : Icons.edit_outlined,
          size: AppButtonSize.small,
        ),
      ],
    );
  }

  Widget _buildTemplateToggle() {
    final cs = context.colorScheme;

    return AppCard(
      child: SwitchListTile(
        title: Text(
          'Use as Template',
          style: context.textTheme.titleSmall?.copyWith(
            fontWeight: AppTypography.wSemiBold,
            color: cs.onSurface,
          ),
        ),
        subtitle: Text(
          'Allow this rubric to be used as a template for future rubrics',
          style: context.textTheme.bodySmall?.copyWith(
            color: cs.onSurfaceVariant,
          ),
        ),
        value: _useAsTemplate,
        onChanged: (v) => setState(() => _useAsTemplate = v),
        contentPadding: EdgeInsets.zero,
        secondary: Icon(
          Icons.content_copy_rounded,
          color: cs.primary,
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Save buttons row
        Row(
          children: [
            Expanded(
              child: AppButton(
                label: 'Save as Draft',
                onPressed: _handleSaveDraft,
                variant: AppButtonVariant.outlined,
                icon: Icons.save_outlined,
                size: AppButtonSize.medium,
              ),
            ),
            const SizedBox(width: Spacings.sm),
            Expanded(
              child: AppButton(
                label: 'Save & Publish',
                onPressed: _handleSaveAndPublish,
                variant: AppButtonVariant.elevated,
                icon: Icons.public_rounded,
                size: AppButtonSize.medium,
              ),
            ),
          ],
        ),
        const SizedBox(height: Spacings.md),

        // Export dropdown
        AppButton(
          label: 'Export',
          onPressed: () => _showExportSheet(),
          variant: AppButtonVariant.tonal,
          icon: Icons.file_download_outlined,
          size: AppButtonSize.medium,
          fullWidth: true,
        ),
        const SizedBox(height: Spacings.sm),

        // Share button
        AppButton(
          label: 'Share with Colleagues',
          onPressed: _handleShare,
          variant: AppButtonVariant.text,
          icon: Icons.share_rounded,
          size: AppButtonSize.medium,
          fullWidth: true,
        ),
      ],
    );
  }

  void _showExportSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(Spacings.lgRadius),
        ),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(Spacings.lg),
              child: Row(
                children: [
                  Text(
                    'Export Rubric',
                    style: context.textTheme.titleMedium?.copyWith(
                      fontWeight: AppTypography.wSemiBold,
                    ),
                  ),
                  const Spacer(),
                  AppIconButton(
                    icon: Icons.close,
                    onPressed: () => Navigator.pop(ctx),
                    variant: AppIconButtonVariant.standard,
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.picture_as_pdf_rounded),
              title: const Text('Export as PDF'),
              onTap: () {
                Navigator.pop(ctx);
                _handleExport('PDF');
              },
            ),
            ListTile(
              leading: const Icon(Icons.description_outlined),
              title: const Text('Export as DOCX'),
              onTap: () {
                Navigator.pop(ctx);
                _handleExport('DOCX');
              },
            ),
            const SizedBox(height: Spacings.lg),
          ],
        ),
      ),
    );
  }
}
