import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../config/dependency_injection.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/utils/logger.dart';
import '../../domain/entities/teacher_workspace_entities.dart';
import '../../domain/entities/workspace_expansion_entities.dart';
import '../../domain/usecases/create_practical_assessment_usecase.dart';
import '../../domain/usecases/generate_practical_assessment_usecase.dart';
import '../../domain/usecases/get_practical_assessments_usecase.dart';

// ═══════════════════════════════════════════════════════════════════════
// PRACTICAL ASSESSMENT STATE
// ═══════════════════════════════════════════════════════════════════════

/// Immutable state snapshot for the practical assessment feature.
///
/// Tracks the current list of assessments, loading flags for each operation,
/// the active filter, and the currently selected assessment.
class PracticalAssessmentState {
  const PracticalAssessmentState({
    this.assessments = const [],
    this.isLoading = false,
    this.isCreating = false,
    this.isGenerating = false,
    this.error,
    this.currentAssessment,
    this.filter = const WorkspaceFilterEntity(),
    this.successMessage,
  });

  /// The current list of practical assessments.
  final List<PracticalAssessmentEntity> assessments;

  /// Whether the initial load is in progress.
  final bool isLoading;

  /// Whether a create operation is in progress.
  final bool isCreating;

  /// Whether an AI generation operation is in progress.
  final bool isGenerating;

  /// The most recent error message, or `null`.
  final String? error;

  /// The currently selected practical assessment with full details, or `null`.
  final PracticalAssessmentEntity? currentAssessment;

  /// The active filter criteria.
  final WorkspaceFilterEntity filter;

  /// A transient success message (e.g. "Assessment created"), or `null`.
  final String? successMessage;

  /// Whether any async operation is in progress.
  bool get isBusy => isLoading || isCreating || isGenerating;

  /// Creates a copy of this state with the given fields replaced.
  PracticalAssessmentState copyWith({
    List<PracticalAssessmentEntity>? assessments,
    bool? isLoading,
    bool? isCreating,
    bool? isGenerating,
    String? error,
    PracticalAssessmentEntity? currentAssessment,
    WorkspaceFilterEntity? filter,
    String? successMessage,
  }) {
    return PracticalAssessmentState(
      assessments: assessments ?? this.assessments,
      isLoading: isLoading ?? this.isLoading,
      isCreating: isCreating ?? this.isCreating,
      isGenerating: isGenerating ?? this.isGenerating,
      error: error,
      currentAssessment: currentAssessment ?? this.currentAssessment,
      filter: filter ?? this.filter,
      successMessage: successMessage,
    );
  }

  /// Clears the current error message.
  PracticalAssessmentState clearError() => copyWith(error: null);

  /// Clears the current success message.
  PracticalAssessmentState clearSuccessMessage() =>
      copyWith(successMessage: null);
}

// ═══════════════════════════════════════════════════════════════════════
// PRACTICAL ASSESSMENT NOTIFIER
// ═══════════════════════════════════════════════════════════════════════

/// Riverpod [StateNotifier] that manages the practical assessment feature's state.
///
/// All practical assessment operations flow through this notifier, which:
/// 1. Sets the appropriate loading flag before each async operation
/// 2. Delegates to the appropriate use case
/// 3. Updates the assessment list and filter state on success
/// 4. Sets [error] on failure
class PracticalAssessmentNotifier
    extends StateNotifier<PracticalAssessmentState> {
  PracticalAssessmentNotifier({
    required GetPracticalAssessmentsUseCase getPracticalAssessmentsUseCase,
    required CreatePracticalAssessmentUseCase createPracticalAssessmentUseCase,
    required GeneratePracticalAssessmentUseCase
        generatePracticalAssessmentUseCase,
  })  : _getPracticalAssessmentsUseCase = getPracticalAssessmentsUseCase,
        _createPracticalAssessmentUseCase = createPracticalAssessmentUseCase,
        _generatePracticalAssessmentUseCase =
            generatePracticalAssessmentUseCase,
        super(const PracticalAssessmentState());

  final GetPracticalAssessmentsUseCase _getPracticalAssessmentsUseCase;
  final CreatePracticalAssessmentUseCase _createPracticalAssessmentUseCase;
  final GeneratePracticalAssessmentUseCase
      _generatePracticalAssessmentUseCase;

  // ─── Load Practical Assessments ──────────────────────────────────

  /// Loads the list of practical assessments using the current filter.
  Future<void> loadPracticalAssessments() async {
    state = state.copyWith(isLoading: true, error: null);

    final result = await _getPracticalAssessmentsUseCase(
      GetPracticalAssessmentsParams(filter: state.filter),
    );

    result.fold(
      onSuccess: (assessments) {
        state = state.copyWith(
          isLoading: false,
          assessments: assessments,
          error: null,
        );
        AppLogger.info('Loaded ${assessments.length} practical assessments');
      },
      onFailure: (failure) {
        state = state.copyWith(
          isLoading: false,
          error: _mapFailureToMessage(failure),
        );
        AppLogger.warning(
          'Failed to load practical assessments: $failure',
        );
      },
    );
  }

  // ─── Create Practical Assessment ─────────────────────────────────

  /// Creates a new practical assessment with the provided [params].
  Future<void> createPracticalAssessment(
    CreatePracticalAssessmentParams params,
  ) async {
    state = state.copyWith(isCreating: true, error: null);

    final result = await _createPracticalAssessmentUseCase(params);

    result.fold(
      onSuccess: (assessment) {
        final updatedList = [assessment, ...state.assessments];
        state = state.copyWith(
          isCreating: false,
          assessments: updatedList,
          successMessage: 'Practical assessment created successfully',
          error: null,
        );
        AppLogger.info('Practical assessment created: ${assessment.id}');
      },
      onFailure: (failure) {
        state = state.copyWith(
          isCreating: false,
          error: _mapFailureToMessage(failure),
        );
        AppLogger.warning(
          'Failed to create practical assessment: $failure',
        );
      },
    );
  }

  // ─── Generate Practical Assessment (AI) ──────────────────────────

  /// Generates a practical assessment using AI with the provided [params].
  Future<void> generatePracticalAssessment(
    GeneratePracticalAssessmentParams params,
  ) async {
    state = state.copyWith(isGenerating: true, error: null);

    final result = await _generatePracticalAssessmentUseCase(params);

    result.fold(
      onSuccess: (assessment) {
        final updatedList = [assessment, ...state.assessments];
        state = state.copyWith(
          isGenerating: false,
          assessments: updatedList,
          currentAssessment: assessment,
          successMessage: 'Practical assessment generated successfully',
          error: null,
        );
        AppLogger.info('Practical assessment generated: ${assessment.id}');
      },
      onFailure: (failure) {
        state = state.copyWith(
          isGenerating: false,
          error: _mapFailureToMessage(failure),
        );
        AppLogger.warning(
          'Failed to generate practical assessment: $failure',
        );
      },
    );
  }

  // ─── Delete Practical Assessment ─────────────────────────────────

  /// Removes a practical assessment from the local list by [id].
  Future<void> deletePracticalAssessment(String id) async {
    final updatedList =
        state.assessments.where((a) => a.id != id).toList();
    state = state.copyWith(
      assessments: updatedList,
      currentAssessment: state.currentAssessment?.id == id
          ? null
          : state.currentAssessment,
      successMessage: 'Practical assessment deleted successfully',
    );
    AppLogger.info('Practical assessment deleted: $id');
  }

  // ─── Set Current Assessment ──────────────────────────────────────

  /// Sets the currently selected practical assessment.
  void setCurrentAssessment(PracticalAssessmentEntity? assessment) {
    state = state.copyWith(currentAssessment: assessment);
  }

  // ─── Set Filter ──────────────────────────────────────────────────

  /// Updates the active filter and reloads the practical assessment list.
  Future<void> setFilter(WorkspaceFilterEntity filter) async {
    state = state.copyWith(filter: filter);
    await loadPracticalAssessments();
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
// PRACTICAL ASSESSMENT PROVIDER
// ═══════════════════════════════════════════════════════════════════════

final practicalAssessmentProvider = StateNotifierProvider<
    PracticalAssessmentNotifier, PracticalAssessmentState>((ref) {
  return PracticalAssessmentNotifier(
    getPracticalAssessmentsUseCase:
        ref.watch(getPracticalAssessmentsUseCaseProvider),
    createPracticalAssessmentUseCase:
        ref.watch(createPracticalAssessmentUseCaseProvider),
    generatePracticalAssessmentUseCase:
        ref.watch(generatePracticalAssessmentUseCaseProvider),
  );
});
