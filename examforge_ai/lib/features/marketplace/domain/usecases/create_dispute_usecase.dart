import '../../../../core/errors/failures.dart';
import '../../../../core/utils/result.dart';
import '../../domain/entities/marketplace_entities.dart';
import '../../data/repositories/marketplace_repository.dart';
import '../../../../features/marketplace/domain/repositories/marketplace_repository.dart';


class CreateDisputeParams {
  const CreateDisputeParams({required this.dispute});
  final DisputeEntity dispute;
}

class CreateDisputeUseCase {
  CreateDisputeUseCase(this._repository);
  final MarketplaceRepository _repository;

  Future<Result<DisputeEntity>> call(CreateDisputeParams params) async {
    return _repository.createDispute(params.dispute);
  }
}
