import '../../../../core/errors/failures.dart';
import '../../../../core/utils/result.dart';
import '../../domain/entities/billing_entities.dart';
import '../../domain/repositories/billing_repository.dart';


// ─── Get Credit Balance ──────────────────────────────────────────────────────

class GetCreditBalanceParams {
  const GetCreditBalanceParams({
    required this.ownerId,
    required this.ownerType,
  });

  final String ownerId;
  final BillingModel ownerType;
}

class GetCreditBalanceUseCase {
  GetCreditBalanceUseCase(this._repository);
  final BillingRepository _repository;

  Future<Result<AiCreditBalanceEntity>> call(
    GetCreditBalanceParams params,
  ) async {
    if (params.ownerId.isEmpty) {
      return FailureResult(
        Failure.validation(message: 'Owner ID cannot be empty', fieldErrors: const {}),
      );
    }

    return _repository.getCreditBalance(
      ownerId: params.ownerId,
      ownerType: params.ownerType,
    );
  }
}

// ─── Get Credit Transactions ─────────────────────────────────────────────────

class GetCreditTransactionsParams {
  const GetCreditTransactionsParams({
    required this.ownerId,
    required this.ownerType,
    this.type,
    required this.page,
    required this.perPage,
  });

  final String ownerId;
  final BillingModel ownerType;
  final CreditTransactionType? type;
  final int page;
  final int perPage;
}

class GetCreditTransactionsUseCase {
  GetCreditTransactionsUseCase(this._repository);
  final BillingRepository _repository;

  Future<Result<List<AiCreditTransactionEntity>>> call(
    GetCreditTransactionsParams params,
  ) async {
    if (params.ownerId.isEmpty) {
      return FailureResult(
        Failure.validation(message: 'Owner ID cannot be empty', fieldErrors: const {}),
      );
    }
    if (params.page < 1) {
      return FailureResult(
        Failure.validation(message: 'Page must be at least 1', fieldErrors: const {}),
      );
    }
    if (params.perPage < 1) {
      return FailureResult(
        Failure.validation(message: 'Per page must be at least 1', fieldErrors: const {}),
      );
    }

    return _repository.getCreditTransactions(
      ownerId: params.ownerId,
      ownerType: params.ownerType,
      type: params.type,
      page: params.page,
      perPage: params.perPage,
    );
  }
}

// ─── Consume Credits ─────────────────────────────────────────────────────────

class ConsumeCreditsParams {
  const ConsumeCreditsParams({
    required this.ownerId,
    required this.ownerType,
    required this.credits,
    required this.featureName,
    this.referenceId,
    required this.estimatedCostUsd,
  });

  final String ownerId;
  final BillingModel ownerType;
  final int credits;
  final String featureName;
  final String? referenceId;
  final double estimatedCostUsd;
}

class ConsumeCreditsUseCase {
  ConsumeCreditsUseCase(this._repository);
  final BillingRepository _repository;

  Future<Result<bool>> call(
    ConsumeCreditsParams params,
  ) async {
    if (params.ownerId.isEmpty) {
      return FailureResult(
        Failure.validation(message: 'Owner ID cannot be empty', fieldErrors: const {}),
      );
    }
    if (params.credits <= 0) {
      return FailureResult(
        Failure.validation(message: 'Credits must be greater than 0', fieldErrors: const {}),
      );
    }
    if (params.featureName.isEmpty) {
      return FailureResult(
        Failure.validation(message: 'Feature name cannot be empty', fieldErrors: const {}),
      );
    }

    return _repository.consumeCredits(
      ownerId: params.ownerId,
      ownerType: params.ownerType,
      credits: params.credits,
      featureName: params.featureName,
      referenceId: params.referenceId,
      estimatedCostUsd: params.estimatedCostUsd,
    );
  }
}

// ─── Purchase Credits ────────────────────────────────────────────────────────

class PurchaseCreditsParams {
  const PurchaseCreditsParams({
    required this.ownerId,
    required this.ownerType,
    required this.creditPackId,
    this.couponCode,
  });

  final String ownerId;
  final BillingModel ownerType;
  final String creditPackId;
  final String? couponCode;
}

class PurchaseCreditsUseCase {
  PurchaseCreditsUseCase(this._repository);
  final BillingRepository _repository;

  Future<Result<AiCreditBalanceEntity>> call(
    PurchaseCreditsParams params,
  ) async {
    if (params.ownerId.isEmpty) {
      return FailureResult(
        Failure.validation(message: 'Owner ID cannot be empty', fieldErrors: const {}),
      );
    }
    if (params.creditPackId.isEmpty) {
      return FailureResult(
        Failure.validation(message: 'Credit pack ID cannot be empty', fieldErrors: const {}),
      );
    }

    return _repository.purchaseCredits(
      ownerId: params.ownerId,
      ownerType: params.ownerType,
      creditPackId: params.creditPackId,
      couponCode: params.couponCode,
    );
  }
}

// ─── Get Credit Packs ────────────────────────────────────────────────────────

class GetCreditPacksParams {
  const GetCreditPacksParams({this.billingModel});
  final BillingModel? billingModel;
}

class GetCreditPacksUseCase {
  GetCreditPacksUseCase(this._repository);
  final BillingRepository _repository;

  Future<Result<List<AiCreditPackEntity>>> call(
    GetCreditPacksParams params,
  ) async {
    return _repository.getCreditPacks(billingModel: params.billingModel);
  }
}
