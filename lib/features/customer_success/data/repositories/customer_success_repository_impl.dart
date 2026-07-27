import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/utils/result.dart';
import '../../domain/entities/customer_success_entities.dart';
import '../../domain/repositories/customer_success_repository.dart';
import '../datasources/customer_success_remote_datasource.dart';

/// Concrete implementation of [CustomerSuccessRepository].
///
/// Converts data-layer exceptions into domain-layer [Failure]s so
/// the presentation layer never leaks implementation details.
class CustomerSuccessRepositoryImpl implements CustomerSuccessRepository {
  CustomerSuccessRepositoryImpl(this._remoteDatasource);

  final CustomerSuccessRemoteDatasource _remoteDatasource;

  // ─── Onboarding ────────────────────────────────────────────────────

  @override
  Future<Result<List<OnboardingFlow>>> getOnboardingFlows({required String role}) async {
    try {
      final models = await _remoteDatasource.getOnboardingFlows(role);
      return Success(models.map((m) => m.toEntity()).toList());
    } on ServerException catch (e) {
      return FailureResult(Failure.server(message: e.message, statusCode: e.statusCode, data: e.data));
    } on NetworkException catch (e) {
      return FailureResult(Failure.network(message: e.message));
    } on AuthException catch (e) {
      return FailureResult(Failure.auth(message: e.message, code: e.code));
    } catch (e) {
      return FailureResult(Failure.server(message: e.toString(), statusCode: 0));
    }
  }

  @override
  Future<Result<List<OnboardingProgress>>> getOnboardingProgress({required String userId}) async {
    try {
      final models = await _remoteDatasource.getOnboardingProgress(userId);
      return Success(models.map((m) => m.toEntity()).toList());
    } on ServerException catch (e) {
      return FailureResult(Failure.server(message: e.message, statusCode: e.statusCode, data: e.data));
    } on NetworkException catch (e) {
      return FailureResult(Failure.network(message: e.message));
    } on AuthException catch (e) {
      return FailureResult(Failure.auth(message: e.message, code: e.code));
    } catch (e) {
      return FailureResult(Failure.server(message: e.toString(), statusCode: 0));
    }
  }

  @override
  Future<Result<OnboardingProgress>> completeOnboardingStep({
    required String userId,
    required String onboardingFlowId,
    Map<String, dynamic>? data,
  }) async {
    try {
      final model = await _remoteDatasource.completeOnboardingStep(
        userId: userId,
        onboardingFlowId: onboardingFlowId,
        data: data,
      );
      return Success(model.toEntity());
    } on ServerException catch (e) {
      return FailureResult(Failure.server(message: e.message, statusCode: e.statusCode, data: e.data));
    } on NetworkException catch (e) {
      return FailureResult(Failure.network(message: e.message));
    } on AuthException catch (e) {
      return FailureResult(Failure.auth(message: e.message, code: e.code));
    } catch (e) {
      return FailureResult(Failure.server(message: e.toString(), statusCode: 0));
    }
  }

  @override
  Future<Result<OnboardingProgress>> skipOnboardingStep({
    required String userId,
    required String onboardingFlowId,
  }) async {
    try {
      final model = await _remoteDatasource.skipOnboardingStep(
        userId: userId,
        onboardingFlowId: onboardingFlowId,
      );
      return Success(model.toEntity());
    } on ServerException catch (e) {
      return FailureResult(Failure.server(message: e.message, statusCode: e.statusCode, data: e.data));
    } on NetworkException catch (e) {
      return FailureResult(Failure.network(message: e.message));
    } on AuthException catch (e) {
      return FailureResult(Failure.auth(message: e.message, code: e.code));
    } catch (e) {
      return FailureResult(Failure.server(message: e.toString(), statusCode: 0));
    }
  }

  // ─── Product Tours ─────────────────────────────────────────────────

  @override
  Future<Result<List<ProductTour>>> getProductTours({required String targetRole}) async {
    try {
      final models = await _remoteDatasource.getProductTours(targetRole);
      return Success(models.map((m) => m.toEntity()).toList());
    } on ServerException catch (e) {
      return FailureResult(Failure.server(message: e.message, statusCode: e.statusCode, data: e.data));
    } on NetworkException catch (e) {
      return FailureResult(Failure.network(message: e.message));
    } catch (e) {
      return FailureResult(Failure.server(message: e.toString(), statusCode: 0));
    }
  }

  // ─── Help Articles ─────────────────────────────────────────────────

  @override
  Future<Result<List<HelpArticle>>> getHelpArticles({
    String? category,
    String? tag,
    int page = 1,
    int perPage = 20,
  }) async {
    try {
      final models = await _remoteDatasource.getHelpArticles(
        category: category,
        tag: tag,
        page: page,
        perPage: perPage,
      );
      return Success(models.map((m) => m.toEntity()).toList());
    } on ServerException catch (e) {
      return FailureResult(Failure.server(message: e.message, statusCode: e.statusCode, data: e.data));
    } on NetworkException catch (e) {
      return FailureResult(Failure.network(message: e.message));
    } catch (e) {
      return FailureResult(Failure.server(message: e.toString(), statusCode: 0));
    }
  }

  @override
  Future<Result<HelpArticle>> getHelpArticleBySlug(String slug) async {
    try {
      final model = await _remoteDatasource.getHelpArticleBySlug(slug);
      return Success(model.toEntity());
    } on ServerException catch (e) {
      return FailureResult(Failure.server(message: e.message, statusCode: e.statusCode, data: e.data));
    } on NetworkException catch (e) {
      return FailureResult(Failure.network(message: e.message));
    } on NotFoundException catch (e) {
      return FailureResult(Failure.notFound(message: e.message));
    } catch (e) {
      return FailureResult(Failure.server(message: e.toString(), statusCode: 0));
    }
  }

  @override
  Future<Result<List<HelpArticle>>> searchHelpArticles({required String query, int limit = 10}) async {
    try {
      final models = await _remoteDatasource.searchHelpArticles(query, limit);
      return Success(models.map((m) => m.toEntity()).toList());
    } on ServerException catch (e) {
      return FailureResult(Failure.server(message: e.message, statusCode: e.statusCode, data: e.data));
    } on NetworkException catch (e) {
      return FailureResult(Failure.network(message: e.message));
    } catch (e) {
      return FailureResult(Failure.server(message: e.toString(), statusCode: 0));
    }
  }

  // ─── Video Tutorials ───────────────────────────────────────────────

  @override
  Future<Result<List<VideoTutorial>>> getVideoTutorials({
    String? category,
    String? targetRole,
    int page = 1,
    int perPage = 20,
  }) async {
    try {
      final models = await _remoteDatasource.getVideoTutorials(
        category: category,
        targetRole: targetRole,
        page: page,
        perPage: perPage,
      );
      return Success(models.map((m) => m.toEntity()).toList());
    } on ServerException catch (e) {
      return FailureResult(Failure.server(message: e.message, statusCode: e.statusCode, data: e.data));
    } on NetworkException catch (e) {
      return FailureResult(Failure.network(message: e.message));
    } catch (e) {
      return FailureResult(Failure.server(message: e.toString(), statusCode: 0));
    }
  }

  // ─── Feedback ──────────────────────────────────────────────────────

  @override
  Future<Result<FeedbackSubmission>> submitFeedback({
    required String userId,
    required FeedbackType feedbackType,
    required String subject,
    required String description,
    String priority = 'medium',
    List<String> attachments = const [],
    Map<String, dynamic> metadata = const {},
  }) async {
    try {
      final model = await _remoteDatasource.submitFeedback({
        'user_id': userId,
        'feedback_type': feedbackType.value,
        'subject': subject,
        'description': description,
        'priority': priority,
        'attachments': attachments,
        'metadata': metadata,
      });
      return Success(model.toEntity());
    } on ServerException catch (e) {
      return FailureResult(Failure.server(message: e.message, statusCode: e.statusCode, data: e.data));
    } on NetworkException catch (e) {
      return FailureResult(Failure.network(message: e.message));
    } on ValidationException catch (e) {
      return FailureResult(Failure.validation(message: e.message, fieldErrors: e.fieldErrors));
    } catch (e) {
      return FailureResult(Failure.server(message: e.toString(), statusCode: 0));
    }
  }

  @override
  Future<Result<List<FeedbackSubmission>>> getFeedbackSubmissions({
    required String userId,
    String? status,
    int page = 1,
    int perPage = 20,
  }) async {
    try {
      final models = await _remoteDatasource.getFeedbackSubmissions(
        userId: userId,
        status: status,
        page: page,
        perPage: perPage,
      );
      return Success(models.map((m) => m.toEntity()).toList());
    } on ServerException catch (e) {
      return FailureResult(Failure.server(message: e.message, statusCode: e.statusCode, data: e.data));
    } on NetworkException catch (e) {
      return FailureResult(Failure.network(message: e.message));
    } catch (e) {
      return FailureResult(Failure.server(message: e.toString(), statusCode: 0));
    }
  }

  // ─── Feature Requests ──────────────────────────────────────────────

  @override
  Future<Result<List<FeatureRequest>>> getFeatureRequests({
    String? status,
    String? category,
    String sortBy = 'upvotes',
    int page = 1,
    int perPage = 20,
  }) async {
    try {
      final models = await _remoteDatasource.getFeatureRequests(
        status: status,
        category: category,
        sortBy: sortBy,
        page: page,
        perPage: perPage,
      );
      return Success(models.map((m) => m.toEntity()).toList());
    } on ServerException catch (e) {
      return FailureResult(Failure.server(message: e.message, statusCode: e.statusCode, data: e.data));
    } on NetworkException catch (e) {
      return FailureResult(Failure.network(message: e.message));
    } catch (e) {
      return FailureResult(Failure.server(message: e.toString(), statusCode: 0));
    }
  }

  @override
  Future<Result<FeatureRequest>> createFeatureRequest({
    required String userId,
    required String title,
    required String description,
    required String category,
  }) async {
    try {
      final model = await _remoteDatasource.createFeatureRequest({
        'user_id': userId,
        'title': title,
        'description': description,
        'category': category,
      });
      return Success(model.toEntity());
    } on ServerException catch (e) {
      return FailureResult(Failure.server(message: e.message, statusCode: e.statusCode, data: e.data));
    } on NetworkException catch (e) {
      return FailureResult(Failure.network(message: e.message));
    } on ValidationException catch (e) {
      return FailureResult(Failure.validation(message: e.message, fieldErrors: e.fieldErrors));
    } catch (e) {
      return FailureResult(Failure.server(message: e.toString(), statusCode: 0));
    }
  }

  @override
  Future<Result<FeatureRequest>> voteFeatureRequest({
    required String featureRequestId,
    required String userId,
  }) async {
    try {
      final model = await _remoteDatasource.voteFeatureRequest(
        featureRequestId: featureRequestId,
        userId: userId,
      );
      return Success(model.toEntity());
    } on ServerException catch (e) {
      return FailureResult(Failure.server(message: e.message, statusCode: e.statusCode, data: e.data));
    } on NetworkException catch (e) {
      return FailureResult(Failure.network(message: e.message));
    } catch (e) {
      return FailureResult(Failure.server(message: e.toString(), statusCode: 0));
    }
  }

  @override
  Future<Result<List<String>>> getFeatureRequestVotes({required String userId}) async {
    try {
      final votes = await _remoteDatasource.getFeatureRequestVotes(userId);
      return Success(votes);
    } on ServerException catch (e) {
      return FailureResult(Failure.server(message: e.message, statusCode: e.statusCode, data: e.data));
    } on NetworkException catch (e) {
      return FailureResult(Failure.network(message: e.message));
    } catch (e) {
      return FailureResult(Failure.server(message: e.toString(), statusCode: 0));
    }
  }
}
