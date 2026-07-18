import '../../../../../core/errors/failures.dart';
import '../../../../../core/utils/result.dart';
import '../../entities/billing_entities.dart';
import '../../repositories/billing_repository.dart';

class GetSubscriptionPlansParams {
  const GetSubscriptionPlansParams({this.billingModel, this.activeOnly = true});
  final BillingModel? billingModel;
  final bool activeOnly;
}

class GetSubscriptionPlansUseCase {
  GetSubscriptionPlansUseCase(this._repository);
  final BillingRepository _repository;

  Future<Result<List<SubscriptionPlanEntity>>> call(
    GetSubscriptionPlansParams params,
  ) async {
    return _repository.getSubscriptionPlans(
      billingModel: params.billingModel,
      activeOnly: params.activeOnly,
    );
  }
}
