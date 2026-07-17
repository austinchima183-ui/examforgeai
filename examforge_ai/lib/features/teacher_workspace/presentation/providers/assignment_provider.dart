import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/utils/logger.dart';
import '../../domain/entities/teacher_workspace_entities.dart';
import '../../domain/usecases/create_assignment_usecase.dart';
import '../../domain/usecases/generate_assignment_usecase.dart';
import '../../domain/usecases/get_assignments_usecase.dart';
import '../../domain/usecases/publish_assignment_usecase.dart';

// ═══════════════════════════════════════════════════════════════════════
// ASSIGNMENT STATE
// ═══════════════════════════════════════════════════════════════════════

/// Immutable state snapshot for the assignment feature.
///
/// Tracks the current list of assignments, pagination state, loading flags
/// for each operation, the active filter, and error/success messages.
class AssignmentState {
  const AssignmentState({
    this.assignments = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.isCreating = false,
    this.isUpdating = false,
    this.isDeleting = false,
    this.isGenerating = false,
    this.isPublishing = false,
    this.error,
    this.currentAssignment,
    this.totalCount = 0,
    this.currentPage = 1,
    this.hasMore = true,
    this.filter = const WorkspaceFilterEntity(),
    this.successMessage,
  });

  /// The current page of assignments.
  final List<WorkspaceAssignmentEntity> assignments;

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

  /// Whether a publish operation is in progress.
  final bool isPublishing;

  /// The most recent error message, or `null`.
  final String? error;

  /// The currently selected assignment with full details, or `null`.
  final WorkspaceAssignmentEntity? currentAssignment;

  /// Total number of assignments matching the current filter.
  final int totalCount;

  /// The current page number (1-based).
  final int currentPage;

  /// Whether there are more pages to load.
  final bool hasMore;

  /// The active filter criteria.
  final WorkspaceFilterEntity filter;

  /// A transient success message, or `null`.
  final String? successMessage;

  /// Number of assignments currently loaded.
  int get loadedCount => assignments.length;

  /// Whether any async operation is in progress.
  bool get isBusy =>
      isLoading ||
      isLoadingMore ||
      isCreating ||
      isUpdating ||
      isDeleting ||
      isGenerating ||
      isPublishing;

  /// Creates a copy of this state with the given fields replaced.
  AssignmentState copyWith({
    List<WorkspaceAssignmentEntity>? assignments,
    bool? isLoading,
    bool? isLoadingMore,
    bool? isCreating,
    bool? isUpdating,
    bool? isDeleting,
    bool? isGenerating,
    bool? isPublishing,
    String? error,
    WorkspaceAssignmentEntity? currentAssignment,
    int? totalCount,
    int? currentPage,
    bool? hasMore,
    WorkspaceFilterEntity? filter,
    String? successMessage,
  }) {
    return AssignmentState(
      assignments: assignments ?? this.assignments,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      isCreating: isCreating ?? this.isCreating,
      isUpdating: isUpdating ?? this.isUpdating,
      isDeleting: isDeleting ?? this.isDeleting,
      isGenerating: isGenerating ?? this.isGenerating,
      isPublishing: isPublishing ?? this.isPublishing,
      error: error,
      currentAssignment: currentAssignment ?? this.currentAssignment,
      totalCount: totalCount ?? this.totalCount,
      currentPage: currentPage ?? this.currentPage,
      hasMore: hasMore ?? this.hasMore,
      filter: filter ?? this.filter,
      successMessage: successMessage,
    );
  }

  /// Clears the current error message.
  AssignmentState clearError() => copyWith(error: null);

  /// Clears the current success message.
  AssignmentState clearSuccessMessage() => copyWith(successMessage: null);
}

// ═══════════════════════════════════════════════════════════════════════
// ASSIGNMENT NOTIFIER
// ═══════════════════════════════════════════════════════════════════════

/// Riverpod [StateNotifier] that manages the assignment feature's state.
///
/// All assignment operations flow through this notifier, which:
/// 1. Sets the appropriate loading flag before each async operation
/// 2. Delegates to the appropriate use case
/// 3. Updates the assignment list, pagination, and filter state on success
/// 4. Sets [error] on failure
class AssignmentNotifier extends StateNotifier<AssignmentState> {
  AssignmentNotifier({
    required GetAssignmentsUseCase getAssignmentsUseCase,
    required CreateAssignmentUseCase createAssignmentUseCase,
    required GenerateAssignmentUseCase generateAssignmentUseCase,
    required PublishAssignmentUseCase publishAssignmentUseCase,
  })  : _getAssignmentsUseCase = getAssignmentsUseCase,
        _createAssignmentUseCase = createAssignmentUseCase,
        _generateAssignmentUseCase = generateAssignmentUseCase,
        _publishAssignmentUseCase = publishAssignmentUseCase,
        super(const AssignmentState());

  final GetAssignmentsUseCase _getAssignmentsUseCase;
  final CreateAssignmentUseCase _createAssignmentUseCase;
  final GenerateAssignmentUseCase _generateAssignmentUseCase;
  final PublishAssignmentUseCase _publishAssignmentUseCase;

  // ─── Load Assignments (first page) ─────────────────────────────────

  /// Loads the first page of assignments using the current filter.
  Future<void> loadAssignments() async {
    state = state.copyWith(isLoading: true, error: null);

    final filter = state.filter.copyWith(page: 1);
    final result = await _getAssignmentsUseCase(
      GetAssignmentsParams(filter: filter),
    );

    result.fold(
      onSuccess: (assignments) {
        state = state.copyWith(
          isLoading: false,
          assignments: assignments,
          currentPage: 1,
          hasMore: assignments.length >= state.filter.perPage,
          error: null,
        );
        AppLogger.info('Loaded ${assignments.length} assignments (page 1)');
      },
      onFailure: (failure) {
        state = state.copyWith(
          isLoading: false,
          error: _mapFailureToMessage(failure),
        );
        AppLogger.warning('Failed to load assignments: $failure');
      },
    );
  }

  // ─── Create Assignment ─────────────────────────────────────────────

  /// Creates a new assignment with the provided [params].
  Future<void> createAssignment(CreateAssignmentParams params) async {
    state = state.copyWith(isCreating: true, error: null);

    final result = await _createAssignmentUseCase(params);

    result.fold(
      onSuccess: (assignment) {
        final updatedList = [assignment, ...state.assignments];
        state = state.copyWith(
          isCreating: false,
          assignments: updatedList,
          successMessage: 'Assignment created successfully',
          error: null,
        );
        AppLogger.info('Assignment created: ${assignment.id}');
      },
      onFailure: (failure) {
        state = state.copyWith(
          isCreating: false,
          error: _mapFailureToMessage(failure),
        );
        AppLogger.warning('Failed to create assignment: $failure');
      },
    );
  }

  // ─── Update Assignment ─────────────────────────────────────────────

  /// Updates an existing assignment.
  Future<void> updateAssignment(WorkspaceAssignmentEntity assignment) async {
    state = state.copyWith(isUpdating: true, error: null);

    // Optimistically update the local state.
    final updatedList = state.assignments
        .map((a) => a.id == assignment.id ? assignment : a)
        .toList();

    state = state.copyWith(
      isUpdating: false,
      assignments: updatedList,
      currentAssignment: state.currentAssignment?.id == assignment.id
          ? assignment
          : state.currentAssignment,
      successMessage: 'Assignment updated successfully',
      error: null,
    );
    AppLogger.info('Assignment updated: ${assignment.id}');
  }

  // ─── Delete Assignment ─────────────────────────────────────────────

  /// Deletes an assignment by [assignmentId].
  Future<void> deleteAssignment(String assignmentId) async {
    state = state.copyWith(isDeleting: true, error: null);

    // Optimistically remove from local state.
    final updatedList =
        state.assignments.where((a) => a.id != assignmentId).toList();
    state = state.copyWith(
      isDeleting: false,
      assignments: updatedList,
      currentAssignment: state.currentAssignment?.id == assignmentId
          ? null
          : state.currentAssignment,
      successMessage: 'Assignment deleted successfully',
      error: null,
    );
    AppLogger.info('Assignment deleted: $assignmentId');
  }

  // ─── Generate Assignment (AI) ──────────────────────────────────────

  /// Generates an assignment using AI with the provided [params].
  Future<void> generateAssignment(GenerateAssignmentParams params) async {
    state = state.copyWith(isGenerating: true, error: null);

    final result = await _generateAssignmentUseCase(params);

    result.fold(
      onSuccess: (assignment) {
        final updatedList = [assignment, ...state.assignments];
        state = state.copyWith(
          isGenerating: false,
          assignments: updatedList,
          currentAssignment: assignment,
          successMessage: 'Assignment generated successfully',
          error: null,
        );
        AppLogger.info('Assignment generated: ${assignment.id}');
      },
      onFailure: (failure) {
        state = state.copyWith(
          isGenerating: false,
          error: _mapFailureToMessage(failure),
        );
        AppLogger.warning('Failed to generate assignment: $failure');
      },
    );
  }

  // ─── Publish Assignment ────────────────────────────────────────────

  /// Publishes a draft assignment, making it visible to students.
  Future<void> publishAssignment(String assignmentId) async {
    state = state.copyWith(isPublishing: true, error: null);

    final result = await _publishAssignmentUseCase(
      PublishAssignmentParams(assignmentId: assignmentId),
    );

    result.fold(
      onSuccess: (_) {
        final updatedList = state.assignments.map((a) {
          if (a.id == assignmentId) {
            return a.copyWith(
              isPublished: true,
              assignmentStatus: AssignmentStatus.published,
            );
          }
          return a;
        }).toList();
        state = state.copyWith(
          isPublishing: false,
          assignments: updatedList,
          currentAssignment: state.currentAssignment?.id == assignmentId
              ? state.currentAssignment!.copyWith(
                  isPublished: true,
                  assignmentStatus: AssignmentStatus.published,
                )
              : state.currentAssignment,
          successMessage: 'Assignment published successfully',
          error: null,
        );
        AppLogger.info('Assignment published: $assignmentId');
      },
      onFailure: (failure) {
        state = state.copyWith(
          isPublishing: false,
          error: _mapFailureToMessage(failure),
        );
        AppLogger.warning('Failed to publish assignment: $failure');
      },
    );
  }

  // ─── Set Filter ────────────────────────────────────────────────────

  /// Updates the active filter and reloads the assignment list.
  Future<void> setFilter(WorkspaceFilterEntity filter) async {
    state = state.copyWith(filter: filter);
    await loadAssignments();
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
// ASSIGNMENT PROVIDER
// ═══════════════════════════════════════════════════════════════════════

final assignmentProvider =
    StateNotifierProvider<AssignmentNotifier, AssignmentState>((ref) {
  return AssignmentNotifier(
    getAssignmentsUseCase: ref.watch(getAssignmentsUseCaseProvider),
    createAssignmentUseCase: ref.watch(createAssignmentUseCaseProvider),
    generateAssignmentUseCase: ref.watch(generateAssignmentUseCaseProvider),
    publishAssignmentUseCase: ref.watch(publishAssignmentUseCaseProvider),
  );
});
