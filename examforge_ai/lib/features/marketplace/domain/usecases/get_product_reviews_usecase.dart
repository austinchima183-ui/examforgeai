import '../../../../core/errors/failures.dart';
import '../../../../core/utils/result.dart';
import '../../domain/entities/marketplace_entities.dart';
import '../../domain/repositories/marketplace_repository.dart';
import '../../../../features/marketplace/domain/repositories/marketplace_repository.dart';


class GetProductReviewsParams {
  const GetProductReviewsParams({required this.productId, this.limit = 20, this.offset = 0});
  final String productId;
  final int limit;
  final int offset;
}

class GetProductReviewsUseCase {
  GetProductReviewsUseCase(this._repository);
  final MarketplaceRepository _repository;

  Future<Result<List<MarketplaceReviewEntity>>> call(GetProductReviewsParams params) async {
    return _repository.getProductReviews(
      params.productId,
      limit: params.limit,
      offset: params.offset,
    );
  }
}
