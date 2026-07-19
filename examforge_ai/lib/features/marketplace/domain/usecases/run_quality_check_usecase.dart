import '../../../../../core/errors/failures.dart';
import '../../../../../core/utils/result.dart';
import '../../entities/marketplace_entities.dart';
import '../../repositories/marketplace_repository.dart';

class RunQualityCheckParams {
  const RunQualityCheckParams({required this.productId});
  final String productId;
}

class RunQualityCheckUseCase {
  RunQualityCheckUseCase(this._repository);
  final MarketplaceRepository _repository;

  Future<Result<QualityCheckEntity>> call(RunQualityCheckParams params) async {
    return _repository.runQualityCheck(params.productId);
  }
}
