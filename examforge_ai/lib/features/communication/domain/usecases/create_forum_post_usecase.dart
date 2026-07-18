import 'package:equatable/equatable.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/utils/result.dart';
import '../entities/communication_entities.dart';
import '../repositories/communication_repository.dart';

class CreateForumPostParams extends Equatable {
  const CreateForumPostParams({
    required this.forumId,
    required this.title,
    required this.body,
    this.attachments,
  });

  final String forumId;
  final String title;
  final String body;
  final List<Map<String, dynamic>>? attachments;

  @override
  List<Object?> get props => [forumId, title, body, attachments];
}

class CreateForumPostUseCase {
  CreateForumPostUseCase(this._repository);

  final CommunicationRepository _repository;

  Future<Result<ForumPostEntity>> call(CreateForumPostParams params) async {
    if (params.forumId.trim().isEmpty) {
      return const FailureResult(
        Failure.validation(
          message: 'Forum ID cannot be empty',
          fieldErrors: {'forumId': 'Required'},
        ),
      );
    }

    if (params.title.trim().isEmpty) {
      return const FailureResult(
        Failure.validation(
          message: 'Post title cannot be empty',
          fieldErrors: {'title': 'Title is required'},
        ),
      );
    }

    if (params.body.trim().isEmpty) {
      return const FailureResult(
        Failure.validation(
          message: 'Post body cannot be empty',
          fieldErrors: {'body': 'Body is required'},
        ),
      );
    }

    return _repository.createForumPost(
      forumId: params.forumId,
      title: params.title,
      body: params.body,
      attachments: params.attachments,
    );
  }
}
