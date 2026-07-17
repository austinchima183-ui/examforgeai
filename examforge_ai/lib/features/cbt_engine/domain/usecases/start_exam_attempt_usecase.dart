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
/// Performs comprehensive pre-flight validation:
/// - Exam must be active (published or in active status)
/// - Exam must be within its scheduled time window
/// - Student must be assigned to the exam
/// - Student must not have exceeded the allowed number of attempts
/// - Student must not be exempt from the exam
/// - Student must not already have an in-progress attempt
class StartExamAttemptUseCase {
  StartExamAttemptUseCase(this._repository);

  final CbtRepository _repository;

  Future<Result<ExamAttemptEntity>> call(StartAttemptParams params) async {
    // ── Retrieve exam with details ────────────────────────────────────
    final examResult = await _repository.getExamWithDetails(params.examId);
    if (examResult.isFailure) {
      return FailureResult(examResult.fold(
        onSuccess: (_) =>
            const Failure.server(message: 'Unknown error', statusCode: 500),
        onFailure: (failure) => failure,
      ));
    }

    final exam = examResult.getOrElse(
      const ExamEntity(
        id: '',
        schoolId: '',
        createdBy: '',
        title: '',
        subjectId: '',
        classId: '',
        academicSessionId: '',
        examType: ExamType.custom,
        status: ExamStatus.draft,
        startTime: DateTime(2000),
        endTime: DateTime(2000),
        timeLimitMinutes: 0,
        totalMarks: 0,
        passMark: 0,
        createdAt: DateTime(2000),
        updatedAt: DateTime(2000),
      ),
    );

    // ── Validate exam is active ───────────────────────────────────────
    if (exam.status != ExamStatus.published &&
        exam.status != ExamStatus.active) {
      return FailureResult(
        Failure.validation(
          message: 'Exam is not available for attempts',
          fieldErrors: {
            'status':
                'Exam must be published or active. Current status: ${exam.status.label}',
          },
        ),
      );
    }

    // ── Validate exam is within time window ───────────────────────────
    final now = DateTime.now();
    if (now.isBefore(exam.startTime)) {
      return FailureResult(
        Failure.validation(
          message: 'Exam has not started yet',
          fieldErrors: {
            'startTime':
                'This exam opens at ${exam.startTime.toIso8601String()}',
          },
        ),
      );
    }

    if (now.isAfter(exam.endTime)) {
      return FailureResult(
        Failure.validation(
          message: 'Exam has ended',
          fieldErrors: {
            'endTime':
                'This exam closed at ${exam.endTime.toIso8601String()}',
          },
        ),
      );
    }

    // ── Validate exam has questions ───────────────────────────────────
    if (exam.questions.isEmpty) {
      return const FailureResult(
        Failure.validation(
          message: 'Exam has no questions',
          fieldErrors: {
            'questions': 'Cannot start an exam without any questions',
          },
        ),
      );
    }

    // ── Delegate to repository (which validates student assignment,
    //    attempt limits, and existing in-progress attempts) ────────────
    return _repository.startAttempt(params.examId);
  }
}
