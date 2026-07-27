import '../../../../core/utils/result.dart';
import '../../domain/entities/marketplace_entities.dart';
import '../../domain/repositories/marketplace_repository.dart';


class AddToCartParams {
  const AddToCartParams({required this.userId, required this.item});
  final String userId;
  final CartItemEntity item;
}

class AddToCartUseCase {
  AddToCartUseCase(this._repository);
  final MarketplaceRepository _repository;

  Future<Result<CartEntity>> call(AddToCartParams params) async {
    return _repository.addToCart(params.userId, params.item);
  }
}
