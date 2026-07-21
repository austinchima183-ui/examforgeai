import '../../../../core/errors/failures.dart';
import '../../../../core/utils/result.dart';
import '../../domain/entities/marketplace_entities.dart';
import '../../domain/repositories/marketplace_repository.dart';
import '../../../../features/marketplace/domain/repositories/marketplace_repository.dart';


class ClearCartParams {
  const ClearCartParams({required this.userId});
  final String userId;
}

class ClearCartUseCase {
  ClearCartUseCase(this._repository);
  final MarketplaceRepository _repository;

  Future<Result<bool>> call(ClearCartParams params) async {
    return _repository.clearCart(params.userId);
  }
}
