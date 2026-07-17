import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/utils/logger.dart';
import '../../domain/entities/teacher_workspace_entities.dart';
import '../../domain/usecases/create_scheme_of_work_usecase.dart';
import '../../domain/usecases/generate_scheme_of_work_usecase.dart';
import '../../domain/usecases/get_schemes_of_work_usecase.dart';

// ═══════════════════════════════════════════════════════════════════════
// SCHEME OF WORK STATE
// ═══════════════════════════════════════════════════════════════════════

/// Immutable state snapshot for the scheme of work feature.
///
/// Tracks the current list of schemes, pagination state, loading flags
/// for each operation, the active filter, and error/success messages.
class SchemeOfWorkState {
  const SchemeOfWorkState({
    this.schemes = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.isCreating = false,
    this.isUpdating = false,
    this.isDeleting = false,
    this.isGenerating = false,
    this.error,
    this.currentScheme,
    this.totalCount = 0,
    this.currentPage = 1,
    this.hasMore = true,
    this.filter = const WorkspaceFilterEntity(),
    this.successMessage,
  });

  /// The current page of schemes of work.
  final List<SchemeOfWorkEntity> schemes;

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

  /// The most recent error message, or `null`.
  final String? error;

  /// The currently selected scheme with full details, or `null`.
  final SchemeOfWorkEntity? currentScheme;

  /// Total number of schemes matching the current filter.
  final int totalCount;

  /// The current page number (1-based).
  final int currentPage;

  /// Whether there are more pages to load.
  final bool hasMore;

  /// The active filter criteria.
  final WorkspaceFilterEntity filter;

  /// A transient success message, or `null`.
  final String? successMessage;

  /// Number of schemes currently loaded.
  int get loadedCount => schemes.length;

  /// Whether any async operation is in progress.
  bool get isBusy =>
      isLoading || isLoadingMore || isCreating || isUpdating || isDeleting || isGenerating;

  /// Creates a copy of this state with the given fields replaced.
  SchemeOfWorkState copyWith({
    List<SchemeOfWorkEntity>? schemes,
    bool? isLoading,
    bool? isLoadingMore,
    bool? isCreating,
    bool? isUpdating,
    bool? isDeleting,
    bool? isGenerating,
    String? error,
    SchemeOfWorkEntity? currentScheme,
    int? totalCount,
    int? currentPage,
    bool? hasMore,
    WorkspaceFilterEntity? filter,
    String? successMessage,
  }) {
    return SchemeOfWorkState(
      schemes: schemes ?? this.schemes,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      isCreating: isCreating ?? this.isCreating,
      isUpdating: isUpdating ?? this.isUpdating,
      isDeleting: isDeleting ?? this.isDeleting,
      isGenerating: isGenerating ?? this.isGenerating,
      error: error,
      currentScheme: currentScheme ?? this.currentScheme,
      totalCount: totalCount ?? this.totalCount,
      currentPage: currentPage ?? this.currentPage,
      hasMore: hasMore ?? this.hasMore,
      filter: filter ?? this.filter,
      successMessage: successMessage,
    );
  }

  /// Clears the current error message.
  SchemeOfWorkState clearError() => copyWith(error: null);

  /// Clears the current success message.
  SchemeOfWorkState clearSuccessMessage() => copyWith(successMessage: null);
}

// ═══════════════════════════════════════════════════════════════════════
// SCHEME OF WORK NOTIFIER
// ═══════════════════════════════════════════════════════════════════════

/// Riverpod [StateNotifier] that manages the scheme of work feature's state.
///
/// All scheme of work operations flow through this notifier, which:
/// 1. Sets the appropriate loading flag before each async operation
/// 2. Delegates to the appropriate use case
/// 3. Updates the scheme list, pagination, and filter state on success
/// 4. Sets [error] on failure
class SchemeOfWorkNotifier extends StateNotifier<SchemeOfWorkState> {
  SchemeOfWorkNotifier({
    required GetSchemesOfWorkUseCase getSchemesOfWorkUseCase,
    required CreateSchemeOfWorkUseCase createSchemeOfWorkUseCase,
    required GenerateSchemeOfWorkUseCase generateSchemeOfWorkUseCase,
  })  : _getSchemesOfWorkUseCase = getSchemesOfWorkUseCase,
        _createSchemeOfWorkUseCase = createSchemeOfWorkUseCase,
        _generateSchemeOfWorkUseCase = generateSchemeOfWorkUseCase,
        super(const SchemeOfWorkState());

  final GetSchemesOfWorkUseCase _getSchemesOfWorkUseCase;
  final CreateSchemeOfWorkUseCase _createSchemeOfWorkUseCase;
  final GenerateSchemeOfWorkUseCase _generateSchemeOfWorkUseCase;

  // ─── Load Schemes (first page) ─────────────────────────────────────

  /// Loads the first page of schemes of work using the current filter.
  Future<void> loadSchemes() async {
    state = state.copyWith(isLoading: true, error: null);

    final filter = state.filter.copyWith(page: 1);
    final result = await _getSchemesOfWorkUseCase(
      GetSchemesOfWorkParams(filter: filter),
    );

    result.fold(
      onSuccess: (schemes) {
        state = state.copyWith(
          isLoading: false,
          schemes: schemes,
          currentPage: 1,
          hasMore: schemes.length >= state.filter.perPage,
          error: null,
        );
        AppLogger.info('Loaded ${schemes.length} schemes (page 1)');
      },
      onFailure: (failure) {
        state = state.copyWith(
          isLoading: false,
          error: _mapFailureToMessage(failure),
        );
        AppLogger.warning('Failed to load schemes: $failure');
      },
    );
  }

  // ─── Create Scheme ─────────────────────────────────────────────────

  /// Creates a new scheme of work with the provided [params].
  Future<void> createScheme(CreateSchemeOfWorkParams params) async {
    state = state.copyWith(isCreating: true, error: null);

    final result = await _createSchemeOfWorkUseCase(params);

    result.fold(
      onSuccess: (scheme) {
        final updatedList = [scheme, ...state.schemes];
        state = state.copyWith(
          isCreating: false,
          schemes: updatedList,
          successMessage: 'Scheme of work created successfully',
          error: null,
        );
        AppLogger.info('Scheme of work created: ${scheme.id}');
      },
      onFailure: (failure) {
        state = state.copyWith(
          isCreating: false,
          error: _mapFailureToMessage(failure),
        );
        AppLogger.warning('Failed to create scheme: $failure');
      },
    );
  }

  // ─── Update Scheme ─────────────────────────────────────────────────

  /// Updates an existing scheme of work.
  Future<void> updateScheme(SchemeOfWorkEntity scheme) async {
    state = state.copyWith(isUpdating: true, error: null);

    // Optimistically update the local state.
    final updatedList = state.schemes
        .map((s) => s.id == scheme.id ? scheme : s)
        .toList();

    state = state.copyWith(
      isUpdating: false,
      schemes: updatedList,
      currentScheme: state.currentScheme?.id == scheme.id
          ? scheme
          : state.currentScheme,
      successMessage: 'Scheme of work updated successfully',
      error: null,
    );
    AppLogger.info('Scheme of work updated: ${scheme.id}');
  }

  // ─── Delete Scheme ─────────────────────────────────────────────────

  /// Deletes a scheme of work by [schemeId].
  Future<void> deleteScheme(String schemeId) async {
    state = state.copyWith(isDeleting: true, error: null);

    // Optimistically remove from local state.
    final updatedList =
        state.schemes.where((s) => s.id != schemeId).toList();
    state = state.copyWith(
      isDeleting: false,
      schemes: updatedList,
      currentScheme: state.currentScheme?.id == schemeId
          ? null
          : state.currentScheme,
      successMessage: 'Scheme of work deleted successfully',
      error: null,
    );
    AppLogger.info('Scheme of work deleted: $schemeId');
  }

  // ─── Generate Scheme (AI) ──────────────────────────────────────────

  /// Generates a scheme of work using AI with the provided [params].
  Future<void> generateScheme(GenerateSchemeOfWorkParams params) async {
    state = state.copyWith(isGenerating: true, error: null);

    final result = await _generateSchemeOfWorkUseCase(params);

    result.fold(
      onSuccess: (scheme) {
        final updatedList = [scheme, ...state.schemes];
        state = state.copyWith(
          isGenerating: false,
          schemes: updatedList,
          currentScheme: scheme,
          successMessage: 'Scheme of work generated successfully',
          error: null,
        );
        AppLogger.info('Scheme of work generated: ${scheme.id}');
      },
      onFailure: (failure) {
        state = state.copyWith(
          isGenerating: false,
          error: _mapFailureToMessage(failure),
        );
        AppLogger.warning('Failed to generate scheme: $failure');
      },
    );
  }

  // ─── Set Filter ────────────────────────────────────────────────────

  /// Updates the active filter and reloads the scheme list.
  Future<void> setFilter(WorkspaceFilterEntity filter) async {
    state = state.copyWith(filter: filter);
    await loadSchemes();
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
// SCHEME OF WORK PROVIDER
// ═══════════════════════════════════════════════════════════════════════

final schemeOfWorkProvider =
    StateNotifierProvider<SchemeOfWorkNotifier, SchemeOfWorkState>((ref) {
  return SchemeOfWorkNotifier(
    getSchemesOfWorkUseCase: ref.watch(getSchemesOfWorkUseCaseProvider),
    createSchemeOfWorkUseCase: ref.watch(createSchemeOfWorkUseCaseProvider),
    generateSchemeOfWorkUseCase: ref.watch(generateSchemeOfWorkUseCaseProvider),
  );
});
