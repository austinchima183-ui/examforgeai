import '../../../../../core/errors/failures.dart';
import '../../../../../core/utils/result.dart';
import '../../entities/billing_entities.dart';
import '../../repositories/billing_repository.dart';

// ─── Validate Coupon ─────────────────────────────────────────────────────────

class ValidateCouponParams {
  const ValidateCouponParams({
    required this.code,
    required this.billingModel,
    this.planId,
  });

  final String code;
  final BillingModel billingModel;
  final String? planId;
}

class ValidateCouponUseCase {
  ValidateCouponUseCase(this._repository);
  final BillingRepository _repository;

  Future<Result<CouponEntity>> call(ValidateCouponParams params) async {
    if (params.code.isEmpty) {
      return FailureResult(
        Failure.validation(message: 'Coupon code cannot be empty'),
      );
    }

    return _repository.validateCoupon(
      code: params.code,
      billingModel: params.billingModel,
      planId: params.planId,
    );
  }
}

// ─── Redeem Coupon ───────────────────────────────────────────────────────────

class RedeemCouponParams {
  const RedeemCouponParams({
    required this.couponId,
    required this.userId,
    this.schoolId,
    this.subscriptionId,
  });

  final String couponId;
  final String userId;
  final String? schoolId;
  final String? subscriptionId;
}

class RedeemCouponUseCase {
  RedeemCouponUseCase(this._repository);
  final BillingRepository _repository;

  Future<Result<CouponEntity>> call(RedeemCouponParams params) async {
    if (params.couponId.isEmpty) {
      return FailureResult(
        Failure.validation(message: 'Coupon ID cannot be empty'),
      );
    }
    if (params.userId.isEmpty) {
      return FailureResult(
        Failure.validation(message: 'User ID cannot be empty'),
      );
    }

    return _repository.redeemCoupon(
      couponId: params.couponId,
      userId: params.userId,
      schoolId: params.schoolId,
      subscriptionId: params.subscriptionId,
    );
  }
}

// ─── Get Coupons ─────────────────────────────────────────────────────────────

class GetCouponsParams {
  const GetCouponsParams({
    required this.activeOnly,
    required this.page,
    required this.perPage,
  });

  final bool activeOnly;
  final int page;
  final int perPage;
}

class GetCouponsUseCase {
  GetCouponsUseCase(this._repository);
  final BillingRepository _repository;

  Future<Result<PaginatedResult<CouponEntity>>> call(
    GetCouponsParams params,
  ) async {
    if (params.page < 1) {
      return FailureResult(
        Failure.validation(message: 'Page must be at least 1'),
      );
    }
    if (params.perPage < 1) {
      return FailureResult(
        Failure.validation(message: 'Per page must be at least 1'),
      );
    }

    return _repository.getCoupons(
      activeOnly: params.activeOnly,
      page: params.page,
      perPage: params.perPage,
    );
  }
}

// ─── Create Coupon ───────────────────────────────────────────────────────────

class CreateCouponParams {
  const CreateCouponParams({required this.coupon});
  final CouponEntity coupon;
}

class CreateCouponUseCase {
  CreateCouponUseCase(this._repository);
  final BillingRepository _repository;

  Future<Result<CouponEntity>> call(CreateCouponParams params) async {
    if (params.coupon.code.isEmpty) {
      return FailureResult(
        Failure.validation(message: 'Coupon code cannot be empty'),
      );
    }
    if (params.coupon.name.isEmpty) {
      return FailureResult(
        Failure.validation(message: 'Coupon name cannot be empty'),
      );
    }

    return _repository.createCoupon(coupon: params.coupon);
  }
}

// ─── Update Coupon ───────────────────────────────────────────────────────────

class UpdateCouponParams {
  const UpdateCouponParams({required this.coupon});
  final CouponEntity coupon;
}

class UpdateCouponUseCase {
  UpdateCouponUseCase(this._repository);
  final BillingRepository _repository;

  Future<Result<CouponEntity>> call(UpdateCouponParams params) async {
    if (params.coupon.id.isEmpty) {
      return FailureResult(
        Failure.validation(message: 'Coupon ID cannot be empty'),
      );
    }

    return _repository.updateCoupon(coupon: params.coupon);
  }
}
