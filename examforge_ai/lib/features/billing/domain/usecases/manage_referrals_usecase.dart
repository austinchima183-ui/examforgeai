import '../../../../core/errors/failures.dart';
import '../../../../core/utils/result.dart';
import '../../domain/entities/billing_entities.dart';
import '../../domain/repositories/billing_repository.dart';
import '../../../../features/billing/domain/repositories/billing_repository.dart';


// ─── Get Or Create Referral Code ─────────────────────────────────────────────

class GetOrCreateReferralCodeParams {
  const GetOrCreateReferralCodeParams({
    required this.referrerId,
    required this.referrerType,
    this.schoolId,
  });

  final String referrerId;
  final ReferrerType referrerType;
  final String? schoolId;
}

class GetOrCreateReferralCodeUseCase {
  GetOrCreateReferralCodeUseCase(this._repository);
  final BillingRepository _repository;

  Future<Result<ReferralCodeEntity>> call(
    GetOrCreateReferralCodeParams params,
  ) async {
    if (params.referrerId.isEmpty) {
      return FailureResult(
        Failure.validation(fieldErrors: const {}, message: 'Referrer ID cannot be empty'),
      );
    }

    return _repository.getOrCreateReferralCode(
      referrerId: params.referrerId,
      referrerType: params.referrerType,
      schoolId: params.schoolId,
    );
  }
}

// ─── Apply Referral Code ─────────────────────────────────────────────────────

class ApplyReferralCodeParams {
  const ApplyReferralCodeParams({
    required this.code,
    required this.refereeId,
    required this.refereeType,
  });

  final String code;
  final String refereeId;
  final RefereeType refereeType;
}

class ApplyReferralCodeUseCase {
  ApplyReferralCodeUseCase(this._repository);
  final BillingRepository _repository;

  Future<Result<ReferralEntity>> call(ApplyReferralCodeParams params) async {
    if (params.code.isEmpty) {
      return FailureResult(
        Failure.validation(fieldErrors: const {}, message: 'Referral code cannot be empty'),
      );
    }
    if (params.refereeId.isEmpty) {
      return FailureResult(
        Failure.validation(fieldErrors: const {}, message: 'Referee ID cannot be empty'),
      );
    }

    return _repository.applyReferralCode(
      code: params.code,
      refereeId: params.refereeId,
      refereeType: params.refereeType,
    );
  }
}

// ─── Get Referral Tracking ───────────────────────────────────────────────────

class GetReferralTrackingParams {
  const GetReferralTrackingParams({
    required this.referrerId,
    required this.page,
    required this.perPage,
  });

  final String referrerId;
  final int page;
  final int perPage;
}

class GetReferralTrackingUseCase {
  GetReferralTrackingUseCase(this._repository);
  final BillingRepository _repository;

  Future<Result<PaginatedResult<ReferralEntity>>> call(
    GetReferralTrackingParams params,
  ) async {
    if (params.referrerId.isEmpty) {
      return FailureResult(
        Failure.validation(fieldErrors: const {}, message: 'Referrer ID cannot be empty'),
      );
    }
    if (params.page < 1) {
      return FailureResult(
        Failure.validation(fieldErrors: const {}, message: 'Page must be at least 1'),
      );
    }
    if (params.perPage < 1) {
      return FailureResult(
        Failure.validation(fieldErrors: const {}, message: 'Per page must be at least 1'),
      );
    }

    return _repository.getReferralTracking(
      referrerId: params.referrerId,
      page: params.page,
      perPage: params.perPage,
    );
  }
}
