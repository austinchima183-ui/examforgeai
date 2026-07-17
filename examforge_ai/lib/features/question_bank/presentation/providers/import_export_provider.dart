import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/utils/logger.dart';
import '../../domain/entities/question_entities.dart';
import '../../domain/usecases/import_questions_usecase.dart';
import '../../domain/usecases/export_questions_usecase.dart';
import '../../domain/repositories/question_bank_repository.dart';

// ═══════════════════════════════════════════════════════════════════════
// IMPORT EXPORT STATE
// ═══════════════════════════════════════════════════════════════════════

/// Immutable state snapshot for the import/export feature.
///
/// Tracks the progress and status of asynchronous import and export jobs,
/// including progress values for UI progress indicators.
class ImportExportState {
  const ImportExportState({
    this.isImporting = false,
    this.isExporting = false,
    this.importStatus,
    this.exportStatus,
    this.importProgress = 0.0,
    this.exportProgress = 0.0,
    this.error,
    this.successMessage,
  });

  /// Whether an import operation is currently in progress.
  final bool isImporting;

  /// Whether an export operation is currently in progress.
  final bool isExporting;

  /// The current import job status, or `null` if no import has been started.
  final QuestionImportEntity? importStatus;

  /// The current export job status, or `null` if no export has been started.
  final QuestionExportEntity? exportStatus;

  /// Import progress as a value between 0.0 and 1.0.
  final double importProgress;

  /// Export progress as a value between 0.0 and 1.0.
  final double exportProgress;

  /// The most recent error message, or `null`.
  final String? error;

  /// A transient success message, or `null`.
  final String? successMessage;

  /// Whether any async operation is in progress.
  bool get isBusy => isImporting || isExporting;

  /// Whether the import has completed successfully.
  bool get isImportComplete =>
      importStatus?.status == 'completed' && !isImporting;

  /// Whether the export has completed successfully.
  bool get isExportComplete =>
      exportStatus?.status == 'completed' && !isExporting;

  /// Whether the import has failed.
  bool get isImportFailed =>
      importStatus?.status == 'failed' && !isImporting;

  /// Whether the export has failed.
  bool get isExportFailed =>
      exportStatus?.status == 'failed' && !isExporting;

  /// Creates a copy of this state with the given fields replaced.
  ImportExportState copyWith({
    bool? isImporting,
    bool? isExporting,
    QuestionImportEntity? importStatus,
    QuestionExportEntity? exportStatus,
    double? importProgress,
    double? exportProgress,
    String? error,
    String? successMessage,
  }) {
    return ImportExportState(
      isImporting: isImporting ?? this.isImporting,
      isExporting: isExporting ?? this.isExporting,
      importStatus: importStatus ?? this.importStatus,
      exportStatus: exportStatus ?? this.exportStatus,
      importProgress: importProgress ?? this.importProgress,
      exportProgress: exportProgress ?? this.exportProgress,
      error: error,
      successMessage: successMessage,
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// IMPORT EXPORT NOTIFIER
// ═══════════════════════════════════════════════════════════════════════

/// Riverpod [StateNotifier] that manages the import/export feature's state.
///
/// Handles starting import and export jobs, polling for status updates,
/// and computing progress values for the UI.
class ImportExportNotifier extends StateNotifier<ImportExportState> {
  ImportExportNotifier({
    required ImportQuestionsUseCase importQuestionsUseCase,
    required ExportQuestionsUseCase exportQuestionsUseCase,
    required QuestionBankRepository repository,
  })  : _importQuestionsUseCase = importQuestionsUseCase,
        _exportQuestionsUseCase = exportQuestionsUseCase,
        _repository = repository,
        super(const ImportExportState());

  final ImportQuestionsUseCase _importQuestionsUseCase;
  final ExportQuestionsUseCase _exportQuestionsUseCase;
  final QuestionBankRepository _repository;

  Timer? _importPollTimer;
  Timer? _exportPollTimer;

  // ─── Start Import ───────────────────────────────────────────────────

  /// Starts an asynchronous import job with the provided [params].
  ///
  /// After starting the job, polls the backend for status updates until
  /// the import completes or fails.
  Future<void> startImport(ImportQuestionsParams params) async {
    state = state.copyWith(
      isImporting: true,
      importProgress: 0.0,
      error: null,
      successMessage: null,
    );

    final result = await _importQuestionsUseCase(params);

    result.fold(
      onSuccess: (importJob) {
        state = state.copyWith(
          importStatus: importJob,
          importProgress: 0.1,
        );
        AppLogger.info('Import job started: ${importJob.id}');
        _startImportPolling(importJob.id);
      },
      onFailure: (failure) {
        state = state.copyWith(
          isImporting: false,
          error: _mapFailureToMessage(failure),
        );
        AppLogger.warning('Failed to start import: $failure');
      },
    );
  }

  // ─── Check Import Status ────────────────────────────────────────────

  /// Checks the current status of an import job by [importId].
  ///
  /// Updates the state with the latest status and computes progress.
  Future<void> checkImportStatus(String importId) async {
    final result = await _repository.getImportStatus(importId);

    result.fold(
      onSuccess: (importJob) {
        final progress = _computeImportProgress(importJob);
        final isComplete = importJob.status == 'completed';
        final isFailed = importJob.status == 'failed';

        state = state.copyWith(
          importStatus: importJob,
          importProgress: progress,
          isImporting: !isComplete && !isFailed,
          successMessage: isComplete
              ? 'Import completed: ${importJob.importedCount} of '
                  '${importJob.totalQuestions} questions imported'
              : null,
          error: isFailed
              ? 'Import failed: ${importJob.failedCount} questions could '
                  'not be imported'
              : null,
        );

        if (isComplete || isFailed) {
          _importPollTimer?.cancel();
          _importPollTimer = null;
          AppLogger.info(
            'Import ${isComplete ? "completed" : "failed"}: $importId',
          );
        }
      },
      onFailure: (failure) {
        AppLogger.warning('Failed to check import status: $failure');
      },
    );
  }

  // ─── Start Export ───────────────────────────────────────────────────

  /// Starts an asynchronous export job with the provided [params].
  ///
  /// After starting the job, polls the backend for status updates until
  /// the export completes or fails.
  Future<void> startExport(ExportQuestionsParams params) async {
    state = state.copyWith(
      isExporting: true,
      exportProgress: 0.0,
      error: null,
      successMessage: null,
    );

    final result = await _exportQuestionsUseCase(params);

    result.fold(
      onSuccess: (exportJob) {
        state = state.copyWith(
          exportStatus: exportJob,
          exportProgress: 0.1,
        );
        AppLogger.info('Export job started: ${exportJob.id}');
        _startExportPolling(exportJob.id);
      },
      onFailure: (failure) {
        state = state.copyWith(
          isExporting: false,
          error: _mapFailureToMessage(failure),
        );
        AppLogger.warning('Failed to start export: $failure');
      },
    );
  }

  // ─── Check Export Status ────────────────────────────────────────────

  /// Checks the current status of an export job by [exportId].
  ///
  /// Updates the state with the latest status and computes progress.
  Future<void> checkExportStatus(String exportId) async {
    final result = await _repository.getExportStatus(exportId);

    result.fold(
      onSuccess: (exportJob) {
        final progress = _computeExportProgress(exportJob);
        final isComplete = exportJob.status == 'completed';
        final isFailed = exportJob.status == 'failed';

        state = state.copyWith(
          exportStatus: exportJob,
          exportProgress: progress,
          isExporting: !isComplete && !isFailed,
          successMessage: isComplete
              ? 'Export completed: ${exportJob.exportedCount} questions '
                  'exported'
              : null,
          error: isFailed
              ? 'Export failed${exportJob.errorMessage != null ? ": ${exportJob.errorMessage}" : ""}'
              : null,
        );

        if (isComplete || isFailed) {
          _exportPollTimer?.cancel();
          _exportPollTimer = null;
          AppLogger.info(
            'Export ${isComplete ? "completed" : "failed"}: $exportId',
          );
        }
      },
      onFailure: (failure) {
        AppLogger.warning('Failed to check export status: $failure');
      },
    );
  }

  // ─── Reset State ────────────────────────────────────────────────────

  /// Resets all import/export state to its initial values and cancels
  /// any active polling timers.
  void resetState() {
    _importPollTimer?.cancel();
    _importPollTimer = null;
    _exportPollTimer?.cancel();
    _exportPollTimer = null;
    state = const ImportExportState();
  }

  // ═══════════════════════════════════════════════════════════════════════
  // PRIVATE HELPERS
  // ═══════════════════════════════════════════════════════════════════════

  /// Starts polling the backend for import status every 2 seconds.
  void _startImportPolling(String importId) {
    _importPollTimer?.cancel();
    _importPollTimer = Timer.periodic(
      const Duration(seconds: 2),
      (_) => checkImportStatus(importId),
    );
  }

  /// Starts polling the backend for export status every 2 seconds.
  void _startExportPolling(String exportId) {
    _exportPollTimer?.cancel();
    _exportPollTimer = Timer.periodic(
      const Duration(seconds: 2),
      (_) => checkExportStatus(exportId),
    );
  }

  /// Computes import progress as a value between 0.0 and 1.0.
  double _computeImportProgress(QuestionImportEntity importJob) {
    if (importJob.totalQuestions == 0) return 0.1;
    final processed =
        importJob.importedCount + importJob.failedCount;
    return (processed / importJob.totalQuestions).clamp(0.0, 1.0);
  }

  /// Computes export progress as a value between 0.0 and 1.0.
  double _computeExportProgress(QuestionExportEntity exportJob) {
    if (exportJob.totalQuestions == 0) return 0.1;
    return (exportJob.exportedCount / exportJob.totalQuestions)
        .clamp(0.0, 1.0);
  }

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

  @override
  void dispose() {
    _importPollTimer?.cancel();
    _exportPollTimer?.cancel();
    super.dispose();
  }
}
