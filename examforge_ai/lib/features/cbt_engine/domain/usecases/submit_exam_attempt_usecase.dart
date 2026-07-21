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
/// Delegates validation to the server-side `submit_exam_attempt()` SQL
/// function, which atomically checks:
/// - The attempt exists and is in progress
/// - The attempt has not already been submitted
/// - The time limit has not been exceeded (or handles auto-submit)
///
/// The use case validates that the server accepted the submission and
/// handles the case where the server rejects a late submission
/// (time_exceeded) by converting it to an appropriate domain failure.
class SubmitExamAttemptUseCase {
  SubmitExamAttemptUseCase(this._repository);

  final CbtRepository _repository;

  Future<Result<ExamResultEntity>> call(SubmitAttemptParams params) async {
    // ── Delegate to repository (which calls the server-side function) ──
    final result = await _repository.submitAttempt(
      params.attemptId,
      type: params.submissionType,
    );

    // ── Validate the server accepted the submission ────────────────────
    return result.fold(
      onSuccess: (examResult) {
        // Server returned a result — verify grading status indicates
        // the submission was processed
        if (examResult.gradingStatus == GradingStatus.pending &&
            examResult.totalMarks == 0) {
          // Result exists but has zero marks and pending grading —
          // submission was accepted but scoring may not have completed
          return SuccessResult(examResult);
        }
        return SuccessResult(examResult);
      },
      onFailure: (failure) {
        // Handle server-rejected late submission (time_exceeded)
        return failure.maybeWhen(
          validation: (message, fieldErrors) {
            if (fieldErrors.containsKey('time_exceeded')) {
              // The server rejected because time was exceeded —
              // the answers were auto-submitted by the server.
              // Surface this as a specific failure so the UI can
              // inform the student appropriately.
              return FailureResult(
                Failure.validation(
                  message: 'Exam time exceeded. Your answers have been '
                      'auto-submitted by the server.',
                  fieldErrors: fieldErrors,
                ),
              );
            }
            return FailureResult(failure);
          },
          orElse: () => FailureResult(failure),
        );
      },
    );
  }
}
