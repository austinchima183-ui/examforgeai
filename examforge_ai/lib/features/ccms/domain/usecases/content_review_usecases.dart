import 'package:equatable/equatable.dart';
import '../../../../../core/utils/result.dart';
import '../entities/ccms_entities.dart';
import '../repositories/ccms_repository.dart';

// ─── CreateReviewUseCase ────────────────────────────────────────────

class CreateReviewParams extends Equatable {
  final ContentReview review;

  const CreateReviewParams({required this.review});

  @override
  List<Object?> get props => [review];
}

class CreateReviewUseCase {
  final CcmsRepository _repository;
  CreateReviewUseCase(this._repository);

  Future<Result<ContentReview>> call(CreateReviewParams params) async {
    return await _repository.createReview(params.review);
  }
}

// ─── GetContentReviewsUseCase ───────────────────────────────────────

class GetContentReviewsParams extends Equatable {
  final String contentItemId;

  const GetContentReviewsParams({required this.contentItemId});

  @override
  List<Object?> get props => [contentItemId];
}

class GetContentReviewsUseCase {
  final CcmsRepository _repository;
  GetContentReviewsUseCase(this._repository);

  Future<Result<List<ContentReview>>> call(
    GetContentReviewsParams params,
  ) async {
    return await _repository.getContentReviews(params.contentItemId);
  }
}
