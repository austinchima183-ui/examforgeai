import '../../../../core/errors/failures.dart';
import '../../../../core/utils/result.dart';
import '../../domain/entities/marketplace_entities.dart';
import '../../domain/repositories/marketplace_repository.dart';
import '../../../../features/marketplace/domain/repositories/marketplace_repository.dart';


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
