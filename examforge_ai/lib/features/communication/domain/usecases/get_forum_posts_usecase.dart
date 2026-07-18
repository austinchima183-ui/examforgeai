import 'package:equatable/equatable.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/utils/result.dart';
import '../entities/communication_entities.dart';
import '../repositories/communication_repository.dart';

class GetForumPostsParams extends Equatable {
  const GetForumPostsParams({
    required this.forumId,
    this.page = 1,
    this.perPage = 20,
  });

  final String forumId;
  final int page;
  final int perPage;

  @override
  List<Object?> get props => [forumId, page, perPage];
}

class GetForumPostsUseCase {
  GetForumPostsUseCase(this._repository);

  final CommunicationRepository _repository;

  Future<Result<List<ForumPostEntity>>> call(GetForumPostsParams params) async {
    if (params.forumId.trim().isEmpty) {
      return const FailureResult(
        Failure.validation(
          message: 'Forum ID cannot be empty',
          fieldErrors: {'forumId': 'Required'},
        ),
      );
    }

    if (params.page < 1) {
      return const FailureResult(
        Failure.validation(
          message: 'Page must be >= 1',
          fieldErrors: {'page': 'Invalid page'},
        ),
      );
    }

    if (params.perPage < 1 || params.perPage > 100) {
      return const FailureResult(
        Failure.validation(
          message: 'PerPage must be between 1 and 100',
          fieldErrors: {'perPage': 'Invalid perPage'},
        ),
      );
    }

    return _repository.getForumPosts(
      forumId: params.forumId,
      page: params.page,
      perPage: params.perPage,
    );
  }
}
