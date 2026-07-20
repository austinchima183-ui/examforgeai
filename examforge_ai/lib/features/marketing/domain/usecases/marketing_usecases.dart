import '../../../../core/utils/result.dart';
import '../entities/marketing_entities.dart';
import '../repositories/marketing_repository.dart';

// ============================================================================
// PARAMS CLASSES
// ============================================================================

class GetLandingPagesParams {
  final bool? isPublished;
  const GetLandingPagesParams({this.isPublished});
}

class GetLandingPageBySlugParams {
  final String slug;
  const GetLandingPageBySlugParams({required this.slug});
}

class CreateLandingPageParams {
  final LandingPage landingPage;
  const CreateLandingPageParams({required this.landingPage});
}

class UpdateLandingPageParams {
  final LandingPage landingPage;
  const UpdateLandingPageParams({required this.landingPage});
}

class GetBlogPostsParams {
  final String? status;
  final String? category;
  final int page;
  final int perPage;
  const GetBlogPostsParams({this.status, this.category, this.page = 1, this.perPage = 20});
}

class GetBlogPostBySlugParams {
  final String slug;
  const GetBlogPostBySlugParams({required this.slug});
}

class CreateBlogPostParams {
  final BlogPost blogPost;
  const CreateBlogPostParams({required this.blogPost});
}

class UpdateBlogPostParams {
  final BlogPost blogPost;
  const UpdateBlogPostParams({required this.blogPost});
}

class DeleteBlogPostParams {
  final String blogPostId;
  const DeleteBlogPostParams({required this.blogPostId});
}

class GetEmailCampaignsParams {
  final String? status;
  final int page;
  final int perPage;
  const GetEmailCampaignsParams({this.status, this.page = 1, this.perPage = 20});
}

class GetEmailCampaignParams {
  final String campaignId;
  const GetEmailCampaignParams({required this.campaignId});
}

class CreateEmailCampaignParams {
  final Map<String, dynamic> payload;
  const CreateEmailCampaignParams({required this.payload});
}

class SendEmailCampaignParams {
  final String campaignId;
  const SendEmailCampaignParams({required this.campaignId});
}

class ScheduleEmailCampaignParams {
  final String campaignId;
  final DateTime scheduledAt;
  const ScheduleEmailCampaignParams({required this.campaignId, required this.scheduledAt});
}

class GetReferralProgramsParams {
  final String? schoolId;
  final bool? isActive;
  const GetReferralProgramsParams({this.schoolId, this.isActive});
}

class GetReferralProgramParams {
  final String programId;
  const GetReferralProgramParams({required this.programId});
}

class CreateReferralProgramParams {
  final Map<String, dynamic> payload;
  const CreateReferralProgramParams({required this.payload});
}

class UpdateReferralProgramParams {
  final ReferralProgram program;
  const UpdateReferralProgramParams({required this.program});
}

class GetReferralsParams {
  final String programId;
  final String? status;
  final int page;
  final int perPage;
  const GetReferralsParams({required this.programId, this.status, this.page = 1, this.perPage = 20});
}

class TrackReferralParams {
  final String referralCode;
  final String referredEmail;
  const TrackReferralParams({required this.referralCode, required this.referredEmail});
}

class GetAffiliatesParams {
  final AffiliateStatus? status;
  final int page;
  final int perPage;
  const GetAffiliatesParams({this.status, this.page = 1, this.perPage = 20});
}

class GetAffiliateParams {
  final String affiliateId;
  const GetAffiliateParams({required this.affiliateId});
}

class CreateAffiliateParams {
  final String userId;
  final String affiliateCode;
  const CreateAffiliateParams({required this.userId, required this.affiliateCode});
}

class UpdateAffiliateStatusParams {
  final String affiliateId;
  final AffiliateStatus status;
  const UpdateAffiliateStatusParams({required this.affiliateId, required this.status});
}

class GetAffiliateReferralsParams {
  final String affiliateId;
  final int page;
  final int perPage;
  const GetAffiliateReferralsParams({required this.affiliateId, this.page = 1, this.perPage = 20});
}

class GetAffiliateAnalyticsParams {
  final String affiliateId;
  const GetAffiliateAnalyticsParams({required this.affiliateId});
}

// ============================================================================
// USE CASES
// ============================================================================

class GetLandingPagesUseCase {
  final MarketingRepository _repo;
  GetLandingPagesUseCase(this._repo);
  Future<Result<List<LandingPage>>> call(GetLandingPagesParams p) => _repo.getLandingPages(isPublished: p.isPublished);
}

class GetLandingPageBySlugUseCase {
  final MarketingRepository _repo;
  GetLandingPageBySlugUseCase(this._repo);
  Future<Result<LandingPage>> call(GetLandingPageBySlugParams p) => _repo.getLandingPageBySlug(p.slug);
}

class CreateLandingPageUseCase {
  final MarketingRepository _repo;
  CreateLandingPageUseCase(this._repo);
  Future<Result<LandingPage>> call(CreateLandingPageParams p) => _repo.createLandingPage(p.landingPage);
}

class UpdateLandingPageUseCase {
  final MarketingRepository _repo;
  UpdateLandingPageUseCase(this._repo);
  Future<Result<LandingPage>> call(UpdateLandingPageParams p) => _repo.updateLandingPage(p.landingPage);
}

class GetBlogPostsUseCase {
  final MarketingRepository _repo;
  GetBlogPostsUseCase(this._repo);
  Future<Result<List<BlogPost>>> call(GetBlogPostsParams p) => _repo.getBlogPosts(status: p.status, category: p.category, page: p.page, perPage: p.perPage);
}

class GetBlogPostBySlugUseCase {
  final MarketingRepository _repo;
  GetBlogPostBySlugUseCase(this._repo);
  Future<Result<BlogPost>> call(GetBlogPostBySlugParams p) => _repo.getBlogPostBySlug(p.slug);
}

class CreateBlogPostUseCase {
  final MarketingRepository _repo;
  CreateBlogPostUseCase(this._repo);
  Future<Result<BlogPost>> call(CreateBlogPostParams p) => _repo.createBlogPost(p.blogPost);
}

class UpdateBlogPostUseCase {
  final MarketingRepository _repo;
  UpdateBlogPostUseCase(this._repo);
  Future<Result<BlogPost>> call(UpdateBlogPostParams p) => _repo.updateBlogPost(p.blogPost);
}

class DeleteBlogPostUseCase {
  final MarketingRepository _repo;
  DeleteBlogPostUseCase(this._repo);
  Future<Result<bool>> call(DeleteBlogPostParams p) => _repo.deleteBlogPost(p.blogPostId);
}

class GetEmailCampaignsUseCase {
  final MarketingRepository _repo;
  GetEmailCampaignsUseCase(this._repo);
  Future<Result<List<EmailCampaign>>> call(GetEmailCampaignsParams p) => _repo.getEmailCampaigns(status: p.status, page: p.page, perPage: p.perPage);
}

class GetEmailCampaignUseCase {
  final MarketingRepository _repo;
  GetEmailCampaignUseCase(this._repo);
  Future<Result<EmailCampaign>> call(GetEmailCampaignParams p) => _repo.getEmailCampaign(p.campaignId);
}

class CreateEmailCampaignUseCase {
  final MarketingRepository _repo;
  CreateEmailCampaignUseCase(this._repo);
  Future<Result<EmailCampaign>> call(CreateEmailCampaignParams p) => _repo.createEmailCampaign(p.payload);
}

class SendEmailCampaignUseCase {
  final MarketingRepository _repo;
  SendEmailCampaignUseCase(this._repo);
  Future<Result<EmailCampaign>> call(SendEmailCampaignParams p) => _repo.sendEmailCampaign(p.campaignId);
}

class ScheduleEmailCampaignUseCase {
  final MarketingRepository _repo;
  ScheduleEmailCampaignUseCase(this._repo);
  Future<Result<EmailCampaign>> call(ScheduleEmailCampaignParams p) => _repo.scheduleEmailCampaign(p.campaignId, p.scheduledAt);
}

class GetReferralProgramsUseCase {
  final MarketingRepository _repo;
  GetReferralProgramsUseCase(this._repo);
  Future<Result<List<ReferralProgram>>> call(GetReferralProgramsParams p) => _repo.getReferralPrograms(schoolId: p.schoolId, isActive: p.isActive);
}

class GetReferralProgramUseCase {
  final MarketingRepository _repo;
  GetReferralProgramUseCase(this._repo);
  Future<Result<ReferralProgram>> call(GetReferralProgramParams p) => _repo.getReferralProgram(p.programId);
}

class CreateReferralProgramUseCase {
  final MarketingRepository _repo;
  CreateReferralProgramUseCase(this._repo);
  Future<Result<ReferralProgram>> call(CreateReferralProgramParams p) => _repo.createReferralProgram(p.payload);
}

class UpdateReferralProgramUseCase {
  final MarketingRepository _repo;
  UpdateReferralProgramUseCase(this._repo);
  Future<Result<ReferralProgram>> call(UpdateReferralProgramParams p) => _repo.updateReferralProgram(p.program);
}

class GetReferralsUseCase {
  final MarketingRepository _repo;
  GetReferralsUseCase(this._repo);
  Future<Result<List<Referral>>> call(GetReferralsParams p) => _repo.getReferrals(programId: p.programId, status: p.status, page: p.page, perPage: p.perPage);
}

class TrackReferralUseCase {
  final MarketingRepository _repo;
  TrackReferralUseCase(this._repo);
  Future<Result<Referral>> call(TrackReferralParams p) => _repo.trackReferral(referralCode: p.referralCode, referredEmail: p.referredEmail);
}

class GetAffiliatesUseCase {
  final MarketingRepository _repo;
  GetAffiliatesUseCase(this._repo);
  Future<Result<List<Affiliate>>> call(GetAffiliatesParams p) => _repo.getAffiliates(status: p.status, page: p.page, perPage: p.perPage);
}

class GetAffiliateUseCase {
  final MarketingRepository _repo;
  GetAffiliateUseCase(this._repo);
  Future<Result<Affiliate>> call(GetAffiliateParams p) => _repo.getAffiliate(p.affiliateId);
}

class CreateAffiliateUseCase {
  final MarketingRepository _repo;
  CreateAffiliateUseCase(this._repo);
  Future<Result<Affiliate>> call(CreateAffiliateParams p) => _repo.createAffiliate(userId: p.userId, affiliateCode: p.affiliateCode);
}

class UpdateAffiliateStatusUseCase {
  final MarketingRepository _repo;
  UpdateAffiliateStatusUseCase(this._repo);
  Future<Result<Affiliate>> call(UpdateAffiliateStatusParams p) => _repo.updateAffiliateStatus(affiliateId: p.affiliateId, status: p.status);
}

class GetAffiliateReferralsUseCase {
  final MarketingRepository _repo;
  GetAffiliateReferralsUseCase(this._repo);
  Future<Result<List<AffiliateReferral>>> call(GetAffiliateReferralsParams p) => _repo.getAffiliateReferrals(affiliateId: p.affiliateId, page: p.page, perPage: p.perPage);
}

class GetAffiliateAnalyticsUseCase {
  final MarketingRepository _repo;
  GetAffiliateAnalyticsUseCase(this._repo);
  Future<Result<Map<String, dynamic>>> call(GetAffiliateAnalyticsParams p) => _repo.getAffiliateAnalytics(affiliateId: p.affiliateId);
}
