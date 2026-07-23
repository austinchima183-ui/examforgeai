import '../../../../core/errors/failures.dart';
import '../../../../core/utils/result.dart';
import '../../domain/entities/marketplace_entities.dart';
import '../../domain/repositories/marketplace_repository.dart';


class GetProductParams {
  const GetProductParams({this.productId, this.slug});
  final String? productId;
  final String? slug;
}

class GetProductUseCase {
  GetProductUseCase(this._repository);
  final MarketplaceRepository _repository;

  Future<Result<MarketplaceProductEntity>> call(GetProductParams params) async {
    if (params.productId != null) {
      return _repository.getProduct(params.productId!);
    }
    if (params.slug != null) {
      return _repository.getProductBySlug(params.slug!);
    }
    return const FailureResult(ServerFailure(message: 'Either productId or slug must be provided', statusCode: 400));
  }
}
