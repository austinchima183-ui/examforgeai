import '../../../../core/errors/failures.dart';
import '../../../../core/utils/result.dart';
import '../entities/cbt_entities.dart';
import '../repositories/cbt_repository.dart';
import '../../../question_bank/domain/entities/question_entities.dart';


/// Parameters for the [CreateExamUseCase].
class CreateExamParams {
  const CreateExamParams({
    required this.exam,
    this.sections = const [],
    this.questions = const [],
    this.studentIds = const [],
  });

  /// The exam creation input from the teacher.
  final ExamCreateInput exam;

  /// Sections to create within the exam.
  final List<ExamSectionEntity> sections;

  /// Questions to add to the exam.
  final List<ExamQuestionEntity> questions;

  /// IDs of students to assign to the exam.
  final List<String> studentIds;
}

/// Use case that creates a new exam in the CBT engine.
///
/// Validates that all required fields are present and logically
/// consistent, then delegates to [CbtRepository.createExam] and
/// handles section, question, and student assignment in sequence.
class CreateExamUseCase {
  CreateExamUseCase(this._repository);

  final CbtRepository _repository;

  Future<Result<ExamEntity>> call(CreateExamParams params) async {
    // ── Validate core exam fields ─────────────────────────────────────
    if (params.exam.title.trim().isEmpty) {
      return const FailureResult(
        Failure.validation(
          message: 'Exam title is required',
          fieldErrors: {'title': 'Please provide a title for the exam'},
        ),
      );
    }

    if (params.exam.subjectId.trim().isEmpty) {
      return const FailureResult(
        Failure.validation(
          message: 'Subject is required',
          fieldErrors: {'subjectId': 'Please select a subject'},
        ),
      );
    }

    if (params.exam.classId.trim().isEmpty) {
      return const FailureResult(
        Failure.validation(
          message: 'Class is required',
          fieldErrors: {'classId': 'Please select a class'},
        ),
      );
    }

    if (params.exam.academicSessionId.trim().isEmpty) {
      return const FailureResult(
        Failure.validation(
          message: 'Academic session is required',
          fieldErrors: {
            'academicSessionId': 'Please select an academic session',
          },
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

    if (params.exam.passMarkType == 'percentage' && params.exam.passMark > 100) {
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
    if (params.exam.negativeMarkingEnabled && params.exam.negativeMarkValue < 0) {
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
    const validShowResults = ['immediate', 'after_submission', 'after_grading', 'manual'];
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

    // ── Validate questions have marks ─────────────────────────────────
    for (final question in params.questions) {
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

    // ── Validate sections have titles ─────────────────────────────────
    for (final section in params.sections) {
      if (section.title.trim().isEmpty) {
        return const FailureResult(
          Failure.validation(
            message: 'All exam sections must have a title',
            fieldErrors: {'sections': 'Each section must have a title'},
          ),
        );
      }
    }

    // ── Build ExamEntity from input ───────────────────────────────────
    final now = DateTime.now();
    double totalMarks = 0.0;
    for (final q in params.questions) {
      totalMarks += q.marks;
    }

    final exam = ExamEntity(
      id: '', // Server-generated
      schoolId: '', // Injected from auth context in repository
      createdBy: '', // Injected from auth context in repository
      title: params.exam.title,
      description: params.exam.description,
      subjectId: params.exam.subjectId,
      classId: params.exam.classId,
      academicSessionId: params.exam.academicSessionId,
      examType: params.exam.examType,
      status: ExamStatus.draft,
      startTime: params.exam.startTime,
      endTime: params.exam.endTime,
      timeLimitMinutes: params.exam.timeLimitMinutes,
      totalMarks: totalMarks,
      passMark: params.exam.passMark,
      passMarkType: params.exam.passMarkType,
      instructions: params.exam.instructions,
      allowedAttempts: params.exam.allowedAttempts,
      negativeMarkingEnabled: params.exam.negativeMarkingEnabled,
      negativeMarkValue: params.exam.negativeMarkValue,
      gracePeriodMinutes: params.exam.gracePeriodMinutes,
      autoSubmit: params.exam.autoSubmit,
      randomizeQuestions: params.exam.randomizeQuestions,
      randomizeOptions: params.exam.randomizeOptions,
      showResults: params.exam.showResults,
      showCorrectAnswers: params.exam.showCorrectAnswers,
      showExplanations: params.exam.showExplanations,
      maxStudents: params.exam.maxStudents,
      requireFullScreen: params.exam.requireFullScreen,
      allowResume: params.exam.allowResume,
      browserLockdown: params.exam.browserLockdown,
      sections: params.sections,
      questions: params.questions,
      createdAt: now,
      updatedAt: now,
    );

    // ── Delegate to repository ────────────────────────────────────────
    final examResult = await _repository.createExam(exam);

    // ── Assign students if provided ───────────────────────────────────
    if (examResult.isFailure) return examResult;

    final createdExam = examResult.getOrElse(
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

    if (params.studentIds.isNotEmpty) {
      final assignResult = await _repository.assignStudents(
        createdExam.id,
        params.studentIds,
      );
      if (assignResult.isFailure) {
        return FailureResult(assignResult.fold(
          onSuccess: (_) => const Failure.server(message: 'Unknown error', statusCode: 500),
          onFailure: (failure) => failure,
        ));
      }
    }

    return examResult;
  }
}
