import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/utils/logger.dart';
import '../../domain/entities/student_portal_entities.dart';
import '../../domain/usecases/student_portal_usecases.dart';
import 'student_dashboard_provider.dart';

// ═══════════════════════════════════════════════════════════════════════
// STUDY PLANNER STATE
// ═══════════════════════════════════════════════════════════════════════

/// Immutable state snapshot for the Study Planner feature.
///
/// Tracks study plans, the currently selected plan with its tasks,
/// loading flags, selected date for filtering, and errors.
class StudyPlannerState {
  const StudyPlannerState({
    this.plans = const [],
    this.currentPlan,
    this.tasks = const [],
    this.isLoading = false,
    this.error,
    this.selectedDate,
    this._isSuggesting = false,
  });

  /// All study plans for the current student.
  final List<StudyPlanEntity> plans;

  /// The currently selected plan, or `null`.
  final StudyPlanEntity? currentPlan;

  /// Tasks for the currently selected plan, optionally filtered by date.
  final List<StudyTaskEntity> tasks;

  /// Whether a load or mutation operation is in progress.
  final bool isLoading;

  /// The most recent error message, or `null`.
  final String? error;

  /// The date used to filter tasks, or `null` for all tasks.
  final DateTime? selectedDate;

  /// Whether an AI suggestion operation is in progress.
  // ignore: unused_field
  final bool _isSuggesting;

  /// Whether an AI suggestion operation is in progress.
  bool get isSuggesting => _isSuggesting;

  /// Whether any async operation is in progress.
  bool get isBusy => isLoading || _isSuggesting;

  /// Number of plans loaded.
  int get planCount => plans.length;

  /// Active (non-completed) plans.
  List<StudyPlanEntity> get activePlans =>
      plans.where((p) => p.isActive).toList();

  /// Tasks filtered by [selectedDate], or all tasks if no date is set.
  List<StudyTaskEntity> get filteredTasks {
    if (selectedDate == null) return tasks;
    return tasks
        .where((t) =>
            t.scheduledDate.year == selectedDate!.year &&
            t.scheduledDate.month == selectedDate!.month &&
            t.scheduledDate.day == selectedDate!.day)
        .toList();
  }

  /// Creates a copy of this state with the given fields replaced.
  StudyPlannerState copyWith({
    List<StudyPlanEntity>? plans,
    StudyPlanEntity? currentPlan,
    List<StudyTaskEntity>? tasks,
    bool? isLoading,
    String? error,
    DateTime? selectedDate,
    bool? isSuggesting,
    bool clearCurrentPlan = false,
    bool clearSelectedDate = false,
  }) {
    return StudyPlannerState(
      plans: plans ?? this.plans,
      currentPlan: clearCurrentPlan
          ? null
          : (currentPlan ?? this.currentPlan),
      tasks: tasks ?? this.tasks,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      selectedDate:
          clearSelectedDate ? null : (selectedDate ?? this.selectedDate),
      _isSuggesting: isSuggesting ?? _isSuggesting,
    );
  }

  /// Clears the current error message.
  StudyPlannerState clearError() => copyWith(error: null);
}

// ═══════════════════════════════════════════════════════════════════════
// STUDY PLANNER NOTIFIER
// ═══════════════════════════════════════════════════════════════════════

/// Riverpod [StateNotifier] that manages the Study Planner feature's
/// state.
///
/// All study planner operations flow through this notifier, which:
/// 1. Sets the appropriate loading flag before each async operation
/// 2. Delegates to the appropriate use case
/// 3. Updates plans, tasks, and selection state on success
/// 4. Sets [error] on failure
class StudyPlannerNotifier extends StateNotifier<StudyPlannerState> {
  StudyPlannerNotifier({
    required GetStudyPlansUseCase getStudyPlans,
    required CreateStudyPlanUseCase createStudyPlan,
    required UpdateStudyTaskUseCase updateStudyTask,
    required SuggestStudyPlanUseCase suggestStudyPlan,
    required DeleteStudyPlanUseCase deleteStudyPlan,
    required String? studentId,
    required String? schoolId,
  })  : _getStudyPlans = getStudyPlans,
        _createStudyPlan = createStudyPlan,
        _updateStudyTask = updateStudyTask,
        _suggestStudyPlan = suggestStudyPlan,
        _deleteStudyPlan = deleteStudyPlan,
        _studentId = studentId,
        _schoolId = schoolId,
        super(StudyPlannerState(
          selectedDate: DateTime.now(),
        ));

  final GetStudyPlansUseCase _getStudyPlans;
  final CreateStudyPlanUseCase _createStudyPlan;
  final UpdateStudyTaskUseCase _updateStudyTask;
  final SuggestStudyPlanUseCase _suggestStudyPlan;
  final DeleteStudyPlanUseCase _deleteStudyPlan;
  final String? _studentId;
  final String? _schoolId;

  // ─── Load Plans ────────────────────────────────────────────────────

  /// Loads all study plans for the current student.
  Future<void> loadPlans() async {
    if (_studentId == null) return;

    state = state.copyWith(isLoading: true, error: null);

    final result = await _getStudyPlans(
      studentId: _studentId!,
      isActive: true,
    );

    result.fold(
      onSuccess: (plans) {
        state = state.copyWith(
          isLoading: false,
          plans: plans,
          error: null,
        );
        AppLogger.info('Loaded ${plans.length} study plans');
      },
      onFailure: (failure) {
        state = state.copyWith(
          isLoading: false,
          error: _mapFailureToMessage(failure),
        );
        AppLogger.warning('Failed to load study plans: $failure');
      },
    );
  }

  // ─── Open Plan ─────────────────────────────────────────────────────

  /// Opens a study plan, loading its tasks into the state.
  void openPlan(String planId) {
    final plan = state.plans.where((p) => p.id == planId).firstOrNull;
    if (plan == null) return;

    state = state.copyWith(
      currentPlan: plan,
      tasks: plan.tasks,
    );
    AppLogger.info(
      'Opened plan: $planId (${plan.tasks.length} tasks)',
    );
  }

  // ─── Create Plan ───────────────────────────────────────────────────

  /// Creates a new study plan with the given parameters.
  Future<void> createPlan({
    required String title,
    String? description,
    StudyPlanFrequency frequency = StudyPlanFrequency.daily,
    required DateTime startDate,
    DateTime? endDate,
    List<StudyTaskEntity> tasks = const [],
  }) async {
    if (_studentId == null) return;

    state = state.copyWith(isLoading: true, error: null);

    final result = await _createStudyPlan(
      studentId: _studentId!,
      schoolId: _schoolId,
      title: title,
      description: description,
      frequency: frequency,
      startDate: startDate,
      endDate: endDate,
      tasks: tasks,
    );

    result.fold(
      onSuccess: (plan) {
        final updatedList = [plan, ...state.plans];
        state = state.copyWith(
          isLoading: false,
          plans: updatedList,
          currentPlan: plan,
          tasks: plan.tasks,
          error: null,
        );
        AppLogger.info('Created study plan: ${plan.id}');
      },
      onFailure: (failure) {
        state = state.copyWith(
          isLoading: false,
          error: _mapFailureToMessage(failure),
        );
        AppLogger.warning('Failed to create study plan: $failure');
      },
    );
  }

  // ─── Delete Plan ───────────────────────────────────────────────────

  /// Deletes a study plan by ID.
  Future<void> deletePlan(String planId) async {
    state = state.copyWith(isLoading: true, error: null);

    final result = await _deleteStudyPlan(planId: planId);

    result.fold(
      onSuccess: (_) {
        final updatedList =
            state.plans.where((p) => p.id != planId).toList();
        state = state.copyWith(
          isLoading: false,
          plans: updatedList,
          currentPlan: state.currentPlan?.id == planId
              ? null
              : state.currentPlan,
          tasks: state.currentPlan?.id == planId
              ? const []
              : state.tasks,
          error: null,
        );
        AppLogger.info('Deleted study plan: $planId');
      },
      onFailure: (failure) {
        state = state.copyWith(
          isLoading: false,
          error: _mapFailureToMessage(failure),
        );
        AppLogger.warning('Failed to delete study plan: $failure');
      },
    );
  }

  // ─── Create Task ───────────────────────────────────────────────────

  /// Creates a new task within the current study plan.
  /// Note: Requires a CreateStudyTaskUseCase in the repository.
  /// This method optimistically adds the task to local state.
  Future<void> createTask({
    required String title,
    String? subjectId,
    String? description,
    required DateTime scheduledDate,
    DateTime? startTime,
    DateTime? endTime,
  }) async {
    final plan = state.currentPlan;
    if (plan == null) return;

    state = state.copyWith(isLoading: true, error: null);

    // Optimistically create a local task placeholder.
    final now = DateTime.now();
    final localTask = StudyTaskEntity(
      id: 'local_${now.millisecondsSinceEpoch}',
      planId: plan.id,
      subjectId: subjectId,
      title: title,
      description: description,
      scheduledDate: scheduledDate,
      startTime: startTime,
      endTime: endTime,
      status: StudyTaskStatus.pending,
      completionPct: 0,
      createdAt: now,
      updatedAt: now,
    );

    final updatedTasks = [...state.tasks, localTask];
    final updatedPlan = plan.copyWith(tasks: updatedTasks);

    state = state.copyWith(
      isLoading: false,
      tasks: updatedTasks,
      currentPlan: updatedPlan,
      plans: state.plans
          .map((p) => p.id == plan.id ? updatedPlan : p)
          .toList(),
      error: null,
    );
    AppLogger.info('Created task: ${localTask.id}');
  }

  // ─── Update Task Status ────────────────────────────────────────────

  /// Updates a study task's status and completion percentage.
  Future<void> updateTaskStatus(
    String taskId, {
    StudyTaskStatus? status,
    double? completionPct,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    final result = await _updateStudyTask(
      taskId: taskId,
      status: status,
      completionPct: completionPct,
    );

    result.fold(
      onSuccess: (updatedTask) {
        final updatedTasks = state.tasks
            .map((t) => t.id == taskId ? updatedTask : t)
            .toList();

        // Also update the plan's task list if a plan is selected.
        StudyPlanEntity? updatedPlan;
        if (state.currentPlan != null) {
          updatedPlan = state.currentPlan!.copyWith(
            tasks: updatedTasks,
          );
        }

        state = state.copyWith(
          isLoading: false,
          tasks: updatedTasks,
          currentPlan: updatedPlan ?? state.currentPlan,
          plans: updatedPlan != null
              ? state.plans
                  .map((p) => p.id == updatedPlan!.id ? updatedPlan : p)
                  .toList()
              : state.plans,
          error: null,
        );
        AppLogger.info('Updated task $taskId status: $status');
      },
      onFailure: (failure) {
        state = state.copyWith(
          isLoading: false,
          error: _mapFailureToMessage(failure),
        );
        AppLogger.warning('Failed to update task: $failure');
      },
    );
  }

  // ─── Delete Task ───────────────────────────────────────────────────

  /// Removes a task from the current plan's local list.
  void deleteTask(String taskId) {
    final updatedTasks =
        state.tasks.where((t) => t.id != taskId).toList();

    StudyPlanEntity? updatedPlan;
    if (state.currentPlan != null) {
      updatedPlan = state.currentPlan!.copyWith(tasks: updatedTasks);
    }

    state = state.copyWith(
      tasks: updatedTasks,
      currentPlan: updatedPlan ?? state.currentPlan,
      plans: updatedPlan != null
          ? state.plans
              .map((p) => p.id == updatedPlan!.id ? updatedPlan : p)
              .toList()
          : state.plans,
    );
    AppLogger.info('Removed task: $taskId');
  }

  // ─── Suggest Plan (AI) ─────────────────────────────────────────────

  /// Requests an AI-suggested study plan based on the student's
  /// progress and the given focus subject.
  Future<void> suggestPlan({String? focusSubjectId}) async {
    if (_studentId == null) return;

    state = state.copyWith(isSuggesting: true, error: null);

    final result = await _suggestStudyPlan(
      studentId: _studentId!,
      schoolId: _schoolId,
      focusSubjectId: focusSubjectId,
    );

    result.fold(
      onSuccess: (suggestedPlan) {
        final updatedList = [suggestedPlan, ...state.plans];
        state = state.copyWith(
          isSuggesting: false,
          plans: updatedList,
          currentPlan: suggestedPlan,
          tasks: suggestedPlan.tasks,
          error: null,
        );
        AppLogger.info(
          'AI suggested study plan: ${suggestedPlan.id}',
        );
      },
      onFailure: (failure) {
        state = state.copyWith(
          isSuggesting: false,
          error: _mapFailureToMessage(failure),
        );
        AppLogger.warning(
          'Failed to suggest study plan: $failure',
        );
      },
    );
  }

  // ─── Select Date ───────────────────────────────────────────────────

  /// Selects a date to filter tasks for that specific date.
  /// Pass `null` to show all tasks.
  void selectDate(DateTime? date) {
    state = date == null
        ? state.copyWith(clearSelectedDate: true)
        : state.copyWith(selectedDate: date);
  }

  // ─── Clear Error ───────────────────────────────────────────────────

  /// Clears the current error message from the state.
  void clearError() {
    state = state.clearError();
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
// STUDY PLANNER PROVIDER
// ═══════════════════════════════════════════════════════════════════════

/// Provides the [StudyPlannerNotifier] with all required use cases.
final studyPlannerProvider =
    StateNotifierProvider<StudyPlannerNotifier, StudyPlannerState>((ref) {
  return StudyPlannerNotifier(
    getStudyPlans: ref.watch(getStudyPlansUseCaseProvider),
    createStudyPlan: ref.watch(createStudyPlanUseCaseProvider),
    updateStudyTask: ref.watch(updateStudyTaskUseCaseProvider),
    suggestStudyPlan: ref.watch(suggestStudyPlanUseCaseProvider),
    deleteStudyPlan: ref.watch(deleteStudyPlanUseCaseProvider),
    studentId: ref.watch(currentStudentIdProvider),
    schoolId: ref.watch(studentSchoolIdProvider),
  );
});
