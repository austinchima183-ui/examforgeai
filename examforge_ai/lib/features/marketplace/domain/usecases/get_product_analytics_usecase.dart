import '../../../../core/utils/result.dart';
import '../../domain/entities/marketplace_entities.dart';
import '../../domain/repositories/marketplace_repository.dart';


class GetProductAnalyticsParams {
  const GetProductAnalyticsParams({
    required this.productId,
    this.startDate,
    this.endDate,
  });
  final String productId;
  final DateTime? startDate;
  final DateTime? endDate;
}

class GetProductAnalyticsUseCase {
  GetProductAnalyticsUseCase(this._repository);
  final MarketplaceRepository _repository;

  Future<Result<ProductAnalyticsEntity>> call(GetProductAnalyticsParams params) async {
    return _repository.getProductAnalytics(
      params.productId,
      startDate: params.startDate,
      endDate: params.endDate,
    );
  }
}
