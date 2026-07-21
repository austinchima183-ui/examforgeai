import '../../../../core/errors/failures.dart';
import '../../../../core/utils/result.dart';
import '../../domain/entities/marketplace_entities.dart';
import '../../data/repositories/marketplace_repository.dart';
import '../../../../features/marketplace/domain/repositories/marketplace_repository.dart';


class GetNotificationsParams {
  const GetNotificationsParams({
    required this.userId,
    this.unreadOnly = false,
    this.limit = 20,
  });
  final String userId;
  final bool unreadOnly;
  final int limit;
}

class GetNotificationsUseCase {
  GetNotificationsUseCase(this._repository);
  final MarketplaceRepository _repository;

  Future<Result<List<MarketplaceNotificationEntity>>> call(GetNotificationsParams params) async {
    return _repository.getUserNotifications(
      params.userId,
      unreadOnly: params.unreadOnly,
      limit: params.limit,
    );
  }
}
