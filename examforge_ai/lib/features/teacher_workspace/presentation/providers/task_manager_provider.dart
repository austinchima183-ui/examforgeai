import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/logger.dart';
import '../../domain/entities/workspace_expansion_entities.dart';

// ═══════════════════════════════════════════════════════════════════════
// TASK MANAGER STATE
// ═══════════════════════════════════════════════════════════════════════

/// Immutable state snapshot for the task manager feature.
class TaskManagerState {
  const TaskManagerState({
    this.tasks = const [],
    this.isLoading = false,
    this.isCreating = false,
    this.isUpdating = false,
    this.isDeleting = false,
    this.error,
    this.successMessage,
  });

  /// The current list of tasks.
  final List<TaskEntity> tasks;

  /// Whether the initial load is in progress.
  final bool isLoading;

  /// Whether a create operation is in progress.
  final bool isCreating;

  /// Whether an update operation is in progress.
  final bool isUpdating;

  /// Whether a delete operation is in progress.
  final bool isDeleting;

  /// The most recent error message, or `null`.
  final String? error;

  /// A transient success message, or `null`.
  final String? successMessage;

  /// Whether any async operation is in progress.
  bool get isBusy => isLoading || isCreating || isUpdating || isDeleting;

  /// Number of pending tasks.
  int get pendingCount =>
      tasks.where((t) => t.status == TaskStatus.pending).length;

  /// Number of in-progress tasks.
  int get inProgressCount =>
      tasks.where((t) => t.status == TaskStatus.inProgress).length;

  /// Number of completed tasks.
  int get completedCount =>
      tasks.where((t) => t.status == TaskStatus.completed).length;

  /// Number of overdue tasks.
  int get overdueCount => tasks
      .where((t) =>
          t.dueDate != null &&
          t.dueDate!.isBefore(DateTime.now()) &&
          t.status != TaskStatus.completed,)
      .length;

  /// Creates a copy of this state with the given fields replaced.
  TaskManagerState copyWith({
    List<TaskEntity>? tasks,
    bool? isLoading,
    bool? isCreating,
    bool? isUpdating,
    bool? isDeleting,
    String? error,
    String? successMessage,
  }) {
    return TaskManagerState(
      tasks: tasks ?? this.tasks,
      isLoading: isLoading ?? this.isLoading,
      isCreating: isCreating ?? this.isCreating,
      isUpdating: isUpdating ?? this.isUpdating,
      isDeleting: isDeleting ?? this.isDeleting,
      error: error,
      successMessage: successMessage,
    );
  }

  /// Clears the current error message.
  TaskManagerState clearError() => copyWith(error: null);

  /// Clears the current success message.
  TaskManagerState clearSuccessMessage() => copyWith(successMessage: null);
}

// ═══════════════════════════════════════════════════════════════════════
// TASK MANAGER NOTIFIER
// ═══════════════════════════════════════════════════════════════════════

/// Riverpod [StateNotifier] that manages the task manager feature's state.
class TaskManagerNotifier extends StateNotifier<TaskManagerState> {
  TaskManagerNotifier() : super(const TaskManagerState());

  // ─── Load Tasks ─────────────────────────────────────────────────────

  /// Loads all tasks.
  Future<void> loadTasks() async {
    state = state.copyWith(isLoading: true, error: null);

    // TODO: Replace with actual use case call
    await Future.delayed(const Duration(milliseconds: 500));

    state = state.copyWith(
      isLoading: false,
      tasks: [],
      error: null,
    );
    AppLogger.info('Loaded tasks');
  }

  // ─── Create Task ────────────────────────────────────────────────────

  /// Creates a new task with the provided parameters.
  Future<void> createTask({
    required String title,
    String? description,
    required TaskPriority priority,
    required TaskCategory category,
    DateTime? dueDate,
    DateTime? reminderAt,
    List<SubtaskEntity> subtasks = const [],
  }) async {
    state = state.copyWith(isCreating: true, error: null);

    // TODO: Replace with actual create use case call
    await Future.delayed(const Duration(milliseconds: 300));

    final now = DateTime.now();
    final task = TaskEntity(
      id: 'task_${now.millisecondsSinceEpoch}',
      teacherId: 'current_teacher',
      title: title,
      description: description,
      priority: priority,
      status: TaskStatus.pending,
      category: category,
      dueDate: dueDate,
      reminderAt: reminderAt,
      subtasks: subtasks,
      createdAt: now,
      updatedAt: now,
    );

    final updatedList = [task, ...state.tasks];

    state = state.copyWith(
      isCreating: false,
      tasks: updatedList,
      successMessage: 'Task created successfully',
      error: null,
    );
    AppLogger.info('Task created: ${task.id}');
  }

  // ─── Update Task Status ─────────────────────────────────────────────

  /// Updates the status of a task.
  Future<void> updateTaskStatus(String taskId, TaskStatus newStatus) async {
    // Optimistically update
    final updatedList = state.tasks.map((t) {
      if (t.id == taskId) {
        return t.copyWith(
          status: newStatus,
          completedAt: newStatus == TaskStatus.completed ? DateTime.now() : null,
        );
      }
      return t;
    }).toList();

    state = state.copyWith(
      tasks: updatedList,
      successMessage: newStatus == TaskStatus.completed
          ? 'Task completed'
          : 'Task status updated',
      error: null,
    );

    // TODO: Replace with actual update use case call
    AppLogger.info('Task status updated: $taskId → ${newStatus.label}');
  }

  // ─── Update Task ────────────────────────────────────────────────────

  /// Updates a task entity.
  Future<void> updateTask(TaskEntity task) async {
    final updatedList = state.tasks.map((t) {
      return t.id == task.id ? task : t;
    }).toList();

    state = state.copyWith(
      tasks: updatedList,
      successMessage: 'Task updated',
      error: null,
    );

    // TODO: Replace with actual update use case call
    AppLogger.info('Task updated: ${task.id}');
  }

  // ─── Delete Task ────────────────────────────────────────────────────

  /// Deletes a task by [taskId].
  Future<void> deleteTask(String taskId) async {
    state = state.copyWith(isDeleting: true, error: null);

    // TODO: Replace with actual delete use case call
    await Future.delayed(const Duration(milliseconds: 300));

    final updatedList = state.tasks.where((t) => t.id != taskId).toList();

    state = state.copyWith(
      isDeleting: false,
      tasks: updatedList,
      successMessage: 'Task deleted',
      error: null,
    );
    AppLogger.info('Task deleted: $taskId');
  }

  // ─── Clear Error / Success ──────────────────────────────────────────

  void clearError() => state = state.clearError();
  void clearSuccessMessage() => state = state.clearSuccessMessage();
}

// ═══════════════════════════════════════════════════════════════════════
// TASK MANAGER PROVIDER
// ═══════════════════════════════════════════════════════════════════════

final taskManagerProvider =
    StateNotifierProvider<TaskManagerNotifier, TaskManagerState>((ref) {
  return TaskManagerNotifier();
});
