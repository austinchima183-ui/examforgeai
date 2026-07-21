import '../../../../core/errors/failures.dart';
import '../../../../core/utils/result.dart';
import '../../domain/entities/marketplace_entities.dart';
import '../../data/repositories/marketplace_repository.dart';
import '../../../../features/marketplace/domain/repositories/marketplace_repository.dart';


class UpdateSellerStatusParams {
  const UpdateSellerStatusParams({required this.sellerId, required this.status});
  final String sellerId;
  final MarketplaceSellerStatus status;
}

class UpdateSellerStatusUseCase {
  UpdateSellerStatusUseCase(this._repository);
  final MarketplaceRepository _repository;

  Future<Result<SellerProfileEntity>> call(UpdateSellerStatusParams params) async {
    return _repository.updateSellerStatus(params.sellerId, params.status);
  }
}
