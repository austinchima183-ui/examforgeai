import '../../../../../core/errors/failures.dart';
import '../../../../../core/utils/result.dart';
import '../../entities/billing_entities.dart';
import '../../repositories/billing_repository.dart';

// ─── Get Licenses ────────────────────────────────────────────────────────────

class GetLicensesParams {
  const GetLicensesParams({
    this.schoolId,
    this.userId,
    this.type,
    this.activeOnly = true,
  });

  final String? schoolId;
  final String? userId;
  final LicenseType? type;
  final bool activeOnly;
}

class GetLicensesUseCase {
  GetLicensesUseCase(this._repository);
  final BillingRepository _repository;

  Future<Result<List<LicenseEntity>>> call(GetLicensesParams params) async {
    return _repository.getLicenses(
      schoolId: params.schoolId,
      userId: params.userId,
      type: params.type,
      activeOnly: params.activeOnly,
    );
  }
}

// ─── Revoke License ──────────────────────────────────────────────────────────

class RevokeLicenseParams {
  const RevokeLicenseParams({
    required this.licenseId,
    required this.reason,
  });

  final String licenseId;
  final String reason;
}

class RevokeLicenseUseCase {
  RevokeLicenseUseCase(this._repository);
  final BillingRepository _repository;

  Future<Result<LicenseEntity>> call(RevokeLicenseParams params) async {
    if (params.licenseId.isEmpty) {
      return FailureResult(
        Failure.validation(message: 'License ID cannot be empty'),
      );
    }
    if (params.reason.isEmpty) {
      return FailureResult(
        Failure.validation(message: 'Reason cannot be empty'),
      );
    }

    return _repository.revokeLicense(
      licenseId: params.licenseId,
      reason: params.reason,
    );
  }
}
