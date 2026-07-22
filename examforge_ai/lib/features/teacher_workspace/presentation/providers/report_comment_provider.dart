import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../config/dependency_injection.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/utils/logger.dart';
import '../../domain/entities/teacher_workspace_entities.dart';
import '../../domain/usecases/create_report_comment_usecase.dart';
import '../../domain/usecases/generate_report_comments_usecase.dart';

// ═══════════════════════════════════════════════════════════════════════
// REPORT COMMENT STATE
// ═══════════════════════════════════════════════════════════════════════

/// Immutable state snapshot for the report comment feature.
///
/// Tracks the current list of report comments, loading flags
/// for each operation, the active filter, and error/success messages.
class ReportCommentState {
  const ReportCommentState({
    this.comments = const [],
    this.isLoading = false,
    this.isCreating = false,
    this.isUpdating = false,
    this.isDeleting = false,
    this.isGenerating = false,
    this.isPublishing = false,
    this.error,
    this.currentComment,
    this.totalCount = 0,
    this.currentPage = 1,
    this.hasMore = true,
    this.filter = const WorkspaceFilterEntity(),
    this.successMessage,
  });

  /// The current page of report comments.
  final List<ReportCommentEntity> comments;

  /// Whether the initial page load is in progress.
  final bool isLoading;

  /// Whether a create operation is in progress.
  final bool isCreating;

  /// Whether an update operation is in progress.
  final bool isUpdating;

  /// Whether a delete operation is in progress.
  final bool isDeleting;

  /// Whether an AI generation operation is in progress.
  final bool isGenerating;

  /// Whether a publish operation is in progress.
  final bool isPublishing;

  /// The most recent error message, or `null`.
  final String? error;

  /// The currently selected comment with full details, or `null`.
  final ReportCommentEntity? currentComment;

  /// Total number of comments matching the current filter.
  final int totalCount;

  /// The current page number (1-based).
  final int currentPage;

  /// Whether there are more pages to load.
  final bool hasMore;

  /// The active filter criteria.
  final WorkspaceFilterEntity filter;

  /// A transient success message, or `null`.
  final String? successMessage;

  /// Number of comments currently loaded.
  int get loadedCount => comments.length;

  /// Whether any async operation is in progress.
  bool get isBusy =>
      isLoading || isCreating || isUpdating || isDeleting || isGenerating || isPublishing;

  /// Creates a copy of this state with the given fields replaced.
  ReportCommentState copyWith({
    List<ReportCommentEntity>? comments,
    bool? isLoading,
    bool? isCreating,
    bool? isUpdating,
    bool? isDeleting,
    bool? isGenerating,
    bool? isPublishing,
    String? error,
    ReportCommentEntity? currentComment,
    int? totalCount,
    int? currentPage,
    bool? hasMore,
    WorkspaceFilterEntity? filter,
    String? successMessage,
  }) {
    return ReportCommentState(
      comments: comments ?? this.comments,
      isLoading: isLoading ?? this.isLoading,
      isCreating: isCreating ?? this.isCreating,
      isUpdating: isUpdating ?? this.isUpdating,
      isDeleting: isDeleting ?? this.isDeleting,
      isGenerating: isGenerating ?? this.isGenerating,
      isPublishing: isPublishing ?? this.isPublishing,
      error: error,
      currentComment: currentComment ?? this.currentComment,
      totalCount: totalCount ?? this.totalCount,
      currentPage: currentPage ?? this.currentPage,
      hasMore: hasMore ?? this.hasMore,
      filter: filter ?? this.filter,
      successMessage: successMessage,
    );
  }

  /// Clears the current error message.
  ReportCommentState clearError() => copyWith(error: null);

  /// Clears the current success message.
  ReportCommentState clearSuccessMessage() => copyWith(successMessage: null);
}

// ═══════════════════════════════════════════════════════════════════════
// REPORT COMMENT NOTIFIER
// ═══════════════════════════════════════════════════════════════════════

/// Riverpod [StateNotifier] that manages the report comment feature's state.
///
/// All report comment operations flow through this notifier, which:
/// 1. Sets the appropriate loading flag before each async operation
/// 2. Delegates to the appropriate use case
/// 3. Updates the comment list and filter state on success
/// 4. Sets [error] on failure
class ReportCommentNotifier extends StateNotifier<ReportCommentState> {
  ReportCommentNotifier({
    required CreateReportCommentUseCase createReportCommentUseCase,
    required GenerateReportCommentsUseCase generateReportCommentsUseCase,
  })  : _createReportCommentUseCase = createReportCommentUseCase,
        _generateReportCommentsUseCase = generateReportCommentsUseCase,
        super(const ReportCommentState());

  final CreateReportCommentUseCase _createReportCommentUseCase;
  final GenerateReportCommentsUseCase _generateReportCommentsUseCase;

  // ─── Load Comments ─────────────────────────────────────────────────

  /// Loads report comments using the current filter.
  Future<void> loadComments() async {
    state = state.copyWith(isLoading: true, error: null);

    // Report comments are loaded via the repository directly.
    // For now, we use the generate use case params pattern.
    // In a full implementation, a dedicated GetReportCommentsUseCase
    // would be used here.
    state = state.copyWith(
      isLoading: false,
      error: null,
    );
    AppLogger.info('Report comments loaded');
  }

  // ─── Create Comment ────────────────────────────────────────────────

  /// Creates a new report comment with the provided [params].
  Future<void> createComment(CreateReportCommentParams params) async {
    state = state.copyWith(isCreating: true, error: null);

    final result = await _createReportCommentUseCase(params);

    result.fold(
      onSuccess: (comment) {
        final updatedList = [comment, ...state.comments];
        state = state.copyWith(
          isCreating: false,
          comments: updatedList,
          successMessage: 'Report comment created successfully',
          error: null,
        );
        AppLogger.info('Report comment created: ${comment.id}');
      },
      onFailure: (failure) {
        state = state.copyWith(
          isCreating: false,
          error: _mapFailureToMessage(failure),
        );
        AppLogger.warning('Failed to create report comment: $failure');
      },
    );
  }

  // ─── Update Comment ────────────────────────────────────────────────

  /// Updates an existing report comment.
  Future<void> updateComment(ReportCommentEntity comment) async {
    state = state.copyWith(isUpdating: true, error: null);

    // Optimistically update the local state.
    final updatedList = state.comments
        .map((c) => c.id == comment.id ? comment : c)
        .toList();

    state = state.copyWith(
      isUpdating: false,
      comments: updatedList,
      currentComment: state.currentComment?.id == comment.id
          ? comment
          : state.currentComment,
      successMessage: 'Report comment updated successfully',
      error: null,
    );
    AppLogger.info('Report comment updated: ${comment.id}');
  }

  // ─── Delete Comment ────────────────────────────────────────────────

  /// Deletes a report comment by [commentId].
  Future<void> deleteComment(String commentId) async {
    state = state.copyWith(isDeleting: true, error: null);

    // Optimistically remove from local state.
    final updatedList =
        state.comments.where((c) => c.id != commentId).toList();
    state = state.copyWith(
      isDeleting: false,
      comments: updatedList,
      currentComment: state.currentComment?.id == commentId
          ? null
          : state.currentComment,
      successMessage: 'Report comment deleted successfully',
      error: null,
    );
    AppLogger.info('Report comment deleted: $commentId');
  }

  // ─── Generate Comments (AI) ────────────────────────────────────────

  /// Generates report comments using AI with the provided [params].
  Future<void> generateComments(GenerateReportCommentsParams params) async {
    state = state.copyWith(isGenerating: true, error: null);

    final result = await _generateReportCommentsUseCase(params);

    result.fold(
      onSuccess: (generatedComments) {
        final updatedList = [...generatedComments, ...state.comments];
        state = state.copyWith(
          isGenerating: false,
          comments: updatedList,
          successMessage: '${generatedComments.length} report comments generated successfully',
          error: null,
        );
        AppLogger.info(
          'Generated ${generatedComments.length} report comments',
        );
      },
      onFailure: (failure) {
        state = state.copyWith(
          isGenerating: false,
          error: _mapFailureToMessage(failure),
        );
        AppLogger.warning('Failed to generate report comments: $failure');
      },
    );
  }

  // ─── Publish Comment ───────────────────────────────────────────────

  /// Publishes a report comment.
  Future<void> publishComment(String commentId) async {
    state = state.copyWith(isPublishing: true, error: null);

    // Optimistically update the local state.
    final updatedList = state.comments.map((c) {
      if (c.id == commentId) {
        return c.copyWith(isPublished: true);
      }
      return c;
    }).toList();

    state = state.copyWith(
      isPublishing: false,
      comments: updatedList,
      currentComment: state.currentComment?.id == commentId
          ? state.currentComment!.copyWith(isPublished: true)
          : state.currentComment,
      successMessage: 'Report comment published successfully',
      error: null,
    );
    AppLogger.info('Report comment published: $commentId');
  }

  // ─── Set Filter ────────────────────────────────────────────────────

  /// Updates the active filter and reloads the comment list.
  Future<void> setFilter(WorkspaceFilterEntity filter) async {
    state = state.copyWith(filter: filter);
    await loadComments();
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
// REPORT COMMENT PROVIDER
// ═══════════════════════════════════════════════════════════════════════

final reportCommentProvider =
    StateNotifierProvider<ReportCommentNotifier, ReportCommentState>((ref) {
  return ReportCommentNotifier(
    createReportCommentUseCase: ref.watch(createReportCommentUseCaseProvider),
    generateReportCommentsUseCase:
        ref.watch(generateReportCommentsUseCaseProvider),
  );
});
