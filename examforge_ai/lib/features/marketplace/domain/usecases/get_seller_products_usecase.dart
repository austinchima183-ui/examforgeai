import '../../../../../core/errors/failures.dart';
import '../../../../../core/utils/result.dart';
import '../../entities/marketplace_entities.dart';
import '../../repositories/marketplace_repository.dart';

class GetSellerProductsParams {
  const GetSellerProductsParams({required this.sellerId, this.limit = 20, this.offset = 0});
  final String sellerId;
  final int limit;
  final int offset;
}

class GetSellerProductsUseCase {
  GetSellerProductsUseCase(this._repository);
  final MarketplaceRepository _repository;

  Future<Result<List<MarketplaceProductEntity>>> call(GetSellerProductsParams params) async {
    return _repository.getSellerProducts(
      params.sellerId,
      limit: params.limit,
      offset: params.offset,
    );
  }
}
