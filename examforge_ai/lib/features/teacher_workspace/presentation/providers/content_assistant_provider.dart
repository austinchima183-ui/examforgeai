import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../config/dependency_injection.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/utils/logger.dart';
import '../../domain/entities/teacher_workspace_entities.dart';
import '../../domain/usecases/ai_content_assistant_usecase.dart';
import '../../domain/usecases/get_content_history_usecase.dart';

// ═══════════════════════════════════════════════════════════════════════
// CONTENT ASSISTANT STATE
// ═══════════════════════════════════════════════════════════════════════

/// Immutable state snapshot for the AI content assistant feature.
///
/// Tracks generated content, loading flags, content history, the source
/// content being acted upon, and the selected AI action.
class ContentAssistantState {
  const ContentAssistantState({
    this.generatedContent,
    this.isGenerating = false,
    this.isSaving = false,
    this.history = const [],
    this.isLoadingHistory = false,
    this.sourceContent,
    this.selectedAction,
    this.error,
    this.successMessage,
  });

  /// The most recently generated content, or `null`.
  final AiContentHistoryEntity? generatedContent;

  /// Whether an AI generation operation is in progress.
  final bool isGenerating;

  /// Whether a save-content-as operation is in progress.
  final bool isSaving;

  /// The history of AI-generated content entries.
  final List<AiContentHistoryEntity> history;

  /// Whether history is being loaded.
  final bool isLoadingHistory;

  /// The source content to act upon, or `null`.
  final String? sourceContent;

  /// The selected AI action, or `null`.
  final ContentAction? selectedAction;

  /// The most recent error message, or `null`.
  final String? error;

  /// A transient success message, or `null`.
  final String? successMessage;

  /// Whether any async operation is in progress.
  bool get isBusy => isGenerating || isSaving || isLoadingHistory;

  /// Creates a copy of this state with the given fields replaced.
  ContentAssistantState copyWith({
    AiContentHistoryEntity? generatedContent,
    bool? isGenerating,
    bool? isSaving,
    List<AiContentHistoryEntity>? history,
    bool? isLoadingHistory,
    String? sourceContent,
    ContentAction? selectedAction,
    String? error,
    String? successMessage,
  }) {
    return ContentAssistantState(
      generatedContent: generatedContent ?? this.generatedContent,
      isGenerating: isGenerating ?? this.isGenerating,
      isSaving: isSaving ?? this.isSaving,
      history: history ?? this.history,
      isLoadingHistory: isLoadingHistory ?? this.isLoadingHistory,
      sourceContent: sourceContent ?? this.sourceContent,
      selectedAction: selectedAction ?? this.selectedAction,
      error: error,
      successMessage: successMessage,
    );
  }

  /// Clears the current error message.
  ContentAssistantState clearError() => copyWith(error: null);

  /// Clears the current success message.
  ContentAssistantState clearSuccessMessage() =>
      copyWith(successMessage: null);
}

// ═══════════════════════════════════════════════════════════════════════
// CONTENT ASSISTANT NOTIFIER
// ═══════════════════════════════════════════════════════════════════════

/// Riverpod [StateNotifier] that manages the AI content assistant state.
///
/// All content assistant operations flow through this notifier, which:
/// 1. Sets the appropriate loading flag before each async operation
/// 2. Delegates to the appropriate use case
/// 3. Updates the generated content and history on success
/// 4. Sets [error] on failure
class ContentAssistantNotifier extends StateNotifier<ContentAssistantState> {
  ContentAssistantNotifier({
    required AiContentAssistantUseCase aiContentAssistantUseCase,
    required GetContentHistoryUseCase getContentHistoryUseCase,
  })  : _aiContentAssistantUseCase = aiContentAssistantUseCase,
        _getContentHistoryUseCase = getContentHistoryUseCase,
        super(const ContentAssistantState());

  final AiContentAssistantUseCase _aiContentAssistantUseCase;
  final GetContentHistoryUseCase _getContentHistoryUseCase;

  // ─── Generate Content ──────────────────────────────────────────────

  /// Generates content using the AI assistant based on the current
  /// source content and selected action.
  Future<void> generateContent() async {
    if (state.sourceContent == null || state.sourceContent!.trim().isEmpty) {
      state = state.copyWith(
        error: 'Source content is required before generating',
      );
      return;
    }
    if (state.selectedAction == null) {
      state = state.copyWith(
        error: 'Please select an action before generating',
      );
      return;
    }

    state = state.copyWith(isGenerating: true, error: null);

    final result = await _aiContentAssistantUseCase(
      AiContentAssistantParams(
        action: state.selectedAction!,
        sourceContent: state.sourceContent!,
      ),
    );

    result.fold(
      onSuccess: (historyEntry) {
        final updatedHistory = [historyEntry, ...state.history];
        state = state.copyWith(
          isGenerating: false,
          generatedContent: historyEntry,
          history: updatedHistory,
          successMessage: 'Content generated successfully',
          error: null,
        );
        AppLogger.info('Content generated: ${historyEntry.id}');
      },
      onFailure: (failure) {
        state = state.copyWith(
          isGenerating: false,
          error: _mapFailureToMessage(failure),
        );
        AppLogger.warning('Failed to generate content: $failure');
      },
    );
  }

  // ─── Set Content ───────────────────────────────────────────────────

  /// Sets the source content to act upon.
  void setContent(String content) {
    state = state.copyWith(sourceContent: content);
  }

  // ─── Set Action ────────────────────────────────────────────────────

  /// Sets the selected AI action.
  void setAction(ContentAction action) {
    state = state.copyWith(selectedAction: action);
  }

  // ─── Load History ──────────────────────────────────────────────────

  /// Loads the AI content generation history.
  Future<void> loadHistory() async {
    state = state.copyWith(isLoadingHistory: true, error: null);

    final result = await _getContentHistoryUseCase(
      const GetContentHistoryParams(
        filter: WorkspaceFilterEntity(),
      ),
    );

    result.fold(
      onSuccess: (history) {
        state = state.copyWith(
          isLoadingHistory: false,
          history: history,
          error: null,
        );
        AppLogger.info('Loaded ${history.length} content history entries');
      },
      onFailure: (failure) {
        state = state.copyWith(
          isLoadingHistory: false,
          error: _mapFailureToMessage(failure),
        );
        AppLogger.warning('Failed to load content history: $failure');
      },
    );
  }

  // ─── Save Content As ───────────────────────────────────────────────

  /// Saves the current generated content as a specific target type
  /// (e.g., lesson plan, worksheet, assignment).
  Future<void> saveContentAs(String targetType) async {
    if (state.generatedContent == null) {
      state = state.copyWith(
        error: 'No generated content to save',
      );
      return;
    }

    state = state.copyWith(isSaving: true, error: null);

    // Mark the history entry as saved with the target type.
    final updatedEntry = state.generatedContent!.copyWith(
      isSaved: true,
      savedAsType: targetType,
    );

    state = state.copyWith(
      isSaving: false,
      generatedContent: updatedEntry,
      successMessage: 'Content saved as $targetType successfully',
      error: null,
    );
    AppLogger.info('Content saved as: $targetType');
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
// CONTENT ASSISTANT PROVIDER
// ═══════════════════════════════════════════════════════════════════════

final contentAssistantProvider =
    StateNotifierProvider<ContentAssistantNotifier, ContentAssistantState>(
  (ref) {
    return ContentAssistantNotifier(
      aiContentAssistantUseCase:
          ref.watch(aiContentAssistantUseCaseProvider),
      getContentHistoryUseCase:
          ref.watch(getContentHistoryUseCaseProvider),
    );
  },
);
