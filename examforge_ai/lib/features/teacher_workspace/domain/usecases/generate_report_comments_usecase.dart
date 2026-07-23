import '../../../../core/errors/failures.dart';
import '../../../../core/utils/result.dart';
import '../entities/teacher_workspace_entities.dart';
import '../repositories/teacher_workspace_repository.dart';

/// Parameters for [GenerateReportCommentsUseCase].
class GenerateReportCommentsParams {
  const GenerateReportCommentsParams({
    required this.classId,
    this.subjectId,
    this.academicSessionId,
    this.studentIds,
  });

  final String classId;
  final String? subjectId;
  final String? academicSessionId;
  final List<String>? studentIds;
}

class GenerateReportCommentsUseCase {
  GenerateReportCommentsUseCase(this._repository);
  final TeacherWorkspaceRepository _repository;

  Future<Result<List<ReportCommentEntity>>> call(
    GenerateReportCommentsParams params,
  ) async {
    if (params.classId.trim().isEmpty) {
      return const FailureResult(Failure.validation(
        message: 'Class ID is required',
        fieldErrors: {'classId': 'Class ID cannot be empty'},
      ),);
    }
    return _repository.generateReportComments({
      'classId': params.classId,
      if (params.subjectId != null) 'subjectId': params.subjectId,
      if (params.academicSessionId != null)
        'academicSessionId': params.academicSessionId,
      if (params.studentIds != null) 'studentIds': params.studentIds,
    });
  }
}
