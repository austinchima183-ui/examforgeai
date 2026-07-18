import '../../../../core/errors/failures.dart';
import '../../../../core/utils/result.dart';
import '../entities/school_management_entities.dart';
import '../repositories/school_management_repository.dart';

// ═══════════════════════════════════════════════════════════════════════
// CREATE HOMEWORK
// ═══════════════════════════════════════════════════════════════════════

class CreateHomeworkParams {
  const CreateHomeworkParams({required this.homework});
  final HomeworkEntity homework;
}

/// Use case that creates a new homework assignment.
///
/// Validates that [HomeworkEntity.title], [HomeworkEntity.classId],
/// [HomeworkEntity.subjectId], and [HomeworkEntity.teacherId] are present,
/// then delegates to [SchoolManagementRepository.createHomework].
class CreateHomeworkUseCase {
  CreateHomeworkUseCase(this._repository);
  final SchoolManagementRepository _repository;

  Future<Result<HomeworkEntity>> call(CreateHomeworkParams params) async {
    // ── Validate title ───────────────────────────────────────────────────
    if (params.homework.title.trim().isEmpty) {
      return const FailureResult(
        Failure.validation(
          message: 'Homework title is required',
          fieldErrors: {'title': 'Please provide a title for the homework'},
        ),
      );
    }

    // ── Validate classId ─────────────────────────────────────────────────
    if (params.homework.classId.trim().isEmpty) {
      return const FailureResult(
        Failure.validation(
          message: 'Class is required',
          fieldErrors: {'classId': 'Please select a class'},
        ),
      );
    }

    // ── Validate subjectId ───────────────────────────────────────────────
    if (params.homework.subjectId.trim().isEmpty) {
      return const FailureResult(
        Failure.validation(
          message: 'Subject is required',
          fieldErrors: {'subjectId': 'Please select a subject'},
        ),
      );
    }

    // ── Validate teacherId ───────────────────────────────────────────────
    if (params.homework.teacherId.trim().isEmpty) {
      return const FailureResult(
        Failure.validation(
          message: 'Teacher is required',
          fieldErrors: {'teacherId': 'Please select a teacher'},
        ),
      );
    }

    return _repository.createHomework(params.homework);
  }
}

// ═══════════════════════════════════════════════════════════════════════
// UPDATE HOMEWORK
// ═══════════════════════════════════════════════════════════════════════

class UpdateHomeworkParams {
  const UpdateHomeworkParams({required this.homework});
  final HomeworkEntity homework;
}

/// Use case that updates an existing homework assignment.
///
/// Delegates to [SchoolManagementRepository.updateHomework].
class UpdateHomeworkUseCase {
  UpdateHomeworkUseCase(this._repository);
  final SchoolManagementRepository _repository;

  Future<Result<HomeworkEntity>> call(UpdateHomeworkParams params) async {
    return _repository.updateHomework(params.homework);
  }
}

// ═══════════════════════════════════════════════════════════════════════
// PUBLISH HOMEWORK
// ═══════════════════════════════════════════════════════════════════════

class PublishHomeworkParams {
  const PublishHomeworkParams({required this.homeworkId});
  final String homeworkId;
}

/// Use case that publishes a homework assignment, making it visible to students.
///
/// Delegates to [SchoolManagementRepository.publishHomework].
class PublishHomeworkUseCase {
  PublishHomeworkUseCase(this._repository);
  final SchoolManagementRepository _repository;

  Future<Result<void>> call(PublishHomeworkParams params) async {
    return _repository.publishHomework(params.homeworkId);
  }
}

// ═══════════════════════════════════════════════════════════════════════
// SUBMIT HOMEWORK
// ═══════════════════════════════════════════════════════════════════════

class SubmitHomeworkParams {
  const SubmitHomeworkParams({required this.submission});
  final HomeworkSubmissionEntity submission;
}

/// Use case that submits homework for a student.
///
/// Validates that [HomeworkSubmissionEntity.homeworkId] and
/// [HomeworkSubmissionEntity.studentId] are present, then delegates to
/// [SchoolManagementRepository.submitHomework].
class SubmitHomeworkUseCase {
  SubmitHomeworkUseCase(this._repository);
  final SchoolManagementRepository _repository;

  Future<Result<HomeworkSubmissionEntity>> call(
    SubmitHomeworkParams params,
  ) async {
    // ── Validate homeworkId ──────────────────────────────────────────────
    if (params.submission.homeworkId.trim().isEmpty) {
      return const FailureResult(
        Failure.validation(
          message: 'Homework ID is required',
          fieldErrors: {'homeworkId': 'Please provide a homework ID'},
        ),
      );
    }

    // ── Validate studentId ───────────────────────────────────────────────
    if (params.submission.studentId.trim().isEmpty) {
      return const FailureResult(
        Failure.validation(
          message: 'Student ID is required',
          fieldErrors: {'studentId': 'Please provide a student ID'},
        ),
      );
    }

    return _repository.submitHomework(params.submission);
  }
}

// ═══════════════════════════════════════════════════════════════════════
// GRADE SUBMISSION
// ═══════════════════════════════════════════════════════════════════════

class GradeSubmissionParams {
  const GradeSubmissionParams({required this.submission});
  final HomeworkSubmissionEntity submission;
}

/// Use case that grades a homework submission.
///
/// Validates that marks are non-negative and max marks are positive,
/// then delegates to [SchoolManagementRepository.gradeSubmission].
class GradeSubmissionUseCase {
  GradeSubmissionUseCase(this._repository);
  final SchoolManagementRepository _repository;

  Future<Result<HomeworkSubmissionEntity>> call(
    GradeSubmissionParams params,
  ) async {
    // ── Validate marksAwarded >= 0 ───────────────────────────────────────
    final marksAwarded = params.submission.marksAwarded;
    if (marksAwarded != null && marksAwarded < 0) {
      return const FailureResult(
        Failure.validation(
          message: 'Marks awarded cannot be negative',
          fieldErrors: {'marksAwarded': 'Marks awarded must be zero or greater'},
        ),
      );
    }

    // ── Validate maxMarks > 0 ────────────────────────────────────────────
    final maxMarks = params.submission.maxMarks;
    if (maxMarks == null || maxMarks <= 0) {
      return const FailureResult(
        Failure.validation(
          message: 'Maximum marks must be greater than zero',
          fieldErrors: {'maxMarks': 'Maximum marks must be a positive number'},
        ),
      );
    }

    return _repository.gradeSubmission(params.submission);
  }
}

// ═══════════════════════════════════════════════════════════════════════
// GET HOMEWORK SUBMISSIONS
// ═══════════════════════════════════════════════════════════════════════

class GetHomeworkSubmissionsParams {
  const GetHomeworkSubmissionsParams({required this.homeworkId});
  final String homeworkId;
}

/// Use case that retrieves all submissions for a given homework assignment.
///
/// Delegates to [SchoolManagementRepository.getHomeworkSubmissions].
class GetHomeworkSubmissionsUseCase {
  GetHomeworkSubmissionsUseCase(this._repository);
  final SchoolManagementRepository _repository;

  Future<Result<List<HomeworkSubmissionEntity>>> call(
    GetHomeworkSubmissionsParams params,
  ) async {
    return _repository.getHomeworkSubmissions(params.homeworkId);
  }
}
