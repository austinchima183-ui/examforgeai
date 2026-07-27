import '../../../../core/utils/result.dart';
import '../entities/communication_entities.dart';
import '../repositories/communication_repository.dart';

class GetCommunicationDashboardUseCase {
  GetCommunicationDashboardUseCase(this._repository);

  final CommunicationRepository _repository;

  Future<Result<CommunicationDashboardEntity>> call() async {
    return _repository.getCommunicationDashboard();
  }
}
