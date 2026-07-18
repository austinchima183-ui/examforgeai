import 'package:equatable/equatable.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/utils/result.dart';
import '../entities/communication_entities.dart';
import '../repositories/communication_repository.dart';

class GetForumsParams extends Equatable {
  const GetForumsParams({
    this.type,
    this.page = 1,
    this.perPage = 20,
  });

  final ForumType? type;
  final int page;
  final int perPage;

  @override
  List<Object?> get props => [type, page, perPage];
}

class GetForumsUseCase {
  GetForumsUseCase(this._repository);

  final CommunicationRepository _repository;

  Future<Result<List<DiscussionForumEntity>>> call(
    GetForumsParams params,
  ) async {
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

    return _repository.getForums(
      type: params.type,
      page: params.page,
      perPage: params.perPage,
    );
  }
}
