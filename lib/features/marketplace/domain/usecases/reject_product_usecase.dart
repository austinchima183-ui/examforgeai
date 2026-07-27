import '../../../../core/utils/result.dart';
import '../../domain/entities/marketplace_entities.dart';
import '../../domain/repositories/marketplace_repository.dart';


class RejectProductParams {
  const RejectProductParams({
    required this.productId,
    required this.reason,
    required this.moderatorId,
  });
  final String productId;
  final String reason;
  final String moderatorId;
}

class RejectProductUseCase {
  RejectProductUseCase(this._repository);
  final MarketplaceRepository _repository;

  Future<Result<MarketplaceProductEntity>> call(RejectProductParams params) async {
    return _repository.rejectProduct(params.productId, params.reason, params.moderatorId);
  }
}
