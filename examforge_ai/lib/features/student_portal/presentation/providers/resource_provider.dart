import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/utils/logger.dart';
import '../../domain/entities/student_portal_entities.dart';
import '../../domain/usecases/student_portal_usecases.dart';
import 'student_dashboard_provider.dart';

// ═══════════════════════════════════════════════════════════════════════
// RESOURCE STATE
// ═══════════════════════════════════════════════════════════════════════

/// Immutable state snapshot for the Learning Resources feature.
///
/// Tracks the list of resources, the currently selected resource,
/// loading flags, pagination state, filters, and search query.
class ResourceState {
  const ResourceState({
    this.resources = const [],
    this.currentResource,
    this.isLoading = false,
    this.error,
    this.hasMore = true,
    this.filterType,
    this.filterSubjectId,
    this.searchQuery,
    this.currentPage = 1,
  });

  /// All learning resources matching the current filter.
  final List<LearningResourceEntity> resources;

  /// The currently selected resource, or `null`.
  final LearningResourceEntity? currentResource;

  /// Whether the initial resource list load is in progress.
  final bool isLoading;

  /// The most recent error message, or `null`.
  final String? error;

  /// Whether there are more resource pages to load.
  final bool hasMore;

  /// Optional filter on resource type.
  final StudentResourceType? filterType;

  /// Optional filter on subject ID.
  final String? filterSubjectId;

  /// Optional search query string.
  final String? searchQuery;

  /// Current page number for resource pagination (1-based).
  // ignore: unused_field
  final int currentPage;

  /// Current page number for resource pagination.

  /// Whether any async operation is in progress.
  bool get isBusy => isLoading;

  /// Number of resources currently loaded.
  int get resourceCount => resources.length;

  /// Whether any filter is active.
  bool get hasActiveFilter =>
      filterType != null ||
      filterSubjectId != null ||
      (searchQuery != null && searchQuery!.isNotEmpty);

  /// Creates a copy of this state with the given fields replaced.
  ResourceState copyWith({
    List<LearningResourceEntity>? resources,
    LearningResourceEntity? currentResource,
    bool? isLoading,
    String? error,
    bool? hasMore,
    StudentResourceType? filterType,
    String? filterSubjectId,
    String? searchQuery,
    int? currentPage,
    bool clearCurrentResource = false,
    bool clearFilterType = false,
    bool clearFilterSubjectId = false,
    bool clearSearchQuery = false,
  }) {
    return ResourceState(
      resources: resources ?? this.resources,
      currentResource: clearCurrentResource
          ? null
          : (currentResource ?? this.currentResource),
      isLoading: isLoading ?? this.isLoading,
      error: error,
      hasMore: hasMore ?? this.hasMore,
      filterType: clearFilterType ? null : (filterType ?? this.filterType),
      filterSubjectId: clearFilterSubjectId
          ? null
          : (filterSubjectId ?? this.filterSubjectId),
      searchQuery: clearSearchQuery ? null : (searchQuery ?? this.searchQuery),
      currentPage: currentPage ?? currentPage,
    );
  }

  /// Clears the current error message.
  ResourceState clearError() => copyWith(error: null);
}

// ═══════════════════════════════════════════════════════════════════════
// RESOURCE NOTIFIER
// ═══════════════════════════════════════════════════════════════════════

/// Riverpod [StateNotifier] that manages the Learning Resources feature's
/// state.
///
/// All resource operations flow through this notifier, which:
/// 1. Sets [isLoading] before each async operation
/// 2. Delegates to the appropriate use case
/// 3. Updates the resource list, pagination, and filters on success
/// 4. Sets [error] on failure
class ResourceNotifier extends StateNotifier<ResourceState> {
  ResourceNotifier({
    required GetStudentResourcesUseCase getResources,
    required GetResourceDetailUseCase getResourceDetail,
    required LogResourceAccessUseCase logResourceAccess,
    required String? studentId,
    required String? schoolId,
  })  : _getResources = getResources,
        _getResourceDetail = getResourceDetail,
        _logResourceAccess = logResourceAccess,
        _studentId = studentId,
        _schoolId = schoolId,
        super(const ResourceState());

  final GetStudentResourcesUseCase _getResources;
  final GetResourceDetailUseCase _getResourceDetail;
  final LogResourceAccessUseCase _logResourceAccess;
  final String? _studentId;
  final String? _schoolId;

  static const int _pageSize = 20;

  // ─── Load Resources (first page) ───────────────────────────────────

  /// Loads the first page of resources matching the current filters.
  Future<void> loadResources() async {
    if (_studentId == null) return;

    state = state.copyWith(isLoading: true, error: null);

    final result = await _getResources(
      studentId: _studentId!,
      schoolId: _schoolId,
      page: 1,
      pageSize: _pageSize,
      resourceType: state.filterType,
      subjectId: state.filterSubjectId,
      searchQuery: state.searchQuery,
    );

    result.fold(
      onSuccess: (resources) {
        state = state.copyWith(
          isLoading: false,
          resources: resources,
          currentPage: 1,
          hasMore: resources.length >= _pageSize,
          error: null,
        );
        AppLogger.info(
          'Loaded ${resources.length} resources (page 1)',
        );
      },
      onFailure: (failure) {
        state = state.copyWith(
          isLoading: false,
          error: _mapFailureToMessage(failure),
        );
        AppLogger.warning('Failed to load resources: $failure');
      },
    );
  }

  // ─── Load More Resources ───────────────────────────────────────────

  /// Loads the next page of resources and appends to the list.
  Future<void> loadMoreResources() async {
    if (_studentId == null || !state.hasMore) return;

    final nextPage = state.currentPage + 1;

    final result = await _getResources(
      studentId: _studentId!,
      schoolId: _schoolId,
      page: nextPage,
      pageSize: _pageSize,
      resourceType: state.filterType,
      subjectId: state.filterSubjectId,
      searchQuery: state.searchQuery,
    );

    result.fold(
      onSuccess: (newResources) {
        final allResources = [...state.resources, ...newResources];
        state = state.copyWith(
          resources: allResources,
          currentPage: nextPage,
          hasMore: newResources.length >= _pageSize,
        );
        AppLogger.info(
          'Loaded ${newResources.length} more resources (page $nextPage)',
        );
      },
      onFailure: (failure) {
        state = state.copyWith(
          error: _mapFailureToMessage(failure),
        );
        AppLogger.warning(
          'Failed to load more resources: $failure',
        );
      },
    );
  }

  // ─── Open Resource ─────────────────────────────────────────────────

  /// Opens a resource by ID, loading its full details.
  Future<void> openResource(String resourceId) async {
    state = state.copyWith(isLoading: true, error: null);

    final result = await _getResourceDetail(resourceId: resourceId);

    result.fold(
      onSuccess: (resource) {
        state = state.copyWith(
          isLoading: false,
          currentResource: resource,
          error: null,
        );
        AppLogger.info('Opened resource: $resourceId');
      },
      onFailure: (failure) {
        state = state.copyWith(
          isLoading: false,
          error: _mapFailureToMessage(failure),
        );
        AppLogger.warning('Failed to open resource: $failure');
      },
    );
  }

  // ─── Filter by Type ────────────────────────────────────────────────

  /// Filters resources by [type] and reloads the list.
  /// Pass `null` to clear the type filter.
  Future<void> filterByType(StudentResourceType? type) async {
    state = type == null
        ? state.copyWith(clearFilterType: true)
        : state.copyWith(filterType: type);
    await loadResources();
  }

  // ─── Filter by Subject ─────────────────────────────────────────────

  /// Filters resources by [subjectId] and reloads the list.
  /// Pass `null` to clear the subject filter.
  Future<void> filterBySubject(String? subjectId) async {
    state = subjectId == null
        ? state.copyWith(clearFilterSubjectId: true)
        : state.copyWith(filterSubjectId: subjectId);
    await loadResources();
  }

  // ─── Search ────────────────────────────────────────────────────────

  /// Searches resources by [query] and reloads the list.
  /// Pass `null` or empty string to clear the search.
  Future<void> search(String? query) async {
    state = (query == null || query.isEmpty)
        ? state.copyWith(clearSearchQuery: true)
        : state.copyWith(searchQuery: query);
    await loadResources();
  }

  // ─── Log Access ────────────────────────────────────────────────────

  /// Logs an access event (view/download) for a resource.
  Future<void> logAccess(String resourceId, {String accessType = 'view'}) async {
    if (_studentId == null) return;

    final result = await _logResourceAccess(
      resourceId: resourceId,
      studentId: _studentId!,
      accessType: accessType,
    );

    result.fold(
      onSuccess: (_) {
        AppLogger.info(
          'Logged $accessType access for resource: $resourceId',
        );
      },
      onFailure: (failure) {
        // Access logging is non-critical; just log the failure.
        AppLogger.warning(
          'Failed to log resource access: $failure',
        );
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
// RESOURCE PROVIDER
// ═══════════════════════════════════════════════════════════════════════

/// Provides the current student's school ID from auth state.
final studentSchoolIdProvider = Provider<String?>((ref) {
  return ref.watch(userSchoolIdProvider);
});

/// Provides the [ResourceNotifier] with all required use cases.
final resourceProvider =
    StateNotifierProvider<ResourceNotifier, ResourceState>((ref) {
  return ResourceNotifier(
    getResources: ref.watch(studentGetResourcesUseCaseProvider),
    getResourceDetail: ref.watch(getResourceDetailUseCaseProvider),
    logResourceAccess: ref.watch(logResourceAccessUseCaseProvider),
    studentId: ref.watch(currentStudentIdProvider),
    schoolId: ref.watch(studentSchoolIdProvider),
  );
});
