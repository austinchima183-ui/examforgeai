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
import '../providers/lesson_plan_provider.dart';
import '../widgets/generate_questions_button.dart';

// ═══════════════════════════════════════════════════════════════════════
// LESSON PLAN LIST PAGE
// ═══════════════════════════════════════════════════════════════════════

/// List page showing all lesson plans with search, filter, and CRUD actions.
class LessonPlanListPage extends ConsumerStatefulWidget {
  const LessonPlanListPage({super.key});

  @override
  ConsumerState<LessonPlanListPage> createState() =>
      _LessonPlanListPageState();
}

class _LessonPlanListPageState extends ConsumerState<LessonPlanListPage> {
  final _searchCtrl = TextEditingController();
  TeachingStyle? _filterTeachingStyle;
  StudentLevel? _filterStudentLevel;
  String? _filterSubject;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(lessonPlanProvider.notifier).loadLessonPlans();
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
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

  List<LessonPlanEntity> _applyLocalFilters(List<LessonPlanEntity> plans) {
    var filtered = plans;

    // Search filter
    final query = _searchCtrl.text.trim().toLowerCase();
    if (query.isNotEmpty) {
      filtered = filtered
          .where((p) =>
              p.title.toLowerCase().contains(query) ||
              p.subject.toLowerCase().contains(query) ||
              (p.className?.toLowerCase().contains(query) ?? false) ||
              (p.topic?.toLowerCase().contains(query) ?? false))
          .toList();
    }

    // Teaching style filter
    if (_filterTeachingStyle != null) {
      filtered = filtered
          .where((p) => p.teachingStyle == _filterTeachingStyle)
          .toList();
    }

    // Student level filter
    if (_filterStudentLevel != null) {
      filtered = filtered
          .where((p) => p.studentLevel == _filterStudentLevel)
          .toList();
    }

    // Subject filter
    if (_filterSubject != null) {
      filtered = filtered
          .where((p) => p.subject == _filterSubject)
          .toList();
    }

    return filtered;
  }

  List<String> _getUniqueSubjects(List<LessonPlanEntity> plans) {
    final subjects = plans.map((p) => p.subject).toSet().toList()..sort();
    return subjects;
  }

  Future<void> _handleRefresh() async {
    await ref.read(lessonPlanProvider.notifier).loadLessonPlans();
    _listenForMessages();
  }

  void _handleDelete(String planId) {
    ref.read(lessonPlanProvider.notifier).deleteLessonPlan(planId);
    _listenForMessages();
  }

  void _handlePublish(String planId) {
    ref.read(lessonPlanProvider.notifier).publishLessonPlan(planId);
    _listenForMessages();
  }

  void _navigateToGenerator() {
    // Navigate to the lesson plan generator page
    context.push('/workspace/lesson-plans/generator');
  }

  void _navigateToDetail(String planId) {
    context.push('/workspace/lesson-plans/detail/$planId');
  }

  // ─── Build ───────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(lessonPlanProvider);

    return Scaffold(
      appBar: AppAppBar(
        title: 'Lesson Plans',
        actions: [
          AppIconButton(
            icon: Icons.add_rounded,
            onPressed: _navigateToGenerator,
            tooltip: 'New Lesson Plan',
            variant: AppIconButtonVariant.filled,
          ),
        ],
      ),
      body: state.isLoading
          ? _buildLoadingShimmer()
          : state.error != null && state.lessonPlans.isEmpty
              ? _buildErrorState()
              : _buildContent(state),
      floatingActionButton: AppFloatingActionButton(
        label: 'New Lesson Plan',
        icon: Icons.add_rounded,
        onPressed: _navigateToGenerator,
        extended: true,
      ),
    );
  }

  // ─── Content ─────────────────────────────────────────────────────────

  Widget _buildContent(LessonPlanState state) {
    final filteredPlans = _applyLocalFilters(state.lessonPlans);

    return RefreshIndicator(
      onRefresh: _handleRefresh,
      child: CustomScrollView(
        slivers: [
          // Search bar
          SliverToBoxAdapter(child: _buildSearchBar()),
          const SliverToBoxAdapter(child: SizedBox(height: Spacings.sm)),

          // Filter chips
          SliverToBoxAdapter(child: _buildFilterChips(state.lessonPlans)),
          const SliverToBoxAdapter(child: SizedBox(height: Spacings.md)),

          // Results count
          SliverToBoxAdapter(child: _buildResultsCount(filteredPlans.length)),
          const SliverToBoxAdapter(child: SizedBox(height: Spacings.sm)),

          // Lesson plan list
          if (filteredPlans.isEmpty)
            SliverFillRemaining(
              child: _buildEmptyState(),
            )
          else
            SliverPadding(
              padding: Spacings.paddingScreen,
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) => Padding(
                    padding: const EdgeInsets.only(bottom: Spacings.md),
                    child: _buildLessonPlanCard(filteredPlans[index]),
                  ),
                  childCount: filteredPlans.length,
                ),
              ),
            ),

          // Load more trigger
          if (state.hasMore && filteredPlans.isNotEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(Spacings.lg),
                child: Center(
                  child: AppButton(
                    label: 'Load More',
                    onPressed: () =>
                        ref.read(lessonPlanProvider.notifier).loadMore(),
                    variant: AppButtonVariant.text,
                    isLoading: state.isLoadingMore,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ─── Search Bar ──────────────────────────────────────────────────────

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: Spacings.lg,
        vertical: Spacings.sm,
      ),
      child: AppSearchField(
        hint: 'Search lesson plans...',
        controller: _searchCtrl,
        onChanged: (_) => setState(() {}),
      ),
    );
  }

  // ─── Filter Chips ────────────────────────────────────────────────────

  Widget _buildFilterChips(List<LessonPlanEntity> plans) {
    final subjects = _getUniqueSubjects(plans);

    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: Spacings.lg),
        children: [
          // Subject filter
          if (subjects.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: Spacings.sm),
              child: _buildFilterDropdown<String>(
                label: 'Subject',
                value: _filterSubject,
                items: subjects,
                itemLabel: (s) => s,
                onChanged: (v) => setState(() => _filterSubject = v),
              ),
            ),

          // Teaching style filter
          Padding(
            padding: const EdgeInsets.only(right: Spacings.sm),
            child: _buildFilterDropdown<TeachingStyle>(
              label: 'Teaching Style',
              value: _filterTeachingStyle,
              items: TeachingStyle.values,
              itemLabel: (s) => s.label,
              onChanged: (v) => setState(() => _filterTeachingStyle = v),
            ),
          ),

          // Student level filter
          Padding(
            padding: const EdgeInsets.only(right: Spacings.sm),
            child: _buildFilterDropdown<StudentLevel>(
              label: 'Student Level',
              value: _filterStudentLevel,
              items: StudentLevel.values,
              itemLabel: (l) => l.label,
              onChanged: (v) => setState(() => _filterStudentLevel = v),
            ),
          ),

          // Clear all filters
          if (_filterSubject != null ||
              _filterTeachingStyle != null ||
              _filterStudentLevel != null)
            Padding(
              padding: const EdgeInsets.only(right: Spacings.sm),
              child: ActionChip(
                label: const Text('Clear'),
                avatar: const Icon(Icons.clear, size: 16),
                onPressed: () {
                  setState(() {
                    _filterSubject = null;
                    _filterTeachingStyle = null;
                    _filterStudentLevel = null;
                  });
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFilterDropdown<T>({
    required String label,
    required T? value,
    required List<T> items,
    required String Function(T) itemLabel,
    required ValueChanged<T?> onChanged,
  }) {
    final cs = context.colorScheme;
    final isSelected = value != null;

    return InputChip(
      selected: isSelected,
      label: Text(
        isSelected ? itemLabel(value as T) : label,
        style: context.textTheme.labelMedium?.copyWith(
          color: isSelected ? cs.onPrimary : cs.onSurfaceVariant,
        ),
      ),
      avatar: Icon(
        Icons.filter_list_rounded,
        size: 16,
        color: isSelected ? cs.onPrimary : cs.onSurfaceVariant,
      ),
      onPressed: () => _showFilterSheet<T>(
        label: label,
        items: items,
        itemLabel: itemLabel,
        selectedValue: value,
        onSelected: onChanged,
      ),
      onDeleted: isSelected ? () => onChanged(null) : null,
      deleteIconColor: isSelected ? cs.onPrimary : null,
      selectedColor: cs.primary,
      backgroundColor: cs.surfaceContainerLow,
      side: BorderSide(
        color: isSelected ? cs.primary : cs.outlineVariant,
      ),
    );
  }

  void _showFilterSheet<T>({
    required String label,
    required List<T> items,
    required String Function(T) itemLabel,
    required T? selectedValue,
    required ValueChanged<T?> onSelected,
  }) {
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
                    'Filter by $label',
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
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: items.length,
                itemBuilder: (_, i) {
                  final item = items[i];
                  final isSelected = item == selectedValue;
                  return ListTile(
                    title: Text(itemLabel(item)),
                    trailing: isSelected
                        ? Icon(Icons.check_rounded, color: context.colorScheme.primary)
                        : null,
                    onTap: () {
                      onSelected(isSelected ? null : item);
                      Navigator.pop(ctx);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Results Count ───────────────────────────────────────────────────

  Widget _buildResultsCount(int count) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Spacings.lg),
      child: Text(
        '$count lesson plan${count != 1 ? 's' : ''}',
        style: context.textTheme.bodySmall?.copyWith(
          color: context.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }

  // ─── Lesson Plan Card ────────────────────────────────────────────────

  Widget _buildLessonPlanCard(LessonPlanEntity plan) {
    final cs = context.colorScheme;
    final isDark = context.isDarkMode;

    return AppCard(
      onTap: () => _navigateToDetail(plan.id),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top row: title + published badge
          Row(
            children: [
              Expanded(
                child: Text(
                  plan.title,
                  style: context.textTheme.titleSmall?.copyWith(
                    fontWeight: AppTypography.wSemiBold,
                    color: cs.onSurface,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (plan.isPublished)
                Container(
                  margin: const EdgeInsets.only(left: Spacings.sm),
                  padding: const EdgeInsets.symmetric(
                    horizontal: Spacings.sm,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: cs.primary.withValues(alpha: isDark ? 0.20 : 0.10),
                    borderRadius: BorderRadius.circular(Spacings.fullRadius),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.public_rounded, size: 12, color: cs.primary),
                      const SizedBox(width: 2),
                      Text(
                        'Published',
                        style: context.textTheme.labelSmall?.copyWith(
                          color: cs.primary,
                          fontWeight: AppTypography.wSemiBold,
                        ),
                      ),
                    ],
                  ),
                ),
              if (plan.isAiGenerated && !plan.isPublished)
                Container(
                  margin: const EdgeInsets.only(left: Spacings.sm),
                  padding: const EdgeInsets.symmetric(
                    horizontal: Spacings.sm,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: cs.tertiaryContainer,
                    borderRadius: BorderRadius.circular(Spacings.fullRadius),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.auto_awesome, size: 12, color: cs.onTertiaryContainer),
                      const SizedBox(width: 2),
                      Text(
                        'AI',
                        style: context.textTheme.labelSmall?.copyWith(
                          color: cs.onTertiaryContainer,
                          fontWeight: AppTypography.wSemiBold,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: Spacings.sm),

          // Subject + Class
          Text(
            '${plan.subject}${plan.className != null ? ' · ${plan.className}' : ''}',
            style: context.textTheme.bodyMedium?.copyWith(
              color: cs.onSurfaceVariant,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),

          // Chips row
          const SizedBox(height: Spacings.sm),
          Wrap(
            spacing: Spacings.sm,
            runSpacing: Spacings.xs,
            children: [
              _buildChip(
                icon: Icons.psychology_outlined,
                label: plan.teachingStyle.label,
                color: cs.secondary,
              ),
              _buildChip(
                icon: Icons.timer_outlined,
                label: '${plan.durationMinutes} min',
                color: cs.tertiary,
              ),
              _buildChip(
                icon: Icons.people_outlined,
                label: plan.studentLevel.label,
                color: cs.primary,
              ),
            ],
          ),

          const SizedBox(height: Spacings.md),

          // Created date
          Text(
            'Created ${_formatDate(plan.createdAt)}',
            style: context.textTheme.bodySmall?.copyWith(
              color: cs.onSurfaceVariant,
            ),
          ),

          const SizedBox(height: Spacings.md),

          // Action buttons row
          Row(
            children: [
              AppButton(
                label: 'Edit',
                onPressed: () => _navigateToDetail(plan.id),
                variant: AppButtonVariant.text,
                icon: Icons.edit_outlined,
                size: AppButtonSize.small,
              ),
              const SizedBox(width: Spacings.xs),
              AppButton(
                label: 'Delete',
                onPressed: () => _confirmDelete(plan),
                variant: AppButtonVariant.text,
                icon: Icons.delete_outline_rounded,
                size: AppButtonSize.small,
              ),
              const Spacer(),
              if (!plan.isPublished)
                AppButton(
                  label: 'Publish',
                  onPressed: () => _handlePublish(plan.id),
                  variant: AppButtonVariant.tonal,
                  icon: Icons.public_rounded,
                  size: AppButtonSize.small,
                ),
              const SizedBox(width: Spacings.xs),
              GenerateQuestionsButton(
                resourceType: 'lesson_plan',
                resourceId: plan.id,
                compact: true,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChip({
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

  // ─── States ──────────────────────────────────────────────────────────

  Widget _buildLoadingShimmer() {
    return ListView.builder(
      padding: Spacings.paddingScreen,
      itemCount: 5,
      itemBuilder: (_, __) => Padding(
        padding: const EdgeInsets.only(bottom: Spacings.md),
        child: AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const AppLoadingShimmer.box(width: 200, height: 16),
                  const Spacer(),
                  const AppLoadingShimmer.box(width: 60, height: 20),
                ],
              ),
              const SizedBox(height: Spacings.sm),
              const AppLoadingShimmer.box(width: 150, height: 14),
              const SizedBox(height: Spacings.sm),
              Row(
                children: const [
                  AppLoadingShimmer.box(width: 80, height: 22),
                  SizedBox(width: Spacings.sm),
                  AppLoadingShimmer.box(width: 60, height: 22),
                  SizedBox(width: Spacings.sm),
                  AppLoadingShimmer.box(width: 70, height: 22),
                ],
              ),
              const SizedBox(height: Spacings.md),
              const AppLoadingShimmer.box(width: 120, height: 12),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return AppEmptyState(
      icon: Icons.description_outlined,
      title: 'No Lesson Plans Yet',
      subtitle: 'Create your first lesson plan with AI assistance or start from scratch.',
      actionLabel: 'Create Lesson Plan',
      onAction: _navigateToGenerator,
    );
  }

  Widget _buildErrorState() {
    return AppErrorState.genericError(
      message: ref.read(lessonPlanProvider).error,
      onRetry: _handleRefresh,
    );
  }

  // ─── Dialogs ─────────────────────────────────────────────────────────

  void _confirmDelete(LessonPlanEntity plan) {
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
            onPressed: () {
              Navigator.pop(ctx);
              _handleDelete(plan.id);
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

  // ─── Date Formatting ─────────────────────────────────────────────────

  String _formatDate(DateTime date) {
    const months = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[date.month]} ${date.day}, ${date.year}';
  }
}
