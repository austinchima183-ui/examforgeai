import '../../../../core/utils/result.dart';
import '../../domain/entities/marketplace_entities.dart';
import '../../domain/repositories/marketplace_repository.dart';


class GetFeaturedProductsParams {
  const GetFeaturedProductsParams({this.limit = 10});
  final int limit;
}

class GetFeaturedProductsUseCase {
  GetFeaturedProductsUseCase(this._repository);
  final MarketplaceRepository _repository;

  Future<Result<List<MarketplaceProductEntity>>> call(GetFeaturedProductsParams params) async {
    return _repository.getFeaturedProducts(limit: params.limit);
  }
}
