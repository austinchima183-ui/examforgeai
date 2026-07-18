import 'package:equatable/equatable.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/utils/result.dart';
import '../entities/communication_entities.dart';
import '../repositories/communication_repository.dart';

class GetAnnouncementsParams extends Equatable {
  const GetAnnouncementsParams({
    this.type,
    this.priority,
    this.publishedOnly = true,
    this.page = 1,
    this.perPage = 20,
  });

  final String? type;
  final String? priority;
  final bool publishedOnly;
  final int page;
  final int perPage;

  @override
  List<Object?> get props => [type, priority, publishedOnly, page, perPage];
}

class GetAnnouncementsUseCase {
  GetAnnouncementsUseCase(this._repository);

  final CommunicationRepository _repository;

  Future<Result<List<AnnouncementEntity>>> call(
    GetAnnouncementsParams params,
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

    return _repository.getAnnouncements(
      type: params.type,
      priority: params.priority,
      publishedOnly: params.publishedOnly,
      page: params.page,
      perPage: params.perPage,
    );
  }
}
