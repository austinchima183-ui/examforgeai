import '../../../../core/errors/failures.dart';
import '../../../../core/utils/result.dart';
import '../entities/teacher_workspace_entities.dart';
import '../repositories/teacher_workspace_repository.dart';

/// Parameters for [AiContentAssistantUseCase].
class AiContentAssistantParams {
  const AiContentAssistantParams({
    required this.action,
    required this.sourceContent,
    this.params,
  });

  final ContentAction action;
  final String sourceContent;
  final Map<String, dynamic>? params;
}

class AiContentAssistantUseCase {
  AiContentAssistantUseCase(this._repository);
  final TeacherWorkspaceRepository _repository;

  Future<Result<AiContentHistoryEntity>> call(
    AiContentAssistantParams params,
  ) async {
    if (params.sourceContent.trim().isEmpty) {
      return const FailureResult(Failure.validation(
        message: 'Source content is required',
        fieldErrors: {'sourceContent': 'Source content cannot be empty'},
      ),);
    }
    // Validate action is a valid ContentAction enum value.
    // Since [ContentAction] is already an enum, any instance is valid.
    // This check ensures forward compatibility if new values are added.
    final validActions = ContentAction.values.toSet();
    if (!validActions.contains(params.action)) {
      return const FailureResult(Failure.validation(
        message: 'Invalid content action',
        fieldErrors: {'action': 'Action must be a valid ContentAction'},
      ),);
    }
    return _repository.generateContent(
      params.action,
      params.sourceContent,
      params.params,
    );
  }
}
