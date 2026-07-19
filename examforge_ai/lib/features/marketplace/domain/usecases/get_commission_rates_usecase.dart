import '../../../../../core/errors/failures.dart';
import '../../../../../core/utils/result.dart';
import '../../entities/marketplace_entities.dart';
import '../../repositories/marketplace_repository.dart';

class GetCommissionRatesParams {
  const GetCommissionRatesParams({this.productType, this.licenseType});
  final MarketplaceProductType? productType;
  final MarketplaceLicenseType? licenseType;
}

class GetCommissionRatesUseCase {
  GetCommissionRatesUseCase(this._repository);
  final MarketplaceRepository _repository;

  Future<Result<List<CommissionRateEntity>>> call(GetCommissionRatesParams params) async {
    return _repository.getCommissionRates(
      productType: params.productType,
      licenseType: params.licenseType,
    );
  }
}
