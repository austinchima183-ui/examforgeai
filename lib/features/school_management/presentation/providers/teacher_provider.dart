import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../config/dependency_injection.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/utils/logger.dart';
import '../../domain/entities/school_management_entities.dart';
import '../../domain/repositories/school_management_repository.dart';


// ═══════════════════════════════════════════════════════════════════════
// TEACHER LIST STATE
// ═══════════════════════════════════════════════════════════════════════

/// Immutable state snapshot for the teacher listing feature.
class TeacherListState {
  const TeacherListState({
    this.teachers = const [],
    this.isLoading = false,
    this.error,
    this.departmentFilter,
    this.searchQuery,
    this.currentPage = 1,
    this.hasMore = true,
  });

  /// The current page of teachers.
  final List<TeacherProfileEntity> teachers;

  /// Whether the initial page load is in progress.
  final bool isLoading;

  /// The most recent error message, or `null`.
  final String? error;

  /// Filter by department ID.
  final String? departmentFilter;

  /// Active search query for filtering teachers.
  final String? searchQuery;

  /// The current page number (1-based).
  final int currentPage;

  /// Whether there are more pages to load.
  final bool hasMore;

  /// Number of teachers currently loaded.
  int get loadedCount => teachers.length;

  /// Whether any async operation is in progress.
  bool get isBusy => isLoading;

  /// Creates a copy of this state with the given fields replaced.
  TeacherListState copyWith({
    List<TeacherProfileEntity>? teachers,
    bool? isLoading,
    String? error,
    String? departmentFilter,
    String? searchQuery,
    int? currentPage,
    bool? hasMore,
  }) {
    return TeacherListState(
      teachers: teachers ?? this.teachers,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      departmentFilter: departmentFilter ?? this.departmentFilter,
      searchQuery: searchQuery ?? this.searchQuery,
      currentPage: currentPage ?? this.currentPage,
      hasMore: hasMore ?? this.hasMore,
    );
  }

  /// Clears the current error message.
  TeacherListState clearError() => copyWith(error: null);
}

// ═══════════════════════════════════════════════════════════════════════
// TEACHER LIST NOTIFIER
// ═══════════════════════════════════════════════════════════════════════

/// Riverpod [StateNotifier] that manages the teacher list feature's state.
class TeacherListNotifier extends StateNotifier<TeacherListState> {
  TeacherListNotifier({
    required SchoolManagementRepository schoolManagementRepository,
  })  : _repository = schoolManagementRepository,
        super(const TeacherListState());

  final SchoolManagementRepository _repository;

  static const int _perPage = 20;

  String? _currentSchoolId;

  /// Sets the school context for subsequent operations.
  void setSchoolId(String schoolId) {
    _currentSchoolId = schoolId;
  }

  // ─── Load Teachers ─────────────────────────────────────────────────

  /// Loads the first page of teachers for the current school.
  Future<void> loadTeachers(String schoolId) async {
    _currentSchoolId = schoolId;
    state = state.copyWith(isLoading: true, error: null);

    final result = await _repository.getTeacherProfiles(
      schoolId: schoolId,
      departmentId: state.departmentFilter,
      searchQuery: state.searchQuery,
      page: 1,
      perPage: _perPage,
    );

    result.fold(
      onSuccess: (teachers) {
        state = state.copyWith(
          isLoading: false,
          teachers: teachers,
          currentPage: 1,
          hasMore: teachers.length >= _perPage,
          error: null,
        );
        AppLogger.info('Loaded ${teachers.length} teachers (page 1)');
      },
      onFailure: (failure) {
        state = state.copyWith(
          isLoading: false,
          error: _mapFailureToMessage(failure),
        );
        AppLogger.warning('Failed to load teachers: $failure');
      },
    );
  }

  // ─── Search Teachers ───────────────────────────────────────────────

  /// Searches teachers by query and reloads the list.
  Future<void> searchTeachers(String query) async {
    if (_currentSchoolId == null) return;
    state = state.copyWith(searchQuery: query, isLoading: true, error: null);

    final result = await _repository.getTeacherProfiles(
      schoolId: _currentSchoolId!,
      departmentId: state.departmentFilter,
      searchQuery: query,
      page: 1,
      perPage: _perPage,
    );

    result.fold(
      onSuccess: (teachers) {
        state = state.copyWith(
          isLoading: false,
          teachers: teachers,
          currentPage: 1,
          hasMore: teachers.length >= _perPage,
          error: null,
        );
        AppLogger.info('Search "$query" returned ${teachers.length} teachers');
      },
      onFailure: (failure) {
        state = state.copyWith(
          isLoading: false,
          error: _mapFailureToMessage(failure),
        );
        AppLogger.warning('Failed to search teachers: $failure');
      },
    );
  }

  // ─── Filter By Department ──────────────────────────────────────────

  /// Filters teachers by department and reloads the list.
  Future<void> filterByDepartment(String? departmentId) async {
    if (_currentSchoolId == null) return;
    state = state.copyWith(
      departmentFilter: departmentId,
      isLoading: true,
      error: null,
    );

    final result = await _repository.getTeacherProfiles(
      schoolId: _currentSchoolId!,
      departmentId: departmentId,
      searchQuery: state.searchQuery,
      page: 1,
      perPage: _perPage,
    );

    result.fold(
      onSuccess: (teachers) {
        state = state.copyWith(
          isLoading: false,
          teachers: teachers,
          currentPage: 1,
          hasMore: teachers.length >= _perPage,
          error: null,
        );
        AppLogger
            .info('Department filter returned ${teachers.length} teachers');
      },
      onFailure: (failure) {
        state = state.copyWith(
          isLoading: false,
          error: _mapFailureToMessage(failure),
        );
        AppLogger.warning('Failed to filter teachers: $failure');
      },
    );
  }

  // ─── Create Teacher ────────────────────────────────────────────────

  /// Creates a new teacher profile.
  Future<void> createTeacher(TeacherProfileEntity profile) async {
    final result = await _repository.createTeacherProfile(profile);

    result.fold(
      onSuccess: (createdProfile) {
        final updatedList = [createdProfile, ...state.teachers];
        state = state.copyWith(teachers: updatedList, error: null);
        AppLogger.info('Teacher created: ${createdProfile.id}');
      },
      onFailure: (failure) {
        state = state.copyWith(
          error: _mapFailureToMessage(failure),
        );
        AppLogger.warning('Failed to create teacher: $failure');
      },
    );
  }

  // ─── Update Teacher ────────────────────────────────────────────────

  /// Updates an existing teacher profile.
  Future<void> updateTeacher(TeacherProfileEntity profile) async {
    final result = await _repository.updateTeacherProfile(profile);

    result.fold(
      onSuccess: (updatedProfile) {
        final updatedList = state.teachers
            .map((t) => t.id == updatedProfile.id ? updatedProfile : t)
            .toList();
        state = state.copyWith(teachers: updatedList, error: null);
        AppLogger.info('Teacher updated: ${updatedProfile.id}');
      },
      onFailure: (failure) {
        state = state.copyWith(
          error: _mapFailureToMessage(failure),
        );
        AppLogger.warning('Failed to update teacher: $failure');
      },
    );
  }

  // ─── Load More ─────────────────────────────────────────────────────

  /// Loads the next page of teachers and appends to the existing list.
  Future<void> loadMore() async {
    if (state.isLoading || !state.hasMore || _currentSchoolId == null) return;

    final nextPage = state.currentPage + 1;

    final result = await _repository.getTeacherProfiles(
      schoolId: _currentSchoolId!,
      departmentId: state.departmentFilter,
      searchQuery: state.searchQuery,
      page: nextPage,
      perPage: _perPage,
    );

    result.fold(
      onSuccess: (teachers) {
        final updatedList = [...state.teachers, ...teachers];
        state = state.copyWith(
          teachers: updatedList,
          currentPage: nextPage,
          hasMore: teachers.length >= _perPage,
          error: null,
        );
        AppLogger.info(
          'Loaded ${teachers.length} more teachers (page $nextPage)',
        );
      },
      onFailure: (failure) {
        state = state.copyWith(
          error: _mapFailureToMessage(failure),
        );
        AppLogger.warning('Failed to load more teachers: $failure');
      },
    );
  }

  // ─── Refresh ───────────────────────────────────────────────────────

  /// Refreshes the teacher list.
  Future<void> refresh() async {
    if (_currentSchoolId == null) return;
    await loadTeachers(_currentSchoolId!);
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
// TEACHER DETAIL STATE
// ═══════════════════════════════════════════════════════════════════════

/// Immutable state snapshot for the teacher detail feature.
class TeacherDetailState {
  const TeacherDetailState({
    this.teacher,
    this.isLoading = false,
    this.error,
  });

  /// The currently viewed teacher, or `null` if not loaded.
  final TeacherProfileEntity? teacher;

  /// Whether the detail is loading.
  final bool isLoading;

  /// The most recent error message, or `null`.
  final String? error;

  /// Whether the teacher data has been loaded.
  bool get isLoaded => teacher != null;

  /// Creates a copy of this state with the given fields replaced.
  TeacherDetailState copyWith({
    TeacherProfileEntity? teacher,
    bool? isLoading,
    String? error,
  }) {
    return TeacherDetailState(
      teacher: teacher ?? this.teacher,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }

  /// Clears the current error message.
  TeacherDetailState clearError() => copyWith(error: null);
}

// ═══════════════════════════════════════════════════════════════════════
// TEACHER DETAIL NOTIFIER
// ═══════════════════════════════════════════════════════════════════════

/// Riverpod [StateNotifier] that manages the teacher detail feature's state.
class TeacherDetailNotifier extends StateNotifier<TeacherDetailState> {
  TeacherDetailNotifier({
    required SchoolManagementRepository schoolManagementRepository,
  })  : _repository = schoolManagementRepository,
        super(const TeacherDetailState());

  final SchoolManagementRepository _repository;

  // ─── Load Teacher ──────────────────────────────────────────────────

  /// Loads a teacher by user ID.
  Future<void> loadTeacher(String userId) async {
    state = state.copyWith(isLoading: true, error: null);

    final result = await _repository.getTeacherProfile(userId);

    result.fold(
      onSuccess: (teacher) {
        state = state.copyWith(
          isLoading: false,
          teacher: teacher,
          error: null,
        );
        AppLogger.info('Loaded teacher detail: $userId');
      },
      onFailure: (failure) {
        state = state.copyWith(
          isLoading: false,
          error: _mapFailureToMessage(failure),
        );
        AppLogger.warning('Failed to load teacher: $failure');
      },
    );
  }

  // ─── Update Teacher ────────────────────────────────────────────────

  /// Updates the current teacher profile.
  Future<void> updateTeacher(TeacherProfileEntity profile) async {
    final result = await _repository.updateTeacherProfile(profile);

    result.fold(
      onSuccess: (updatedProfile) {
        state = state.copyWith(teacher: updatedProfile, error: null);
        AppLogger.info('Teacher updated: ${updatedProfile.id}');
      },
      onFailure: (failure) {
        state = state.copyWith(
          error: _mapFailureToMessage(failure),
        );
        AppLogger.warning('Failed to update teacher: $failure');
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

/// Provides the [TeacherListNotifier] and its [TeacherListState].
final teacherListProvider =
    StateNotifierProvider<TeacherListNotifier, TeacherListState>((ref) {
  return TeacherListNotifier(
    schoolManagementRepository: ref.watch(schoolManagementRepositoryProvider),
  );
});

/// Provides the [TeacherDetailNotifier] and its [TeacherDetailState].
final teacherDetailProvider =
    StateNotifierProvider<TeacherDetailNotifier, TeacherDetailState>((ref) {
  return TeacherDetailNotifier(
    schoolManagementRepository: ref.watch(schoolManagementRepositoryProvider),
  );
});
