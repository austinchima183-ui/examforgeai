import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../config/dependency_injection.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/utils/logger.dart';
import '../../domain/entities/student_portal_entities.dart';
import '../../domain/usecases/student_portal_usecases.dart';
import 'student_dashboard_provider.dart';

// ═══════════════════════════════════════════════════════════════════════
// GOALS STATE
// ═══════════════════════════════════════════════════════════════════════

/// Immutable state snapshot for the Student Goals feature.
///
/// Tracks the list of goals, loading flags, active filter, and errors.
class GoalsState {
  const GoalsState({
    this.goals = const [],
    this.isLoading = false,
    this.error,
    this.filterStatus,
  });

  /// All goals for the current student.
  final List<StudentGoalEntity> goals;

  /// Whether a load or mutation operation is in progress.
  final bool isLoading;

  /// The most recent error message, or `null`.
  final String? error;

  /// Optional filter on goal status.
  final GoalStatus? filterStatus;

  /// Whether any async operation is in progress.
  bool get isBusy => isLoading;

  /// Number of goals loaded.
  int get goalCount => goals.length;

  /// Goals filtered by [filterStatus], or all if no filter is set.
  List<StudentGoalEntity> get filteredGoals {
    if (filterStatus == null) return goals;
    return goals.where((g) => g.status == filterStatus).toList();
  }

  /// Number of active (in-progress) goals.
  int get activeGoalCount =>
      goals.where((g) => g.status == GoalStatus.inProgress).length;

  /// Number of achieved goals.
  int get achievedGoalCount =>
      goals.where((g) => g.status == GoalStatus.achieved).length;

  /// Overall average progress across all goals.
  double get averageProgress {
    if (goals.isEmpty) return 0;
    return goals
            .map((g) => g.progressPct)
            .reduce((a, b) => a + b) /
        goals.length;
  }

  /// Creates a copy of this state with the given fields replaced.
  GoalsState copyWith({
    List<StudentGoalEntity>? goals,
    bool? isLoading,
    String? error,
    GoalStatus? filterStatus,
    bool clearFilterStatus = false,
  }) {
    return GoalsState(
      goals: goals ?? this.goals,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      filterStatus:
          clearFilterStatus ? null : (filterStatus ?? this.filterStatus),
    );
  }

  /// Clears the current error message.
  GoalsState clearError() => copyWith(error: null);
}

// ═══════════════════════════════════════════════════════════════════════
// GOALS NOTIFIER
// ═══════════════════════════════════════════════════════════════════════

/// Riverpod [StateNotifier] that manages the Student Goals feature's
/// state.
///
/// All goal operations flow through this notifier, which:
/// 1. Sets [isLoading] before each async operation
/// 2. Delegates to the appropriate use case
/// 3. Updates the goals list on success
/// 4. Sets [error] on failure
class GoalsNotifier extends StateNotifier<GoalsState> {
  GoalsNotifier({
    required GetGoalsUseCase getGoals,
    required CreateGoalUseCase createGoal,
    required UpdateGoalUseCase updateGoal,
    required String? studentId,
    required String? schoolId,
  })  : _getGoals = getGoals,
        _createGoal = createGoal,
        _updateGoal = updateGoal,
        _studentId = studentId,
        _schoolId = schoolId,
        super(const GoalsState());

  final GetGoalsUseCase _getGoals;
  final CreateGoalUseCase _createGoal;
  final UpdateGoalUseCase _updateGoal;
  final String? _studentId;
  final String? _schoolId;

  // ─── Load Goals ────────────────────────────────────────────────────

  /// Loads all goals for the current student, optionally filtered by
  /// [filterStatus].
  Future<void> loadGoals() async {
    if (_studentId == null) return;

    state = state.copyWith(isLoading: true, error: null);

    final result = await _getGoals(
      studentId: _studentId!,
      status: state.filterStatus,
    );

    result.fold(
      onSuccess: (goals) {
        state = state.copyWith(
          isLoading: false,
          goals: goals,
          error: null,
        );
        AppLogger.info('Loaded ${goals.length} goals');
      },
      onFailure: (failure) {
        state = state.copyWith(
          isLoading: false,
          error: _mapFailureToMessage(failure),
        );
        AppLogger.warning('Failed to load goals: $failure');
      },
    );
  }

  // ─── Create Goal ───────────────────────────────────────────────────

  /// Creates a new goal with the given parameters.
  Future<void> createGoal({
    required String title,
    String? subjectId,
    String? description,
    double? targetValue,
    String unit = '%',
    GoalPriority priority = GoalPriority.medium,
    DateTime? deadline,
  }) async {
    if (_studentId == null) return;

    state = state.copyWith(isLoading: true, error: null);

    final result = await _createGoal(
      studentId: _studentId!,
      schoolId: _schoolId,
      subjectId: subjectId,
      title: title,
      description: description,
      targetValue: targetValue,
      unit: unit,
      priority: priority,
      deadline: deadline,
    );

    result.fold(
      onSuccess: (goal) {
        final updatedList = [goal, ...state.goals];
        state = state.copyWith(
          isLoading: false,
          goals: updatedList,
          error: null,
        );
        AppLogger.info('Created goal: ${goal.id}');
      },
      onFailure: (failure) {
        state = state.copyWith(
          isLoading: false,
          error: _mapFailureToMessage(failure),
        );
        AppLogger.warning('Failed to create goal: $failure');
      },
    );
  }

  // ─── Update Goal ───────────────────────────────────────────────────

  /// Updates a goal's current value, priority, or status.
  Future<void> updateGoal(
    String goalId, {
    double? currentValue,
    GoalPriority? priority,
    GoalStatus? status,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    final result = await _updateGoal(
      goalId: goalId,
      currentValue: currentValue,
      priority: priority,
      status: status,
    );

    result.fold(
      onSuccess: (updatedGoal) {
        final updatedList = state.goals
            .map((g) => g.id == goalId ? updatedGoal : g)
            .toList();

        state = state.copyWith(
          isLoading: false,
          goals: updatedList,
          error: null,
        );
        AppLogger.info('Updated goal: $goalId');
      },
      onFailure: (failure) {
        state = state.copyWith(
          isLoading: false,
          error: _mapFailureToMessage(failure),
        );
        AppLogger.warning('Failed to update goal: $failure');
      },
    );
  }

  // ─── Delete Goal ───────────────────────────────────────────────────

  /// Removes a goal from the local list.
  /// Note: Actual deletion requires a DeleteGoalUseCase.
  void deleteGoal(String goalId) {
    final updatedList =
        state.goals.where((g) => g.id != goalId).toList();
    state = state.copyWith(goals: updatedList);
    AppLogger.info('Removed goal: $goalId');
  }

  // ─── Filter by Status ──────────────────────────────────────────────

  /// Filters goals by [status] and reloads the list.
  /// Pass `null` to clear the filter.
  Future<void> filterByStatus(GoalStatus? status) async {
    state = status == null
        ? state.copyWith(clearFilterStatus: true)
        : state.copyWith(filterStatus: status);
    await loadGoals();
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
// GOALS PROVIDER
// ═══════════════════════════════════════════════════════════════════════

/// Provides the [GoalsNotifier] with all required use cases.
final goalsProvider =
    StateNotifierProvider<GoalsNotifier, GoalsState>((ref) {
  return GoalsNotifier(
    getGoals: ref.watch(getGoalsUseCaseProvider),
    createGoal: ref.watch(createGoalUseCaseProvider),
    updateGoal: ref.watch(updateGoalUseCaseProvider),
    studentId: ref.watch(currentStudentIdProvider),
    schoolId: ref.watch(studentSchoolIdProvider),
  );
});
