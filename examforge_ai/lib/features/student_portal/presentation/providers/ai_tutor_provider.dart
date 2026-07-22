import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/utils/logger.dart';
import '../../domain/entities/student_portal_entities.dart';
import '../../domain/usecases/student_portal_usecases.dart';
import 'student_dashboard_provider.dart';

// ═══════════════════════════════════════════════════════════════════════
// AI TUTOR STATE
// ═══════════════════════════════════════════════════════════════════════

/// Immutable state snapshot for the AI Tutor feature.
///
/// Tracks the list of conversations, the currently open conversation
/// with its messages, loading flags, pagination state, and errors.
class AiTutorState {
  const AiTutorState({
    this.conversations = const [],
    this.currentConversation,
    this.messages = const [],
    this.isLoading = false,
    this.isSendingMessage = false,
    this.error,
    this.hasMoreConversations = true,
    this.currentPage = 1,
  });

  /// All conversations for the current student.
  final List<AiTutorConversationEntity> conversations;

  /// The currently selected conversation, or `null`.
  final AiTutorConversationEntity? currentConversation;

  /// Messages for the currently selected conversation.
  final List<AiTutorMessageEntity> messages;

  /// Whether the initial conversation list load is in progress.
  final bool isLoading;

  /// Whether a message send operation is in progress.
  final bool isSendingMessage;

  /// The most recent error message, or `null`.
  final String? error;

  /// Whether there are more conversation pages to load.
  final bool hasMoreConversations;

  /// Current page number for conversation pagination (1-based).
  // ignore: unused_field
  final int currentPage;

  /// Current page number for conversation pagination.

  /// Whether any async operation is in progress.
  bool get isBusy => isLoading || isSendingMessage;

  /// Number of total conversations loaded.
  int get conversationCount => conversations.length;

  /// Creates a copy of this state with the given fields replaced.
  AiTutorState copyWith({
    List<AiTutorConversationEntity>? conversations,
    AiTutorConversationEntity? currentConversation,
    List<AiTutorMessageEntity>? messages,
    bool? isLoading,
    bool? isSendingMessage,
    String? error,
    bool? hasMoreConversations,
    int? currentPage,
    bool clearCurrentConversation = false,
  }) {
    return AiTutorState(
      conversations: conversations ?? this.conversations,
      currentConversation: clearCurrentConversation
          ? null
          : (currentConversation ?? this.currentConversation),
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      isSendingMessage: isSendingMessage ?? this.isSendingMessage,
      error: error,
      hasMoreConversations:
          hasMoreConversations ?? this.hasMoreConversations,
      currentPage: currentPage ?? currentPage,
    );
  }

  /// Clears the current error message.
  AiTutorState clearError() => copyWith(error: null);
}

// ═══════════════════════════════════════════════════════════════════════
// AI TUTOR NOTIFIER
// ═══════════════════════════════════════════════════════════════════════

/// Riverpod [StateNotifier] that manages the AI Tutor feature's state.
///
/// All AI Tutor operations flow through this notifier, which:
/// 1. Sets the appropriate loading flag before each async operation
/// 2. Delegates to the appropriate use case
/// 3. Updates the conversation list, messages, and pagination on success
/// 4. Sets [error] on failure
class AiTutorNotifier extends StateNotifier<AiTutorState> {
  AiTutorNotifier({
    required GetConversationsUseCase getConversations,
    required GetConversationDetailUseCase getConversationDetail,
    required CreateConversationUseCase createConversation,
    required SendMessageUseCase sendMessage,
    required DeleteConversationUseCase deleteConversation,
    required String? studentId,
  })  : _getConversations = getConversations,
        _getConversationDetail = getConversationDetail,
        _createConversation = createConversation,
        _sendMessage = sendMessage,
        _deleteConversation = deleteConversation,
        _studentId = studentId,
        super(const AiTutorState());

  final GetConversationsUseCase _getConversations;
  final GetConversationDetailUseCase _getConversationDetail;
  final CreateConversationUseCase _createConversation;
  final SendMessageUseCase _sendMessage;
  final DeleteConversationUseCase _deleteConversation;
  final String? _studentId;

  static const int _pageSize = 20;

  // ─── Load Conversations (first page) ───────────────────────────────

  /// Loads the first page of conversations for the current student.
  Future<void> loadConversations() async {
    if (_studentId == null) return;

    state = state.copyWith(isLoading: true, error: null);

    final result = await _getConversations(
      studentId: _studentId!,
      page: 1,
      pageSize: _pageSize,
    );

    result.fold(
      onSuccess: (conversations) {
        state = state.copyWith(
          isLoading: false,
          conversations: conversations,
          currentPage: 1,
          hasMoreConversations: conversations.length >= _pageSize,
          error: null,
        );
        AppLogger.info(
          'Loaded ${conversations.length} conversations (page 1)',
        );
      },
      onFailure: (failure) {
        state = state.copyWith(
          isLoading: false,
          error: _mapFailureToMessage(failure),
        );
        AppLogger.warning('Failed to load conversations: $failure');
      },
    );
  }

  // ─── Load More Conversations ───────────────────────────────────────

  /// Loads the next page of conversations and appends to the list.
  Future<void> loadMoreConversations() async {
    if (_studentId == null || !state.hasMoreConversations) return;

    final nextPage = state.currentPage + 1;

    final result = await _getConversations(
      studentId: _studentId!,
      page: nextPage,
      pageSize: _pageSize,
    );

    result.fold(
      onSuccess: (newConversations) {
        final allConversations = [
          ...state.conversations,
          ...newConversations,
        ];
        state = state.copyWith(
          conversations: allConversations,
          currentPage: nextPage,
          hasMoreConversations: newConversations.length >= _pageSize,
        );
        AppLogger.info(
          'Loaded ${newConversations.length} more conversations (page $nextPage)',
        );
      },
      onFailure: (failure) {
        state = state.copyWith(
          error: _mapFailureToMessage(failure),
        );
        AppLogger.warning(
          'Failed to load more conversations: $failure',
        );
      },
    );
  }

  // ─── Open Conversation ─────────────────────────────────────────────

  /// Opens a conversation by ID, loading its messages.
  Future<void> openConversation(String conversationId) async {
    state = state.copyWith(isLoading: true, error: null);

    final result = await _getConversationDetail(
      conversationId: conversationId,
    );

    result.fold(
      onSuccess: (conversation) {
        // Messages are loaded separately or populated via sendMessage.
        // The conversation detail provides metadata; message history
        // would be fetched via a dedicated endpoint if available.
        state = state.copyWith(
          isLoading: false,
          currentConversation: conversation,
          messages: const [],
          error: null,
        );
        AppLogger.info(
          'Opened conversation: $conversationId',
        );
      },
      onFailure: (failure) {
        state = state.copyWith(
          isLoading: false,
          error: _mapFailureToMessage(failure),
        );
        AppLogger.warning(
          'Failed to open conversation: $failure',
        );
      },
    );
  }

  // ─── Create Conversation ───────────────────────────────────────────

  /// Creates a new conversation with the given parameters.
  Future<void> createConversation({
    String title = 'New Conversation',
    String? subjectId,
    String? topic,
    String curriculumType = 'nigerian',
  }) async {
    if (_studentId == null) return;

    state = state.copyWith(isLoading: true, error: null);

    final result = await _createConversation(
      studentId: _studentId!,
      title: title,
      subjectId: subjectId,
      topic: topic,
      curriculumType: curriculumType,
    );

    result.fold(
      onSuccess: (conversation) {
        final updatedList = [conversation, ...state.conversations];
        state = state.copyWith(
          isLoading: false,
          conversations: updatedList,
          currentConversation: conversation,
          messages: const [],
          error: null,
        );
        AppLogger.info('Created conversation: ${conversation.id}');
      },
      onFailure: (failure) {
        state = state.copyWith(
          isLoading: false,
          error: _mapFailureToMessage(failure),
        );
        AppLogger.warning(
          'Failed to create conversation: $failure',
        );
      },
    );
  }

  // ─── Send Message ──────────────────────────────────────────────────

  /// Sends a message in the current conversation and appends the response.
  Future<void> sendMessage(String content) async {
    final conversation = state.currentConversation;
    if (conversation == null || _studentId == null) return;

    state = state.copyWith(isSendingMessage: true, error: null);

    final result = await _sendMessage(
      conversationId: conversation.id,
      content: content,
    );

    result.fold(
      onSuccess: (aiMessage) {
        // Create the user message locally since it was sent.
        final userMessage = AiTutorMessageEntity(
          id: 'local_${DateTime.now().millisecondsSinceEpoch}',
          conversationId: conversation.id,
          role: TutorMessageRole.user,
          content: content,
          createdAt: DateTime.now(),
        );

        final updatedMessages = [...state.messages, userMessage, aiMessage];

        // Update conversation's lastMessage and messageCount.
        final updatedConversation = conversation.copyWith(
          lastMessage: content,
          messageCount: conversation.messageCount + 2,
          updatedAt: DateTime.now(),
        );

        // Update the conversation in the list as well.
        final updatedList = state.conversations
            .map((c) => c.id == conversation.id ? updatedConversation : c)
            .toList();

        state = state.copyWith(
          isSendingMessage: false,
          messages: updatedMessages,
          currentConversation: updatedConversation,
          conversations: updatedList,
          error: null,
        );
        AppLogger.info('Message sent in conversation: ${conversation.id}');
      },
      onFailure: (failure) {
        state = state.copyWith(
          isSendingMessage: false,
          error: _mapFailureToMessage(failure),
        );
        AppLogger.warning('Failed to send message: $failure');
      },
    );
  }

  // ─── Delete Conversation ───────────────────────────────────────────

  /// Deletes a conversation by ID and removes it from the list.
  Future<void> deleteConversation(String conversationId) async {
    state = state.copyWith(isLoading: true, error: null);

    final result = await _deleteConversation(
      conversationId: conversationId,
    );

    result.fold(
      onSuccess: (_) {
        final updatedList = state.conversations
            .where((c) => c.id != conversationId)
            .toList();

        state = state.copyWith(
          isLoading: false,
          conversations: updatedList,
          currentConversation:
              state.currentConversation?.id == conversationId
                  ? null
                  : state.currentConversation,
          messages: state.currentConversation?.id == conversationId
              ? const []
              : state.messages,
          error: null,
        );
        AppLogger.info('Deleted conversation: $conversationId');
      },
      onFailure: (failure) {
        state = state.copyWith(
          isLoading: false,
          error: _mapFailureToMessage(failure),
        );
        AppLogger.warning(
          'Failed to delete conversation: $failure',
        );
      },
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
// AI TUTOR PROVIDER
// ═══════════════════════════════════════════════════════════════════════

/// Provides the [AiTutorNotifier] with all required use cases.
final aiTutorProvider =
    StateNotifierProvider<AiTutorNotifier, AiTutorState>((ref) {
  return AiTutorNotifier(
    getConversations: ref.watch(getConversationsUseCaseProvider),
    getConversationDetail: ref.watch(getConversationDetailUseCaseProvider),
    createConversation: ref.watch(createConversationUseCaseProvider),
    sendMessage: ref.watch(sendMessageUseCaseProvider),
    deleteConversation: ref.watch(deleteConversationUseCaseProvider),
    studentId: ref.watch(currentStudentIdProvider),
  );
});
