import '../../../../core/utils/result.dart';
import '../entities/marketing_entities.dart';

/// Abstract contract for the Marketing repository.
abstract class MarketingRepository {
  // ─── Landing Pages ─────────────────────────────────────────────────
  Future<Result<List<LandingPage>>> getLandingPages({bool? isPublished});
  Future<Result<LandingPage>> getLandingPageBySlug(String slug);
  Future<Result<LandingPage>> createLandingPage(LandingPage landingPage);
  Future<Result<LandingPage>> updateLandingPage(LandingPage landingPage);

  // ─── Blog Posts ────────────────────────────────────────────────────
  Future<Result<List<BlogPost>>> getBlogPosts({String? status, String? category, int page = 1, int perPage = 20});
  Future<Result<BlogPost>> getBlogPostBySlug(String slug);
  Future<Result<BlogPost>> createBlogPost(BlogPost blogPost);
  Future<Result<BlogPost>> updateBlogPost(BlogPost blogPost);
  Future<Result<bool>> deleteBlogPost(String blogPostId);

  // ─── Email Campaigns ───────────────────────────────────────────────
  Future<Result<List<EmailCampaign>>> getEmailCampaigns({String? status, int page = 1, int perPage = 20});
  Future<Result<EmailCampaign>> getEmailCampaign(String campaignId);
  Future<Result<EmailCampaign>> createEmailCampaign(Map<String, dynamic> payload);
  Future<Result<EmailCampaign>> updateEmailCampaign(String campaignId, Map<String, dynamic> payload);
  Future<Result<EmailCampaign>> sendEmailCampaign(String campaignId);
  Future<Result<EmailCampaign>> scheduleEmailCampaign(String campaignId, DateTime scheduledAt);

  // ─── Referral Programs ─────────────────────────────────────────────
  Future<Result<List<ReferralProgram>>> getReferralPrograms({String? schoolId, bool? isActive});
  Future<Result<ReferralProgram>> getReferralProgram(String programId);
  Future<Result<ReferralProgram>> createReferralProgram(Map<String, dynamic> payload);
  Future<Result<ReferralProgram>> updateReferralProgram(ReferralProgram program);
  Future<Result<List<Referral>>> getReferrals({required String programId, String? status, int page = 1, int perPage = 20});
  Future<Result<Referral>> trackReferral({required String referralCode, required String referredEmail});

  // ─── Affiliate Program ─────────────────────────────────────────────
  Future<Result<List<Affiliate>>> getAffiliates({AffiliateStatus? status, int page = 1, int perPage = 20});
  Future<Result<Affiliate>> getAffiliate(String affiliateId);
  Future<Result<Affiliate>> createAffiliate({required String userId, required String affiliateCode});
  Future<Result<Affiliate>> updateAffiliateStatus({required String affiliateId, required AffiliateStatus status});
  Future<Result<List<AffiliateReferral>>> getAffiliateReferrals({required String affiliateId, int page = 1, int perPage = 20});
  Future<Result<Map<String, dynamic>>> getAffiliateAnalytics({required String affiliateId});
}
