import '../../../../core/network/api_client.dart';
import '../models/customer_success_models.dart';

/// Remote data source for Customer Success feature.
///
/// Handles all HTTP communication with the backend API.
class CustomerSuccessRemoteDatasource {
  CustomerSuccessRemoteDatasource(this._apiClient);

  final ApiClient _apiClient;

  static const String _basePath = '/customer-success';

  // ─── Onboarding ────────────────────────────────────────────────────

  Future<List<OnboardingFlowModel>> getOnboardingFlows(String role) async {
    final response = await _apiClient.get(
      '$_basePath/onboarding/flows',
      queryParameters: {'role': role},
    );
    final data = response.data as List?;
    return data?.map((e) => OnboardingFlowModel.fromJson(e as Map<String, dynamic>)).toList() ?? [];
  }

  Future<List<OnboardingProgressModel>> getOnboardingProgress(String userId) async {
    final response = await _apiClient.get(
      '$_basePath/onboarding/progress',
      queryParameters: {'user_id': userId},
    );
    final data = response.data as List?;
    return data?.map((e) => OnboardingProgressModel.fromJson(e as Map<String, dynamic>)).toList() ?? [];
  }

  Future<OnboardingProgressModel> completeOnboardingStep({
    required String userId,
    required String onboardingFlowId,
    Map<String, dynamic>? data,
  }) async {
    final response = await _apiClient.post(
      '$_basePath/onboarding/complete',
      data: {
        'user_id': userId,
        'onboarding_flow_id': onboardingFlowId,
        if (data != null) 'data': data,
      },
    );
    return OnboardingProgressModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<OnboardingProgressModel> skipOnboardingStep({
    required String userId,
    required String onboardingFlowId,
  }) async {
    final response = await _apiClient.post(
      '$_basePath/onboarding/skip',
      data: {
        'user_id': userId,
        'onboarding_flow_id': onboardingFlowId,
      },
    );
    return OnboardingProgressModel.fromJson(response.data as Map<String, dynamic>);
  }

  // ─── Product Tours ─────────────────────────────────────────────────

  Future<List<ProductTourModel>> getProductTours(String targetRole) async {
    final response = await _apiClient.get(
      '$_basePath/product-tours',
      queryParameters: {'target_role': targetRole},
    );
    final data = response.data as List?;
    return data?.map((e) => ProductTourModel.fromJson(e as Map<String, dynamic>)).toList() ?? [];
  }

  // ─── Help Articles ─────────────────────────────────────────────────

  Future<List<HelpArticleModel>> getHelpArticles({
    String? category,
    String? tag,
    int page = 1,
    int perPage = 20,
  }) async {
    final response = await _apiClient.get(
      '$_basePath/help-articles',
      queryParameters: {
        if (category != null) 'category': category,
        if (tag != null) 'tag': tag,
        'page': page,
        'per_page': perPage,
      },
    );
    final data = response.data as List?;
    return data?.map((e) => HelpArticleModel.fromJson(e as Map<String, dynamic>)).toList() ?? [];
  }

  Future<HelpArticleModel> getHelpArticleBySlug(String slug) async {
    final response = await _apiClient.get('$_basePath/help-articles/$slug');
    return HelpArticleModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<List<HelpArticleModel>> searchHelpArticles(String query, int limit) async {
    final response = await _apiClient.get(
      '$_basePath/help-articles/search',
      queryParameters: {'q': query, 'limit': limit},
    );
    final data = response.data as List?;
    return data?.map((e) => HelpArticleModel.fromJson(e as Map<String, dynamic>)).toList() ?? [];
  }

  // ─── Video Tutorials ───────────────────────────────────────────────

  Future<List<VideoTutorialModel>> getVideoTutorials({
    String? category,
    String? targetRole,
    int page = 1,
    int perPage = 20,
  }) async {
    final response = await _apiClient.get(
      '$_basePath/video-tutorials',
      queryParameters: {
        if (category != null) 'category': category,
        if (targetRole != null) 'target_role': targetRole,
        'page': page,
        'per_page': perPage,
      },
    );
    final data = response.data as List?;
    return data?.map((e) => VideoTutorialModel.fromJson(e as Map<String, dynamic>)).toList() ?? [];
  }

  // ─── Feedback ──────────────────────────────────────────────────────

  Future<FeedbackSubmissionModel> submitFeedback(Map<String, dynamic> payload) async {
    final response = await _apiClient.post(
      '$_basePath/feedback',
      data: payload,
    );
    return FeedbackSubmissionModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<List<FeedbackSubmissionModel>> getFeedbackSubmissions({
    required String userId,
    String? status,
    int page = 1,
    int perPage = 20,
  }) async {
    final response = await _apiClient.get(
      '$_basePath/feedback',
      queryParameters: {
        'user_id': userId,
        if (status != null) 'status': status,
        'page': page,
        'per_page': perPage,
      },
    );
    final data = response.data as List?;
    return data?.map((e) => FeedbackSubmissionModel.fromJson(e as Map<String, dynamic>)).toList() ?? [];
  }

  // ─── Feature Requests ──────────────────────────────────────────────

  Future<List<FeatureRequestModel>> getFeatureRequests({
    String? status,
    String? category,
    String sortBy = 'upvotes',
    int page = 1,
    int perPage = 20,
  }) async {
    final response = await _apiClient.get(
      '$_basePath/feature-requests',
      queryParameters: {
        if (status != null) 'status': status,
        if (category != null) 'category': category,
        'sort_by': sortBy,
        'page': page,
        'per_page': perPage,
      },
    );
    final data = response.data as List?;
    return data?.map((e) => FeatureRequestModel.fromJson(e as Map<String, dynamic>)).toList() ?? [];
  }

  Future<FeatureRequestModel> createFeatureRequest(Map<String, dynamic> payload) async {
    final response = await _apiClient.post(
      '$_basePath/feature-requests',
      data: payload,
    );
    return FeatureRequestModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<FeatureRequestModel> voteFeatureRequest({
    required String featureRequestId,
    required String userId,
  }) async {
    final response = await _apiClient.post(
      '$_basePath/feature-requests/$featureRequestId/vote',
      data: {'user_id': userId},
    );
    return FeatureRequestModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<List<String>> getFeatureRequestVotes(String userId) async {
    final response = await _apiClient.get(
      '$_basePath/feature-requests/votes',
      queryParameters: {'user_id': userId},
    );
    final data = response.data as List?;
    return data?.map((e) => e as String).toList() ?? [];
  }
}
