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
import '../../../../shared/widgets/app_error_state.dart';
import '../../../../routing/route_names.dart';
import '../../domain/entities/teacher_workspace_entities.dart';
import '../../domain/usecases/update_lesson_plan_usecase.dart';
import '../providers/lesson_plan_provider.dart';
import '../widgets/generate_questions_button.dart';

// ═══════════════════════════════════════════════════════════════════════
// LESSON PLAN DETAIL PAGE
// ═══════════════════════════════════════════════════════════════════════

/// Detail page for a single lesson plan with all sections, edit mode toggle,
/// and the "Generate Questions" button prominently displayed.
class LessonPlanDetailPage extends ConsumerStatefulWidget {
  const LessonPlanDetailPage({
    super.key,
    required this.planId,
  });

  /// The ID of the lesson plan to display.
  final String planId;

  @override
  ConsumerState<LessonPlanDetailPage> createState() =>
      _LessonPlanDetailPageState();
}

class _LessonPlanDetailPageState extends ConsumerState<LessonPlanDetailPage> {
  bool _isEditing = false;

  // ─── Edit Controllers ────────────────────────────────────────────────

  final _titleCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  final List<TextEditingController> _objectiveControllers = [];
  final List<TextEditingController> _outcomeControllers = [];
  final List<TextEditingController> _materialControllers = [];
  final List<TextEditingController> _homeworkControllers = [];
  final List<TextEditingController> _referenceControllers = [];
  final List<TextEditingController> _extensionControllers = [];

  bool _controllersInitialized = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadPlan();
    });
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _notesCtrl.dispose();
    _disposeControllers(_objectiveControllers);
    _disposeControllers(_outcomeControllers);
    _disposeControllers(_materialControllers);
    _disposeControllers(_homeworkControllers);
    _disposeControllers(_referenceControllers);
    _disposeControllers(_extensionControllers);
    super.dispose();
  }

  void _disposeControllers(List<TextEditingController> controllers) {
    for (final c in controllers) {
      c.dispose();
    }
  }

  // ─── Data Loading ────────────────────────────────────────────────────

  void _loadPlan() {
    final state = ref.read(lessonPlanProvider);
    // First check if the plan is already in the list
    final plan = state.lessonPlans.where((p) => p.id == widget.planId).firstOrNull;
    if (plan != null) {
      ref.read(lessonPlanProvider.notifier).setCurrentPlan(plan);
    }
    // If no plan is loaded, try loading from the API
    if (ref.read(lessonPlanProvider).currentPlan == null) {
      ref.read(lessonPlanProvider.notifier).loadLessonPlans();
    }
  }

  void _initEditControllers(LessonPlanEntity plan) {
    if (_controllersInitialized) return;
    _controllersInitialized = true;

    _titleCtrl.text = plan.title;
    _notesCtrl.text = plan.notes ?? '';
    _initListControllers(plan.learningObjectives, _objectiveControllers);
    _initListControllers(plan.learningOutcomes, _outcomeControllers);
    _initListControllers(plan.teachingMaterials, _materialControllers);
    _initListControllers(plan.homework, _homeworkControllers);
    _initListControllers(plan.referencesList, _referenceControllers);
    _initListControllers(plan.extensionActivities, _extensionControllers);
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

  Future<void> _handleSave() async {
    final plan = ref.read(lessonPlanProvider).currentPlan;
    if (plan == null) return;

    final updatedPlan = plan.copyWith(
      title: _titleCtrl.text.trim().isNotEmpty
          ? _titleCtrl.text.trim()
          : plan.title,
      notes: _notesCtrl.text.trim().isNotEmpty
          ? _notesCtrl.text.trim()
          : plan.notes,
      learningObjectives: _controllersToList(_objectiveControllers),
      learningOutcomes: _controllersToList(_outcomeControllers),
      teachingMaterials: _controllersToList(_materialControllers),
      homework: _controllersToList(_homeworkControllers),
      referencesList: _controllersToList(_referenceControllers),
      extensionActivities: _controllersToList(_extensionControllers),
    );

    await ref.read(lessonPlanProvider.notifier).updateLessonPlan(
      UpdateLessonPlanParams(plan: updatedPlan),
    );

    setState(() => _isEditing = false);
    _controllersInitialized = false;
    _listenForMessages();
  }

  List<String> _controllersToList(List<TextEditingController> controllers) {
    return controllers
        .map((c) => c.text.trim())
        .where((s) => s.isNotEmpty)
        .toList();
  }

  void _handleDelete() {
    final plan = ref.read(lessonPlanProvider).currentPlan;
    if (plan == null) return;

    final cs = context.colorScheme;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Lesson Plan'),
        content: Text(
          'Are you sure you want to delete "${plan.title}"? This action cannot be undone.',
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Spacings.lgRadius),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await ref.read(lessonPlanProvider.notifier).deleteLessonPlan(plan.id);
              _listenForMessages();
              if (mounted) context.pop();
            },
            style: FilledButton.styleFrom(
              backgroundColor: cs.error,
              foregroundColor: cs.onError,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _handlePublish() {
    ref.read(lessonPlanProvider.notifier).publishLessonPlan(widget.planId);
    _listenForMessages();
  }

  // ─── Build ───────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(lessonPlanProvider);
    final plan = state.currentPlan;

    if (state.isLoading && plan == null) {
      return Scaffold(
        appBar: AppAppBar(title: 'Lesson Plan'),
        body: const Center(
          child: AppLoadingSpinner(size: AppLoadingSpinnerSize.large),
        ),
      );
    }

    if (plan == null && state.error != null) {
      return Scaffold(
        appBar: AppAppBar(title: 'Lesson Plan'),
        body: AppErrorState.genericError(
          message: state.error,
          onRetry: () => ref.read(lessonPlanProvider.notifier).loadLessonPlans(),
        ),
      );
    }

    if (plan == null) {
      return Scaffold(
        appBar: AppAppBar(title: 'Lesson Plan'),
        body: AppEmptyState(
          icon: Icons.description_outlined,
          title: 'Lesson Plan Not Found',
          subtitle: 'The lesson plan you are looking for does not exist or has been removed.',
          actionLabel: 'Go Back',
          onAction: () => context.pop(),
        ),
      );
    }

    // Initialize edit controllers when plan is available
    _initEditControllers(plan);

    return Scaffold(
      appBar: AppAppBar(
        title: _isEditing ? 'Edit Lesson Plan' : 'Lesson Plan Details',
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
        actions: [
          if (!_isEditing) ...[
            AppIconButton(
              icon: Icons.edit_rounded,
              onPressed: () => setState(() => _isEditing = true),
              tooltip: 'Edit',
              variant: AppIconButtonVariant.tonal,
            ),
            AppIconButton(
              icon: Icons.delete_outline_rounded,
              onPressed: _handleDelete,
              tooltip: 'Delete',
              variant: AppIconButtonVariant.standard,
            ),
          ] else ...[
            AppIconButton(
              icon: Icons.save_rounded,
              onPressed: _handleSave,
              tooltip: 'Save',
              variant: AppIconButtonVariant.filled,
              isLoading: state.isUpdating,
            ),
            AppIconButton(
              icon: Icons.close_rounded,
              onPressed: () {
                setState(() {
                  _isEditing = false;
                  _controllersInitialized = false;
                });
              },
              tooltip: 'Cancel',
              variant: AppIconButtonVariant.standard,
            ),
          ],
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(lessonPlanProvider.notifier).loadLessonPlans();
          _listenForMessages();
        },
        child: _buildDetailContent(plan),
      ),
    );
  }

  // ─── Detail Content ──────────────────────────────────────────────────

  Widget _buildDetailContent(LessonPlanEntity plan) {
    return SingleChildScrollView(
      padding: Spacings.paddingScreen,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status badges
          _buildStatusBadges(plan),
          const SizedBox(height: Spacings.md),

          // Title
          _buildSectionCard(
            icon: Icons.title_rounded,
            title: 'Title',
            child: _isEditing
                ? AppTextField(
                    controller: _titleCtrl,
                    label: 'Lesson Plan Title',
                    isRequired: true,
                  )
                : Text(
                    plan.title,
                    style: context.textTheme.headlineSmall?.copyWith(
                      fontWeight: AppTypography.wBold,
                      color: context.colorScheme.onSurface,
                    ),
                  ),
          ),
          Spacings.itemGap,

          // Meta info
          _buildMetaSection(plan),
          Spacings.itemGap,

          // Lesson Objectives
          _buildEditableListSection(
            icon: Icons.flag_rounded,
            title: 'Lesson Objectives',
            controllers: _objectiveControllers,
            displayItems: plan.learningObjectives,
          ),
          Spacings.itemGap,

          // Learning Outcomes
          _buildEditableListSection(
            icon: Icons.emoji_events_rounded,
            title: 'Learning Outcomes',
            controllers: _outcomeControllers,
            displayItems: plan.learningOutcomes,
          ),
          Spacings.itemGap,

          // Teaching Materials
          _buildEditableListSection(
            icon: Icons.inventory_2_outlined,
            title: 'Teaching Materials',
            controllers: _materialControllers,
            displayItems: plan.teachingMaterials,
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
          _buildEditableListSection(
            icon: Icons.assignment_outlined,
            title: 'Homework',
            controllers: _homeworkControllers,
            displayItems: plan.homework,
          ),
          Spacings.itemGap,

          // Assessment Questions
          _buildAssessmentSection(plan.assessmentQuestions),
          Spacings.itemGap,

          // References
          _buildEditableListSection(
            icon: Icons.menu_book_rounded,
            title: 'References',
            controllers: _referenceControllers,
            displayItems: plan.referencesList,
          ),
          Spacings.itemGap,

          // Extension Activities
          _buildEditableListSection(
            icon: Icons.extension_rounded,
            title: 'Extension Activities',
            controllers: _extensionControllers,
            displayItems: plan.extensionActivities,
          ),
          Spacings.itemGap,

          // Notes (editable)
          if (_isEditing || (plan.notes != null && plan.notes!.isNotEmpty)) ...[
            _buildSectionCard(
              icon: Icons.sticky_note_2_outlined,
              title: 'Notes',
              child: _isEditing
                  ? AppTextField(
                      controller: _notesCtrl,
                      label: 'Additional Notes',
                      maxLines: 4,
                      minLines: 2,
                    )
                  : Text(
                      plan.notes!,
                      style: context.textTheme.bodyMedium?.copyWith(
                        color: context.colorScheme.onSurface,
                        height: 1.5,
                      ),
                    ),
            ),
            Spacings.itemGap,
          ],

          Spacings.sectionGap,

          // Generate Questions button (CRITICAL - prominent)
          GenerateQuestionsButton(
            resourceType: 'lesson_plan',
            resourceId: plan.id,
          ),
          Spacings.sectionGap,

          // Action buttons (when not in edit mode)
          if (!_isEditing) _buildBottomActions(plan),
          const SizedBox(height: Spacings.xxl),
        ],
      ),
    );
  }

  // ─── Status Badges ───────────────────────────────────────────────────

  Widget _buildStatusBadges(LessonPlanEntity plan) {
    final cs = context.colorScheme;
    final isDark = context.isDarkMode;

    return Wrap(
      spacing: Spacings.sm,
      runSpacing: Spacings.sm,
      children: [
        if (plan.isAiGenerated)
          Container(
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
                Icon(Icons.auto_awesome, size: 14, color: cs.onTertiaryContainer),
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
          ),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: Spacings.md,
            vertical: Spacings.sm,
          ),
          decoration: BoxDecoration(
            color: plan.isPublished
                ? cs.primary.withOpacity(isDark ? 0.20 : 0.10)
                : cs.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(Spacings.fullRadius),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                plan.isPublished ? Icons.public_rounded : Icons.drafts_rounded,
                size: 14,
                color: plan.isPublished ? cs.primary : cs.onSurfaceVariant,
              ),
              const SizedBox(width: Spacings.xs),
              Text(
                plan.isPublished ? 'Published' : 'Draft',
                style: context.textTheme.labelSmall?.copyWith(
                  color: plan.isPublished ? cs.primary : cs.onSurfaceVariant,
                  fontWeight: AppTypography.wSemiBold,
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: Spacings.md,
            vertical: Spacings.sm,
          ),
          decoration: BoxDecoration(
            color: cs.secondaryContainer,
            borderRadius: BorderRadius.circular(Spacings.fullRadius),
          ),
          child: Text(
            'Version ${plan.version}',
            style: context.textTheme.labelSmall?.copyWith(
              color: cs.onSecondaryContainer,
              fontWeight: AppTypography.wMedium,
            ),
          ),
        ),
      ],
    );
  }

  // ─── Meta Section ────────────────────────────────────────────────────

  Widget _buildMetaSection(LessonPlanEntity plan) {
    final cs = context.colorScheme;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline_rounded, size: Spacings.mdIcon, color: cs.primary),
              const SizedBox(width: Spacings.sm),
              Text(
                'Overview',
                style: context.textTheme.titleSmall?.copyWith(
                  fontWeight: AppTypography.wSemiBold,
                  color: cs.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: Spacings.md),
          Wrap(
            spacing: Spacings.md,
            runSpacing: Spacings.sm,
            children: [
              _buildMetaChip(Icons.book_outlined, plan.subject, cs.primary),
              if (plan.className != null)
                _buildMetaChip(Icons.school_outlined, plan.className!, cs.tertiary),
              if (plan.topic != null)
                _buildMetaChip(Icons.topic_outlined, plan.topic!, cs.secondary),
              if (plan.subtopic != null)
                _buildMetaChip(Icons.subdirectory_arrow_right_rounded, plan.subtopic!, cs.secondary),
              _buildMetaChip(Icons.psychology_outlined, plan.teachingStyle.label, cs.secondary),
              _buildMetaChip(Icons.timer_outlined, '${plan.durationMinutes} min', cs.primary),
              _buildMetaChip(Icons.people_outlined, plan.studentLevel.label, cs.tertiary),
              _buildMetaChip(Icons.curriculum_outlined, plan.curriculum.label, cs.secondary),
            ],
          ),
          const SizedBox(height: Spacings.md),
          Row(
            children: [
              Icon(Icons.calendar_today_outlined, size: Spacings.smIcon, color: cs.onSurfaceVariant),
              const SizedBox(width: Spacings.xs),
              Text(
                'Created ${_formatDate(plan.createdAt)} · Updated ${_formatDate(plan.updatedAt)}',
                style: context.textTheme.bodySmall?.copyWith(
                  color: cs.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetaChip(IconData icon, String label, Color color) {
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

  // ─── Section Card ────────────────────────────────────────────────────

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

  // ─── Editable List Section ───────────────────────────────────────────

  Widget _buildEditableListSection({
    required IconData icon,
    required String title,
    required List<TextEditingController> controllers,
    required List<String> displayItems,
  }) {
    final cs = context.colorScheme;
    final items = _isEditing ? controllers : displayItems;

    if (items.isEmpty && !_isEditing) return const SizedBox.shrink();

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
              if (!_isEditing)
                Text(
                  '${displayItems.length} item${displayItems.length != 1 ? 's' : ''}',
                  style: context.textTheme.bodySmall?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
                ),
            ],
          ),
          const SizedBox(height: Spacings.md),
          if (_isEditing) ...[
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
            }),
            // Add item button
            AppButton(
              label: 'Add $title',
              onPressed: () {
                setState(() {
                  controllers.add(TextEditingController());
                });
              },
              variant: AppButtonVariant.text,
              icon: Icons.add_rounded,
              size: AppButtonSize.small,
            ),
          ] else ...[
            ...displayItems.map((item) => _buildBulletItem(item)),
          ],
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

  // ─── Activity Section ────────────────────────────────────────────────

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

  // ─── Assessment Section ──────────────────────────────────────────────

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
            final marks = q['marks'] as int?;

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
                    width: 28,
                    height: 28,
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
                        const SizedBox(height: Spacings.xs),
                        Row(
                          children: [
                            if (type != null)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: Spacings.sm,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: cs.secondaryContainer,
                                  borderRadius:
                                      BorderRadius.circular(Spacings.fullRadius),
                                ),
                                child: Text(
                                  type,
                                  style: context.textTheme.labelSmall?.copyWith(
                                    color: cs.onSecondaryContainer,
                                  ),
                                ),
                              ),
                            if (marks != null) ...[
                              const SizedBox(width: Spacings.sm),
                              Text(
                                '$marks marks',
                                style: context.textTheme.labelSmall?.copyWith(
                                  color: cs.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ],
                        ),
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

  // ─── Bottom Actions ──────────────────────────────────────────────────

  Widget _buildBottomActions(LessonPlanEntity plan) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppButton(
          label: 'Edit Lesson Plan',
          onPressed: () => setState(() => _isEditing = true),
          variant: AppButtonVariant.outlined,
          icon: Icons.edit_rounded,
          fullWidth: true,
        ),
        const SizedBox(height: Spacings.sm),
        if (!plan.isPublished)
          AppButton(
            label: 'Publish Lesson Plan',
            onPressed: _handlePublish,
            variant: AppButtonVariant.tonal,
            icon: Icons.public_rounded,
            fullWidth: true,
          ),
        const SizedBox(height: Spacings.sm),
        AppButton(
          label: 'Delete Lesson Plan',
          onPressed: _handleDelete,
          variant: AppButtonVariant.text,
          icon: Icons.delete_outline_rounded,
          fullWidth: true,
        ),
      ],
    );
  }

  // ─── Date Formatting ─────────────────────────────────────────────────

  String _formatDate(DateTime date) {
    const months = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[date.month]} ${date.day}, ${date.year}';
  }
}
