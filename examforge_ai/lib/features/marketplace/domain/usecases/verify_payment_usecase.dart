import '../../../../core/errors/failures.dart';
import '../../../../core/utils/result.dart';
import '../../domain/entities/marketplace_entities.dart';
import '../../data/repositories/marketplace_repository.dart';
import '../../../../features/marketplace/domain/repositories/marketplace_repository.dart';


class VerifyPaymentParams {
  const VerifyPaymentParams({required this.txRef});
  final String txRef;
}

class VerifyPaymentUseCase {
  VerifyPaymentUseCase(this._repository);
  final MarketplaceRepository _repository;

  Future<Result<MarketplaceOrderEntity>> call(VerifyPaymentParams params) async {
    return _repository.verifyPayment(params.txRef);
  }
}
