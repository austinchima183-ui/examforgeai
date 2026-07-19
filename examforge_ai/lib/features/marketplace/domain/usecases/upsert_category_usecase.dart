import '../../../../../core/errors/failures.dart';
import '../../../../../core/utils/result.dart';
import '../../entities/marketplace_entities.dart';
import '../../repositories/marketplace_repository.dart';

class UpsertCategoryParams {
  const UpsertCategoryParams({required this.category});
  final MarketplaceCategoryEntity category;
}

class UpsertCategoryUseCase {
  UpsertCategoryUseCase(this._repository);
  final MarketplaceRepository _repository;

  Future<Result<MarketplaceCategoryEntity>> call(UpsertCategoryParams params) async {
    return _repository.upsertCategory(params.category);
  }
}
