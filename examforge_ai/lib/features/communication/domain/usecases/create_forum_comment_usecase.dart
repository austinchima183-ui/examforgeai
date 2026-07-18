import 'package:equatable/equatable.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/utils/result.dart';
import '../entities/communication_entities.dart';
import '../repositories/communication_repository.dart';

class CreateForumCommentParams extends Equatable {
  const CreateForumCommentParams({
    required this.postId,
    required this.forumId,
    required this.body,
    this.parentCommentId,
  });

  final String postId;
  final String forumId;
  final String body;
  final String? parentCommentId;

  @override
  List<Object?> get props => [postId, forumId, body, parentCommentId];
}

class CreateForumCommentUseCase {
  CreateForumCommentUseCase(this._repository);

  final CommunicationRepository _repository;

  Future<Result<ForumCommentEntity>> call(
    CreateForumCommentParams params,
  ) async {
    if (params.postId.trim().isEmpty) {
      return const FailureResult(
        Failure.validation(
          message: 'Post ID cannot be empty',
          fieldErrors: {'postId': 'Required'},
        ),
      );
    }

    if (params.forumId.trim().isEmpty) {
      return const FailureResult(
        Failure.validation(
          message: 'Forum ID cannot be empty',
          fieldErrors: {'forumId': 'Required'},
        ),
      );
    }

    if (params.body.trim().isEmpty) {
      return const FailureResult(
        Failure.validation(
          message: 'Comment body cannot be empty',
          fieldErrors: {'body': 'Body is required'},
        ),
      );
    }

    return _repository.createForumComment(
      postId: params.postId,
      forumId: params.forumId,
      body: params.body,
      parentCommentId: params.parentCommentId,
    );
  }
}
