import '../../../../core/errors/failures.dart';
import '../../../../core/utils/result.dart';
import '../../domain/entities/marketplace_entities.dart';
import '../../data/repositories/marketplace_repository.dart';
import '../../../../features/marketplace/domain/repositories/marketplace_repository.dart';


class UpsertCommissionRateParams {
  const UpsertCommissionRateParams({required this.rate});
  final CommissionRateEntity rate;
}

class UpsertCommissionRateUseCase {
  UpsertCommissionRateUseCase(this._repository);
  final MarketplaceRepository _repository;

  Future<Result<CommissionRateEntity>> call(UpsertCommissionRateParams params) async {
    return _repository.upsertCommissionRate(params.rate);
  }
}
