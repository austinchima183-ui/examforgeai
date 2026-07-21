import '../../../../core/errors/failures.dart';
import '../../../../core/utils/result.dart';
import '../../domain/entities/marketplace_entities.dart';
import '../../domain/repositories/marketplace_repository.dart';
import '../../../../features/marketplace/domain/repositories/marketplace_repository.dart';


class GetSellerProfileParams {
  const GetSellerProfileParams({this.sellerId, this.userId});
  final String? sellerId;
  final String? userId;
}

class GetSellerProfileUseCase {
  GetSellerProfileUseCase(this._repository);
  final MarketplaceRepository _repository;

  Future<Result<SellerProfileEntity>> call(GetSellerProfileParams params) async {
    if (params.sellerId != null) {
      return _repository.getSellerProfile(params.sellerId!);
    }
    if (params.userId != null) {
      return _repository.getSellerProfileByUserId(params.userId!);
    }
    return FailureResult(ServerFailure('Either sellerId or userId must be provided'));
  }
}
