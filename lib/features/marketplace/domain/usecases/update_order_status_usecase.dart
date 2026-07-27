import '../../../../core/errors/failures.dart';
import '../../../../core/utils/result.dart';
import '../../domain/entities/marketplace_entities.dart';
import '../../domain/repositories/marketplace_repository.dart';


class UpdateOrderStatusParams {
  const UpdateOrderStatusParams({
    required this.orderId,
    required this.status,
  });
  final String orderId;
  final MarketplaceOrderStatus status;
}

class UpdateOrderStatusUseCase {
  UpdateOrderStatusUseCase(this._repository);
  final MarketplaceRepository _repository;

  Future<Result<MarketplaceOrderEntity>> call(UpdateOrderStatusParams params) async {
    if (params.orderId.isEmpty) {
      return const FailureResult(Failure.validation(fieldErrors: {}, message: 'Order ID is required'));
    }
    return _repository.updateOrderStatus(params.orderId, params.status);
  }
}
