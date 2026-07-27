import '../../../../core/utils/result.dart';
import '../entities/communication_entities.dart';
import '../repositories/communication_repository.dart';

class GetNotificationPreferencesUseCase {
  GetNotificationPreferencesUseCase(this._repository);

  final CommunicationRepository _repository;

  Future<Result<NotificationPreferencesEntity>> call() async {
    return _repository.getNotificationPreferences();
  }
}
