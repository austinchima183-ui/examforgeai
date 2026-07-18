import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/utils/logger.dart';
import '../../domain/entities/school_management_entities.dart';
import '../../domain/repositories/school_management_repository.dart';

// ═══════════════════════════════════════════════════════════════════════
// STUDENT LIST STATE
// ═══════════════════════════════════════════════════════════════════════

/// Immutable state snapshot for the student listing feature.
class StudentListState {
  const StudentListState({
    this.students = const [],
    this.isLoading = false,
    this.error,
    this.classFilter,
    this.searchQuery,
    this.currentPage = 1,
    this.hasMore = true,
  });

  /// The current page of students.
  final List<StudentProfileEntity> students;

  /// Whether the initial page load is in progress.
  final bool isLoading;

  /// The most recent error message, or `null`.
  final String? error;

  /// Filter by class ID.
  final String? classFilter;

  /// Active search query for filtering students.
  final String? searchQuery;

  /// The current page number (1-based).
  final int currentPage;

  /// Whether there are more pages to load.
  final bool hasMore;

  /// Number of students currently loaded.
  int get loadedCount => students.length;

  /// Whether any async operation is in progress.
  bool get isBusy => isLoading;

  /// Creates a copy of this state with the given fields replaced.
  StudentListState copyWith({
    List<StudentProfileEntity>? students,
    bool? isLoading,
    String? error,
    String? classFilter,
    String? searchQuery,
    int? currentPage,
    bool? hasMore,
  }) {
    return StudentListState(
      students: students ?? this.students,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      classFilter: classFilter ?? this.classFilter,
      searchQuery: searchQuery ?? this.searchQuery,
      currentPage: currentPage ?? this.currentPage,
      hasMore: hasMore ?? this.hasMore,
    );
  }

  /// Clears the current error message.
  StudentListState clearError() => copyWith(error: null);
}

// ═══════════════════════════════════════════════════════════════════════
// STUDENT LIST NOTIFIER
// ═══════════════════════════════════════════════════════════════════════

/// Riverpod [StateNotifier] that manages the student list feature's state.
class StudentListNotifier extends StateNotifier<StudentListState> {
  StudentListNotifier({
    required SchoolManagementRepository schoolManagementRepository,
  })  : _repository = schoolManagementRepository,
        super(const StudentListState());

  final SchoolManagementRepository _repository;

  static const int _perPage = 20;

  String? _currentSchoolId;

  /// Sets the school context for subsequent operations.
  void setSchoolId(String schoolId) {
    _currentSchoolId = schoolId;
  }

  // ─── Load Students ─────────────────────────────────────────────────

  /// Loads the first page of students for the current school.
  Future<void> loadStudents(String schoolId) async {
    _currentSchoolId = schoolId;
    state = state.copyWith(isLoading: true, error: null);

    final result = await _repository.getStudentProfiles(
      schoolId: schoolId,
      classId: state.classFilter,
      searchQuery: state.searchQuery,
      page: 1,
      perPage: _perPage,
    );

    result.fold(
      onSuccess: (students) {
        state = state.copyWith(
          isLoading: false,
          students: students,
          currentPage: 1,
          hasMore: students.length >= _perPage,
          error: null,
        );
        AppLogger.info('Loaded ${students.length} students (page 1)');
      },
      onFailure: (failure) {
        state = state.copyWith(
          isLoading: false,
          error: _mapFailureToMessage(failure),
        );
        AppLogger.warning('Failed to load students: $failure');
      },
    );
  }

  // ─── Search Students ───────────────────────────────────────────────

  /// Searches students by query and reloads the list.
  Future<void> searchStudents(String query) async {
    if (_currentSchoolId == null) return;
    state = state.copyWith(searchQuery: query, isLoading: true, error: null);

    final result = await _repository.getStudentProfiles(
      schoolId: _currentSchoolId!,
      classId: state.classFilter,
      searchQuery: query,
      page: 1,
      perPage: _perPage,
    );

    result.fold(
      onSuccess: (students) {
        state = state.copyWith(
          isLoading: false,
          students: students,
          currentPage: 1,
          hasMore: students.length >= _perPage,
          error: null,
        );
        AppLogger.info('Search "$query" returned ${students.length} students');
      },
      onFailure: (failure) {
        state = state.copyWith(
          isLoading: false,
          error: _mapFailureToMessage(failure),
        );
        AppLogger.warning('Failed to search students: $failure');
      },
    );
  }

  // ─── Filter By Class ───────────────────────────────────────────────

  /// Filters students by class and reloads the list.
  Future<void> filterByClass(String? classId) async {
    if (_currentSchoolId == null) return;
    state = state.copyWith(classFilter: classId, isLoading: true, error: null);

    final result = await _repository.getStudentProfiles(
      schoolId: _currentSchoolId!,
      classId: classId,
      searchQuery: state.searchQuery,
      page: 1,
      perPage: _perPage,
    );

    result.fold(
      onSuccess: (students) {
        state = state.copyWith(
          isLoading: false,
          students: students,
          currentPage: 1,
          hasMore: students.length >= _perPage,
          error: null,
        );
        AppLogger.info('Class filter returned ${students.length} students');
      },
      onFailure: (failure) {
        state = state.copyWith(
          isLoading: false,
          error: _mapFailureToMessage(failure),
        );
        AppLogger.warning('Failed to filter students: $failure');
      },
    );
  }

  // ─── Create Student ────────────────────────────────────────────────

  /// Creates a new student profile.
  Future<void> createStudent(StudentProfileEntity profile) async {
    final result = await _repository.createStudentProfile(profile);

    result.fold(
      onSuccess: (createdProfile) {
        final updatedList = [createdProfile, ...state.students];
        state = state.copyWith(students: updatedList, error: null);
        AppLogger.info('Student created: ${createdProfile.id}');
      },
      onFailure: (failure) {
        state = state.copyWith(
          error: _mapFailureToMessage(failure),
        );
        AppLogger.warning('Failed to create student: $failure');
      },
    );
  }

  // ─── Update Student ────────────────────────────────────────────────

  /// Updates an existing student profile.
  Future<void> updateStudent(StudentProfileEntity profile) async {
    final result = await _repository.updateStudentProfile(profile);

    result.fold(
      onSuccess: (updatedProfile) {
        final updatedList = state.students
            .map((s) => s.id == updatedProfile.id ? updatedProfile : s)
            .toList();
        state = state.copyWith(students: updatedList, error: null);
        AppLogger.info('Student updated: ${updatedProfile.id}');
      },
      onFailure: (failure) {
        state = state.copyWith(
          error: _mapFailureToMessage(failure),
        );
        AppLogger.warning('Failed to update student: $failure');
      },
    );
  }

  // ─── Promote Student ───────────────────────────────────────────────

  /// Promotes a student to a new class.
  Future<void> promoteStudent({
    required String studentId,
    required String schoolId,
    required String toClassId,
    required PromotionStatus promotionStatus,
    String? fromClassId,
    String? academicSessionId,
    double? averageScore,
    String? comment,
  }) async {
    final result = await _repository.promoteStudent(
      studentId: studentId,
      schoolId: schoolId,
      toClassId: toClassId,
      promotionStatus: promotionStatus,
      fromClassId: fromClassId,
      academicSessionId: academicSessionId,
      averageScore: averageScore,
      comment: comment,
    );

    result.fold(
      onSuccess: (_) {
        AppLogger.info('Student promoted: $studentId');
      },
      onFailure: (failure) {
        state = state.copyWith(
          error: _mapFailureToMessage(failure),
        );
        AppLogger.warning('Failed to promote student: $failure');
      },
    );
  }

  // ─── Graduate Student ──────────────────────────────────────────────

  /// Graduates a student.
  Future<void> graduateStudent(String studentId, String schoolId) async {
    final result = await _repository.graduateStudent(studentId, schoolId);

    result.fold(
      onSuccess: (_) {
        final updatedList =
            state.students.where((s) => s.id != studentId).toList();
        state = state.copyWith(students: updatedList, error: null);
        AppLogger.info('Student graduated: $studentId');
      },
      onFailure: (failure) {
        state = state.copyWith(
          error: _mapFailureToMessage(failure),
        );
        AppLogger.warning('Failed to graduate student: $failure');
      },
    );
  }

  // ─── Load More ─────────────────────────────────────────────────────

  /// Loads the next page of students and appends to the existing list.
  Future<void> loadMore() async {
    if (state.isLoading || !state.hasMore || _currentSchoolId == null) return;

    final nextPage = state.currentPage + 1;

    final result = await _repository.getStudentProfiles(
      schoolId: _currentSchoolId!,
      classId: state.classFilter,
      searchQuery: state.searchQuery,
      page: nextPage,
      perPage: _perPage,
    );

    result.fold(
      onSuccess: (students) {
        final updatedList = [...state.students, ...students];
        state = state.copyWith(
          students: updatedList,
          currentPage: nextPage,
          hasMore: students.length >= _perPage,
          error: null,
        );
        AppLogger.info(
          'Loaded ${students.length} more students (page $nextPage)',
        );
      },
      onFailure: (failure) {
        state = state.copyWith(
          error: _mapFailureToMessage(failure),
        );
        AppLogger.warning('Failed to load more students: $failure');
      },
    );
  }

  // ─── Refresh ───────────────────────────────────────────────────────

  /// Refreshes the student list.
  Future<void> refresh() async {
    if (_currentSchoolId == null) return;
    await loadStudents(_currentSchoolId!);
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
// STUDENT DETAIL STATE
// ═══════════════════════════════════════════════════════════════════════

/// Immutable state snapshot for the student detail feature.
class StudentDetailState {
  const StudentDetailState({
    this.student,
    this.parentLinks = const [],
    this.promotionHistory = const [],
    this.isLoading = false,
    this.error,
  });

  /// The currently viewed student, or `null` if not loaded.
  final StudentProfileEntity? student;

  /// Parent links associated with this student.
  final List<ParentStudentLinkEntity> parentLinks;

  /// Promotion history for this student.
  final List<PromotionHistoryEntity> promotionHistory;

  /// Whether the detail is loading.
  final bool isLoading;

  /// The most recent error message, or `null`.
  final String? error;

  /// Whether the student data has been loaded.
  bool get isLoaded => student != null;

  /// Creates a copy of this state with the given fields replaced.
  StudentDetailState copyWith({
    StudentProfileEntity? student,
    List<ParentStudentLinkEntity>? parentLinks,
    List<PromotionHistoryEntity>? promotionHistory,
    bool? isLoading,
    String? error,
  }) {
    return StudentDetailState(
      student: student ?? this.student,
      parentLinks: parentLinks ?? this.parentLinks,
      promotionHistory: promotionHistory ?? this.promotionHistory,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }

  /// Clears the current error message.
  StudentDetailState clearError() => copyWith(error: null);
}

// ═══════════════════════════════════════════════════════════════════════
// STUDENT DETAIL NOTIFIER
// ═══════════════════════════════════════════════════════════════════════

/// Riverpod [StateNotifier] that manages the student detail feature's state.
class StudentDetailNotifier extends StateNotifier<StudentDetailState> {
  StudentDetailNotifier({
    required SchoolManagementRepository schoolManagementRepository,
  })  : _repository = schoolManagementRepository,
        super(const StudentDetailState());

  final SchoolManagementRepository _repository;

  // ─── Load Student ──────────────────────────────────────────────────

  /// Loads a student by ID along with parent links and promotion history.
  Future<void> loadStudent(String userId) async {
    state = state.copyWith(isLoading: true, error: null);

    final studentResult = await _repository.getStudentProfile(userId);

    await studentResult.fold(
      onSuccess: (student) async {
        // Load parent links and promotion history in parallel
        final linksResult =
            await _repository.getParentStudentLinks(student.userId);
        final historyResult =
            await _repository.getPromotionHistory(student.userId);

        final links = linksResult.getOrElse(() => []);
        final history = historyResult.getOrElse(() => []);

        state = state.copyWith(
          isLoading: false,
          student: student,
          parentLinks: links,
          promotionHistory: history,
          error: null,
        );
        AppLogger.info('Loaded student detail: $userId');
      },
      onFailure: (failure) {
        state = state.copyWith(
          isLoading: false,
          error: _mapFailureToMessage(failure),
        );
        AppLogger.warning('Failed to load student: $failure');
      },
    );
  }

  // ─── Update Student ────────────────────────────────────────────────

  /// Updates the current student profile.
  Future<void> updateStudent(StudentProfileEntity profile) async {
    final result = await _repository.updateStudentProfile(profile);

    result.fold(
      onSuccess: (updatedProfile) {
        state = state.copyWith(student: updatedProfile, error: null);
        AppLogger.info('Student updated: ${updatedProfile.id}');
      },
      onFailure: (failure) {
        state = state.copyWith(
          error: _mapFailureToMessage(failure),
        );
        AppLogger.warning('Failed to update student: $failure');
      },
    );
  }

  // ─── Link Parent ───────────────────────────────────────────────────

  /// Links a parent to the current student.
  Future<void> linkParent({
    required String parentId,
    required String studentId,
    required String relationship,
    bool isPrimaryContact = false,
  }) async {
    final result = await _repository.linkParentToStudent(
      parentId: parentId,
      studentId: studentId,
      relationship: relationship,
      isPrimaryContact: isPrimaryContact,
    );

    result.fold(
      onSuccess: (_) {
        // Reload parent links to get the updated list
        _reloadParentLinks(studentId);
        AppLogger.info('Parent linked: $parentId -> $studentId');
      },
      onFailure: (failure) {
        state = state.copyWith(
          error: _mapFailureToMessage(failure),
        );
        AppLogger.warning('Failed to link parent: $failure');
      },
    );
  }

  // ─── Unlink Parent ─────────────────────────────────────────────────

  /// Unlinks a parent from the current student.
  Future<void> unlinkParent(String linkId, String studentId) async {
    final result = await _repository.unlinkParentFromStudent(linkId);

    result.fold(
      onSuccess: (_) {
        final updatedLinks =
            state.parentLinks.where((l) => l.id != linkId).toList();
        state = state.copyWith(parentLinks: updatedLinks, error: null);
        AppLogger.info('Parent unlinked: $linkId');
      },
      onFailure: (failure) {
        state = state.copyWith(
          error: _mapFailureToMessage(failure),
        );
        AppLogger.warning('Failed to unlink parent: $failure');
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

  Future<void> _reloadParentLinks(String studentId) async {
    final linksResult = await _repository.getParentStudentLinks(studentId);
    linksResult.fold(
      onSuccess: (links) {
        state = state.copyWith(parentLinks: links);
      },
      onFailure: (_) {},
    );
  }

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

/// Provides the [StudentListNotifier] and its [StudentListState].
final studentListProvider =
    StateNotifierProvider<StudentListNotifier, StudentListState>((ref) {
  return StudentListNotifier(
    schoolManagementRepository: ref.watch(schoolManagementRepositoryProvider),
  );
});

/// Provides the [StudentDetailNotifier] and its [StudentDetailState].
final studentDetailProvider =
    StateNotifierProvider<StudentDetailNotifier, StudentDetailState>((ref) {
  return StudentDetailNotifier(
    schoolManagementRepository: ref.watch(schoolManagementRepositoryProvider),
  );
});
