import '../../../../core/errors/failures.dart';
import '../../../../core/utils/result.dart';
import '../../domain/entities/marketplace_entities.dart';
import '../../domain/repositories/marketplace_repository.dart';
import '../../../../features/marketplace/domain/repositories/marketplace_repository.dart';


class CreateProductParams {
  const CreateProductParams({required this.product});
  final MarketplaceProductEntity product;
}

class CreateProductUseCase {
  CreateProductUseCase(this._repository);
  final MarketplaceRepository _repository;

  Future<Result<MarketplaceProductEntity>> call(CreateProductParams params) async {
    return _repository.createProduct(params.product);
  }
}
