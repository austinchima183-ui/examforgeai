import '../../../../core/utils/result.dart';
import '../../domain/entities/marketplace_entities.dart';
import '../../domain/repositories/marketplace_repository.dart';


class GetRelatedProductsParams {
  const GetRelatedProductsParams({required this.productId, this.limit = 10});
  final String productId;
  final int limit;
}

class GetRelatedProductsUseCase {
  GetRelatedProductsUseCase(this._repository);
  final MarketplaceRepository _repository;

  Future<Result<List<MarketplaceProductEntity>>> call(GetRelatedProductsParams params) async {
    return _repository.getRelatedProducts(params.productId, limit: params.limit);
  }
}
