import '../../../../../core/errors/failures.dart';
import '../../../../../core/utils/result.dart';
import '../../entities/marketplace_entities.dart';
import '../../repositories/marketplace_repository.dart';

class ModerateReviewParams {
  const ModerateReviewParams({required this.reviewId, required this.status});
  final String reviewId;
  final MarketplaceReviewStatus status;
}

class ModerateReviewUseCase {
  ModerateReviewUseCase(this._repository);
  final MarketplaceRepository _repository;

  Future<Result<MarketplaceReviewEntity>> call(ModerateReviewParams params) async {
    return _repository.moderateReview(params.reviewId, params.status);
  }
}
