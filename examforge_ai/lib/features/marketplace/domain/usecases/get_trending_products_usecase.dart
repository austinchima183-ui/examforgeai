import '../../../../../core/errors/failures.dart';
import '../../../../../core/utils/result.dart';
import '../../entities/marketplace_entities.dart';
import '../../repositories/marketplace_repository.dart';

class GetTrendingProductsParams {
  const GetTrendingProductsParams({this.limit = 10});
  final int limit;
}

class GetTrendingProductsUseCase {
  GetTrendingProductsUseCase(this._repository);
  final MarketplaceRepository _repository;

  Future<Result<List<MarketplaceProductEntity>>> call(GetTrendingProductsParams params) async {
    return _repository.getTrendingProducts(limit: params.limit);
  }
}
