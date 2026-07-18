import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/utils/logger.dart';
import '../../domain/entities/parent_portal_entities.dart';
import '../../domain/usecases/get_parent_messages_usecase.dart';
import '../../domain/usecases/get_message_threads_usecase.dart';
import '../../domain/usecases/mark_message_read_usecase.dart';
import '../../domain/usecases/send_parent_message_usecase.dart';

// ═══════════════════════════════════════════════════════════════════════
// PARENT MESSAGING STATE
// ═══════════════════════════════════════════════════════════════════════

/// Immutable state snapshot for the parent messaging feature.
///
/// Tracks messages, threads, loading and sending flags, error message,
/// the current thread ID, and a transient success message.
class ParentMessagingState {
  const ParentMessagingState({
    this.messages = const [],
    this.threads = const [],
    this.isLoading = false,
    this.isSending = false,
    this.error,
    this.currentThreadId,
    this.successMessage,
  });

  /// The list of messages in the current thread.
  final List<ParentMessageEntity> messages;

  /// The list of message threads for the current parent.
  final List<ParentMessageThreadEntity> threads;

  /// Whether a load operation is in progress.
  final bool isLoading;

  /// Whether a send operation is in progress.
  final bool isSending;

  /// The most recent error message, or `null`.
  final String? error;

  /// The currently selected thread ID, or `null`.
  final String? currentThreadId;

  /// A transient success message (e.g. "Message sent"), or `null`.
  final String? successMessage;

  /// Creates a copy of this state with the given fields replaced.
  ParentMessagingState copyWith({
    List<ParentMessageEntity>? messages,
    List<ParentMessageThreadEntity>? threads,
    bool? isLoading,
    bool? isSending,
    String? error,
    String? currentThreadId,
    String? successMessage,
  }) {
    return ParentMessagingState(
      messages: messages ?? this.messages,
      threads: threads ?? this.threads,
      isLoading: isLoading ?? this.isLoading,
      isSending: isSending ?? this.isSending,
      error: error,
      currentThreadId: currentThreadId ?? this.currentThreadId,
      successMessage: successMessage,
    );
  }

  /// Clears the current error message.
  ParentMessagingState clearError() => copyWith(error: null);
}

// ═══════════════════════════════════════════════════════════════════════
// PARENT MESSAGING NOTIFIER
// ═══════════════════════════════════════════════════════════════════════

/// Riverpod [StateNotifier] that manages the parent messaging feature's state.
///
/// All messaging operations flow through this notifier, which:
/// 1. Sets the appropriate loading flag before each async operation
/// 2. Delegates to the relevant use case
/// 3. Updates messages, threads, and metadata on success
/// 4. Sets [error] on failure
class ParentMessagingNotifier extends StateNotifier<ParentMessagingState> {
  ParentMessagingNotifier({
    required SendParentMessageUseCase sendParentMessageUseCase,
    required GetParentMessagesUseCase getParentMessagesUseCase,
    required GetMessageThreadsUseCase getParentThreadsUseCase,
    required MarkMessageReadUseCase markMessageReadUseCase,
  })  : _sendParentMessageUseCase = sendParentMessageUseCase,
        _getParentMessagesUseCase = getParentMessagesUseCase,
        _getParentThreadsUseCase = getParentThreadsUseCase,
        _markMessageReadUseCase = markMessageReadUseCase,
        super(const ParentMessagingState());

  final SendParentMessageUseCase _sendParentMessageUseCase;
  final GetParentMessagesUseCase _getParentMessagesUseCase;
  final GetMessageThreadsUseCase _getParentThreadsUseCase;
  final MarkMessageReadUseCase _markMessageReadUseCase;

  // ─── Load Threads ──────────────────────────────────────────────────

  /// Loads the message threads for the current parent.
  Future<void> loadThreads() async {
    state = state.copyWith(isLoading: true, error: null);

    final result = await _getParentThreadsUseCase(
      const GetMessageThreadsParams(page: 1, perPage: 50),
    );

    result.fold(
      onSuccess: (threads) {
        state = state.copyWith(
          isLoading: false,
          threads: threads,
          error: null,
        );
        AppLogger.info('Parent threads loaded (${threads.length} threads)');
      },
      onFailure: (failure) {
        state = state.copyWith(
          isLoading: false,
          error: _mapFailureToMessage(failure),
        );
        AppLogger.warning('Failed to load parent threads: $failure');
      },
    );
  }

  // ─── Load Messages ─────────────────────────────────────────────────

  /// Loads the messages for the specified [threadId].
  Future<void> loadMessages(String threadId) async {
    state = state.copyWith(
      isLoading: true,
      error: null,
      currentThreadId: threadId,
    );

    final result = await _getParentMessagesUseCase(
      GetParentMessagesParams(
        threadId: threadId,
        page: 1,
        perPage: 50,
      ),
    );

    result.fold(
      onSuccess: (messages) {
        state = state.copyWith(
          isLoading: false,
          messages: messages,
          error: null,
        );
        AppLogger.info(
          'Parent messages loaded for thread: $threadId (${messages.length} messages)',
        );
      },
      onFailure: (failure) {
        state = state.copyWith(
          isLoading: false,
          error: _mapFailureToMessage(failure),
        );
        AppLogger.warning('Failed to load parent messages: $failure');
      },
    );
  }

  // ─── Send Message ──────────────────────────────────────────────────

  /// Sends a new message with the provided [params].
  Future<void> sendMessage(SendMessageParams params) async {
    state = state.copyWith(isSending: true, error: null);

    final result = await _sendParentMessageUseCase(params);

    result.fold(
      onSuccess: (message) {
        final updatedMessages = [...state.messages, message];
        state = state.copyWith(
          isSending: false,
          messages: updatedMessages,
          successMessage: 'Message sent successfully',
          error: null,
        );
        AppLogger.info('Parent message sent: ${message.id}');
      },
      onFailure: (failure) {
        state = state.copyWith(
          isSending: false,
          error: _mapFailureToMessage(failure),
        );
        AppLogger.warning('Failed to send parent message: $failure');
      },
    );
  }

  // ─── Mark As Read ──────────────────────────────────────────────────

  /// Marks the specified [messageId] as read.
  Future<void> markAsRead(String messageId) async {
    final result = await _markMessageReadUseCase(
      MarkMessageReadParams(messageId: messageId),
    );

    result.fold(
      onSuccess: (_) {
        final updatedMessages = state.messages.map((m) {
          if (m.id == messageId) {
            return m.copyWith(isRead: true);
          }
          return m;
        }).toList();
        state = state.copyWith(messages: updatedMessages);
        AppLogger.info('Parent message marked as read: $messageId');
      },
      onFailure: (failure) {
        state = state.copyWith(
          error: _mapFailureToMessage(failure),
        );
        AppLogger.warning('Failed to mark message as read: $failure');
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
// PARENT MESSAGING PROVIDER
// ═══════════════════════════════════════════════════════════════════════

final parentMessagingProvider =
    StateNotifierProvider<ParentMessagingNotifier, ParentMessagingState>(
        (ref) {
  return ParentMessagingNotifier(
    sendParentMessageUseCase: ref.watch(sendParentMessageUseCaseProvider),
    getParentMessagesUseCase: ref.watch(getParentMessagesUseCaseProvider),
    getParentThreadsUseCase: ref.watch(getMessageThreadsUseCaseProvider),
    markMessageReadUseCase: ref.watch(markMessageReadUseCaseProvider),
  );
});
