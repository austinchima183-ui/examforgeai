import '../../../../core/errors/failures.dart';
import '../../../../core/utils/result.dart';
import '../../domain/entities/marketplace_entities.dart';
import '../../data/repositories/marketplace_repository.dart';
import '../../../../features/marketplace/domain/repositories/marketplace_repository.dart';


class ValidatePromoCodeParams {
  const ValidatePromoCodeParams({
    required this.code,
    this.orderAmount,
    this.productTypes,
  });
  final String code;
  final double? orderAmount;
  final List<MarketplaceProductType>? productTypes;
}

class ValidatePromoCodeUseCase {
  ValidatePromoCodeUseCase(this._repository);
  final MarketplaceRepository _repository;

  Future<Result<PromoCodeEntity>> call(ValidatePromoCodeParams params) async {
    return _repository.validatePromoCode(
      params.code,
      orderAmount: params.orderAmount,
      productTypes: params.productTypes,
    );
  }
}
