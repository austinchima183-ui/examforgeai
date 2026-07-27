import '../../../../core/utils/result.dart';
import '../../domain/entities/marketplace_entities.dart';
import '../../domain/repositories/marketplace_repository.dart';


class SuspendSellerParams {
  const SuspendSellerParams({required this.sellerId, required this.reason});
  final String sellerId;
  final String reason;
}

class SuspendSellerUseCase {
  SuspendSellerUseCase(this._repository);
  final MarketplaceRepository _repository;

  Future<Result<SellerProfileEntity>> call(SuspendSellerParams params) async {
    return _repository.suspendSeller(params.sellerId, params.reason);
  }
}
