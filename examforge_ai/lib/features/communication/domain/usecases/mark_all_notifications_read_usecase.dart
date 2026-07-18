import '../../../../core/errors/failures.dart';
import '../../../../core/utils/result.dart';
import '../repositories/communication_repository.dart';

class MarkAllNotificationsReadUseCase {
  MarkAllNotificationsReadUseCase(this._repository);

  final CommunicationRepository _repository;

  Future<Result<void>> call() async {
    return _repository.markAllNotificationsRead();
  }
}
