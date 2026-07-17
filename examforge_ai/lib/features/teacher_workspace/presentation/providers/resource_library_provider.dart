import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/utils/logger.dart';
import '../../domain/entities/teacher_workspace_entities.dart';
import '../../domain/usecases/get_resources_usecase.dart';
import '../../domain/usecases/toggle_favorite_usecase.dart';

// ═══════════════════════════════════════════════════════════════════════
// RESOURCE LIBRARY STATE
// ═══════════════════════════════════════════════════════════════════════

/// Immutable state snapshot for the resource library feature.
///
/// Tracks folders, the selected folder, search query, all resources,
/// and loading flags for each operation.
class ResourceLibraryState {
  const ResourceLibraryState({
    this.folders = const [],
    this.selectedFolderId,
    this.searchQuery,
    this.allResources = const [],
    this.isLoading = false,
    this.isSearching = false,
    this.isCreatingFolder = false,
    this.isDeletingFolder = false,
    this.isTogglingFavorite = false,
    this.error,
    this.successMessage,
  });

  /// The list of resource folders.
  final List<ResourceFolderEntity> folders;

  /// The ID of the currently selected folder, or `null` for root.
  final String? selectedFolderId;

  /// The current search query, or `null`.
  final String? searchQuery;

  /// All resources in the library (possibly filtered by folder/search).
  final List<TeachingResourceEntity> allResources;

  /// Whether a library load operation is in progress.
  final bool isLoading;

  /// Whether a search operation is in progress.
  final bool isSearching;

  /// Whether a folder creation operation is in progress.
  final bool isCreatingFolder;

  /// Whether a folder deletion operation is in progress.
  final bool isDeletingFolder;

  /// Whether a toggle-favorite operation is in progress.
  final bool isTogglingFavorite;

  /// The most recent error message, or `null`.
  final String? error;

  /// A transient success message, or `null`.
  final String? successMessage;

  /// Whether any async operation is in progress.
  bool get isBusy =>
      isLoading ||
      isSearching ||
      isCreatingFolder ||
      isDeletingFolder ||
      isTogglingFavorite;

  /// Resources filtered by the currently selected folder.
  List<TeachingResourceEntity> get filteredResources {
    if (selectedFolderId == null) return allResources;
    return allResources
        .where((r) => r.folderId == selectedFolderId)
        .toList();
  }

  /// Resources matching the current search query.
  List<TeachingResourceEntity> get searchResults {
    if (searchQuery == null || searchQuery!.trim().isEmpty) {
      return filteredResources;
    }
    final query = searchQuery!.toLowerCase();
    return filteredResources
        .where((r) =>
            r.title.toLowerCase().contains(query) ||
            (r.subject?.toLowerCase().contains(query) ?? false) ||
            (r.description?.toLowerCase().contains(query) ?? false))
        .toList();
  }

  /// Creates a copy of this state with the given fields replaced.
  ResourceLibraryState copyWith({
    List<ResourceFolderEntity>? folders,
    String? selectedFolderId,
    String? searchQuery,
    List<TeachingResourceEntity>? allResources,
    bool? isLoading,
    bool? isSearching,
    bool? isCreatingFolder,
    bool? isDeletingFolder,
    bool? isTogglingFavorite,
    String? error,
    String? successMessage,
  }) {
    return ResourceLibraryState(
      folders: folders ?? this.folders,
      selectedFolderId: selectedFolderId ?? this.selectedFolderId,
      searchQuery: searchQuery ?? this.searchQuery,
      allResources: allResources ?? this.allResources,
      isLoading: isLoading ?? this.isLoading,
      isSearching: isSearching ?? this.isSearching,
      isCreatingFolder: isCreatingFolder ?? this.isCreatingFolder,
      isDeletingFolder: isDeletingFolder ?? this.isDeletingFolder,
      isTogglingFavorite: isTogglingFavorite ?? this.isTogglingFavorite,
      error: error,
      successMessage: successMessage,
    );
  }

  /// Clears the current error message.
  ResourceLibraryState clearError() => copyWith(error: null);

  /// Clears the current success message.
  ResourceLibraryState clearSuccessMessage() => copyWith(successMessage: null);
}

// ═══════════════════════════════════════════════════════════════════════
// RESOURCE LIBRARY NOTIFIER
// ═══════════════════════════════════════════════════════════════════════

/// Riverpod [StateNotifier] that manages the resource library state.
///
/// All resource library operations flow through this notifier, which:
/// 1. Sets the appropriate loading flag before each async operation
/// 2. Delegates to the appropriate use case
/// 3. Updates folders, resources, and search state on success
/// 4. Sets [error] on failure
class ResourceLibraryNotifier extends StateNotifier<ResourceLibraryState> {
  ResourceLibraryNotifier({
    required GetResourcesUseCase getResourcesUseCase,
    required ToggleFavoriteUseCase toggleFavoriteUseCase,
  })  : _getResourcesUseCase = getResourcesUseCase,
        _toggleFavoriteUseCase = toggleFavoriteUseCase,
        super(const ResourceLibraryState());

  final GetResourcesUseCase _getResourcesUseCase;
  final ToggleFavoriteUseCase _toggleFavoriteUseCase;

  // ─── Load Library ──────────────────────────────────────────────────

  /// Loads the full resource library including folders and resources.
  Future<void> loadLibrary() async {
    state = state.copyWith(isLoading: true, error: null);

    final result = await _getResourcesUseCase(
      const GetResourcesParams(
        filter: WorkspaceFilterEntity(),
      ),
    );

    result.fold(
      onSuccess: (resources) {
        state = state.copyWith(
          isLoading: false,
          allResources: resources,
          error: null,
        );
        AppLogger.info('Loaded ${resources.length} resources for library');
      },
      onFailure: (failure) {
        state = state.copyWith(
          isLoading: false,
          error: _mapFailureToMessage(failure),
        );
        AppLogger.warning('Failed to load library: $failure');
      },
    );
  }

  // ─── Search Library ────────────────────────────────────────────────

  /// Searches the resource library with the given [query].
  void searchLibrary(String query) {
    state = state.copyWith(searchQuery: query);
  }

  // ─── Select Folder ─────────────────────────────────────────────────

  /// Selects a folder for filtering resources.
  void selectFolder(String? folderId) {
    state = state.copyWith(selectedFolderId: folderId);
  }

  // ─── Create Folder ─────────────────────────────────────────────────

  /// Creates a new resource folder.
  Future<void> createFolder(ResourceFolderEntity folder) async {
    state = state.copyWith(isCreatingFolder: true, error: null);

    // Optimistically add the folder to local state.
    final updatedFolders = [...state.folders, folder];
    state = state.copyWith(
      isCreatingFolder: false,
      folders: updatedFolders,
      successMessage: 'Folder created successfully',
      error: null,
    );
    AppLogger.info('Folder created: ${folder.id}');
  }

  // ─── Delete Folder ─────────────────────────────────────────────────

  /// Deletes a resource folder by [folderId].
  Future<void> deleteFolder(String folderId) async {
    state = state.copyWith(isDeletingFolder: true, error: null);

    // Optimistically remove the folder from local state.
    final updatedFolders =
        state.folders.where((f) => f.id != folderId).toList();
    state = state.copyWith(
      isDeletingFolder: false,
      folders: updatedFolders,
      selectedFolderId:
          state.selectedFolderId == folderId ? null : state.selectedFolderId,
      successMessage: 'Folder deleted successfully',
      error: null,
    );
    AppLogger.info('Folder deleted: $folderId');
  }

  // ─── Toggle Favorite ───────────────────────────────────────────────

  /// Toggles the favorite status of a resource.
  Future<void> toggleFavorite(String resourceId) async {
    state = state.copyWith(isTogglingFavorite: true, error: null);

    final result = await _toggleFavoriteUseCase(
      ToggleFavoriteParams(resourceId: resourceId),
    );

    result.fold(
      onSuccess: (_) {
        final updatedResources = state.allResources.map((r) {
          if (r.id == resourceId) {
            return r.copyWith(isFavorite: !r.isFavorite);
          }
          return r;
        }).toList();
        state = state.copyWith(
          isTogglingFavorite: false,
          allResources: updatedResources,
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
// RESOURCE LIBRARY PROVIDER
// ═══════════════════════════════════════════════════════════════════════

final resourceLibraryProvider =
    StateNotifierProvider<ResourceLibraryNotifier, ResourceLibraryState>(
  (ref) {
    return ResourceLibraryNotifier(
      getResourcesUseCase: ref.watch(getResourcesUseCaseProvider),
      toggleFavoriteUseCase: ref.watch(toggleFavoriteUseCaseProvider),
    );
  },
);
