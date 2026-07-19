import '../../../../../core/errors/failures.dart';
import '../../../../../core/utils/result.dart';
import '../../entities/marketplace_entities.dart';
import '../../repositories/marketplace_repository.dart';

class UpdateProductStatusParams {
  const UpdateProductStatusParams({required this.productId, required this.status});
  final String productId;
  final MarketplaceProductStatus status;
}

class UpdateProductStatusUseCase {
  UpdateProductStatusUseCase(this._repository);
  final MarketplaceRepository _repository;

  Future<Result<MarketplaceProductEntity>> call(UpdateProductStatusParams params) async {
    return _repository.updateProductStatus(params.productId, params.status);
  }
}
