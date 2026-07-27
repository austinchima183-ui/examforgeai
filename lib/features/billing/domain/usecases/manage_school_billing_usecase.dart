import '../../../../core/errors/failures.dart';
import '../../../../core/utils/result.dart';
import '../../domain/entities/billing_entities.dart';
import '../../domain/repositories/billing_repository.dart';


// ─── Get School Billing Profile ──────────────────────────────────────────────

class GetSchoolBillingProfileParams {
  const GetSchoolBillingProfileParams({required this.schoolId});
  final String schoolId;
}

class GetSchoolBillingProfileUseCase {
  GetSchoolBillingProfileUseCase(this._repository);
  final BillingRepository _repository;

  Future<Result<SchoolBillingProfileEntity>> call(
    GetSchoolBillingProfileParams params,
  ) async {
    if (params.schoolId.isEmpty) {
      return const FailureResult(
        Failure.validation(fieldErrors: {}, message: 'School ID cannot be empty'),
      );
    }

    return _repository.getSchoolBillingProfile(params.schoolId);
  }
}

// ─── Update School Billing Profile ───────────────────────────────────────────

class UpdateSchoolBillingProfileParams {
  const UpdateSchoolBillingProfileParams({required this.profile});
  final SchoolBillingProfileEntity profile;
}

class UpdateSchoolBillingProfileUseCase {
  UpdateSchoolBillingProfileUseCase(this._repository);
  final BillingRepository _repository;

  Future<Result<SchoolBillingProfileEntity>> call(
    UpdateSchoolBillingProfileParams params,
  ) async {
    if (params.profile.schoolId.isEmpty) {
      return const FailureResult(
        Failure.validation(fieldErrors: {}, message: 'School ID cannot be empty'),
      );
    }

    return _repository.updateSchoolBillingProfile(params.profile);
  }
}
