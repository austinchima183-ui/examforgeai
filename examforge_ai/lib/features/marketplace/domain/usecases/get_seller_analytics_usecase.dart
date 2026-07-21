import '../../../../core/errors/failures.dart';
import '../../../../core/utils/result.dart';
import '../../domain/entities/marketplace_entities.dart';
import '../../domain/repositories/marketplace_repository.dart';
import '../../../../features/marketplace/domain/repositories/marketplace_repository.dart';


class GetSellerAnalyticsParams {
  const GetSellerAnalyticsParams({
    required this.sellerId,
    this.startDate,
    this.endDate,
  });
  final String sellerId;
  final DateTime? startDate;
  final DateTime? endDate;
}

class GetSellerAnalyticsUseCase {
  GetSellerAnalyticsUseCase(this._repository);
  final MarketplaceRepository _repository;

  Future<Result<SellerAnalyticsEntity>> call(GetSellerAnalyticsParams params) async {
    return _repository.getSellerAnalytics(
      params.sellerId,
      startDate: params.startDate,
      endDate: params.endDate,
    );
  }
}
