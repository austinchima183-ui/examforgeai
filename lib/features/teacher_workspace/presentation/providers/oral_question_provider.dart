import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../config/dependency_injection.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/utils/logger.dart';
import '../../domain/entities/teacher_workspace_entities.dart';
import '../../domain/entities/workspace_expansion_entities.dart';
import '../../domain/usecases/create_oral_questions_usecase.dart';
import '../../domain/usecases/generate_oral_questions_usecase.dart';
import '../../domain/usecases/get_oral_questions_usecase.dart';

// ═══════════════════════════════════════════════════════════════════════
// ORAL QUESTION STATE
// ═══════════════════════════════════════════════════════════════════════

/// Immutable state snapshot for the oral question feature.
///
/// Tracks the current list of oral question sets, loading flags for each
/// operation, the active filter, and the currently selected oral question set.
class OralQuestionState {
  const OralQuestionState({
    this.oralQuestions = const [],
    this.isLoading = false,
    this.isCreating = false,
    this.isGenerating = false,
    this.error,
    this.currentOralQuestion,
    this.filter = const WorkspaceFilterEntity(),
    this.successMessage,
  });

  /// The current list of oral question sets.
  final List<OralQuestionEntity> oralQuestions;

  /// Whether the initial load is in progress.
  final bool isLoading;

  /// Whether a create operation is in progress.
  final bool isCreating;

  /// Whether an AI generation operation is in progress.
  final bool isGenerating;

  /// The most recent error message, or `null`.
  final String? error;

  /// The currently selected oral question set with full details, or `null`.
  final OralQuestionEntity? currentOralQuestion;

  /// The active filter criteria.
  final WorkspaceFilterEntity filter;

  /// A transient success message (e.g. "Oral questions created"), or `null`.
  final String? successMessage;

  /// Whether any async operation is in progress.
  bool get isBusy => isLoading || isCreating || isGenerating;

  /// Creates a copy of this state with the given fields replaced.
  OralQuestionState copyWith({
    List<OralQuestionEntity>? oralQuestions,
    bool? isLoading,
    bool? isCreating,
    bool? isGenerating,
    String? error,
    OralQuestionEntity? currentOralQuestion,
    WorkspaceFilterEntity? filter,
    String? successMessage,
  }) {
    return OralQuestionState(
      oralQuestions: oralQuestions ?? this.oralQuestions,
      isLoading: isLoading ?? this.isLoading,
      isCreating: isCreating ?? this.isCreating,
      isGenerating: isGenerating ?? this.isGenerating,
      error: error,
      currentOralQuestion: currentOralQuestion ?? this.currentOralQuestion,
      filter: filter ?? this.filter,
      successMessage: successMessage,
    );
  }

  /// Clears the current error message.
  OralQuestionState clearError() => copyWith(error: null);

  /// Clears the current success message.
  OralQuestionState clearSuccessMessage() => copyWith(successMessage: null);
}

// ═══════════════════════════════════════════════════════════════════════
// ORAL QUESTION NOTIFIER
// ═══════════════════════════════════════════════════════════════════════

/// Riverpod [StateNotifier] that manages the oral question feature's state.
///
/// All oral question operations flow through this notifier, which:
/// 1. Sets the appropriate loading flag before each async operation
/// 2. Delegates to the appropriate use case
/// 3. Updates the oral question list and filter state on success
/// 4. Sets [error] on failure
class OralQuestionNotifier extends StateNotifier<OralQuestionState> {
  OralQuestionNotifier({
    required GetOralQuestionsUseCase getOralQuestionsUseCase,
    required CreateOralQuestionsUseCase createOralQuestionsUseCase,
    required GenerateOralQuestionsUseCase generateOralQuestionsUseCase,
  })  : _getOralQuestionsUseCase = getOralQuestionsUseCase,
        _createOralQuestionsUseCase = createOralQuestionsUseCase,
        _generateOralQuestionsUseCase = generateOralQuestionsUseCase,
        super(const OralQuestionState());

  final GetOralQuestionsUseCase _getOralQuestionsUseCase;
  final CreateOralQuestionsUseCase _createOralQuestionsUseCase;
  final GenerateOralQuestionsUseCase _generateOralQuestionsUseCase;

  // ─── Load Oral Questions ─────────────────────────────────────────

  /// Loads the list of oral question sets using the current filter.
  Future<void> loadOralQuestions() async {
    state = state.copyWith(isLoading: true, error: null);

    final result = await _getOralQuestionsUseCase(
      GetOralQuestionsParams(filter: state.filter),
    );

    result.fold(
      onSuccess: (oralQuestions) {
        state = state.copyWith(
          isLoading: false,
          oralQuestions: oralQuestions,
          error: null,
        );
        AppLogger.info('Loaded ${oralQuestions.length} oral question sets');
      },
      onFailure: (failure) {
        state = state.copyWith(
          isLoading: false,
          error: _mapFailureToMessage(failure),
        );
        AppLogger.warning('Failed to load oral questions: $failure');
      },
    );
  }

  // ─── Create Oral Questions ───────────────────────────────────────

  /// Creates a new oral question set with the provided [params].
  Future<void> createOralQuestions(CreateOralQuestionsParams params) async {
    state = state.copyWith(isCreating: true, error: null);

    final result = await _createOralQuestionsUseCase(params);

    result.fold(
      onSuccess: (oralQuestion) {
        final updatedList = [oralQuestion, ...state.oralQuestions];
        state = state.copyWith(
          isCreating: false,
          oralQuestions: updatedList,
          successMessage: 'Oral questions created successfully',
          error: null,
        );
        AppLogger.info('Oral questions created: ${oralQuestion.id}');
      },
      onFailure: (failure) {
        state = state.copyWith(
          isCreating: false,
          error: _mapFailureToMessage(failure),
        );
        AppLogger.warning('Failed to create oral questions: $failure');
      },
    );
  }

  // ─── Generate Oral Questions (AI) ────────────────────────────────

  /// Generates oral questions using AI with the provided [params].
  Future<void> generateOralQuestions(
    GenerateOralQuestionsParams params,
  ) async {
    state = state.copyWith(isGenerating: true, error: null);

    final result = await _generateOralQuestionsUseCase(params);

    result.fold(
      onSuccess: (oralQuestion) {
        final updatedList = [oralQuestion, ...state.oralQuestions];
        state = state.copyWith(
          isGenerating: false,
          oralQuestions: updatedList,
          currentOralQuestion: oralQuestion,
          successMessage: 'Oral questions generated successfully',
          error: null,
        );
        AppLogger.info('Oral questions generated: ${oralQuestion.id}');
      },
      onFailure: (failure) {
        state = state.copyWith(
          isGenerating: false,
          error: _mapFailureToMessage(failure),
        );
        AppLogger.warning('Failed to generate oral questions: $failure');
      },
    );
  }

  // ─── Delete Oral Questions ───────────────────────────────────────

  /// Removes an oral question set from the local list by [id].
  Future<void> deleteOralQuestions(String id) async {
    final updatedList =
        state.oralQuestions.where((oq) => oq.id != id).toList();
    state = state.copyWith(
      oralQuestions: updatedList,
      currentOralQuestion: state.currentOralQuestion?.id == id
          ? null
          : state.currentOralQuestion,
      successMessage: 'Oral questions deleted successfully',
    );
    AppLogger.info('Oral questions deleted: $id');
  }

  // ─── Set Current Oral Question ───────────────────────────────────

  /// Sets the currently selected oral question set.
  void setCurrentOralQuestion(OralQuestionEntity? oralQuestion) {
    state = state.copyWith(currentOralQuestion: oralQuestion);
  }

  // ─── Set Filter ──────────────────────────────────────────────────

  /// Updates the active filter and reloads the oral question list.
  Future<void> setFilter(WorkspaceFilterEntity filter) async {
    state = state.copyWith(filter: filter);
    await loadOralQuestions();
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
// ORAL QUESTION PROVIDER
// ═══════════════════════════════════════════════════════════════════════

final oralQuestionProvider =
    StateNotifierProvider<OralQuestionNotifier, OralQuestionState>((ref) {
  return OralQuestionNotifier(
    getOralQuestionsUseCase: ref.watch(getOralQuestionsUseCaseProvider),
    createOralQuestionsUseCase: ref.watch(createOralQuestionsUseCaseProvider),
    generateOralQuestionsUseCase:
        ref.watch(generateOralQuestionsUseCaseProvider),
  );
});
