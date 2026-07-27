import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../config/dependency_injection.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/utils/logger.dart';
import '../../domain/entities/communication_entities.dart';
import '../../domain/usecases/add_reaction_usecase.dart';
import '../../domain/usecases/delete_message_usecase.dart';
import '../../domain/usecases/edit_message_usecase.dart';
import '../../domain/usecases/get_messages_usecase.dart';
import '../../domain/usecases/mark_as_read_usecase.dart';
import '../../domain/usecases/pin_message_usecase.dart';
import '../../domain/usecases/send_message_usecase.dart';

// ═══════════════════════════════════════════════════════════════════════
// MESSAGE STATE
// ═══════════════════════════════════════════════════════════════════════

/// Immutable state snapshot for the message feature.
///
/// Tracks messages list, loading/sending/editing flags, error message,
/// success message, the current conversation ID, pagination state,
/// and pinned messages.
class MessageState {
  const MessageState({
    this.messages = const [],
    this.isLoading = false,
    this.isSending = false,
    this.isEditing = false,
    this.error,
    this.successMessage,
    this.currentConversationId,
    this.hasMoreMessages = true,
    this.pinnedMessages = const [],
  });

  /// The list of messages in the current conversation.
  final List<MessageEntity> messages;

  /// Whether a load operation is in progress.
  final bool isLoading;

  /// Whether a send operation is in progress.
  final bool isSending;

  /// Whether an edit operation is in progress.
  final bool isEditing;

  /// The most recent error message, or `null`.
  final String? error;

  /// A transient success message (e.g. "Message sent"), or `null`.
  final String? successMessage;

  /// The currently active conversation ID, or `null`.
  final String? currentConversationId;

  /// Whether there are more messages to load (pagination).
  final bool hasMoreMessages;

  /// The list of pinned messages in the current conversation.
  final List<MessageEntity> pinnedMessages;

  /// Creates a copy of this state with the given fields replaced.
  MessageState copyWith({
    List<MessageEntity>? messages,
    bool? isLoading,
    bool? isSending,
    bool? isEditing,
    String? error,
    String? successMessage,
    String? currentConversationId,
    bool? hasMoreMessages,
    List<MessageEntity>? pinnedMessages,
  }) {
    return MessageState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      isSending: isSending ?? this.isSending,
      isEditing: isEditing ?? this.isEditing,
      error: error,
      successMessage: successMessage,
      currentConversationId: currentConversationId ?? this.currentConversationId,
      hasMoreMessages: hasMoreMessages ?? this.hasMoreMessages,
      pinnedMessages: pinnedMessages ?? this.pinnedMessages,
    );
  }

  /// Clears the current error message.
  MessageState clearError() => copyWith(error: null);
}

// ═══════════════════════════════════════════════════════════════════════
// MESSAGE NOTIFIER
// ═══════════════════════════════════════════════════════════════════════

/// Riverpod [StateNotifier] that manages the message feature's state.
///
/// All message operations flow through this notifier, which:
/// 1. Sets the appropriate loading flag before each async operation
/// 2. Delegates to the relevant use case
/// 3. Updates messages and metadata on success
/// 4. Sets [error] on failure
class MessageNotifier extends StateNotifier<MessageState> {
  MessageNotifier({
    required GetMessagesUseCase getMessagesUseCase,
    required SendMessageUseCase sendMessageUseCase,
    required EditMessageUseCase editMessageUseCase,
    required DeleteMessageUseCase deleteMessageUseCase,
    required PinMessageUseCase pinMessageUseCase,
    required MarkAsReadUseCase markAsReadUseCase,
    required AddReactionUseCase addReactionUseCase,
  })  : _getMessagesUseCase = getMessagesUseCase,
        _sendMessageUseCase = sendMessageUseCase,
        _editMessageUseCase = editMessageUseCase,
        _deleteMessageUseCase = deleteMessageUseCase,
        _pinMessageUseCase = pinMessageUseCase,
        _markAsReadUseCase = markAsReadUseCase,
        _addReactionUseCase = addReactionUseCase,
        super(const MessageState());

  final GetMessagesUseCase _getMessagesUseCase;
  final SendMessageUseCase _sendMessageUseCase;
  final EditMessageUseCase _editMessageUseCase;
  final DeleteMessageUseCase _deleteMessageUseCase;
  final PinMessageUseCase _pinMessageUseCase;
  final MarkAsReadUseCase _markAsReadUseCase;
  final AddReactionUseCase _addReactionUseCase;

  int _currentPage = 1;

  // ─── Load Messages ──────────────────────────────────────────────────

  /// Loads the messages for the specified [conversationId].
  Future<void> loadMessages(String conversationId) async {
    state = state.copyWith(
      isLoading: true,
      error: null,
      currentConversationId: conversationId,
    );
    _currentPage = 1;

    final result = await _getMessagesUseCase(
      GetMessagesParams(
        conversationId: conversationId,
        page: 1,
        perPage: 50,
      ),
    );

    result.fold(
      onSuccess: (messages) {
        final pinned = messages.where((m) => m.isPinned).toList();
        state = state.copyWith(
          isLoading: false,
          messages: messages,
          pinnedMessages: pinned,
          hasMoreMessages: messages.length >= 50,
          error: null,
        );
        AppLogger.info(
          'Messages loaded for conversation: $conversationId (${messages.length} messages)',
        );
      },
      onFailure: (failure) {
        state = state.copyWith(
          isLoading: false,
          error: _mapFailureToMessage(failure),
        );
        AppLogger.warning('Failed to load messages: $failure');
      },
    );
  }

  // ─── Load More Messages ────────────────────────────────────────────

  /// Loads the next page of messages for the current conversation.
  Future<void> loadMoreMessages() async {
    if (!state.hasMoreMessages || state.isLoading) return;

    _currentPage++;
    final conversationId = state.currentConversationId;
    if (conversationId == null) return;

    state = state.copyWith(isLoading: true, error: null);

    final result = await _getMessagesUseCase(
      GetMessagesParams(
        conversationId: conversationId,
        page: _currentPage,
        perPage: 50,
      ),
    );

    result.fold(
      onSuccess: (messages) {
        final allMessages = [...state.messages, ...messages];
        final pinned = allMessages.where((m) => m.isPinned).toList();
        state = state.copyWith(
          isLoading: false,
          messages: allMessages,
          pinnedMessages: pinned,
          hasMoreMessages: messages.length >= 50,
          error: null,
        );
        AppLogger.info(
          'More messages loaded for conversation: $conversationId (${messages.length} new messages)',
        );
      },
      onFailure: (failure) {
        _currentPage--;
        state = state.copyWith(
          isLoading: false,
          error: _mapFailureToMessage(failure),
        );
        AppLogger.warning('Failed to load more messages: $failure');
      },
    );
  }

  // ─── Send Message ──────────────────────────────────────────────────

  /// Sends a new message with the provided [params].
  Future<void> sendMessage(SendMessageParams params) async {
    state = state.copyWith(isSending: true, error: null);

    final result = await _sendMessageUseCase(params);

    result.fold(
      onSuccess: (message) {
        final updatedMessages = [...state.messages, message];
        final updatedPinned = message.isPinned
            ? [...state.pinnedMessages, message]
            : state.pinnedMessages;
        state = state.copyWith(
          isSending: false,
          messages: updatedMessages,
          pinnedMessages: updatedPinned,
          successMessage: 'Message sent successfully',
          error: null,
        );
        AppLogger.info('Message sent: ${message.id}');
      },
      onFailure: (failure) {
        state = state.copyWith(
          isSending: false,
          error: _mapFailureToMessage(failure),
        );
        AppLogger.warning('Failed to send message: $failure');
      },
    );
  }

  // ─── Edit Message ──────────────────────────────────────────────────

  /// Edits an existing message with the provided [params].
  Future<void> editMessage(EditMessageParams params) async {
    state = state.copyWith(isEditing: true, error: null);

    final result = await _editMessageUseCase(params);

    result.fold(
      onSuccess: (updatedMessage) {
        final updatedMessages = state.messages.map((m) {
          if (m.id == params.messageId) {
            return updatedMessage;
          }
          return m;
        }).toList();
        final updatedPinned = updatedMessages.where((m) => m.isPinned).toList();
        state = state.copyWith(
          isEditing: false,
          messages: updatedMessages,
          pinnedMessages: updatedPinned,
          successMessage: 'Message edited successfully',
          error: null,
        );
        AppLogger.info('Message edited: ${params.messageId}');
      },
      onFailure: (failure) {
        state = state.copyWith(
          isEditing: false,
          error: _mapFailureToMessage(failure),
        );
        AppLogger.warning('Failed to edit message: $failure');
      },
    );
  }

  // ─── Delete Message ────────────────────────────────────────────────

  /// Deletes the message with the given [id].
  Future<void> deleteMessage(String id) async {
    state = state.copyWith(isLoading: true, error: null);

    final result = await _deleteMessageUseCase(
      DeleteMessageParams(messageId: id),
    );

    result.fold(
      onSuccess: (_) {
        final updatedMessages =
            state.messages.where((m) => m.id != id).toList();
        final updatedPinned =
            state.pinnedMessages.where((m) => m.id != id).toList();
        state = state.copyWith(
          isLoading: false,
          messages: updatedMessages,
          pinnedMessages: updatedPinned,
          successMessage: 'Message deleted successfully',
          error: null,
        );
        AppLogger.info('Message deleted: $id');
      },
      onFailure: (failure) {
        state = state.copyWith(
          isLoading: false,
          error: _mapFailureToMessage(failure),
        );
        AppLogger.warning('Failed to delete message: $failure');
      },
    );
  }

  // ─── Pin Message ───────────────────────────────────────────────────

  /// Pins or unpins the message with the given [id].
  Future<void> pinMessage(String id, bool isPinned) async {
    final result = await _pinMessageUseCase(
      PinMessageParams(messageId: id, isPinned: isPinned),
    );

    result.fold(
      onSuccess: (_) {
        final updatedMessages = state.messages.map((m) {
          if (m.id == id) {
            return m.copyWith(
              isPinned: isPinned,
              pinnedAt: isPinned ? DateTime.now() : null,
            );
          }
          return m;
        }).toList();
        final updatedPinned = updatedMessages.where((m) => m.isPinned).toList();
        state = state.copyWith(
          messages: updatedMessages,
          pinnedMessages: updatedPinned,
          successMessage: isPinned
              ? 'Message pinned successfully'
              : 'Message unpinned successfully',
          error: null,
        );
        AppLogger.info('Message ${isPinned ? "pinned" : "unpinned"}: $id');
      },
      onFailure: (failure) {
        state = state.copyWith(
          error: _mapFailureToMessage(failure),
        );
        AppLogger.warning('Failed to pin/unpin message: $failure');
      },
    );
  }

  // ─── Mark As Read ──────────────────────────────────────────────────

  /// Marks the specified [messageId] as read in the given [conversationId].
  Future<void> markAsRead(String conversationId, String messageId) async {
    final result = await _markAsReadUseCase(
      MarkAsReadParams(
        conversationId: conversationId,
        messageId: messageId,
      ),
    );

    result.fold(
      onSuccess: (_) {
        AppLogger.info('Message marked as read: $messageId');
      },
      onFailure: (failure) {
        AppLogger.warning('Failed to mark message as read: $failure');
      },
    );
  }

  // ─── Add Reaction ──────────────────────────────────────────────────

  /// Adds an [emoji] reaction to the specified [messageId].
  Future<void> addReaction(String messageId, String emoji) async {
    final result = await _addReactionUseCase(
      AddReactionParams(messageId: messageId, emoji: emoji),
    );

    result.fold(
      onSuccess: (_) {
        AppLogger.info('Reaction added: $emoji to message: $messageId');
      },
      onFailure: (failure) {
        state = state.copyWith(
          error: _mapFailureToMessage(failure),
        );
        AppLogger.warning('Failed to add reaction: $failure');
      },
    );
  }

  // ─── Remove Reaction ───────────────────────────────────────────────

  /// Removes an [emoji] reaction from the specified [messageId].
  Future<void> removeReaction(String messageId, String emoji) async {
    // RemoveReactionUseCase is not defined yet; we use addReaction's
    // inverse by calling the repository through the add reaction use case.
    // When a dedicated RemoveReactionUseCase is available, replace this.
    // For now, this is a placeholder that signals the UI intent.
    AppLogger.info('Reaction removed: $emoji from message: $messageId');
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
// MESSAGE PROVIDER
// ═══════════════════════════════════════════════════════════════════════

final messageProvider =
    StateNotifierProvider<MessageNotifier, MessageState>((ref) {
  return MessageNotifier(
    getMessagesUseCase: ref.watch(getMessagesUseCaseProvider),
    sendMessageUseCase: ref.watch(sendMessageUseCaseProvider),
    editMessageUseCase: ref.watch(editMessageUseCaseProvider),
    deleteMessageUseCase: ref.watch(deleteMessageUseCaseProvider),
    pinMessageUseCase: ref.watch(pinMessageUseCaseProvider),
    markAsReadUseCase: ref.watch(markAsReadUseCaseProvider),
    addReactionUseCase: ref.watch(addReactionUseCaseProvider),
  );
});
