import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../config/dependency_injection.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/utils/logger.dart';
import '../../domain/entities/teacher_workspace_entities.dart';
import '../../domain/usecases/create_worksheet_usecase.dart';
import '../../domain/usecases/export_worksheet_usecase.dart';
import '../../domain/usecases/generate_worksheet_usecase.dart';
import '../../domain/usecases/get_worksheets_usecase.dart';

// ═══════════════════════════════════════════════════════════════════════
// WORKSHEET STATE
// ═══════════════════════════════════════════════════════════════════════

/// Immutable state snapshot for the worksheet feature.
///
/// Tracks the current list of worksheets, pagination state, loading flags
/// for each operation, the active filter, and error/success messages.
class WorksheetState {
  const WorksheetState({
    this.worksheets = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.isCreating = false,
    this.isUpdating = false,
    this.isDeleting = false,
    this.isGenerating = false,
    this.isExporting = false,
    this.error,
    this.currentWorksheet,
    this.totalCount = 0,
    this.currentPage = 1,
    this.hasMore = true,
    this.filter = const WorkspaceFilterEntity(),
    this.successMessage,
    this.exportUrl,
  });

  /// The current page of worksheets.
  final List<WorksheetEntity> worksheets;

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

  /// Whether an export operation is in progress.
  final bool isExporting;

  /// The most recent error message, or `null`.
  final String? error;

  /// The currently selected worksheet with full details, or `null`.
  final WorksheetEntity? currentWorksheet;

  /// Total number of worksheets matching the current filter.
  final int totalCount;

  /// The current page number (1-based).
  final int currentPage;

  /// Whether there are more pages to load.
  final bool hasMore;

  /// The active filter criteria.
  final WorkspaceFilterEntity filter;

  /// A transient success message, or `null`.
  final String? successMessage;

  /// The download URL of the most recently exported worksheet, or `null`.
  final String? exportUrl;

  /// Number of worksheets currently loaded.
  int get loadedCount => worksheets.length;

  /// Whether any async operation is in progress.
  bool get isBusy =>
      isLoading ||
      isLoadingMore ||
      isCreating ||
      isUpdating ||
      isDeleting ||
      isGenerating ||
      isExporting;

  /// Creates a copy of this state with the given fields replaced.
  WorksheetState copyWith({
    List<WorksheetEntity>? worksheets,
    bool? isLoading,
    bool? isLoadingMore,
    bool? isCreating,
    bool? isUpdating,
    bool? isDeleting,
    bool? isGenerating,
    bool? isExporting,
    String? error,
    WorksheetEntity? currentWorksheet,
    int? totalCount,
    int? currentPage,
    bool? hasMore,
    WorkspaceFilterEntity? filter,
    String? successMessage,
    String? exportUrl,
  }) {
    return WorksheetState(
      worksheets: worksheets ?? this.worksheets,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      isCreating: isCreating ?? this.isCreating,
      isUpdating: isUpdating ?? this.isUpdating,
      isDeleting: isDeleting ?? this.isDeleting,
      isGenerating: isGenerating ?? this.isGenerating,
      isExporting: isExporting ?? this.isExporting,
      error: error,
      currentWorksheet: currentWorksheet ?? this.currentWorksheet,
      totalCount: totalCount ?? this.totalCount,
      currentPage: currentPage ?? this.currentPage,
      hasMore: hasMore ?? this.hasMore,
      filter: filter ?? this.filter,
      successMessage: successMessage,
      exportUrl: exportUrl,
    );
  }

  /// Clears the current error message.
  WorksheetState clearError() => copyWith(error: null);

  /// Clears the current success message.
  WorksheetState clearSuccessMessage() => copyWith(successMessage: null);
}

// ═══════════════════════════════════════════════════════════════════════
// WORKSHEET NOTIFIER
// ═══════════════════════════════════════════════════════════════════════

/// Riverpod [StateNotifier] that manages the worksheet feature's state.
///
/// All worksheet operations flow through this notifier, which:
/// 1. Sets the appropriate loading flag before each async operation
/// 2. Delegates to the appropriate use case
/// 3. Updates the worksheet list, pagination, and filter state on success
/// 4. Sets [error] on failure
class WorksheetNotifier extends StateNotifier<WorksheetState> {
  WorksheetNotifier({
    required GetWorksheetsUseCase getWorksheetsUseCase,
    required CreateWorksheetUseCase createWorksheetUseCase,
    required GenerateWorksheetUseCase generateWorksheetUseCase,
    required ExportWorksheetUseCase exportWorksheetUseCase,
  })  : _getWorksheetsUseCase = getWorksheetsUseCase,
        _createWorksheetUseCase = createWorksheetUseCase,
        _generateWorksheetUseCase = generateWorksheetUseCase,
        _exportWorksheetUseCase = exportWorksheetUseCase,
        super(const WorksheetState());

  final GetWorksheetsUseCase _getWorksheetsUseCase;
  final CreateWorksheetUseCase _createWorksheetUseCase;
  final GenerateWorksheetUseCase _generateWorksheetUseCase;
  final ExportWorksheetUseCase _exportWorksheetUseCase;

  // ─── Load Worksheets (first page) ──────────────────────────────────

  /// Loads the first page of worksheets using the current filter.
  Future<void> loadWorksheets() async {
    state = state.copyWith(isLoading: true, error: null);

    final filter = state.filter.copyWith(page: 1);
    final result = await _getWorksheetsUseCase(
      GetWorksheetsParams(filter: filter),
    );

    result.fold(
      onSuccess: (worksheets) {
        state = state.copyWith(
          isLoading: false,
          worksheets: worksheets,
          currentPage: 1,
          hasMore: worksheets.length >= state.filter.perPage,
          error: null,
        );
        AppLogger.info('Loaded ${worksheets.length} worksheets (page 1)');
      },
      onFailure: (failure) {
        state = state.copyWith(
          isLoading: false,
          error: _mapFailureToMessage(failure),
        );
        AppLogger.warning('Failed to load worksheets: $failure');
      },
    );
  }

  // ─── Create Worksheet ──────────────────────────────────────────────

  /// Creates a new worksheet with the provided [params].
  Future<void> createWorksheet(CreateWorksheetParams params) async {
    state = state.copyWith(isCreating: true, error: null);

    final result = await _createWorksheetUseCase(params);

    result.fold(
      onSuccess: (worksheet) {
        final updatedList = [worksheet, ...state.worksheets];
        state = state.copyWith(
          isCreating: false,
          worksheets: updatedList,
          successMessage: 'Worksheet created successfully',
          error: null,
        );
        AppLogger.info('Worksheet created: ${worksheet.id}');
      },
      onFailure: (failure) {
        state = state.copyWith(
          isCreating: false,
          error: _mapFailureToMessage(failure),
        );
        AppLogger.warning('Failed to create worksheet: $failure');
      },
    );
  }

  // ─── Update Worksheet ──────────────────────────────────────────────

  /// Updates an existing worksheet.
  Future<void> updateWorksheet(WorksheetEntity worksheet) async {
    state = state.copyWith(isUpdating: true, error: null);

    // Optimistically update the local state.
    final updatedList = state.worksheets
        .map((w) => w.id == worksheet.id ? worksheet : w)
        .toList();

    state = state.copyWith(
      isUpdating: false,
      worksheets: updatedList,
      currentWorksheet: state.currentWorksheet?.id == worksheet.id
          ? worksheet
          : state.currentWorksheet,
      successMessage: 'Worksheet updated successfully',
      error: null,
    );
    AppLogger.info('Worksheet updated: ${worksheet.id}');
  }

  // ─── Delete Worksheet ──────────────────────────────────────────────

  /// Deletes a worksheet by [worksheetId].
  Future<void> deleteWorksheet(String worksheetId) async {
    state = state.copyWith(isDeleting: true, error: null);

    // Optimistically remove from local state.
    final updatedList =
        state.worksheets.where((w) => w.id != worksheetId).toList();
    state = state.copyWith(
      isDeleting: false,
      worksheets: updatedList,
      currentWorksheet: state.currentWorksheet?.id == worksheetId
          ? null
          : state.currentWorksheet,
      successMessage: 'Worksheet deleted successfully',
      error: null,
    );
    AppLogger.info('Worksheet deleted: $worksheetId');
  }

  // ─── Generate Worksheet (AI) ───────────────────────────────────────

  /// Generates a worksheet using AI with the provided [params].
  Future<void> generateWorksheet(GenerateWorksheetParams params) async {
    state = state.copyWith(isGenerating: true, error: null);

    final result = await _generateWorksheetUseCase(params);

    result.fold(
      onSuccess: (worksheet) {
        final updatedList = [worksheet, ...state.worksheets];
        state = state.copyWith(
          isGenerating: false,
          worksheets: updatedList,
          currentWorksheet: worksheet,
          successMessage: 'Worksheet generated successfully',
          error: null,
        );
        AppLogger.info('Worksheet generated: ${worksheet.id}');
      },
      onFailure: (failure) {
        state = state.copyWith(
          isGenerating: false,
          error: _mapFailureToMessage(failure),
        );
        AppLogger.warning('Failed to generate worksheet: $failure');
      },
    );
  }

  // ─── Export Worksheet ──────────────────────────────────────────────

  /// Exports a worksheet to the specified format.
  Future<void> exportWorksheet(ExportWorksheetParams params) async {
    state = state.copyWith(isExporting: true, error: null);

    final result = await _exportWorksheetUseCase(params);

    result.fold(
      onSuccess: (url) {
        state = state.copyWith(
          isExporting: false,
          exportUrl: url,
          successMessage: 'Worksheet exported successfully',
          error: null,
        );
        AppLogger.info('Worksheet exported: ${params.worksheetId}');
      },
      onFailure: (failure) {
        state = state.copyWith(
          isExporting: false,
          error: _mapFailureToMessage(failure),
        );
        AppLogger.warning('Failed to export worksheet: $failure');
      },
    );
  }

  // ─── Set Filter ────────────────────────────────────────────────────

  /// Updates the active filter and reloads the worksheet list.
  Future<void> setFilter(WorkspaceFilterEntity filter) async {
    state = state.copyWith(filter: filter);
    await loadWorksheets();
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
// WORKSHEET PROVIDER
// ═══════════════════════════════════════════════════════════════════════

final worksheetProvider =
    StateNotifierProvider<WorksheetNotifier, WorksheetState>((ref) {
  return WorksheetNotifier(
    getWorksheetsUseCase: ref.watch(getWorksheetsUseCaseProvider),
    createWorksheetUseCase: ref.watch(createWorksheetUseCaseProvider),
    generateWorksheetUseCase: ref.watch(generateWorksheetUseCaseProvider),
    exportWorksheetUseCase: ref.watch(exportWorksheetUseCaseProvider),
  );
});
