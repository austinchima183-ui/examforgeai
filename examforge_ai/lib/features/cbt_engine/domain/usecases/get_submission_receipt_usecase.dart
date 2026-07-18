import '../../../../core/errors/failures.dart';
import '../../../../core/utils/result.dart';
import '../entities/exam_template_entities.dart';
import '../repositories/exam_template_repository.dart';

// ═══════════════════════════════════════════════════════════════════════
// GET SUBMISSION RECEIPT
// ═══════════════════════════════════════════════════════════════════════

/// Parameters for the [GetSubmissionReceiptUseCase].
class GetSubmissionReceiptParams {
  const GetSubmissionReceiptParams({
    required this.attemptId,
  });

  /// The ID of the exam attempt to retrieve the receipt for.
  final String attemptId;
}

/// Use case that retrieves a submission receipt for a completed exam
/// attempt.
///
/// The receipt provides verifiable proof that a student submitted
/// their exam, including counts of answered/unanswered/flagged
/// questions, time spent, and device metadata. Validates that an
/// attempt ID is provided before delegating to the repository.
class GetSubmissionReceiptUseCase {
  GetSubmissionReceiptUseCase(this._repository);

  final ExamTemplateRepository _repository;

  Future<Result<SubmissionReceiptEntity>> call(
    GetSubmissionReceiptParams params,
  ) async {
    // ── Validate attempt ID ───────────────────────────────────────────
    if (params.attemptId.trim().isEmpty) {
      return const FailureResult(
        Failure.validation(
          message: 'Attempt ID is required',
          fieldErrors: {'attemptId': 'Please provide an attempt ID'},
        ),
      );
    }

    // ── Delegate to repository ────────────────────────────────────────
    return _repository.getSubmissionReceipt(params.attemptId);
  }
}

// ═══════════════════════════════════════════════════════════════════════
// VERIFY SUBMISSION RECEIPT
// ═══════════════════════════════════════════════════════════════════════

/// Parameters for the [VerifySubmissionReceiptUseCase].
class VerifyReceiptParams {
  const VerifyReceiptParams({
    required this.receiptNumber,
  });

  /// The unique receipt number to verify.
  final String receiptNumber;
}

/// Use case that verifies the authenticity of a submission receipt.
///
/// Checks whether the receipt number corresponds to a valid, verified
/// submission in the system. This is useful for audit trails, dispute
/// resolution, and confirming that a student's submission was recorded
/// correctly.
class VerifySubmissionReceiptUseCase {
  VerifySubmissionReceiptUseCase(this._repository);

  final ExamTemplateRepository _repository;

  Future<Result<bool>> call(VerifyReceiptParams params) async {
    // ── Validate receipt number ───────────────────────────────────────
    if (params.receiptNumber.trim().isEmpty) {
      return const FailureResult(
        Failure.validation(
          message: 'Receipt number is required',
          fieldErrors: {
            'receiptNumber': 'Please provide a receipt number to verify',
          },
        ),
      );
    }

    // ── Delegate to repository ────────────────────────────────────────
    return _repository.verifyReceipt(params.receiptNumber);
  }
}
