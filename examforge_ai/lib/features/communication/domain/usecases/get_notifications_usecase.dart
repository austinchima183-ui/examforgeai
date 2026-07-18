import 'package:equatable/equatable.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/utils/result.dart';
import '../entities/communication_entities.dart';
import '../repositories/communication_repository.dart';

class GetNotificationsParams extends Equatable {
  const GetNotificationsParams({
    this.category,
    this.isRead,
    this.page = 1,
    this.perPage = 20,
  });

  final String? category;
  final bool? isRead;
  final int page;
  final int perPage;

  @override
  List<Object?> get props => [category, isRead, page, perPage];
}

class GetNotificationsUseCase {
  GetNotificationsUseCase(this._repository);

  final CommunicationRepository _repository;

  Future<Result<List<CommunicationNotificationEntity>>> call(
    GetNotificationsParams params,
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

    return _repository.getNotifications(
      category: params.category,
      isRead: params.isRead,
      page: params.page,
      perPage: params.perPage,
    );
  }
}
