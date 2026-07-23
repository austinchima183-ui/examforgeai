import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/utils/logger.dart';
import '../../../../services/ai/ai_service.dart';
import '../../../question_bank/domain/entities/question_entities.dart';
import '../../domain/entities/ai_entities.dart';
import '../../domain/usecases/generate_questions_usecase.dart';
import '../../domain/usecases/get_generation_history_usecase.dart';
import '../../domain/usecases/improve_question_usecase.dart';
import '../../domain/usecases/manage_prompt_templates_usecase.dart';
import '../../domain/usecases/review_generated_question_usecase.dart';
import '../../domain/usecases/save_to_question_bank_usecase.dart';
import '../../domain/usecases/validate_question_usecase.dart';

// ═══════════════════════════════════════════════════════════════════════
// AI GENERATOR STATE
// ═══════════════════════════════════════════════════════════════════════

/// Immutable state snapshot for the AI question generator feature.
///
/// Tracks the current list of generated questions, active generation
/// request, streaming progress, input form data, and transient
/// error/success messages.
class AiGeneratorState {
  const AiGeneratorState({
    this.generatedQuestions = const [],
    this.currentGeneration,
    this.isGenerating = false,
    this.generationProgress,
    this.error,
    this.successMessage,
    this.input,
    this.generationHistory = const [],
    this.historyPage = 1,
    this.hasMoreHistory = true,
    this.isLoadingHistory = false,
  });

  /// The current list of generated questions from the latest generation.
  final List<GeneratedQuestionEntity> generatedQuestions;

  /// The active generation request, if any.
  final GenerationRequestEntity? currentGeneration;

  /// Whether a question generation operation is in progress.
  final bool isGenerating;

  /// Real-time progress during streaming generation.
  final GenerationProgress? generationProgress;

  /// The most recent error message, or `null`.
  final String? error;

  /// A transient success message (e.g. "5 questions generated"), or `null`.
  final String? successMessage;

  /// The current generation input parameters from the form.
  final GenerationInputEntity? input;

  /// Paginated generation request history.
  final List<GenerationRequestEntity> generationHistory;

  /// Current page number for history pagination (1-based).
  final int historyPage;

  /// Whether there are more history pages to load.
  final bool hasMoreHistory;

  /// Whether history is currently being loaded.
  final bool isLoadingHistory;

  /// Whether any async operation is in progress.
  bool get isBusy => isGenerating || isLoadingHistory;

  /// Creates a copy of this state with the given fields replaced.
  ///
  /// Note: [error] and [successMessage] use direct assignment (no `??`)
  /// so they can be explicitly cleared with `null`. Nullable reference
  /// fields like [currentGeneration] and [generationProgress] use
  /// dedicated `clear*` boolean parameters.
  AiGeneratorState copyWith({
    List<GeneratedQuestionEntity>? generatedQuestions,
    GenerationRequestEntity? currentGeneration,
    bool clearCurrentGeneration = false,
    bool? isGenerating,
    GenerationProgress? generationProgress,
    bool clearGenerationProgress = false,
    String? error,
    String? successMessage,
    GenerationInputEntity? input,
    List<GenerationRequestEntity>? generationHistory,
    int? historyPage,
    bool? hasMoreHistory,
    bool? isLoadingHistory,
  }) {
    return AiGeneratorState(
      generatedQuestions: generatedQuestions ?? this.generatedQuestions,
      currentGeneration: clearCurrentGeneration ? null : (currentGeneration ?? this.currentGeneration),
      isGenerating: isGenerating ?? this.isGenerating,
      generationProgress: clearGenerationProgress ? null : (generationProgress ?? this.generationProgress),
      error: error,
      successMessage: successMessage,
      input: input ?? this.input,
      generationHistory: generationHistory ?? this.generationHistory,
      historyPage: historyPage ?? this.historyPage,
      hasMoreHistory: hasMoreHistory ?? this.hasMoreHistory,
      isLoadingHistory: isLoadingHistory ?? this.isLoadingHistory,
    );
  }

  /// Clears the current error message.
  AiGeneratorState clearError() => copyWith(error: null);

  /// Clears the current success message.
  AiGeneratorState clearSuccessMessage() => copyWith(successMessage: null);
}

// ═══════════════════════════════════════════════════════════════════════
// AI GENERATOR NOTIFIER
// ═══════════════════════════════════════════════════════════════════════

/// Riverpod [StateNotifier] that manages the AI question generator
/// feature's state.
///
/// All generation, review, improvement, validation, and question bank
/// integration operations flow through this notifier. It:
/// 1. Sets the appropriate loading flag before each async operation
/// 2. Delegates to the appropriate use case or [AiService]
/// 3. Updates the generated questions, progress, and input state
/// 4. Sets [error] on failure and [successMessage] on success
class AiGeneratorNotifier extends StateNotifier<AiGeneratorState> {
  AiGeneratorNotifier({
    required GenerateQuestionsUseCase generateQuestionsUseCase,
    required ReviewGeneratedQuestionUseCase reviewGeneratedQuestionUseCase,
    required ImproveQuestionUseCase improveQuestionUseCase,
    required ValidateQuestionUseCase validateQuestionUseCase,
    required SaveToQuestionBankUseCase saveToQuestionBankUseCase,
    required GetGenerationHistoryUseCase getGenerationHistoryUseCase,
    required AiService aiService,
    required ManagePromptTemplatesUseCase managePromptTemplatesUseCase,
  })  : _generateQuestionsUseCase = generateQuestionsUseCase,
        _reviewGeneratedQuestionUseCase = reviewGeneratedQuestionUseCase,
        _improveQuestionUseCase = improveQuestionUseCase,
        _validateQuestionUseCase = validateQuestionUseCase,
        _saveToQuestionBankUseCase = saveToQuestionBankUseCase,
        _getGenerationHistoryUseCase = getGenerationHistoryUseCase,
        _aiService = aiService,
        _managePromptTemplatesUseCase = managePromptTemplatesUseCase,
        super(const AiGeneratorState());

  final GenerateQuestionsUseCase _generateQuestionsUseCase;
  final ReviewGeneratedQuestionUseCase _reviewGeneratedQuestionUseCase;
  final ImproveQuestionUseCase _improveQuestionUseCase;
  final ValidateQuestionUseCase _validateQuestionUseCase;
  final SaveToQuestionBankUseCase _saveToQuestionBankUseCase;
  final GetGenerationHistoryUseCase _getGenerationHistoryUseCase;
  final AiService _aiService;
  final ManagePromptTemplatesUseCase _managePromptTemplatesUseCase;

  StreamSubscription<GenerationProgress>? _streamSubscription;

  // ─── Generate Questions ───────────────────────────────────────────

  /// Generates questions using the current [input] via the repository.
  ///
  /// Sets [isGenerating] to `true` during the operation and appends
  /// the generated questions to the state on success.
  Future<void> generateQuestions() async {
    final input = state.input;
    if (input == null) {
      state = state.copyWith(
        error: 'Please configure generation parameters before generating',
      );
      return;
    }

    state = state.copyWith(isGenerating: true, error: null);

    final result = await _generateQuestionsUseCase(
      GenerateQuestionsParams(input: input),
    );

    result.fold(
      onSuccess: (questions) {
        state = state.copyWith(
          isGenerating: false,
          generatedQuestions: questions,
          successMessage: '${questions.length} questions generated successfully',
          error: null,
        );
        AppLogger.info('Generated ${questions.length} questions');
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

  // ─── Generate Questions (Streaming) ───────────────────────────────

  /// Generates questions using streaming via [AiService] for real-time
  /// progress updates.
  ///
  /// Listens to the [GenerationProgress] stream and updates the state
  /// on each emission so the UI can render live progress.
  Stream<void> generateQuestionsStreaming() async* {
    final input = state.input;
    if (input == null) {
      state = state.copyWith(
        error: 'Please configure generation parameters before generating',
      );
      return;
    }

    state = state.copyWith(isGenerating: true, error: null);

    // Fetch available prompt templates for the AiService
    final templatesResult = await _managePromptTemplatesUseCase(
      const ManagePromptParams(action: PromptAction.list),
    );

    final List<PromptTemplateEntity> templates = [];
    templatesResult.fold(
      onSuccess: (data) {
        if (data is List<PromptTemplateEntity>) {
          templates.addAll(data);
        }
      },
      onFailure: (_) {
        AppLogger.info('No prompt templates found; using defaults');
      },
    );

    final progressStream =
        _aiService.generateQuestionsStream(input, templates);

    await for (final progress in progressStream) {
      state = state.copyWith(generationProgress: progress);

      if (progress.status == GenerationProgressStatus.completed) {
        state = state.copyWith(
          isGenerating: false,
          successMessage: 'Generation completed successfully',
        );
        AppLogger.info('Streaming generation completed');
      } else if (progress.status == GenerationProgressStatus.failed) {
        state = state.copyWith(
          isGenerating: false,
          error: progress.error ?? 'Generation failed',
        );
        AppLogger.warning('Streaming generation failed: ${progress.error}');
      }

      yield null;
    }
  }

  /// Starts streaming generation and subscribes to progress updates.
  ///
  /// This is an alternative to [generateQuestionsStreaming] for use in
  /// imperative contexts where a [Stream] return type is inconvenient.
  Future<void> startStreamingGeneration() async {
    final input = state.input;
    if (input == null) {
      state = state.copyWith(
        error: 'Please configure generation parameters before generating',
      );
      return;
    }

    state = state.copyWith(isGenerating: true, error: null);

    // Fetch available prompt templates for the AiService
    final templatesResult = await _managePromptTemplatesUseCase(
      const ManagePromptParams(action: PromptAction.list),
    );

    final List<PromptTemplateEntity> templates = [];
    templatesResult.fold(
      onSuccess: (data) {
        if (data is List<PromptTemplateEntity>) {
          templates.addAll(data);
        }
      },
      onFailure: (_) {
        AppLogger.info('No prompt templates found; using defaults');
      },
    );

    await _streamSubscription?.cancel();
    _streamSubscription =
        _aiService.generateQuestionsStream(input, templates).listen(
      (progress) {
        state = state.copyWith(generationProgress: progress);

        if (progress.status == GenerationProgressStatus.completed) {
          state = state.copyWith(
            isGenerating: false,
            successMessage: 'Generation completed successfully',
          );
          AppLogger.info('Streaming generation completed');
        } else if (progress.status == GenerationProgressStatus.failed) {
          state = state.copyWith(
            isGenerating: false,
            error: progress.error ?? 'Generation failed',
          );
          AppLogger.warning('Streaming generation failed: ${progress.error}');
        }
      },
      onError: (error) {
        state = state.copyWith(
          isGenerating: false,
          error: 'Streaming error: $error',
        );
        AppLogger.error('Streaming generation error', error: error);
      },
      onDone: () {
        if (state.isGenerating) {
          state = state.copyWith(isGenerating: false);
        }
      },
    );
  }

  /// Cancels any active streaming generation.
  Future<void> cancelGeneration() async {
    await _streamSubscription?.cancel();
    _streamSubscription = null;
    state = state.copyWith(isGenerating: false);
    AppLogger.info('Generation cancelled by user');
  }

  // ─── Input Management ────────────────────────────────────────────

  /// Sets the entire generation input.
  Future<void> setInput(GenerationInputEntity input) async {
    state = state.copyWith(input: input);
  }

  /// Updates a single field in the generation input.
  ///
  /// [field] must match one of the named parameters of
  /// [GenerationInputEntity.copyWith]. [value] is the new value.
  Future<void> updateInputField(String field, dynamic value) async {
    final current = state.input;
    if (current == null) return;

    GenerationInputEntity? updated;
    switch (field) {
      case 'subjectId':
        updated = current.copyWith(subjectId: value as String);
        break;
      case 'topicId':
        updated = current.copyWith(topicId: value as String);
        break;
      case 'subtopicId':
        updated = current.copyWith(subtopicId: value as String?);
        break;
      case 'classId':
        updated = current.copyWith(classId: value as String?);
        break;
      case 'curriculum':
        updated = current.copyWith(curriculum: value as CurriculumType?);
        break;
      case 'difficulty':
        updated = current.copyWith(difficulty: value as DifficultyLevel);
        break;
      case 'bloomLevel':
        updated = current.copyWith(bloomLevel: value as BloomTaxonomy?);
        break;
      case 'questionType':
        updated = current.copyWith(questionType: value as QuestionType?);
        break;
      case 'numQuestions':
        updated = current.copyWith(numQuestions: value as int);
        break;
      case 'language':
        updated = current.copyWith(language: value as String);
        break;
      case 'examType':
        updated = current.copyWith(examType: value as ExamType?);
        break;
      case 'keywords':
        updated = current.copyWith(keywords: value as List<String>);
        break;
      case 'customInstructions':
        updated = current.copyWith(customInstructions: value as String?);
        break;
      case 'provider':
        updated = current.copyWith(provider: value as AiProvider?);
        break;
      case 'promptTemplateId':
        updated = current.copyWith(promptTemplateId: value as String?);
        break;
      default:
        AppLogger.warning('Unknown input field: $field');
        return;
    }

    state = state.copyWith(input: updated);
  }

  // ─── Review Actions ──────────────────────────────────────────────

  /// Approves a generated question, optionally with [notes].
  Future<void> approveQuestion(String questionId, {String? notes}) async {
    state = state.copyWith(error: null);

    final result = await _reviewGeneratedQuestionUseCase(
      ReviewParams(
        questionId: questionId,
        action: ReviewAction.approve,
        notes: notes,
      ),
    );

    result.fold(
      onSuccess: (question) {
        final updatedList = state.generatedQuestions
            .map((q) => q.id == questionId ? question : q)
            .toList();
        state = state.copyWith(
          generatedQuestions: updatedList,
          successMessage: 'Question approved',
          error: null,
        );
        AppLogger.info('Question approved: $questionId');
      },
      onFailure: (failure) {
        state = state.copyWith(error: _mapFailureToMessage(failure));
        AppLogger.warning('Failed to approve question: $failure');
      },
    );
  }

  /// Rejects a generated question with a required [reason].
  Future<void> rejectQuestion(String questionId, String reason) async {
    state = state.copyWith(error: null);

    final result = await _reviewGeneratedQuestionUseCase(
      ReviewParams(
        questionId: questionId,
        action: ReviewAction.reject,
        notes: reason,
      ),
    );

    result.fold(
      onSuccess: (question) {
        final updatedList = state.generatedQuestions
            .map((q) => q.id == questionId ? question : q)
            .toList();
        state = state.copyWith(
          generatedQuestions: updatedList,
          successMessage: 'Question rejected',
          error: null,
        );
        AppLogger.info('Question rejected: $questionId');
      },
      onFailure: (failure) {
        state = state.copyWith(error: _mapFailureToMessage(failure));
        AppLogger.warning('Failed to reject question: $failure');
      },
    );
  }

  /// Requests revision for a generated question with [notes].
  Future<void> requestRevision(String questionId, String notes) async {
    state = state.copyWith(error: null);

    final result = await _reviewGeneratedQuestionUseCase(
      ReviewParams(
        questionId: questionId,
        action: ReviewAction.revision,
        notes: notes,
      ),
    );

    result.fold(
      onSuccess: (question) {
        final updatedList = state.generatedQuestions
            .map((q) => q.id == questionId ? question : q)
            .toList();
        state = state.copyWith(
          generatedQuestions: updatedList,
          successMessage: 'Revision requested',
          error: null,
        );
        AppLogger.info('Revision requested for question: $questionId');
      },
      onFailure: (failure) {
        state = state.copyWith(error: _mapFailureToMessage(failure));
        AppLogger.warning('Failed to request revision: $failure');
      },
    );
  }

  // ─── Question Improvement ────────────────────────────────────────

  /// Submits a generated question for AI-powered improvement.
  ///
  /// [improvementType] describes the kind of improvement (e.g.
  /// "clarity", "distractors", "difficulty", "explanation").
  Future<void> improveQuestion(
    String questionId,
    String improvementType, {
    String? customInstructions,
  }) async {
    state = state.copyWith(error: null);

    final result = await _improveQuestionUseCase(
      ImproveQuestionParams(
        questionId: questionId,
        improvementType: improvementType,
        customInstructions: customInstructions,
      ),
    );

    result.fold(
      onSuccess: (improvement) {
        // Update the question in the list with the improved content
        final updatedList = state.generatedQuestions.map((q) {
          if (q.id == questionId) {
            return q.copyWith(
              content: improvement.improvedContent,
              answerOptions: improvement.improvedAnswerOptions ?? q.answerOptions,
              isEdited: true,
            );
          }
          return q;
        }).toList();
        state = state.copyWith(
          generatedQuestions: updatedList,
          successMessage: 'Question improved ($improvementType)',
          error: null,
        );
        AppLogger.info('Question improved: $questionId ($improvementType)');
      },
      onFailure: (failure) {
        state = state.copyWith(error: _mapFailureToMessage(failure));
        AppLogger.warning('Failed to improve question: $failure');
      },
    );
  }

  // ─── Validation ──────────────────────────────────────────────────

  /// Validates a generated question for quality and curriculum alignment.
  Future<void> validateQuestion(String questionId) async {
    state = state.copyWith(error: null);

    final result = await _validateQuestionUseCase(
      ValidateQuestionParams(questionId: questionId),
    );

    result.fold(
      onSuccess: (validationResults) {
        final hasCritical = validationResults.any(
          (v) =>
              v.severity == ValidationSeverity.error ||
              v.severity == ValidationSeverity.critical,
        );
        state = state.copyWith(
          successMessage: hasCritical
              ? 'Validation found ${validationResults.length} issues'
              : 'Validation passed',
          error: null,
        );
        AppLogger.info(
          'Question $questionId validated: ${validationResults.length} results',
        );
      },
      onFailure: (failure) {
        state = state.copyWith(error: _mapFailureToMessage(failure));
        AppLogger.warning('Failed to validate question: $failure');
      },
    );
  }

  // ─── Save to Question Bank ───────────────────────────────────────

  /// Saves an approved generated question to the Question Bank module.
  Future<void> saveToQuestionBank(String generatedQuestionId) async {
    state = state.copyWith(error: null);

    final result = await _saveToQuestionBankUseCase(
      SaveToQuestionBankParams(generatedQuestionId: generatedQuestionId),
    );

    result.fold(
      onSuccess: (questionBankId) {
        // Mark the question as saved in the list
        final updatedList = state.generatedQuestions.map((q) {
          if (q.id == generatedQuestionId) {
            return q.copyWith(
              questionBankId: questionBankId,
              isApproved: true,
              reviewStatus: ReviewStatus.approved,
            );
          }
          return q;
        }).toList();
        state = state.copyWith(
          generatedQuestions: updatedList,
          successMessage: 'Question saved to Question Bank',
          error: null,
        );
        AppLogger.info(
          'Saved question to bank: $generatedQuestionId → $questionBankId',
        );
      },
      onFailure: (failure) {
        state = state.copyWith(error: _mapFailureToMessage(failure));
        AppLogger.warning('Failed to save to question bank: $failure');
      },
    );
  }

  // ─── Generation History ──────────────────────────────────────────

  /// Loads generation request history with pagination.
  Future<void> loadGenerationHistory({int page = 1}) async {
    if (state.isLoadingHistory) return;

    state = state.copyWith(isLoadingHistory: true, error: null);

    final result = await _getGenerationHistoryUseCase(
      GetHistoryParams(page: page, perPage: 20),
    );

    result.fold(
      onSuccess: (requests) {
        final updatedHistory = page == 1
            ? requests
            : [...state.generationHistory, ...requests];
        state = state.copyWith(
          isLoadingHistory: false,
          generationHistory: updatedHistory,
          historyPage: page,
          hasMoreHistory: requests.length >= 20,
          error: null,
        );
        AppLogger.info(
          'Loaded ${requests.length} history entries (page $page)',
        );
      },
      onFailure: (failure) {
        state = state.copyWith(
          isLoadingHistory: false,
          error: _mapFailureToMessage(failure),
        );
        AppLogger.warning('Failed to load generation history: $failure');
      },
    );
  }

  // ─── Clear State ─────────────────────────────────────────────────

  /// Clears the current error message from the state.
  void clearError() {
    state = state.clearError();
  }

  /// Clears the current success message from the state.
  void clearSuccessMessage() {
    state = state.clearSuccessMessage();
  }

  /// Clears all generated questions and resets generation state.
  void clearGeneratedQuestions() {
    state = state.copyWith(
      generatedQuestions: const [],
      clearCurrentGeneration: true,
      clearGenerationProgress: true,
    );
  }

  @override
  void dispose() {
    _streamSubscription?.cancel();
    super.dispose();
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
