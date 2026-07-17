import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/utils/logger.dart';
import '../../domain/entities/teacher_workspace_entities.dart';
import '../../domain/usecases/create_lesson_plan_usecase.dart';
import '../../domain/usecases/delete_lesson_plan_usecase.dart';
import '../../domain/usecases/generate_lesson_plan_usecase.dart';
import '../../domain/usecases/get_lesson_plans_usecase.dart';
import '../../domain/usecases/update_lesson_plan_usecase.dart';

// ═══════════════════════════════════════════════════════════════════════
// LESSON PLAN STATE
// ═══════════════════════════════════════════════════════════════════════

/// Immutable state snapshot for the lesson plan feature.
///
/// Tracks the current list of lesson plans, pagination state, loading flags
/// for each operation, the active filter, and the currently selected plan.
class LessonPlanState {
  const LessonPlanState({
    this.lessonPlans = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.isCreating = false,
    this.isUpdating = false,
    this.isDeleting = false,
    this.isGenerating = false,
    this.error,
    this.currentPlan,
    this.totalCount = 0,
    this.currentPage = 1,
    this.hasMore = true,
    this.filter = const WorkspaceFilterEntity(),
    this.successMessage,
  });

  /// The current page of lesson plans.
  final List<LessonPlanEntity> lessonPlans;

  /// Whether the initial page load is in progress.
  final bool isLoading;

  /// Whether a pagination (load-more) request is in progress.
  final bool isLoadingMore;

  /// Whether a create operation is in progress.
  final bool isCreating;

  /// Whether an update operation is in progress.
  final bool isUpdating;

  /// Whether a delete operation is in progress.
  final bool isDeleting;

  /// Whether an AI generation operation is in progress.
  final bool isGenerating;

  /// The most recent error message, or `null`.
  final String? error;

  /// The currently selected lesson plan with full details, or `null`.
  final LessonPlanEntity? currentPlan;

  /// Total number of lesson plans matching the current filter.
  final int totalCount;

  /// The current page number (1-based).
  final int currentPage;

  /// Whether there are more pages to load.
  final bool hasMore;

  /// The active filter criteria.
  final WorkspaceFilterEntity filter;

  /// A transient success message (e.g. "Lesson plan created"), or `null`.
  final String? successMessage;

  /// Number of lesson plans currently loaded.
  int get loadedCount => lessonPlans.length;

  /// Whether any async operation is in progress.
  bool get isBusy =>
      isLoading || isLoadingMore || isCreating || isUpdating || isDeleting || isGenerating;

  /// Creates a copy of this state with the given fields replaced.
  LessonPlanState copyWith({
    List<LessonPlanEntity>? lessonPlans,
    bool? isLoading,
    bool? isLoadingMore,
    bool? isCreating,
    bool? isUpdating,
    bool? isDeleting,
    bool? isGenerating,
    String? error,
    LessonPlanEntity? currentPlan,
    int? totalCount,
    int? currentPage,
    bool? hasMore,
    WorkspaceFilterEntity? filter,
    String? successMessage,
  }) {
    return LessonPlanState(
      lessonPlans: lessonPlans ?? this.lessonPlans,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      isCreating: isCreating ?? this.isCreating,
      isUpdating: isUpdating ?? this.isUpdating,
      isDeleting: isDeleting ?? this.isDeleting,
      isGenerating: isGenerating ?? this.isGenerating,
      error: error,
      currentPlan: currentPlan ?? this.currentPlan,
      totalCount: totalCount ?? this.totalCount,
      currentPage: currentPage ?? this.currentPage,
      hasMore: hasMore ?? this.hasMore,
      filter: filter ?? this.filter,
      successMessage: successMessage,
    );
  }

  /// Clears the current error message.
  LessonPlanState clearError() => copyWith(error: null);

  /// Clears the current success message.
  LessonPlanState clearSuccessMessage() => copyWith(successMessage: null);
}

// ═══════════════════════════════════════════════════════════════════════
// LESSON PLAN NOTIFIER
// ═══════════════════════════════════════════════════════════════════════

/// Riverpod [StateNotifier] that manages the lesson plan feature's state.
///
/// All lesson plan operations flow through this notifier, which:
/// 1. Sets the appropriate loading flag before each async operation
/// 2. Delegates to the appropriate use case
/// 3. Updates the lesson plan list, pagination, and filter state on success
/// 4. Sets [error] on failure
class LessonPlanNotifier extends StateNotifier<LessonPlanState> {
  LessonPlanNotifier({
    required GetLessonPlansUseCase getLessonPlansUseCase,
    required CreateLessonPlanUseCase createLessonPlanUseCase,
    required UpdateLessonPlanUseCase updateLessonPlanUseCase,
    required DeleteLessonPlanUseCase deleteLessonPlanUseCase,
    required GenerateLessonPlanUseCase generateLessonPlanUseCase,
  })  : _getLessonPlansUseCase = getLessonPlansUseCase,
        _createLessonPlanUseCase = createLessonPlanUseCase,
        _updateLessonPlanUseCase = updateLessonPlanUseCase,
        _deleteLessonPlanUseCase = deleteLessonPlanUseCase,
        _generateLessonPlanUseCase = generateLessonPlanUseCase,
        super(const LessonPlanState());

  final GetLessonPlansUseCase _getLessonPlansUseCase;
  final CreateLessonPlanUseCase _createLessonPlanUseCase;
  final UpdateLessonPlanUseCase _updateLessonPlanUseCase;
  final DeleteLessonPlanUseCase _deleteLessonPlanUseCase;
  final GenerateLessonPlanUseCase _generateLessonPlanUseCase;

  // ─── Load Lesson Plans (first page) ────────────────────────────────

  /// Loads the first page of lesson plans using the current filter.
  Future<void> loadLessonPlans() async {
    state = state.copyWith(isLoading: true, error: null);

    final filter = state.filter.copyWith(page: 1);
    final result = await _getLessonPlansUseCase(
      GetLessonPlansParams(filter: filter),
    );

    result.fold(
      onSuccess: (plans) {
        state = state.copyWith(
          isLoading: false,
          lessonPlans: plans,
          currentPage: 1,
          hasMore: plans.length >= state.filter.perPage,
          error: null,
        );
        AppLogger.info('Loaded ${plans.length} lesson plans (page 1)');
      },
      onFailure: (failure) {
        state = state.copyWith(
          isLoading: false,
          error: _mapFailureToMessage(failure),
        );
        AppLogger.warning('Failed to load lesson plans: $failure');
      },
    );
  }

  // ─── Load More Lesson Plans (pagination) ───────────────────────────

  /// Loads the next page of lesson plans and appends to the existing list.
  Future<void> loadMore() async {
    if (state.isLoadingMore || !state.hasMore) return;

    state = state.copyWith(isLoadingMore: true, error: null);

    final nextPage = state.currentPage + 1;
    final filter = state.filter.copyWith(page: nextPage);
    final result = await _getLessonPlansUseCase(
      GetLessonPlansParams(filter: filter),
    );

    result.fold(
      onSuccess: (plans) {
        final updatedList = [...state.lessonPlans, ...plans];
        state = state.copyWith(
          isLoadingMore: false,
          lessonPlans: updatedList,
          currentPage: nextPage,
          hasMore: plans.length >= state.filter.perPage,
          error: null,
        );
        AppLogger.info(
          'Loaded ${plans.length} more lesson plans (page $nextPage)',
        );
      },
      onFailure: (failure) {
        state = state.copyWith(
          isLoadingMore: false,
          error: _mapFailureToMessage(failure),
        );
        AppLogger.warning('Failed to load more lesson plans: $failure');
      },
    );
  }

  // ─── Create Lesson Plan ────────────────────────────────────────────

  /// Creates a new lesson plan with the provided [params].
  Future<void> createLessonPlan(CreateLessonPlanParams params) async {
    state = state.copyWith(isCreating: true, error: null);

    final result = await _createLessonPlanUseCase(params);

    result.fold(
      onSuccess: (plan) {
        final updatedList = [plan, ...state.lessonPlans];
        state = state.copyWith(
          isCreating: false,
          lessonPlans: updatedList,
          successMessage: 'Lesson plan created successfully',
          error: null,
        );
        AppLogger.info('Lesson plan created: ${plan.id}');
      },
      onFailure: (failure) {
        state = state.copyWith(
          isCreating: false,
          error: _mapFailureToMessage(failure),
        );
        AppLogger.warning('Failed to create lesson plan: $failure');
      },
    );
  }

  // ─── Update Lesson Plan ────────────────────────────────────────────

  /// Updates an existing lesson plan with the provided [params].
  Future<void> updateLessonPlan(UpdateLessonPlanParams params) async {
    state = state.copyWith(isUpdating: true, error: null);

    final result = await _updateLessonPlanUseCase(params);

    result.fold(
      onSuccess: (updatedPlan) {
        final updatedList = state.lessonPlans
            .map((p) => p.id == updatedPlan.id ? updatedPlan : p)
            .toList();
        state = state.copyWith(
          isUpdating: false,
          lessonPlans: updatedList,
          currentPlan: state.currentPlan?.id == updatedPlan.id
              ? updatedPlan
              : state.currentPlan,
          successMessage: 'Lesson plan updated successfully',
          error: null,
        );
        AppLogger.info('Lesson plan updated: ${updatedPlan.id}');
      },
      onFailure: (failure) {
        state = state.copyWith(
          isUpdating: false,
          error: _mapFailureToMessage(failure),
        );
        AppLogger.warning('Failed to update lesson plan: $failure');
      },
    );
  }

  // ─── Delete Lesson Plan ────────────────────────────────────────────

  /// Deletes a lesson plan by [planId].
  Future<void> deleteLessonPlan(String planId) async {
    state = state.copyWith(isDeleting: true, error: null);

    final result = await _deleteLessonPlanUseCase(
      DeleteLessonPlanParams(planId: planId),
    );

    result.fold(
      onSuccess: (_) {
        final updatedList =
            state.lessonPlans.where((p) => p.id != planId).toList();
        state = state.copyWith(
          isDeleting: false,
          lessonPlans: updatedList,
          currentPlan: state.currentPlan?.id == planId
              ? null
              : state.currentPlan,
          successMessage: 'Lesson plan deleted successfully',
          error: null,
        );
        AppLogger.info('Lesson plan deleted: $planId');
      },
      onFailure: (failure) {
        state = state.copyWith(
          isDeleting: false,
          error: _mapFailureToMessage(failure),
        );
        AppLogger.warning('Failed to delete lesson plan: $failure');
      },
    );
  }

  // ─── Generate Lesson Plan (AI) ─────────────────────────────────────

  /// Generates a lesson plan using AI with the provided [params].
  Future<void> generateLessonPlan(GenerateLessonPlanParams params) async {
    state = state.copyWith(isGenerating: true, error: null);

    final result = await _generateLessonPlanUseCase(params);

    result.fold(
      onSuccess: (plan) {
        final updatedList = [plan, ...state.lessonPlans];
        state = state.copyWith(
          isGenerating: false,
          lessonPlans: updatedList,
          currentPlan: plan,
          successMessage: 'Lesson plan generated successfully',
          error: null,
        );
        AppLogger.info('Lesson plan generated: ${plan.id}');
      },
      onFailure: (failure) {
        state = state.copyWith(
          isGenerating: false,
          error: _mapFailureToMessage(failure),
        );
        AppLogger.warning('Failed to generate lesson plan: $failure');
      },
    );
  }

  // ─── Publish Lesson Plan ───────────────────────────────────────────

  /// Publishes a draft lesson plan, making it visible to students.
  Future<void> publishLessonPlan(String planId) async {
    state = state.copyWith(isUpdating: true, error: null);

    // Optimistically update the local state.
    final updatedList = state.lessonPlans.map((p) {
      if (p.id == planId) {
        return p.copyWith(isPublished: true);
      }
      return p;
    }).toList();

    state = state.copyWith(
      isUpdating: false,
      lessonPlans: updatedList,
      currentPlan: state.currentPlan?.id == planId
          ? state.currentPlan!.copyWith(isPublished: true)
          : state.currentPlan,
      successMessage: 'Lesson plan published successfully',
      error: null,
    );
    AppLogger.info('Lesson plan published: $planId');
  }

  // ─── Archive Lesson Plan ───────────────────────────────────────────

  /// Archives a lesson plan, hiding it from active lists.
  Future<void> archiveLessonPlan(String planId) async {
    state = state.copyWith(isUpdating: true, error: null);

    // Optimistically update the local state.
    final updatedList = state.lessonPlans.map((p) {
      if (p.id == planId) {
        return p.copyWith(isArchived: true);
      }
      return p;
    }).toList();

    state = state.copyWith(
      isUpdating: false,
      lessonPlans: updatedList,
      currentPlan: state.currentPlan?.id == planId
          ? state.currentPlan!.copyWith(isArchived: true)
          : state.currentPlan,
      successMessage: 'Lesson plan archived successfully',
      error: null,
    );
    AppLogger.info('Lesson plan archived: $planId');
  }

  // ─── Duplicate Lesson Plan ─────────────────────────────────────────

  /// Creates a deep copy of a lesson plan with a new ID.
  Future<void> duplicateLessonPlan(String planId) async {
    state = state.copyWith(isCreating: true, error: null);

    final sourcePlan = state.lessonPlans.where((p) => p.id == planId).firstOrNull;
    if (sourcePlan == null) {
      state = state.copyWith(
        isCreating: false,
        error: 'Lesson plan not found',
      );
      return;
    }

    // Create a duplicate with modified title.
    final duplicate = sourcePlan.copyWith(
      id: '', // Backend will assign a new ID
      title: '${sourcePlan.title} (Copy)',
      isPublished: false,
      isArchived: false,
    );

    final result = await _createLessonPlanUseCase(
      CreateLessonPlanParams(plan: duplicate),
    );

    result.fold(
      onSuccess: (newPlan) {
        final updatedList = [newPlan, ...state.lessonPlans];
        state = state.copyWith(
          isCreating: false,
          lessonPlans: updatedList,
          successMessage: 'Lesson plan duplicated successfully',
          error: null,
        );
        AppLogger.info('Lesson plan duplicated from: $planId');
      },
      onFailure: (failure) {
        state = state.copyWith(
          isCreating: false,
          error: _mapFailureToMessage(failure),
        );
        AppLogger.warning('Failed to duplicate lesson plan: $failure');
      },
    );
  }

  // ─── Set Current Plan ──────────────────────────────────────────────

  /// Sets the currently selected lesson plan.
  void setCurrentPlan(LessonPlanEntity? plan) {
    state = state.copyWith(currentPlan: plan);
  }

  // ─── Set Filter ────────────────────────────────────────────────────

  /// Updates the active filter and reloads the lesson plan list.
  Future<void> setFilter(WorkspaceFilterEntity filter) async {
    state = state.copyWith(filter: filter);
    await loadLessonPlans();
  }

  // ─── Clear Error ───────────────────────────────────────────────────

  /// Clears the current error message from the state.
  void clearError() {
    state = state.clearError();
  }

  // ─── Clear Success Message ─────────────────────────────────────────

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
// LESSON PLAN PROVIDER
// ═══════════════════════════════════════════════════════════════════════

final lessonPlanProvider =
    StateNotifierProvider<LessonPlanNotifier, LessonPlanState>((ref) {
  return LessonPlanNotifier(
    getLessonPlansUseCase: ref.watch(getLessonPlansUseCaseProvider),
    createLessonPlanUseCase: ref.watch(createLessonPlanUseCaseProvider),
    updateLessonPlanUseCase: ref.watch(updateLessonPlanUseCaseProvider),
    deleteLessonPlanUseCase: ref.watch(deleteLessonPlanUseCaseProvider),
    generateLessonPlanUseCase: ref.watch(generateLessonPlanUseCaseProvider),
  );
});
