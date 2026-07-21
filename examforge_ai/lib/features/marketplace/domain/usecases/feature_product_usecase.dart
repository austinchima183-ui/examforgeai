import '../../../../core/errors/failures.dart';
import '../../../../core/utils/result.dart';
import '../../domain/entities/marketplace_entities.dart';
import '../../data/repositories/marketplace_repository.dart';
import '../../../../features/marketplace/domain/repositories/marketplace_repository.dart';


class FeatureProductParams {
  const FeatureProductParams({required this.productId, required this.featured});
  final String productId;
  final bool featured;
}

class FeatureProductUseCase {
  FeatureProductUseCase(this._repository);
  final MarketplaceRepository _repository;

  Future<Result<MarketplaceProductEntity>> call(FeatureProductParams params) async {
    return _repository.featureProduct(params.productId, params.featured);
  }
}
