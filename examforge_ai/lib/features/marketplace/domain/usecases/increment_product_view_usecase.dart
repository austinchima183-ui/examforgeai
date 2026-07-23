import '../../../../core/errors/failures.dart';
import '../../../../core/utils/result.dart';
import '../../domain/repositories/marketplace_repository.dart';


class IncrementProductViewParams {
  const IncrementProductViewParams({required this.productId});
  final String productId;
}

class IncrementProductViewUseCase {
  IncrementProductViewUseCase(this._repository);
  final MarketplaceRepository _repository;

  Future<Result<bool>> call(IncrementProductViewParams params) async {
    if (params.productId.isEmpty) {
      return const FailureResult(Failure.validation(fieldErrors: {}, message: 'Product ID is required'));
    }
    return _repository.incrementProductView(params.productId);
  }
}
