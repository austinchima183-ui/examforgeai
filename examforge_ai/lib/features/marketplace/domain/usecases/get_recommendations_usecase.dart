import '../../../../../core/errors/failures.dart';
import '../../../../../core/utils/result.dart';
import '../../entities/marketplace_entities.dart';
import '../../repositories/marketplace_repository.dart';

class GetRecommendationsParams {
  const GetRecommendationsParams({required this.userId, this.limit = 10});
  final String userId;
  final int limit;
}

class GetRecommendationsUseCase {
  GetRecommendationsUseCase(this._repository);
  final MarketplaceRepository _repository;

  Future<Result<List<MarketplaceProductEntity>>> call(GetRecommendationsParams params) async {
    return _repository.getRecommendations(params.userId, limit: params.limit);
  }
}
