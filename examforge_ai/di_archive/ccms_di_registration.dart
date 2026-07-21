/// CCMS Feature Module - Dependency Injection Registration
///
/// This file registers all Riverpod providers for the CCMS (Curriculum Content
/// Management System) feature module following Clean Architecture:
///   datasource → repository → use cases → presentation providers
///
/// Infrastructure providers (supabaseClientProvider, storageServiceProvider)
/// are defined in the main DI file: dependency_injection.dart
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;
import 'package:examforge_ai/config/supabase_config.dart';
import 'package:examforge_ai/services/storage_service.dart';
import 'package:examforge_ai/features/ccms/data/datasources/ccms_remote_datasource.dart';
import 'package:examforge_ai/features/ccms/data/repositories/ccms_repository_impl.dart';
import 'package:examforge_ai/features/ccms/domain/repositories/ccms_repository.dart';
import 'package:examforge_ai/features/ccms/domain/usecases/educational_level_usecases.dart';
import 'package:examforge_ai/features/ccms/domain/usecases/curriculum_usecases.dart';
import 'package:examforge_ai/features/ccms/domain/usecases/subject_usecases.dart';
import 'package:examforge_ai/features/ccms/domain/usecases/topic_usecases.dart';
import 'package:examforge_ai/features/ccms/domain/usecases/content_usecases.dart';
import 'package:examforge_ai/features/ccms/domain/usecases/content_review_usecases.dart';
import 'package:examforge_ai/features/ccms/domain/usecases/content_import_usecases.dart';
import 'package:examforge_ai/features/ccms/domain/usecases/content_collection_usecases.dart';
import 'package:examforge_ai/features/ccms/domain/usecases/ai_curriculum_usecases.dart';
import 'package:examforge_ai/features/ccms/domain/usecases/answer_repository_usecases.dart';
import 'package:examforge_ai/features/ccms/domain/usecases/enterprise_security_usecases.dart';
import 'package:examforge_ai/features/ccms/domain/usecases/monitoring_usecases.dart';
import 'package:examforge_ai/features/ccms/domain/usecases/deployment_usecases.dart';
import 'package:examforge_ai/features/ccms/presentation/providers/educational_level_provider.dart';
import 'package:examforge_ai/features/ccms/presentation/providers/curriculum_provider.dart';
import 'package:examforge_ai/features/ccms/presentation/providers/subject_provider.dart';
import 'package:examforge_ai/features/ccms/presentation/providers/content_provider.dart';
import 'package:examforge_ai/features/ccms/presentation/providers/ai_curriculum_provider.dart';
import 'package:examforge_ai/features/ccms/presentation/providers/enterprise_provider.dart';

// ============================================================================
// DATA LAYER - Datasource & Repository
// ============================================================================

/// Provides the CCMS remote datasource backed by the Supabase client.
final ccmsRemoteDataSourceProvider = Provider<CcmsRemoteDataSource>((ref) {
  return CcmsRemoteDataSourceImpl(supabase: ref.watch(supabaseClientProvider));
});

/// Provides the CCMS repository implementation.
/// Depends on the remote datasource and local storage service.
final ccmsRepositoryProvider = Provider<CcmsRepository>((ref) {
  return CcmsRepositoryImpl(
    remoteDataSource: ref.watch(ccmsRemoteDataSourceProvider),
    storageService: ref.watch(storageServiceProvider),
  );
});

// ============================================================================
// DOMAIN LAYER - Use Case Providers
// ============================================================================

// ---------------------------------------------------------------------------
// Educational Level Use Cases (4)
// ---------------------------------------------------------------------------

final getEducationalLevelsUseCaseProvider = Provider<GetEducationalLevelsUseCase>((ref) {
  return GetEducationalLevelsUseCase(ref.watch(ccmsRepositoryProvider));
});

final getSchoolLevelsUseCaseProvider = Provider<GetSchoolLevelsUseCase>((ref) {
  return GetSchoolLevelsUseCase(ref.watch(ccmsRepositoryProvider));
});

final configureSchoolLevelUseCaseProvider = Provider<ConfigureSchoolLevelUseCase>((ref) {
  return ConfigureSchoolLevelUseCase(ref.watch(ccmsRepositoryProvider));
});

final updateSchoolLevelConfigurationUseCaseProvider = Provider<UpdateSchoolLevelConfigurationUseCase>((ref) {
  return UpdateSchoolLevelConfigurationUseCase(ref.watch(ccmsRepositoryProvider));
});

// ---------------------------------------------------------------------------
// Curriculum Use Cases (6)
// ---------------------------------------------------------------------------

final getCurriculaUseCaseProvider = Provider<GetCurriculaUseCase>((ref) {
  return GetCurriculaUseCase(ref.watch(ccmsRepositoryProvider));
});

final getCurriculumByIdUseCaseProvider = Provider<GetCurriculumByIdUseCase>((ref) {
  return GetCurriculumByIdUseCase(ref.watch(ccmsRepositoryProvider));
});

final createCurriculumUseCaseProvider = Provider<CreateCurriculumUseCase>((ref) {
  return CreateCurriculumUseCase(ref.watch(ccmsRepositoryProvider));
});

final updateCurriculumUseCaseProvider = Provider<UpdateCurriculumUseCase>((ref) {
  return UpdateCurriculumUseCase(ref.watch(ccmsRepositoryProvider));
});

final getCurriculumVersionsUseCaseProvider = Provider<GetCurriculumVersionsUseCase>((ref) {
  return GetCurriculumVersionsUseCase(ref.watch(ccmsRepositoryProvider));
});

final getCurriculumLevelMappingsUseCaseProvider = Provider<GetCurriculumLevelMappingsUseCase>((ref) {
  return GetCurriculumLevelMappingsUseCase(ref.watch(ccmsRepositoryProvider));
});

// ---------------------------------------------------------------------------
// Subject Use Cases (6)
// ---------------------------------------------------------------------------

final getSubjectsUseCaseProvider = Provider<GetSubjectsUseCase>((ref) {
  return GetSubjectsUseCase(ref.watch(ccmsRepositoryProvider));
});

final getSubjectByIdUseCaseProvider = Provider<GetSubjectByIdUseCase>((ref) {
  return GetSubjectByIdUseCase(ref.watch(ccmsRepositoryProvider));
});

final createSubjectUseCaseProvider = Provider<CreateSubjectUseCase>((ref) {
  return CreateSubjectUseCase(ref.watch(ccmsRepositoryProvider));
});

final updateSubjectUseCaseProvider = Provider<UpdateSubjectUseCase>((ref) {
  return UpdateSubjectUseCase(ref.watch(ccmsRepositoryProvider));
});

final deleteSubjectUseCaseProvider = Provider<DeleteSubjectUseCase>((ref) {
  return DeleteSubjectUseCase(ref.watch(ccmsRepositoryProvider));
});

final getLevelSubjectsUseCaseProvider = Provider<GetLevelSubjectsUseCase>((ref) {
  return GetLevelSubjectsUseCase(ref.watch(ccmsRepositoryProvider));
});

// ---------------------------------------------------------------------------
// Topic Use Cases (9)
// ---------------------------------------------------------------------------

final getTopicsUseCaseProvider = Provider<GetTopicsUseCase>((ref) {
  return GetTopicsUseCase(ref.watch(ccmsRepositoryProvider));
});

final createTopicUseCaseProvider = Provider<CreateTopicUseCase>((ref) {
  return CreateTopicUseCase(ref.watch(ccmsRepositoryProvider));
});

final updateTopicUseCaseProvider = Provider<UpdateTopicUseCase>((ref) {
  return UpdateTopicUseCase(ref.watch(ccmsRepositoryProvider));
});

final deleteTopicUseCaseProvider = Provider<DeleteTopicUseCase>((ref) {
  return DeleteTopicUseCase(ref.watch(ccmsRepositoryProvider));
});

final getSubtopicsUseCaseProvider = Provider<GetSubtopicsUseCase>((ref) {
  return GetSubtopicsUseCase(ref.watch(ccmsRepositoryProvider));
});

final createSubtopicUseCaseProvider = Provider<CreateSubtopicUseCase>((ref) {
  return CreateSubtopicUseCase(ref.watch(ccmsRepositoryProvider));
});

final updateSubtopicUseCaseProvider = Provider<UpdateSubtopicUseCase>((ref) {
  return UpdateSubtopicUseCase(ref.watch(ccmsRepositoryProvider));
});

final deleteSubtopicUseCaseProvider = Provider<DeleteSubtopicUseCase>((ref) {
  return DeleteSubtopicUseCase(ref.watch(ccmsRepositoryProvider));
});

final getCurriculumTreeUseCaseProvider = Provider<GetCurriculumTreeUseCase>((ref) {
  return GetCurriculumTreeUseCase(ref.watch(ccmsRepositoryProvider));
});

// ---------------------------------------------------------------------------
// Content Use Cases (9)
// ---------------------------------------------------------------------------

final getContentItemsUseCaseProvider = Provider<GetContentItemsUseCase>((ref) {
  return GetContentItemsUseCase(ref.watch(ccmsRepositoryProvider));
});

final getContentByIdUseCaseProvider = Provider<GetContentByIdUseCase>((ref) {
  return GetContentByIdUseCase(ref.watch(ccmsRepositoryProvider));
});

final createContentUseCaseProvider = Provider<CreateContentUseCase>((ref) {
  return CreateContentUseCase(ref.watch(ccmsRepositoryProvider));
});

final updateContentUseCaseProvider = Provider<UpdateContentUseCase>((ref) {
  return UpdateContentUseCase(ref.watch(ccmsRepositoryProvider));
});

final deleteContentUseCaseProvider = Provider<DeleteContentUseCase>((ref) {
  return DeleteContentUseCase(ref.watch(ccmsRepositoryProvider));
});

final publishContentUseCaseProvider = Provider<PublishContentUseCase>((ref) {
  return PublishContentUseCase(ref.watch(ccmsRepositoryProvider));
});

final archiveContentUseCaseProvider = Provider<ArchiveContentUseCase>((ref) {
  return ArchiveContentUseCase(ref.watch(ccmsRepositoryProvider));
});

final getContentVersionsUseCaseProvider = Provider<GetContentVersionsUseCase>((ref) {
  return GetContentVersionsUseCase(ref.watch(ccmsRepositoryProvider));
});

final getContentWithDetailsUseCaseProvider = Provider<GetContentWithDetailsUseCase>((ref) {
  return GetContentWithDetailsUseCase(ref.watch(ccmsRepositoryProvider));
});

// ---------------------------------------------------------------------------
// Content Review Use Cases (2)
// ---------------------------------------------------------------------------

final createReviewUseCaseProvider = Provider<CreateReviewUseCase>((ref) {
  return CreateReviewUseCase(ref.watch(ccmsRepositoryProvider));
});

final getContentReviewsUseCaseProvider = Provider<GetContentReviewsUseCase>((ref) {
  return GetContentReviewsUseCase(ref.watch(ccmsRepositoryProvider));
});

// ---------------------------------------------------------------------------
// Content Import Use Cases (3)
// ---------------------------------------------------------------------------

final createImportUseCaseProvider = Provider<CreateImportUseCase>((ref) {
  return CreateImportUseCase(ref.watch(ccmsRepositoryProvider));
});

final getImportsUseCaseProvider = Provider<GetImportsUseCase>((ref) {
  return GetImportsUseCase(ref.watch(ccmsRepositoryProvider));
});

final getImportByIdUseCaseProvider = Provider<GetImportByIdUseCase>((ref) {
  return GetImportByIdUseCase(ref.watch(ccmsRepositoryProvider));
});

// ---------------------------------------------------------------------------
// Content Collection Use Cases (6)
// ---------------------------------------------------------------------------

final getCollectionsUseCaseProvider = Provider<GetCollectionsUseCase>((ref) {
  return GetCollectionsUseCase(ref.watch(ccmsRepositoryProvider));
});

final createCollectionUseCaseProvider = Provider<CreateCollectionUseCase>((ref) {
  return CreateCollectionUseCase(ref.watch(ccmsRepositoryProvider));
});

final updateCollectionUseCaseProvider = Provider<UpdateCollectionUseCase>((ref) {
  return UpdateCollectionUseCase(ref.watch(ccmsRepositoryProvider));
});

final deleteCollectionUseCaseProvider = Provider<DeleteCollectionUseCase>((ref) {
  return DeleteCollectionUseCase(ref.watch(ccmsRepositoryProvider));
});

final addCollectionItemUseCaseProvider = Provider<AddCollectionItemUseCase>((ref) {
  return AddCollectionItemUseCase(ref.watch(ccmsRepositoryProvider));
});

final removeCollectionItemUseCaseProvider = Provider<RemoveCollectionItemUseCase>((ref) {
  return RemoveCollectionItemUseCase(ref.watch(ccmsRepositoryProvider));
});

// ---------------------------------------------------------------------------
// AI Curriculum Use Cases (5)
// ---------------------------------------------------------------------------

final getAiCurriculumConfigUseCaseProvider = Provider<GetAiCurriculumConfigUseCase>((ref) {
  return GetAiCurriculumConfigUseCase(ref.watch(ccmsRepositoryProvider));
});

final upsertAiCurriculumConfigUseCaseProvider = Provider<UpsertAiCurriculumConfigUseCase>((ref) {
  return UpsertAiCurriculumConfigUseCase(ref.watch(ccmsRepositoryProvider));
});

final getAiGenerationRulesUseCaseProvider = Provider<GetAiGenerationRulesUseCase>((ref) {
  return GetAiGenerationRulesUseCase(ref.watch(ccmsRepositoryProvider));
});

final createAiGenerationRuleUseCaseProvider = Provider<CreateAiGenerationRuleUseCase>((ref) {
  return CreateAiGenerationRuleUseCase(ref.watch(ccmsRepositoryProvider));
});

final updateAiGenerationRuleUseCaseProvider = Provider<UpdateAiGenerationRuleUseCase>((ref) {
  return UpdateAiGenerationRuleUseCase(ref.watch(ccmsRepositoryProvider));
});

// ---------------------------------------------------------------------------
// Answer Repository Use Cases (4)
// ---------------------------------------------------------------------------

final getAnswerEntryUseCaseProvider = Provider<GetAnswerEntryUseCase>((ref) {
  return GetAnswerEntryUseCase(ref.watch(ccmsRepositoryProvider));
});

final createAnswerEntryUseCaseProvider = Provider<CreateAnswerEntryUseCase>((ref) {
  return CreateAnswerEntryUseCase(ref.watch(ccmsRepositoryProvider));
});

final updateAnswerEntryUseCaseProvider = Provider<UpdateAnswerEntryUseCase>((ref) {
  return UpdateAnswerEntryUseCase(ref.watch(ccmsRepositoryProvider));
});

final verifyAnswerUseCaseProvider = Provider<VerifyAnswerUseCase>((ref) {
  return VerifyAnswerUseCase(ref.watch(ccmsRepositoryProvider));
});

// ---------------------------------------------------------------------------
// Enterprise Security Use Cases (14)
// ---------------------------------------------------------------------------

final recordAuditEventUseCaseProvider = Provider<RecordAuditEventUseCase>((ref) {
  return RecordAuditEventUseCase(ref.watch(ccmsRepositoryProvider));
});

final getAuditTrailUseCaseProvider = Provider<GetAuditTrailUseCase>((ref) {
  return GetAuditTrailUseCase(ref.watch(ccmsRepositoryProvider));
});

final getMfaConfigUseCaseProvider = Provider<GetMfaConfigUseCase>((ref) {
  return GetMfaConfigUseCase(ref.watch(ccmsRepositoryProvider));
});

final enableMfaUseCaseProvider = Provider<EnableMfaUseCase>((ref) {
  return EnableMfaUseCase(ref.watch(ccmsRepositoryProvider));
});

final disableMfaUseCaseProvider = Provider<DisableMfaUseCase>((ref) {
  return DisableMfaUseCase(ref.watch(ccmsRepositoryProvider));
});

final verifyMfaUseCaseProvider = Provider<VerifyMfaUseCase>((ref) {
  return VerifyMfaUseCase(ref.watch(ccmsRepositoryProvider));
});

final createApiKeyUseCaseProvider = Provider<CreateApiKeyUseCase>((ref) {
  return CreateApiKeyUseCase(ref.watch(ccmsRepositoryProvider));
});

final revokeApiKeyUseCaseProvider = Provider<RevokeApiKeyUseCase>((ref) {
  return RevokeApiKeyUseCase(ref.watch(ccmsRepositoryProvider));
});

final getApiKeysUseCaseProvider = Provider<GetApiKeysUseCase>((ref) {
  return GetApiKeysUseCase(ref.watch(ccmsRepositoryProvider));
});

final recordSecurityEventUseCaseProvider = Provider<RecordSecurityEventUseCase>((ref) {
  return RecordSecurityEventUseCase(ref.watch(ccmsRepositoryProvider));
});

final getSecurityEventsUseCaseProvider = Provider<GetSecurityEventsUseCase>((ref) {
  return GetSecurityEventsUseCase(ref.watch(ccmsRepositoryProvider));
});

final checkRateLimitUseCaseProvider = Provider<CheckRateLimitUseCase>((ref) {
  return CheckRateLimitUseCase(ref.watch(ccmsRepositoryProvider));
});

final getUserSessionsUseCaseProvider = Provider<GetUserSessionsUseCase>((ref) {
  return GetUserSessionsUseCase(ref.watch(ccmsRepositoryProvider));
});

final invalidateUserSessionsUseCaseProvider = Provider<InvalidateUserSessionsUseCase>((ref) {
  return InvalidateUserSessionsUseCase(ref.watch(ccmsRepositoryProvider));
});

// ---------------------------------------------------------------------------
// Monitoring Use Cases (13)
// ---------------------------------------------------------------------------

final recordMetricUseCaseProvider = Provider<RecordMetricUseCase>((ref) {
  return RecordMetricUseCase(ref.watch(ccmsRepositoryProvider));
});

final getSystemMetricsUseCaseProvider = Provider<GetSystemMetricsUseCase>((ref) {
  return GetSystemMetricsUseCase(ref.watch(ccmsRepositoryProvider));
});

final getAlertRulesUseCaseProvider = Provider<GetAlertRulesUseCase>((ref) {
  return GetAlertRulesUseCase(ref.watch(ccmsRepositoryProvider));
});

final createAlertRuleUseCaseProvider = Provider<CreateAlertRuleUseCase>((ref) {
  return CreateAlertRuleUseCase(ref.watch(ccmsRepositoryProvider));
});

final getAlertIncidentsUseCaseProvider = Provider<GetAlertIncidentsUseCase>((ref) {
  return GetAlertIncidentsUseCase(ref.watch(ccmsRepositoryProvider));
});

final acknowledgeAlertUseCaseProvider = Provider<AcknowledgeAlertUseCase>((ref) {
  return AcknowledgeAlertUseCase(ref.watch(ccmsRepositoryProvider));
});

final resolveAlertUseCaseProvider = Provider<ResolveAlertUseCase>((ref) {
  return ResolveAlertUseCase(ref.watch(ccmsRepositoryProvider));
});

final recordPerformanceLogUseCaseProvider = Provider<RecordPerformanceLogUseCase>((ref) {
  return RecordPerformanceLogUseCase(ref.watch(ccmsRepositoryProvider));
});

final getPerformanceLogsUseCaseProvider = Provider<GetPerformanceLogsUseCase>((ref) {
  return GetPerformanceLogsUseCase(ref.watch(ccmsRepositoryProvider));
});

final reportErrorUseCaseProvider = Provider<ReportErrorUseCase>((ref) {
  return ReportErrorUseCase(ref.watch(ccmsRepositoryProvider));
});

final getErrorReportsUseCaseProvider = Provider<GetErrorReportsUseCase>((ref) {
  return GetErrorReportsUseCase(ref.watch(ccmsRepositoryProvider));
});

final resolveErrorUseCaseProvider = Provider<ResolveErrorUseCase>((ref) {
  return ResolveErrorUseCase(ref.watch(ccmsRepositoryProvider));
});

final getCcmsStatsUseCaseProvider = Provider<GetCcmsStatsUseCase>((ref) {
  return GetCcmsStatsUseCase(ref.watch(ccmsRepositoryProvider));
});

// ---------------------------------------------------------------------------
// Deployment Use Cases (5)
// ---------------------------------------------------------------------------

final getDeploymentsUseCaseProvider = Provider<GetDeploymentsUseCase>((ref) {
  return GetDeploymentsUseCase(ref.watch(ccmsRepositoryProvider));
});

final createDeploymentUseCaseProvider = Provider<CreateDeploymentUseCase>((ref) {
  return CreateDeploymentUseCase(ref.watch(ccmsRepositoryProvider));
});

final updateDeploymentStatusUseCaseProvider = Provider<UpdateDeploymentStatusUseCase>((ref) {
  return UpdateDeploymentStatusUseCase(ref.watch(ccmsRepositoryProvider));
});

final recordTestResultUseCaseProvider = Provider<RecordTestResultUseCase>((ref) {
  return RecordTestResultUseCase(ref.watch(ccmsRepositoryProvider));
});

final getTestResultsUseCaseProvider = Provider<GetTestResultsUseCase>((ref) {
  return GetTestResultsUseCase(ref.watch(ccmsRepositoryProvider));
});

// ============================================================================
// PRESENTATION LAYER - StateNotifierProviders
// ============================================================================
//
// These providers are defined in their respective presentation provider files
// and are re-exported here so they can be accessed from a single import point.
//
// Importing this file gives access to:
//   - educationalLevelProvider        (from educational_level_provider.dart)
//   - curriculumProvider              (from curriculum_provider.dart)
//   - subjectProvider                 (from subject_provider.dart)
//   - contentProvider                 (from content_provider.dart)
//   - aiCurriculumProvider            (from ai_curriculum_provider.dart)
//   - enterpriseProvider              (from enterprise_provider.dart)
// ============================================================================
