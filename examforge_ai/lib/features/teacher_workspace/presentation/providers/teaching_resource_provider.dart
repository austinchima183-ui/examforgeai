import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../config/dependency_injection.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/utils/logger.dart';
import '../../domain/entities/teacher_workspace_entities.dart';
import '../../domain/usecases/create_resource_usecase.dart';
import '../../domain/usecases/generate_resource_usecase.dart';
import '../../domain/usecases/get_resources_usecase.dart';
import '../../domain/usecases/toggle_favorite_usecase.dart';

// ═══════════════════════════════════════════════════════════════════════
// TEACHING RESOURCE STATE
// ═══════════════════════════════════════════════════════════════════════

/// Immutable state snapshot for the teaching resource feature.
///
/// Tracks the current list of resources, pagination state, loading flags
/// for each operation, the active filter, the current folder, and
/// error/success messages.
class TeachingResourceState {
  const TeachingResourceState({
    this.resources = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.isCreating = false,
    this.isUpdating = false,
    this.isDeleting = false,
    this.isGenerating = false,
    this.isTogglingFavorite = false,
    this.error,
    this.currentResource,
    this.totalCount = 0,
    this.currentPage = 1,
    this.hasMore = true,
    this.filter = const WorkspaceFilterEntity(),
    this.successMessage,
    this.currentFolderId,
  });

  /// The current page of teaching resources.
  final List<TeachingResourceEntity> resources;

  /// Whether the initial page load is in progress.
  final bool isLoading;

  /// Whether a pagination (load-more) request is in progress.
  final bool isLoadingMore;

  /// Whether a create operation is in progress.
  final bool isCreating;

  /// Whether an update operation is in progress.
  final bool isUpdating;

  /// Whether a delete operation is in progress.
  final bool isDeleting;

  /// Whether an AI generation operation is in progress.
  final bool isGenerating;

  /// Whether a toggle-favorite operation is in progress.
  final bool isTogglingFavorite;

  /// The most recent error message, or `null`.
  final String? error;

  /// The currently selected resource with full details, or `null`.
  final TeachingResourceEntity? currentResource;

  /// Total number of resources matching the current filter.
  final int totalCount;

  /// The current page number (1-based).
  final int currentPage;

  /// Whether there are more pages to load.
  final bool hasMore;

  /// The active filter criteria.
  final WorkspaceFilterEntity filter;

  /// A transient success message, or `null`.
  final String? successMessage;

  /// The ID of the currently selected folder, or `null` for root.
  final String? currentFolderId;

  /// Number of resources currently loaded.
  int get loadedCount => resources.length;

  /// Whether any async operation is in progress.
  bool get isBusy =>
      isLoading ||
      isLoadingMore ||
      isCreating ||
      isUpdating ||
      isDeleting ||
      isGenerating ||
      isTogglingFavorite;

  /// Creates a copy of this state with the given fields replaced.
  TeachingResourceState copyWith({
    List<TeachingResourceEntity>? resources,
    bool? isLoading,
    bool? isLoadingMore,
    bool? isCreating,
    bool? isUpdating,
    bool? isDeleting,
    bool? isGenerating,
    bool? isTogglingFavorite,
    String? error,
    TeachingResourceEntity? currentResource,
    int? totalCount,
    int? currentPage,
    bool? hasMore,
    WorkspaceFilterEntity? filter,
    String? successMessage,
    String? currentFolderId,
  }) {
    return TeachingResourceState(
      resources: resources ?? this.resources,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      isCreating: isCreating ?? this.isCreating,
      isUpdating: isUpdating ?? this.isUpdating,
      isDeleting: isDeleting ?? this.isDeleting,
      isGenerating: isGenerating ?? this.isGenerating,
      isTogglingFavorite: isTogglingFavorite ?? this.isTogglingFavorite,
      error: error,
      currentResource: currentResource ?? this.currentResource,
      totalCount: totalCount ?? this.totalCount,
      currentPage: currentPage ?? this.currentPage,
      hasMore: hasMore ?? this.hasMore,
      filter: filter ?? this.filter,
      successMessage: successMessage,
      currentFolderId: currentFolderId ?? this.currentFolderId,
    );
  }

  /// Clears the current error message.
  TeachingResourceState clearError() => copyWith(error: null);

  /// Clears the current success message.
  TeachingResourceState clearSuccessMessage() => copyWith(successMessage: null);
}

// ═══════════════════════════════════════════════════════════════════════
// TEACHING RESOURCE NOTIFIER
// ═══════════════════════════════════════════════════════════════════════

/// Riverpod [StateNotifier] that manages the teaching resource feature's state.
///
/// All teaching resource operations flow through this notifier, which:
/// 1. Sets the appropriate loading flag before each async operation
/// 2. Delegates to the appropriate use case
/// 3. Updates the resource list, pagination, and filter state on success
/// 4. Sets [error] on failure
class TeachingResourceNotifier extends StateNotifier<TeachingResourceState> {
  TeachingResourceNotifier({
    required GetResourcesUseCase getResourcesUseCase,
    required CreateResourceUseCase createResourceUseCase,
    required GenerateResourceUseCase generateResourceUseCase,
    required ToggleFavoriteUseCase toggleFavoriteUseCase,
  })  : _getResourcesUseCase = getResourcesUseCase,
        _createResourceUseCase = createResourceUseCase,
        _generateResourceUseCase = generateResourceUseCase,
        _toggleFavoriteUseCase = toggleFavoriteUseCase,
        super(const TeachingResourceState());

  final GetResourcesUseCase _getResourcesUseCase;
  final CreateResourceUseCase _createResourceUseCase;
  final GenerateResourceUseCase _generateResourceUseCase;
  final ToggleFavoriteUseCase _toggleFavoriteUseCase;

  // ─── Load Resources (first page) ───────────────────────────────────

  /// Loads the first page of teaching resources using the current filter.
  Future<void> loadResources() async {
    state = state.copyWith(isLoading: true, error: null);

    final filter = state.filter.copyWith(page: 1);
    final result = await _getResourcesUseCase(
      GetResourcesParams(filter: filter),
    );

    result.fold(
      onSuccess: (resources) {
        state = state.copyWith(
          isLoading: false,
          resources: resources,
          currentPage: 1,
          hasMore: resources.length >= state.filter.perPage,
          error: null,
        );
        AppLogger.info('Loaded ${resources.length} resources (page 1)');
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

  // ─── Create Resource ───────────────────────────────────────────────

  /// Creates a new teaching resource with the provided [params].
  Future<void> createResource(CreateResourceParams params) async {
    state = state.copyWith(isCreating: true, error: null);

    final result = await _createResourceUseCase(params);

    result.fold(
      onSuccess: (resource) {
        final updatedList = [resource, ...state.resources];
        state = state.copyWith(
          isCreating: false,
          resources: updatedList,
          successMessage: 'Resource created successfully',
          error: null,
        );
        AppLogger.info('Resource created: ${resource.id}');
      },
      onFailure: (failure) {
        state = state.copyWith(
          isCreating: false,
          error: _mapFailureToMessage(failure),
        );
        AppLogger.warning('Failed to create resource: $failure');
      },
    );
  }

  // ─── Update Resource ───────────────────────────────────────────────

  /// Updates an existing teaching resource.
  Future<void> updateResource(TeachingResourceEntity resource) async {
    state = state.copyWith(isUpdating: true, error: null);

    // Optimistically update the local state.
    final updatedList = state.resources
        .map((r) => r.id == resource.id ? resource : r)
        .toList();

    state = state.copyWith(
      isUpdating: false,
      resources: updatedList,
      currentResource: state.currentResource?.id == resource.id
          ? resource
          : state.currentResource,
      successMessage: 'Resource updated successfully',
      error: null,
    );
    AppLogger.info('Resource updated: ${resource.id}');
  }

  // ─── Delete Resource ───────────────────────────────────────────────

  /// Deletes a teaching resource by [resourceId].
  Future<void> deleteResource(String resourceId) async {
    state = state.copyWith(isDeleting: true, error: null);

    // Optimistically remove from local state.
    final updatedList =
        state.resources.where((r) => r.id != resourceId).toList();
    state = state.copyWith(
      isDeleting: false,
      resources: updatedList,
      currentResource: state.currentResource?.id == resourceId
          ? null
          : state.currentResource,
      successMessage: 'Resource deleted successfully',
      error: null,
    );
    AppLogger.info('Resource deleted: $resourceId');
  }

  // ─── Generate Resource (AI) ────────────────────────────────────────

  /// Generates a teaching resource using AI with the provided [params].
  Future<void> generateResource(GenerateResourceParams params) async {
    state = state.copyWith(isGenerating: true, error: null);

    final result = await _generateResourceUseCase(params);

    result.fold(
      onSuccess: (resource) {
        final updatedList = [resource, ...state.resources];
        state = state.copyWith(
          isGenerating: false,
          resources: updatedList,
          currentResource: resource,
          successMessage: 'Resource generated successfully',
          error: null,
        );
        AppLogger.info('Resource generated: ${resource.id}');
      },
      onFailure: (failure) {
        state = state.copyWith(
          isGenerating: false,
          error: _mapFailureToMessage(failure),
        );
        AppLogger.warning('Failed to generate resource: $failure');
      },
    );
  }

  // ─── Toggle Favorite ───────────────────────────────────────────────

  /// Toggles the favorite status of a teaching resource.
  Future<void> toggleFavorite(String resourceId) async {
    state = state.copyWith(isTogglingFavorite: true, error: null);

    final result = await _toggleFavoriteUseCase(
      ToggleFavoriteParams(resourceId: resourceId),
    );

    result.fold(
      onSuccess: (_) {
        final updatedList = state.resources.map((r) {
          if (r.id == resourceId) {
            return r.copyWith(isFavorite: !r.isFavorite);
          }
          return r;
        }).toList();
        state = state.copyWith(
          isTogglingFavorite: false,
          resources: updatedList,
          currentResource: state.currentResource?.id == resourceId
              ? state.currentResource!.copyWith(
                  isFavorite: !state.currentResource!.isFavorite,
                )
              : state.currentResource,
          error: null,
        );
        AppLogger.info('Toggled favorite for resource: $resourceId');
      },
      onFailure: (failure) {
        state = state.copyWith(
          isTogglingFavorite: false,
          error: _mapFailureToMessage(failure),
        );
        AppLogger.warning('Failed to toggle favorite: $failure');
      },
    );
  }

  // ─── Set Filter ────────────────────────────────────────────────────

  /// Updates the active filter and reloads the resource list.
  Future<void> setFilter(WorkspaceFilterEntity filter) async {
    state = state.copyWith(filter: filter);
    await loadResources();
  }

  // ─── Set Current Folder ────────────────────────────────────────────

  /// Sets the current folder for filtering resources.
  void setCurrentFolder(String? folderId) {
    state = state.copyWith(currentFolderId: folderId);
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
// TEACHING RESOURCE PROVIDER
// ═══════════════════════════════════════════════════════════════════════

final teachingResourceProvider =
    StateNotifierProvider<TeachingResourceNotifier, TeachingResourceState>(
  (ref) {
    return TeachingResourceNotifier(
      getResourcesUseCase: ref.watch(getResourcesUseCaseProvider),
      createResourceUseCase: ref.watch(createResourceUseCaseProvider),
      generateResourceUseCase: ref.watch(generateResourceUseCaseProvider),
      toggleFavoriteUseCase: ref.watch(toggleFavoriteUseCaseProvider),
    );
  },
);
