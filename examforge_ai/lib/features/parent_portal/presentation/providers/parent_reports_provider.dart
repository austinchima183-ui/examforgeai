import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/utils/logger.dart';
import '../../domain/entities/parent_portal_entities.dart';
import '../../domain/usecases/download_report_usecase.dart';

// ═══════════════════════════════════════════════════════════════════════
// PARENT REPORTS STATE
// ═══════════════════════════════════════════════════════════════════════

/// Immutable state snapshot for the parent reports feature.
///
/// Tracks the download history, downloading flag, error message,
/// transient success message, and the last download URL.
class ParentReportsState {
  const ParentReportsState({
    this.downloads = const [],
    this.isDownloading = false,
    this.error,
    this.successMessage,
    this.lastDownloadUrl,
  });

  /// The list of report download history entries.
  final List<ParentReportDownloadEntity> downloads;

  /// Whether a download operation is in progress.
  final bool isDownloading;

  /// The most recent error message, or `null`.
  final String? error;

  /// A transient success message (e.g. "Report downloaded"), or `null`.
  final String? successMessage;

  /// The URL of the most recently downloaded report, or `null`.
  final String? lastDownloadUrl;

  /// Creates a copy of this state with the given fields replaced.
  ParentReportsState copyWith({
    List<ParentReportDownloadEntity>? downloads,
    bool? isDownloading,
    String? error,
    String? successMessage,
    String? lastDownloadUrl,
  }) {
    return ParentReportsState(
      downloads: downloads ?? this.downloads,
      isDownloading: isDownloading ?? this.isDownloading,
      error: error,
      successMessage: successMessage,
      lastDownloadUrl: lastDownloadUrl ?? this.lastDownloadUrl,
    );
  }

  /// Clears the current error message.
  ParentReportsState clearError() => copyWith(error: null);
}

// ═══════════════════════════════════════════════════════════════════════
// PARENT REPORTS NOTIFIER
// ═══════════════════════════════════════════════════════════════════════

/// Riverpod [StateNotifier] that manages the parent reports feature's state.
///
/// All report operations flow through this notifier, which:
/// 1. Sets [isDownloading] before each download operation
/// 2. Delegates to the [DownloadReportUseCase]
/// 3. Updates [downloads], [lastDownloadUrl], and [successMessage] on success
/// 4. Sets [error] on failure
class ParentReportsNotifier extends StateNotifier<ParentReportsState> {
  ParentReportsNotifier({
    required DownloadReportUseCase downloadReportUseCase,
  })  : _downloadReportUseCase = downloadReportUseCase,
        super(const ParentReportsState());

  final DownloadReportUseCase _downloadReportUseCase;

  // ─── Download Report ───────────────────────────────────────────────

  /// Downloads a report for the specified [studentId], [reportType],
  /// and [format] (e.g. `pdf`, `excel`, `printable`).
  Future<void> downloadReport(
    String studentId,
    String reportType,
    String format,
  ) async {
    state = state.copyWith(isDownloading: true, error: null);

    final result = await _downloadReportUseCase(
      DownloadReportParams(
        studentId: studentId,
        reportType: reportType,
        format: format,
      ),
    );

    result.fold(
      onSuccess: (download) {
        final updatedDownloads = [download, ...state.downloads];
        state = state.copyWith(
          isDownloading: false,
          downloads: updatedDownloads,
          successMessage: 'Report downloaded successfully',
          lastDownloadUrl: download.downloadUrl,
          error: null,
        );
        AppLogger.info('Report downloaded for student: $studentId');
      },
      onFailure: (failure) {
        state = state.copyWith(
          isDownloading: false,
          error: _mapFailureToMessage(failure),
        );
        AppLogger.warning('Failed to download report: $failure');
      },
    );
  }

  // ─── Load Download History ─────────────────────────────────────────

  /// Loads the report download history for the specified [studentId].
  ///
  /// Since no dedicated use case exists for download history, this
  /// method is a placeholder that can be extended when a history
  /// endpoint becomes available.
  Future<void> loadDownloadHistory(String studentId) async {
    // Placeholder: download history is tracked locally via the
    // [downloads] list which grows as reports are downloaded.
    AppLogger.info('Download history requested for student: $studentId');
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
// PARENT REPORTS PROVIDER
// ═══════════════════════════════════════════════════════════════════════

final parentReportsProvider =
    StateNotifierProvider<ParentReportsNotifier, ParentReportsState>((ref) {
  return ParentReportsNotifier(
    downloadReportUseCase: ref.watch(downloadReportUseCaseProvider),
  );
});
