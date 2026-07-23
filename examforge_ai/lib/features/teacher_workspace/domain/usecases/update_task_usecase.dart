import 'package:equatable/equatable.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/utils/result.dart';
import '../entities/workspace_expansion_entities.dart';
import '../repositories/teacher_workspace_repository.dart';

/// Parameters for [UpdateTaskUseCase].
class UpdateTaskParams extends Equatable {
  const UpdateTaskParams({required this.task});
  final TaskEntity task;

  @override
  List<Object?> get props => [task];
}

/// Use case for updating an existing task.
///
/// Validates that the [UpdateTaskParams.task] id is not empty
/// before delegating to the [TeacherWorkspaceRepository].
class UpdateTaskUseCase {
  UpdateTaskUseCase(this._repository);
  final TeacherWorkspaceRepository _repository;

  /// Updates a task with the provided [params].
  ///
  /// Returns a [Result] containing the updated [TaskEntity]
  /// on success, or a [FailureResult] if validation fails or the
  /// repository encounters an error.
  Future<Result<TaskEntity>> call(UpdateTaskParams params) async {
    if (params.task.id.trim().isEmpty) {
      return const FailureResult(Failure.validation(
        message: 'Task ID is required',
        fieldErrors: {'id': 'Task ID cannot be empty'},
      ),);
    }
    return _repository.updateTask(params.task);
  }
}
