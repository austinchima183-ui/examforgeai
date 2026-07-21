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
import '../../domain/entities/teacher_workspace_entities.dart';
import '../../domain/entities/workspace_expansion_entities.dart';
import '../../domain/usecases/generate_practical_assessment_usecase.dart';
import '../../domain/usecases/create_practical_assessment_usecase.dart';
import '../providers/practical_assessment_provider.dart';
import '../providers/rubric_provider.dart';

// ═══════════════════════════════════════════════════════════════════════
// PRACTICAL ASSESSMENT GENERATOR PAGE
// ═══════════════════════════════════════════════════════════════════════

/// AI Practical Assessment Generator page where teachers fill in parameters
/// and AI generates a complete practical assessment with objectives,
/// materials, procedure, safety, and assessment criteria.
///
/// Has two states: input form (no assessment generated yet) and generated
/// result (editable sections with expandable cards).
class PracticalAssessmentGeneratorPage extends ConsumerStatefulWidget {
  const PracticalAssessmentGeneratorPage({super.key});

  @override
  ConsumerState<PracticalAssessmentGeneratorPage> createState() =>
      _PracticalAssessmentGeneratorPageState();
}

class _PracticalAssessmentGeneratorPageState
    extends ConsumerState<PracticalAssessmentGeneratorPage> {
  // ─── Form Controllers ────────────────────────────────────────────────

  final _formKey = GlobalKey<FormState>();
  final _topicCtrl = TextEditingController();
  final _durationCtrl = TextEditingController(text: '60');
  final _customInstructionsCtrl = TextEditingController();

  String? _selectedSubject;
  String? _selectedClass;
  StudentLevel _difficulty = StudentLevel.intermediate;
  String? _selectedRubricId;

  // ─── Edit State ──────────────────────────────────────────────────────

  bool _isEditing = false;
  int? _expandedSectionIndex;
  final List<TextEditingController> _objectiveControllers = [];
  final List<TextEditingController> _materialControllers = [];
  final List<TextEditingController> _stepControllers = [];
  final List<TextEditingController> _safetyControllers = [];
  final _expectedResultsCtrl = TextEditingController();

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
    _durationCtrl.dispose();
    _customInstructionsCtrl.dispose();
    _expectedResultsCtrl.dispose();
    for (final c in _objectiveControllers) {
      c.dispose();
    }
    for (final c in _materialControllers) {
      c.dispose();
    }
    for (final c in _stepControllers) {
      c.dispose();
    }
    for (final c in _safetyControllers) {
      c.dispose();
    }
    super.dispose();
  }

  // ─── Helpers ─────────────────────────────────────────────────────────

  void _listenForMessages() {
    final state = ref.read(practicalAssessmentProvider);
    if (state.successMessage != null) {
      _showSnackBar(state.successMessage!, isError: false);
      ref.read(practicalAssessmentProvider.notifier).clearSuccessMessage();
    }
    if (state.error != null) {
      _showSnackBar(state.error!, isError: true);
      ref.read(practicalAssessmentProvider.notifier).clearError();
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

  void _initListControllers(
    List<String> items,
    List<TextEditingController> controllers,
  ) {
    for (final c in controllers) {
      c.dispose();
    }
    controllers.clear();
    for (final item in items) {
      controllers.add(TextEditingController(text: item));
    }
  }

  void _initEditControllers(PracticalAssessmentEntity assessment) {
    _initListControllers(assessment.objectives, _objectiveControllers);
    _initListControllers(assessment.materialsNeeded, _materialControllers);
    _initListControllers(assessment.procedureSteps, _stepControllers);
    _initListControllers(assessment.safetyPrecautions, _safetyControllers);
    _expectedResultsCtrl.text = assessment.expectedResults ?? '';
  }

  Future<void> _handleGenerate() async {
    if (!_formKey.currentState!.validate()) return;

    await ref.read(practicalAssessmentProvider.notifier).generatePracticalAssessment(
      GeneratePracticalAssessmentParams(
        subjectId: _selectedSubject,
        topic: _topicCtrl.text.trim(),
        difficulty: _difficulty.value,
        estimatedDuration: int.tryParse(_durationCtrl.text) ?? 60,
      ),
    );

    _listenForMessages();

    final assessment = ref.read(practicalAssessmentProvider).currentAssessment;
    if (assessment != null) {
      _initEditControllers(assessment);
    }
  }

  void _handleSaveDraft() {
    _showSnackBar('Practical assessment saved as draft', isError: false);
  }

  void _handleSaveAndPublish() {
    _showSnackBar('Practical assessment published successfully', isError: false);
  }

  void _handleExport(String format) {
    _showSnackBar('Exporting practical assessment as $format...', isError: false);
  }

  void _handleShare() {
    _showSnackBar('Share dialog opened', isError: false);
  }

  void _handleAddItem(List<TextEditingController> controllers) {
    controllers.add(TextEditingController(text: ''));
    setState(() {});
  }

  void _handleRemoveItem(List<TextEditingController> controllers, int index) {
    if (controllers.length <= 1) return;
    controllers[index].dispose();
    controllers.removeAt(index);
    setState(() {});
  }

  void _handleReset() {
    ref.read(practicalAssessmentProvider.notifier).setCurrentAssessment(null);
    _expectedResultsCtrl.clear();
    for (final c in _objectiveControllers) {
      c.dispose();
    }
    _objectiveControllers.clear();
    for (final c in _materialControllers) {
      c.dispose();
    }
    _materialControllers.clear();
    for (final c in _stepControllers) {
      c.dispose();
    }
    _stepControllers.clear();
    for (final c in _safetyControllers) {
      c.dispose();
    }
    _safetyControllers.clear();
    _expandedSectionIndex = null;
    _isEditing = false;
    setState(() {});
  }

  // ─── Build ───────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(practicalAssessmentProvider);
    final assessment = state.currentAssessment;

    return Scaffold(
      appBar: AppAppBar(
        title: assessment != null
            ? 'Generated Practical Assessment'
            : 'AI Practical Assessment Generator',
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
        actions: [
          if (assessment != null)
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
          : assessment != null
              ? _buildGeneratedResult(assessment)
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
              'Create a Practical Assessment with AI',
              style: context.textTheme.headlineSmall?.copyWith(
                fontWeight: AppTypography.wBold,
                color: cs.onSurface,
              ),
            ),
            const SizedBox(height: Spacings.sm),
            Text(
              'Fill in the details below and let AI generate a comprehensive practical assessment with objectives, materials, procedure, and safety precautions.',
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
              hint: 'e.g. Acid-Base Titration, Circuit Building',
              controller: _topicCtrl,
              prefixIcon: Icons.topic_outlined,
              isRequired: true,
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Topic is required' : null,
            ),
            Spacings.itemGap,

            // Difficulty dropdown
            _buildEnumDropdownField<StudentLevel>(
              label: 'Difficulty',
              value: _difficulty,
              items: StudentLevel.values,
              itemLabel: (s) => s.label,
              prefixIcon: Icons.signal_cellular_alt_rounded,
              onChanged: (v) {
                if (v != null) setState(() => _difficulty = v);
              },
            ),
            Spacings.itemGap,

            // Estimated Duration
            AppTextField(
              label: 'Estimated Duration (minutes)',
              hint: 'e.g. 60',
              controller: _durationCtrl,
              prefixIcon: Icons.timer_outlined,
              keyboardType: TextInputType.number,
            ),
            Spacings.itemGap,

            // Custom Instructions
            AppTextField(
              label: 'Custom Instructions',
              hint: 'Any specific instructions for the AI assessment generator...',
              controller: _customInstructionsCtrl,
              prefixIcon: Icons.edit_note_rounded,
              maxLines: 4,
              minLines: 2,
            ),
            Spacings.sectionGap,

            // Generate Button
            AppButton(
              label: 'Generate Practical Assessment',
              onPressed: _handleGenerate,
              variant: AppButtonVariant.elevated,
              icon: Icons.auto_awesome,
              isLoading: ref.watch(practicalAssessmentProvider).isGenerating,
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

  Widget _buildEnumDropdownField<T>({
    required String label,
    required T value,
    required List<T> items,
    required String Function(T) itemLabel,
    required IconData prefixIcon,
    required ValueChanged<T?> onChanged,
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
              label,
              style: context.textTheme.labelLarge?.copyWith(
                color: cs.onSurfaceVariant,
              ),
            ),
          ],
        ),
        const SizedBox(height: Spacings.xs),
        DropdownButtonFormField<T>(
          value: value,
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(Spacings.smRadius),
            ),
            contentPadding: Spacings.paddingInput,
          ),
          items: items
              .map((item) => DropdownMenuItem(
                    value: item,
                    child: Text(itemLabel(item)),
                  ))
              .toList(),
          onChanged: onChanged,
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
              'Generating Practical Assessment...',
              style: context.textTheme.titleMedium?.copyWith(
                fontWeight: AppTypography.wSemiBold,
                color: cs.onSurface,
              ),
            ),
            const SizedBox(height: Spacings.sm),
            Text(
              'AI is crafting a comprehensive practical assessment with objectives, materials, and procedures. This may take a moment.',
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

  Widget _buildGeneratedResult(PracticalAssessmentEntity assessment) {
    return SingleChildScrollView(
      padding: Spacings.paddingScreen,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // AI badge
          if (assessment.isAiGenerated) _buildAiBadge(),
          const SizedBox(height: Spacings.md),

          // Preview card
          _buildPreviewCard(assessment),
          Spacings.itemGap,

          // Section: Objectives
          _buildExpandableSection(
            index: 0,
            icon: Icons.flag_rounded,
            title: 'Objectives',
            count: assessment.objectives.length,
            child: _buildEditableList(
              controllers: _objectiveControllers,
              onAdd: () => _handleAddItem(_objectiveControllers),
              onRemove: (i) => _handleRemoveItem(_objectiveControllers, i),
              emptyLabel: 'No objectives defined',
            ),
          ),
          Spacings.itemGap,

          // Section: Materials Needed
          _buildExpandableSection(
            index: 1,
            icon: Icons.inventory_2_outlined,
            title: 'Materials Needed',
            count: assessment.materialsNeeded.length,
            child: _buildEditableList(
              controllers: _materialControllers,
              onAdd: () => _handleAddItem(_materialControllers),
              onRemove: (i) => _handleRemoveItem(_materialControllers, i),
              emptyLabel: 'No materials listed',
            ),
          ),
          Spacings.itemGap,

          // Section: Procedure Steps
          _buildExpandableSection(
            index: 2,
            icon: Icons.format_list_numbered_rounded,
            title: 'Procedure Steps',
            count: assessment.procedureSteps.length,
            child: _buildEditableList(
              controllers: _stepControllers,
              onAdd: () => _handleAddItem(_stepControllers),
              onRemove: (i) => _handleRemoveItem(_stepControllers, i),
              emptyLabel: 'No steps defined',
              numbered: true,
              reorderable: true,
            ),
          ),
          Spacings.itemGap,

          // Section: Safety Precautions
          _buildExpandableSection(
            index: 3,
            icon: Icons.warning_amber_rounded,
            title: 'Safety Precautions',
            count: assessment.safetyPrecautions.length,
            child: _buildEditableList(
              controllers: _safetyControllers,
              onAdd: () => _handleAddItem(_safetyControllers),
              onRemove: (i) => _handleRemoveItem(_safetyControllers, i),
              emptyLabel: 'No safety precautions listed',
            ),
          ),
          Spacings.itemGap,

          // Section: Expected Results
          _buildExpandableSection(
            index: 4,
            icon: Icons.analytics_outlined,
            title: 'Expected Results',
            count: null,
            child: _buildExpectedResultsSection(),
          ),
          Spacings.itemGap,

          // Section: Assessment Criteria (linked rubric)
          _buildExpandableSection(
            index: 5,
            icon: Icons.grid_on_outlined,
            title: 'Assessment Criteria',
            count: assessment.assessmentCriteria.length,
            child: _buildAssessmentCriteriaSection(assessment),
          ),
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

  Widget _buildPreviewCard(PracticalAssessmentEntity assessment) {
    final cs = context.colorScheme;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.science_rounded, size: Spacings.mdIcon, color: cs.primary),
              const SizedBox(width: Spacings.sm),
              Expanded(
                child: Text(
                  assessment.title,
                  style: context.textTheme.titleMedium?.copyWith(
                    fontWeight: AppTypography.wSemiBold,
                    color: cs.onSurface,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: Spacings.md),
          Row(
            children: [
              _buildStatChip(
                icon: Icons.flag_outlined,
                label: '${assessment.objectives.length} objectives',
                color: cs.primary,
              ),
              const SizedBox(width: Spacings.sm),
              _buildStatChip(
                icon: Icons.inventory_2_outlined,
                label: '${assessment.materialsNeeded.length} materials',
                color: cs.tertiary,
              ),
              if (assessment.estimatedDurationMinutes != null) ...[
                const SizedBox(width: Spacings.sm),
                _buildStatChip(
                  icon: Icons.timer_outlined,
                  label: '${assessment.estimatedDurationMinutes} min',
                  color: cs.secondary,
                ),
              ],
              const SizedBox(width: Spacings.sm),
              _buildStatChip(
                icon: Icons.format_list_numbered_rounded,
                label: '${assessment.procedureSteps.length} steps',
                color: cs.primary,
              ),
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
        color: color.withOpacity(isDark ? 0.20 : 0.10),
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

  Widget _buildExpandableSection({
    required int index,
    required IconData icon,
    required String title,
    required int? count,
    required Widget child,
  }) {
    final cs = context.colorScheme;
    final isExpanded = _expandedSectionIndex == index;

    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () => setState(() {
              _expandedSectionIndex =
                  _expandedSectionIndex == index ? null : index;
            }),
            borderRadius: BorderRadius.circular(Spacings.mdRadius),
            child: Padding(
              padding: const EdgeInsets.all(Spacings.md),
              child: Row(
                children: [
                  Icon(icon, size: Spacings.mdIcon, color: cs.primary),
                  const SizedBox(width: Spacings.sm),
                  Text(
                    title,
                    style: context.textTheme.titleSmall?.copyWith(
                      fontWeight: AppTypography.wSemiBold,
                      color: cs.onSurface,
                    ),
                  ),
                  if (count != null) ...[
                    const SizedBox(width: Spacings.sm),
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
                        '$count',
                        style: context.textTheme.labelSmall?.copyWith(
                          color: cs.onPrimaryContainer,
                          fontWeight: AppTypography.wSemiBold,
                        ),
                      ),
                    ),
                  ],
                  const Spacer(),
                  Icon(
                    isExpanded
                        ? Icons.expand_less_rounded
                        : Icons.expand_more_rounded,
                    color: cs.onSurfaceVariant,
                  ),
                ],
              ),
            ),
          ),
          if (isExpanded) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(Spacings.md),
              child: child,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEditableList({
    required List<TextEditingController> controllers,
    required VoidCallback onAdd,
    required void Function(int) onRemove,
    required String emptyLabel,
    bool numbered = false,
    bool reorderable = false,
  }) {
    if (controllers.isEmpty) {
      return Text(
        emptyLabel,
        style: context.textTheme.bodyMedium?.copyWith(
          color: context.colorScheme.onSurfaceVariant,
          fontStyle: FontStyle.italic,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...controllers.asMap().entries.map((entry) {
          final index = entry.key;
          final controller = entry.value;
          return Padding(
            padding: const EdgeInsets.only(bottom: Spacings.sm),
            child: Row(
              children: [
                if (numbered)
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: context.colorScheme.primaryContainer,
                      borderRadius:
                          BorderRadius.circular(Spacings.fullRadius),
                    ),
                    child: Center(
                      child: Text(
                        '${index + 1}',
                        style: context.textTheme.labelSmall?.copyWith(
                          color: context.colorScheme.onPrimaryContainer,
                          fontWeight: AppTypography.wSemiBold,
                        ),
                      ),
                    ),
                  ),
                if (numbered) const SizedBox(width: Spacings.sm),
                if (reorderable)
                  Icon(
                    Icons.drag_indicator_rounded,
                    size: Spacings.mdIcon,
                    color: context.colorScheme.onSurfaceVariant,
                  ),
                if (reorderable) const SizedBox(width: Spacings.xs),
                Expanded(
                  child: _isEditing
                      ? TextFormField(
                          controller: controller,
                          style: context.textTheme.bodyMedium,
                          maxLines: 2,
                          minLines: 1,
                          decoration: InputDecoration(
                            isDense: true,
                            border: const OutlineInputBorder(),
                            borderRadius:
                                BorderRadius.circular(Spacings.smRadius),
                          ),
                        )
                      : Text(
                          controller.text,
                          style: context.textTheme.bodyMedium?.copyWith(
                            color: context.colorScheme.onSurface,
                          ),
                        ),
                ),
                if (_isEditing) ...[
                  const SizedBox(width: Spacings.xs),
                  IconButton(
                    icon: Icon(
                      Icons.remove_circle_outline_rounded,
                      size: Spacings.mdIcon,
                      color: context.colorScheme.error,
                    ),
                    onPressed: () => onRemove(index),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ],
            ),
          );
        }),

        // Add button
        if (_isEditing)
          AppButton(
            label: 'Add Item',
            onPressed: onAdd,
            variant: AppButtonVariant.text,
            icon: Icons.add_rounded,
            size: AppButtonSize.small,
          ),
      ],
    );
  }

  Widget _buildExpectedResultsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_isEditing)
          TextFormField(
            controller: _expectedResultsCtrl,
            maxLines: 5,
            minLines: 3,
            decoration: InputDecoration(
              labelText: 'Expected Results',
              border: const OutlineInputBorder(),
              borderRadius: BorderRadius.circular(Spacings.smRadius),
            ),
          )
        else
          Text(
            _expectedResultsCtrl.text.isEmpty
                ? 'No expected results defined'
                : _expectedResultsCtrl.text,
            style: context.textTheme.bodyMedium?.copyWith(
              color: _expectedResultsCtrl.text.isEmpty
                  ? context.colorScheme.onSurfaceVariant
                  : context.colorScheme.onSurface,
              fontStyle: _expectedResultsCtrl.text.isEmpty
                  ? FontStyle.italic
                  : null,
            ),
          ),
      ],
    );
  }

  Widget _buildAssessmentCriteriaSection(PracticalAssessmentEntity assessment) {
    final cs = context.colorScheme;
    final rubrics = ref.watch(rubricProvider).rubrics;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Rubric selector
        Row(
          children: [
            Icon(Icons.link_rounded, size: Spacings.smIcon, color: cs.primary),
            const SizedBox(width: Spacings.xs),
            Text(
              'Associated Rubric',
              style: context.textTheme.labelLarge?.copyWith(
                color: cs.onSurfaceVariant,
              ),
            ),
          ],
        ),
        const SizedBox(height: Spacings.xs),
        DropdownButtonFormField<String>(
          value: _selectedRubricId ?? assessment.rubricId,
          hint: const Text('Select a rubric'),
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(Spacings.smRadius),
            ),
            contentPadding: Spacings.paddingInput,
          ),
          items: [
            const DropdownMenuItem<String>(
              value: null,
              child: Text('No rubric linked'),
            ),
            ...rubrics.map((r) => DropdownMenuItem(
                  value: r.id,
                  child: Text(r.title),
                )),
          ],
          onChanged: (v) => setState(() => _selectedRubricId = v),
        ),
        const SizedBox(height: Spacings.md),

        // Criteria table preview
        if (assessment.assessmentCriteria.isNotEmpty) ...[
          Text(
            'Assessment Criteria',
            style: context.textTheme.titleSmall?.copyWith(
              fontWeight: AppTypography.wSemiBold,
              color: cs.onSurface,
            ),
          ),
          const SizedBox(height: Spacings.sm),
          ...assessment.assessmentCriteria.map((criterion) => Padding(
                padding: const EdgeInsets.only(bottom: Spacings.sm),
                child: Row(
                  children: [
                    Icon(Icons.check_circle_outline_rounded,
                        size: Spacings.smIcon, color: cs.primary),
                    const SizedBox(width: Spacings.sm),
                    Expanded(
                      child: Text(
                        criterion['criterion']?.toString() ?? '',
                        style: context.textTheme.bodyMedium,
                      ),
                    ),
                    Text(
                      '${criterion['marks'] ?? 0} marks',
                      style: context.textTheme.labelMedium?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              )),
        ] else
          Text(
            'No assessment criteria defined. Link a rubric to auto-populate.',
            style: context.textTheme.bodyMedium?.copyWith(
              color: cs.onSurfaceVariant,
              fontStyle: FontStyle.italic,
            ),
          ),
      ],
    );
  }

  Widget _buildActionButtons() {
    final cs = context.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Edit toggle
        AppButton(
          label: _isEditing ? 'Done Editing' : 'Edit Sections',
          onPressed: () => setState(() => _isEditing = !_isEditing),
          variant: AppButtonVariant.outlined,
          icon: _isEditing ? Icons.check_rounded : Icons.edit_outlined,
          size: AppButtonSize.medium,
          fullWidth: true,
        ),
        const SizedBox(height: Spacings.md),

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
                    'Export Assessment',
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
