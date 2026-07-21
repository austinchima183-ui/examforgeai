import '../../../../core/errors/failures.dart';
import '../../../../core/utils/result.dart';
import '../../domain/entities/marketplace_entities.dart';
import '../../domain/repositories/marketplace_repository.dart';
import '../../../../features/marketplace/domain/repositories/marketplace_repository.dart';


class DeleteProductParams {
  const DeleteProductParams({required this.productId});
  final String productId;
}

class DeleteProductUseCase {
  DeleteProductUseCase(this._repository);
  final MarketplaceRepository _repository;

  Future<Result<bool>> call(DeleteProductParams params) async {
    return _repository.deleteProduct(params.productId);
  }
}
