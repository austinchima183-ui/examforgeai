import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/utils/logger.dart';
import '../../domain/entities/school_management_entities.dart';
import '../../domain/repositories/school_management_repository.dart';
import '../../../../config/dependency_injection.dart';


// ═══════════════════════════════════════════════════════════════════════
// REPOSITORY PROVIDER
// ═══════════════════════════════════════════════════════════════════════

// Provider is registered in dependency_injection.dart
final schoolManagementRepositoryProvider =
    Provider<SchoolManagementRepository>((ref) {
  throw UnimplementedError(
    'schoolManagementRepositoryProvider must be overridden',
  );
});

// ═══════════════════════════════════════════════════════════════════════
// SCHOOL LIST STATE
// ═══════════════════════════════════════════════════════════════════════

/// Immutable state snapshot for the school listing feature.
class SchoolListState {
  const SchoolListState({
    this.schools = const [],
    this.isLoading = false,
    this.error,
    this.currentPage = 1,
    this.hasMore = true,
    this.searchQuery,
  });

  /// The current page of schools.
  final List<SchoolEntity> schools;

  /// Whether the initial page load is in progress.
  final bool isLoading;

  /// The most recent error message, or `null`.
  final String? error;

  /// The current page number (1-based).
  final int currentPage;

  /// Whether there are more pages to load.
  final bool hasMore;

  /// Active search query for filtering schools.
  final String? searchQuery;

  /// Number of schools currently loaded.
  int get loadedCount => schools.length;

  /// Whether any async operation is in progress.
  bool get isBusy => isLoading;

  /// Creates a copy of this state with the given fields replaced.
  SchoolListState copyWith({
    List<SchoolEntity>? schools,
    bool? isLoading,
    String? error,
    int? currentPage,
    bool? hasMore,
    String? searchQuery,
  }) {
    return SchoolListState(
      schools: schools ?? this.schools,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      currentPage: currentPage ?? this.currentPage,
      hasMore: hasMore ?? this.hasMore,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }

  /// Clears the current error message.
  SchoolListState clearError() => copyWith(error: null);
}

// ═══════════════════════════════════════════════════════════════════════
// SCHOOL LIST NOTIFIER
// ═══════════════════════════════════════════════════════════════════════

/// Riverpod [StateNotifier] that manages the school list feature's state.
class SchoolListNotifier extends StateNotifier<SchoolListState> {
  SchoolListNotifier({
    required SchoolManagementRepository schoolManagementRepository,
  })  : _repository = schoolManagementRepository,
        super(const SchoolListState());

  final SchoolManagementRepository _repository;

  static const int _perPage = 20;

  // ─── Load Schools ──────────────────────────────────────────────────

  /// Loads the first page of schools.
  Future<void> loadSchools() async {
    state = state.copyWith(isLoading: true, error: null);

    final result = await _repository.getSchools(page: 1, perPage: _perPage);

    result.fold(
      onSuccess: (schools) {
        state = state.copyWith(
          isLoading: false,
          schools: schools,
          currentPage: 1,
          hasMore: schools.length >= _perPage,
          error: null,
        );
        AppLogger.info('Loaded ${schools.length} schools (page 1)');
      },
      onFailure: (failure) {
        state = state.copyWith(
          isLoading: false,
          error: _mapFailureToMessage(failure),
        );
        AppLogger.warning('Failed to load schools: $failure');
      },
    );
  }

  // ─── Search Schools ────────────────────────────────────────────────

  /// Searches schools by query and reloads the list.
  Future<void> searchSchools(String query) async {
    state = state.copyWith(searchQuery: query, isLoading: true, error: null);

    final result = await _repository.getSchools(page: 1, perPage: _perPage);

    result.fold(
      onSuccess: (schools) {
        // Client-side filtering by search query
        final filtered = query.isEmpty
            ? schools
            : schools
                .where((s) =>
                    s.name.toLowerCase().contains(query.toLowerCase()) ||
                    s.code.toLowerCase().contains(query.toLowerCase()))
                .toList();
        state = state.copyWith(
          isLoading: false,
          schools: filtered,
          currentPage: 1,
          hasMore: schools.length >= _perPage,
          error: null,
        );
        AppLogger.info('Search "$query" returned ${filtered.length} schools');
      },
      onFailure: (failure) {
        state = state.copyWith(
          isLoading: false,
          error: _mapFailureToMessage(failure),
        );
        AppLogger.warning('Failed to search schools: $failure');
      },
    );
  }

  // ─── Delete School ─────────────────────────────────────────────────

  /// Deletes a school by its ID.
  Future<void> deleteSchool(String schoolId) async {
    final result = await _repository.deleteSchool(schoolId);

    result.fold(
      onSuccess: (_) {
        final updatedList =
            state.schools.where((s) => s.id != schoolId).toList();
        state = state.copyWith(schools: updatedList);
        AppLogger.info('School deleted: $schoolId');
      },
      onFailure: (failure) {
        state = state.copyWith(
          error: _mapFailureToMessage(failure),
        );
        AppLogger.warning('Failed to delete school: $failure');
      },
    );
  }

  // ─── Load More ─────────────────────────────────────────────────────

  /// Loads the next page of schools and appends to the existing list.
  Future<void> loadMore() async {
    if (state.isLoading || !state.hasMore) return;

    final nextPage = state.currentPage + 1;

    final result =
        await _repository.getSchools(page: nextPage, perPage: _perPage);

    result.fold(
      onSuccess: (schools) {
        final updatedList = [...state.schools, ...schools];
        state = state.copyWith(
          schools: updatedList,
          currentPage: nextPage,
          hasMore: schools.length >= _perPage,
          error: null,
        );
        AppLogger.info(
          'Loaded ${schools.length} more schools (page $nextPage)',
        );
      },
      onFailure: (failure) {
        state = state.copyWith(
          error: _mapFailureToMessage(failure),
        );
        AppLogger.warning('Failed to load more schools: $failure');
      },
    );
  }

  // ─── Refresh ───────────────────────────────────────────────────────

  /// Refreshes the school list by reloading the first page.
  Future<void> refresh() async {
    state = state.copyWith(isLoading: true, error: null);

    final result = await _repository.getSchools(page: 1, perPage: _perPage);

    result.fold(
      onSuccess: (schools) {
        state = state.copyWith(
          isLoading: false,
          schools: schools,
          currentPage: 1,
          hasMore: schools.length >= _perPage,
          error: null,
        );
        AppLogger.info('Refreshed schools list');
      },
      onFailure: (failure) {
        state = state.copyWith(
          isLoading: false,
          error: _mapFailureToMessage(failure),
        );
        AppLogger.warning('Failed to refresh schools: $failure');
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
// SCHOOL DETAIL STATE
// ═══════════════════════════════════════════════════════════════════════

/// Immutable state snapshot for the school detail feature.
class SchoolDetailState {
  const SchoolDetailState({
    this.school,
    this.branches = const [],
    this.departments = const [],
    this.isLoading = false,
    this.error,
  });

  /// The currently viewed school, or `null` if not loaded.
  final SchoolEntity? school;

  /// Branches belonging to this school.
  final List<SchoolBranchEntity> branches;

  /// Departments belonging to this school.
  final List<DepartmentEntity> departments;

  /// Whether the detail is loading.
  final bool isLoading;

  /// The most recent error message, or `null`.
  final String? error;

  /// Whether the school data has been loaded.
  bool get isLoaded => school != null;

  /// Creates a copy of this state with the given fields replaced.
  SchoolDetailState copyWith({
    SchoolEntity? school,
    List<SchoolBranchEntity>? branches,
    List<DepartmentEntity>? departments,
    bool? isLoading,
    String? error,
  }) {
    return SchoolDetailState(
      school: school ?? this.school,
      branches: branches ?? this.branches,
      departments: departments ?? this.departments,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }

  /// Clears the current error message.
  SchoolDetailState clearError() => copyWith(error: null);
}

// ═══════════════════════════════════════════════════════════════════════
// SCHOOL DETAIL NOTIFIER
// ═══════════════════════════════════════════════════════════════════════

/// Riverpod [StateNotifier] that manages the school detail feature's state.
class SchoolDetailNotifier extends StateNotifier<SchoolDetailState> {
  SchoolDetailNotifier({
    required SchoolManagementRepository schoolManagementRepository,
  })  : _repository = schoolManagementRepository,
        super(const SchoolDetailState());

  final SchoolManagementRepository _repository;

  // ─── Load School ───────────────────────────────────────────────────

  /// Loads a school by ID along with its branches and departments.
  Future<void> loadSchool(String schoolId) async {
    state = state.copyWith(isLoading: true, error: null);

    final schoolResult = await _repository.getSchool(schoolId);

    await schoolResult.fold(
      onSuccess: (school) async {
        // Load branches and departments in parallel
        final branchesResult = await _repository.getBranches(schoolId);
        final departmentsResult = await _repository.getDepartments(schoolId);

        final branches = branchesResult.getOrElse(() => []);
        final departments = departmentsResult.getOrElse(() => []);

        state = state.copyWith(
          isLoading: false,
          school: school,
          branches: branches,
          departments: departments,
          error: null,
        );
        AppLogger.info('Loaded school detail: $schoolId');
      },
      onFailure: (failure) {
        state = state.copyWith(
          isLoading: false,
          error: _mapFailureToMessage(failure),
        );
        AppLogger.warning('Failed to load school: $failure');
      },
    );
  }

  // ─── Update School ─────────────────────────────────────────────────

  /// Updates the current school entity.
  Future<void> updateSchool(SchoolEntity school) async {
    final result = await _repository.updateSchool(school);

    result.fold(
      onSuccess: (updatedSchool) {
        state = state.copyWith(school: updatedSchool, error: null);
        AppLogger.info('School updated: ${updatedSchool.id}');
      },
      onFailure: (failure) {
        state = state.copyWith(
          error: _mapFailureToMessage(failure),
        );
        AppLogger.warning('Failed to update school: $failure');
      },
    );
  }

  // ─── Create Branch ─────────────────────────────────────────────────

  /// Creates a new branch for the current school.
  Future<void> createBranch(SchoolBranchEntity branch) async {
    final result = await _repository.createBranch(branch);

    result.fold(
      onSuccess: (createdBranch) {
        final updatedBranches = [...state.branches, createdBranch];
        state = state.copyWith(branches: updatedBranches, error: null);
        AppLogger.info('Branch created: ${createdBranch.id}');
      },
      onFailure: (failure) {
        state = state.copyWith(
          error: _mapFailureToMessage(failure),
        );
        AppLogger.warning('Failed to create branch: $failure');
      },
    );
  }

  // ─── Update Branch ─────────────────────────────────────────────────

  /// Updates an existing branch.
  Future<void> updateBranch(SchoolBranchEntity branch) async {
    final result = await _repository.updateBranch(branch);

    result.fold(
      onSuccess: (updatedBranch) {
        final updatedBranches = state.branches
            .map((b) => b.id == updatedBranch.id ? updatedBranch : b)
            .toList();
        state = state.copyWith(branches: updatedBranches, error: null);
        AppLogger.info('Branch updated: ${updatedBranch.id}');
      },
      onFailure: (failure) {
        state = state.copyWith(
          error: _mapFailureToMessage(failure),
        );
        AppLogger.warning('Failed to update branch: $failure');
      },
    );
  }

  // ─── Create Department ─────────────────────────────────────────────

  /// Creates a new department for the current school.
  Future<void> createDepartment(DepartmentEntity department) async {
    final result = await _repository.createDepartment(department);

    result.fold(
      onSuccess: (createdDepartment) {
        final updatedDepts = [...state.departments, createdDepartment];
        state = state.copyWith(departments: updatedDepts, error: null);
        AppLogger.info('Department created: ${createdDepartment.id}');
      },
      onFailure: (failure) {
        state = state.copyWith(
          error: _mapFailureToMessage(failure),
        );
        AppLogger.warning('Failed to create department: $failure');
      },
    );
  }

  // ─── Update Department ─────────────────────────────────────────────

  /// Updates an existing department.
  Future<void> updateDepartment(DepartmentEntity department) async {
    final result = await _repository.updateDepartment(department);

    result.fold(
      onSuccess: (updatedDept) {
        final updatedDepts = state.departments
            .map((d) => d.id == updatedDept.id ? updatedDept : d)
            .toList();
        state = state.copyWith(departments: updatedDepts, error: null);
        AppLogger.info('Department updated: ${updatedDept.id}');
      },
      onFailure: (failure) {
        state = state.copyWith(
          error: _mapFailureToMessage(failure),
        );
        AppLogger.warning('Failed to update department: $failure');
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

/// Provides the [SchoolListNotifier] and its [SchoolListState].
final schoolListProvider =
    StateNotifierProvider<SchoolListNotifier, SchoolListState>((ref) {
  return SchoolListNotifier(
    schoolManagementRepository: ref.watch(schoolManagementRepositoryProvider),
  );
});

/// Provides the [SchoolDetailNotifier] and its [SchoolDetailState].
final schoolDetailProvider =
    StateNotifierProvider<SchoolDetailNotifier, SchoolDetailState>((ref) {
  return SchoolDetailNotifier(
    schoolManagementRepository: ref.watch(schoolManagementRepositoryProvider),
  );
});
