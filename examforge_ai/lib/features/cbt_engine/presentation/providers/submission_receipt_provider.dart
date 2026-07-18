import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/utils/logger.dart';
import '../../domain/entities/exam_template_entities.dart';
import '../../domain/usecases/get_submission_receipt_usecase.dart';

// ═══════════════════════════════════════════════════════════════════════
// SUBMISSION RECEIPT STATE
// ═══════════════════════════════════════════════════════════════════════

/// Immutable state snapshot for the submission receipt feature.
///
/// Tracks the receipt entity, verification status, loading flags,
/// and error messages.
class SubmissionReceiptState {
  const SubmissionReceiptState({
    this.receipt,
    this.isVerified,
    this.isLoading = false,
    this.error,
  });

  /// The submission receipt entity, or `null` if not yet loaded.
  final SubmissionReceiptEntity? receipt;

  /// Whether the receipt has been verified as authentic, or `null`
  /// if verification has not been attempted.
  final bool? isVerified;

  /// Whether a load or verify operation is in progress.
  final bool isLoading;

  /// The most recent error message, or `null`.
  final String? error;

  // ── Convenience getters ──────────────────────────────────────────────

  /// Whether a receipt is currently loaded.
  bool get hasReceipt => receipt != null;

  /// Whether verification has been attempted (regardless of outcome).
  bool get hasVerified => isVerified != null;

  /// Whether any async operation is in progress.
  bool get isBusy => isLoading;

  // ── copyWith ─────────────────────────────────────────────────────────

  SubmissionReceiptState copyWith({
    SubmissionReceiptEntity? receipt,
    bool? isVerified,
    bool? isLoading,
    String? error,
  }) {
    return SubmissionReceiptState(
      receipt: receipt ?? this.receipt,
      isVerified: isVerified ?? this.isVerified,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }

  /// Clears the current error message.
  SubmissionReceiptState clearError() => copyWith(error: null);
}

// ═══════════════════════════════════════════════════════════════════════
// SUBMISSION RECEIPT NOTIFIER
// ═══════════════════════════════════════════════════════════════════════

/// Riverpod [StateNotifier] that manages the submission receipt feature's
/// state.
///
/// Provides methods for loading a receipt by attempt ID and verifying a
/// receipt by its unique receipt number.
class SubmissionReceiptNotifier extends StateNotifier<SubmissionReceiptState> {
  SubmissionReceiptNotifier({
    required GetSubmissionReceiptUseCase getSubmissionReceiptUseCase,
    required VerifySubmissionReceiptUseCase verifySubmissionReceiptUseCase,
  })  : _getSubmissionReceiptUseCase = getSubmissionReceiptUseCase,
        _verifySubmissionReceiptUseCase = verifySubmissionReceiptUseCase,
        super(const SubmissionReceiptState());

  final GetSubmissionReceiptUseCase _getSubmissionReceiptUseCase;
  final VerifySubmissionReceiptUseCase _verifySubmissionReceiptUseCase;

  // ─── Load Receipt ────────────────────────────────────────────────────

  /// Loads a submission receipt for the given [attemptId].
  Future<void> loadReceipt(String attemptId) async {
    state = state.copyWith(isLoading: true, error: null);

    final result = await _getSubmissionReceiptUseCase(
      GetSubmissionReceiptParams(attemptId: attemptId),
    );

    result.fold(
      onSuccess: (receipt) {
        state = state.copyWith(
          isLoading: false,
          receipt: receipt,
          isVerified: receipt.isVerified ? true : null,
          error: null,
        );
        AppLogger.info('Loaded submission receipt for attempt: $attemptId');
      },
      onFailure: (failure) {
        state = state.copyWith(
          isLoading: false,
          error: _mapFailureToMessage(failure),
        );
        AppLogger.warning('Failed to load submission receipt: $failure');
      },
    );
  }

  // ─── Verify Receipt ──────────────────────────────────────────────────

  /// Verifies the authenticity of a receipt by its [receiptNumber].
  Future<void> verifyReceipt(String receiptNumber) async {
    state = state.copyWith(isLoading: true, error: null);

    final result = await _verifySubmissionReceiptUseCase(
      VerifyReceiptParams(receiptNumber: receiptNumber),
    );

    result.fold(
      onSuccess: (isValid) {
        state = state.copyWith(
          isLoading: false,
          isVerified: isValid,
          error: null,
        );
        AppLogger.info(
          'Receipt verification result: ${isValid ? "valid" : "invalid"}',
        );
      },
      onFailure: (failure) {
        state = state.copyWith(
          isLoading: false,
          isVerified: false,
          error: _mapFailureToMessage(failure),
        );
        AppLogger.warning('Failed to verify receipt: $failure');
      },
    );
  }

  // ─── Clear Error ─────────────────────────────────────────────────────

  /// Clears the current error message from the state.
  void clearError() {
    state = state.clearError();
  }

  // ─── Reset ───────────────────────────────────────────────────────────

  /// Resets the state back to its initial empty values.
  void reset() {
    state = const SubmissionReceiptState();
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
