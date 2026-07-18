import '../../../../core/errors/failures.dart';
import '../../../../core/utils/result.dart';
import '../repositories/teacher_workspace_repository.dart';

/// Parameters for [GenerateQuestionsFromContentUseCase].
class GenerateQuestionsFromContentParams {
  const GenerateQuestionsFromContentParams({
    required this.resourceType,
    required this.resourceId,
    this.questionCount,
    this.difficulty,
    this.questionTypes,
  });

  final String resourceType;
  final String resourceId;
  final int? questionCount;
  final String? difficulty;
  final List<String>? questionTypes;
}

class GenerateQuestionsFromContentUseCase {
  GenerateQuestionsFromContentUseCase(this._repository);
  final TeacherWorkspaceRepository _repository;

  Future<Result<Map<String, dynamic>>> call(
    GenerateQuestionsFromContentParams params,
  ) async {
    if (params.resourceType.trim().isEmpty) {
      return const FailureResult(Failure.validation(
        message: 'Resource type is required',
        fieldErrors: {'resourceType': 'Resource type cannot be empty'},
      ));
    }
    if (params.resourceId.trim().isEmpty) {
      return const FailureResult(Failure.validation(
        message: 'Resource ID is required',
        fieldErrors: {'resourceId': 'Resource ID cannot be empty'},
      ));
    }
    return _repository.generateQuestionsFromContent(
      params.resourceType,
      params.resourceId,
      {
        if (params.questionCount != null)
          'questionCount': params.questionCount,
        if (params.difficulty != null) 'difficulty': params.difficulty,
        if (params.questionTypes != null)
          'questionTypes': params.questionTypes,
      },
    );
  }
}
