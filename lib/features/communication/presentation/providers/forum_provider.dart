import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../config/dependency_injection.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/utils/logger.dart';
import '../../domain/entities/communication_entities.dart';
import '../../domain/usecases/create_forum_comment_usecase.dart';
import '../../domain/usecases/create_forum_post_usecase.dart';
import '../../domain/usecases/create_forum_usecase.dart';
import '../../domain/usecases/get_forum_posts_usecase.dart';
import '../../domain/usecases/get_forums_usecase.dart';

// ═══════════════════════════════════════════════════════════════════════
// FORUM STATE
// ═══════════════════════════════════════════════════════════════════════

/// Immutable state snapshot for the discussion forum feature.
///
/// Tracks forums list, the currently selected forum, forum posts,
/// forum comments, loading and creating flags, error message,
/// and success message.
class ForumState {
  const ForumState({
    this.forums = const [],
    this.currentForum,
    this.forumPosts = const [],
    this.forumComments = const [],
    this.isLoading = false,
    this.isCreating = false,
    this.error,
    this.successMessage,
  });

  /// The list of discussion forums.
  final List<DiscussionForumEntity> forums;

  /// The currently selected forum, or `null`.
  final DiscussionForumEntity? currentForum;

  /// The list of posts in the current forum.
  final List<ForumPostEntity> forumPosts;

  /// The list of comments for the current forum post.
  final List<ForumCommentEntity> forumComments;

  /// Whether a load operation is in progress.
  final bool isLoading;

  /// Whether a create operation is in progress.
  final bool isCreating;

  /// The most recent error message, or `null`.
  final String? error;

  /// A transient success message (e.g. "Forum created"), or `null`.
  final String? successMessage;

  /// Creates a copy of this state with the given fields replaced.
  ForumState copyWith({
    List<DiscussionForumEntity>? forums,
    DiscussionForumEntity? currentForum,
    List<ForumPostEntity>? forumPosts,
    List<ForumCommentEntity>? forumComments,
    bool? isLoading,
    bool? isCreating,
    String? error,
    String? successMessage,
    bool clearCurrentForum = false,
    bool clearForumComments = false,
  }) {
    return ForumState(
      forums: forums ?? this.forums,
      currentForum:
          clearCurrentForum ? null : (currentForum ?? this.currentForum),
      forumPosts: forumPosts ?? this.forumPosts,
      forumComments: clearForumComments
          ? const []
          : (forumComments ?? this.forumComments),
      isLoading: isLoading ?? this.isLoading,
      isCreating: isCreating ?? this.isCreating,
      error: error,
      successMessage: successMessage,
    );
  }

  /// Clears the current error message.
  ForumState clearError() => copyWith(error: null);
}

// ═══════════════════════════════════════════════════════════════════════
// FORUM NOTIFIER
// ═══════════════════════════════════════════════════════════════════════

/// Riverpod [StateNotifier] that manages the discussion forum feature's state.
///
/// All forum operations flow through this notifier, which:
/// 1. Sets the appropriate loading flag before each async operation
/// 2. Delegates to the relevant use case
/// 3. Updates forums, posts, comments, and metadata on success
/// 4. Sets [error] on failure
class ForumNotifier extends StateNotifier<ForumState> {
  ForumNotifier({
    required GetForumsUseCase getForumsUseCase,
    required CreateForumUseCase createForumUseCase,
    required GetForumPostsUseCase getForumPostsUseCase,
    required CreateForumPostUseCase createForumPostUseCase,
    required CreateForumCommentUseCase createForumCommentUseCase,
  })  : _getForumsUseCase = getForumsUseCase,
        _createForumUseCase = createForumUseCase,
        _getForumPostsUseCase = getForumPostsUseCase,
        _createForumPostUseCase = createForumPostUseCase,
        _createForumCommentUseCase = createForumCommentUseCase,
        super(const ForumState());

  final GetForumsUseCase _getForumsUseCase;
  final CreateForumUseCase _createForumUseCase;
  final GetForumPostsUseCase _getForumPostsUseCase;
  final CreateForumPostUseCase _createForumPostUseCase;
  final CreateForumCommentUseCase _createForumCommentUseCase;

  // ─── Load Forums ────────────────────────────────────────────────────

  /// Loads the discussion forums list with the provided [params].
  Future<void> loadForums(GetForumsParams params) async {
    state = state.copyWith(isLoading: true, error: null);

    final result = await _getForumsUseCase(params);

    result.fold(
      onSuccess: (forums) {
        state = state.copyWith(
          isLoading: false,
          forums: forums,
          error: null,
        );
        AppLogger.info('Forums loaded (${forums.length} forums)');
      },
      onFailure: (failure) {
        state = state.copyWith(
          isLoading: false,
          error: _mapFailureToMessage(failure),
        );
        AppLogger.warning('Failed to load forums: $failure');
      },
    );
  }

  // ─── Load Forum ─────────────────────────────────────────────────────

  /// Loads a single forum by [id] and sets it as currentForum.
  Future<void> loadForum(String id) async {
    state = state.copyWith(isLoading: true, error: null);

    final result = await _getForumsUseCase(
      const GetForumsParams(page: 1, perPage: 100),
    );

    result.fold(
      onSuccess: (forums) {
        final forum = forums.where((f) => f.id == id).firstOrNull;
        state = state.copyWith(
          isLoading: false,
          currentForum: forum,
          error: null,
        );
        AppLogger.info(
          'Forum loaded: $id (${forum != null ? "found" : "not found"})',
        );
      },
      onFailure: (failure) {
        state = state.copyWith(
          isLoading: false,
          error: _mapFailureToMessage(failure),
        );
        AppLogger.warning('Failed to load forum: $failure');
      },
    );
  }

  // ─── Create Forum ──────────────────────────────────────────────────

  /// Creates a new discussion forum with the provided [params].
  Future<void> createForum(CreateForumParams params) async {
    state = state.copyWith(isCreating: true, error: null);

    final result = await _createForumUseCase(params);

    result.fold(
      onSuccess: (forum) {
        final updatedForums = [forum, ...state.forums];
        state = state.copyWith(
          isCreating: false,
          forums: updatedForums,
          currentForum: forum,
          successMessage: 'Forum created successfully',
          error: null,
        );
        AppLogger.info('Forum created: ${forum.id}');
      },
      onFailure: (failure) {
        state = state.copyWith(
          isCreating: false,
          error: _mapFailureToMessage(failure),
        );
        AppLogger.warning('Failed to create forum: $failure');
      },
    );
  }

  // ─── Load Forum Posts ──────────────────────────────────────────────

  /// Loads the posts for the specified [forumId].
  Future<void> loadForumPosts(String forumId) async {
    state = state.copyWith(isLoading: true, error: null);

    final result = await _getForumPostsUseCase(
      GetForumPostsParams(forumId: forumId),
    );

    result.fold(
      onSuccess: (posts) {
        state = state.copyWith(
          isLoading: false,
          forumPosts: posts,
          error: null,
        );
        AppLogger.info(
          'Forum posts loaded for forum: $forumId (${posts.length} posts)',
        );
      },
      onFailure: (failure) {
        state = state.copyWith(
          isLoading: false,
          error: _mapFailureToMessage(failure),
        );
        AppLogger.warning('Failed to load forum posts: $failure');
      },
    );
  }

  // ─── Create Forum Post ─────────────────────────────────────────────

  /// Creates a new forum post with the provided [params].
  Future<void> createForumPost(CreateForumPostParams params) async {
    state = state.copyWith(isCreating: true, error: null);

    final result = await _createForumPostUseCase(params);

    result.fold(
      onSuccess: (post) {
        final updatedPosts = [post, ...state.forumPosts];
        state = state.copyWith(
          isCreating: false,
          forumPosts: updatedPosts,
          successMessage: 'Post created successfully',
          error: null,
        );
        AppLogger.info('Forum post created: ${post.id}');
      },
      onFailure: (failure) {
        state = state.copyWith(
          isCreating: false,
          error: _mapFailureToMessage(failure),
        );
        AppLogger.warning('Failed to create forum post: $failure');
      },
    );
  }

  // ─── Load Forum Comments ───────────────────────────────────────────

  /// Loads the comments for the specified [postId].
  Future<void> loadForumComments(String postId) async {
    state = state.copyWith(isLoading: true, error: null, clearForumComments: true);

    final result = await _getForumPostsUseCase(
      GetForumPostsParams(forumId: state.currentForum?.id ?? ''),
    );

    result.fold(
      onSuccess: (posts) {
        final post = posts.where((p) => p.id == postId).firstOrNull;
        state = state.copyWith(
          isLoading: false,
          forumComments: post?.comments ?? const [],
          error: null,
        );
        AppLogger.info(
          'Forum comments loaded for post: $postId (${post?.comments.length ?? 0} comments)',
        );
      },
      onFailure: (failure) {
        state = state.copyWith(
          isLoading: false,
          error: _mapFailureToMessage(failure),
        );
        AppLogger.warning('Failed to load forum comments: $failure');
      },
    );
  }

  // ─── Create Forum Comment ──────────────────────────────────────────

  /// Creates a new forum comment with the provided [params].
  Future<void> createForumComment(CreateForumCommentParams params) async {
    state = state.copyWith(isCreating: true, error: null);

    final result = await _createForumCommentUseCase(params);

    result.fold(
      onSuccess: (comment) {
        final updatedComments = [...state.forumComments, comment];
        state = state.copyWith(
          isCreating: false,
          forumComments: updatedComments,
          successMessage: 'Comment added successfully',
          error: null,
        );
        AppLogger.info('Forum comment created: ${comment.id}');
      },
      onFailure: (failure) {
        state = state.copyWith(
          isCreating: false,
          error: _mapFailureToMessage(failure),
        );
        AppLogger.warning('Failed to create forum comment: $failure');
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
// FORUM PROVIDER
// ═══════════════════════════════════════════════════════════════════════

final forumProvider =
    StateNotifierProvider<ForumNotifier, ForumState>((ref) {
  return ForumNotifier(
    getForumsUseCase: ref.watch(getForumsUseCaseProvider),
    createForumUseCase: ref.watch(createForumUseCaseProvider),
    getForumPostsUseCase: ref.watch(getForumPostsUseCaseProvider),
    createForumPostUseCase: ref.watch(createForumPostUseCaseProvider),
    createForumCommentUseCase: ref.watch(createForumCommentUseCaseProvider),
  );
});
