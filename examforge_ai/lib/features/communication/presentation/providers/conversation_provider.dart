import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../config/dependency_injection.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/utils/logger.dart';
import '../../domain/entities/communication_entities.dart';
import '../../domain/usecases/archive_conversation_usecase.dart';
import '../../domain/usecases/create_conversation_usecase.dart';
import '../../domain/usecases/get_conversations_usecase.dart';
import '../../domain/usecases/mute_conversation_usecase.dart';

// ═══════════════════════════════════════════════════════════════════════
// CONVERSATION STATE
// ═══════════════════════════════════════════════════════════════════════

/// Immutable state snapshot for the conversation feature.
///
/// Tracks conversations list, the currently selected conversation,
/// loading and creating flags, error message, success message,
/// and total unread count across all conversations.
class ConversationState {
  const ConversationState({
    this.conversations = const [],
    this.currentConversation,
    this.isLoading = false,
    this.isCreating = false,
    this.error,
    this.successMessage,
    this.unreadTotalCount = 0,
    this.participants = const [],
  });

  /// The list of conversations for the current user.
  final List<ConversationEntity> conversations;

  /// The currently selected conversation, or `null`.
  final ConversationEntity? currentConversation;

  /// Whether a load operation is in progress.
  final bool isLoading;

  /// Whether a create operation is in progress.
  final bool isCreating;

  /// The most recent error message, or `null`.
  final String? error;

  /// A transient success message (e.g. "Conversation created"), or `null`.
  final String? successMessage;

  /// The total unread count across all conversations.
  final int unreadTotalCount;

  /// Available participants for creating new conversations.
  final List<ParticipantInfo> participants;

  /// Creates a copy of this state with the given fields replaced.
  ConversationState copyWith({
    List<ConversationEntity>? conversations,
    ConversationEntity? currentConversation,
    bool? isLoading,
    bool? isCreating,
    String? error,
    String? successMessage,
    int? unreadTotalCount,
    List<ParticipantInfo>? participants,
    bool clearCurrentConversation = false,
  }) {
    return ConversationState(
      conversations: conversations ?? this.conversations,
      currentConversation: clearCurrentConversation
          ? null
          : (currentConversation ?? this.currentConversation),
      isLoading: isLoading ?? this.isLoading,
      isCreating: isCreating ?? this.isCreating,
      error: error,
      successMessage: successMessage,
      unreadTotalCount: unreadTotalCount ?? this.unreadTotalCount,
      participants: participants ?? this.participants,
    );
  }

  /// Clears the current error message.
  ConversationState clearError() => copyWith(error: null);
}

/// Lightweight model for available participants in conversations.
class ParticipantInfo {
  const ParticipantInfo({
    required this.id,
    required this.name,
    this.role,
    this.avatarUrl,
  });

  final String id;
  final String name;
  final String? role;
  final String? avatarUrl;
}

// ═══════════════════════════════════════════════════════════════════════
// CONVERSATION NOTIFIER
// ═══════════════════════════════════════════════════════════════════════

/// Riverpod [StateNotifier] that manages the conversation feature's state.
///
/// All conversation operations flow through this notifier, which:
/// 1. Sets the appropriate loading flag before each async operation
/// 2. Delegates to the relevant use case
/// 3. Updates conversations and metadata on success
/// 4. Sets [error] on failure
class ConversationNotifier extends StateNotifier<ConversationState> {
  ConversationNotifier({
    required GetConversationsUseCase getConversationsUseCase,
    required CreateConversationUseCase createConversationUseCase,
    required MuteConversationUseCase muteConversationUseCase,
    required ArchiveConversationUseCase archiveConversationUseCase,
  })  : _getConversationsUseCase = getConversationsUseCase,
        _createConversationUseCase = createConversationUseCase,
        _muteConversationUseCase = muteConversationUseCase,
        _archiveConversationUseCase = archiveConversationUseCase,
        super(const ConversationState());

  final GetConversationsUseCase _getConversationsUseCase;
  final CreateConversationUseCase _createConversationUseCase;
  final MuteConversationUseCase _muteConversationUseCase;
  final ArchiveConversationUseCase _archiveConversationUseCase;

  // ─── Load Conversations ─────────────────────────────────────────────

  /// Loads the conversations list for the current user.
  Future<void> loadConversations() async {
    state = state.copyWith(isLoading: true, error: null);

    final result = await _getConversationsUseCase(
      const GetConversationsParams(page: 1, perPage: 50),
    );

    result.fold(
      onSuccess: (conversations) {
        final totalUnread = conversations.fold<int>(
          0,
          (sum, c) => sum + c.unreadCount,
        );
        state = state.copyWith(
          isLoading: false,
          conversations: conversations,
          unreadTotalCount: totalUnread,
          error: null,
        );
        AppLogger.info(
          'Conversations loaded (${conversations.length} conversations)',
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

  // ─── Load Conversation ──────────────────────────────────────────────

  /// Loads a single conversation by [id] and sets it as currentConversation.
  Future<void> loadConversation(String id) async {
    state = state.copyWith(isLoading: true, error: null);

    final result = await _getConversationsUseCase(
      const GetConversationsParams(page: 1, perPage: 50),
    );

    result.fold(
      onSuccess: (conversations) {
        final conversation = conversations.where((c) => c.id == id).firstOrNull;
        state = state.copyWith(
          isLoading: false,
          currentConversation: conversation,
          error: null,
        );
        AppLogger.info(
          'Conversation loaded: $id (${conversation != null ? "found" : "not found"})',
        );
      },
      onFailure: (failure) {
        state = state.copyWith(
          isLoading: false,
          error: _mapFailureToMessage(failure),
        );
        AppLogger.warning('Failed to load conversation: $failure');
      },
    );
  }

  // ─── Create Conversation ────────────────────────────────────────────

  /// Creates a new conversation with the provided [params].
  Future<void> createConversation(CreateConversationParams params) async {
    state = state.copyWith(isCreating: true, error: null);

    final result = await _createConversationUseCase(params);

    result.fold(
      onSuccess: (conversation) {
        final updatedConversations = [conversation, ...state.conversations];
        state = state.copyWith(
          isCreating: false,
          conversations: updatedConversations,
          currentConversation: conversation,
          successMessage: 'Conversation created successfully',
          error: null,
        );
        AppLogger.info('Conversation created: ${conversation.id}');
      },
      onFailure: (failure) {
        state = state.copyWith(
          isCreating: false,
          error: _mapFailureToMessage(failure),
        );
        AppLogger.warning('Failed to create conversation: $failure');
      },
    );
  }

  // ─── Mute Conversation ─────────────────────────────────────────────

  /// Mutes the conversation with the given [id].
  Future<void> muteConversation(String id) async {
    state = state.copyWith(isLoading: true, error: null);

    final result = await _muteConversationUseCase(
      MuteConversationParams(conversationId: id),
    );

    result.fold(
      onSuccess: (_) {
        final updatedConversations = state.conversations.map((c) {
          if (c.id == id) {
            return c.copyWith(isMuted: true);
          }
          return c;
        }).toList();
        final updatedCurrent = state.currentConversation?.id == id
            ? state.currentConversation!.copyWith(isMuted: true)
            : state.currentConversation;
        state = state.copyWith(
          isLoading: false,
          conversations: updatedConversations,
          currentConversation: updatedCurrent,
          successMessage: 'Conversation muted successfully',
          error: null,
        );
        AppLogger.info('Conversation muted: $id');
      },
      onFailure: (failure) {
        state = state.copyWith(
          isLoading: false,
          error: _mapFailureToMessage(failure),
        );
        AppLogger.warning('Failed to mute conversation: $failure');
      },
    );
  }

  // ─── Archive Conversation ──────────────────────────────────────────

  /// Archives the conversation with the given [id].
  Future<void> archiveConversation(String id) async {
    state = state.copyWith(isLoading: true, error: null);

    final result = await _archiveConversationUseCase(
      ArchiveConversationParams(conversationId: id),
    );

    result.fold(
      onSuccess: (_) {
        final updatedConversations = state.conversations.map((c) {
          if (c.id == id) {
            return c.copyWith(isArchived: true);
          }
          return c;
        }).toList();
        final updatedCurrent = state.currentConversation?.id == id
            ? state.currentConversation!.copyWith(isArchived: true)
            : state.currentConversation;
        state = state.copyWith(
          isLoading: false,
          conversations: updatedConversations,
          currentConversation: updatedCurrent,
          successMessage: 'Conversation archived successfully',
          error: null,
        );
        AppLogger.info('Conversation archived: $id');
      },
      onFailure: (failure) {
        state = state.copyWith(
          isLoading: false,
          error: _mapFailureToMessage(failure),
        );
        AppLogger.warning('Failed to archive conversation: $failure');
      },
    );
  }

  // ─── Leave Conversation ─────────────────────────────────────────────

  /// Leaves the conversation with the given [id] by archiving it.
  Future<void> leaveConversation(String id) async {
    state = state.copyWith(isLoading: true, error: null);

    final result = await _archiveConversationUseCase(
      ArchiveConversationParams(conversationId: id),
    );

    result.fold(
      onSuccess: (_) {
        final updatedConversations =
            state.conversations.where((c) => c.id != id).toList();
        final updatedCurrent = state.currentConversation?.id == id
            ? null
            : state.currentConversation;
        state = state.copyWith(
          isLoading: false,
          conversations: updatedConversations,
          currentConversation: updatedCurrent,
          successMessage: 'Left conversation successfully',
          error: null,
          clearCurrentConversation: state.currentConversation?.id == id,
        );
        AppLogger.info('Left conversation: $id');
      },
      onFailure: (failure) {
        state = state.copyWith(
          isLoading: false,
          error: _mapFailureToMessage(failure),
        );
        AppLogger.warning('Failed to leave conversation: $failure');
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
// CONVERSATION PROVIDER
// ═══════════════════════════════════════════════════════════════════════

final conversationProvider =
    StateNotifierProvider<ConversationNotifier, ConversationState>((ref) {
  return ConversationNotifier(
    getConversationsUseCase: ref.watch(getConversationsUseCaseProvider),
    createConversationUseCase: ref.watch(createConversationUseCaseProvider),
    muteConversationUseCase: ref.watch(muteConversationUseCaseProvider),
    archiveConversationUseCase: ref.watch(archiveConversationUseCaseProvider),
  );
});
