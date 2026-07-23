import '../../../../core/utils/result.dart';
import '../../domain/entities/offline_entities.dart';
import '../../domain/repositories/offline_repository.dart';


/// Use case: get the current connectivity information.
///
/// No parameters required — this reads the device's current state.
class GetConnectivityInfoUseCase {
  GetConnectivityInfoUseCase(this._repository);
  final OfflineRepository _repository;

  Future<Result<ConnectivityInfo>> call() async {
    return _repository.getConnectivityInfo();
  }
}
