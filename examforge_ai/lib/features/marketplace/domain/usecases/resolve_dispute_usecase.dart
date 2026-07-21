import '../../../../core/errors/failures.dart';
import '../../../../core/utils/result.dart';
import '../../domain/entities/marketplace_entities.dart';
import '../../domain/repositories/marketplace_repository.dart';
import '../../../../features/marketplace/domain/repositories/marketplace_repository.dart';


class ResolveDisputeParams {
  const ResolveDisputeParams({
    required this.disputeId,
    required this.resolution,
    required this.resolvedBy,
  });
  final String disputeId;
  final String resolution;
  final String resolvedBy;
}

class ResolveDisputeUseCase {
  ResolveDisputeUseCase(this._repository);
  final MarketplaceRepository _repository;

  Future<Result<DisputeEntity>> call(ResolveDisputeParams params) async {
    return _repository.resolveDispute(
      params.disputeId,
      params.resolution,
      params.resolvedBy,
    );
  }
}
