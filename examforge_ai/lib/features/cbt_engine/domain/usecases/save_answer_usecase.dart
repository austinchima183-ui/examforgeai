import '../../../../core/errors/failures.dart';
import '../../../../core/utils/result.dart';
import '../entities/cbt_entities.dart';
import '../repositories/cbt_repository.dart';

/// Parameters for the [SaveAnswerUseCase].
class SaveAnswerParams {
  const SaveAnswerParams({
    required this.attemptId,
    required this.questionId,
    required this.answerData,
  });

  /// The ID of the active attempt.
  final String attemptId;

  /// The ID of the question being answered.
  final String questionId;

  /// The answer payload — structure varies by question type.
  ///
  /// For multiple choice: `{'selected_option_id': 'abc123'}`
  /// For multiple response: `{'selected_option_ids': ['abc123', 'def456']}`
  /// For fill-in-blank: `{'blanks': [{'index': 0, 'answer': 'photosynthesis'}]}`
  /// For matching: `{'pairs': [{'left_id': 'l1', 'right_id': 'r2'}]}`
  /// For ordering: `{'ordered_ids': ['q1', 'q3', 'q2']}`
  /// For essay/short answer: `{'text': 'Student response...'}`
  /// For numerical: `{'value': 42.5}`
  final Map<String, dynamic> answerData;
}

/// Use case that saves or updates a student's answer during an exam attempt.
///
/// Validates that:
/// - The attempt exists and is currently in progress
/// - The answer data is not empty
///
/// The repository handles upsert logic (create or update) and may
/// perform auto-grading for objective question types.
class SaveAnswerUseCase {
  SaveAnswerUseCase(this._repository);

  final CbtRepository _repository;

  Future<Result<StudentAnswerEntity>> call(SaveAnswerParams params) async {
    // ── Validate answer data is not empty ─────────────────────────────
    if (params.answerData.isEmpty) {
      return const FailureResult(
        Failure.validation(
          message: 'Answer data cannot be empty',
          fieldErrors: {
            'answerData': 'Please provide an answer for this question',
          },
        ),
      );
    }

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
      ExamAttemptEntity(
        id: '',
        examId: '',
        studentId: '',
        attemptNumber: 0,
        status: AttemptStatus.notStarted,
        startedAt: DateTime.utc(2000),
        gradingStatus: GradingStatus.pending,
        createdAt: DateTime.utc(2000),
        updatedAt: DateTime.utc(2000),
      ),
    );

    if (attempt.status != AttemptStatus.inProgress) {
      return FailureResult(
        Failure.validation(
          message: 'Cannot save answer for a non-active attempt',
          fieldErrors: {
            'status':
                'Attempt must be in progress. Current status: ${attempt.status.label}',
          },
        ),
      );
    }

    // ── Delegate to repository ────────────────────────────────────────
    return _repository.saveAnswer(
      params.attemptId,
      params.questionId,
      params.answerData,
    );
  }
}
