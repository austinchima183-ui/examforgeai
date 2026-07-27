import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/themes/app_colors.dart';
import '../../../../core/themes/app_typography.dart';
import '../../../../core/themes/spacings.dart';
import '../../../../shared/widgets/app_app_bar.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/app_dialog.dart';
import '../../../../shared/widgets/app_empty_state.dart';
import '../../../../shared/widgets/app_error_state.dart';
import '../../../../shared/widgets/app_loading.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../domain/entities/workspace_expansion_entities.dart';
import '../providers/task_manager_provider.dart';

// ═══════════════════════════════════════════════════════════════════════
// TASK MANAGER PAGE
// ═══════════════════════════════════════════════════════════════════════

/// Task Manager page with to-do lists, summary counts, tab-based filtering,
/// category chips, and a bottom sheet for adding new tasks.
class TaskManagerPage extends ConsumerStatefulWidget {
  const TaskManagerPage({super.key});

  @override
  ConsumerState<TaskManagerPage> createState() => _TaskManagerPageState();
}

class _TaskManagerPageState extends ConsumerState<TaskManagerPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  TaskCategory? _filterCategory;

  static const _tabs = [
    Tab(text: 'All'),
    Tab(text: 'Pending'),
    Tab(text: 'In Progress'),
    Tab(text: 'Completed'),
  ];

  // ─── Add Task Bottom Sheet Controllers ───────────────────────────────

  final _addTaskFormKey = GlobalKey<FormState>();
  final _taskTitleCtrl = TextEditingController();
  final _taskDescCtrl = TextEditingController();
  TaskPriority _taskPriority = TaskPriority.medium;
  TaskCategory _taskCategory = TaskCategory.general;
  DateTime? _taskDueDate;
  bool _taskHasReminder = false;
  TimeOfDay? _taskReminderTime;
  final List<String> _taskSubtasks = [];
  final _subtaskInputCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {});
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(taskManagerProvider.notifier).loadTasks();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _taskTitleCtrl.dispose();
    _taskDescCtrl.dispose();
    _subtaskInputCtrl.dispose();
    super.dispose();
  }

  // ─── Helpers ─────────────────────────────────────────────────────────

  void _listenForMessages() {
    final state = ref.read(taskManagerProvider);
    if (state.successMessage != null) {
      _showSnackBar(state.successMessage!, isError: false);
      ref.read(taskManagerProvider.notifier).clearSuccessMessage();
    }
    if (state.error != null) {
      _showSnackBar(state.error!, isError: true);
      ref.read(taskManagerProvider.notifier).clearError();
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

  List<TaskEntity> _applyFilters(List<TaskEntity> tasks) {
    var filtered = tasks;

    // Tab filter
    final tabIndex = _tabController.index;
    switch (tabIndex) {
      case 1: // Pending
        filtered = filtered.where((t) => t.status == TaskStatus.pending).toList();
        break;
      case 2: // In Progress
        filtered = filtered.where((t) => t.status == TaskStatus.inProgress).toList();
        break;
      case 3: // Completed
        filtered = filtered.where((t) => t.status == TaskStatus.completed).toList();
        break;
    }

    // Category filter
    if (_filterCategory != null) {
      filtered = filtered.where((t) => t.category == _filterCategory).toList();
    }

    return filtered;
  }

  Future<void> _handleRefresh() async {
    await ref.read(taskManagerProvider.notifier).loadTasks();
    _listenForMessages();
  }

  void _handleToggleComplete(TaskEntity task) {
    final newStatus = task.status == TaskStatus.completed
        ? TaskStatus.pending
        : TaskStatus.completed;

    ref.read(taskManagerProvider.notifier).updateTaskStatus(
          task.id,
          newStatus,
        );
    _listenForMessages();
  }

  void _handleDeleteTask(String taskId) {
    ref.read(taskManagerProvider.notifier).deleteTask(taskId);
    _listenForMessages();
  }

  void _handleToggleSubtask(TaskEntity task, int subtaskIndex) {
    final updatedSubtasks = task.subtasks
        .asMap()
        .entries
        .map((e) => e.key == subtaskIndex
            ? e.value.copyWith(isCompleted: !e.value.isCompleted)
            : e.value,)
        .toList();

    ref.read(taskManagerProvider.notifier).updateTask(
          task.copyWith(subtasks: updatedSubtasks),
        );
  }

  // ─── Add Task ────────────────────────────────────────────────────────

  void _showAddTaskBottomSheet() {
    // Reset form
    _taskTitleCtrl.clear();
    _taskDescCtrl.clear();
    _taskPriority = TaskPriority.medium;
    _taskCategory = TaskCategory.general;
    _taskDueDate = null;
    _taskHasReminder = false;
    _taskReminderTime = null;
    _taskSubtasks.clear();
    _subtaskInputCtrl.clear();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(Spacings.lgRadius)),
      ),
      builder: (ctx) => _buildAddTaskSheet(),
    );
  }

  void _handleSaveTask() {
    if (!_addTaskFormKey.currentState!.validate()) return;

    final subtasks = _taskSubtasks
        .map((title) => SubtaskEntity(title: title))
        .toList();

    ref.read(taskManagerProvider.notifier).createTask(
          title: _taskTitleCtrl.text.trim(),
          description: _taskDescCtrl.text.trim().isNotEmpty
              ? _taskDescCtrl.text.trim()
              : null,
          priority: _taskPriority,
          category: _taskCategory,
          dueDate: _taskDueDate,
          reminderAt: _taskHasReminder && _taskDueDate != null && _taskReminderTime != null
              ? DateTime(
                  _taskDueDate!.year,
                  _taskDueDate!.month,
                  _taskDueDate!.day,
                  _taskReminderTime!.hour,
                  _taskReminderTime!.minute,
                )
              : null,
          subtasks: subtasks,
        );

    Navigator.of(context).pop();
    _listenForMessages();
  }

  // ─── Build ───────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(taskManagerProvider);

    return Scaffold(
      appBar: AppAppBar(
        title: 'Task Manager',
        bottom: TabBar(
          controller: _tabController,
          tabs: _tabs,
          labelStyle: context.textTheme.labelLarge?.copyWith(
            fontWeight: AppTypography.wSemiBold,
          ),
          unselectedLabelStyle: context.textTheme.labelLarge?.copyWith(
            fontWeight: AppTypography.wMedium,
          ),
        ),
      ),
      body: state.isLoading
          ? _buildLoadingShimmer()
          : state.error != null && state.tasks.isEmpty
              ? _buildErrorState()
              : _buildContent(state),
      floatingActionButton: AppFloatingActionButton(
        label: 'Add Task',
        icon: Icons.add_rounded,
        onPressed: _showAddTaskBottomSheet,
        extended: true,
      ),
    );
  }

  // ─── Content ─────────────────────────────────────────────────────────

  Widget _buildContent(TaskManagerState state) {
    return Column(
      children: [
        // Summary row
        _buildSummaryRow(state.tasks),
        const SizedBox(height: Spacings.sm),

        // Category filter chips
        _buildCategoryChips(),

        // Tab content
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: List.generate(
              _tabs.length,
              (_) => _buildTabContent(state),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTabContent(TaskManagerState state) {
    final filteredTasks = _applyFilters(state.tasks);

    return RefreshIndicator(
      onRefresh: _handleRefresh,
      child: filteredTasks.isEmpty
          ? _buildEmptyStateForTab()
          : ListView.builder(
              padding: const EdgeInsets.symmetric(
                horizontal: Spacings.lg,
                vertical: Spacings.sm,
              ),
              itemCount: filteredTasks.length,
              itemBuilder: (ctx, index) => Padding(
                padding: const EdgeInsets.only(bottom: Spacings.md),
                child: _buildTaskCard(filteredTasks[index]),
              ),
            ),
    );
  }

  // ─── Summary Row ─────────────────────────────────────────────────────

  Widget _buildSummaryRow(List<TaskEntity> tasks) {
    final pendingCount = tasks.where((t) => t.status == TaskStatus.pending).length;
    final inProgressCount = tasks.where((t) => t.status == TaskStatus.inProgress).length;
    final completedCount = tasks.where((t) => t.status == TaskStatus.completed).length;
    final overdueCount = tasks
        .where((t) =>
            t.dueDate != null &&
            t.dueDate!.isBefore(DateTime.now()) &&
            t.status != TaskStatus.completed,)
        .length;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: Spacings.lg,
        vertical: Spacings.sm,
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildSummaryCard(
              label: 'Pending',
              count: pendingCount,
              color: AppColors.warning,
              icon: Icons.pending_outlined,
            ),
          ),
          const SizedBox(width: Spacings.sm),
          Expanded(
            child: _buildSummaryCard(
              label: 'In Progress',
              count: inProgressCount,
              color: AppColors.info,
              icon: Icons.autorenew_rounded,
            ),
          ),
          const SizedBox(width: Spacings.sm),
          Expanded(
            child: _buildSummaryCard(
              label: 'Completed',
              count: completedCount,
              color: AppColors.success,
              icon: Icons.check_circle_outline_rounded,
            ),
          ),
          const SizedBox(width: Spacings.sm),
          Expanded(
            child: _buildSummaryCard(
              label: 'Overdue',
              count: overdueCount,
              color: AppColors.error,
              icon: Icons.warning_amber_rounded,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard({
    required String label,
    required int count,
    required Color color,
    required IconData icon,
  }) {
    final cs = context.colorScheme;
    final isDark = context.isDarkMode;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Spacings.sm,
        vertical: Spacings.md,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.15 : 0.08),
        borderRadius: BorderRadius.circular(Spacings.mdRadius),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        children: [
          Icon(icon, size: Spacings.mdIcon, color: color),
          const SizedBox(height: Spacings.xs),
          Text(
            '$count',
            style: context.textTheme.titleMedium?.copyWith(
              fontWeight: AppTypography.wBold,
              color: color,
            ),
          ),
          Text(
            label,
            style: context.textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: AppTypography.wSemiBold,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  // ─── Category Filter Chips ───────────────────────────────────────────

  Widget _buildCategoryChips() {
    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: Spacings.lg),
        children: [
          _buildCategoryChip(
            label: 'All',
            isSelected: _filterCategory == null,
            onTap: () => setState(() => _filterCategory = null),
          ),
          const SizedBox(width: Spacings.sm),
          ...TaskCategory.values.map((cat) => Padding(
                padding: const EdgeInsets.only(right: Spacings.sm),
                child: _buildCategoryChip(
                  label: cat.label,
                  isSelected: _filterCategory == cat,
                  onTap: () => setState(() => _filterCategory = cat),
                ),
              ),),
        ],
      ),
    );
  }

  Widget _buildCategoryChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final cs = context.colorScheme;

    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onTap(),
      showCheckmark: false,
      selectedColor: cs.primaryContainer,
      labelStyle: context.textTheme.labelMedium?.copyWith(
        color: isSelected ? cs.onPrimaryContainer : cs.onSurfaceVariant,
        fontWeight: isSelected ? AppTypography.wSemiBold : AppTypography.wRegular,
      ),
    );
  }

  // ─── Task Card ───────────────────────────────────────────────────────

  Widget _buildTaskCard(TaskEntity task) {
    final cs = context.colorScheme;
    final isDark = context.isDarkMode;
    final isOverdue = task.dueDate != null &&
        task.dueDate!.isBefore(DateTime.now()) &&
        task.status != TaskStatus.completed;
    final isCompleted = task.status == TaskStatus.completed;
    final completedSubtasks = task.subtasks.where((s) => s.isCompleted).length;

    return Dismissible(
      key: ValueKey(task.id),
      direction: DismissDirection.endToStart,
      confirmDismiss: (direction) async {
        return await AppDialog.showConfirm(
          context: context,
          title: 'Delete Task',
          message: 'Are you sure you want to delete "${task.title}"?',
          confirmText: 'Delete',
          isDestructive: true,
        );
      },
      onDismissed: (_) => _handleDeleteTask(task.id),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: Spacings.xl),
        decoration: BoxDecoration(
          color: cs.error,
          borderRadius: BorderRadius.circular(Spacings.mdRadius),
        ),
        child: Icon(Icons.delete_rounded, color: cs.onError),
      ),
      child: AppCard(
        onTap: () => _showTaskDetailBottomSheet(task),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top row: checkbox + title + priority badge
            Row(
              children: [
                // Checkbox
                GestureDetector(
                  onTap: () => _handleToggleComplete(task),
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isCompleted
                          ? AppColors.success
                          : Colors.transparent,
                      border: Border.all(
                        color: isCompleted
                            ? AppColors.success
                            : cs.outline,
                        width: 2,
                      ),
                    ),
                    child: isCompleted
                        ? const Icon(Icons.check, size: 16, color: Colors.white)
                        : null,
                  ),
                ),
                const SizedBox(width: Spacings.md),

                // Title
                Expanded(
                  child: Text(
                    task.title,
                    style: context.textTheme.titleSmall?.copyWith(
                      fontWeight: AppTypography.wSemiBold,
                      color: isCompleted
                          ? cs.onSurfaceVariant
                          : cs.onSurface,
                      decoration: isCompleted
                          ? TextDecoration.lineThrough
                          : null,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),

                // Priority color badge
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: _priorityColor(task.priority),
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),

            // Description preview
            if (task.description != null && task.description!.isNotEmpty) ...[
              const SizedBox(height: Spacings.sm),
              Text(
                task.description!,
                style: context.textTheme.bodySmall?.copyWith(
                  color: cs.onSurfaceVariant,
                  height: 1.4,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],

            const SizedBox(height: Spacings.md),

            // Bottom row: due date + category chip + subtask progress
            Row(
              children: [
                // Due date with overdue highlighting
                if (task.dueDate != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: Spacings.sm,
                      vertical: Spacings.xs,
                    ),
                    decoration: BoxDecoration(
                      color: isOverdue
                          ? AppColors.error.withValues(alpha: isDark ? 0.20 : 0.10)
                          : cs.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(Spacings.fullRadius),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isOverdue
                              ? Icons.warning_amber_rounded
                              : Icons.calendar_today_outlined,
                          size: 12,
                          color: isOverdue ? AppColors.error : cs.onSurfaceVariant,
                        ),
                        const SizedBox(width: Spacings.xs),
                        Text(
                          _formatDate(task.dueDate!),
                          style: context.textTheme.labelSmall?.copyWith(
                            color: isOverdue ? AppColors.error : cs.onSurfaceVariant,
                            fontWeight: isOverdue
                                ? AppTypography.wSemiBold
                                : AppTypography.wRegular,
                          ),
                        ),
                      ],
                    ),
                  ),

                const SizedBox(width: Spacings.sm),

                // Category chip
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: Spacings.sm,
                    vertical: Spacings.xs,
                  ),
                  decoration: BoxDecoration(
                    color: cs.secondaryContainer.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(Spacings.fullRadius),
                  ),
                  child: Text(
                    task.category.label,
                    style: context.textTheme.labelSmall?.copyWith(
                      color: cs.onSecondaryContainer,
                    ),
                  ),
                ),

                const Spacer(),

                // Subtask progress
                if (task.subtasks.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: Spacings.sm,
                      vertical: Spacings.xs,
                    ),
                    decoration: BoxDecoration(
                      color: cs.tertiaryContainer.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(Spacings.fullRadius),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.checklist_rounded,
                          size: 12,
                          color: cs.onTertiaryContainer,
                        ),
                        const SizedBox(width: Spacings.xs),
                        Text(
                          '$completedSubtasks/${task.subtasks.length}',
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
          ],
        ),
      ),
    );
  }

  // ─── Task Detail Bottom Sheet ────────────────────────────────────────

  void _showTaskDetailBottomSheet(TaskEntity task) {
    final cs = context.colorScheme;
    final isDark = context.isDarkMode;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(Spacings.lgRadius)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: Spacings.lg,
          right: Spacings.lg,
          top: Spacings.lg,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + Spacings.lg,
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: cs.outlineVariant,
                    borderRadius: BorderRadius.circular(Spacings.fullRadius),
                  ),
                ),
              ),
              const SizedBox(height: Spacings.lg),

              // Title
              Text(
                task.title,
                style: context.textTheme.headlineSmall?.copyWith(
                  fontWeight: AppTypography.wBold,
                  color: cs.onSurface,
                ),
              ),
              const SizedBox(height: Spacings.md),

              // Meta info
              Wrap(
                spacing: Spacings.sm,
                runSpacing: Spacings.sm,
                children: [
                  _buildBadge(
                    icon: Icons.flag_rounded,
                    label: task.priority.label,
                    color: _priorityColor(task.priority),
                  ),
                  _buildBadge(
                    icon: Icons.category_outlined,
                    label: task.category.label,
                    color: cs.secondary,
                  ),
                  _buildBadge(
                    icon: Icons.info_outline_rounded,
                    label: task.status.label,
                    color: cs.tertiary,
                  ),
                  if (task.dueDate != null)
                    _buildBadge(
                      icon: Icons.calendar_today_outlined,
                      label: _formatDate(task.dueDate!),
                      color: task.dueDate!.isBefore(DateTime.now()) &&
                              task.status != TaskStatus.completed
                          ? AppColors.error
                          : cs.primary,
                    ),
                ],
              ),
              const SizedBox(height: Spacings.lg),

              // Description
              if (task.description != null && task.description!.isNotEmpty) ...[
                Text(
                  'Description',
                  style: context.textTheme.titleSmall?.copyWith(
                    fontWeight: AppTypography.wSemiBold,
                    color: cs.onSurface,
                  ),
                ),
                const SizedBox(height: Spacings.sm),
                Text(
                  task.description!,
                  style: context.textTheme.bodyMedium?.copyWith(
                    color: cs.onSurfaceVariant,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: Spacings.lg),
              ],

              // Subtasks
              if (task.subtasks.isNotEmpty) ...[
                Row(
                  children: [
                    Text(
                      'Subtasks',
                      style: context.textTheme.titleSmall?.copyWith(
                        fontWeight: AppTypography.wSemiBold,
                        color: cs.onSurface,
                      ),
                    ),
                    const SizedBox(width: Spacings.sm),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: Spacings.sm,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: cs.tertiaryContainer,
                        borderRadius: BorderRadius.circular(Spacings.fullRadius),
                      ),
                      child: Text(
                        '${task.subtasks.where((s) => s.isCompleted).length}/${task.subtasks.length}',
                        style: context.textTheme.labelSmall?.copyWith(
                          color: cs.onTertiaryContainer,
                          fontWeight: AppTypography.wSemiBold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: Spacings.sm),
                ...task.subtasks.asMap().entries.map((entry) {
                  final i = entry.key;
                  final subtask = entry.value;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: Spacings.sm),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: () {
                            _handleToggleSubtask(task, i);
                            Navigator.of(ctx).pop();
                          },
                          child: Container(
                            width: 20,
                            height: 20,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: subtask.isCompleted
                                  ? AppColors.success
                                  : Colors.transparent,
                              border: Border.all(
                                color: subtask.isCompleted
                                    ? AppColors.success
                                    : cs.outline,
                                width: 2,
                              ),
                            ),
                            child: subtask.isCompleted
                                ? const Icon(Icons.check, size: 12, color: Colors.white)
                                : null,
                          ),
                        ),
                        const SizedBox(width: Spacings.sm),
                        Expanded(
                          child: Text(
                            subtask.title,
                            style: context.textTheme.bodyMedium?.copyWith(
                              color: subtask.isCompleted
                                  ? cs.onSurfaceVariant
                                  : cs.onSurface,
                              decoration: subtask.isCompleted
                                  ? TextDecoration.lineThrough
                                  : null,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
                const SizedBox(height: Spacings.lg),
              ],

              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: AppButton(
                      label: task.status == TaskStatus.completed
                          ? 'Reopen'
                          : 'Complete',
                      onPressed: () {
                        _handleToggleComplete(task);
                        Navigator.of(ctx).pop();
                      },
                      variant: AppButtonVariant.elevated,
                      icon: task.status == TaskStatus.completed
                          ? Icons.replay_rounded
                          : Icons.check_rounded,
                      fullWidth: true,
                    ),
                  ),
                  const SizedBox(width: Spacings.sm),
                  Expanded(
                    child: AppButton(
                      label: 'Delete',
                      onPressed: () async {
                        final confirmed = await AppDialog.showConfirm(
                          context: context,
                          title: 'Delete Task',
                          message: 'Are you sure you want to delete "${task.title}"?',
                          confirmText: 'Delete',
                          isDestructive: true,
                        );
                        if (confirmed == true) {
                          _handleDeleteTask(task.id);
                          if (ctx.mounted) Navigator.of(ctx).pop();
                        }
                      },
                      variant: AppButtonVariant.outlined,
                      icon: Icons.delete_outline_rounded,
                      fullWidth: true,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBadge({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    final isDark = context.isDarkMode;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Spacings.sm,
        vertical: Spacings.xs,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.20 : 0.10),
        borderRadius: BorderRadius.circular(Spacings.fullRadius),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
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

  // ─── Add Task Bottom Sheet ───────────────────────────────────────────

  Widget _buildAddTaskSheet() {
    final cs = context.colorScheme;

    return Padding(
      padding: EdgeInsets.only(
        left: Spacings.lg,
        right: Spacings.lg,
        top: Spacings.lg,
        bottom: MediaQuery.of(context).viewInsets.bottom + Spacings.lg,
      ),
      child: Form(
        key: _addTaskFormKey,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: cs.outlineVariant,
                    borderRadius: BorderRadius.circular(Spacings.fullRadius),
                  ),
                ),
              ),
              const SizedBox(height: Spacings.lg),

              // Title
              Text(
                'Add New Task',
                style: context.textTheme.headlineSmall?.copyWith(
                  fontWeight: AppTypography.wBold,
                  color: cs.onSurface,
                ),
              ),
              Spacings.sectionGap,

              // Task Title
              AppTextField(
                label: 'Title',
                hint: 'e.g. Grade SS2 Mathematics exam',
                controller: _taskTitleCtrl,
                prefixIcon: Icons.title_outlined,
                isRequired: true,
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Title is required' : null,
              ),
              Spacings.itemGap,

              // Description
              AppTextField(
                label: 'Description',
                hint: 'Optional details about this task...',
                controller: _taskDescCtrl,
                prefixIcon: Icons.description_outlined,
                maxLines: 3,
                minLines: 1,
              ),
              Spacings.itemGap,

              // Priority dropdown
              AppDropdownField<TaskPriority>(
                label: 'Priority',
                items: TaskPriority.values,
                selectedItem: _taskPriority,
                onChanged: (v) {
                  if (v != null) setState(() => _taskPriority = v);
                },
                itemLabel: (p) => p.label,
                prefixIcon: Icons.flag_outlined,
              ),
              Spacings.itemGap,

              // Category dropdown
              AppDropdownField<TaskCategory>(
                label: 'Category',
                items: TaskCategory.values,
                selectedItem: _taskCategory,
                onChanged: (v) {
                  if (v != null) setState(() => _taskCategory = v);
                },
                itemLabel: (c) => c.label,
                prefixIcon: Icons.category_outlined,
              ),
              Spacings.itemGap,

              // Due Date
              AppDateField(
                label: 'Due Date',
                selectedDate: _taskDueDate,
                onDateSelected: (date) => setState(() => _taskDueDate = date),
              ),
              Spacings.itemGap,

              // Reminder toggle + time picker
              Row(
                children: [
                  Switch(
                    value: _taskHasReminder,
                    onChanged: (v) => setState(() => _taskHasReminder = v),
                  ),
                  const SizedBox(width: Spacings.sm),
                  Expanded(
                    child: Text(
                      'Set Reminder',
                      style: context.textTheme.bodyLarge?.copyWith(
                        color: cs.onSurface,
                      ),
                    ),
                  ),
                  if (_taskHasReminder)
                    TextButton(
                      onPressed: () async {
                        final time = await showTimePicker(
                          context: context,
                          initialTime: _taskReminderTime ?? TimeOfDay.now(),
                        );
                        if (time != null) {
                          setState(() => _taskReminderTime = time);
                        }
                      },
                      child: Text(
                        _taskReminderTime != null
                            ? _taskReminderTime!.format(context)
                            : 'Pick Time',
                      ),
                    ),
                ],
              ),
              Spacings.itemGap,

              // Subtasks
              Text(
                'Subtasks',
                style: context.textTheme.titleSmall?.copyWith(
                  fontWeight: AppTypography.wSemiBold,
                  color: cs.onSurface,
                ),
              ),
              const SizedBox(height: Spacings.sm),

              // Subtask list
              ..._taskSubtasks.asMap().entries.map((entry) {
                final i = entry.key;
                final subtask = entry.value;
                return Padding(
                  padding: const EdgeInsets.only(bottom: Spacings.sm),
                  child: Row(
                    children: [
                      Icon(Icons.subdirectory_arrow_right_rounded, size: 16, color: cs.onSurfaceVariant),
                      const SizedBox(width: Spacings.sm),
                      Expanded(
                        child: Text(
                          subtask,
                          style: context.textTheme.bodyMedium?.copyWith(
                            color: cs.onSurface,
                          ),
                        ),
                      ),
                      AppIconButton(
                        icon: Icons.close_rounded,
                        onPressed: () => setState(() => _taskSubtasks.removeAt(i)),
                        variant: AppIconButtonVariant.standard,
                        size: AppButtonSize.small,
                      ),
                    ],
                  ),
                );
              }),

              // Add subtask input
              Row(
                children: [
                  Expanded(
                    child: AppTextField(
                      controller: _subtaskInputCtrl,
                      hint: 'Add a subtask...',
                      onFieldSubmitted: (value) {
                        if (value.trim().isNotEmpty) {
                          setState(() {
                            _taskSubtasks.add(value.trim());
                            _subtaskInputCtrl.clear();
                          });
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: Spacings.sm),
                  AppIconButton(
                    icon: Icons.add_rounded,
                    onPressed: () {
                      if (_subtaskInputCtrl.text.trim().isNotEmpty) {
                        setState(() {
                          _taskSubtasks.add(_subtaskInputCtrl.text.trim());
                          _subtaskInputCtrl.clear();
                        });
                      }
                    },
                    variant: AppIconButtonVariant.filled,
                  ),
                ],
              ),
              Spacings.sectionGap,

              // Save button
              AppButton(
                label: 'Save Task',
                onPressed: _handleSaveTask,
                variant: AppButtonVariant.elevated,
                icon: Icons.save_rounded,
                isLoading: ref.watch(taskManagerProvider).isCreating,
                fullWidth: true,
                size: AppButtonSize.large,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Loading / Error / Empty ─────────────────────────────────────────

  Widget _buildLoadingShimmer() {
    return ListView.builder(
      padding: const EdgeInsets.all(Spacings.lg),
      itemCount: 5,
      itemBuilder: (ctx, i) => const Padding(
        padding: EdgeInsets.only(bottom: Spacings.md),
        child: AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  AppLoadingShimmer.box(width: 24, height: 24),
                  SizedBox(width: Spacings.md),
                  Expanded(child: AppLoadingShimmer.box(width: double.infinity, height: 16)),
                  SizedBox(width: Spacings.sm),
                  AppLoadingShimmer.box(width: 12, height: 12),
                ],
              ),
              SizedBox(height: Spacings.md),
              AppLoadingShimmer.box(width: double.infinity, height: 14),
              SizedBox(height: Spacings.sm),
              Row(
                children: [
                  AppLoadingShimmer.box(width: 80, height: 12),
                  SizedBox(width: Spacings.sm),
                  AppLoadingShimmer.box(width: 60, height: 12),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return AppErrorState(
      icon: Icons.cloud_off_rounded,
      title: 'Something Went Wrong',
      message: ref.read(taskManagerProvider).error ?? 'Failed to load tasks',
      onRetry: _handleRefresh,
    );
  }

  Widget _buildEmptyStateForTab() {
    final tabIndex = _tabController.index;
    String title;
    String subtitle;
    IconData icon;

    switch (tabIndex) {
      case 1: // Pending
        icon = Icons.pending_outlined;
        title = 'No Pending Tasks';
        subtitle = 'All tasks are in progress or completed';
        break;
      case 2: // In Progress
        icon = Icons.autorenew_rounded;
        title = 'No In-Progress Tasks';
        subtitle = 'Start working on pending tasks';
        break;
      case 3: // Completed
        icon = Icons.check_circle_outline_rounded;
        title = 'No Completed Tasks';
        subtitle = 'Complete tasks to see them here';
        break;
      default: // All
        icon = Icons.task_outlined;
        title = _filterCategory != null
            ? 'No Matching Tasks'
            : 'No Tasks Yet';
        subtitle = _filterCategory != null
            ? 'Try adjusting your category filter'
            : 'Add your first task to get started';
    }

    return AppEmptyState(
      icon: icon,
      title: title,
      subtitle: subtitle,
      actionLabel: 'Add Task',
      onAction: _showAddTaskBottomSheet,
    );
  }

  // ─── Utilities ───────────────────────────────────────────────────────

  Color _priorityColor(TaskPriority priority) {
    switch (priority) {
      case TaskPriority.low:
        return AppColors.success;
      case TaskPriority.medium:
        return AppColors.warning;
      case TaskPriority.high:
        return Colors.orange;
      case TaskPriority.urgent:
        return AppColors.error;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final targetDate = DateTime(date.year, date.month, date.day);
    final diff = targetDate.difference(today).inDays;

    if (diff == 0) return 'Today';
    if (diff == 1) return 'Tomorrow';
    if (diff == -1) return 'Yesterday';
    if (diff > 0 && diff <= 7) return 'In $diff days';
    if (diff < 0 && diff >= -7) return '${-diff} days ago';
    return '${date.day}/${date.month}/${date.year}';
  }
}
