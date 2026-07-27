import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../config/dependency_injection.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/utils/logger.dart';
import '../../domain/entities/marketplace_entities.dart';
import '../../domain/usecases/get_quality_check_usecase.dart';
import '../../domain/usecases/run_quality_check_usecase.dart';

// ═══════════════════════════════════════════════════════════════════════
// QUALITY CHECK STATE
// ═══════════════════════════════════════════════════════════════════════

/// Immutable state snapshot for the AI Quality Review System.
///
/// Tracks quality check results, quality history, check running state,
/// and loading/error states.
class QualityCheckState {
  const QualityCheckState({
    this.isLoading = false,
    this.error,
    this.qualityCheck,
    this.qualityHistory = const [],
    this.isRunningCheck = false,
  });

  /// Whether an async operation is in progress.
  final bool isLoading;

  /// The most recent error message, or `null`.
  final String? error;

  /// The current quality check result.
  final QualityCheckEntity? qualityCheck;

  /// Historical quality check results.
  final List<QualityCheckEntity> qualityHistory;

  /// Whether a quality check is currently being run.
  final bool isRunningCheck;

  // ─── Computed Getters ────────────────────────────────────────────────

  /// Whether a quality check result is available.
  bool get hasQualityCheck => qualityCheck != null;

  /// Whether the current quality check passed.
  bool get isPassed =>
      qualityCheck != null &&
      qualityCheck!.computedStatus == QualityCheckStatus.passed;

  /// Whether the current quality check needs improvement.
  bool get needsImprovement =>
      qualityCheck != null &&
      qualityCheck!.computedStatus == QualityCheckStatus.needsImprovement;

  /// Whether the current quality check failed.
  bool get isFailed =>
      qualityCheck != null &&
      qualityCheck!.computedStatus == QualityCheckStatus.failed;

  /// Whether there are flagged issues.
  bool get hasIssues => qualityCheck?.hasIssues ?? false;

  /// Whether there are suggestions.
  bool get hasSuggestions => qualityCheck?.hasSuggestions ?? false;

  /// Creates a copy of this state with the given fields replaced.
  QualityCheckState copyWith({
    bool? isLoading,
    String? error,
    QualityCheckEntity? qualityCheck,
    List<QualityCheckEntity>? qualityHistory,
    bool? isRunningCheck,
  }) {
    return QualityCheckState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      qualityCheck: qualityCheck ?? this.qualityCheck,
      qualityHistory: qualityHistory ?? this.qualityHistory,
      isRunningCheck: isRunningCheck ?? this.isRunningCheck,
    );
  }

  /// Clears the current error message.
  QualityCheckState clearError() => copyWith(error: null);

  /// Clears the current success message (no-op, included for consistency).
  QualityCheckState clearSuccess() => copyWith();
}

// ═══════════════════════════════════════════════════════════════════════
// QUALITY CHECK NOTIFIER
// ═══════════════════════════════════════════════════════════════════════

/// Riverpod [StateNotifier] that manages the AI Quality Review state.
///
/// Supports running quality checks, loading check results, and
/// viewing quality check history.
class QualityCheckNotifier extends StateNotifier<QualityCheckState> {
  QualityCheckNotifier({
    required RunQualityCheckUseCase runQualityCheckUseCase,
    required GetQualityCheckUseCase getQualityCheckUseCase,
  })  : _runQualityCheckUseCase = runQualityCheckUseCase,
        _getQualityCheckUseCase = getQualityCheckUseCase,
        super(const QualityCheckState());

  final RunQualityCheckUseCase _runQualityCheckUseCase;
  final GetQualityCheckUseCase _getQualityCheckUseCase;

  // ─── Run Quality Check ──────────────────────────────────────────────

  /// Runs an AI quality check on the specified product.
  Future<void> runQualityCheck({required String productId}) async {
    state = state.copyWith(isRunningCheck: true, error: null);

    final result = await _runQualityCheckUseCase(
      RunQualityCheckParams(productId: productId),
    );

    result.fold(
      onSuccess: (qualityCheck) {
        state = state.copyWith(
          isRunningCheck: false,
          qualityCheck: qualityCheck,
          qualityHistory: [qualityCheck, ...state.qualityHistory],
        );
        AppLogger.info(
          'Quality check completed for product: $productId '
          '(score: ${qualityCheck.overallScore})',
        );
      },
      onFailure: (failure) {
        state = state.copyWith(
          isRunningCheck: false,
          error: _mapFailureToMessage(failure),
        );
        AppLogger.warning('Failed to run quality check: $failure');
      },
    );
  }

  // ─── Load Quality Check ─────────────────────────────────────────────

  /// Loads the latest quality check result for a product.
  Future<void> loadQualityCheck({required String productId}) async {
    state = state.copyWith(isLoading: true, error: null);

    final result = await _getQualityCheckUseCase(
      GetQualityCheckParams(productId: productId),
    );

    result.fold(
      onSuccess: (qualityCheck) {
        state = state.copyWith(
          isLoading: false,
          qualityCheck: qualityCheck,
        );
        AppLogger.info('Loaded quality check for product: $productId');
      },
      onFailure: (failure) {
        state = state.copyWith(
          isLoading: false,
          error: _mapFailureToMessage(failure),
        );
        AppLogger.warning('Failed to load quality check: $failure');
      },
    );
  }

  // ─── Load Quality History ───────────────────────────────────────────

  /// Loads the quality check history for a product.
  Future<void> loadQualityHistory({required String productId}) async {
    state = state.copyWith(isLoading: true, error: null);

    // Re-use getQualityCheck to fetch latest; history is accumulated
    final result = await _getQualityCheckUseCase(
      GetQualityCheckParams(productId: productId),
    );

    result.fold(
      onSuccess: (qualityCheck) {
        state = state.copyWith(
          isLoading: false,
          qualityCheck: qualityCheck,
          qualityHistory: [qualityCheck, ...state.qualityHistory],
        );
        AppLogger.info('Loaded quality history for product: $productId');
      },
      onFailure: (failure) {
        state = state.copyWith(
          isLoading: false,
          error: _mapFailureToMessage(failure),
        );
        AppLogger.warning('Failed to load quality history: $failure');
      },
    );
  }

  // ─── Clear Error ────────────────────────────────────────────────────

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
// QUALITY CHECK PROVIDER
// ═══════════════════════════════════════════════════════════════════════

/// Riverpod provider for the AI Quality Review feature.
///
/// The factory accepts all required use cases via named parameters.
final qualityCheckProvider =
    StateNotifierProvider<QualityCheckNotifier, QualityCheckState>(
  (ref) => QualityCheckNotifier(
    runQualityCheckUseCase: ref.watch(runQualityCheckUseCaseProvider),
    getQualityCheckUseCase: ref.watch(getQualityCheckUseCaseProvider),
  ),
);
