import '../../../../core/errors/failures.dart';
import '../../../../core/utils/result.dart';
import '../../domain/entities/marketplace_entities.dart';
import '../../domain/repositories/marketplace_repository.dart';
import '../../../../features/marketplace/domain/repositories/marketplace_repository.dart';


class GetOrderParams {
  const GetOrderParams({this.orderId, this.orderNumber});
  final String? orderId;
  final String? orderNumber;
}

class GetOrderUseCase {
  GetOrderUseCase(this._repository);
  final MarketplaceRepository _repository;

  Future<Result<MarketplaceOrderEntity>> call(GetOrderParams params) async {
    if (params.orderId != null) {
      return _repository.getOrder(params.orderId!);
    }
    if (params.orderNumber != null) {
      return _repository.getOrderByNumber(params.orderNumber!);
    }
    return FailureResult(ServerFailure('Either orderId or orderNumber must be provided'));
  }
}
