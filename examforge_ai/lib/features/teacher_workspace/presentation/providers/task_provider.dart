import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/utils/logger.dart';
import '../../domain/entities/workspace_expansion_entities.dart';
import '../../domain/usecases/create_task_usecase.dart';
import '../../domain/usecases/delete_task_usecase.dart';
import '../../domain/usecases/get_tasks_usecase.dart';
import '../../domain/usecases/update_task_usecase.dart';

// ═══════════════════════════════════════════════════════════════════════
// TASK STATE
// ═══════════════════════════════════════════════════════════════════════

/// Immutable state snapshot for the task feature.
///
/// Tracks the current list of tasks, loading flags for each operation,
/// filter criteria, and the currently selected task.
class TaskState {
  const TaskState({
    this.tasks = const [],
    this.isLoading = false,
    this.isCreating = false,
    this.isUpdating = false,
    this.error,
    this.currentTask,
    this.filterByStatus,
    this.filterByCategory,
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

  /// The most recent error message, or `null`.
  final String? error;

  /// The currently selected task with full details, or `null`.
  final TaskEntity? currentTask;

  /// The status filter applied to the task list.
  final String? filterByStatus;

  /// The category filter applied to the task list.
  final String? filterByCategory;

  /// A transient success message (e.g. "Task created"), or `null`.
  final String? successMessage;

  /// Whether any async operation is in progress.
  bool get isBusy => isLoading || isCreating || isUpdating;

  /// Creates a copy of this state with the given fields replaced.
  TaskState copyWith({
    List<TaskEntity>? tasks,
    bool? isLoading,
    bool? isCreating,
    bool? isUpdating,
    String? error,
    TaskEntity? currentTask,
    String? filterByStatus,
    String? filterByCategory,
    String? successMessage,
  }) {
    return TaskState(
      tasks: tasks ?? this.tasks,
      isLoading: isLoading ?? this.isLoading,
      isCreating: isCreating ?? this.isCreating,
      isUpdating: isUpdating ?? this.isUpdating,
      error: error,
      currentTask: currentTask ?? this.currentTask,
      filterByStatus: filterByStatus ?? this.filterByStatus,
      filterByCategory: filterByCategory ?? this.filterByCategory,
      successMessage: successMessage,
    );
  }

  /// Clears the current error message.
  TaskState clearError() => copyWith(error: null);

  /// Clears the current success message.
  TaskState clearSuccessMessage() => copyWith(successMessage: null);
}

// ═══════════════════════════════════════════════════════════════════════
// TASK NOTIFIER
// ═══════════════════════════════════════════════════════════════════════

/// Riverpod [StateNotifier] that manages the task feature's state.
///
/// All task operations flow through this notifier, which:
/// 1. Sets the appropriate loading flag before each async operation
/// 2. Delegates to the appropriate use case
/// 3. Updates the task list and filter state on success
/// 4. Sets [error] on failure
class TaskNotifier extends StateNotifier<TaskState> {
  TaskNotifier({
    required GetTasksUseCase getTasksUseCase,
    required CreateTaskUseCase createTaskUseCase,
    required UpdateTaskUseCase updateTaskUseCase,
    required DeleteTaskUseCase deleteTaskUseCase,
  })  : _getTasksUseCase = getTasksUseCase,
        _createTaskUseCase = createTaskUseCase,
        _updateTaskUseCase = updateTaskUseCase,
        _deleteTaskUseCase = deleteTaskUseCase,
        super(const TaskState());

  final GetTasksUseCase _getTasksUseCase;
  final CreateTaskUseCase _createTaskUseCase;
  final UpdateTaskUseCase _updateTaskUseCase;
  final DeleteTaskUseCase _deleteTaskUseCase;

  // ─── Load Tasks ──────────────────────────────────────────────────

  /// Loads the list of tasks using the provided optional filters.
  Future<void> loadTasks({
    String? status,
    String? category,
    DateTime? dueBefore,
  }) async {
    state = state.copyWith(
      isLoading: true,
      error: null,
      filterByStatus: status ?? state.filterByStatus,
      filterByCategory: category ?? state.filterByCategory,
    );

    final result = await _getTasksUseCase(
      GetTasksParams(
        status: state.filterByStatus,
        category: state.filterByCategory,
        dueBefore: dueBefore,
      ),
    );

    result.fold(
      onSuccess: (tasks) {
        state = state.copyWith(
          isLoading: false,
          tasks: tasks,
          error: null,
        );
        AppLogger.info('Loaded ${tasks.length} tasks');
      },
      onFailure: (failure) {
        state = state.copyWith(
          isLoading: false,
          error: _mapFailureToMessage(failure),
        );
        AppLogger.warning('Failed to load tasks: $failure');
      },
    );
  }

  // ─── Create Task ─────────────────────────────────────────────────

  /// Creates a new task with the provided [params].
  Future<void> createTask(CreateTaskParams params) async {
    state = state.copyWith(isCreating: true, error: null);

    final result = await _createTaskUseCase(params);

    result.fold(
      onSuccess: (task) {
        final updatedList = [task, ...state.tasks];
        state = state.copyWith(
          isCreating: false,
          tasks: updatedList,
          successMessage: 'Task created successfully',
          error: null,
        );
        AppLogger.info('Task created: ${task.id}');
      },
      onFailure: (failure) {
        state = state.copyWith(
          isCreating: false,
          error: _mapFailureToMessage(failure),
        );
        AppLogger.warning('Failed to create task: $failure');
      },
    );
  }

  // ─── Update Task ─────────────────────────────────────────────────

  /// Updates an existing task with the provided [params].
  Future<void> updateTask(UpdateTaskParams params) async {
    state = state.copyWith(isUpdating: true, error: null);

    final result = await _updateTaskUseCase(params);

    result.fold(
      onSuccess: (updatedTask) {
        final updatedList = state.tasks
            .map((t) => t.id == updatedTask.id ? updatedTask : t)
            .toList();
        state = state.copyWith(
          isUpdating: false,
          tasks: updatedList,
          currentTask: state.currentTask?.id == updatedTask.id
              ? updatedTask
              : state.currentTask,
          successMessage: 'Task updated successfully',
          error: null,
        );
        AppLogger.info('Task updated: ${updatedTask.id}');
      },
      onFailure: (failure) {
        state = state.copyWith(
          isUpdating: false,
          error: _mapFailureToMessage(failure),
        );
        AppLogger.warning('Failed to update task: $failure');
      },
    );
  }

  // ─── Delete Task ─────────────────────────────────────────────────

  /// Deletes a task by [taskId].
  Future<void> deleteTask(String taskId) async {
    final result = await _deleteTaskUseCase(
      DeleteTaskParams(taskId: taskId),
    );

    result.fold(
      onSuccess: (_) {
        final updatedList =
            state.tasks.where((t) => t.id != taskId).toList();
        state = state.copyWith(
          tasks: updatedList,
          currentTask: state.currentTask?.id == taskId
              ? null
              : state.currentTask,
          successMessage: 'Task deleted successfully',
          error: null,
        );
        AppLogger.info('Task deleted: $taskId');
      },
      onFailure: (failure) {
        state = state.copyWith(
          error: _mapFailureToMessage(failure),
        );
        AppLogger.warning('Failed to delete task: $failure');
      },
    );
  }

  // ─── Complete Task ───────────────────────────────────────────────

  /// Marks a task as completed with optional [notes].
  Future<void> completeTask(String id, String? notes) async {
    final task = state.tasks.where((t) => t.id == id).firstOrNull;
    if (task == null) {
      state = state.copyWith(error: 'Task not found');
      return;
    }

    final updatedTask = task.copyWith(
      status: TaskStatus.completed,
      completionNotes: notes,
    );

    state = state.copyWith(isUpdating: true, error: null);

    final result = await _updateTaskUseCase(
      UpdateTaskParams(task: updatedTask),
    );

    result.fold(
      onSuccess: (completedTask) {
        final updatedList = state.tasks
            .map((t) => t.id == completedTask.id ? completedTask : t)
            .toList();
        state = state.copyWith(
          isUpdating: false,
          tasks: updatedList,
          currentTask: state.currentTask?.id == completedTask.id
              ? completedTask
              : state.currentTask,
          successMessage: 'Task completed successfully',
          error: null,
        );
        AppLogger.info('Task completed: $id');
      },
      onFailure: (failure) {
        state = state.copyWith(
          isUpdating: false,
          error: _mapFailureToMessage(failure),
        );
        AppLogger.warning('Failed to complete task: $failure');
      },
    );
  }

  // ─── Set Current Task ────────────────────────────────────────────

  /// Sets the currently selected task.
  void setCurrentTask(TaskEntity? task) {
    state = state.copyWith(currentTask: task);
  }

  // ─── Clear Error ─────────────────────────────────────────────────

  /// Clears the current error message from the state.
  void clearError() {
    state = state.clearError();
  }

  // ─── Clear Success Message ───────────────────────────────────────

  /// Clears the current success message from the state.
  void clearSuccessMessage() {
    state = state.clearSuccessMessage();
  }

  // ═══════════════════════════════════════════════════════════════════════
  // PRIVATE HELPERS
  // ═══════════════════════════════════════════════════════════════════════

  /// Maps a [Failure] to a user-friendly error message.
  String _mapFailureToMessage(Failure failure) {
    return failure.when(
      server: (message, _, __) => message,
      cache: (message) => message,
      auth: (message, _) => message,
      network: (message) => message,
      validation: (message, _) => message,
      notFound: (message) => message,
      unauthorized: (message) => message,
      forbidden: (message) => message,
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// TASK PROVIDER
// ═══════════════════════════════════════════════════════════════════════

final taskProvider =
    StateNotifierProvider<TaskNotifier, TaskState>((ref) {
  return TaskNotifier(
    getTasksUseCase: ref.watch(getTasksUseCaseProvider),
    createTaskUseCase: ref.watch(createTaskUseCaseProvider),
    updateTaskUseCase: ref.watch(updateTaskUseCaseProvider),
    deleteTaskUseCase: ref.watch(deleteTaskUseCaseProvider),
  );
});
