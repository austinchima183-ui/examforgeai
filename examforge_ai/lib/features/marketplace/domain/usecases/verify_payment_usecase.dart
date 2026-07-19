import '../../../../../core/errors/failures.dart';
import '../../../../../core/utils/result.dart';
import '../../entities/marketplace_entities.dart';
import '../../repositories/marketplace_repository.dart';

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
