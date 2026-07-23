import '../../../../core/utils/result.dart';
import '../../domain/entities/marketplace_entities.dart';
import '../../domain/repositories/marketplace_repository.dart';


class ApproveProductParams {
  const ApproveProductParams({required this.productId, required this.moderatorId});
  final String productId;
  final String moderatorId;
}

class ApproveProductUseCase {
  ApproveProductUseCase(this._repository);
  final MarketplaceRepository _repository;

  Future<Result<MarketplaceProductEntity>> call(ApproveProductParams params) async {
    return _repository.approveProduct(params.productId, params.moderatorId);
  }
}
