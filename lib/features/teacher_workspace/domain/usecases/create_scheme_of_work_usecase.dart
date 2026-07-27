import '../../../../core/errors/failures.dart';
import '../../../../core/utils/result.dart';
import '../entities/teacher_workspace_entities.dart';
import '../repositories/teacher_workspace_repository.dart';

/// Parameters for [CreateSchemeOfWorkUseCase].
class CreateSchemeOfWorkParams {
  const CreateSchemeOfWorkParams({required this.scheme});
  final SchemeOfWorkEntity scheme;
}

class CreateSchemeOfWorkUseCase {
  CreateSchemeOfWorkUseCase(this._repository);
  final TeacherWorkspaceRepository _repository;

  Future<Result<SchemeOfWorkEntity>> call(
    CreateSchemeOfWorkParams params,
  ) async {
    if (params.scheme.title.trim().isEmpty) {
      return const FailureResult(Failure.validation(
        message: 'Scheme of work title is required',
        fieldErrors: {'title': 'Title cannot be empty'},
      ),);
    }
    return _repository.createSchemeOfWork(params.scheme);
  }
}
