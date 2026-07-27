import 'package:equatable/equatable.dart';

import '../../../../core/utils/result.dart';
import '../entities/workspace_expansion_entities.dart';
import '../repositories/teacher_workspace_repository.dart';

/// Parameters for [GetTasksUseCase].
class GetTasksParams extends Equatable {
  const GetTasksParams({
    this.status,
    this.category,
    this.dueBefore,
  });

  final String? status;
  final String? category;
  final DateTime? dueBefore;

  @override
  List<Object?> get props => [status, category, dueBefore];
}

/// Use case for retrieving a filtered list of tasks.
///
/// Delegates directly to the [TeacherWorkspaceRepository] without
/// additional validation since all parameters are optional filters.
class GetTasksUseCase {
  GetTasksUseCase(this._repository);
  final TeacherWorkspaceRepository _repository;

  /// Retrieves a list of tasks matching the optional filter criteria.
  ///
  /// Returns a [Result] containing a list of [TaskEntity]
  /// on success, or a [FailureResult] if the repository
  /// encounters an error.
  Future<Result<List<TaskEntity>>> call(GetTasksParams params) {
    return _repository.getTasks(
      status: params.status,
      category: params.category,
      dueBefore: params.dueBefore,
    );
  }
}
