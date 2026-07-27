import 'package:equatable/equatable.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/utils/result.dart';
import '../repositories/teacher_workspace_repository.dart';

/// Parameters for [DeleteTaskUseCase].
class DeleteTaskParams extends Equatable {
  const DeleteTaskParams({required this.taskId});
  final String taskId;

  @override
  List<Object?> get props => [taskId];
}

/// Use case for permanently deleting a task.
///
/// Validates that the [DeleteTaskParams.taskId] is not empty
/// before delegating to the [TeacherWorkspaceRepository].
class DeleteTaskUseCase {
  DeleteTaskUseCase(this._repository);
  final TeacherWorkspaceRepository _repository;

  /// Deletes a task identified by [params].
  ///
  /// Returns a [Result] containing `void` on success, or a
  /// [FailureResult] if validation fails or the repository
  /// encounters an error.
  Future<Result<void>> call(DeleteTaskParams params) async {
    if (params.taskId.trim().isEmpty) {
      return const FailureResult(Failure.validation(
        message: 'Task ID is required',
        fieldErrors: {'taskId': 'Task ID cannot be empty'},
      ),);
    }
    return _repository.deleteTask(params.taskId);
  }
}
