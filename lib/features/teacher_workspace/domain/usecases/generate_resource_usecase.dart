import '../../../../core/errors/failures.dart';
import '../../../../core/utils/result.dart';
import '../entities/teacher_workspace_entities.dart';
import '../repositories/teacher_workspace_repository.dart';

/// Parameters for [GenerateResourceUseCase].
class GenerateResourceParams {
  const GenerateResourceParams({
    required this.resourceType,
    required this.subject,
    this.topic,
    this.className,
    this.curriculum,
  });

  final ResourceType resourceType;
  final String subject;
  final String? topic;
  final String? className;
  final CurriculumType? curriculum;
}

class GenerateResourceUseCase {
  GenerateResourceUseCase(this._repository);
  final TeacherWorkspaceRepository _repository;

  Future<Result<TeachingResourceEntity>> call(
    GenerateResourceParams params,
  ) async {
    if (params.subject.trim().isEmpty) {
      return const FailureResult(Failure.validation(
        message: 'Subject is required',
        fieldErrors: {'subject': 'Subject cannot be empty'},
      ),);
    }
    return _repository.generateResource({
      'resourceType': params.resourceType.value,
      'subject': params.subject,
      if (params.topic != null) 'topic': params.topic,
      if (params.className != null) 'className': params.className,
      if (params.curriculum != null) 'curriculum': params.curriculum!.value,
    });
  }
}
