import '../../../../core/utils/result.dart';
import '../../domain/repositories/marketplace_repository.dart';


class RemoveFromCartParams {
  const RemoveFromCartParams({required this.cartItemId});
  final String cartItemId;
}

class RemoveFromCartUseCase {
  RemoveFromCartUseCase(this._repository);
  final MarketplaceRepository _repository;

  Future<Result<bool>> call(RemoveFromCartParams params) async {
    return _repository.removeFromCart(params.cartItemId);
  }
}
