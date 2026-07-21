import '../../../../core/errors/failures.dart';
import '../../../../core/utils/result.dart';
import '../../domain/entities/marketplace_entities.dart';
import '../../domain/repositories/marketplace_repository.dart';
import '../../../../features/marketplace/domain/repositories/marketplace_repository.dart';


class GetDisputesParams {
  const GetDisputesParams({
    this.orderId,
    this.buyerId,
    this.sellerId,
    this.status,
  });
  final String? orderId;
  final String? buyerId;
  final String? sellerId;
  final DisputeStatus? status;
}

class GetDisputesUseCase {
  GetDisputesUseCase(this._repository);
  final MarketplaceRepository _repository;

  Future<Result<List<DisputeEntity>>> call(GetDisputesParams params) async {
    return _repository.getDisputes(
      orderId: params.orderId,
      buyerId: params.buyerId,
      sellerId: params.sellerId,
      status: params.status,
    );
  }
}
