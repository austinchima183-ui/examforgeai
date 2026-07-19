import '../../../../../core/errors/failures.dart';
import '../../../../../core/utils/result.dart';
import '../../entities/marketplace_entities.dart';
import '../../repositories/marketplace_repository.dart';

class RespondToReviewParams {
  const RespondToReviewParams({required this.reviewId, required this.response});
  final String reviewId;
  final String response;
}

class RespondToReviewUseCase {
  RespondToReviewUseCase(this._repository);
  final MarketplaceRepository _repository;

  Future<Result<MarketplaceReviewEntity>> call(RespondToReviewParams params) async {
    return _repository.respondToReview(params.reviewId, params.response);
  }
}
