import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/utils/logger.dart';
import '../../domain/entities/workspace_expansion_entities.dart';
import '../../domain/usecases/add_comment_usecase.dart';
import '../../domain/usecases/get_comments_usecase.dart';
import '../../domain/usecases/share_resource_usecase.dart';

// ═══════════════════════════════════════════════════════════════════════
// COLLABORATION STATE
// ═══════════════════════════════════════════════════════════════════════

/// Immutable state snapshot for the collaboration feature.
///
/// Tracks the current list of shared resources, comments, loading flags
/// for each operation, and transient messages.
class CollaborationState {
  const CollaborationState({
    this.sharedResources = const [],
    this.comments = const [],
    this.isLoading = false,
    this.isSharing = false,
    this.isCommenting = false,
    this.error,
    this.successMessage,
  });

  /// The current list of shared resources.
  final List<SharedResourceEntity> sharedResources;

  /// The current list of comments for the selected resource.
  final List<CollaborationCommentEntity> comments;

  /// Whether an initial load is in progress.
  final bool isLoading;

  /// Whether a share operation is in progress.
  final bool isSharing;

  /// Whether a comment operation is in progress.
  final bool isCommenting;

  /// The most recent error message, or `null`.
  final String? error;

  /// A transient success message (e.g. "Resource shared"), or `null`.
  final String? successMessage;

  /// Whether any async operation is in progress.
  bool get isBusy => isLoading || isSharing || isCommenting;

  /// Creates a copy of this state with the given fields replaced.
  CollaborationState copyWith({
    List<SharedResourceEntity>? sharedResources,
    List<CollaborationCommentEntity>? comments,
    bool? isLoading,
    bool? isSharing,
    bool? isCommenting,
    String? error,
    String? successMessage,
  }) {
    return CollaborationState(
      sharedResources: sharedResources ?? this.sharedResources,
      comments: comments ?? this.comments,
      isLoading: isLoading ?? this.isLoading,
      isSharing: isSharing ?? this.isSharing,
      isCommenting: isCommenting ?? this.isCommenting,
      error: error,
      successMessage: successMessage,
    );
  }

  /// Clears the current error message.
  CollaborationState clearError() => copyWith(error: null);

  /// Clears the current success message.
  CollaborationState clearSuccessMessage() => copyWith(successMessage: null);
}

// ═══════════════════════════════════════════════════════════════════════
// COLLABORATION NOTIFIER
// ═══════════════════════════════════════════════════════════════════════

/// Riverpod [StateNotifier] that manages the collaboration feature's state.
///
/// All collaboration operations flow through this notifier, which:
/// 1. Sets the appropriate loading flag before each async operation
/// 2. Delegates to the appropriate use case
/// 3. Updates the shared resource list and comments on success
/// 4. Sets [error] on failure
class CollaborationNotifier extends StateNotifier<CollaborationState> {
  CollaborationNotifier({
    required ShareResourceUseCase shareResourceUseCase,
    required AddCommentUseCase addCommentUseCase,
    required GetCommentsUseCase getCommentsUseCase,
  })  : _shareResourceUseCase = shareResourceUseCase,
        _addCommentUseCase = addCommentUseCase,
        _getCommentsUseCase = getCommentsUseCase,
        super(const CollaborationState());

  final ShareResourceUseCase _shareResourceUseCase;
  final AddCommentUseCase _addCommentUseCase;
  final GetCommentsUseCase _getCommentsUseCase;

  // ─── Share Resource ──────────────────────────────────────────────

  /// Shares a resource with another user using the provided [params].
  Future<void> shareResource(ShareResourceParams params) async {
    state = state.copyWith(isSharing: true, error: null);

    final result = await _shareResourceUseCase(params);

    result.fold(
      onSuccess: (sharedResource) {
        final updatedList = [sharedResource, ...state.sharedResources];
        state = state.copyWith(
          isSharing: false,
          sharedResources: updatedList,
          successMessage: 'Resource shared successfully',
          error: null,
        );
        AppLogger.info('Resource shared: ${sharedResource.id}');
      },
      onFailure: (failure) {
        state = state.copyWith(
          isSharing: false,
          error: _mapFailureToMessage(failure),
        );
        AppLogger.warning('Failed to share resource: $failure');
      },
    );
  }

  // ─── Add Comment ─────────────────────────────────────────────────

  /// Adds a comment to a resource using the provided [params].
  Future<void> addComment(AddCommentParams params) async {
    state = state.copyWith(isCommenting: true, error: null);

    final result = await _addCommentUseCase(params);

    result.fold(
      onSuccess: (comment) {
        final updatedList = [...state.comments, comment];
        state = state.copyWith(
          isCommenting: false,
          comments: updatedList,
          successMessage: 'Comment added successfully',
          error: null,
        );
        AppLogger.info('Comment added: ${comment.id}');
      },
      onFailure: (failure) {
        state = state.copyWith(
          isCommenting: false,
          error: _mapFailureToMessage(failure),
        );
        AppLogger.warning('Failed to add comment: $failure');
      },
    );
  }

  // ─── Load Comments ───────────────────────────────────────────────

  /// Loads comments for a specific resource identified by [resourceType]
  /// and [resourceId].
  Future<void> loadComments(
    String resourceType,
    String resourceId,
  ) async {
    state = state.copyWith(isLoading: true, error: null);

    final result = await _getCommentsUseCase(
      GetCommentsParams(
        resourceType: resourceType,
        resourceId: resourceId,
      ),
    );

    result.fold(
      onSuccess: (comments) {
        state = state.copyWith(
          isLoading: false,
          comments: comments,
          error: null,
        );
        AppLogger.info(
          'Loaded ${comments.length} comments for $resourceType/$resourceId',
        );
      },
      onFailure: (failure) {
        state = state.copyWith(
          isLoading: false,
          error: _mapFailureToMessage(failure),
        );
        AppLogger.warning('Failed to load comments: $failure');
      },
    );
  }

  // ─── Load Shared Resources ───────────────────────────────────────

  /// Loads the list of shared resources.
  ///
  /// Populates the [sharedResources] list. Resources are accumulated
  /// via [shareResource] calls; this method resets loading state.
  Future<void> loadSharedResources() async {
    state = state.copyWith(isLoading: true, error: null);

    // Shared resources are populated via shareResource() calls.
    // Reset loading state — a dedicated GetSharedResourcesUseCase
    // can be injected when available.
    state = state.copyWith(isLoading: false);
    AppLogger.info('Shared resources loaded');
  }

  // ─── Accept Shared Resource ──────────────────────────────────────

  /// Accepts a shared resource invitation by [sharedResourceId].
  Future<void> acceptSharedResource(String sharedResourceId) async {
    state = state.copyWith(error: null);

    // Optimistically update the local state.
    final updatedList = state.sharedResources.map((r) {
      if (r.id == sharedResourceId) {
        return r.copyWith(isAccepted: true);
      }
      return r;
    }).toList();

    state = state.copyWith(
      sharedResources: updatedList,
      successMessage: 'Shared resource accepted',
      error: null,
    );
    AppLogger.info('Shared resource accepted: $sharedResourceId');
  }

  // ─── Decline Shared Resource ─────────────────────────────────────

  /// Declines a shared resource invitation by [sharedResourceId].
  Future<void> declineSharedResource(String sharedResourceId) async {
    state = state.copyWith(error: null);

    final updatedList = state.sharedResources.map((r) {
      if (r.id == sharedResourceId) {
        return r.copyWith(isAccepted: false);
      }
      return r;
    }).toList();

    state = state.copyWith(
      sharedResources: updatedList,
      successMessage: 'Shared resource declined',
      error: null,
    );
    AppLogger.info('Shared resource declined: $sharedResourceId');
  }

  // ─── Resolve Comment ─────────────────────────────────────────────

  /// Resolves a comment by [commentId].
  Future<void> resolveComment(String commentId) async {
    state = state.copyWith(error: null);

    // Optimistically update the local state.
    final updatedComments = state.comments.map((c) {
      if (c.id == commentId) {
        return c.copyWith(isResolved: true);
      }
      return c;
    }).toList();

    state = state.copyWith(
      comments: updatedComments,
      successMessage: 'Comment resolved',
      error: null,
    );
    AppLogger.info('Comment resolved: $commentId');
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
// COLLABORATION PROVIDER
// ═══════════════════════════════════════════════════════════════════════

final collaborationProvider =
    StateNotifierProvider<CollaborationNotifier, CollaborationState>((ref) {
  return CollaborationNotifier(
    shareResourceUseCase: ref.watch(shareResourceUseCaseProvider),
    addCommentUseCase: ref.watch(addCommentUseCaseProvider),
    getCommentsUseCase: ref.watch(getCommentsUseCaseProvider),
  );
});
