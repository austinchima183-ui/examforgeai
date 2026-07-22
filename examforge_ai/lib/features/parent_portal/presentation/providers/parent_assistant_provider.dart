import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../config/dependency_injection.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/utils/logger.dart';
import '../../domain/entities/parent_portal_entities.dart';
import '../../domain/usecases/ask_parent_assistant_usecase.dart';

// ═══════════════════════════════════════════════════════════════════════
// PARENT ASSISTANT STATE
// ═══════════════════════════════════════════════════════════════════════

/// Immutable state snapshot for the parent AI assistant feature.
///
/// Tracks the assistant response, loading flag, error message,
/// conversation history, and the current question.
class ParentAssistantState {
  const ParentAssistantState({
    this.response,
    this.isLoading = false,
    this.error,
    this.conversationHistory = const [],
    this.currentQuestion,
  });

  /// The most recent AI assistant response, or `null`.
  final ParentAssistantResponseEntity? response;

  /// Whether an ask operation is in progress.
  final bool isLoading;

  /// The most recent error message, or `null`.
  final String? error;

  /// The conversation history as a list of role/content maps.
  final List<Map<String, String>> conversationHistory;

  /// The current question being asked, or `null`.
  final String? currentQuestion;

  /// Creates a copy of this state with the given fields replaced.
  ParentAssistantState copyWith({
    ParentAssistantResponseEntity? response,
    bool? isLoading,
    String? error,
    List<Map<String, String>>? conversationHistory,
    String? currentQuestion,
  }) {
    return ParentAssistantState(
      response: response ?? this.response,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      conversationHistory: conversationHistory ?? this.conversationHistory,
      currentQuestion: currentQuestion ?? this.currentQuestion,
    );
  }

  /// Clears the current error message.
  ParentAssistantState clearError() => copyWith(error: null);
}

// ═══════════════════════════════════════════════════════════════════════
// PARENT ASSISTANT NOTIFIER
// ═══════════════════════════════════════════════════════════════════════

/// Riverpod [StateNotifier] that manages the parent AI assistant feature's state.
///
/// All assistant operations flow through this notifier, which:
/// 1. Sets [isLoading] before each async operation
/// 2. Delegates to the [AskParentAssistantUseCase]
/// 3. Updates [response] and [conversationHistory] on success
/// 4. Sets [error] on failure
class ParentAssistantNotifier extends StateNotifier<ParentAssistantState> {
  ParentAssistantNotifier({
    required AskParentAssistantUseCase askParentAssistantUseCase,
  })  : _askParentAssistantUseCase = askParentAssistantUseCase,
        super(const ParentAssistantState());

  final AskParentAssistantUseCase _askParentAssistantUseCase;

  // ─── Ask Question ──────────────────────────────────────────────────

  /// Asks the AI assistant a [question], optionally scoped to [studentId]
  /// with additional [context].
  Future<void> askQuestion(
    String question, [
    String? studentId,
    Map<String, dynamic>? context,
  ]) async {
    state = state.copyWith(
      isLoading: true,
      error: null,
      currentQuestion: question,
    );

    // Append the user question to conversation history.
    final updatedHistory = [
      ...state.conversationHistory,
      {'role': 'user', 'content': question},
    ];

    final result = await _askParentAssistantUseCase(
      AskParentAssistantParams(
        question: question,
        studentId: studentId,
        context: context,
      ),
    );

    result.fold(
      onSuccess: (response) {
        // Append the assistant response to conversation history.
        final historyWithResponse = [
          ...updatedHistory,
          {'role': 'assistant', 'content': response.answer},
        ];
        state = state.copyWith(
          isLoading: false,
          response: response,
          conversationHistory: historyWithResponse,
          currentQuestion: null,
          error: null,
        );
        AppLogger.info('Parent assistant responded to question');
      },
      onFailure: (failure) {
        state = state.copyWith(
          isLoading: false,
          conversationHistory: updatedHistory,
          currentQuestion: null,
          error: _mapFailureToMessage(failure),
        );
        AppLogger.warning('Failed to get parent assistant response: $failure');
      },
    );
  }

  // ─── Clear Conversation ────────────────────────────────────────────

  /// Clears the conversation history and response.
  void clearConversation() {
    state = state.copyWith(
      response: null,
      conversationHistory: const [],
      currentQuestion: null,
    );
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
// PARENT ASSISTANT PROVIDER
// ═══════════════════════════════════════════════════════════════════════

final parentAssistantProvider =
    StateNotifierProvider<ParentAssistantNotifier, ParentAssistantState>(
        (ref) {
  return ParentAssistantNotifier(
    askParentAssistantUseCase: ref.watch(askParentAssistantUseCaseProvider),
  );
});
