import '../../../../../core/errors/failures.dart';
import '../../../../../core/utils/result.dart';
import '../../entities/marketplace_entities.dart';
import '../../repositories/marketplace_repository.dart';

class CreateReviewParams {
  const CreateReviewParams({required this.review});
  final MarketplaceReviewEntity review;
}

class CreateReviewUseCase {
  CreateReviewUseCase(this._repository);
  final MarketplaceRepository _repository;

  Future<Result<MarketplaceReviewEntity>> call(CreateReviewParams params) async {
    return _repository.createReview(params.review);
  }
}
