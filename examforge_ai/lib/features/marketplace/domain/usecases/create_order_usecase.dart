import '../../../../../core/errors/failures.dart';
import '../../../../../core/utils/result.dart';
import '../../entities/marketplace_entities.dart';
import '../../repositories/marketplace_repository.dart';

class CreateOrderParams {
  const CreateOrderParams({required this.order});
  final MarketplaceOrderEntity order;
}

class CreateOrderUseCase {
  CreateOrderUseCase(this._repository);
  final MarketplaceRepository _repository;

  Future<Result<MarketplaceOrderEntity>> call(CreateOrderParams params) async {
    return _repository.createOrder(params.order);
  }
}
