import '../../../../core/errors/failures.dart';
import '../../../../core/utils/result.dart';
import '../../domain/entities/billing_entities.dart';
import '../../domain/repositories/billing_repository.dart';


// ─── Get Revenue Data ────────────────────────────────────────────────────────

class GetRevenueDataParams {
  const GetRevenueDataParams({
    required this.periodType,
    required this.startDate,
    required this.endDate,
  });

  final String periodType;
  final DateTime startDate;
  final DateTime endDate;
}

class GetRevenueDataUseCase {
  GetRevenueDataUseCase(this._repository);
  final BillingRepository _repository;

  Future<Result<List<RevenueDataPoint>>> call(GetRevenueDataParams params) async {
    if (params.periodType.isEmpty) {
      return FailureResult(
        Failure.validation(fieldErrors: const {}, message: 'Period type cannot be empty'),
      );
    }
    if (params.endDate.isBefore(params.startDate)) {
      return FailureResult(
        Failure.validation(fieldErrors: const {}, message: 'End date must be after start date'),
      );
    }

    return _repository.getRevenueData(
      periodType: params.periodType,
      startDate: params.startDate,
      endDate: params.endDate,
    );
  }
}

// ─── Get Billing Dashboard Summary ───────────────────────────────────────────

class GetBillingDashboardSummaryUseCase {
  GetBillingDashboardSummaryUseCase(this._repository);
  final BillingRepository _repository;

  Future<Result<Map<String, dynamic>>> call() async {
    return _repository.getBillingDashboardSummary();
  }
}
