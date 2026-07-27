import '../../../../core/utils/result.dart';
import '../../domain/entities/marketplace_entities.dart';
import '../../domain/repositories/marketplace_repository.dart';


class UpsertSellerProfileParams {
  const UpsertSellerProfileParams({required this.profile});
  final SellerProfileEntity profile;
}

class UpsertSellerProfileUseCase {
  UpsertSellerProfileUseCase(this._repository);
  final MarketplaceRepository _repository;

  Future<Result<SellerProfileEntity>> call(UpsertSellerProfileParams params) async {
    return _repository.upsertSellerProfile(params.profile);
  }
}
