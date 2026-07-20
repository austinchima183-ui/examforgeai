// ============================================================================
// ExamForge AI — Final Production DI Registration
// Exam Ecosystem, Admission Hub, AI Coach, Customer Success,
// Marketing, EduOS, Analytics Dashboard
// ============================================================================

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;
import 'package:examforge_ai/config/supabase_config.dart';
import 'package:examforge_ai/services/storage_service.dart';

// Domain
import 'package:examforge_ai/features/exam_ecosystem/domain/repositories/exam_ecosystem_repository.dart';
import 'package:examforge_ai/features/exam_ecosystem/domain/usecases/exam_ecosystem_usecases.dart';
import 'package:examforge_ai/features/admission_hub/domain/repositories/admission_hub_repository.dart';
import 'package:examforge_ai/features/admission_hub/domain/usecases/admission_hub_usecases.dart';
import 'package:examforge_ai/features/ai_coach/domain/repositories/ai_coach_repository.dart';
import 'package:examforge_ai/features/ai_coach/domain/usecases/ai_coach_usecases.dart';
import 'package:examforge_ai/features/customer_success/domain/repositories/customer_success_repository.dart';
import 'package:examforge_ai/features/customer_success/domain/usecases/customer_success_usecases.dart';
import 'package:examforge_ai/features/marketing/domain/repositories/marketing_repository.dart';
import 'package:examforge_ai/features/marketing/domain/usecases/marketing_usecases.dart';
import 'package:examforge_ai/features/edu_os/domain/repositories/edu_os_repository.dart';
import 'package:examforge_ai/features/edu_os/domain/usecases/edu_os_usecases.dart';
import 'package:examforge_ai/features/analytics_dashboard/domain/repositories/analytics_dashboard_repository.dart';
import 'package:examforge_ai/features/analytics_dashboard/domain/usecases/analytics_dashboard_usecases.dart';

// Data
import 'package:examforge_ai/features/exam_ecosystem/data/datasources/exam_ecosystem_remote_datasource.dart';
import 'package:examforge_ai/features/exam_ecosystem/data/repositories/exam_ecosystem_repository_impl.dart';
import 'package:examforge_ai/features/admission_hub/data/datasources/admission_hub_remote_datasource.dart';
import 'package:examforge_ai/features/admission_hub/data/repositories/admission_hub_repository_impl.dart';
import 'package:examforge_ai/features/ai_coach/data/datasources/ai_coach_remote_datasource.dart';
import 'package:examforge_ai/features/ai_coach/data/repositories/ai_coach_repository_impl.dart';
import 'package:examforge_ai/features/customer_success/data/datasources/customer_success_remote_datasource.dart';
import 'package:examforge_ai/features/customer_success/data/repositories/customer_success_repository_impl.dart';
import 'package:examforge_ai/features/marketing/data/datasources/marketing_remote_datasource.dart';
import 'package:examforge_ai/features/marketing/data/repositories/marketing_repository_impl.dart';
import 'package:examforge_ai/features/edu_os/data/datasources/edu_os_remote_datasource.dart';
import 'package:examforge_ai/features/edu_os/data/repositories/edu_os_repository_impl.dart';
import 'package:examforge_ai/features/analytics_dashboard/data/datasources/analytics_dashboard_remote_datasource.dart';
import 'package:examforge_ai/features/analytics_dashboard/data/repositories/analytics_dashboard_repository_impl.dart';

// Presentation
import 'package:examforge_ai/features/exam_ecosystem/presentation/providers/exam_ecosystem_provider.dart';
import 'package:examforge_ai/features/admission_hub/presentation/providers/admission_hub_provider.dart';
import 'package:examforge_ai/features/ai_coach/presentation/providers/ai_coach_provider.dart';
import 'package:examforge_ai/features/customer_success/presentation/providers/customer_success_provider.dart';
import 'package:examforge_ai/features/marketing/presentation/providers/marketing_provider.dart';
import 'package:examforge_ai/features/edu_os/presentation/providers/edu_os_provider.dart';
import 'package:examforge_ai/features/analytics_dashboard/presentation/providers/analytics_dashboard_provider.dart';

// ═══════════════════════════════════════════════════════════════════════
// EXAM ECOSYSTEM
// ═══════════════════════════════════════════════════════════════════════

final examEcosystemRemoteDataSourceProvider = Provider<ExamEcosystemRemoteDataSource>((ref) {
  return ExamEcosystemRemoteDataSourceImpl(supabase: ref.watch(supabaseClientProvider));
});

final examEcosystemRepositoryProvider = Provider<ExamEcosystemRepository>((ref) {
  return ExamEcosystemRepositoryImpl(
    remoteDataSource: ref.watch(examEcosystemRemoteDataSourceProvider),
    storageService: ref.watch(storageServiceProvider),
  );
});

// Use Cases
final getExaminationBodiesUseCaseProvider = Provider<GetExaminationBodiesUseCase>((ref) => GetExaminationBodiesUseCase(ref.watch(examEcosystemRepositoryProvider)));
final getExaminationProductsUseCaseProvider = Provider<GetExaminationProductsUseCase>((ref) => GetExaminationProductsUseCase(ref.watch(examEcosystemRepositoryProvider)));
final createExaminationProductUseCaseProvider = Provider<CreateExaminationProductUseCase>((ref) => CreateExaminationProductUseCase(ref.watch(examEcosystemRepositoryProvider)));
final getMockExamsUseCaseProvider = Provider<GetMockExamsUseCase>((ref) => GetMockExamsUseCase(ref.watch(examEcosystemRepositoryProvider)));
final createMockExamUseCaseProvider = Provider<CreateMockExamUseCase>((ref) => CreateMockExamUseCase(ref.watch(examEcosystemRepositoryProvider)));
final publishMockExamUseCaseProvider = Provider<PublishMockExamUseCase>((ref) => PublishMockExamUseCase(ref.watch(examEcosystemRepositoryProvider)));
final startMockExamAttemptUseCaseProvider = Provider<StartMockExamAttemptUseCase>((ref) => StartMockExamAttemptUseCase(ref.watch(examEcosystemRepositoryProvider)));
final submitMockExamAttemptUseCaseProvider = Provider<SubmitMockExamAttemptUseCase>((ref) => SubmitMockExamAttemptUseCase(ref.watch(examEcosystemRepositoryProvider)));
final getMockExamResultsUseCaseProvider = Provider<GetMockExamResultsUseCase>((ref) => GetMockExamResultsUseCase(ref.watch(examEcosystemRepositoryProvider)));
final getReadinessAssessmentUseCaseProvider = Provider<GetReadinessAssessmentUseCase>((ref) => GetReadinessAssessmentUseCase(ref.watch(examEcosystemRepositoryProvider)));
final calculateReadinessUseCaseProvider = Provider<CalculateReadinessUseCase>((ref) => CalculateReadinessUseCase(ref.watch(examEcosystemRepositoryProvider)));
final getExamReadinessUseCaseProvider = Provider<GetExamReadinessUseCase>((ref) => GetExamReadinessUseCase(ref.watch(examEcosystemRepositoryProvider)));
final getStudyPlansUseCaseProvider = Provider<GetStudyPlansUseCase>((ref) => GetStudyPlansUseCase(ref.watch(examEcosystemRepositoryProvider)));
final createStudyPlanUseCaseProvider = Provider<CreateStudyPlanUseCase>((ref) => CreateStudyPlanUseCase(ref.watch(examEcosystemRepositoryProvider)));
final generateAiStudyPlanUseCaseProvider = Provider<GenerateAiStudyPlanUseCase>((ref) => GenerateAiStudyPlanUseCase(ref.watch(examEcosystemRepositoryProvider)));
final getStudyPlanActivitiesUseCaseProvider = Provider<GetStudyPlanActivitiesUseCase>((ref) => GetStudyPlanActivitiesUseCase(ref.watch(examEcosystemRepositoryProvider)));
final completeStudyPlanActivityUseCaseProvider = Provider<CompleteStudyPlanActivityUseCase>((ref) => CompleteStudyPlanActivityUseCase(ref.watch(examEcosystemRepositoryProvider)));

// ═══════════════════════════════════════════════════════════════════════
// ADMISSION HUB
// ═══════════════════════════════════════════════════════════════════════

final admissionHubRemoteDataSourceProvider = Provider<AdmissionHubRemoteDataSource>((ref) {
  return AdmissionHubRemoteDataSourceImpl(supabase: ref.watch(supabaseClientProvider));
});

final admissionHubRepositoryProvider = Provider<AdmissionHubRepository>((ref) {
  return AdmissionHubRepositoryImpl(
    remoteDataSource: ref.watch(admissionHubRemoteDataSourceProvider),
    storageService: ref.watch(storageServiceProvider),
  );
});

final getUniversitiesUseCaseProvider = Provider<GetUniversitiesUseCase>((ref) => GetUniversitiesUseCase(ref.watch(admissionHubRepositoryProvider)));
final searchUniversitiesUseCaseProvider = Provider<SearchUniversitiesUseCase>((ref) => SearchUniversitiesUseCase(ref.watch(admissionHubRepositoryProvider)));
final getUniversityDepartmentsUseCaseProvider = Provider<GetUniversityDepartmentsUseCase>((ref) => GetUniversityDepartmentsUseCase(ref.watch(admissionHubRepositoryProvider)));
final checkAdmissionEligibilityUseCaseProvider = Provider<CheckAdmissionEligibilityUseCase>((ref) => CheckAdmissionEligibilityUseCase(ref.watch(admissionHubRepositoryProvider)));
final getPostUtmeProductsUseCaseProvider = Provider<GetPostUtmeProductsUseCase>((ref) => GetPostUtmeProductsUseCase(ref.watch(admissionHubRepositoryProvider)));
final createPostUtmeProductUseCaseProvider = Provider<CreatePostUtmeProductUseCase>((ref) => CreatePostUtmeProductUseCase(ref.watch(admissionHubRepositoryProvider)));
final getAdmissionChecklistUseCaseProvider = Provider<GetAdmissionChecklistUseCase>((ref) => GetAdmissionChecklistUseCase(ref.watch(admissionHubRepositoryProvider)));
final updateAdmissionChecklistUseCaseProvider = Provider<UpdateAdmissionChecklistUseCase>((ref) => UpdateAdmissionChecklistUseCase(ref.watch(admissionHubRepositoryProvider)));
final createAdmissionApplicationUseCaseProvider = Provider<CreateAdmissionApplicationUseCase>((ref) => CreateAdmissionApplicationUseCase(ref.watch(admissionHubRepositoryProvider)));
final compareUniversitiesUseCaseProvider = Provider<CompareUniversitiesUseCase>((ref) => CompareUniversitiesUseCase(ref.watch(admissionHubRepositoryProvider)));

// ═══════════════════════════════════════════════════════════════════════
// AI COACH
// ═══════════════════════════════════════════════════════════════════════

final aiCoachRemoteDataSourceProvider = Provider<AiCoachRemoteDataSource>((ref) {
  return AiCoachRemoteDataSourceImpl(supabase: ref.watch(supabaseClientProvider));
});

final aiCoachRepositoryProvider = Provider<AiCoachRepository>((ref) {
  return AiCoachRepositoryImpl(
    remoteDataSource: ref.watch(aiCoachRemoteDataSourceProvider),
    storageService: ref.watch(storageServiceProvider),
  );
});

final getCoachSessionsUseCaseProvider = Provider<GetCoachSessionsUseCase>((ref) => GetCoachSessionsUseCase(ref.watch(aiCoachRepositoryProvider)));
final createCoachSessionUseCaseProvider = Provider<CreateCoachSessionUseCase>((ref) => CreateCoachSessionUseCase(ref.watch(aiCoachRepositoryProvider)));
final updateCoachSessionUseCaseProvider = Provider<UpdateCoachSessionUseCase>((ref) => UpdateCoachSessionUseCase(ref.watch(aiCoachRepositoryProvider)));
final getRecommendationsUseCaseProvider = Provider<GetRecommendationsUseCase>((ref) => GetRecommendationsUseCase(ref.watch(aiCoachRepositoryProvider)));
final dismissRecommendationUseCaseProvider = Provider<DismissRecommendationUseCase>((ref) => DismissRecommendationUseCase(ref.watch(aiCoachRepositoryProvider)));
final generateStudyPlanCoachUseCaseProvider = Provider<GenerateStudyPlanCoachUseCase>((ref) => GenerateStudyPlanCoachUseCase(ref.watch(aiCoachRepositoryProvider)));
final detectWeakTopicsUseCaseProvider = Provider<DetectWeakTopicsUseCase>((ref) => DetectWeakTopicsUseCase(ref.watch(aiCoachRepositoryProvider)));
final predictReadinessUseCaseProvider = Provider<PredictReadinessUseCase>((ref) => PredictReadinessUseCase(ref.watch(aiCoachRepositoryProvider)));
final getMotivationalMessageUseCaseProvider = Provider<GetMotivationalMessageUseCase>((ref) => GetMotivationalMessageUseCase(ref.watch(aiCoachRepositoryProvider)));

// ═══════════════════════════════════════════════════════════════════════
// CUSTOMER SUCCESS
// ═══════════════════════════════════════════════════════════════════════

final customerSuccessRemoteDataSourceProvider = Provider<CustomerSuccessRemoteDataSource>((ref) {
  return CustomerSuccessRemoteDataSourceImpl(supabase: ref.watch(supabaseClientProvider));
});

final customerSuccessRepositoryProvider = Provider<CustomerSuccessRepository>((ref) {
  return CustomerSuccessRepositoryImpl(
    remoteDataSource: ref.watch(customerSuccessRemoteDataSourceProvider),
    storageService: ref.watch(storageServiceProvider),
  );
});

final getOnboardingFlowsUseCaseProvider = Provider<GetOnboardingFlowsUseCase>((ref) => GetOnboardingFlowsUseCase(ref.watch(customerSuccessRepositoryProvider)));
final getOnboardingProgressUseCaseProvider = Provider<GetOnboardingProgressUseCase>((ref) => GetOnboardingProgressUseCase(ref.watch(customerSuccessRepositoryProvider)));
final completeOnboardingStepUseCaseProvider = Provider<CompleteOnboardingStepUseCase>((ref) => CompleteOnboardingStepUseCase(ref.watch(customerSuccessRepositoryProvider)));
final skipOnboardingStepUseCaseProvider = Provider<SkipOnboardingStepUseCase>((ref) => SkipOnboardingStepUseCase(ref.watch(customerSuccessRepositoryProvider)));
final getProductToursUseCaseProvider = Provider<GetProductToursUseCase>((ref) => GetProductToursUseCase(ref.watch(customerSuccessRepositoryProvider)));
final getHelpArticlesUseCaseProvider = Provider<GetHelpArticlesUseCase>((ref) => GetHelpArticlesUseCase(ref.watch(customerSuccessRepositoryProvider)));
final searchHelpArticlesUseCaseProvider = Provider<SearchHelpArticlesUseCase>((ref) => SearchHelpArticlesUseCase(ref.watch(customerSuccessRepositoryProvider)));
final submitFeedbackUseCaseProvider = Provider<SubmitFeedbackUseCase>((ref) => SubmitFeedbackUseCase(ref.watch(customerSuccessRepositoryProvider)));
final getFeatureRequestsUseCaseProvider = Provider<GetFeatureRequestsUseCase>((ref) => GetFeatureRequestsUseCase(ref.watch(customerSuccessRepositoryProvider)));
final createFeatureRequestUseCaseProvider = Provider<CreateFeatureRequestUseCase>((ref) => CreateFeatureRequestUseCase(ref.watch(customerSuccessRepositoryProvider)));
final voteFeatureRequestUseCaseProvider = Provider<VoteFeatureRequestUseCase>((ref) => VoteFeatureRequestUseCase(ref.watch(customerSuccessRepositoryProvider)));

// ═══════════════════════════════════════════════════════════════════════
// MARKETING
// ═══════════════════════════════════════════════════════════════════════

final marketingRemoteDataSourceProvider = Provider<MarketingRemoteDataSource>((ref) {
  return MarketingRemoteDataSourceImpl(supabase: ref.watch(supabaseClientProvider));
});

final marketingRepositoryProvider = Provider<MarketingRepository>((ref) {
  return MarketingRepositoryImpl(
    remoteDataSource: ref.watch(marketingRemoteDataSourceProvider),
    storageService: ref.watch(storageServiceProvider),
  );
});

final getLandingPagesUseCaseProvider = Provider<GetLandingPagesUseCase>((ref) => GetLandingPagesUseCase(ref.watch(marketingRepositoryProvider)));
final getBlogPostsUseCaseProvider = Provider<GetBlogPostsUseCase>((ref) => GetBlogPostsUseCase(ref.watch(marketingRepositoryProvider)));
final createBlogPostUseCaseProvider = Provider<CreateBlogPostUseCase>((ref) => CreateBlogPostUseCase(ref.watch(marketingRepositoryProvider)));
final getEmailCampaignsUseCaseProvider = Provider<GetEmailCampaignsUseCase>((ref) => GetEmailCampaignsUseCase(ref.watch(marketingRepositoryProvider)));
final getReferralProgramsUseCaseProvider = Provider<GetReferralProgramsUseCase>((ref) => GetReferralProgramsUseCase(ref.watch(marketingRepositoryProvider)));
final getReferralsUseCaseProvider = Provider<GetReferralsUseCase>((ref) => GetReferralsUseCase(ref.watch(marketingRepositoryProvider)));
final getAffiliatesUseCaseProvider = Provider<GetAffiliatesUseCase>((ref) => GetAffiliatesUseCase(ref.watch(marketingRepositoryProvider)));
final getAffiliateReferralsUseCaseProvider = Provider<GetAffiliateReferralsUseCase>((ref) => GetAffiliateReferralsUseCase(ref.watch(marketingRepositoryProvider)));

// ═══════════════════════════════════════════════════════════════════════
// EDUOS
// ═══════════════════════════════════════════════════════════════════════

final eduOsRemoteDataSourceProvider = Provider<EduOsRemoteDataSource>((ref) {
  return EduOsRemoteDataSourceImpl(supabase: ref.watch(supabaseClientProvider));
});

final eduOsRepositoryProvider = Provider<EduOsRepository>((ref) {
  return EduOsRepositoryImpl(
    remoteDataSource: ref.watch(eduOsRemoteDataSourceProvider),
    storageService: ref.watch(storageServiceProvider),
  );
});

final getModulesUseCaseProvider = Provider<GetModulesUseCase>((ref) => GetModulesUseCase(ref.watch(eduOsRepositoryProvider)));
final getModuleByCodeUseCaseProvider = Provider<GetModuleByCodeUseCase>((ref) => GetModuleByCodeUseCase(ref.watch(eduOsRepositoryProvider)));
final getModuleSubscriptionsUseCaseProvider = Provider<GetModuleSubscriptionsUseCase>((ref) => GetModuleSubscriptionsUseCase(ref.watch(eduOsRepositoryProvider)));
final subscribeModuleUseCaseProvider = Provider<SubscribeModuleUseCase>((ref) => SubscribeModuleUseCase(ref.watch(eduOsRepositoryProvider)));
final enableModuleUseCaseProvider = Provider<EnableModuleUseCase>((ref) => EnableModuleUseCase(ref.watch(eduOsRepositoryProvider)));
final disableModuleUseCaseProvider = Provider<DisableModuleUseCase>((ref) => DisableModuleUseCase(ref.watch(eduOsRepositoryProvider)));
final getModuleApisUseCaseProvider = Provider<GetModuleApisUseCase>((ref) => GetModuleApisUseCase(ref.watch(eduOsRepositoryProvider)));
final trackAnalyticsEventUseCaseProvider = Provider<TrackAnalyticsEventUseCase>((ref) => TrackAnalyticsEventUseCase(ref.watch(eduOsRepositoryProvider)));

// ═══════════════════════════════════════════════════════════════════════
// ANALYTICS DASHBOARD
// ═══════════════════════════════════════════════════════════════════════

final analyticsDashboardRemoteDataSourceProvider = Provider<AnalyticsDashboardRemoteDataSource>((ref) {
  return AnalyticsDashboardRemoteDataSourceImpl(supabase: ref.watch(supabaseClientProvider));
});

final analyticsDashboardRepositoryProvider = Provider<AnalyticsDashboardRepository>((ref) {
  return AnalyticsDashboardRepositoryImpl(
    remoteDataSource: ref.watch(analyticsDashboardRemoteDataSourceProvider),
    storageService: ref.watch(storageServiceProvider),
  );
});

final trackEventUseCaseProvider = Provider<TrackEventUseCase>((ref) => TrackEventUseCase(ref.watch(analyticsDashboardRepositoryProvider)));
final getAnalyticsSummaryUseCaseProvider = Provider<GetAnalyticsSummaryUseCase>((ref) => GetAnalyticsSummaryUseCase(ref.watch(analyticsDashboardRepositoryProvider)));
final getDailyMetricsUseCaseProvider = Provider<GetDailyMetricsUseCase>((ref) => GetDailyMetricsUseCase(ref.watch(analyticsDashboardRepositoryProvider)));
final getFeatureAdoptionUseCaseProvider = Provider<GetFeatureAdoptionUseCase>((ref) => GetFeatureAdoptionUseCase(ref.watch(analyticsDashboardRepositoryProvider)));
final getRetentionDataUseCaseProvider = Provider<GetRetentionDataUseCase>((ref) => GetRetentionDataUseCase(ref.watch(analyticsDashboardRepositoryProvider)));
final getChurnDataUseCaseProvider = Provider<GetChurnDataUseCase>((ref) => GetChurnDataUseCase(ref.watch(analyticsDashboardRepositoryProvider)));
final getRevenueMetricsUseCaseProvider = Provider<GetRevenueMetricsUseCase>((ref) => GetRevenueMetricsUseCase(ref.watch(analyticsDashboardRepositoryProvider)));
final getReleaseNotesUseCaseProvider = Provider<GetReleaseNotesUseCase>((ref) => GetReleaseNotesUseCase(ref.watch(analyticsDashboardRepositoryProvider)));
final createReleaseNoteUseCaseProvider = Provider<CreateReleaseNoteUseCase>((ref) => CreateReleaseNoteUseCase(ref.watch(analyticsDashboardRepositoryProvider)));
