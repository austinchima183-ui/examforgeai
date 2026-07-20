import '../../../../core/utils/result.dart';
import '../entities/customer_success_entities.dart';

/// Abstract contract for the Customer Success repository.
///
/// All customer success operations flow through this interface,
/// enabling Clean Architecture separation and testability.
abstract class CustomerSuccessRepository {
  // ─── Onboarding ────────────────────────────────────────────────────

  /// Get onboarding flows for a specific role.
  Future<Result<List<OnboardingFlow>>> getOnboardingFlows({
    required String role,
  });

  /// Get the onboarding progress for a user.
  Future<Result<List<OnboardingProgress>>> getOnboardingProgress({
    required String userId,
  });

  /// Complete an onboarding step.
  Future<Result<OnboardingProgress>> completeOnboardingStep({
    required String userId,
    required String onboardingFlowId,
    Map<String, dynamic>? data,
  });

  /// Skip an onboarding step.
  Future<Result<OnboardingProgress>> skipOnboardingStep({
    required String userId,
    required String onboardingFlowId,
  });

  // ─── Product Tours ─────────────────────────────────────────────────

  /// Get active product tours for a role.
  Future<Result<List<ProductTour>>> getProductTours({
    required String targetRole,
  });

  // ─── Help Articles ─────────────────────────────────────────────────

  /// Get help articles with optional category filter.
  Future<Result<List<HelpArticle>>> getHelpArticles({
    String? category,
    String? tag,
    int page = 1,
    int perPage = 20,
  });

  /// Get a single help article by slug.
  Future<Result<HelpArticle>> getHelpArticleBySlug(String slug);

  /// Search help articles by query.
  Future<Result<List<HelpArticle>>> searchHelpArticles({
    required String query,
    int limit = 10,
  });

  // ─── Video Tutorials ───────────────────────────────────────────────

  /// Get video tutorials with optional filters.
  Future<Result<List<VideoTutorial>>> getVideoTutorials({
    String? category,
    String? targetRole,
    int page = 1,
    int perPage = 20,
  });

  // ─── Feedback ──────────────────────────────────────────────────────

  /// Submit feedback.
  Future<Result<FeedbackSubmission>> submitFeedback({
    required String userId,
    required FeedbackType feedbackType,
    required String subject,
    required String description,
    String priority = 'medium',
    List<String> attachments = const [],
    Map<String, dynamic> metadata = const {},
  });

  /// Get feedback submissions for a user.
  Future<Result<List<FeedbackSubmission>>> getFeedbackSubmissions({
    required String userId,
    String? status,
    int page = 1,
    int perPage = 20,
  });

  // ─── Feature Requests ──────────────────────────────────────────────

  /// Get feature requests.
  Future<Result<List<FeatureRequest>>> getFeatureRequests({
    String? status,
    String? category,
    String sortBy = 'upvotes',
    int page = 1,
    int perPage = 20,
  });

  /// Create a feature request.
  Future<Result<FeatureRequest>> createFeatureRequest({
    required String userId,
    required String title,
    required String description,
    required String category,
  });

  /// Vote for a feature request.
  Future<Result<FeatureRequest>> voteFeatureRequest({
    required String featureRequestId,
    required String userId,
  });

  /// Get user's votes on feature requests.
  Future<Result<List<String>>> getFeatureRequestVotes({
    required String userId,
  });
}
