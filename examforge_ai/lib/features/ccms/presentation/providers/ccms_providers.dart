/// Barrel export for all CCMS presentation providers.
///
/// Also defines Riverpod [StateNotifierProvider] instances for every CCMS
/// notifier, injecting the repository and use-case dependencies.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/core.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;
import '../../data/datasources/ccms_remote_datasource.dart';
import '../../data/models/ccms_models.dart';
import '../../data/repositories/ccms_repository_impl.dart';
import '../../domain/entities/ccms_entities.dart';
import '../../domain/repositories/ccms_repository.dart';
import '../../domain/usecases/educational_level_usecases.dart';
import '../../domain/usecases/curriculum_usecases.dart';
import '../../domain/usecases/subject_usecases.dart';
import '../../domain/usecases/topic_usecases.dart';
import '../../domain/usecases/content_usecases.dart';
import '../../domain/usecases/content_review_usecases.dart';
import '../../domain/usecases/content_import_usecases.dart';
import '../../domain/usecases/content_collection_usecases.dart';
import '../../domain/usecases/ai_curriculum_usecases.dart';
import '../../domain/usecases/answer_repository_usecases.dart';
import '../../domain/usecases/enterprise_security_usecases.dart';
import '../../domain/usecases/monitoring_usecases.dart';
import '../../domain/usecases/deployment_usecases.dart';
import 'educational_level_provider.dart';
import 'curriculum_provider.dart';
import 'subject_provider.dart';
import 'topic_provider.dart';
import 'content_provider.dart';
import 'content_review_provider.dart';
import 'content_import_provider.dart';
import 'content_collection_provider.dart';
import 'ai_curriculum_provider.dart';
import 'answer_repository_provider.dart';
import 'enterprise_provider.dart';
import 'monitoring_provider.dart';
import 'deployment_provider.dart';

// ─── Repository Provider ────────────────────────────────────────────────────

final _ccmsRemoteDatasourceProvider = Provider<CcmsRemoteDataSource>((ref) {
  return CcmsRemoteDataSourceImpl(supabase: sb.Supabase.instance.client);
});

final ccmsRepositoryProvider = Provider<CcmsRepository>((ref) {
  return CcmsRepositoryImpl(remoteDataSource: ref.watch(_ccmsRemoteDatasourceProvider));
});

// ─── Educational Level Use Cases ────────────────────────────────────────────

final _getEducationalLevelsUseCaseProvider = Provider<GetEducationalLevelsUseCase>((ref) {
  return GetEducationalLevelsUseCase(ref.watch(ccmsRepositoryProvider));
});

final _getSchoolLevelsUseCaseProvider = Provider<GetSchoolLevelsUseCase>((ref) {
  return GetSchoolLevelsUseCase(ref.watch(ccmsRepositoryProvider));
});

final _configureSchoolLevelUseCaseProvider = Provider<ConfigureSchoolLevelUseCase>((ref) {
  return ConfigureSchoolLevelUseCase(ref.watch(ccmsRepositoryProvider));
});

final _updateSchoolLevelConfigurationUseCaseProvider = Provider<UpdateSchoolLevelConfigurationUseCase>((ref) {
  return UpdateSchoolLevelConfigurationUseCase(ref.watch(ccmsRepositoryProvider));
});

// ─── Curriculum Use Cases ───────────────────────────────────────────────────

final _getCurriculaUseCaseProvider = Provider<GetCurriculaUseCase>((ref) {
  return GetCurriculaUseCase(ref.watch(ccmsRepositoryProvider));
});

final _getCurriculumByIdUseCaseProvider = Provider<GetCurriculumByIdUseCase>((ref) {
  return GetCurriculumByIdUseCase(ref.watch(ccmsRepositoryProvider));
});

final _createCurriculumUseCaseProvider = Provider<CreateCurriculumUseCase>((ref) {
  return CreateCurriculumUseCase(ref.watch(ccmsRepositoryProvider));
});

final _updateCurriculumUseCaseProvider = Provider<UpdateCurriculumUseCase>((ref) {
  return UpdateCurriculumUseCase(ref.watch(ccmsRepositoryProvider));
});

final _getCurriculumVersionsUseCaseProvider = Provider<GetCurriculumVersionsUseCase>((ref) {
  return GetCurriculumVersionsUseCase(ref.watch(ccmsRepositoryProvider));
});

final _getCurriculumLevelMappingsUseCaseProvider = Provider<GetCurriculumLevelMappingsUseCase>((ref) {
  return GetCurriculumLevelMappingsUseCase(ref.watch(ccmsRepositoryProvider));
});

// ─── Subject Use Cases ──────────────────────────────────────────────────────

final _getSubjectsUseCaseProvider = Provider<GetSubjectsUseCase>((ref) {
  return GetSubjectsUseCase(ref.watch(ccmsRepositoryProvider));
});

final _getSubjectByIdUseCaseProvider = Provider<GetSubjectByIdUseCase>((ref) {
  return GetSubjectByIdUseCase(ref.watch(ccmsRepositoryProvider));
});

final _createSubjectUseCaseProvider = Provider<CreateSubjectUseCase>((ref) {
  return CreateSubjectUseCase(ref.watch(ccmsRepositoryProvider));
});

final _updateSubjectUseCaseProvider = Provider<UpdateSubjectUseCase>((ref) {
  return UpdateSubjectUseCase(ref.watch(ccmsRepositoryProvider));
});

final _deleteSubjectUseCaseProvider = Provider<DeleteSubjectUseCase>((ref) {
  return DeleteSubjectUseCase(ref.watch(ccmsRepositoryProvider));
});

final _getLevelSubjectsUseCaseProvider = Provider<GetLevelSubjectsUseCase>((ref) {
  return GetLevelSubjectsUseCase(ref.watch(ccmsRepositoryProvider));
});

// ─── Topic Use Cases ────────────────────────────────────────────────────────

final _getTopicsUseCaseProvider = Provider<GetTopicsUseCase>((ref) {
  return GetTopicsUseCase(ref.watch(ccmsRepositoryProvider));
});

final _createTopicUseCaseProvider = Provider<CreateTopicUseCase>((ref) {
  return CreateTopicUseCase(ref.watch(ccmsRepositoryProvider));
});

final _updateTopicUseCaseProvider = Provider<UpdateTopicUseCase>((ref) {
  return UpdateTopicUseCase(ref.watch(ccmsRepositoryProvider));
});

final _deleteTopicUseCaseProvider = Provider<DeleteTopicUseCase>((ref) {
  return DeleteTopicUseCase(ref.watch(ccmsRepositoryProvider));
});

final _getSubtopicsUseCaseProvider = Provider<GetSubtopicsUseCase>((ref) {
  return GetSubtopicsUseCase(ref.watch(ccmsRepositoryProvider));
});

final _createSubtopicUseCaseProvider = Provider<CreateSubtopicUseCase>((ref) {
  return CreateSubtopicUseCase(ref.watch(ccmsRepositoryProvider));
});

final _updateSubtopicUseCaseProvider = Provider<UpdateSubtopicUseCase>((ref) {
  return UpdateSubtopicUseCase(ref.watch(ccmsRepositoryProvider));
});

final _deleteSubtopicUseCaseProvider = Provider<DeleteSubtopicUseCase>((ref) {
  return DeleteSubtopicUseCase(ref.watch(ccmsRepositoryProvider));
});

final _getCurriculumTreeUseCaseProvider = Provider<GetCurriculumTreeUseCase>((ref) {
  return GetCurriculumTreeUseCase(ref.watch(ccmsRepositoryProvider));
});

// ─── Content Use Cases ──────────────────────────────────────────────────────

final _getContentItemsUseCaseProvider = Provider<GetContentItemsUseCase>((ref) {
  return GetContentItemsUseCase(ref.watch(ccmsRepositoryProvider));
});

final _getContentByIdUseCaseProvider = Provider<GetContentByIdUseCase>((ref) {
  return GetContentByIdUseCase(ref.watch(ccmsRepositoryProvider));
});

final _createContentUseCaseProvider = Provider<CreateContentUseCase>((ref) {
  return CreateContentUseCase(ref.watch(ccmsRepositoryProvider));
});

final _updateContentUseCaseProvider = Provider<UpdateContentUseCase>((ref) {
  return UpdateContentUseCase(ref.watch(ccmsRepositoryProvider));
});

final _deleteContentUseCaseProvider = Provider<DeleteContentUseCase>((ref) {
  return DeleteContentUseCase(ref.watch(ccmsRepositoryProvider));
});

final _publishContentUseCaseProvider = Provider<PublishContentUseCase>((ref) {
  return PublishContentUseCase(ref.watch(ccmsRepositoryProvider));
});

final _archiveContentUseCaseProvider = Provider<ArchiveContentUseCase>((ref) {
  return ArchiveContentUseCase(ref.watch(ccmsRepositoryProvider));
});

final _getContentVersionsUseCaseProvider = Provider<GetContentVersionsUseCase>((ref) {
  return GetContentVersionsUseCase(ref.watch(ccmsRepositoryProvider));
});

final _getContentWithDetailsUseCaseProvider = Provider<GetContentWithDetailsUseCase>((ref) {
  return GetContentWithDetailsUseCase(ref.watch(ccmsRepositoryProvider));
});

// ─── Content Review Use Cases ───────────────────────────────────────────────

final _createReviewUseCaseProvider = Provider<CreateReviewUseCase>((ref) {
  return CreateReviewUseCase(ref.watch(ccmsRepositoryProvider));
});

final _getContentReviewsUseCaseProvider = Provider<GetContentReviewsUseCase>((ref) {
  return GetContentReviewsUseCase(ref.watch(ccmsRepositoryProvider));
});

// ─── Content Import Use Cases ───────────────────────────────────────────────

final _createImportUseCaseProvider = Provider<CreateImportUseCase>((ref) {
  return CreateImportUseCase(ref.watch(ccmsRepositoryProvider));
});

final _getImportsUseCaseProvider = Provider<GetImportsUseCase>((ref) {
  return GetImportsUseCase(ref.watch(ccmsRepositoryProvider));
});

final _getImportByIdUseCaseProvider = Provider<GetImportByIdUseCase>((ref) {
  return GetImportByIdUseCase(ref.watch(ccmsRepositoryProvider));
});

// ─── Content Collection Use Cases ───────────────────────────────────────────

final _getCollectionsUseCaseProvider = Provider<GetCollectionsUseCase>((ref) {
  return GetCollectionsUseCase(ref.watch(ccmsRepositoryProvider));
});

final _createCollectionUseCaseProvider = Provider<CreateCollectionUseCase>((ref) {
  return CreateCollectionUseCase(ref.watch(ccmsRepositoryProvider));
});

final _updateCollectionUseCaseProvider = Provider<UpdateCollectionUseCase>((ref) {
  return UpdateCollectionUseCase(ref.watch(ccmsRepositoryProvider));
});

final _deleteCollectionUseCaseProvider = Provider<DeleteCollectionUseCase>((ref) {
  return DeleteCollectionUseCase(ref.watch(ccmsRepositoryProvider));
});

final _addCollectionItemUseCaseProvider = Provider<AddCollectionItemUseCase>((ref) {
  return AddCollectionItemUseCase(ref.watch(ccmsRepositoryProvider));
});

final _removeCollectionItemUseCaseProvider = Provider<RemoveCollectionItemUseCase>((ref) {
  return RemoveCollectionItemUseCase(ref.watch(ccmsRepositoryProvider));
});

// ─── AI Curriculum Use Cases ────────────────────────────────────────────────

final _getAiCurriculumConfigUseCaseProvider = Provider<GetAiCurriculumConfigUseCase>((ref) {
  return GetAiCurriculumConfigUseCase(ref.watch(ccmsRepositoryProvider));
});

final _upsertAiCurriculumConfigUseCaseProvider = Provider<UpsertAiCurriculumConfigUseCase>((ref) {
  return UpsertAiCurriculumConfigUseCase(ref.watch(ccmsRepositoryProvider));
});

final _getAiGenerationRulesUseCaseProvider = Provider<GetAiGenerationRulesUseCase>((ref) {
  return GetAiGenerationRulesUseCase(ref.watch(ccmsRepositoryProvider));
});

final _createAiGenerationRuleUseCaseProvider = Provider<CreateAiGenerationRuleUseCase>((ref) {
  return CreateAiGenerationRuleUseCase(ref.watch(ccmsRepositoryProvider));
});

final _updateAiGenerationRuleUseCaseProvider = Provider<UpdateAiGenerationRuleUseCase>((ref) {
  return UpdateAiGenerationRuleUseCase(ref.watch(ccmsRepositoryProvider));
});

// ─── Answer Repository Use Cases ────────────────────────────────────────────

final _getAnswerEntryUseCaseProvider = Provider<GetAnswerEntryUseCase>((ref) {
  return GetAnswerEntryUseCase(ref.watch(ccmsRepositoryProvider));
});

final _createAnswerEntryUseCaseProvider = Provider<CreateAnswerEntryUseCase>((ref) {
  return CreateAnswerEntryUseCase(ref.watch(ccmsRepositoryProvider));
});

final _updateAnswerEntryUseCaseProvider = Provider<UpdateAnswerEntryUseCase>((ref) {
  return UpdateAnswerEntryUseCase(ref.watch(ccmsRepositoryProvider));
});

final _verifyAnswerUseCaseProvider = Provider<VerifyAnswerUseCase>((ref) {
  return VerifyAnswerUseCase(ref.watch(ccmsRepositoryProvider));
});

// ─── Enterprise Security Use Cases ──────────────────────────────────────────

final _recordAuditEventUseCaseProvider = Provider<RecordAuditEventUseCase>((ref) {
  return RecordAuditEventUseCase(ref.watch(ccmsRepositoryProvider));
});

final _getAuditTrailUseCaseProvider = Provider<GetAuditTrailUseCase>((ref) {
  return GetAuditTrailUseCase(ref.watch(ccmsRepositoryProvider));
});

final _getMfaConfigUseCaseProvider = Provider<GetMfaConfigUseCase>((ref) {
  return GetMfaConfigUseCase(ref.watch(ccmsRepositoryProvider));
});

final _enableMfaUseCaseProvider = Provider<EnableMfaUseCase>((ref) {
  return EnableMfaUseCase(ref.watch(ccmsRepositoryProvider));
});

final _disableMfaUseCaseProvider = Provider<DisableMfaUseCase>((ref) {
  return DisableMfaUseCase(ref.watch(ccmsRepositoryProvider));
});

final _verifyMfaUseCaseProvider = Provider<VerifyMfaUseCase>((ref) {
  return VerifyMfaUseCase(ref.watch(ccmsRepositoryProvider));
});

final _createApiKeyUseCaseProvider = Provider<CreateApiKeyUseCase>((ref) {
  return CreateApiKeyUseCase(ref.watch(ccmsRepositoryProvider));
});

final _revokeApiKeyUseCaseProvider = Provider<RevokeApiKeyUseCase>((ref) {
  return RevokeApiKeyUseCase(ref.watch(ccmsRepositoryProvider));
});

final _getApiKeysUseCaseProvider = Provider<GetApiKeysUseCase>((ref) {
  return GetApiKeysUseCase(ref.watch(ccmsRepositoryProvider));
});

final _recordSecurityEventUseCaseProvider = Provider<RecordSecurityEventUseCase>((ref) {
  return RecordSecurityEventUseCase(ref.watch(ccmsRepositoryProvider));
});

final _getSecurityEventsUseCaseProvider = Provider<GetSecurityEventsUseCase>((ref) {
  return GetSecurityEventsUseCase(ref.watch(ccmsRepositoryProvider));
});

final _checkRateLimitUseCaseProvider = Provider<CheckRateLimitUseCase>((ref) {
  return CheckRateLimitUseCase(ref.watch(ccmsRepositoryProvider));
});

final _getUserSessionsUseCaseProvider = Provider<GetUserSessionsUseCase>((ref) {
  return GetUserSessionsUseCase(ref.watch(ccmsRepositoryProvider));
});

final _invalidateUserSessionsUseCaseProvider = Provider<InvalidateUserSessionsUseCase>((ref) {
  return InvalidateUserSessionsUseCase(ref.watch(ccmsRepositoryProvider));
});

// ─── Monitoring Use Cases ───────────────────────────────────────────────────

final _recordMetricUseCaseProvider = Provider<RecordMetricUseCase>((ref) {
  return RecordMetricUseCase(ref.watch(ccmsRepositoryProvider));
});

final _getSystemMetricsUseCaseProvider = Provider<GetSystemMetricsUseCase>((ref) {
  return GetSystemMetricsUseCase(ref.watch(ccmsRepositoryProvider));
});

final _getAlertRulesUseCaseProvider = Provider<GetAlertRulesUseCase>((ref) {
  return GetAlertRulesUseCase(ref.watch(ccmsRepositoryProvider));
});

final _createAlertRuleUseCaseProvider = Provider<CreateAlertRuleUseCase>((ref) {
  return CreateAlertRuleUseCase(ref.watch(ccmsRepositoryProvider));
});

final _getAlertIncidentsUseCaseProvider = Provider<GetAlertIncidentsUseCase>((ref) {
  return GetAlertIncidentsUseCase(ref.watch(ccmsRepositoryProvider));
});

final _acknowledgeAlertUseCaseProvider = Provider<AcknowledgeAlertUseCase>((ref) {
  return AcknowledgeAlertUseCase(ref.watch(ccmsRepositoryProvider));
});

final _resolveAlertUseCaseProvider = Provider<ResolveAlertUseCase>((ref) {
  return ResolveAlertUseCase(ref.watch(ccmsRepositoryProvider));
});

final _recordPerformanceLogUseCaseProvider = Provider<RecordPerformanceLogUseCase>((ref) {
  return RecordPerformanceLogUseCase(ref.watch(ccmsRepositoryProvider));
});

final _getPerformanceLogsUseCaseProvider = Provider<GetPerformanceLogsUseCase>((ref) {
  return GetPerformanceLogsUseCase(ref.watch(ccmsRepositoryProvider));
});

final _reportErrorUseCaseProvider = Provider<ReportErrorUseCase>((ref) {
  return ReportErrorUseCase(ref.watch(ccmsRepositoryProvider));
});

final _getErrorReportsUseCaseProvider = Provider<GetErrorReportsUseCase>((ref) {
  return GetErrorReportsUseCase(ref.watch(ccmsRepositoryProvider));
});

final _resolveErrorUseCaseProvider = Provider<ResolveErrorUseCase>((ref) {
  return ResolveErrorUseCase(ref.watch(ccmsRepositoryProvider));
});

final _getCcmsStatsUseCaseProvider = Provider<GetCcmsStatsUseCase>((ref) {
  return GetCcmsStatsUseCase(ref.watch(ccmsRepositoryProvider));
});

// ─── Deployment Use Cases ───────────────────────────────────────────────────

final _getDeploymentsUseCaseProvider = Provider<GetDeploymentsUseCase>((ref) {
  return GetDeploymentsUseCase(ref.watch(ccmsRepositoryProvider));
});

final _createDeploymentUseCaseProvider = Provider<CreateDeploymentUseCase>((ref) {
  return CreateDeploymentUseCase(ref.watch(ccmsRepositoryProvider));
});

final _updateDeploymentStatusUseCaseProvider = Provider<UpdateDeploymentStatusUseCase>((ref) {
  return UpdateDeploymentStatusUseCase(ref.watch(ccmsRepositoryProvider));
});

final _recordTestResultUseCaseProvider = Provider<RecordTestResultUseCase>((ref) {
  return RecordTestResultUseCase(ref.watch(ccmsRepositoryProvider));
});

final _getTestResultsUseCaseProvider = Provider<GetTestResultsUseCase>((ref) {
  return GetTestResultsUseCase(ref.watch(ccmsRepositoryProvider));
});

// ═══════════════════════════════════════════════════════════════════════════
// State Notifier Providers
// ═══════════════════════════════════════════════════════════════════════════

// PERF: autoDispose — releases memory when user navigates away from this feature
final educationalLevelProvider = StateNotifierProvider.autoDispose<EducationalLevelNotifier, EducationalLevelState>((ref) {
  return EducationalLevelNotifier(
    getEducationalLevelsUseCase: ref.watch(_getEducationalLevelsUseCaseProvider),
    getSchoolLevelsUseCase: ref.watch(_getSchoolLevelsUseCaseProvider),
    configureSchoolLevelUseCase: ref.watch(_configureSchoolLevelUseCaseProvider),
    updateSchoolLevelConfigurationUseCase: ref.watch(_updateSchoolLevelConfigurationUseCaseProvider),
  );
});

// PERF: autoDispose — releases memory when user navigates away from this feature
final curriculumProvider = StateNotifierProvider.autoDispose<CurriculumNotifier, CurriculumState>((ref) {
  return CurriculumNotifier(
    getCurriculaUseCase: ref.watch(_getCurriculaUseCaseProvider),
    getCurriculumByIdUseCase: ref.watch(_getCurriculumByIdUseCaseProvider),
    createCurriculumUseCase: ref.watch(_createCurriculumUseCaseProvider),
    updateCurriculumUseCase: ref.watch(_updateCurriculumUseCaseProvider),
    getCurriculumVersionsUseCase: ref.watch(_getCurriculumVersionsUseCaseProvider),
    getCurriculumLevelMappingsUseCase: ref.watch(_getCurriculumLevelMappingsUseCaseProvider),
  );
});

// PERF: autoDispose — releases memory when user navigates away from this feature
final subjectProvider = StateNotifierProvider.autoDispose<SubjectNotifier, SubjectState>((ref) {
  return SubjectNotifier(
    getSubjectsUseCase: ref.watch(_getSubjectsUseCaseProvider),
    getSubjectByIdUseCase: ref.watch(_getSubjectByIdUseCaseProvider),
    createSubjectUseCase: ref.watch(_createSubjectUseCaseProvider),
    updateSubjectUseCase: ref.watch(_updateSubjectUseCaseProvider),
    deleteSubjectUseCase: ref.watch(_deleteSubjectUseCaseProvider),
    getLevelSubjectsUseCase: ref.watch(_getLevelSubjectsUseCaseProvider),
  );
});

// PERF: autoDispose — releases memory when user navigates away from this feature
final topicProvider = StateNotifierProvider.autoDispose<TopicNotifier, TopicState>((ref) {
  return TopicNotifier(
    getTopicsUseCase: ref.watch(_getTopicsUseCaseProvider),
    createTopicUseCase: ref.watch(_createTopicUseCaseProvider),
    updateTopicUseCase: ref.watch(_updateTopicUseCaseProvider),
    deleteTopicUseCase: ref.watch(_deleteTopicUseCaseProvider),
    getSubtopicsUseCase: ref.watch(_getSubtopicsUseCaseProvider),
    createSubtopicUseCase: ref.watch(_createSubtopicUseCaseProvider),
    updateSubtopicUseCase: ref.watch(_updateSubtopicUseCaseProvider),
    deleteSubtopicUseCase: ref.watch(_deleteSubtopicUseCaseProvider),
    getCurriculumTreeUseCase: ref.watch(_getCurriculumTreeUseCaseProvider),
  );
});

// PERF: autoDispose — releases memory when user navigates away from this feature
final contentProvider = StateNotifierProvider.autoDispose<ContentNotifier, ContentState>((ref) {
  return ContentNotifier(
    getContentItemsUseCase: ref.watch(_getContentItemsUseCaseProvider),
    getContentByIdUseCase: ref.watch(_getContentByIdUseCaseProvider),
    createContentUseCase: ref.watch(_createContentUseCaseProvider),
    updateContentUseCase: ref.watch(_updateContentUseCaseProvider),
    deleteContentUseCase: ref.watch(_deleteContentUseCaseProvider),
    publishContentUseCase: ref.watch(_publishContentUseCaseProvider),
    archiveContentUseCase: ref.watch(_archiveContentUseCaseProvider),
    getContentVersionsUseCase: ref.watch(_getContentVersionsUseCaseProvider),
    getCcmsStatsUseCase: ref.watch(_getCcmsStatsUseCaseProvider),
  );
});

// PERF: autoDispose — releases memory when user navigates away from this feature
final contentReviewProvider = StateNotifierProvider.autoDispose<ContentReviewNotifier, ContentReviewState>((ref) {
  return ContentReviewNotifier(
    createReviewUseCase: ref.watch(_createReviewUseCaseProvider),
    getContentReviewsUseCase: ref.watch(_getContentReviewsUseCaseProvider),
  );
});

// PERF: autoDispose — releases memory when user navigates away from this feature
final contentImportProvider = StateNotifierProvider.autoDispose<ContentImportNotifier, ContentImportState>((ref) {
  return ContentImportNotifier(
    createImportUseCase: ref.watch(_createImportUseCaseProvider),
    getImportsUseCase: ref.watch(_getImportsUseCaseProvider),
    getImportByIdUseCase: ref.watch(_getImportByIdUseCaseProvider),
  );
});

// PERF: autoDispose — releases memory when user navigates away from this feature
final contentCollectionProvider = StateNotifierProvider.autoDispose<ContentCollectionNotifier, ContentCollectionState>((ref) {
  return ContentCollectionNotifier(
    getCollectionsUseCase: ref.watch(_getCollectionsUseCaseProvider),
    createCollectionUseCase: ref.watch(_createCollectionUseCaseProvider),
    updateCollectionUseCase: ref.watch(_updateCollectionUseCaseProvider),
    deleteCollectionUseCase: ref.watch(_deleteCollectionUseCaseProvider),
    addCollectionItemUseCase: ref.watch(_addCollectionItemUseCaseProvider),
    removeCollectionItemUseCase: ref.watch(_removeCollectionItemUseCaseProvider),
  );
});

// PERF: autoDispose — releases memory when user navigates away from this feature
final aiCurriculumProvider = StateNotifierProvider.autoDispose<AiCurriculumNotifier, AiCurriculumState>((ref) {
  return AiCurriculumNotifier(
    getConfigUseCase: ref.watch(_getAiCurriculumConfigUseCaseProvider),
    upsertConfigUseCase: ref.watch(_upsertAiCurriculumConfigUseCaseProvider),
    getRulesUseCase: ref.watch(_getAiGenerationRulesUseCaseProvider),
    createRuleUseCase: ref.watch(_createAiGenerationRuleUseCaseProvider),
    updateRuleUseCase: ref.watch(_updateAiGenerationRuleUseCaseProvider),
  );
});

// PERF: autoDispose — releases memory when user navigates away from this feature
final answerRepositoryProvider = StateNotifierProvider.autoDispose<AnswerRepositoryNotifier, AnswerRepositoryState>((ref) {
  return AnswerRepositoryNotifier(
    getAnswerEntryUseCase: ref.watch(_getAnswerEntryUseCaseProvider),
    createAnswerEntryUseCase: ref.watch(_createAnswerEntryUseCaseProvider),
    updateAnswerEntryUseCase: ref.watch(_updateAnswerEntryUseCaseProvider),
    verifyAnswerUseCase: ref.watch(_verifyAnswerUseCaseProvider),
  );
});

// PERF: autoDispose — releases memory when user navigates away from this feature
final enterpriseProvider = StateNotifierProvider.autoDispose<EnterpriseNotifier, EnterpriseState>((ref) {
  return EnterpriseNotifier(
    recordAuditEventUseCase: ref.watch(_recordAuditEventUseCaseProvider),
    getAuditTrailUseCase: ref.watch(_getAuditTrailUseCaseProvider),
    getMfaConfigUseCase: ref.watch(_getMfaConfigUseCaseProvider),
    enableMfaUseCase: ref.watch(_enableMfaUseCaseProvider),
    disableMfaUseCase: ref.watch(_disableMfaUseCaseProvider),
    verifyMfaUseCase: ref.watch(_verifyMfaUseCaseProvider),
    createApiKeyUseCase: ref.watch(_createApiKeyUseCaseProvider),
    revokeApiKeyUseCase: ref.watch(_revokeApiKeyUseCaseProvider),
    getApiKeysUseCase: ref.watch(_getApiKeysUseCaseProvider),
    recordSecurityEventUseCase: ref.watch(_recordSecurityEventUseCaseProvider),
    getSecurityEventsUseCase: ref.watch(_getSecurityEventsUseCaseProvider),
    checkRateLimitUseCase: ref.watch(_checkRateLimitUseCaseProvider),
    getUserSessionsUseCase: ref.watch(_getUserSessionsUseCaseProvider),
    invalidateUserSessionsUseCase: ref.watch(_invalidateUserSessionsUseCaseProvider),
    getCcmsStatsUseCase: ref.watch(_getCcmsStatsUseCaseProvider),
    getAlertRulesUseCase: ref.watch(_getAlertRulesUseCaseProvider),
    createAlertRuleUseCase: ref.watch(_createAlertRuleUseCaseProvider),
    getAlertIncidentsUseCase: ref.watch(_getAlertIncidentsUseCaseProvider),
    acknowledgeAlertUseCase: ref.watch(_acknowledgeAlertUseCaseProvider),
    resolveAlertUseCase: ref.watch(_resolveAlertUseCaseProvider),
    recordMetricUseCase: ref.watch(_recordMetricUseCaseProvider),
    getSystemMetricsUseCase: ref.watch(_getSystemMetricsUseCaseProvider),
    recordPerformanceLogUseCase: ref.watch(_recordPerformanceLogUseCaseProvider),
    getPerformanceLogsUseCase: ref.watch(_getPerformanceLogsUseCaseProvider),
    reportErrorUseCase: ref.watch(_reportErrorUseCaseProvider),
    getErrorReportsUseCase: ref.watch(_getErrorReportsUseCaseProvider),
    resolveErrorUseCase: ref.watch(_resolveErrorUseCaseProvider),
  );
});

// PERF: autoDispose — releases memory when user navigates away from this feature
final monitoringProvider = StateNotifierProvider.autoDispose<MonitoringNotifier, MonitoringState>((ref) {
  return MonitoringNotifier(
    recordMetricUseCase: ref.watch(_recordMetricUseCaseProvider),
    getMetricsUseCase: ref.watch(_getSystemMetricsUseCaseProvider),
    getAlertRulesUseCase: ref.watch(_getAlertRulesUseCaseProvider),
    createAlertRuleUseCase: ref.watch(_createAlertRuleUseCaseProvider),
    getAlertIncidentsUseCase: ref.watch(_getAlertIncidentsUseCaseProvider),
    acknowledgeAlertUseCase: ref.watch(_acknowledgeAlertUseCaseProvider),
    resolveAlertUseCase: ref.watch(_resolveAlertUseCaseProvider),
    recordPerformanceLogUseCase: ref.watch(_recordPerformanceLogUseCaseProvider),
    getPerformanceLogsUseCase: ref.watch(_getPerformanceLogsUseCaseProvider),
    reportErrorUseCase: ref.watch(_reportErrorUseCaseProvider),
    getErrorReportsUseCase: ref.watch(_getErrorReportsUseCaseProvider),
    resolveErrorUseCase: ref.watch(_resolveErrorUseCaseProvider),
    getCcmsStatsUseCase: ref.watch(_getCcmsStatsUseCaseProvider),
  );
});

// PERF: autoDispose — releases memory when user navigates away from this feature
final deploymentProvider = StateNotifierProvider.autoDispose<DeploymentNotifier, DeploymentState>((ref) {
  return DeploymentNotifier(
    getDeploymentsUseCase: ref.watch(_getDeploymentsUseCaseProvider),
    createDeploymentUseCase: ref.watch(_createDeploymentUseCaseProvider),
    updateDeploymentStatusUseCase: ref.watch(_updateDeploymentStatusUseCaseProvider),
    recordTestResultUseCase: ref.watch(_recordTestResultUseCaseProvider),
    getTestResultsUseCase: ref.watch(_getTestResultsUseCaseProvider),
  );
});
