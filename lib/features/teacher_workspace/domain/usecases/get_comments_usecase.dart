import 'package:equatable/equatable.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/utils/result.dart';
import '../entities/workspace_expansion_entities.dart';
import '../repositories/teacher_workspace_repository.dart';

/// Parameters for [GetCommentsUseCase].
class GetCommentsParams extends Equatable {
  const GetCommentsParams({
    required this.resourceType,
    required this.resourceId,
  });

  final String resourceType;
  final String resourceId;

  @override
  List<Object?> get props => [resourceType, resourceId];
}

/// Use case for retrieving comments on a workspace resource.
///
/// Validates that both [GetCommentsParams.resourceType] and
/// [GetCommentsParams.resourceId] are not empty before delegating
/// to the [TeacherWorkspaceRepository].
class GetCommentsUseCase {
  GetCommentsUseCase(this._repository);
  final TeacherWorkspaceRepository _repository;

  /// Retrieves comments for the specified resource.
  ///
  /// Returns a [Result] containing a list of [CollaborationCommentEntity]
  /// on success, or a [FailureResult] if validation fails or the
  /// repository encounters an error.
  Future<Result<List<CollaborationCommentEntity>>> call(GetCommentsParams params) async {
    if (params.resourceType.trim().isEmpty) {
      return const FailureResult(Failure.validation(
        message: 'Resource type is required',
        fieldErrors: {'resourceType': 'Resource type cannot be empty'},
      ),);
    }
    if (params.resourceId.trim().isEmpty) {
      return const FailureResult(Failure.validation(
        message: 'Resource ID is required',
        fieldErrors: {'resourceId': 'Resource ID cannot be empty'},
      ),);
    }
    return _repository.getComments(params.resourceType, params.resourceId);
  }
}
