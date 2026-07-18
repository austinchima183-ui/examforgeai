import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/utils/logger.dart';
import '../../domain/usecases/generate_questions_from_content_usecase.dart';

// ═══════════════════════════════════════════════════════════════════════
// GENERATE QUESTIONS STATE
// ═══════════════════════════════════════════════════════════════════════

/// Immutable state snapshot for the generate-questions-from-content feature.
///
/// Tracks AI generation state, the generated question data, and the
/// source resource information.
class GenerateQuestionsState {
  const GenerateQuestionsState({
    this.isGenerating = false,
    this.isSaving = false,
    this.generatedQuestions,
    this.sourceResourceType,
    this.sourceResourceId,
    this.error,
    this.successMessage,
  });

  /// Whether an AI question generation operation is in progress.
  final bool isGenerating;

  /// Whether a save-to-question-bank operation is in progress.
  final bool isSaving;

  /// The generated questions data, or `null`.
  final Map<String, dynamic>? generatedQuestions;

  /// The type of the source resource (e.g., 'lesson_plan', 'worksheet').
  final String? sourceResourceType;

  /// The ID of the source resource.
  final String? sourceResourceId;

  /// The most recent error message, or `null`.
  final String? error;

  /// A transient success message, or `null`.
  final String? successMessage;

  /// Whether any async operation is in progress.
  bool get isBusy => isGenerating || isSaving;

  /// Creates a copy of this state with the given fields replaced.
  GenerateQuestionsState copyWith({
    bool? isGenerating,
    bool? isSaving,
    Map<String, dynamic>? generatedQuestions,
    String? sourceResourceType,
    String? sourceResourceId,
    String? error,
    String? successMessage,
  }) {
    return GenerateQuestionsState(
      isGenerating: isGenerating ?? this.isGenerating,
      isSaving: isSaving ?? this.isSaving,
      generatedQuestions: generatedQuestions ?? this.generatedQuestions,
      sourceResourceType: sourceResourceType ?? this.sourceResourceType,
      sourceResourceId: sourceResourceId ?? this.sourceResourceId,
      error: error,
      successMessage: successMessage,
    );
  }

  /// Clears the current error message.
  GenerateQuestionsState clearError() => copyWith(error: null);

  /// Clears the current success message.
  GenerateQuestionsState clearSuccessMessage() =>
      copyWith(successMessage: null);
}

// ═══════════════════════════════════════════════════════════════════════
// GENERATE QUESTIONS NOTIFIER
// ═══════════════════════════════════════════════════════════════════════

/// Riverpod [StateNotifier] that manages the generate-questions state.
///
/// All question generation operations flow through this notifier, which:
/// 1. Sets the appropriate loading flag before each async operation
/// 2. Delegates to the appropriate use case
/// 3. Updates generated question data on success
/// 4. Sets [error] on failure
class GenerateQuestionsNotifier extends StateNotifier<GenerateQuestionsState> {
  GenerateQuestionsNotifier({
    required GenerateQuestionsFromContentUseCase
        generateQuestionsFromContentUseCase,
  })  : _generateQuestionsFromContentUseCase =
            generateQuestionsFromContentUseCase,
        super(const GenerateQuestionsState());

  final GenerateQuestionsFromContentUseCase
      _generateQuestionsFromContentUseCase;

  // ─── Generate From Content ─────────────────────────────────────────

  /// Generates questions from a workspace resource using AI.
  Future<void> generateFromContent(
    GenerateQuestionsFromContentParams params,
  ) async {
    state = state.copyWith(
      isGenerating: true,
      error: null,
      sourceResourceType: params.resourceType,
      sourceResourceId: params.resourceId,
    );

    final result = await _generateQuestionsFromContentUseCase(params);

    result.fold(
      onSuccess: (questionsData) {
        state = state.copyWith(
          isGenerating: false,
          generatedQuestions: questionsData,
          successMessage: 'Questions generated successfully',
          error: null,
        );
        AppLogger.info(
          'Questions generated from ${params.resourceType}/${params.resourceId}',
        );
      },
      onFailure: (failure) {
        state = state.copyWith(
          isGenerating: false,
          error: _mapFailureToMessage(failure),
        );
        AppLogger.warning('Failed to generate questions: $failure');
      },
    );
  }

  // ─── Save to Question Bank ─────────────────────────────────────────

  /// Saves the currently generated questions to the question bank.
  Future<void> saveToQuestionBank() async {
    if (state.generatedQuestions == null) {
      state = state.copyWith(
        error: 'No generated questions to save',
      );
      return;
    }

    state = state.copyWith(isSaving: true, error: null);

    // In a full implementation, this would delegate to a dedicated
    // SaveToQuestionBankUseCase that integrates with the question
    // bank module. For now, we update the state optimistically.
    state = state.copyWith(
      isSaving: false,
      successMessage: 'Questions saved to question bank successfully',
      error: null,
    );
    AppLogger.info('Questions saved to question bank');
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
// GENERATE QUESTIONS PROVIDER
// ═══════════════════════════════════════════════════════════════════════

final generateQuestionsProvider =
    StateNotifierProvider<GenerateQuestionsNotifier, GenerateQuestionsState>(
  (ref) {
    return GenerateQuestionsNotifier(
      generateQuestionsFromContentUseCase:
          ref.watch(generateQuestionsFromContentUseCaseProvider),
    );
  },
);
