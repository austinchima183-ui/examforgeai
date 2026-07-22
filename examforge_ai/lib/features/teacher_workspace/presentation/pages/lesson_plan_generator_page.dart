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
import '../../../../routing/route_names.dart';
import '../../domain/entities/teacher_workspace_entities.dart';
import '../../domain/usecases/generate_lesson_plan_usecase.dart';
import '../../domain/usecases/create_lesson_plan_usecase.dart';
import '../../domain/usecases/update_lesson_plan_usecase.dart';
import '../providers/lesson_plan_provider.dart';
import '../widgets/generate_questions_button.dart';

// ═══════════════════════════════════════════════════════════════════════
// LESSON PLAN GENERATOR PAGE
// ═══════════════════════════════════════════════════════════════════════

/// AI Lesson Plan Generator page where teachers fill in parameters and AI
/// generates a complete lesson plan.
///
/// Has two states: input form (no plan generated yet) and generated result
/// (editable lesson plan with all sections).
class LessonPlanGeneratorPage extends ConsumerStatefulWidget {
  const LessonPlanGeneratorPage({super.key});

  @override
  ConsumerState<LessonPlanGeneratorPage> createState() =>
      _LessonPlanGeneratorPageState();
}

class _LessonPlanGeneratorPageState
    extends ConsumerState<LessonPlanGeneratorPage> {
  // ─── Form Controllers ────────────────────────────────────────────────

  final _formKey = GlobalKey<FormState>();
  final _subjectCtrl = TextEditingController();
  final _classNameCtrl = TextEditingController();
  final _topicCtrl = TextEditingController();
  final _subtopicCtrl = TextEditingController();
  final _objectivesCtrl = TextEditingController();
  final _durationCtrl = TextEditingController(text: '40');

  CurriculumType _curriculum = CurriculumType.nigerian;
  TeachingStyle _teachingStyle = TeachingStyle.interactive;
  StudentLevel _studentLevel = StudentLevel.intermediate;

  // ─── Edit Controllers (for generated result) ────────────────────────

  final _titleEditCtrl = TextEditingController();
  final List<TextEditingController> _objectiveControllers = [];
  final List<TextEditingController> _outcomeControllers = [];
  bool _isEditing = false;

  @override
  void dispose() {
    _subjectCtrl.dispose();
    _classNameCtrl.dispose();
    _topicCtrl.dispose();
    _subtopicCtrl.dispose();
    _objectivesCtrl.dispose();
    _durationCtrl.dispose();
    _titleEditCtrl.dispose();
    for (final c in _objectiveControllers) {
      c.dispose();
    }
    for (final c in _outcomeControllers) {
      c.dispose();
    }
    super.dispose();
  }

  // ─── Helpers ─────────────────────────────────────────────────────────

  void _listenForMessages() {
    final state = ref.read(lessonPlanProvider);
    if (state.successMessage != null) {
      _showSnackBar(state.successMessage!, isError: false);
      ref.read(lessonPlanProvider.notifier).clearSuccessMessage();
    }
    if (state.error != null) {
      _showSnackBar(state.error!, isError: true);
      ref.read(lessonPlanProvider.notifier).clearError();
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

  Future<void> _handleGenerate() async {
    if (!_formKey.currentState!.validate()) return;

    final objectives = _objectivesCtrl.text
        .split('\n')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();

    final duration = int.tryParse(_durationCtrl.text) ?? 40;

    await ref.read(lessonPlanProvider.notifier).generateLessonPlan(
      GenerateLessonPlanParams(
        subject: _subjectCtrl.text.trim(),
        className: _classNameCtrl.text.trim(),
        topic: _topicCtrl.text.trim(),
        subtopic: _subtopicCtrl.text.trim().isNotEmpty
            ? _subtopicCtrl.text.trim()
            : null,
        curriculum: _curriculum,
        learningObjectives: objectives.isNotEmpty ? objectives : null,
        durationMinutes: duration,
        teachingStyle: _teachingStyle,
        studentLevel: _studentLevel,
      ),
    );

    _listenForMessages();

    // Initialize edit controllers from the generated plan
    final plan = ref.read(lessonPlanProvider).currentPlan;
    if (plan != null) {
      _titleEditCtrl.text = plan.title;
      _initListControllers(
        plan.learningObjectives,
        _objectiveControllers,
      );
      _initListControllers(
        plan.learningOutcomes,
        _outcomeControllers,
      );
    }
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

  void _handleSave() {
    final plan = ref.read(lessonPlanProvider).currentPlan;
    if (plan == null) return;

    final updatedObjectives = _objectiveControllers
        .map((c) => c.text.trim())
        .where((s) => s.isNotEmpty)
        .toList();
    final updatedOutcomes = _outcomeControllers
        .map((c) => c.text.trim())
        .where((s) => s.isNotEmpty)
        .toList();

    ref.read(lessonPlanProvider.notifier).updateLessonPlan(
      UpdateLessonPlanParams(
        plan: plan.copyWith(
          title: _titleEditCtrl.text.trim().isNotEmpty
              ? _titleEditCtrl.text.trim()
              : plan.title,
          learningObjectives: updatedObjectives,
          learningOutcomes: updatedOutcomes,
        ),
      ),
    );

    setState(() => _isEditing = false);
    _listenForMessages();
  }

  void _handleReset() {
    ref.read(lessonPlanProvider.notifier).setCurrentPlan(null);
    _titleEditCtrl.clear();
    for (final c in _objectiveControllers) {
      c.dispose();
    }
    _objectiveControllers.clear();
    for (final c in _outcomeControllers) {
      c.dispose();
    }
    _outcomeControllers.clear();
    setState(() => _isEditing = false);
  }

  // ─── Build ───────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(lessonPlanProvider);
    final plan = state.currentPlan;

    return Scaffold(
      appBar: AppAppBar(
        title: plan != null ? 'Generated Lesson Plan' : 'AI Lesson Plan Generator',
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
        actions: [
          if (plan != null)
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
          : plan != null
              ? _buildGeneratedResult(plan)
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
              'Create a Lesson Plan with AI',
              style: context.textTheme.headlineSmall?.copyWith(
                fontWeight: AppTypography.wBold,
                color: cs.onSurface,
              ),
            ),
            const SizedBox(height: Spacings.sm),
            Text(
              'Fill in the details below and let AI generate a comprehensive lesson plan tailored to your needs.',
              style: context.textTheme.bodyMedium?.copyWith(
                color: cs.onSurfaceVariant,
              ),
            ),
            Spacings.sectionGap,

            // Subject
            AppTextField(
              label: 'Subject',
              hint: 'e.g. Mathematics, English, Physics',
              controller: _subjectCtrl,
              prefixIcon: Icons.book_outlined,
              isRequired: true,
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Subject is required' : null,
            ),
            Spacings.itemGap,

            // Class Name
            AppTextField(
              label: 'Class Name',
              hint: 'e.g. SS2, JSS3, Primary 5',
              controller: _classNameCtrl,
              prefixIcon: Icons.school_outlined,
            ),
            Spacings.itemGap,

            // Topic
            AppTextField(
              label: 'Topic',
              hint: 'e.g. Quadratic Equations, Photosynthesis',
              controller: _topicCtrl,
              prefixIcon: Icons.topic_outlined,
            ),
            Spacings.itemGap,

            // Subtopic
            AppTextField(
              label: 'Subtopic',
              hint: 'e.g. Solving by Formula',
              controller: _subtopicCtrl,
              prefixIcon: Icons.subdirectory_arrow_right_rounded,
            ),
            Spacings.itemGap,

            // Curriculum dropdown
            AppDropdownField<CurriculumType>(
              label: 'Curriculum',
              items: CurriculumType.values,
              selectedItem: _curriculum,
              onChanged: (v) {
                if (v != null) setState(() => _curriculum = v);
              },
              itemLabel: (c) => c.label,
              prefixIcon: Icons.school_outlined,
              isRequired: true,
            ),
            Spacings.itemGap,

            // Learning Objectives
            AppTextField(
              label: 'Learning Objectives',
              hint: 'Enter each objective on a new line',
              controller: _objectivesCtrl,
              prefixIcon: Icons.flag_outlined,
              maxLines: 4,
              minLines: 2,
            ),
            Spacings.itemGap,

            // Duration
            AppTextField(
              label: 'Duration (minutes)',
              hint: 'e.g. 40',
              controller: _durationCtrl,
              prefixIcon: Icons.timer_outlined,
              keyboardType: TextInputType.number,
            ),
            Spacings.itemGap,

            // Teaching Style dropdown
            AppDropdownField<TeachingStyle>(
              label: 'Teaching Style',
              items: TeachingStyle.values,
              selectedItem: _teachingStyle,
              onChanged: (v) {
                if (v != null) setState(() => _teachingStyle = v);
              },
              itemLabel: (s) => s.label,
              prefixIcon: Icons.psychology_outlined,
            ),
            Spacings.itemGap,

            // Student Level dropdown
            AppDropdownField<StudentLevel>(
              label: 'Student Level',
              items: StudentLevel.values,
              selectedItem: _studentLevel,
              onChanged: (v) {
                if (v != null) setState(() => _studentLevel = v);
              },
              itemLabel: (l) => l.label,
              prefixIcon: Icons.people_outlined,
            ),
            Spacings.sectionGap,

            // Generate Button
            AppButton(
              label: 'Generate Lesson Plan',
              onPressed: _handleGenerate,
              variant: AppButtonVariant.elevated,
              icon: Icons.auto_awesome,
              isLoading: ref.watch(lessonPlanProvider).isGenerating,
              fullWidth: true,
              size: AppButtonSize.large,
            ),
            const SizedBox(height: Spacings.xl),
          ],
        ),
      ),
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
              'Generating Your Lesson Plan...',
              style: context.textTheme.titleMedium?.copyWith(
                fontWeight: AppTypography.wSemiBold,
                color: cs.onSurface,
              ),
            ),
            const SizedBox(height: Spacings.sm),
            Text(
              'AI is crafting a comprehensive lesson plan based on your parameters. This may take a moment.',
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

  Widget _buildGeneratedResult(LessonPlanEntity plan) {
    return SingleChildScrollView(
      padding: Spacings.paddingScreen,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // AI badge
          if (plan.isAiGenerated)
            _buildAiBadge(),
          const SizedBox(height: Spacings.md),

          // Title section
          _buildSectionCard(
            icon: Icons.title_rounded,
            title: 'Title',
            child: _isEditing
                ? AppTextField(
                    controller: _titleEditCtrl,
                    label: 'Lesson Plan Title',
                    isRequired: true,
                  )
                : Text(
                    plan.title,
                    style: context.textTheme.titleLarge?.copyWith(
                      fontWeight: AppTypography.wBold,
                      color: context.colorScheme.onSurface,
                    ),
                  ),
          ),
          Spacings.itemGap,

          // Meta info row
          _buildMetaInfoRow(plan),
          Spacings.itemGap,

          // Lesson Objectives
          _buildEditableListSection(
            icon: Icons.flag_rounded,
            title: 'Lesson Objectives',
            items: plan.learningObjectives,
            controllers: _objectiveControllers,
          ),
          Spacings.itemGap,

          // Learning Outcomes
          _buildEditableListSection(
            icon: Icons.emoji_events_rounded,
            title: 'Learning Outcomes',
            items: plan.learningOutcomes,
            controllers: _outcomeControllers,
          ),
          Spacings.itemGap,

          // Teaching Materials
          _buildListSection(
            icon: Icons.inventory_2_outlined,
            title: 'Teaching Materials',
            items: plan.teachingMaterials,
          ),
          Spacings.itemGap,

          // Classroom Activities
          _buildActivitySection(
            icon: Icons.groups_rounded,
            title: 'Classroom Activities',
            activities: plan.classroomActivities,
          ),
          Spacings.itemGap,

          // Practical Activities
          _buildActivitySection(
            icon: Icons.science_rounded,
            title: 'Practical Activities',
            activities: plan.practicalActivities,
          ),
          Spacings.itemGap,

          // Homework
          _buildListSection(
            icon: Icons.assignment_outlined,
            title: 'Homework',
            items: plan.homework,
          ),
          Spacings.itemGap,

          // Assessment Questions
          _buildAssessmentSection(plan.assessmentQuestions),
          Spacings.itemGap,

          // References
          _buildListSection(
            icon: Icons.menu_book_rounded,
            title: 'References',
            items: plan.referencesList,
          ),
          Spacings.itemGap,

          // Extension Activities
          _buildListSection(
            icon: Icons.extension_rounded,
            title: 'Extension Activities',
            items: plan.extensionActivities,
          ),
          Spacings.sectionGap,

          // Generate Questions button (CRITICAL - prominent)
          GenerateQuestionsButton(
            resourceType: 'lesson_plan',
            resourceId: plan.id,
            resourceName: plan.title,
          ),
          Spacings.sectionGap,

          // Action buttons
          _buildActionButtons(plan),
          const SizedBox(height: Spacings.xxl),
        ],
      ),
    );
  }

  // ─── Section Builders ────────────────────────────────────────────────

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

  Widget _buildSectionCard({
    required IconData icon,
    required String title,
    required Widget child,
  }) {
    final cs = context.colorScheme;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
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
            ],
          ),
          const SizedBox(height: Spacings.md),
          child,
        ],
      ),
    );
  }

  Widget _buildMetaInfoRow(LessonPlanEntity plan) {
    final cs = context.colorScheme;

    return AppCard(
      child: Wrap(
        spacing: Spacings.md,
        runSpacing: Spacings.sm,
        children: [
          _buildMetaChip(
            icon: Icons.book_outlined,
            label: plan.subject,
            color: cs.primary,
          ),
          if (plan.className != null)
            _buildMetaChip(
              icon: Icons.school_outlined,
              label: plan.className!,
              color: cs.tertiary,
            ),
          _buildMetaChip(
            icon: Icons.psychology_outlined,
            label: plan.teachingStyle.label,
            color: cs.secondary,
          ),
          _buildMetaChip(
            icon: Icons.timer_outlined,
            label: '${plan.durationMinutes} min',
            color: cs.primary,
          ),
          _buildMetaChip(
            icon: Icons.people_outlined,
            label: plan.studentLevel.label,
            color: cs.tertiary,
          ),
          _buildMetaChip(
            icon: Icons.school_outlined,
            label: plan.curriculum.label,
            color: cs.secondary,
          ),
        ],
      ),
    );
  }

  Widget _buildMetaChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    final cs = context.colorScheme;
    final isDark = context.isDarkMode;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Spacings.md,
        vertical: Spacings.sm,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(isDark ? 0.20 : 0.10),
        borderRadius: BorderRadius.circular(Spacings.fullRadius),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: Spacings.xs),
          Text(
            label,
            style: context.textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: AppTypography.wSemiBold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditableListSection({
    required IconData icon,
    required String title,
    required List<String> items,
    required List<TextEditingController> controllers,
  }) {
    final cs = context.colorScheme;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
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
            ],
          ),
          const SizedBox(height: Spacings.md),
          if (_isEditing)
            ...List.generate(controllers.length, (i) {
              return Padding(
                padding: const EdgeInsets.only(bottom: Spacings.sm),
                child: Row(
                  children: [
                    Expanded(
                      child: AppTextField(
                        controller: controllers[i],
                        hint: '$title ${i + 1}',
                      ),
                    ),
                    const SizedBox(width: Spacings.sm),
                    AppIconButton(
                      icon: Icons.delete_outline_rounded,
                      onPressed: () {
                        setState(() {
                          controllers[i].dispose();
                          controllers.removeAt(i);
                        });
                      },
                      variant: AppIconButtonVariant.standard,
                      size: AppButtonSize.small,
                      color: cs.error,
                    ),
                  ],
                ),
              );
            })
          else
            ...items.map((item) => _buildBulletItem(item)),
        ],
      ),
    );
  }

  Widget _buildListSection({
    required IconData icon,
    required String title,
    required List<String> items,
  }) {
    final cs = context.colorScheme;

    if (items.isEmpty) return const SizedBox.shrink();

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
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
              const Spacer(),
              Text(
                '${items.length} item${items.length != 1 ? 's' : ''}',
                style: context.textTheme.bodySmall?.copyWith(
                  color: cs.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: Spacings.md),
          ...items.map((item) => _buildBulletItem(item)),
        ],
      ),
    );
  }

  Widget _buildBulletItem(String text) {
    final cs = context.colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: Spacings.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 6, right: Spacings.sm),
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: cs.primary,
              shape: BoxShape.circle,
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: context.textTheme.bodyMedium?.copyWith(
                color: cs.onSurface,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivitySection({
    required IconData icon,
    required String title,
    required List<Map<String, dynamic>> activities,
  }) {
    final cs = context.colorScheme;

    if (activities.isEmpty) return const SizedBox.shrink();

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
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
              const Spacer(),
              Text(
                '${activities.length} activit${activities.length != 1 ? 'ies' : 'y'}',
                style: context.textTheme.bodySmall?.copyWith(
                  color: cs.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: Spacings.md),
          ...activities.map((activity) => _buildActivityCard(activity)),
        ],
      ),
    );
  }

  Widget _buildActivityCard(Map<String, dynamic> activity) {
    final cs = context.colorScheme;
    final isDark = context.isDarkMode;
    final name = activity['name'] as String? ?? activity['title'] as String? ?? 'Activity';
    final description = activity['description'] as String? ?? '';
    final duration = activity['duration'] as int?;
    final type = activity['type'] as String?;

    return Container(
      margin: const EdgeInsets.only(bottom: Spacings.sm),
      padding: const EdgeInsets.all(Spacings.md),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(Spacings.smRadius),
        border: Border.all(
          color: cs.outlineVariant.withOpacity(0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  name,
                  style: context.textTheme.titleSmall?.copyWith(
                    fontWeight: AppTypography.wSemiBold,
                    color: cs.onSurface,
                  ),
                ),
              ),
              if (duration != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: Spacings.sm,
                    vertical: Spacings.xs,
                  ),
                  decoration: BoxDecoration(
                    color: cs.primary.withOpacity(isDark ? 0.20 : 0.10),
                    borderRadius: BorderRadius.circular(Spacings.fullRadius),
                  ),
                  child: Text(
                    '$duration min',
                    style: context.textTheme.labelSmall?.copyWith(
                      color: cs.primary,
                      fontWeight: AppTypography.wSemiBold,
                    ),
                  ),
                ),
            ],
          ),
          if (description.isNotEmpty) ...[
            const SizedBox(height: Spacings.xs),
            Text(
              description,
              style: context.textTheme.bodySmall?.copyWith(
                color: cs.onSurfaceVariant,
                height: 1.5,
              ),
            ),
          ],
          if (type != null) ...[
            const SizedBox(height: Spacings.xs),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: Spacings.sm,
                vertical: 2,
              ),
              decoration: BoxDecoration(
                color: cs.secondaryContainer,
                borderRadius: BorderRadius.circular(Spacings.fullRadius),
              ),
              child: Text(
                type,
                style: context.textTheme.labelSmall?.copyWith(
                  color: cs.onSecondaryContainer,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAssessmentSection(List<Map<String, dynamic>> questions) {
    final cs = context.colorScheme;

    if (questions.isEmpty) return const SizedBox.shrink();

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.quiz_rounded, size: Spacings.mdIcon, color: cs.primary),
              const SizedBox(width: Spacings.sm),
              Text(
                'Assessment Questions',
                style: context.textTheme.titleSmall?.copyWith(
                  fontWeight: AppTypography.wSemiBold,
                  color: cs.onSurface,
                ),
              ),
              const Spacer(),
              Text(
                '${questions.length} question${questions.length != 1 ? 's' : ''}',
                style: context.textTheme.bodySmall?.copyWith(
                  color: cs.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: Spacings.md),
          ...List.generate(questions.length, (i) {
            final q = questions[i];
            final questionText = q['question'] as String? ?? q['text'] as String? ?? 'Question ${i + 1}';
            final type = q['type'] as String?;

            return Container(
              margin: const EdgeInsets.only(bottom: Spacings.sm),
              padding: const EdgeInsets.all(Spacings.md),
              decoration: BoxDecoration(
                color: cs.surfaceContainerLow,
                borderRadius: BorderRadius.circular(Spacings.smRadius),
                border: Border.all(
                  color: cs.outlineVariant.withOpacity(0.5),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: cs.primary.withOpacity(context.isDarkMode ? 0.20 : 0.10,
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '${i + 1}',
                        style: context.textTheme.labelSmall?.copyWith(
                          color: cs.primary,
                          fontWeight: AppTypography.wSemiBold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: Spacings.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          questionText,
                          style: context.textTheme.bodyMedium?.copyWith(
                            color: cs.onSurface,
                          ),
                        ),
                        if (type != null) ...[
                          const SizedBox(height: Spacings.xs),
                          Text(
                            type,
                            style: context.textTheme.labelSmall?.copyWith(
                              color: cs.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildActionButtons(LessonPlanEntity plan) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_isEditing) ...[
          AppButton(
            label: 'Save Changes',
            onPressed: _handleSave,
            variant: AppButtonVariant.elevated,
            icon: Icons.save_rounded,
            isLoading: ref.watch(lessonPlanProvider).isUpdating,
            fullWidth: true,
          ),
          const SizedBox(height: Spacings.sm),
          AppButton(
            label: 'Cancel Editing',
            onPressed: () => setState(() => _isEditing = false),
            variant: AppButtonVariant.outlined,
            fullWidth: true,
          ),
        ] else ...[
          AppButton(
            label: 'Edit Lesson Plan',
            onPressed: () => setState(() => _isEditing = true),
            variant: AppButtonVariant.outlined,
            icon: Icons.edit_rounded,
            fullWidth: true,
          ),
          const SizedBox(height: Spacings.sm),
          AppButton(
            label: 'Save to My Plans',
            onPressed: () {
              ref.read(lessonPlanProvider.notifier).createLessonPlan(
                    CreateLessonPlanParams(plan: plan),
                  );
              _listenForMessages();
            },
            variant: AppButtonVariant.tonal,
            icon: Icons.bookmark_add_rounded,
            fullWidth: true,
          ),
        ],
      ],
    );
  }
}
