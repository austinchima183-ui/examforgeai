import '../../../../core/errors/failures.dart';
import '../../../../core/utils/result.dart';
import '../entities/cbt_entities.dart';
import '../repositories/cbt_repository.dart';

/// Parameters for the [SubmitExamAttemptUseCase].
class SubmitAttemptParams {
  const SubmitAttemptParams({
    required this.attemptId,
    this.submissionType = SubmissionType.manual,
  });

  /// The ID of the attempt to submit.
  final String attemptId;

  /// How the attempt is being submitted (manual, auto, timed out, forced).
  final SubmissionType submissionType;
}

/// Use case that submits an exam attempt.
///
/// Validates that:
/// - The attempt exists
/// - The attempt is currently in progress
/// - The attempt has not already been submitted
///
/// On successful submission, the repository computes auto-graded results,
/// marks non-auto-gradable answers as pending, and returns an
/// [ExamResultEntity].
class SubmitExamAttemptUseCase {
  SubmitExamAttemptUseCase(this._repository);

  final CbtRepository _repository;

  Future<Result<ExamResultEntity>> call(SubmitAttemptParams params) async {
    // ── Validate attempt exists and is in progress ────────────────────
    final attemptResult = await _repository.getAttempt(params.attemptId);
    if (attemptResult.isFailure) {
      return FailureResult(attemptResult.fold(
        onSuccess: (_) =>
            const Failure.server(message: 'Unknown error', statusCode: 500),
        onFailure: (failure) => failure,
      ));
    }

    final attempt = attemptResult.getOrElse(
      const ExamAttemptEntity(
        id: '',
        examId: '',
        studentId: '',
        attemptNumber: 0,
        status: AttemptStatus.notStarted,
        startedAt: DateTime(2000),
        gradingStatus: GradingStatus.pending,
        createdAt: DateTime(2000),
        updatedAt: DateTime(2000),
      ),
    );

    // ── Validate attempt is in progress ───────────────────────────────
    if (attempt.status != AttemptStatus.inProgress) {
      return FailureResult(
        Failure.validation(
          message: 'Attempt cannot be submitted',
          fieldErrors: {
            'status':
                'Attempt must be in progress to submit. Current status: ${attempt.status.label}',
          },
        ),
      );
    }

    // ── Validate attempt is not already terminal ──────────────────────
    if (attempt.status.isTerminal) {
      return FailureResult(
        Failure.validation(
          message: 'Attempt has already been finalized',
          fieldErrors: {
            'status':
                'This attempt has already been ${attempt.status.label}',
          },
        ),
      );
    }

    // ── Delegate to repository ────────────────────────────────────────
    return _repository.submitAttempt(
      params.attemptId,
      type: params.submissionType,
    );
  }
}
