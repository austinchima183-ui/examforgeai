import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/core.dart';
import '../../domain/entities/ccms_entities.dart';
import '../../domain/usecases/content_review_usecases.dart';

class ContentReviewState extends Equatable {
  final List<ContentReview> reviews;
  final bool isLoading;
  final String? error;

  const ContentReviewState({this.reviews = const [], this.isLoading = false, this.error});

  ContentReviewState copyWith({List<ContentReview>? reviews, bool? isLoading, String? error}) {
    return ContentReviewState(reviews: reviews ?? this.reviews, isLoading: isLoading ?? this.isLoading, error: error);
  }

  @override
  List<Object?> get props => [reviews, isLoading, error];
}

class ContentReviewNotifier extends StateNotifier<ContentReviewState> {
  final CreateReviewUseCase _createReviewUseCase;
  final GetContentReviewsUseCase _getContentReviewsUseCase;

  ContentReviewNotifier({
    required CreateReviewUseCase createReviewUseCase,
    required GetContentReviewsUseCase getContentReviewsUseCase,
  })  : _createReviewUseCase = createReviewUseCase,
        _getContentReviewsUseCase = getContentReviewsUseCase,
        super(const ContentReviewState());

  Future<void> createReview(ContentReview review) async {
    state = state.copyWith(isLoading: true, error: null);
    final result = await _createReviewUseCase(CreateReviewParams(review: review));
    result.fold(
      onSuccess: (created) => state = state.copyWith(reviews: [...state.reviews, created], isLoading: false),
      onFailure: (failure) => state = state.copyWith(isLoading: false, error: _mapFailureToMessage(failure)),
    );
  }

  Future<void> loadContentReviews(String contentItemId) async {
    state = state.copyWith(isLoading: true, error: null);
    final result = await _getContentReviewsUseCase(GetContentReviewsParams(contentItemId: contentItemId));
    result.fold(
      onSuccess: (reviews) => state = state.copyWith(reviews: reviews, isLoading: false),
      onFailure: (failure) => state = state.copyWith(isLoading: false, error: _mapFailureToMessage(failure)),
    );
  }
}

String _mapFailureToMessage(Failure failure) {
  return failure.when(
    server: (message, statusCode, data) => 'Server error: $message',
    cache: (message) => 'Cache error: $message',
    auth: (message, code) => 'Auth error: $message',
    network: (message) => 'Network error: $message',
    validation: (message, fieldErrors) => 'Validation error: $message',
    notFound: (message) => 'Not found: $message',
    unauthorized: (message) => 'Unauthorized: $message',
    forbidden: (message) => 'Forbidden: $message',
  );
}
