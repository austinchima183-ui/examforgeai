import '../../../../core/errors/failures.dart';
import '../../../../core/utils/result.dart';
import '../../domain/entities/marketplace_entities.dart';
import '../../data/repositories/marketplace_repository.dart';
import '../../../../features/marketplace/domain/repositories/marketplace_repository.dart';


class ReportReviewParams {
  const ReportReviewParams({required this.reviewId, required this.reason});
  final String reviewId;
  final String reason;
}

class ReportReviewUseCase {
  ReportReviewUseCase(this._repository);
  final MarketplaceRepository _repository;

  Future<Result<bool>> call(ReportReviewParams params) async {
    return _repository.reportReview(params.reviewId, params.reason);
  }
}
