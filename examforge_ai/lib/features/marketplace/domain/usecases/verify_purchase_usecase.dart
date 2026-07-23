import '../../../../core/utils/result.dart';
import '../../domain/repositories/marketplace_repository.dart';


class VerifyPurchaseParams {
  const VerifyPurchaseParams({required this.buyerId, required this.productId});
  final String buyerId;
  final String productId;
}

class VerifyPurchaseUseCase {
  VerifyPurchaseUseCase(this._repository);
  final MarketplaceRepository _repository;

  Future<Result<bool>> call(VerifyPurchaseParams params) async {
    return _repository.verifyPurchase(params.buyerId, params.productId);
  }
}
