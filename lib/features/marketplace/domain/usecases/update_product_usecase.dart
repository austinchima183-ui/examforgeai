import '../../../../core/utils/result.dart';
import '../../domain/entities/marketplace_entities.dart';
import '../../domain/repositories/marketplace_repository.dart';


class UpdateProductParams {
  const UpdateProductParams({required this.product});
  final MarketplaceProductEntity product;
}

class UpdateProductUseCase {
  UpdateProductUseCase(this._repository);
  final MarketplaceRepository _repository;

  Future<Result<MarketplaceProductEntity>> call(UpdateProductParams params) async {
    return _repository.updateProduct(params.product);
  }
}
