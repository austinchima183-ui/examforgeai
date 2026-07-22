import '../../../../core/errors/failures.dart';
import '../../../../core/utils/result.dart';
import '../entities/cbt_entities.dart';
import '../repositories/cbt_repository.dart';
import '../../../../features/cbt_engine/domain/entities/cbt_entities.dart';


/// Parameters for the [UpdateExamUseCase].
class UpdateExamParams {
  const UpdateExamParams({
    required this.exam,
    this.sections,
    this.questions,
    this.studentIds,
  });

  /// The exam entity with updated fields.
  final ExamEntity exam;

  /// Optional updated sections list. If `null`, sections are not modified.
  final List<ExamSectionEntity>? sections;

  /// Optional updated questions list. If `null`, questions are not modified.
  final List<ExamQuestionEntity>? questions;

  /// Optional student IDs to assign. If `null`, student assignments are
  /// not modified.
  final List<String>? studentIds;
}

/// Use case that updates an existing exam in the CBT engine.
///
/// Validates that the exam is in an editable state and that the
/// updated fields are logically consistent, then delegates to
/// [CbtRepository.updateExam].
class UpdateExamUseCase {
  UpdateExamUseCase(this._repository);

  final CbtRepository _repository;

  Future<Result<ExamEntity>> call(UpdateExamParams params) async {
    // ── Validate exam exists and is editable ──────────────────────────
    final existingResult = await _repository.getExam(params.exam.id);
    if (existingResult.isFailure) {
      return FailureResult(existingResult.fold(
        onSuccess: (_) => const Failure.server(message: 'Unknown error', statusCode: 500),
        onFailure: (failure) => failure,
      ));
    }

    final existing = existingResult.getOrElse(
      ExamEntity(
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

    if (!existing.status.isEditable) {
      return FailureResult(
        Failure.validation(
          message: 'Exam cannot be edited in ${existing.status.label} status',
          fieldErrors: {
            'status':
                'Only draft exams can be edited. Current status: ${existing.status.label}',
          },
        ),
      );
    }

    // ── Validate core fields ──────────────────────────────────────────
    if (params.exam.title.trim().isEmpty) {
      return const FailureResult(
        Failure.validation(
          message: 'Exam title is required',
          fieldErrors: {'title': 'Please provide a title for the exam'},
        ),
      );
    }

    // ── Validate timing ───────────────────────────────────────────────
    if (params.exam.endTime.isBefore(params.exam.startTime) ||
        params.exam.endTime.isAtSameMomentAs(params.exam.startTime)) {
      return const FailureResult(
        Failure.validation(
          message: 'End time must be after start time',
          fieldErrors: {
            'endTime': 'The exam end time must be later than the start time',
          },
        ),
      );
    }

    if (params.exam.timeLimitMinutes <= 0) {
      return const FailureResult(
        Failure.validation(
          message: 'Time limit must be greater than zero',
          fieldErrors: {
            'timeLimitMinutes': 'Set a time limit of at least 1 minute',
          },
        ),
      );
    }

    // ── Validate scoring ──────────────────────────────────────────────
    if (params.exam.passMark < 0) {
      return const FailureResult(
        Failure.validation(
          message: 'Pass mark cannot be negative',
          fieldErrors: {'passMark': 'Pass mark must be zero or positive'},
        ),
      );
    }

    if (params.exam.passMarkType == 'percentage' &&
        params.exam.passMark > 100) {
      return const FailureResult(
        Failure.validation(
          message: 'Pass mark percentage cannot exceed 100',
          fieldErrors: {
            'passMark': 'Percentage pass mark must be between 0 and 100',
          },
        ),
      );
    }

    // ── Validate negative marking ─────────────────────────────────────
    if (params.exam.negativeMarkingEnabled &&
        params.exam.negativeMarkValue < 0) {
      return const FailureResult(
        Failure.validation(
          message: 'Negative mark value cannot be negative',
          fieldErrors: {
            'negativeMarkValue': 'Set a positive value for negative marking',
          },
        ),
      );
    }

    // ── Validate attempt rules ────────────────────────────────────────
    if (params.exam.allowedAttempts < 1) {
      return const FailureResult(
        Failure.validation(
          message: 'At least one attempt must be allowed',
          fieldErrors: {
            'allowedAttempts': 'Allow at least 1 attempt',
          },
        ),
      );
    }

    // ── Validate showResults value ────────────────────────────────────
    const validShowResults = [
      'immediate',
      'after_submission',
      'after_grading',
      'manual',
    ];
    if (!validShowResults.contains(params.exam.showResults)) {
      return const FailureResult(
        Failure.validation(
          message: 'Invalid show results setting',
          fieldErrors: {
            'showResults':
                'Must be one of: immediate, after_submission, after_grading, manual',
          },
        ),
      );
    }

    // ── Validate questions if provided ────────────────────────────────
    if (params.questions != null) {
      for (final question in params.questions!) {
        if (question.marks <= 0) {
          return FailureResult(
            Failure.validation(
              message: 'All exam questions must have marks greater than zero',
              fieldErrors: {
                'questions':
                    'Question "${question.questionId}" has ${question.marks} marks',
              },
            ),
          );
        }
      }
    }

    // ── Validate sections if provided ─────────────────────────────────
    if (params.sections != null) {
      for (final section in params.sections!) {
        if (section.title.trim().isEmpty) {
          return const FailureResult(
            Failure.validation(
              message: 'All exam sections must have a title',
              fieldErrors: {'sections': 'Each section must have a title'},
            ),
          );
        }
      }
    }

    // ── Delegate to repository ────────────────────────────────────────
    return _repository.updateExam(params.exam);
  }
}
