import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/utils/logger.dart';
import '../../domain/entities/communication_entities.dart';
import '../../domain/usecases/ai_adjust_tone_usecase.dart';
import '../../domain/usecases/ai_correct_grammar_usecase.dart';
import '../../domain/usecases/ai_draft_announcement_usecase.dart';
import '../../domain/usecases/ai_rewrite_message_usecase.dart';
import '../../domain/usecases/ai_suggest_reply_usecase.dart';
import '../../domain/usecases/ai_summarize_conversation_usecase.dart';
import '../../domain/usecases/ai_translate_message_usecase.dart';

// ═══════════════════════════════════════════════════════════════════════
// AI ASSISTANT STATE
// ═══════════════════════════════════════════════════════════════════════

/// A single chat-like exchange between the user and the AI assistant.
class AiAssistantExchange {
  const AiAssistantExchange({
    required this.type,
    required this.input,
    required this.response,
    required this.timestamp,
  });

  /// The type of AI operation (e.g. 'draft_announcement', 'rewrite', etc.).
  final String type;

  /// The user's input that triggered this exchange.
  final String input;

  /// The AI assistant's response content.
  final String response;

  /// When this exchange occurred.
  final DateTime timestamp;
}

/// Immutable state snapshot for the AI communication assistant feature.
///
/// Tracks the current response, loading flag, error message,
/// and a history of conversation-like exchanges with the assistant.
class AiAssistantState {
  const AiAssistantState({
    this.response,
    this.isLoading = false,
    this.error,
    this.conversationHistory = const [],
  });

  /// The current AI assistant response, or `null`.
  final AiCommunicationAssistantEntity? response;

  /// Whether an AI operation is in progress.
  final bool isLoading;

  /// The most recent error message, or `null`.
  final String? error;

  /// A list of chat-like exchanges with the AI assistant.
  final List<AiAssistantExchange> conversationHistory;

  /// Creates a copy of this state with the given fields replaced.
  AiAssistantState copyWith({
    AiCommunicationAssistantEntity? response,
    bool? isLoading,
    String? error,
    List<AiAssistantExchange>? conversationHistory,
    bool clearResponse = false,
  }) {
    return AiAssistantState(
      response: clearResponse ? null : (response ?? this.response),
      isLoading: isLoading ?? this.isLoading,
      error: error,
      conversationHistory: conversationHistory ?? this.conversationHistory,
    );
  }

  /// Clears the current error message.
  AiAssistantState clearError() => copyWith(error: null);
}

// ═══════════════════════════════════════════════════════════════════════
// AI ASSISTANT NOTIFIER
// ═══════════════════════════════════════════════════════════════════════

/// Riverpod [StateNotifier] that manages the AI communication assistant's state.
///
/// All AI assistant operations flow through this notifier, which:
/// 1. Sets the loading flag before each async operation
/// 2. Delegates to the relevant AI use case
/// 3. Updates the response and conversation history on success
/// 4. Sets [error] on failure
class AiAssistantNotifier extends StateNotifier<AiAssistantState> {
  AiAssistantNotifier({
    required AiDraftAnnouncementUseCase aiDraftAnnouncementUseCase,
    required AiRewriteMessageUseCase aiRewriteMessageUseCase,
    required AiSummarizeConversationUseCase aiSummarizeConversationUseCase,
    required AiTranslateMessageUseCase aiTranslateMessageUseCase,
    required AiSuggestReplyUseCase aiSuggestReplyUseCase,
    required AiCorrectGrammarUseCase aiCorrectGrammarUseCase,
    required AiAdjustToneUseCase aiAdjustToneUseCase,
  })  : _aiDraftAnnouncementUseCase = aiDraftAnnouncementUseCase,
        _aiRewriteMessageUseCase = aiRewriteMessageUseCase,
        _aiSummarizeConversationUseCase = aiSummarizeConversationUseCase,
        _aiTranslateMessageUseCase = aiTranslateMessageUseCase,
        _aiSuggestReplyUseCase = aiSuggestReplyUseCase,
        _aiCorrectGrammarUseCase = aiCorrectGrammarUseCase,
        _aiAdjustToneUseCase = aiAdjustToneUseCase,
        super(const AiAssistantState());

  final AiDraftAnnouncementUseCase _aiDraftAnnouncementUseCase;
  final AiRewriteMessageUseCase _aiRewriteMessageUseCase;
  final AiSummarizeConversationUseCase _aiSummarizeConversationUseCase;
  final AiTranslateMessageUseCase _aiTranslateMessageUseCase;
  final AiSuggestReplyUseCase _aiSuggestReplyUseCase;
  final AiCorrectGrammarUseCase _aiCorrectGrammarUseCase;
  final AiAdjustToneUseCase _aiAdjustToneUseCase;

  // ─── Draft Announcement ─────────────────────────────────────────────

  /// Drafts an announcement using AI with the provided [params].
  Future<void> draftAnnouncement(AiDraftAnnouncementParams params) async {
    state = state.copyWith(isLoading: true, error: null);

    final result = await _aiDraftAnnouncementUseCase(params);

    result.fold(
      onSuccess: (assistant) {
        final exchange = AiAssistantExchange(
          type: 'draft_announcement',
          input: params.topic,
          response: assistant.content,
          timestamp: DateTime.now(),
        );
        state = state.copyWith(
          isLoading: false,
          response: assistant,
          conversationHistory: [...state.conversationHistory, exchange],
          error: null,
        );
        AppLogger.info('AI drafted announcement: ${assistant.id}');
      },
      onFailure: (failure) {
        state = state.copyWith(
          isLoading: false,
          error: _mapFailureToMessage(failure),
        );
        AppLogger.warning('Failed to draft announcement: $failure');
      },
    );
  }

  // ─── Rewrite Message ───────────────────────────────────────────────

  /// Rewrites a message using AI with the provided [params].
  Future<void> rewriteMessage(AiRewriteMessageParams params) async {
    state = state.copyWith(isLoading: true, error: null);

    final result = await _aiRewriteMessageUseCase(params);

    result.fold(
      onSuccess: (assistant) {
        final exchange = AiAssistantExchange(
          type: 'rewrite',
          input: params.text,
          response: assistant.content,
          timestamp: DateTime.now(),
        );
        state = state.copyWith(
          isLoading: false,
          response: assistant,
          conversationHistory: [...state.conversationHistory, exchange],
          error: null,
        );
        AppLogger.info('AI rewrote message: ${assistant.id}');
      },
      onFailure: (failure) {
        state = state.copyWith(
          isLoading: false,
          error: _mapFailureToMessage(failure),
        );
        AppLogger.warning('Failed to rewrite message: $failure');
      },
    );
  }

  // ─── Summarize Conversation ────────────────────────────────────────

  /// Summarizes a conversation using AI for the given [conversationId].
  Future<void> summarizeConversation(String conversationId) async {
    state = state.copyWith(isLoading: true, error: null);

    final result = await _aiSummarizeConversationUseCase(
      AiSummarizeConversationParams(conversationId: conversationId),
    );

    result.fold(
      onSuccess: (assistant) {
        final exchange = AiAssistantExchange(
          type: 'summarize',
          input: 'Conversation: $conversationId',
          response: assistant.content,
          timestamp: DateTime.now(),
        );
        state = state.copyWith(
          isLoading: false,
          response: assistant,
          conversationHistory: [...state.conversationHistory, exchange],
          error: null,
        );
        AppLogger.info('AI summarized conversation: ${assistant.id}');
      },
      onFailure: (failure) {
        state = state.copyWith(
          isLoading: false,
          error: _mapFailureToMessage(failure),
        );
        AppLogger.warning('Failed to summarize conversation: $failure');
      },
    );
  }

  // ─── Translate Message ─────────────────────────────────────────────

  /// Translates a message using AI with the provided [params].
  Future<void> translateMessage(AiTranslateMessageParams params) async {
    state = state.copyWith(isLoading: true, error: null);

    final result = await _aiTranslateMessageUseCase(params);

    result.fold(
      onSuccess: (assistant) {
        final exchange = AiAssistantExchange(
          type: 'translate',
          input: '${params.text} → ${params.targetLanguage}',
          response: assistant.content,
          timestamp: DateTime.now(),
        );
        state = state.copyWith(
          isLoading: false,
          response: assistant,
          conversationHistory: [...state.conversationHistory, exchange],
          error: null,
        );
        AppLogger.info('AI translated message: ${assistant.id}');
      },
      onFailure: (failure) {
        state = state.copyWith(
          isLoading: false,
          error: _mapFailureToMessage(failure),
        );
        AppLogger.warning('Failed to translate message: $failure');
      },
    );
  }

  // ─── Suggest Reply ─────────────────────────────────────────────────

  /// Suggests a reply using AI with the provided [params].
  Future<void> suggestReply(AiSuggestReplyParams params) async {
    state = state.copyWith(isLoading: true, error: null);

    final result = await _aiSuggestReplyUseCase(params);

    result.fold(
      onSuccess: (assistant) {
        final exchange = AiAssistantExchange(
          type: 'suggest_reply',
          input: 'Message: ${params.messageId}',
          response: assistant.content,
          timestamp: DateTime.now(),
        );
        state = state.copyWith(
          isLoading: false,
          response: assistant,
          conversationHistory: [...state.conversationHistory, exchange],
          error: null,
        );
        AppLogger.info('AI suggested reply: ${assistant.id}');
      },
      onFailure: (failure) {
        state = state.copyWith(
          isLoading: false,
          error: _mapFailureToMessage(failure),
        );
        AppLogger.warning('Failed to suggest reply: $failure');
      },
    );
  }

  // ─── Correct Grammar ───────────────────────────────────────────────

  /// Corrects grammar using AI with the provided [params].
  Future<void> correctGrammar(AiCorrectGrammarParams params) async {
    state = state.copyWith(isLoading: true, error: null);

    final result = await _aiCorrectGrammarUseCase(params);

    result.fold(
      onSuccess: (assistant) {
        final exchange = AiAssistantExchange(
          type: 'grammar',
          input: params.text,
          response: assistant.content,
          timestamp: DateTime.now(),
        );
        state = state.copyWith(
          isLoading: false,
          response: assistant,
          conversationHistory: [...state.conversationHistory, exchange],
          error: null,
        );
        AppLogger.info('AI corrected grammar: ${assistant.id}');
      },
      onFailure: (failure) {
        state = state.copyWith(
          isLoading: false,
          error: _mapFailureToMessage(failure),
        );
        AppLogger.warning('Failed to correct grammar: $failure');
      },
    );
  }

  // ─── Adjust Tone ───────────────────────────────────────────────────

  /// Adjusts tone using AI with the provided [params].
  Future<void> adjustTone(AiAdjustToneParams params) async {
    state = state.copyWith(isLoading: true, error: null);

    final result = await _aiAdjustToneUseCase(params);

    result.fold(
      onSuccess: (assistant) {
        final exchange = AiAssistantExchange(
          type: 'tone_adjust',
          input: '${params.text} → ${params.targetTone}',
          response: assistant.content,
          timestamp: DateTime.now(),
        );
        state = state.copyWith(
          isLoading: false,
          response: assistant,
          conversationHistory: [...state.conversationHistory, exchange],
          error: null,
        );
        AppLogger.info('AI adjusted tone: ${assistant.id}');
      },
      onFailure: (failure) {
        state = state.copyWith(
          isLoading: false,
          error: _mapFailureToMessage(failure),
        );
        AppLogger.warning('Failed to adjust tone: $failure');
      },
    );
  }

  // ─── Clear Response ────────────────────────────────────────────────

  /// Clears the current AI response from the state.
  void clearResponse() {
    state = state.copyWith(clearResponse: true);
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
// AI ASSISTANT PROVIDER
// ═══════════════════════════════════════════════════════════════════════

final aiAssistantProvider =
    StateNotifierProvider<AiAssistantNotifier, AiAssistantState>((ref) {
  return AiAssistantNotifier(
    aiDraftAnnouncementUseCase:
        ref.watch(aiDraftAnnouncementUseCaseProvider),
    aiRewriteMessageUseCase: ref.watch(aiRewriteMessageUseCaseProvider),
    aiSummarizeConversationUseCase:
        ref.watch(aiSummarizeConversationUseCaseProvider),
    aiTranslateMessageUseCase: ref.watch(aiTranslateMessageUseCaseProvider),
    aiSuggestReplyUseCase: ref.watch(aiSuggestReplyUseCaseProvider),
    aiCorrectGrammarUseCase: ref.watch(aiCorrectGrammarUseCaseProvider),
    aiAdjustToneUseCase: ref.watch(aiAdjustToneUseCaseProvider),
  );
});
