import 'package:equatable/equatable.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/utils/result.dart';
import '../entities/workspace_expansion_entities.dart';
import '../repositories/teacher_workspace_repository.dart';

/// Parameters for [AddCommentUseCase].
class AddCommentParams extends Equatable {
  const AddCommentParams({
    required this.resourceType,
    required this.resourceId,
    required this.content,
    this.parentCommentId,
  });

  final String resourceType;
  final String resourceId;
  final String content;
  final String? parentCommentId;

  @override
  List<Object?> get props => [resourceType, resourceId, content, parentCommentId];

  /// Converts these params into a [Map<String, dynamic>] suitable for
  /// passing to [TeacherWorkspaceRepository.addComment].
  Map<String, dynamic> toMap() => {
    'resourceType': resourceType,
    'resourceId': resourceId,
    'content': content,
    'parentCommentId': parentCommentId,
  };
}

/// Use case for adding a comment to a workspace resource.
///
/// Validates that the [AddCommentParams.content] is not empty
/// before delegating to the [TeacherWorkspaceRepository].
class AddCommentUseCase {
  AddCommentUseCase(this._repository);
  final TeacherWorkspaceRepository _repository;

  /// Adds a comment to a resource based on the provided [params].
  ///
  /// Returns a [Result] containing the created [CollaborationCommentEntity]
  /// on success, or a [FailureResult] if validation fails or the
  /// repository encounters an error.
  Future<Result<CollaborationCommentEntity>> call(AddCommentParams params) async {
    if (params.content.trim().isEmpty) {
      return const FailureResult(Failure.validation(
        message: 'Comment content is required',
        fieldErrors: {'content': 'Content cannot be empty'},
      ));
    }
    return _repository.addComment(params.toMap());
  }
}
