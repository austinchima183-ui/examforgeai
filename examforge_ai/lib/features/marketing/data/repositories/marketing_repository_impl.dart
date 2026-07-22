import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/utils/result.dart';
import '../../domain/entities/marketing_entities.dart';
import '../../domain/repositories/marketing_repository.dart';
import '../datasources/marketing_remote_datasource.dart';

/// Concrete implementation of [MarketingRepository].
class MarketingRepositoryImpl implements MarketingRepository {
  MarketingRepositoryImpl(this._remoteDatasource);
  final MarketingRemoteDatasource _remoteDatasource;

  Result<T> _handleError<T>(Object e) {
    if (e is ServerException) return FailureResult(Failure.server(message: e.message, statusCode: e.statusCode, data: e.data));
    if (e is NetworkException) return FailureResult(Failure.network(message: e.message));
    if (e is AuthException) return FailureResult(Failure.auth(message: e.message, code: e.code));
    if (e is NotFoundException) return FailureResult(Failure.notFound(message: e.message));
    if (e is ValidationException) return FailureResult(Failure.validation(fieldErrors: const {}, message: e.message, fieldErrors: e.fieldErrors));
    return FailureResult(Failure.server(message: e.toString(), statusCode: 0));
  }

  // ─── Landing Pages ─────────────────────────────────────────────────
  @override
  Future<Result<List<LandingPage>>> getLandingPages({bool? isPublished}) async {
    try {
      final models = await _remoteDatasource.getLandingPages(isPublished: isPublished);
      return Success(models.map((m) => m.toEntity()).toList());
    } catch (e) { return _handleError(e); }
  }

  @override
  Future<Result<LandingPage>> getLandingPageBySlug(String slug) async {
    try {
      final model = await _remoteDatasource.getLandingPageBySlug(slug);
      return Success(model.toEntity());
    } catch (e) { return _handleError(e); }
  }

  @override
  Future<Result<LandingPage>> createLandingPage(LandingPage landingPage) async {
    try {
      final model = await _remoteDatasource.createLandingPage({
        'slug': landingPage.slug, 'title': landingPage.title, 'sections': landingPage.sections,
        'seo_title': landingPage.seoTitle, 'seo_description': landingPage.seoDescription,
      });
      return Success(model.toEntity());
    } catch (e) { return _handleError(e); }
  }

  @override
  Future<Result<LandingPage>> updateLandingPage(LandingPage landingPage) async {
    try {
      final model = await _remoteDatasource.updateLandingPage(landingPage.id, {
        'title': landingPage.title, 'sections': landingPage.sections, 'is_published': landingPage.isPublished,
      });
      return Success(model.toEntity());
    } catch (e) { return _handleError(e); }
  }

  // ─── Blog Posts ────────────────────────────────────────────────────
  @override
  Future<Result<List<BlogPost>>> getBlogPosts({String? status, String? category, int page = 1, int perPage = 20}) async {
    try {
      final models = await _remoteDatasource.getBlogPosts(status: status, category: category, page: page, perPage: perPage);
      return Success(models.map((m) => m.toEntity()).toList());
    } catch (e) { return _handleError(e); }
  }

  @override
  Future<Result<BlogPost>> getBlogPostBySlug(String slug) async {
    try {
      final model = await _remoteDatasource.getBlogPostBySlug(slug);
      return Success(model.toEntity());
    } catch (e) { return _handleError(e); }
  }

  @override
  Future<Result<BlogPost>> createBlogPost(BlogPost blogPost) async {
    try {
      final model = await _remoteDatasource.createBlogPost({
        'title': blogPost.title, 'slug': blogPost.slug, 'excerpt': blogPost.excerpt,
        'content': blogPost.content, 'category': blogPost.category, 'tags': blogPost.tags,
        'author_id': blogPost.authorId, 'status': blogPost.status,
      });
      return Success(model.toEntity());
    } catch (e) { return _handleError(e); }
  }

  @override
  Future<Result<BlogPost>> updateBlogPost(BlogPost blogPost) async {
    try {
      final model = await _remoteDatasource.updateBlogPost(blogPost.id, {
        'title': blogPost.title, 'content': blogPost.content, 'category': blogPost.category,
        'status': blogPost.status, 'tags': blogPost.tags,
      });
      return Success(model.toEntity());
    } catch (e) { return _handleError(e); }
  }

  @override
  Future<Result<bool>> deleteBlogPost(String blogPostId) async {
    try {
      await _remoteDatasource.deleteBlogPost(blogPostId);
      return const Success(true);
    } catch (e) { return _handleError(e); }
  }

  // ─── Email Campaigns ───────────────────────────────────────────────
  @override
  Future<Result<List<EmailCampaign>>> getEmailCampaigns({String? status, int page = 1, int perPage = 20}) async {
    try {
      final models = await _remoteDatasource.getEmailCampaigns(status: status, page: page, perPage: perPage);
      return Success(models.map((m) => m.toEntity()).toList());
    } catch (e) { return _handleError(e); }
  }

  @override
  Future<Result<EmailCampaign>> getEmailCampaign(String campaignId) async {
    try {
      final model = await _remoteDatasource.getEmailCampaign(campaignId);
      return Success(model.toEntity());
    } catch (e) { return _handleError(e); }
  }

  @override
  Future<Result<EmailCampaign>> createEmailCampaign(Map<String, dynamic> payload) async {
    try {
      final model = await _remoteDatasource.createEmailCampaign(payload);
      return Success(model.toEntity());
    } catch (e) { return _handleError(e); }
  }

  @override
  Future<Result<EmailCampaign>> updateEmailCampaign(String campaignId, Map<String, dynamic> payload) async {
    try {
      final model = await _remoteDatasource.createEmailCampaign(payload);
      return Success(model.toEntity());
    } catch (e) { return _handleError(e); }
  }

  @override
  Future<Result<EmailCampaign>> sendEmailCampaign(String campaignId) async {
    try {
      final model = await _remoteDatasource.sendEmailCampaign(campaignId);
      return Success(model.toEntity());
    } catch (e) { return _handleError(e); }
  }

  @override
  Future<Result<EmailCampaign>> scheduleEmailCampaign(String campaignId, DateTime scheduledAt) async {
    try {
      final model = await _remoteDatasource.scheduleEmailCampaign(campaignId, scheduledAt);
      return Success(model.toEntity());
    } catch (e) { return _handleError(e); }
  }

  // ─── Referral Programs ─────────────────────────────────────────────
  @override
  Future<Result<List<ReferralProgram>>> getReferralPrograms({String? schoolId, bool? isActive}) async {
    try {
      final models = await _remoteDatasource.getReferralPrograms(schoolId: schoolId, isActive: isActive);
      return Success(models.map((m) => m.toEntity()).toList());
    } catch (e) { return _handleError(e); }
  }

  @override
  Future<Result<ReferralProgram>> getReferralProgram(String programId) async {
    try {
      final model = await _remoteDatasource.getReferralProgram(programId);
      return Success(model.toEntity());
    } catch (e) { return _handleError(e); }
  }

  @override
  Future<Result<ReferralProgram>> createReferralProgram(Map<String, dynamic> payload) async {
    try {
      final model = await _remoteDatasource.createReferralProgram(payload);
      return Success(model.toEntity());
    } catch (e) { return _handleError(e); }
  }

  @override
  Future<Result<ReferralProgram>> updateReferralProgram(ReferralProgram program) async {
    try {
      final model = await _remoteDatasource.updateReferralProgram(program.id, {
        'name': program.name, 'description': program.description, 'is_active': program.isActive,
      });
      return Success(model.toEntity());
    } catch (e) { return _handleError(e); }
  }

  @override
  Future<Result<List<Referral>>> getReferrals({required String programId, String? status, int page = 1, int perPage = 20}) async {
    try {
      final models = await _remoteDatasource.getReferrals(programId: programId, status: status, page: page, perPage: perPage);
      return Success(models.map((m) => m.toEntity()).toList());
    } catch (e) { return _handleError(e); }
  }

  @override
  Future<Result<Referral>> trackReferral({required String referralCode, required String referredEmail}) async {
    try {
      final model = await _remoteDatasource.trackReferral(referralCode: referralCode, referredEmail: referredEmail);
      return Success(model.toEntity());
    } catch (e) { return _handleError(e); }
  }

  // ─── Affiliate Program ─────────────────────────────────────────────
  @override
  Future<Result<List<Affiliate>>> getAffiliates({AffiliateStatus? status, int page = 1, int perPage = 20}) async {
    try {
      final models = await _remoteDatasource.getAffiliates(status: status?.value, page: page, perPage: perPage);
      return Success(models.map((m) => m.toEntity()).toList());
    } catch (e) { return _handleError(e); }
  }

  @override
  Future<Result<Affiliate>> getAffiliate(String affiliateId) async {
    try {
      final model = await _remoteDatasource.getAffiliate(affiliateId);
      return Success(model.toEntity());
    } catch (e) { return _handleError(e); }
  }

  @override
  Future<Result<Affiliate>> createAffiliate({required String userId, required String affiliateCode}) async {
    try {
      final model = await _remoteDatasource.createAffiliate({'user_id': userId, 'affiliate_code': affiliateCode});
      return Success(model.toEntity());
    } catch (e) { return _handleError(e); }
  }

  @override
  Future<Result<Affiliate>> updateAffiliateStatus({required String affiliateId, required AffiliateStatus status}) async {
    try {
      final model = await _remoteDatasource.updateAffiliateStatus(affiliateId, status.value);
      return Success(model.toEntity());
    } catch (e) { return _handleError(e); }
  }

  @override
  Future<Result<List<AffiliateReferral>>> getAffiliateReferrals({required String affiliateId, int page = 1, int perPage = 20}) async {
    try {
      final models = await _remoteDatasource.getAffiliateReferrals(affiliateId: affiliateId, page: page, perPage: perPage);
      return Success(models.map((m) => m.toEntity()).toList());
    } catch (e) { return _handleError(e); }
  }

  @override
  Future<Result<Map<String, dynamic>>> getAffiliateAnalytics({required String affiliateId}) async {
    try {
      final data = await _remoteDatasource.getAffiliateAnalytics(affiliateId);
      return Success(data);
    } catch (e) { return _handleError(e); }
  }
}
