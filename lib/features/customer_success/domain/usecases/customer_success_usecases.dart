import '../../../../core/utils/result.dart';
import '../entities/customer_success_entities.dart';
import '../repositories/customer_success_repository.dart';

// ============================================================================
// PARAMS CLASSES
// ============================================================================

class GetOnboardingFlowsParams {
  final String role;
  const GetOnboardingFlowsParams({required this.role});
}

class GetOnboardingProgressParams {
  final String userId;
  const GetOnboardingProgressParams({required this.userId});
}

class CompleteOnboardingStepParams {
  final String userId;
  final String onboardingFlowId;
  final Map<String, dynamic>? data;
  const CompleteOnboardingStepParams({
    required this.userId,
    required this.onboardingFlowId,
    this.data,
  });
}

class SkipOnboardingStepParams {
  final String userId;
  final String onboardingFlowId;
  const SkipOnboardingStepParams({
    required this.userId,
    required this.onboardingFlowId,
  });
}

class GetProductToursParams {
  final String targetRole;
  const GetProductToursParams({required this.targetRole});
}

class GetHelpArticlesParams {
  final String? category;
  final String? tag;
  final int page;
  final int perPage;
  const GetHelpArticlesParams({
    this.category,
    this.tag,
    this.page = 1,
    this.perPage = 20,
  });
}

class GetHelpArticleBySlugParams {
  final String slug;
  const GetHelpArticleBySlugParams({required this.slug});
}

class SearchHelpArticlesParams {
  final String query;
  final int limit;
  const SearchHelpArticlesParams({required this.query, this.limit = 10});
}

class GetVideoTutorialsParams {
  final String? category;
  final String? targetRole;
  final int page;
  final int perPage;
  const GetVideoTutorialsParams({
    this.category,
    this.targetRole,
    this.page = 1,
    this.perPage = 20,
  });
}

class SubmitFeedbackParams {
  final String userId;
  final FeedbackType feedbackType;
  final String subject;
  final String description;
  final String priority;
  final List<String> attachments;
  final Map<String, dynamic> metadata;
  const SubmitFeedbackParams({
    required this.userId,
    required this.feedbackType,
    required this.subject,
    required this.description,
    this.priority = 'medium',
    this.attachments = const [],
    this.metadata = const {},
  });
}

class GetFeedbackSubmissionsParams {
  final String userId;
  final String? status;
  final int page;
  final int perPage;
  const GetFeedbackSubmissionsParams({
    required this.userId,
    this.status,
    this.page = 1,
    this.perPage = 20,
  });
}

class GetFeatureRequestsParams {
  final String? status;
  final String? category;
  final String sortBy;
  final int page;
  final int perPage;
  const GetFeatureRequestsParams({
    this.status,
    this.category,
    this.sortBy = 'upvotes',
    this.page = 1,
    this.perPage = 20,
  });
}

class CreateFeatureRequestParams {
  final String userId;
  final String title;
  final String description;
  final String category;
  const CreateFeatureRequestParams({
    required this.userId,
    required this.title,
    required this.description,
    required this.category,
  });
}

class VoteFeatureRequestParams {
  final String featureRequestId;
  final String userId;
  const VoteFeatureRequestParams({
    required this.featureRequestId,
    required this.userId,
  });
}

class GetFeatureRequestVotesParams {
  final String userId;
  const GetFeatureRequestVotesParams({required this.userId});
}

// ============================================================================
// USE CASES
// ============================================================================

class GetOnboardingFlowsUseCase {
  final CustomerSuccessRepository _repository;
  GetOnboardingFlowsUseCase(this._repository);

  Future<Result<List<OnboardingFlow>>> call(GetOnboardingFlowsParams params) {
    return _repository.getOnboardingFlows(role: params.role);
  }
}

class GetOnboardingProgressUseCase {
  final CustomerSuccessRepository _repository;
  GetOnboardingProgressUseCase(this._repository);

  Future<Result<List<OnboardingProgress>>> call(GetOnboardingProgressParams params) {
    return _repository.getOnboardingProgress(userId: params.userId);
  }
}

class CompleteOnboardingStepUseCase {
  final CustomerSuccessRepository _repository;
  CompleteOnboardingStepUseCase(this._repository);

  Future<Result<OnboardingProgress>> call(CompleteOnboardingStepParams params) {
    return _repository.completeOnboardingStep(
      userId: params.userId,
      onboardingFlowId: params.onboardingFlowId,
      data: params.data,
    );
  }
}

class SkipOnboardingStepUseCase {
  final CustomerSuccessRepository _repository;
  SkipOnboardingStepUseCase(this._repository);

  Future<Result<OnboardingProgress>> call(SkipOnboardingStepParams params) {
    return _repository.skipOnboardingStep(
      userId: params.userId,
      onboardingFlowId: params.onboardingFlowId,
    );
  }
}

class GetProductToursUseCase {
  final CustomerSuccessRepository _repository;
  GetProductToursUseCase(this._repository);

  Future<Result<List<ProductTour>>> call(GetProductToursParams params) {
    return _repository.getProductTours(targetRole: params.targetRole);
  }
}

class GetHelpArticlesUseCase {
  final CustomerSuccessRepository _repository;
  GetHelpArticlesUseCase(this._repository);

  Future<Result<List<HelpArticle>>> call(GetHelpArticlesParams params) {
    return _repository.getHelpArticles(
      category: params.category,
      tag: params.tag,
      page: params.page,
      perPage: params.perPage,
    );
  }
}

class GetHelpArticleBySlugUseCase {
  final CustomerSuccessRepository _repository;
  GetHelpArticleBySlugUseCase(this._repository);

  Future<Result<HelpArticle>> call(GetHelpArticleBySlugParams params) {
    return _repository.getHelpArticleBySlug(params.slug);
  }
}

class SearchHelpArticlesUseCase {
  final CustomerSuccessRepository _repository;
  SearchHelpArticlesUseCase(this._repository);

  Future<Result<List<HelpArticle>>> call(SearchHelpArticlesParams params) {
    return _repository.searchHelpArticles(query: params.query, limit: params.limit);
  }
}

class GetVideoTutorialsUseCase {
  final CustomerSuccessRepository _repository;
  GetVideoTutorialsUseCase(this._repository);

  Future<Result<List<VideoTutorial>>> call(GetVideoTutorialsParams params) {
    return _repository.getVideoTutorials(
      category: params.category,
      targetRole: params.targetRole,
      page: params.page,
      perPage: params.perPage,
    );
  }
}

class SubmitFeedbackUseCase {
  final CustomerSuccessRepository _repository;
  SubmitFeedbackUseCase(this._repository);

  Future<Result<FeedbackSubmission>> call(SubmitFeedbackParams params) {
    return _repository.submitFeedback(
      userId: params.userId,
      feedbackType: params.feedbackType,
      subject: params.subject,
      description: params.description,
      priority: params.priority,
      attachments: params.attachments,
      metadata: params.metadata,
    );
  }
}

class GetFeedbackSubmissionsUseCase {
  final CustomerSuccessRepository _repository;
  GetFeedbackSubmissionsUseCase(this._repository);

  Future<Result<List<FeedbackSubmission>>> call(GetFeedbackSubmissionsParams params) {
    return _repository.getFeedbackSubmissions(
      userId: params.userId,
      status: params.status,
      page: params.page,
      perPage: params.perPage,
    );
  }
}

class GetFeatureRequestsUseCase {
  final CustomerSuccessRepository _repository;
  GetFeatureRequestsUseCase(this._repository);

  Future<Result<List<FeatureRequest>>> call(GetFeatureRequestsParams params) {
    return _repository.getFeatureRequests(
      status: params.status,
      category: params.category,
      sortBy: params.sortBy,
      page: params.page,
      perPage: params.perPage,
    );
  }
}

class CreateFeatureRequestUseCase {
  final CustomerSuccessRepository _repository;
  CreateFeatureRequestUseCase(this._repository);

  Future<Result<FeatureRequest>> call(CreateFeatureRequestParams params) {
    return _repository.createFeatureRequest(
      userId: params.userId,
      title: params.title,
      description: params.description,
      category: params.category,
    );
  }
}

class VoteFeatureRequestUseCase {
  final CustomerSuccessRepository _repository;
  VoteFeatureRequestUseCase(this._repository);

  Future<Result<FeatureRequest>> call(VoteFeatureRequestParams params) {
    return _repository.voteFeatureRequest(
      featureRequestId: params.featureRequestId,
      userId: params.userId,
    );
  }
}

class GetFeatureRequestVotesUseCase {
  final CustomerSuccessRepository _repository;
  GetFeatureRequestVotesUseCase(this._repository);

  Future<Result<List<String>>> call(GetFeatureRequestVotesParams params) {
    return _repository.getFeatureRequestVotes(userId: params.userId);
  }
}
