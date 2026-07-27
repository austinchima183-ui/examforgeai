import '../../../../core/utils/result.dart';
import '../../domain/entities/marketplace_entities.dart';
import '../../domain/repositories/marketplace_repository.dart';


class UpdateCartItemParams {
  const UpdateCartItemParams({required this.item});
  final CartItemEntity item;
}

class UpdateCartItemUseCase {
  UpdateCartItemUseCase(this._repository);
  final MarketplaceRepository _repository;

  Future<Result<CartItemEntity>> call(UpdateCartItemParams params) async {
    return _repository.updateCartItem(params.item);
  }
}
