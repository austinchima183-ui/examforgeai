import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/utils/logger.dart';
import '../../domain/entities/school_management_entities.dart';
import '../../domain/repositories/school_management_repository.dart';
import '../../../../config/dependency_injection.dart';


// ═══════════════════════════════════════════════════════════════════════
// HOMEWORK LIST STATE
// ═══════════════════════════════════════════════════════════════════════

/// Immutable state snapshot for the homework listing feature.
class HomeworkListState {
  const HomeworkListState({
    this.homeworkList = const [],
    this.isLoading = false,
    this.error,
    this.classFilter,
    this.subjectFilter,
    this.statusFilter,
  });

  /// The list of homework items.
  final List<HomeworkEntity> homeworkList;

  /// Whether the initial load is in progress.
  final bool isLoading;

  /// The most recent error message, or `null`.
  final String? error;

  /// Filter by class ID.
  final String? classFilter;

  /// Filter by subject ID.
  final String? subjectFilter;

  /// Filter by homework status.
  final HomeworkStatus? statusFilter;

  /// Number of homework items currently loaded.
  int get loadedCount => homeworkList.length;

  /// Whether any async operation is in progress.
  bool get isBusy => isLoading;

  /// Creates a copy of this state with the given fields replaced.
  HomeworkListState copyWith({
    List<HomeworkEntity>? homeworkList,
    bool? isLoading,
    String? error,
    String? classFilter,
    String? subjectFilter,
    HomeworkStatus? statusFilter,
  }) {
    return HomeworkListState(
      homeworkList: homeworkList ?? this.homeworkList,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      classFilter: classFilter ?? this.classFilter,
      subjectFilter: subjectFilter ?? this.subjectFilter,
      statusFilter: statusFilter ?? this.statusFilter,
    );
  }

  /// Clears the current error message.
  HomeworkListState clearError() => copyWith(error: null);
}

// ═══════════════════════════════════════════════════════════════════════
// HOMEWORK LIST NOTIFIER
// ═══════════════════════════════════════════════════════════════════════

/// Riverpod [StateNotifier] that manages the homework list feature's state.
class HomeworkListNotifier extends StateNotifier<HomeworkListState> {
  HomeworkListNotifier({
    required SchoolManagementRepository schoolManagementRepository,
  })  : _repository = schoolManagementRepository,
        super(const HomeworkListState());

  final SchoolManagementRepository _repository;

  static const int _perPage = 20;

  // ─── Load Homework ─────────────────────────────────────────────────

  /// Loads the homework list with optional filters.
  Future<void> loadHomework({
    required String schoolId,
    String? classId,
    String? subjectId,
    String? teacherId,
    HomeworkStatus? status,
    int page = 1,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    final result = await _repository.getHomeworkList(
      schoolId: schoolId,
      classId: classId ?? state.classFilter,
      subjectId: subjectId ?? state.subjectFilter,
      teacherId: teacherId,
      status: status ?? state.statusFilter,
      page: page,
      perPage: _perPage,
    );

    result.fold(
      onSuccess: (homeworkList) {
        state = state.copyWith(
          isLoading: false,
          homeworkList: homeworkList,
          error: null,
        );
        AppLogger.info('Loaded ${homeworkList.length} homework items');
      },
      onFailure: (failure) {
        state = state.copyWith(
          isLoading: false,
          error: _mapFailureToMessage(failure),
        );
        AppLogger.warning('Failed to load homework: $failure');
      },
    );
  }

  // ─── Create Homework ───────────────────────────────────────────────

  /// Creates a new homework item.
  Future<void> createHomework(HomeworkEntity homework) async {
    final result = await _repository.createHomework(homework);

    result.fold(
      onSuccess: (createdHomework) {
        final updatedList = [createdHomework, ...state.homeworkList];
        state = state.copyWith(homeworkList: updatedList, error: null);
        AppLogger.info('Homework created: ${createdHomework.id}');
      },
      onFailure: (failure) {
        state = state.copyWith(
          error: _mapFailureToMessage(failure),
        );
        AppLogger.warning('Failed to create homework: $failure');
      },
    );
  }

  // ─── Update Homework ───────────────────────────────────────────────

  /// Updates an existing homework item.
  Future<void> updateHomework(HomeworkEntity homework) async {
    final result = await _repository.updateHomework(homework);

    result.fold(
      onSuccess: (updatedHomework) {
        final updatedList = state.homeworkList
            .map((h) => h.id == updatedHomework.id ? updatedHomework : h)
            .toList();
        state = state.copyWith(homeworkList: updatedList, error: null);
        AppLogger.info('Homework updated: ${updatedHomework.id}');
      },
      onFailure: (failure) {
        state = state.copyWith(
          error: _mapFailureToMessage(failure),
        );
        AppLogger.warning('Failed to update homework: $failure');
      },
    );
  }

  // ─── Publish Homework ──────────────────────────────────────────────

  /// Publishes a homework item by its ID.
  Future<void> publishHomework(String homeworkId) async {
    final result = await _repository.publishHomework(homeworkId);

    result.fold(
      onSuccess: (_) {
        final updatedList = state.homeworkList.map((h) {
          if (h.id == homeworkId) {
            return h.copyWith(
              isPublished: true,
              status: HomeworkStatus.published,
            );
          }
          return h;
        }).toList();
        state = state.copyWith(homeworkList: updatedList, error: null);
        AppLogger.info('Homework published: $homeworkId');
      },
      onFailure: (failure) {
        state = state.copyWith(
          error: _mapFailureToMessage(failure),
        );
        AppLogger.warning('Failed to publish homework: $failure');
      },
    );
  }

  // ─── Delete Homework ───────────────────────────────────────────────

  /// Deletes a homework item by its ID.
  Future<void> deleteHomework(String homeworkId) async {
    final result = await _repository.deleteHomework(homeworkId);

    result.fold(
      onSuccess: (_) {
        final updatedList =
            state.homeworkList.where((h) => h.id != homeworkId).toList();
        state = state.copyWith(homeworkList: updatedList, error: null);
        AppLogger.info('Homework deleted: $homeworkId');
      },
      onFailure: (failure) {
        state = state.copyWith(
          error: _mapFailureToMessage(failure),
        );
        AppLogger.warning('Failed to delete homework: $failure');
      },
    );
  }

  // ─── Set Filters ───────────────────────────────────────────────────

  /// Sets the class filter.
  void setClassFilter(String? classId) {
    state = state.copyWith(classFilter: classId);
  }

  /// Sets the subject filter.
  void setSubjectFilter(String? subjectId) {
    state = state.copyWith(subjectFilter: subjectId);
  }

  /// Sets the status filter.
  void setStatusFilter(HomeworkStatus? status) {
    state = state.copyWith(statusFilter: status);
  }

  // ─── Clear Error ───────────────────────────────────────────────────

  /// Clears the current error message from the state.
  void clearError() {
    state = state.clearError();
  }

  // ═══════════════════════════════════════════════════════════════════════
  // PRIVATE HELPERS
  // ═══════════════════════════════════════════════════════════════════════

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
// HOMEWORK DETAIL STATE
// ═══════════════════════════════════════════════════════════════════════

/// Immutable state snapshot for the homework detail feature.
class HomeworkDetailState {
  const HomeworkDetailState({
    this.homework,
    this.submissions = const [],
    this.isLoading = false,
    this.error,
  });

  /// The currently viewed homework, or `null`.
  final HomeworkEntity? homework;

  /// The list of submissions for this homework.
  final List<HomeworkSubmissionEntity> submissions;

  /// Whether the detail is loading.
  final bool isLoading;

  /// The most recent error message, or `null`.
  final String? error;

  /// Whether the homework data has been loaded.
  bool get isLoaded => homework != null;

  /// Creates a copy of this state with the given fields replaced.
  HomeworkDetailState copyWith({
    HomeworkEntity? homework,
    List<HomeworkSubmissionEntity>? submissions,
    bool? isLoading,
    String? error,
  }) {
    return HomeworkDetailState(
      homework: homework ?? this.homework,
      submissions: submissions ?? this.submissions,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }

  /// Clears the current error message.
  HomeworkDetailState clearError() => copyWith(error: null);
}

// ═══════════════════════════════════════════════════════════════════════
// HOMEWORK DETAIL NOTIFIER
// ═══════════════════════════════════════════════════════════════════════

/// Riverpod [StateNotifier] that manages the homework detail feature's state.
class HomeworkDetailNotifier extends StateNotifier<HomeworkDetailState> {
  HomeworkDetailNotifier({
    required SchoolManagementRepository schoolManagementRepository,
  })  : _repository = schoolManagementRepository,
        super(const HomeworkDetailState());

  final SchoolManagementRepository _repository;

  // ─── Load Homework ─────────────────────────────────────────────────

  /// Loads a homework item by ID along with its submissions.
  Future<void> loadHomework(String homeworkId) async {
    state = state.copyWith(isLoading: true, error: null);

    final homeworkResult = await _repository.getHomework(homeworkId);

    await homeworkResult.fold(
      onSuccess: (homework) async {
        // Load submissions for this homework
        final submissionsResult =
            await _repository.getHomeworkSubmissions(homeworkId);
        final submissions = submissionsResult.getOrElse(<HomeworkSubmissionEntity>[]);

        state = state.copyWith(
          isLoading: false,
          homework: homework,
          submissions: submissions,
          error: null,
        );
        AppLogger.info('Loaded homework detail: $homeworkId');
      },
      onFailure: (failure) {
        state = state.copyWith(
          isLoading: false,
          error: _mapFailureToMessage(failure),
        );
        AppLogger.warning('Failed to load homework: $failure');
      },
    );
  }

  // ─── Submit Homework ───────────────────────────────────────────────

  /// Submits a homework entry for a student.
  Future<void> submitHomework(HomeworkSubmissionEntity submission) async {
    final result = await _repository.submitHomework(submission);

    result.fold(
      onSuccess: (createdSubmission) {
        final updatedSubmissions = [...state.submissions, createdSubmission];
        state = state.copyWith(submissions: updatedSubmissions, error: null);
        AppLogger.info('Homework submitted: ${createdSubmission.id}');
      },
      onFailure: (failure) {
        state = state.copyWith(
          error: _mapFailureToMessage(failure),
        );
        AppLogger.warning('Failed to submit homework: $failure');
      },
    );
  }

  // ─── Grade Submission ──────────────────────────────────────────────

  /// Grades a homework submission.
  Future<void> gradeSubmission(HomeworkSubmissionEntity submission) async {
    final result = await _repository.gradeSubmission(submission);

    result.fold(
      onSuccess: (gradedSubmission) {
        final updatedSubmissions = state.submissions
            .map((s) => s.id == gradedSubmission.id ? gradedSubmission : s)
            .toList();
        state = state.copyWith(submissions: updatedSubmissions, error: null);
        AppLogger.info('Submission graded: ${gradedSubmission.id}');
      },
      onFailure: (failure) {
        state = state.copyWith(
          error: _mapFailureToMessage(failure),
        );
        AppLogger.warning('Failed to grade submission: $failure');
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
// PROVIDERS
// ═══════════════════════════════════════════════════════════════════════

/// Provides the [HomeworkListNotifier] and its [HomeworkListState].
final homeworkListProvider =
    StateNotifierProvider<HomeworkListNotifier, HomeworkListState>((ref) {
  return HomeworkListNotifier(
    schoolManagementRepository: ref.watch(schoolManagementRepositoryProvider),
  );
});

/// Provides the [HomeworkDetailNotifier] and its [HomeworkDetailState].
final homeworkDetailProvider =
    StateNotifierProvider<HomeworkDetailNotifier, HomeworkDetailState>((ref) {
  return HomeworkDetailNotifier(
    schoolManagementRepository: ref.watch(schoolManagementRepositoryProvider),
  );
});
