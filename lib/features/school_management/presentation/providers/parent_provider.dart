import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../config/dependency_injection.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/utils/logger.dart';
import '../../domain/entities/school_management_entities.dart';
import '../../domain/repositories/school_management_repository.dart';


// ═══════════════════════════════════════════════════════════════════════
// PARENT LIST STATE
// ═══════════════════════════════════════════════════════════════════════

/// Immutable state snapshot for the parent listing feature.
class ParentListState {
  const ParentListState({
    this.parents = const [],
    this.isLoading = false,
    this.error,
    this.searchQuery,
    this.currentPage = 1,
    this.hasMore = true,
  });

  /// The current page of parents.
  final List<ParentProfileEntity> parents;

  /// Whether the initial page load is in progress.
  final bool isLoading;

  /// The most recent error message, or `null`.
  final String? error;

  /// Active search query for filtering parents.
  final String? searchQuery;

  /// The current page number (1-based).
  final int currentPage;

  /// Whether there are more pages to load.
  final bool hasMore;

  /// Number of parents currently loaded.
  int get loadedCount => parents.length;

  /// Whether any async operation is in progress.
  bool get isBusy => isLoading;

  /// Creates a copy of this state with the given fields replaced.
  ParentListState copyWith({
    List<ParentProfileEntity>? parents,
    bool? isLoading,
    String? error,
    String? searchQuery,
    int? currentPage,
    bool? hasMore,
  }) {
    return ParentListState(
      parents: parents ?? this.parents,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      searchQuery: searchQuery ?? this.searchQuery,
      currentPage: currentPage ?? this.currentPage,
      hasMore: hasMore ?? this.hasMore,
    );
  }

  /// Clears the current error message.
  ParentListState clearError() => copyWith(error: null);
}

// ═══════════════════════════════════════════════════════════════════════
// PARENT LIST NOTIFIER
// ═══════════════════════════════════════════════════════════════════════

/// Riverpod [StateNotifier] that manages the parent list feature's state.
class ParentListNotifier extends StateNotifier<ParentListState> {
  ParentListNotifier({
    required SchoolManagementRepository schoolManagementRepository,
  })  : _repository = schoolManagementRepository,
        super(const ParentListState());

  final SchoolManagementRepository _repository;

  static const int _perPage = 20;

  String? _currentSchoolId;

  /// Sets the school context for subsequent operations.
  void setSchoolId(String schoolId) {
    _currentSchoolId = schoolId;
  }

  // ─── Load Parents ──────────────────────────────────────────────────

  /// Loads the first page of parents for the current school.
  Future<void> loadParents(String schoolId) async {
    _currentSchoolId = schoolId;
    state = state.copyWith(isLoading: true, error: null);

    final result = await _repository.getParentProfiles(
      schoolId: schoolId,
      searchQuery: state.searchQuery,
      page: 1,
      perPage: _perPage,
    );

    result.fold(
      onSuccess: (parents) {
        state = state.copyWith(
          isLoading: false,
          parents: parents,
          currentPage: 1,
          hasMore: parents.length >= _perPage,
          error: null,
        );
        AppLogger.info('Loaded ${parents.length} parents (page 1)');
      },
      onFailure: (failure) {
        state = state.copyWith(
          isLoading: false,
          error: _mapFailureToMessage(failure),
        );
        AppLogger.warning('Failed to load parents: $failure');
      },
    );
  }

  // ─── Search Parents ────────────────────────────────────────────────

  /// Searches parents by query and reloads the list.
  Future<void> searchParents(String query) async {
    if (_currentSchoolId == null) return;
    state = state.copyWith(searchQuery: query, isLoading: true, error: null);

    final result = await _repository.getParentProfiles(
      schoolId: _currentSchoolId!,
      searchQuery: query,
      page: 1,
      perPage: _perPage,
    );

    result.fold(
      onSuccess: (parents) {
        state = state.copyWith(
          isLoading: false,
          parents: parents,
          currentPage: 1,
          hasMore: parents.length >= _perPage,
          error: null,
        );
        AppLogger.info('Search "$query" returned ${parents.length} parents');
      },
      onFailure: (failure) {
        state = state.copyWith(
          isLoading: false,
          error: _mapFailureToMessage(failure),
        );
        AppLogger.warning('Failed to search parents: $failure');
      },
    );
  }

  // ─── Create Parent ─────────────────────────────────────────────────

  /// Creates a new parent profile.
  Future<void> createParent(ParentProfileEntity profile) async {
    final result = await _repository.createParentProfile(profile);

    result.fold(
      onSuccess: (createdProfile) {
        final updatedList = [createdProfile, ...state.parents];
        state = state.copyWith(parents: updatedList, error: null);
        AppLogger.info('Parent created: ${createdProfile.id}');
      },
      onFailure: (failure) {
        state = state.copyWith(
          error: _mapFailureToMessage(failure),
        );
        AppLogger.warning('Failed to create parent: $failure');
      },
    );
  }

  // ─── Update Parent ─────────────────────────────────────────────────

  /// Updates an existing parent profile.
  Future<void> updateParent(ParentProfileEntity profile) async {
    final result = await _repository.updateParentProfile(profile);

    result.fold(
      onSuccess: (updatedProfile) {
        final updatedList = state.parents
            .map((p) => p.id == updatedProfile.id ? updatedProfile : p)
            .toList();
        state = state.copyWith(parents: updatedList, error: null);
        AppLogger.info('Parent updated: ${updatedProfile.id}');
      },
      onFailure: (failure) {
        state = state.copyWith(
          error: _mapFailureToMessage(failure),
        );
        AppLogger.warning('Failed to update parent: $failure');
      },
    );
  }

  // ─── Load More ─────────────────────────────────────────────────────

  /// Loads the next page of parents and appends to the existing list.
  Future<void> loadMore() async {
    if (state.isLoading || !state.hasMore || _currentSchoolId == null) return;

    final nextPage = state.currentPage + 1;

    final result = await _repository.getParentProfiles(
      schoolId: _currentSchoolId!,
      searchQuery: state.searchQuery,
      page: nextPage,
      perPage: _perPage,
    );

    result.fold(
      onSuccess: (parents) {
        final updatedList = [...state.parents, ...parents];
        state = state.copyWith(
          parents: updatedList,
          currentPage: nextPage,
          hasMore: parents.length >= _perPage,
          error: null,
        );
        AppLogger.info(
          'Loaded ${parents.length} more parents (page $nextPage)',
        );
      },
      onFailure: (failure) {
        state = state.copyWith(
          error: _mapFailureToMessage(failure),
        );
        AppLogger.warning('Failed to load more parents: $failure');
      },
    );
  }

  // ─── Refresh ───────────────────────────────────────────────────────

  /// Refreshes the parent list.
  Future<void> refresh() async {
    if (_currentSchoolId == null) return;
    await loadParents(_currentSchoolId!);
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

/// Provides the [ParentListNotifier] and its [ParentListState].
final parentListProvider =
    StateNotifierProvider<ParentListNotifier, ParentListState>((ref) {
  return ParentListNotifier(
    schoolManagementRepository: ref.watch(schoolManagementRepositoryProvider),
  );
});
