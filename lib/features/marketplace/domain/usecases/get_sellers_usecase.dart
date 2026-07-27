import '../../../../core/utils/result.dart';
import '../../domain/entities/marketplace_entities.dart';
import '../../domain/repositories/marketplace_repository.dart';


class GetSellersParams {
  const GetSellersParams({this.status, this.limit = 20, this.offset = 0});
  final MarketplaceSellerStatus? status;
  final int limit;
  final int offset;
}

class GetSellersUseCase {
  GetSellersUseCase(this._repository);
  final MarketplaceRepository _repository;

  Future<Result<List<SellerProfileEntity>>> call(GetSellersParams params) async {
    return _repository.getSellers(
      status: params.status,
      limit: params.limit,
      offset: params.offset,
    );
  }
}
