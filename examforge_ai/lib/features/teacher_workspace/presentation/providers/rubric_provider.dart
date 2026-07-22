import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../config/dependency_injection.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/utils/logger.dart';
import '../../domain/entities/teacher_workspace_entities.dart';
import '../../domain/entities/workspace_expansion_entities.dart';
import '../../domain/usecases/create_rubric_usecase.dart';
import '../../domain/usecases/generate_rubric_usecase.dart';
import '../../domain/usecases/get_rubrics_usecase.dart';

// ═══════════════════════════════════════════════════════════════════════
// RUBRIC STATE
// ═══════════════════════════════════════════════════════════════════════

/// Immutable state snapshot for the rubric feature.
///
/// Tracks the current list of rubrics, loading flags for each operation,
/// the active filter, and the currently selected rubric.
class RubricState {
  const RubricState({
    this.rubrics = const [],
    this.isLoading = false,
    this.isCreating = false,
    this.isGenerating = false,
    this.error,
    this.currentRubric,
    this.filter = const WorkspaceFilterEntity(),
    this.successMessage,
  });

  /// The current list of rubrics.
  final List<RubricEntity> rubrics;

  /// Whether the initial load is in progress.
  final bool isLoading;

  /// Whether a create operation is in progress.
  final bool isCreating;

  /// Whether an AI generation operation is in progress.
  final bool isGenerating;

  /// The most recent error message, or `null`.
  final String? error;

  /// The currently selected rubric with full details, or `null`.
  final RubricEntity? currentRubric;

  /// The active filter criteria.
  final WorkspaceFilterEntity filter;

  /// A transient success message (e.g. "Rubric created"), or `null`.
  final String? successMessage;

  /// Whether any async operation is in progress.
  bool get isBusy => isLoading || isCreating || isGenerating;

  /// Creates a copy of this state with the given fields replaced.
  RubricState copyWith({
    List<RubricEntity>? rubrics,
    bool? isLoading,
    bool? isCreating,
    bool? isGenerating,
    String? error,
    RubricEntity? currentRubric,
    WorkspaceFilterEntity? filter,
    String? successMessage,
  }) {
    return RubricState(
      rubrics: rubrics ?? this.rubrics,
      isLoading: isLoading ?? this.isLoading,
      isCreating: isCreating ?? this.isCreating,
      isGenerating: isGenerating ?? this.isGenerating,
      error: error,
      currentRubric: currentRubric ?? this.currentRubric,
      filter: filter ?? this.filter,
      successMessage: successMessage,
    );
  }

  /// Clears the current error message.
  RubricState clearError() => copyWith(error: null);

  /// Clears the current success message.
  RubricState clearSuccessMessage() => copyWith(successMessage: null);
}

// ═══════════════════════════════════════════════════════════════════════
// RUBRIC NOTIFIER
// ═══════════════════════════════════════════════════════════════════════

/// Riverpod [StateNotifier] that manages the rubric feature's state.
///
/// All rubric operations flow through this notifier, which:
/// 1. Sets the appropriate loading flag before each async operation
/// 2. Delegates to the appropriate use case
/// 3. Updates the rubric list and filter state on success
/// 4. Sets [error] on failure
class RubricNotifier extends StateNotifier<RubricState> {
  RubricNotifier({
    required GetRubricsUseCase getRubricsUseCase,
    required CreateRubricUseCase createRubricUseCase,
    required GenerateRubricUseCase generateRubricUseCase,
  })  : _getRubricsUseCase = getRubricsUseCase,
        _createRubricUseCase = createRubricUseCase,
        _generateRubricUseCase = generateRubricUseCase,
        super(const RubricState());

  final GetRubricsUseCase _getRubricsUseCase;
  final CreateRubricUseCase _createRubricUseCase;
  final GenerateRubricUseCase _generateRubricUseCase;

  // ─── Load Rubrics ────────────────────────────────────────────────

  /// Loads the list of rubrics using the current filter.
  Future<void> loadRubrics() async {
    state = state.copyWith(isLoading: true, error: null);

    final result = await _getRubricsUseCase(
      GetRubricsParams(filter: state.filter),
    );

    result.fold(
      onSuccess: (rubrics) {
        state = state.copyWith(
          isLoading: false,
          rubrics: rubrics,
          error: null,
        );
        AppLogger.info('Loaded ${rubrics.length} rubrics');
      },
      onFailure: (failure) {
        state = state.copyWith(
          isLoading: false,
          error: _mapFailureToMessage(failure),
        );
        AppLogger.warning('Failed to load rubrics: $failure');
      },
    );
  }

  // ─── Create Rubric ───────────────────────────────────────────────

  /// Creates a new rubric with the provided [params].
  Future<void> createRubric(CreateRubricParams params) async {
    state = state.copyWith(isCreating: true, error: null);

    final result = await _createRubricUseCase(params);

    result.fold(
      onSuccess: (rubric) {
        final updatedList = [rubric, ...state.rubrics];
        state = state.copyWith(
          isCreating: false,
          rubrics: updatedList,
          successMessage: 'Rubric created successfully',
          error: null,
        );
        AppLogger.info('Rubric created: ${rubric.id}');
      },
      onFailure: (failure) {
        state = state.copyWith(
          isCreating: false,
          error: _mapFailureToMessage(failure),
        );
        AppLogger.warning('Failed to create rubric: $failure');
      },
    );
  }

  // ─── Generate Rubric (AI) ────────────────────────────────────────

  /// Generates a rubric using AI with the provided [params].
  Future<void> generateRubric(GenerateRubricParams params) async {
    state = state.copyWith(isGenerating: true, error: null);

    final result = await _generateRubricUseCase(params);

    result.fold(
      onSuccess: (rubric) {
        final updatedList = [rubric, ...state.rubrics];
        state = state.copyWith(
          isGenerating: false,
          rubrics: updatedList,
          currentRubric: rubric,
          successMessage: 'Rubric generated successfully',
          error: null,
        );
        AppLogger.info('Rubric generated: ${rubric.id}');
      },
      onFailure: (failure) {
        state = state.copyWith(
          isGenerating: false,
          error: _mapFailureToMessage(failure),
        );
        AppLogger.warning('Failed to generate rubric: $failure');
      },
    );
  }

  // ─── Delete Rubric ───────────────────────────────────────────────

  /// Removes a rubric from the local list by [id].
  Future<void> deleteRubric(String id) async {
    final updatedList = state.rubrics.where((r) => r.id != id).toList();
    state = state.copyWith(
      rubrics: updatedList,
      currentRubric: state.currentRubric?.id == id
          ? null
          : state.currentRubric,
      successMessage: 'Rubric deleted successfully',
    );
    AppLogger.info('Rubric deleted: $id');
  }

  // ─── Set Current Rubric ──────────────────────────────────────────

  /// Sets the currently selected rubric.
  void setCurrentRubric(RubricEntity? rubric) {
    state = state.copyWith(currentRubric: rubric);
  }

  // ─── Set Filter ──────────────────────────────────────────────────

  /// Updates the active filter and reloads the rubric list.
  Future<void> setFilter(WorkspaceFilterEntity filter) async {
    state = state.copyWith(filter: filter);
    await loadRubrics();
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
// RUBRIC PROVIDER
// ═══════════════════════════════════════════════════════════════════════

final rubricProvider =
    StateNotifierProvider<RubricNotifier, RubricState>((ref) {
  return RubricNotifier(
    getRubricsUseCase: ref.watch(getRubricsUseCaseProvider),
    createRubricUseCase: ref.watch(createRubricUseCaseProvider),
    generateRubricUseCase: ref.watch(generateRubricUseCaseProvider),
  );
});
