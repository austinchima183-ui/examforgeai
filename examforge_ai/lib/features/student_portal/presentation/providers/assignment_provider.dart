import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../config/dependency_injection.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/utils/logger.dart';
import '../../domain/entities/student_portal_entities.dart';
import '../../domain/usecases/student_portal_usecases.dart';
import 'student_dashboard_provider.dart';

// ═══════════════════════════════════════════════════════════════════════
// ASSIGNMENT STATE
// ═══════════════════════════════════════════════════════════════════════

/// Immutable state snapshot for the student Assignment feature.
///
/// Tracks the list of assignment submissions, the currently selected
/// submission, loading flags, pagination state, filter, and errors.
class AssignmentState {
  const AssignmentState({
    this.submissions = const [],
    this.currentSubmission,
    this.isLoading = false,
    this.isSubmitting = false,
    this.error,
    this.hasMore = true,
    this.filterStatus,
    this.currentPage = 1,
  });

  /// All assignment submissions for the current student.
  final List<AssignmentSubmissionEntity> submissions;

  /// The currently selected submission with full details, or `null`.
  final AssignmentSubmissionEntity? currentSubmission;

  /// Whether the initial submission list load is in progress.
  final bool isLoading;

  /// Whether a submit/create operation is in progress.
  final bool isSubmitting;

  /// The most recent error message, or `null`.
  final String? error;

  /// Whether there are more submission pages to load.
  final bool hasMore;

  /// Optional filter on submission status.
  final SubmissionStatus? filterStatus;

  /// Current page number for submission pagination (1-based).
  // ignore: unused_field
  final int currentPage;

  /// Current page number for submission pagination.

  /// Whether any async operation is in progress.
  bool get isBusy => isLoading || isSubmitting;

  /// Number of submissions currently loaded.
  int get submissionCount => submissions.length;

  /// Creates a copy of this state with the given fields replaced.
  AssignmentState copyWith({
    List<AssignmentSubmissionEntity>? submissions,
    AssignmentSubmissionEntity? currentSubmission,
    bool? isLoading,
    bool? isSubmitting,
    String? error,
    bool? hasMore,
    SubmissionStatus? filterStatus,
    int? currentPage,
    bool clearCurrentSubmission = false,
    bool clearFilterStatus = false,
  }) {
    return AssignmentState(
      submissions: submissions ?? this.submissions,
      currentSubmission: clearCurrentSubmission
          ? null
          : (currentSubmission ?? this.currentSubmission),
      isLoading: isLoading ?? this.isLoading,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      error: error,
      hasMore: hasMore ?? this.hasMore,
      filterStatus:
          clearFilterStatus ? null : (filterStatus ?? this.filterStatus),
      currentPage: currentPage ?? this.currentPage,
    );
  }

  /// Clears the current error message.
  AssignmentState clearError() => copyWith(error: null);
}

// ═══════════════════════════════════════════════════════════════════════
// ASSIGNMENT NOTIFIER
// ═══════════════════════════════════════════════════════════════════════

/// Riverpod [StateNotifier] that manages the student Assignment feature's
/// state.
///
/// All assignment submission operations flow through this notifier, which:
/// 1. Sets the appropriate loading flag before each async operation
/// 2. Delegates to the appropriate use case
/// 3. Updates the submission list, current submission, and pagination on success
/// 4. Sets [error] on failure
class AssignmentNotifier extends StateNotifier<AssignmentState> {
  AssignmentNotifier({
    required GetSubmissionsUseCase getSubmissions,
    required GetSubmissionDetailUseCase getSubmissionDetail,
    required CreateSubmissionUseCase createSubmission,
    required SubmitAssignmentUseCase submitAssignment,
    required GetAssignedAssignmentsUseCase getAssignedAssignments,
    required String? studentId,
  })  : _getSubmissions = getSubmissions,
        _getSubmissionDetail = getSubmissionDetail,
        _createSubmission = createSubmission,
        _submitAssignment = submitAssignment,
        _getAssignedAssignments = getAssignedAssignments,
        _studentId = studentId,
        super(const AssignmentState());

  final GetSubmissionsUseCase _getSubmissions;
  final GetSubmissionDetailUseCase _getSubmissionDetail;
  final CreateSubmissionUseCase _createSubmission;
  final SubmitAssignmentUseCase _submitAssignment;
  final GetAssignedAssignmentsUseCase _getAssignedAssignments;
  final String? _studentId;

  static const int _pageSize = 20;

  // ─── Load Submissions (first page) ─────────────────────────────────

  /// Loads the first page of assignment submissions for the current
  /// student, optionally filtered by [filterStatus].
  Future<void> loadSubmissions() async {
    if (_studentId == null) return;

    state = state.copyWith(isLoading: true, error: null);

    final result = await _getSubmissions(
      studentId: _studentId!,
      page: 1,
      pageSize: _pageSize,
      status: state.filterStatus,
    );

    result.fold(
      onSuccess: (submissions) {
        state = state.copyWith(
          isLoading: false,
          submissions: submissions,
          currentPage: 1,
          hasMore: submissions.length >= _pageSize,
          error: null,
        );
        AppLogger.info(
          'Loaded ${submissions.length} submissions (page 1)',
        );
      },
      onFailure: (failure) {
        state = state.copyWith(
          isLoading: false,
          error: _mapFailureToMessage(failure),
        );
        AppLogger.warning('Failed to load submissions: $failure');
      },
    );
  }

  // ─── Load More Submissions ─────────────────────────────────────────

  /// Loads the next page of submissions and appends to the list.
  Future<void> loadMoreSubmissions() async {
    if (_studentId == null || !state.hasMore) return;

    final nextPage = state.currentPage + 1;

    final result = await _getSubmissions(
      studentId: _studentId!,
      page: nextPage,
      pageSize: _pageSize,
      status: state.filterStatus,
    );

    result.fold(
      onSuccess: (newSubmissions) {
        final allSubmissions = [...state.submissions, ...newSubmissions];
        state = state.copyWith(
          submissions: allSubmissions,
          currentPage: nextPage,
          hasMore: newSubmissions.length >= _pageSize,
        );
        AppLogger.info(
          'Loaded ${newSubmissions.length} more submissions (page $nextPage)',
        );
      },
      onFailure: (failure) {
        state = state.copyWith(
          error: _mapFailureToMessage(failure),
        );
        AppLogger.warning(
          'Failed to load more submissions: $failure',
        );
      },
    );
  }

  // ─── Open Submission ───────────────────────────────────────────────

  /// Opens a submission by ID, loading its full details.
  Future<void> openSubmission(String submissionId) async {
    state = state.copyWith(isLoading: true, error: null);

    final result = await _getSubmissionDetail(
      submissionId: submissionId,
    );

    result.fold(
      onSuccess: (submission) {
        state = state.copyWith(
          isLoading: false,
          currentSubmission: submission,
          error: null,
        );
        AppLogger.info('Opened submission: $submissionId');
      },
      onFailure: (failure) {
        state = state.copyWith(
          isLoading: false,
          error: _mapFailureToMessage(failure),
        );
        AppLogger.warning('Failed to open submission: $failure');
      },
    );
  }

  // ─── Create Submission ─────────────────────────────────────────────

  /// Creates a new draft submission for the given assignment.
  Future<void> createSubmission({
    required String assignmentId,
    Map<String, dynamic> content = const {},
    List<AttachmentInfo> attachments = const [],
  }) async {
    if (_studentId == null) return;

    state = state.copyWith(isSubmitting: true, error: null);

    final result = await _createSubmission(
      assignmentId: assignmentId,
      studentId: _studentId!,
      content: content,
      attachments: attachments,
    );

    result.fold(
      onSuccess: (submission) {
        final updatedList = [submission, ...state.submissions];
        state = state.copyWith(
          isSubmitting: false,
          submissions: updatedList,
          currentSubmission: submission,
          error: null,
        );
        AppLogger.info('Created submission: ${submission.id}');
      },
      onFailure: (failure) {
        state = state.copyWith(
          isSubmitting: false,
          error: _mapFailureToMessage(failure),
        );
        AppLogger.warning(
          'Failed to create submission: $failure',
        );
      },
    );
  }

  // ─── Submit Assignment ─────────────────────────────────────────────

  /// Submits a draft assignment, changing its status from draft to
  /// submitted.
  Future<void> submitAssignment(String submissionId) async {
    state = state.copyWith(isSubmitting: true, error: null);

    final result = await _submitAssignment(submissionId: submissionId);

    result.fold(
      onSuccess: (updatedSubmission) {
        final updatedList = state.submissions
            .map((s) => s.id == submissionId ? updatedSubmission : s)
            .toList();

        state = state.copyWith(
          isSubmitting: false,
          submissions: updatedList,
          currentSubmission: state.currentSubmission?.id == submissionId
              ? updatedSubmission
              : state.currentSubmission,
          error: null,
        );
        AppLogger.info('Submitted assignment: $submissionId');
      },
      onFailure: (failure) {
        state = state.copyWith(
          isSubmitting: false,
          error: _mapFailureToMessage(failure),
        );
        AppLogger.warning(
          'Failed to submit assignment: $failure',
        );
      },
    );
  }

  // ─── Filter by Status ──────────────────────────────────────────────

  /// Filters submissions by [status] and reloads the list.
  /// Pass `null` to clear the filter.
  Future<void> filterByStatus(SubmissionStatus? status) async {
    state = state.copyWith(
      filterStatus: status,
      clearFilterStatus: status == null,
    );
    await loadSubmissions();
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
// ASSIGNMENT PROVIDER
// ═══════════════════════════════════════════════════════════════════════

/// Provides the [AssignmentNotifier] with all required use cases.
final studentAssignmentProvider =
    StateNotifierProvider<AssignmentNotifier, AssignmentState>((ref) {
  return AssignmentNotifier(
    getSubmissions: ref.watch(getSubmissionsUseCaseProvider),
    getSubmissionDetail: ref.watch(getSubmissionDetailUseCaseProvider),
    createSubmission: ref.watch(createSubmissionUseCaseProvider),
    submitAssignment: ref.watch(submitAssignmentUseCaseProvider),
    getAssignedAssignments:
        ref.watch(getAssignedAssignmentsUseCaseProvider),
    studentId: ref.watch(currentStudentIdProvider),
  );
});
