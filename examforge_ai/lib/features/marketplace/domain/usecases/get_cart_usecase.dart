import '../../../../core/errors/failures.dart';
import '../../../../core/utils/result.dart';
import '../../domain/entities/marketplace_entities.dart';
import '../../data/repositories/marketplace_repository.dart';
import '../../../../features/marketplace/domain/repositories/marketplace_repository.dart';


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
