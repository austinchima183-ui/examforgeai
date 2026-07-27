import 'package:supabase_flutter/supabase_flutter.dart' as sb;

import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/utils/logger.dart';
import '../../../../core/utils/result.dart';
import '../../domain/entities/admission_hub_entities.dart';
import '../../domain/repositories/admission_hub_repository.dart';
import '../datasources/admission_hub_remote_datasource.dart';
import '../models/admission_hub_models.dart';

/// Concrete implementation of [AdmissionHubRepository] that delegates
/// all operations to [AdmissionHubRemoteDatasource].
///
/// Responsibilities:
/// - Converts domain entities to/from data models
/// - Catches data-layer exceptions and converts them to domain [Failure] types
/// - Returns [Result] to force callers to handle both success and failure
class AdmissionHubRepositoryImpl implements AdmissionHubRepository {
  AdmissionHubRepositoryImpl({
    required AdmissionHubRemoteDatasource remoteDatasource,
    required sb.SupabaseClient supabaseClient,
  })  : _datasource = remoteDatasource,
        _supabaseClient = supabaseClient;

  final AdmissionHubRemoteDatasource _datasource;
  final sb.SupabaseClient _supabaseClient;

  // ═══════════════════════════════════════════════════════════════════════
  // Helper: Safe call with exception → Failure mapping
  // ═══════════════════════════════════════════════════════════════════════

  Future<Result<T>> _safeCall<T>(Future<T> Function() call) async {
    try {
      final result = await call();
      return Success(result);
    } on ServerException catch (e) {
      return FailureResult(Failure.server(
        message: e.message,
        statusCode: e.statusCode,
        data: e.data,
      ),);
    } on AuthException catch (e) {
      return FailureResult(Failure.auth(message: e.message, code: e.code));
    } on NetworkException catch (e) {
      return FailureResult(Failure.network(message: e.message));
    } on NotFoundException catch (e) {
      return FailureResult(Failure.notFound(message: e.message));
    } on UnauthorizedException catch (e) {
      return FailureResult(Failure.unauthorized(message: e.message));
    } on ForbiddenException catch (e) {
      return FailureResult(Failure.forbidden(message: e.message));
    } on ValidationException catch (e) {
      return FailureResult(Failure.validation(
        message: e.message,
        fieldErrors: e.fieldErrors,
      ),);
    } on CacheException catch (e) {
      return FailureResult(Failure.cache(message: e.message));
    } catch (e) {
      AppLogger.error(
          'Unexpected exception in AdmissionHubRepositoryImpl', error: e,);
      return FailureResult(Failure.server(
        message: e.toString(),
        statusCode: 500,
      ),);
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // UNIVERSITIES
  // ═══════════════════════════════════════════════════════════════════════

  @override
  Future<Result<List<University>>> getUniversities({
    UniversityType? type,
    String? state,
    int page = 1,
    int pageSize = 20,
  }) =>
      _safeCall(() async {
        final models = await _datasource.getUniversities(
          type: type?.value,
          state: state,
          page: page,
          pageSize: pageSize,
        );
        return models.map((m) => m.toEntity()).toList();
      });

  @override
  Future<Result<University>> getUniversityById({
    required String universityId,
  }) =>
      _safeCall(() async {
        final model = await _datasource.getUniversityById(
          universityId: universityId,
        );
        return model.toEntity();
      });

  @override
  Future<Result<List<University>>> searchUniversities({
    required String query,
    UniversityType? type,
    String? state,
    int page = 1,
    int pageSize = 20,
  }) =>
      _safeCall(() async {
        final models = await _datasource.searchUniversities(
          query: query,
          type: type?.value,
          state: state,
          page: page,
          pageSize: pageSize,
        );
        return models.map((m) => m.toEntity()).toList();
      });

  // ═══════════════════════════════════════════════════════════════════════
  // FACULTIES & DEPARTMENTS
  // ═══════════════════════════════════════════════════════════════════════

  @override
  Future<Result<List<UniversityFaculty>>> getFaculties({
    required String universityId,
  }) =>
      _safeCall(() async {
        final models = await _datasource.getFaculties(
          universityId: universityId,
        );
        return models.map((m) => m.toEntity()).toList();
      });

  @override
  Future<Result<List<UniversityDepartment>>> getDepartments({
    required String universityId,
    String? facultyId,
  }) =>
      _safeCall(() async {
        final models = await _datasource.getDepartments(
          universityId: universityId,
          facultyId: facultyId,
        );
        return models.map((m) => m.toEntity()).toList();
      });

  // ═══════════════════════════════════════════════════════════════════════
  // ELIGIBILITY CHECKER
  // ═══════════════════════════════════════════════════════════════════════

  @override
  Future<Result<EligibilityResult>> checkAdmissionEligibility({
    required String universityId,
    required String departmentId,
    required double jambScore,
    required List<Map<String, dynamic>> oLevelResults,
    List<String>? selectedSubjects,
  }) =>
      _safeCall(() async {
        final response = await _datasource.checkAdmissionEligibility(
          universityId: universityId,
          departmentId: departmentId,
          jambScore: jambScore,
          oLevelResults: oLevelResults,
          selectedSubjects: selectedSubjects,
        );
        return EligibilityResult(
          universityId: response['university_id'] as String? ?? universityId,
          departmentId: response['department_id'] as String? ?? departmentId,
          isEligible: response['is_eligible'] as bool? ?? false,
          eligibilityScore:
              (response['eligibility_score'] as num?)?.toDouble() ?? 0.0,
          jambScoreMet: response['jamb_score_met'] as bool? ?? false,
          oLevelRequirementsMet:
              response['o_level_requirements_met'] as bool? ?? false,
          subjectCombinationCorrect:
              response['subject_combination_correct'] as bool? ?? false,
          missingSubjects:
              (response['missing_subjects'] as List<dynamic>?)
                      ?.map((e) => e as String)
                      .toList() ??
                  [],
          missingOLevelGrades:
              (response['missing_o_level_grades'] as List<dynamic>?)
                      ?.map((e) => e as String)
                      .toList() ??
                  [],
          recommendations:
              (response['recommendations'] as List<dynamic>?)
                      ?.map((e) => e as String)
                      .toList() ??
                  [],
          details: response['details'] as Map<String, dynamic>? ?? {},
        );
      });

  // ═══════════════════════════════════════════════════════════════════════
  // POST-UTME PRODUCTS
  // ═══════════════════════════════════════════════════════════════════════

  @override
  Future<Result<List<PostUtmeProduct>>> getPostUtmeProducts({
    String? universityId,
    String? departmentId,
    int? year,
    int page = 1,
    int pageSize = 20,
  }) =>
      _safeCall(() async {
        final models = await _datasource.getPostUtmeProducts(
          universityId: universityId,
          departmentId: departmentId,
          year: year,
          page: page,
          pageSize: pageSize,
        );
        return models.map((m) => m.toEntity()).toList();
      });

  @override
  Future<Result<PostUtmeProduct>> createPostUtmeProduct({
    required String universityId,
    required String departmentId,
    required String facultyId,
    required String name,
    String? description,
    required int year,
    int durationMinutes = 60,
    int totalQuestions = 50,
    int totalMarks = 100,
    double passMark = 50,
    List<Map<String, dynamic>> instructions = const [],
    Map<String, dynamic> settings = const {},
    bool isPremium = false,
    String sourceType = 'official',
    bool hasLicensingRights = false,
    Map<String, dynamic> licenseDetails = const {},
  }) =>
      _safeCall(() async {
        final data = PostUtmeProduct(
          id: '',
          universityId: universityId,
          departmentId: departmentId,
          facultyId: facultyId,
          name: name,
          description: description,
          year: year,
          durationMinutes: durationMinutes,
          totalQuestions: totalQuestions,
          totalMarks: totalMarks,
          passMark: passMark,
          instructions: instructions,
          settings: settings,
          isPremium: isPremium,
          sourceType: sourceType,
          hasLicensingRights: hasLicensingRights,
          licenseDetails: licenseDetails,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        final model = await _datasource.createPostUtmeProduct(
          data: PostUtmeProductModel.fromEntity(data).toJson()
            ..['created_by'] = _supabaseClient.auth.currentUser?.id,
        );
        return model.toEntity();
      });

  // ═══════════════════════════════════════════════════════════════════════
  // ADMISSION CHECKLIST
  // ═══════════════════════════════════════════════════════════════════════

  @override
  Future<Result<AdmissionChecklist>> getAdmissionChecklist({
    required String userId,
    required String universityId,
    required String departmentId,
  }) =>
      _safeCall(() async {
        final model = await _datasource.getAdmissionChecklist(
          userId: userId,
          universityId: universityId,
          departmentId: departmentId,
        );
        return model.toEntity();
      });

  @override
  Future<Result<AdmissionChecklist>> updateAdmissionChecklist({
    required String checklistId,
    List<Map<String, dynamic>>? completedItems,
    List<Map<String, dynamic>>? documents,
    double? overallReadinessScore,
    String? status,
  }) =>
      _safeCall(() async {
        final data = <String, dynamic>{};
        if (completedItems != null) data['completed_items'] = completedItems;
        if (documents != null) data['documents'] = documents;
        if (overallReadinessScore != null) {
          data['overall_readiness_score'] = overallReadinessScore;
        }
        if (status != null) data['status'] = status;
        final model = await _datasource.updateAdmissionChecklist(
          checklistId: checklistId,
          data: data,
        );
        return model.toEntity();
      });

  // ═══════════════════════════════════════════════════════════════════════
  // ADMISSION APPLICATIONS
  // ═══════════════════════════════════════════════════════════════════════

  @override
  Future<Result<List<AdmissionApplication>>> getAdmissionApplications({
    required String userId,
    AdmissionStatus? status,
    int page = 1,
    int pageSize = 20,
  }) =>
      _safeCall(() async {
        final models = await _datasource.getAdmissionApplications(
          userId: userId,
          status: status?.value,
          page: page,
          pageSize: pageSize,
        );
        return models.map((m) => m.toEntity()).toList();
      });

  @override
  Future<Result<AdmissionApplication>> createAdmissionApplication({
    required String userId,
    required String universityId,
    required String departmentId,
    required String course,
    required int applicationYear,
    double? jambScore,
    double? postUtmeScore,
    List<Map<String, dynamic>> oLevelResults = const [],
    List<Map<String, dynamic>> documents = const [],
    String? notes,
  }) =>
      _safeCall(() async {
        final data = AdmissionApplicationModel(
          id: '',
          userId: userId,
          universityId: universityId,
          departmentId: departmentId,
          course: course,
          admissionStatus: 'applied',
          applicationYear: applicationYear,
          jambScore: jambScore,
          postUtmeScore: postUtmeScore,
          oLevelResults: oLevelResults,
          documents: documents,
          notes: notes,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ).toJson();
        final model = await _datasource.createAdmissionApplication(data: data);
        return model.toEntity();
      });

  @override
  Future<Result<AdmissionApplication>> updateAdmissionApplication({
    required String applicationId,
    AdmissionStatus? admissionStatus,
    double? jambScore,
    double? postUtmeScore,
    List<Map<String, dynamic>>? oLevelResults,
    List<Map<String, dynamic>>? documents,
    String? notes,
  }) =>
      _safeCall(() async {
        final data = <String, dynamic>{};
        if (admissionStatus != null) {
          data['admission_status'] = admissionStatus.value;
        }
        if (jambScore != null) data['jamb_score'] = jambScore;
        if (postUtmeScore != null) data['post_utme_score'] = postUtmeScore;
        if (oLevelResults != null) data['o_level_results'] = oLevelResults;
        if (documents != null) data['documents'] = documents;
        if (notes != null) data['notes'] = notes;
        final model = await _datasource.updateAdmissionApplication(
          applicationId: applicationId,
          data: data,
        );
        return model.toEntity();
      });

  // ═══════════════════════════════════════════════════════════════════════
  // UNIVERSITY COMPARISON
  // ═══════════════════════════════════════════════════════════════════════

  @override
  Future<Result<UniversityComparison>> compareUniversities({
    required List<String> universityIds,
  }) =>
      _safeCall(() async {
        final models = await _datasource.compareUniversities(
          universityIds: universityIds,
        );
        final entities = models.map((m) => m.toEntity()).toList();

        // Build comparison data from the entities
        final comparisonData = <String, dynamic>{
          'university_count': entities.length,
          'types': entities.map((u) => u.universityType.label).toList(),
          'states': entities.map((u) => u.state).toList(),
          'rankings': entities
              .map((u) => u.rankingNational ?? 0)
              .toList(),
        };

        return UniversityComparison(
          universities: entities,
          comparisonData: comparisonData,
        );
      });
}
