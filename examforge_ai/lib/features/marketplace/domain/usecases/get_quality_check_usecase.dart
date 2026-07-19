import '../../../../../core/errors/failures.dart';
import '../../../../../core/utils/result.dart';
import '../../entities/marketplace_entities.dart';
import '../../repositories/marketplace_repository.dart';

class GetQualityCheckParams {
  const GetQualityCheckParams({required this.productId});
  final String productId;
}

class GetQualityCheckUseCase {
  GetQualityCheckUseCase(this._repository);
  final MarketplaceRepository _repository;

  Future<Result<QualityCheckEntity>> call(GetQualityCheckParams params) async {
    return _repository.getQualityCheck(params.productId);
  }
}
