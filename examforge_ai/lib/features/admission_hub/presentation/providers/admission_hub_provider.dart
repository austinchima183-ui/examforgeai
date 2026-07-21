import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;

import '../../../../core/errors/failures.dart';
import '../../../../core/utils/logger.dart';
import '../../data/datasources/admission_hub_remote_datasource.dart';
import '../../data/repositories/admission_hub_repository_impl.dart';
import '../../domain/entities/admission_hub_entities.dart';
import '../../domain/usecases/admission_hub_usecases.dart';

// ═══════════════════════════════════════════════════════════════════════
// ADMISSION HUB STATE
// ═══════════════════════════════════════════════════════════════════════

/// Immutable state snapshot for the Admission Hub feature.
class AdmissionHubState {
  const AdmissionHubState({
    this.universities = const [],
    this.faculties = const [],
    this.departments = const [],
    this.postUtmeProducts = const [],
    this.checklist,
    this.applications = const [],
    this.eligibilityResult,
    this.comparison,
    this.isLoading = false,
    this.isSearching = false,
    this.isCheckingEligibility = false,
    this.isLoadingProducts = false,
    this.isLoadingChecklist = false,
    this.isCreatingApplication = false,
    this.isComparing = false,
    this.error,
    this.searchQuery = '',
    this.selectedUniversityType,
    this.selectedState,
    this.hasMoreUniversities = true,
    this.currentPage = 1,
  });

  final List<University> universities;
  final List<UniversityFaculty> faculties;
  final List<UniversityDepartment> departments;
  final List<PostUtmeProduct> postUtmeProducts;
  final AdmissionChecklist? checklist;
  final List<AdmissionApplication> applications;
  final EligibilityResult? eligibilityResult;
  final UniversityComparison? comparison;

  final bool isLoading;
  final bool isSearching;
  final bool isCheckingEligibility;
  final bool isLoadingProducts;
  final bool isLoadingChecklist;
  final bool isCreatingApplication;
  final bool isComparing;

  final String? error;
  final String searchQuery;
  final UniversityType? selectedUniversityType;
  final String? selectedState;

  final bool hasMoreUniversities;
  final int currentPage;

  int get currentPage => currentPage;
  bool get isBusy =>
      isLoading ||
      isSearching ||
      isCheckingEligibility ||
      isLoadingProducts ||
      isLoadingChecklist ||
      isCreatingApplication ||
      isComparing;

  AdmissionHubState copyWith({
    List<University>? universities,
    List<UniversityFaculty>? faculties,
    List<UniversityDepartment>? departments,
    List<PostUtmeProduct>? postUtmeProducts,
    AdmissionChecklist? checklist,
    List<AdmissionApplication>? applications,
    EligibilityResult? eligibilityResult,
    UniversityComparison? comparison,
    bool? isLoading,
    bool? isSearching,
    bool? isCheckingEligibility,
    bool? isLoadingProducts,
    bool? isLoadingChecklist,
    bool? isCreatingApplication,
    bool? isComparing,
    String? error,
    String? searchQuery,
    UniversityType? selectedUniversityType,
    String? selectedState,
    bool? hasMoreUniversities,
    int? currentPage,
    bool clearEligibilityResult = false,
    bool clearChecklist = false,
    bool clearComparison = false,
    bool clearSelectedUniversityType = false,
  }) {
    return AdmissionHubState(
      universities: universities ?? this.universities,
      faculties: faculties ?? this.faculties,
      departments: departments ?? this.departments,
      postUtmeProducts: postUtmeProducts ?? this.postUtmeProducts,
      checklist: clearChecklist ? null : (checklist ?? this.checklist),
      applications: applications ?? this.applications,
      eligibilityResult: clearEligibilityResult
          ? null
          : (eligibilityResult ?? this.eligibilityResult),
      comparison:
          clearComparison ? null : (comparison ?? this.comparison),
      isLoading: isLoading ?? this.isLoading,
      isSearching: isSearching ?? this.isSearching,
      isCheckingEligibility:
          isCheckingEligibility ?? this.isCheckingEligibility,
      isLoadingProducts: isLoadingProducts ?? this.isLoadingProducts,
      isLoadingChecklist: isLoadingChecklist ?? this.isLoadingChecklist,
      isCreatingApplication:
          isCreatingApplication ?? this.isCreatingApplication,
      isComparing: isComparing ?? this.isComparing,
      error: error,
      searchQuery: searchQuery ?? this.searchQuery,
      selectedUniversityType: clearSelectedUniversityType
          ? null
          : (selectedUniversityType ?? this.selectedUniversityType),
      selectedState: selectedState ?? this.selectedState,
      hasMoreUniversities:
          hasMoreUniversities ?? this.hasMoreUniversities,
      currentPage: currentPage ?? currentPage,
    );
  }

  AdmissionHubState clearError() => copyWith(error: null);
}

// ═══════════════════════════════════════════════════════════════════════
// ADMISSION HUB NOTIFIER
// ═══════════════════════════════════════════════════════════════════════

/// Riverpod [StateNotifier] that manages the Admission Hub feature's state.
class AdmissionHubNotifier extends StateNotifier<AdmissionHubState> {
  AdmissionHubNotifier({
    required GetUniversitiesUseCase getUniversities,
    required SearchUniversitiesUseCase searchUniversities,
    required GetUniversityDepartmentsUseCase getUniversityDepartments,
    required CheckAdmissionEligibilityUseCase checkAdmissionEligibility,
    required GetPostUtmeProductsUseCase getPostUtmeProducts,
    required GetAdmissionChecklistUseCase getAdmissionChecklist,
    required UpdateAdmissionChecklistUseCase updateAdmissionChecklist,
    required CreateAdmissionApplicationUseCase createAdmissionApplication,
    required CompareUniversitiesUseCase compareUniversities,
    required String? userId,
  })  : _getUniversities = getUniversities,
        _searchUniversities = searchUniversities,
        _getUniversityDepartments = getUniversityDepartments,
        _checkAdmissionEligibility = checkAdmissionEligibility,
        _getPostUtmeProducts = getPostUtmeProducts,
        _getAdmissionChecklist = getAdmissionChecklist,
        _updateAdmissionChecklist = updateAdmissionChecklist,
        _createAdmissionApplication = createAdmissionApplication,
        _compareUniversities = compareUniversities,
        _userId = userId,
        super(const AdmissionHubState());

  final GetUniversitiesUseCase _getUniversities;
  final SearchUniversitiesUseCase _searchUniversities;
  final GetUniversityDepartmentsUseCase _getUniversityDepartments;
  final CheckAdmissionEligibilityUseCase _checkAdmissionEligibility;
  final GetPostUtmeProductsUseCase _getPostUtmeProducts;
  final GetAdmissionChecklistUseCase _getAdmissionChecklist;
  final UpdateAdmissionChecklistUseCase _updateAdmissionChecklist;
  final CreateAdmissionApplicationUseCase _createAdmissionApplication;
  final CompareUniversitiesUseCase _compareUniversities;
  final String? _userId;

  static const int _pageSize = 20;

  // ─── Load Universities ──────────────────────────────────────────────

  /// Loads the first page of universities.
  Future<void> loadUniversities() async {
    state = state.copyWith(isLoading: true, error: null);

    final result = await _getUniversities(
      type: state.selectedUniversityType,
      state: state.selectedState,
      page: 1,
      pageSize: _pageSize,
    );

    result.fold(
      onSuccess: (universities) {
        state = state.copyWith(
          isLoading: false,
          universities: universities,
          currentPage: 1,
          hasMoreUniversities: universities.length >= _pageSize,
        );
      },
      onFailure: (failure) {
        state = state.copyWith(
          isLoading: false,
          error: _mapFailure(failure),
        );
      },
    );
  }

  /// Loads more universities (pagination).
  Future<void> loadMoreUniversities() async {
    if (state.isBusy || !state.hasMoreUniversities) return;

    final nextPage = state.currentPage + 1;
    final result = await _getUniversities(
      type: state.selectedUniversityType,
      state: state.selectedState,
      page: nextPage,
      pageSize: _pageSize,
    );

    result.fold(
      onSuccess: (universities) {
        state = state.copyWith(
          universities: [...state.universities, ...universities],
          currentPage: nextPage,
          hasMoreUniversities: universities.length >= _pageSize,
        );
      },
      onFailure: (failure) {
        state = state.copyWith(error: _mapFailure(failure));
      },
    );
  }

  // ─── Search Universities ────────────────────────────────────────────

  /// Searches universities by query string.
  Future<void> searchUniversities(String query) async {
    state = state.copyWith(isSearching: true, searchQuery: query, error: null);

    final result = await _searchUniversities(
      query: query,
      type: state.selectedUniversityType,
      state: state.selectedState,
      page: 1,
      pageSize: _pageSize,
    );

    result.fold(
      onSuccess: (universities) {
        state = state.copyWith(
          isSearching: false,
          universities: universities,
          currentPage: 1,
          hasMoreUniversities: universities.length >= _pageSize,
        );
      },
      onFailure: (failure) {
        state = state.copyWith(
          isSearching: false,
          error: _mapFailure(failure),
        );
      },
    );
  }

  /// Clears the search query and reloads all universities.
  Future<void> clearSearch() async {
    state = state.copyWith(searchQuery: '', clearEligibilityResult: true);
    await loadUniversities();
  }

  // ─── Filter Helpers ─────────────────────────────────────────────────

  /// Sets the university type filter.
  Future<void> setUniversityType(UniversityType? type) async {
    state = state.copyWith(
      selectedUniversityType: type,
      clearSelectedUniversityType: type == null,
    );
    await loadUniversities();
  }

  /// Sets the state filter.
  Future<void> setStateFilter(String? stateFilter) async {
    state = state.copyWith(selectedState: stateFilter);
    await loadUniversities();
  }

  // ─── Departments ────────────────────────────────────────────────────

  /// Loads departments for a university.
  Future<void> loadDepartments(String universityId) async {
    state = state.copyWith(isLoading: true, error: null);

    final result = await _getUniversityDepartments(
      universityId: universityId,
    );

    result.fold(
      onSuccess: (departments) {
        state = state.copyWith(
          isLoading: false,
          departments: departments,
        );
      },
      onFailure: (failure) {
        state = state.copyWith(
          isLoading: false,
          error: _mapFailure(failure),
        );
      },
    );
  }

  // ─── Eligibility Checker ────────────────────────────────────────────

  /// Checks admission eligibility.
  Future<void> checkEligibility({
    required String universityId,
    required String departmentId,
    required double jambScore,
    required List<Map<String, dynamic>> oLevelResults,
    List<String>? selectedSubjects,
  }) async {
    state =
        state.copyWith(isCheckingEligibility: true, clearEligibilityResult: true, error: null);

    final result = await _checkAdmissionEligibility(
      universityId: universityId,
      departmentId: departmentId,
      jambScore: jambScore,
      oLevelResults: oLevelResults,
      selectedSubjects: selectedSubjects,
    );

    result.fold(
      onSuccess: (eligibilityResult) {
        state = state.copyWith(
          isCheckingEligibility: false,
          eligibilityResult: eligibilityResult,
        );
      },
      onFailure: (failure) {
        state = state.copyWith(
          isCheckingEligibility: false,
          error: _mapFailure(failure),
        );
      },
    );
  }

  // ─── Post-UTME Products ─────────────────────────────────────────────

  /// Loads Post-UTME products for a university/department.
  Future<void> loadPostUtmeProducts({
    String? universityId,
    String? departmentId,
    int? year,
  }) async {
    state = state.copyWith(isLoadingProducts: true, error: null);

    final result = await _getPostUtmeProducts(
      universityId: universityId,
      departmentId: departmentId,
      year: year,
      page: 1,
      pageSize: _pageSize,
    );

    result.fold(
      onSuccess: (products) {
        state = state.copyWith(
          isLoadingProducts: false,
          postUtmeProducts: products,
        );
      },
      onFailure: (failure) {
        state = state.copyWith(
          isLoadingProducts: false,
          error: _mapFailure(failure),
        );
      },
    );
  }

  // ─── Admission Checklist ────────────────────────────────────────────

  /// Loads the admission checklist.
  Future<void> loadChecklist({
    required String universityId,
    required String departmentId,
  }) async {
    if (_userId == null) return;
    state = state.copyWith(isLoadingChecklist: true, error: null);

    final result = await _getAdmissionChecklist(
      userId: _userId!,
      universityId: universityId,
      departmentId: departmentId,
    );

    result.fold(
      onSuccess: (checklist) {
        state = state.copyWith(
          isLoadingChecklist: false,
          checklist: checklist,
        );
      },
      onFailure: (failure) {
        state = state.copyWith(
          isLoadingChecklist: false,
          error: _mapFailure(failure),
        );
      },
    );
  }

  /// Updates checklist items.
  Future<void> updateChecklist({
    required String checklistId,
    List<Map<String, dynamic>>? completedItems,
    List<Map<String, dynamic>>? documents,
    double? overallReadinessScore,
    String? status,
  }) async {
    final result = await _updateAdmissionChecklist(
      checklistId: checklistId,
      completedItems: completedItems,
      documents: documents,
      overallReadinessScore: overallReadinessScore,
      status: status,
    );

    result.fold(
      onSuccess: (checklist) {
        state = state.copyWith(checklist: checklist);
      },
      onFailure: (failure) {
        state = state.copyWith(error: _mapFailure(failure));
      },
    );
  }

  // ─── Admission Applications ─────────────────────────────────────────

  /// Creates a new admission application.
  Future<void> createApplication({
    required String universityId,
    required String departmentId,
    required String course,
    required int applicationYear,
    double? jambScore,
    double? postUtmeScore,
    List<Map<String, dynamic>> oLevelResults = const [],
    List<Map<String, dynamic>> documents = const [],
    String? notes,
  }) async {
    if (_userId == null) return;
    state = state.copyWith(isCreatingApplication: true, error: null);

    final result = await _createAdmissionApplication(
      userId: _userId!,
      universityId: universityId,
      departmentId: departmentId,
      course: course,
      applicationYear: applicationYear,
      jambScore: jambScore,
      postUtmeScore: postUtmeScore,
      oLevelResults: oLevelResults,
      documents: documents,
      notes: notes,
    );

    result.fold(
      onSuccess: (application) {
        state = state.copyWith(
          isCreatingApplication: false,
          applications: [application, ...state.applications],
        );
      },
      onFailure: (failure) {
        state = state.copyWith(
          isCreatingApplication: false,
          error: _mapFailure(failure),
        );
      },
    );
  }

  // ─── University Comparison ──────────────────────────────────────────

  /// Compares universities side by side.
  Future<void> compareUniversities(List<String> universityIds) async {
    state = state.copyWith(isComparing: true, clearComparison: true, error: null);

    final result = await _compareUniversities(universityIds: universityIds);

    result.fold(
      onSuccess: (comparison) {
        state = state.copyWith(
          isComparing: false,
          comparison: comparison,
        );
      },
      onFailure: (failure) {
        state = state.copyWith(
          isComparing: false,
          error: _mapFailure(failure),
        );
      },
    );
  }

  // ─── Failure Mapping ────────────────────────────────────────────────

  String _mapFailure(Failure failure) => failure.when(
        server: (message, statusCode, data) =>
            'Server error ($statusCode): $message',
        cache: (message) => 'Cache error: $message',
        auth: (message, code) => 'Auth error: $message',
        network: (message) => 'Network error: $message',
        validation: (message, fieldErrors) =>
            'Validation error: $message',
        notFound: (message) => message,
        unauthorized: (message) => 'Unauthorized: $message',
        forbidden: (message) => 'Forbidden: $message',
      );
}

// ═══════════════════════════════════════════════════════════════════════
// PROVIDERS
// ═══════════════════════════════════════════════════════════════════════

/// Provides the Supabase client.
final _supabaseClientProvider = Provider<sb.SupabaseClient>((ref) {
  return sb.Supabase.instance.client;
});

/// Provides the remote datasource.
final _remoteDatasourceProvider =
    Provider<AdmissionHubRemoteDatasource>((ref) {
  return AdmissionHubRemoteDatasourceImpl(
    supabaseClient: ref.watch(_supabaseClientProvider),
  );
});

/// Provides the repository implementation.
final _repositoryProvider = Provider<AdmissionHubRepositoryImpl>((ref) {
  return AdmissionHubRepositoryImpl(
    remoteDatasource: ref.watch(_remoteDatasourceProvider),
    supabaseClient: ref.watch(_supabaseClientProvider),
  );
});

/// Provides the current user ID.
final _userIdProvider = Provider<String?>((ref) {
  return sb.Supabase.instance.client.auth.currentUser?.id;
});

/// Provides the [GetUniversitiesUseCase].
final _getUniversitiesUseCaseProvider = Provider<GetUniversitiesUseCase>((ref) {
  return GetUniversitiesUseCase(ref.watch(_repositoryProvider));
});

/// Provides the [SearchUniversitiesUseCase].
final _searchUniversitiesUseCaseProvider =
    Provider<SearchUniversitiesUseCase>((ref) {
  return SearchUniversitiesUseCase(ref.watch(_repositoryProvider));
});

/// Provides the [GetUniversityDepartmentsUseCase].
final _getUniversityDepartmentsUseCaseProvider =
    Provider<GetUniversityDepartmentsUseCase>((ref) {
  return GetUniversityDepartmentsUseCase(ref.watch(_repositoryProvider));
});

/// Provides the [CheckAdmissionEligibilityUseCase].
final _checkAdmissionEligibilityUseCaseProvider =
    Provider<CheckAdmissionEligibilityUseCase>((ref) {
  return CheckAdmissionEligibilityUseCase(ref.watch(_repositoryProvider));
});

/// Provides the [GetPostUtmeProductsUseCase].
final _getPostUtmeProductsUseCaseProvider =
    Provider<GetPostUtmeProductsUseCase>((ref) {
  return GetPostUtmeProductsUseCase(ref.watch(_repositoryProvider));
});

/// Provides the [GetAdmissionChecklistUseCase].
final _getAdmissionChecklistUseCaseProvider =
    Provider<GetAdmissionChecklistUseCase>((ref) {
  return GetAdmissionChecklistUseCase(ref.watch(_repositoryProvider));
});

/// Provides the [UpdateAdmissionChecklistUseCase].
final _updateAdmissionChecklistUseCaseProvider =
    Provider<UpdateAdmissionChecklistUseCase>((ref) {
  return UpdateAdmissionChecklistUseCase(ref.watch(_repositoryProvider));
});

/// Provides the [CreateAdmissionApplicationUseCase].
final _createAdmissionApplicationUseCaseProvider =
    Provider<CreateAdmissionApplicationUseCase>((ref) {
  return CreateAdmissionApplicationUseCase(ref.watch(_repositoryProvider));
});

/// Provides the [CompareUniversitiesUseCase].
final _compareUniversitiesUseCaseProvider =
    Provider<CompareUniversitiesUseCase>((ref) {
  return CompareUniversitiesUseCase(ref.watch(_repositoryProvider));
});

/// Main provider for the Admission Hub feature.
final admissionHubProvider =
    StateNotifierProvider<AdmissionHubNotifier, AdmissionHubState>((ref) {
  return AdmissionHubNotifier(
    getUniversities: ref.watch(_getUniversitiesUseCaseProvider),
    searchUniversities: ref.watch(_searchUniversitiesUseCaseProvider),
    getUniversityDepartments:
        ref.watch(_getUniversityDepartmentsUseCaseProvider),
    checkAdmissionEligibility:
        ref.watch(_checkAdmissionEligibilityUseCaseProvider),
    getPostUtmeProducts: ref.watch(_getPostUtmeProductsUseCaseProvider),
    getAdmissionChecklist: ref.watch(_getAdmissionChecklistUseCaseProvider),
    updateAdmissionChecklist:
        ref.watch(_updateAdmissionChecklistUseCaseProvider),
    createAdmissionApplication:
        ref.watch(_createAdmissionApplicationUseCaseProvider),
    compareUniversities: ref.watch(_compareUniversitiesUseCaseProvider),
    userId: ref.watch(_userIdProvider),
  );
});
