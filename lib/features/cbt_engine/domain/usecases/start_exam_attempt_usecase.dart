import '../../../../core/errors/failures.dart';
import '../../../../core/utils/result.dart';
import '../entities/cbt_entities.dart';
import '../repositories/cbt_repository.dart';

/// Parameters for the [StartExamAttemptUseCase].
class StartAttemptParams {
  const StartAttemptParams({
    required this.examId,
  });

  /// The ID of the exam to start an attempt for.
  final String examId;
}

/// Use case that starts a new exam attempt for a student.
///
/// Delegates all validation to the server-side `start_exam_attempt()`
/// SQL function, which atomically checks:
/// - Exam is active (published or in active status)
/// - Exam is within its scheduled time window
/// - Student is assigned to the exam
/// - Student has not exceeded the allowed number of attempts
/// - Student is not exempt from the exam
/// - Student does not already have an in-progress attempt
///
/// The use case validates that the server confirmed the attempt was
/// started and surfaces any server-rejected reasons as domain failures.
class StartExamAttemptUseCase {
  StartExamAttemptUseCase(this._repository);

  final CbtRepository _repository;

  Future<Result<ExamAttemptEntity>> call(StartAttemptParams params) async {
    // ── Delegate to repository (which calls the server-side function) ──
    final result = await _repository.startAttempt(params.examId);

    // ── Validate the server confirmed the attempt was started ──────────
    return result.fold(
      onSuccess: (attempt) {
        // Server returned an attempt — verify it is in the expected state
        if (attempt.status != AttemptStatus.inProgress) {
          return FailureResult(
            Failure.validation(
              message: 'Server did not start the attempt as expected',
              fieldErrors: {
                'status': 'Expected in_progress but received '
                    '${attempt.status.label}',
              },
            ),
          );
        }
        return Success(attempt);
      },
      onFailure: (failure) => FailureResult(failure),
    );
  }
}
