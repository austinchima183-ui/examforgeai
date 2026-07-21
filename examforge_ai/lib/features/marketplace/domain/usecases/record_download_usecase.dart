import '../../../../core/errors/failures.dart';
import '../../../../core/utils/result.dart';
import '../../domain/entities/marketplace_entities.dart';
import '../../domain/repositories/marketplace_repository.dart';
import '../../../../features/marketplace/domain/repositories/marketplace_repository.dart';


class RecordDownloadParams {
  const RecordDownloadParams({required this.purchaseId});
  final String purchaseId;
}

class RecordDownloadUseCase {
  RecordDownloadUseCase(this._repository);
  final MarketplaceRepository _repository;

  Future<Result<bool>> call(RecordDownloadParams params) async {
    return _repository.recordDownload(params.purchaseId);
  }
}
