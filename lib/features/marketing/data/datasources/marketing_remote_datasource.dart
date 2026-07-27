import '../../../../core/network/api_client.dart';
import '../models/marketing_models.dart';

/// Remote data source for Marketing feature.
class MarketingRemoteDatasource {
  MarketingRemoteDatasource(this._apiClient);
  final ApiClient _apiClient;
  static const String _basePath = '/marketing';

  // ─── Landing Pages ─────────────────────────────────────────────────
  Future<List<LandingPageModel>> getLandingPages({bool? isPublished}) async {
    final response = await _apiClient.get('$_basePath/landing-pages', queryParameters: {if (isPublished != null) 'is_published': isPublished});
    final data = response.data as List?;
    return data?.map((e) => LandingPageModel.fromJson(e as Map<String, dynamic>)).toList() ?? [];
  }

  Future<LandingPageModel> getLandingPageBySlug(String slug) async {
    final response = await _apiClient.get('$_basePath/landing-pages/$slug');
    return LandingPageModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<LandingPageModel> createLandingPage(Map<String, dynamic> payload) async {
    final response = await _apiClient.post('$_basePath/landing-pages', data: payload);
    return LandingPageModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<LandingPageModel> updateLandingPage(String id, Map<String, dynamic> payload) async {
    final response = await _apiClient.put('$_basePath/landing-pages/$id', data: payload);
    return LandingPageModel.fromJson(response.data as Map<String, dynamic>);
  }

  // ─── Blog Posts ────────────────────────────────────────────────────
  Future<List<BlogPostModel>> getBlogPosts({String? status, String? category, int page = 1, int perPage = 20}) async {
    final response = await _apiClient.get('$_basePath/blog-posts', queryParameters: {if (status != null) 'status': status, if (category != null) 'category': category, 'page': page, 'per_page': perPage});
    final data = response.data as List?;
    return data?.map((e) => BlogPostModel.fromJson(e as Map<String, dynamic>)).toList() ?? [];
  }

  Future<BlogPostModel> getBlogPostBySlug(String slug) async {
    final response = await _apiClient.get('$_basePath/blog-posts/$slug');
    return BlogPostModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<BlogPostModel> createBlogPost(Map<String, dynamic> payload) async {
    final response = await _apiClient.post('$_basePath/blog-posts', data: payload);
    return BlogPostModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<BlogPostModel> updateBlogPost(String id, Map<String, dynamic> payload) async {
    final response = await _apiClient.put('$_basePath/blog-posts/$id', data: payload);
    return BlogPostModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> deleteBlogPost(String id) async {
    await _apiClient.delete('$_basePath/blog-posts/$id');
  }

  // ─── Email Campaigns ───────────────────────────────────────────────
  Future<List<EmailCampaignModel>> getEmailCampaigns({String? status, int page = 1, int perPage = 20}) async {
    final response = await _apiClient.get('$_basePath/email-campaigns', queryParameters: {if (status != null) 'status': status, 'page': page, 'per_page': perPage});
    final data = response.data as List?;
    return data?.map((e) => EmailCampaignModel.fromJson(e as Map<String, dynamic>)).toList() ?? [];
  }

  Future<EmailCampaignModel> getEmailCampaign(String id) async {
    final response = await _apiClient.get('$_basePath/email-campaigns/$id');
    return EmailCampaignModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<EmailCampaignModel> createEmailCampaign(Map<String, dynamic> payload) async {
    final response = await _apiClient.post('$_basePath/email-campaigns', data: payload);
    return EmailCampaignModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<EmailCampaignModel> sendEmailCampaign(String id) async {
    final response = await _apiClient.post('$_basePath/email-campaigns/$id/send');
    return EmailCampaignModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<EmailCampaignModel> scheduleEmailCampaign(String id, DateTime scheduledAt) async {
    final response = await _apiClient.post('$_basePath/email-campaigns/$id/schedule', data: {'scheduled_at': scheduledAt.toIso8601String()});
    return EmailCampaignModel.fromJson(response.data as Map<String, dynamic>);
  }

  // ─── Referral Programs ─────────────────────────────────────────────
  Future<List<ReferralProgramModel>> getReferralPrograms({String? schoolId, bool? isActive}) async {
    final response = await _apiClient.get('$_basePath/referral-programs', queryParameters: {if (schoolId != null) 'school_id': schoolId, if (isActive != null) 'is_active': isActive});
    final data = response.data as List?;
    return data?.map((e) => ReferralProgramModel.fromJson(e as Map<String, dynamic>)).toList() ?? [];
  }

  Future<ReferralProgramModel> getReferralProgram(String id) async {
    final response = await _apiClient.get('$_basePath/referral-programs/$id');
    return ReferralProgramModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<ReferralProgramModel> createReferralProgram(Map<String, dynamic> payload) async {
    final response = await _apiClient.post('$_basePath/referral-programs', data: payload);
    return ReferralProgramModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<ReferralProgramModel> updateReferralProgram(String id, Map<String, dynamic> payload) async {
    final response = await _apiClient.put('$_basePath/referral-programs/$id', data: payload);
    return ReferralProgramModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<List<ReferralModel>> getReferrals({required String programId, String? status, int page = 1, int perPage = 20}) async {
    final response = await _apiClient.get('$_basePath/referral-programs/$programId/referrals', queryParameters: {if (status != null) 'status': status, 'page': page, 'per_page': perPage});
    final data = response.data as List?;
    return data?.map((e) => ReferralModel.fromJson(e as Map<String, dynamic>)).toList() ?? [];
  }

  Future<ReferralModel> trackReferral({required String referralCode, required String referredEmail}) async {
    final response = await _apiClient.post('$_basePath/referrals/track', data: {'referral_code': referralCode, 'referred_email': referredEmail});
    return ReferralModel.fromJson(response.data as Map<String, dynamic>);
  }

  // ─── Affiliate Program ─────────────────────────────────────────────
  Future<List<AffiliateModel>> getAffiliates({String? status, int page = 1, int perPage = 20}) async {
    final response = await _apiClient.get('$_basePath/affiliates', queryParameters: {if (status != null) 'status': status, 'page': page, 'per_page': perPage});
    final data = response.data as List?;
    return data?.map((e) => AffiliateModel.fromJson(e as Map<String, dynamic>)).toList() ?? [];
  }

  Future<AffiliateModel> getAffiliate(String id) async {
    final response = await _apiClient.get('$_basePath/affiliates/$id');
    return AffiliateModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<AffiliateModel> createAffiliate(Map<String, dynamic> payload) async {
    final response = await _apiClient.post('$_basePath/affiliates', data: payload);
    return AffiliateModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<AffiliateModel> updateAffiliateStatus(String id, String status) async {
    final response = await _apiClient.patch('$_basePath/affiliates/$id/status', data: {'status': status});
    return AffiliateModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<List<AffiliateReferralModel>> getAffiliateReferrals({required String affiliateId, int page = 1, int perPage = 20}) async {
    final response = await _apiClient.get('$_basePath/affiliates/$affiliateId/referrals', queryParameters: {'page': page, 'per_page': perPage});
    final data = response.data as List?;
    return data?.map((e) => AffiliateReferralModel.fromJson(e as Map<String, dynamic>)).toList() ?? [];
  }

  Future<Map<String, dynamic>> getAffiliateAnalytics(String affiliateId) async {
    final response = await _apiClient.get('$_basePath/affiliates/$affiliateId/analytics');
    return Map<String, dynamic>.from(response.data as Map);
  }
}
