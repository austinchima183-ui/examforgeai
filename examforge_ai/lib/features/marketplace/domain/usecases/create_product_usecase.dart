import '../../../../../core/errors/failures.dart';
import '../../../../../core/utils/result.dart';
import '../../entities/marketplace_entities.dart';
import '../../repositories/marketplace_repository.dart';

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
