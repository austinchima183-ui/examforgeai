import '../../../../core/errors/failures.dart';
import '../../../../core/utils/result.dart';
import '../../domain/entities/marketplace_entities.dart';
import '../../domain/repositories/marketplace_repository.dart';
import '../../../../features/marketplace/domain/repositories/marketplace_repository.dart';


class GetUserPurchasesParams {
  const GetUserPurchasesParams({required this.buyerId, this.limit = 20, this.offset = 0});
  final String buyerId;
  final int limit;
  final int offset;
}

class GetUserPurchasesUseCase {
  GetUserPurchasesUseCase(this._repository);
  final MarketplaceRepository _repository;

  Future<Result<List<MarketplacePurchaseEntity>>> call(GetUserPurchasesParams params) async {
    return _repository.getUserPurchases(
      params.buyerId,
      limit: params.limit,
      offset: params.offset,
    );
  }
}
