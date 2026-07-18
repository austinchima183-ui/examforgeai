import 'package:equatable/equatable.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/utils/result.dart';
import '../entities/workspace_expansion_entities.dart';
import '../repositories/teacher_workspace_repository.dart';

/// Parameters for [CreateRubricUseCase].
class CreateRubricParams extends Equatable {
  const CreateRubricParams({required this.rubric});
  final RubricEntity rubric;

  @override
  List<Object?> get props => [rubric];
}

/// Use case for creating a new rubric.
///
/// Validates that the [CreateRubricParams.rubric] title is not empty
/// before delegating to the [TeacherWorkspaceRepository].
class CreateRubricUseCase {
  CreateRubricUseCase(this._repository);
  final TeacherWorkspaceRepository _repository;

  /// Creates a new rubric from the provided [params].
  ///
  /// Returns a [Result] containing the persisted [RubricEntity]
  /// on success, or a [FailureResult] if validation fails or the
  /// repository encounters an error.
  Future<Result<RubricEntity>> call(CreateRubricParams params) async {
    if (params.rubric.title.trim().isEmpty) {
      return const FailureResult(Failure.validation(
        message: 'Rubric title is required',
        fieldErrors: {'title': 'Title cannot be empty'},
      ));
    }
    return _repository.createRubric(params.rubric);
  }
}
