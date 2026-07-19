import '../../../../../core/errors/failures.dart';
import '../../../../../core/utils/result.dart';
import '../../entities/marketplace_entities.dart';
import '../../repositories/marketplace_repository.dart';

class GetCategoriesParams {
  const GetCategoriesParams({this.activeOnly = true});
  final bool activeOnly;
}

class GetCategoriesUseCase {
  GetCategoriesUseCase(this._repository);
  final MarketplaceRepository _repository;

  Future<Result<List<MarketplaceCategoryEntity>>> call(GetCategoriesParams params) async {
    return _repository.getCategories(activeOnly: params.activeOnly);
  }
}
