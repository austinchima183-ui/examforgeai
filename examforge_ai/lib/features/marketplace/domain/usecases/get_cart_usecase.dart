import '../../../../core/utils/result.dart';
import '../../domain/entities/marketplace_entities.dart';
import '../../domain/repositories/marketplace_repository.dart';


class GetCartParams {
  const GetCartParams({required this.userId});
  final String userId;
}

class GetCartUseCase {
  GetCartUseCase(this._repository);
  final MarketplaceRepository _repository;

  Future<Result<CartEntity>> call(GetCartParams params) async {
    return _repository.getCart(params.userId);
  }
}
