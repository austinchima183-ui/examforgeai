import '../../../../core/errors/failures.dart';
import '../../../../core/utils/result.dart';
import '../../domain/entities/marketplace_entities.dart';
import '../../domain/repositories/marketplace_repository.dart';
import '../../../../features/marketplace/domain/repositories/marketplace_repository.dart';


class VoteReviewHelpfulParams {
  const VoteReviewHelpfulParams({required this.reviewId, required this.userId});
  final String reviewId;
  final String userId;
}

class VoteReviewHelpfulUseCase {
  VoteReviewHelpfulUseCase(this._repository);
  final MarketplaceRepository _repository;

  Future<Result<bool>> call(VoteReviewHelpfulParams params) async {
    return _repository.voteReviewHelpful(params.reviewId, params.userId);
  }
}
