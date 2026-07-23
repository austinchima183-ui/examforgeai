import 'package:equatable/equatable.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/utils/result.dart';
import '../entities/workspace_expansion_entities.dart';
import '../repositories/teacher_workspace_repository.dart';

/// Parameters for [CreateTaskUseCase].
class CreateTaskParams extends Equatable {
  const CreateTaskParams({required this.task});
  final TaskEntity task;

  @override
  List<Object?> get props => [task];
}

/// Use case for creating a new task.
///
/// Validates that the [CreateTaskParams.task] title is not empty
/// before delegating to the [TeacherWorkspaceRepository].
class CreateTaskUseCase {
  CreateTaskUseCase(this._repository);
  final TeacherWorkspaceRepository _repository;

  /// Creates a new task from the provided [params].
  ///
  /// Returns a [Result] containing the persisted [TaskEntity]
  /// on success, or a [FailureResult] if validation fails or the
  /// repository encounters an error.
  Future<Result<TaskEntity>> call(CreateTaskParams params) async {
    if (params.task.title.trim().isEmpty) {
      return const FailureResult(Failure.validation(
        message: 'Task title is required',
        fieldErrors: {'title': 'Title cannot be empty'},
      ),);
    }
    return _repository.createTask(params.task);
  }
}
