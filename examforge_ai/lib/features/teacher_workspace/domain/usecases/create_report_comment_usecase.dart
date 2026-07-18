import '../../../../core/errors/failures.dart';
import '../../../../core/utils/result.dart';
import '../entities/teacher_workspace_entities.dart';
import '../repositories/teacher_workspace_repository.dart';

/// Parameters for [CreateReportCommentUseCase].
class CreateReportCommentParams {
  const CreateReportCommentParams({required this.comment});
  final ReportCommentEntity comment;
}

class CreateReportCommentUseCase {
  CreateReportCommentUseCase(this._repository);
  final TeacherWorkspaceRepository _repository;

  Future<Result<ReportCommentEntity>> call(
    CreateReportCommentParams params,
  ) async {
    if (params.comment.commentText.trim().isEmpty) {
      return const FailureResult(Failure.validation(
        message: 'Comment text is required',
        fieldErrors: {'commentText': 'Comment text cannot be empty'},
      ));
    }
    return _repository.createReportComment(params.comment);
  }
}
