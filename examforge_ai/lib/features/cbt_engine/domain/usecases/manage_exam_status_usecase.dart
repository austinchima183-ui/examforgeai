import '../../../../core/errors/failures.dart';
import '../../../../core/utils/result.dart';
import '../entities/cbt_entities.dart';
import '../repositories/cbt_repository.dart';
import '../../../../features/cbt_engine/domain/entities/cbt_entities.dart';


/// The action to perform on an exam's status.
enum ManageStatusAction {
  publish,
  archive,
  clone,
  cancel,
}

/// Parameters for the [ManageExamStatusUseCase].
class ManageStatusParams {
  const ManageStatusParams({
    required this.examId,
    required this.action,
  });

  /// The ID of the exam to manage.
  final String examId;

  /// The status transition action to perform.
  final ManageStatusAction action;
}

/// Use case that manages exam lifecycle status transitions.
///
/// Each action has specific preconditions:
/// - **publish**: Exam must be in `draft` status with at least one question
/// - **archive**: Exam must be in `published`, `completed`, or `cancelled` status
/// - **clone**: Exam can be cloned from any non-archived status
/// - **cancel**: Exam must be in `draft` or `published` status
class ManageExamStatusUseCase {
  ManageExamStatusUseCase(this._repository);

  final CbtRepository _repository;

  Future<Result<ExamEntity>> call(ManageStatusParams params) async {
    // ── Retrieve current exam ─────────────────────────────────────────
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

    // ── Route to appropriate handler ──────────────────────────────────
    switch (params.action) {
      case ManageStatusAction.publish:
        return _handlePublish(exam);
      case ManageStatusAction.archive:
        return _handleArchive(exam);
      case ManageStatusAction.clone:
        return _handleClone(exam);
      case ManageStatusAction.cancel:
        return _handleCancel(exam);
    }
  }

  /// Publishes a draft exam, making it visible to assigned students.
  Future<Result<ExamEntity>> _handlePublish(ExamEntity exam) async {
    // ── Validate current status ───────────────────────────────────────
    if (exam.status != ExamStatus.draft) {
      return FailureResult(
        Failure.validation(
          message: 'Only draft exams can be published',
          fieldErrors: {
            'status':
                'Current status is ${exam.status.label}. Must be Draft to publish.',
          },
        ),
      );
    }

    // ── Validate exam has questions ───────────────────────────────────
    if (exam.questions.isEmpty) {
      return const FailureResult(
        Failure.validation(
          message: 'Cannot publish an exam without questions',
          fieldErrors: {
            'questions': 'Add at least one question before publishing',
          },
        ),
      );
    }

    // ── Validate exam has students assigned ───────────────────────────
    // Note: ExamEntity doesn't have a direct students list in the
    // loaded entity, but the repository handles this check during
    // the publish operation.

    // ── Validate exam time window ─────────────────────────────────────
    if (exam.endTime.isBefore(DateTime.now())) {
      return const FailureResult(
        Failure.validation(
          message: 'Cannot publish an exam with a past end time',
          fieldErrors: {
            'endTime': 'The exam end time must be in the future',
          },
        ),
      );
    }

    return _repository.publishExam(exam.id);
  }

  /// Archives an exam, removing it from active lists.
  Future<Result<ExamEntity>> _handleArchive(ExamEntity exam) async {
    // ── Validate current status ───────────────────────────────────────
    final archivableStatuses = {
      ExamStatus.published,
      ExamStatus.completed,
      ExamStatus.cancelled,
    };

    if (!archivableStatuses.contains(exam.status)) {
      return FailureResult(
        Failure.validation(
          message: 'Exam cannot be archived from ${exam.status.label} status',
          fieldErrors: {
            'status':
                'Only published, completed, or cancelled exams can be archived',
          },
        ),
      );
    }

    return _repository.archiveExam(exam.id);
  }

  /// Creates a deep copy of an exam with a new ID and draft status.
  Future<Result<ExamEntity>> _handleClone(ExamEntity exam) async {
    // ── Validate exam is not archived ─────────────────────────────────
    if (exam.status == ExamStatus.archived) {
      return const FailureResult(
        Failure.validation(
          message: 'Cannot clone an archived exam',
          fieldErrors: {
            'status': 'Restore the exam before cloning',
          },
        ),
      );
    }

    return _repository.cloneExam(exam.id);
  }

  /// Cancels an exam, preventing further attempts.
  Future<Result<ExamEntity>> _handleCancel(ExamEntity exam) async {
    // ── Validate current status ───────────────────────────────────────
    final cancellableStatuses = {ExamStatus.draft, ExamStatus.published};

    if (!cancellableStatuses.contains(exam.status)) {
      return FailureResult(
        Failure.validation(
          message: 'Exam cannot be cancelled from ${exam.status.label} status',
          fieldErrors: {
            'status': 'Only draft or published exams can be cancelled',
          },
        ),
      );
    }

    // Update the exam status to cancelled
    final updatedExam = exam.copyWith(
      status: ExamStatus.cancelled,
      updatedAt: DateTime.now(),
    );

    return _repository.updateExam(updatedExam);
  }
}
