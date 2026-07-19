import '../../../../../core/errors/failures.dart';
import '../../../../../core/utils/result.dart';
import '../../entities/marketplace_entities.dart';
import '../../repositories/marketplace_repository.dart';

class MarkNotificationReadParams {
  const MarkNotificationReadParams({required this.notificationId});
  final String notificationId;
}

class MarkNotificationReadUseCase {
  MarkNotificationReadUseCase(this._repository);
  final MarketplaceRepository _repository;

  Future<Result<bool>> call(MarkNotificationReadParams params) async {
    return _repository.markNotificationRead(params.notificationId);
  }
}
