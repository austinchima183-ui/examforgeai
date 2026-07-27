import '../../../../core/errors/failures.dart';
import '../../../../core/utils/result.dart';
import '../entities/teacher_workspace_entities.dart';
import '../repositories/teacher_workspace_repository.dart';

/// Parameters for [GenerateSchemeOfWorkUseCase].
class GenerateSchemeOfWorkParams {
  const GenerateSchemeOfWorkParams({
    required this.subject,
    required this.className,
    required this.curriculum,
    required this.durationType,
    this.term,
  });

  final String subject;
  final String className;
  final CurriculumType curriculum;
  final PlanDuration durationType;
  final String? term;
}

class GenerateSchemeOfWorkUseCase {
  GenerateSchemeOfWorkUseCase(this._repository);
  final TeacherWorkspaceRepository _repository;

  Future<Result<SchemeOfWorkEntity>> call(
    GenerateSchemeOfWorkParams params,
  ) async {
    if (params.subject.trim().isEmpty) {
      return const FailureResult(Failure.validation(
        message: 'Subject is required',
        fieldErrors: {'subject': 'Subject cannot be empty'},
      ),);
    }
    return _repository.generateSchemeOfWork({
      'subject': params.subject,
      'className': params.className,
      'curriculum': params.curriculum.value,
      'durationType': params.durationType.value,
      if (params.term != null) 'term': params.term,
    });
  }
}
