import '../../../../core/errors/failures.dart';
import '../../../../core/utils/result.dart';
import '../../domain/entities/marketplace_entities.dart';
import '../../domain/repositories/marketplace_repository.dart';
import '../../../../features/marketplace/domain/repositories/marketplace_repository.dart';


class GetUserOrdersParams {
  const GetUserOrdersParams({required this.buyerId, this.limit = 20, this.offset = 0});
  final String buyerId;
  final int limit;
  final int offset;
}

class GetUserOrdersUseCase {
  GetUserOrdersUseCase(this._repository);
  final MarketplaceRepository _repository;

  Future<Result<List<MarketplaceOrderEntity>>> call(GetUserOrdersParams params) async {
    return _repository.getUserOrders(
      params.buyerId,
      limit: params.limit,
      offset: params.offset,
    );
  }
}
