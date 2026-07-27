import '../../../../core/utils/result.dart';
import '../../domain/entities/marketplace_entities.dart';
import '../../domain/repositories/marketplace_repository.dart';


class GetWishlistParams {
  const GetWishlistParams({required this.userId});
  final String userId;
}

class GetWishlistUseCase {
  GetWishlistUseCase(this._repository);
  final MarketplaceRepository _repository;

  Future<Result<List<WishlistEntity>>> call(GetWishlistParams params) async {
    return _repository.getUserWishlist(params.userId);
  }
}
