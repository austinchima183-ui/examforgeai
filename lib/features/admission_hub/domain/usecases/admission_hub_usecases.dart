import '../../../../core/utils/result.dart';
import '../entities/admission_hub_entities.dart';
import '../repositories/admission_hub_repository.dart';

// ═══════════════════════════════════════════════════════════════════════
// GET UNIVERSITIES USE CASE
// ═══════════════════════════════════════════════════════════════════════

class GetUniversitiesUseCase {
  final AdmissionHubRepository _repository;
  GetUniversitiesUseCase(this._repository);

  Future<Result<List<University>>> call({
    UniversityType? type,
    String? state,
    int page = 1,
    int pageSize = 20,
  }) =>
      _repository.getUniversities(
        type: type,
        state: state,
        page: page,
        pageSize: pageSize,
      );
}

// ═══════════════════════════════════════════════════════════════════════
// SEARCH UNIVERSITIES USE CASE
// ═══════════════════════════════════════════════════════════════════════

class SearchUniversitiesUseCase {
  final AdmissionHubRepository _repository;
  SearchUniversitiesUseCase(this._repository);

  Future<Result<List<University>>> call({
    required String query,
    UniversityType? type,
    String? state,
    int page = 1,
    int pageSize = 20,
  }) =>
      _repository.searchUniversities(
        query: query,
        type: type,
        state: state,
        page: page,
        pageSize: pageSize,
      );
}

// ═══════════════════════════════════════════════════════════════════════
// GET UNIVERSITY DEPARTMENTS USE CASE
// ═══════════════════════════════════════════════════════════════════════

class GetUniversityDepartmentsUseCase {
  final AdmissionHubRepository _repository;
  GetUniversityDepartmentsUseCase(this._repository);

  Future<Result<List<UniversityDepartment>>> call({
    required String universityId,
    String? facultyId,
  }) =>
      _repository.getDepartments(
        universityId: universityId,
        facultyId: facultyId,
      );
}

// ═══════════════════════════════════════════════════════════════════════
// CHECK ADMISSION ELIGIBILITY USE CASE
// ═══════════════════════════════════════════════════════════════════════

class CheckAdmissionEligibilityUseCase {
  final AdmissionHubRepository _repository;
  CheckAdmissionEligibilityUseCase(this._repository);

  Future<Result<EligibilityResult>> call({
    required String universityId,
    required String departmentId,
    required double jambScore,
    required List<Map<String, dynamic>> oLevelResults,
    List<String>? selectedSubjects,
  }) =>
      _repository.checkAdmissionEligibility(
        universityId: universityId,
        departmentId: departmentId,
        jambScore: jambScore,
        oLevelResults: oLevelResults,
        selectedSubjects: selectedSubjects,
      );
}

// ═══════════════════════════════════════════════════════════════════════
// GET POST-UTME PRODUCTS USE CASE
// ═══════════════════════════════════════════════════════════════════════

class GetPostUtmeProductsUseCase {
  final AdmissionHubRepository _repository;
  GetPostUtmeProductsUseCase(this._repository);

  Future<Result<List<PostUtmeProduct>>> call({
    String? universityId,
    String? departmentId,
    int? year,
    int page = 1,
    int pageSize = 20,
  }) =>
      _repository.getPostUtmeProducts(
        universityId: universityId,
        departmentId: departmentId,
        year: year,
        page: page,
        pageSize: pageSize,
      );
}

// ═══════════════════════════════════════════════════════════════════════
// CREATE POST-UTME PRODUCT USE CASE
// ═══════════════════════════════════════════════════════════════════════

class CreatePostUtmeProductUseCase {
  final AdmissionHubRepository _repository;
  CreatePostUtmeProductUseCase(this._repository);

  Future<Result<PostUtmeProduct>> call({
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
      _repository.createPostUtmeProduct(
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
      );
}

// ═══════════════════════════════════════════════════════════════════════
// GET ADMISSION CHECKLIST USE CASE
// ═══════════════════════════════════════════════════════════════════════

class GetAdmissionChecklistUseCase {
  final AdmissionHubRepository _repository;
  GetAdmissionChecklistUseCase(this._repository);

  Future<Result<AdmissionChecklist>> call({
    required String userId,
    required String universityId,
    required String departmentId,
  }) =>
      _repository.getAdmissionChecklist(
        userId: userId,
        universityId: universityId,
        departmentId: departmentId,
      );
}

// ═══════════════════════════════════════════════════════════════════════
// UPDATE ADMISSION CHECKLIST USE CASE
// ═══════════════════════════════════════════════════════════════════════

class UpdateAdmissionChecklistUseCase {
  final AdmissionHubRepository _repository;
  UpdateAdmissionChecklistUseCase(this._repository);

  Future<Result<AdmissionChecklist>> call({
    required String checklistId,
    List<Map<String, dynamic>>? completedItems,
    List<Map<String, dynamic>>? documents,
    double? overallReadinessScore,
    String? status,
  }) =>
      _repository.updateAdmissionChecklist(
        checklistId: checklistId,
        completedItems: completedItems,
        documents: documents,
        overallReadinessScore: overallReadinessScore,
        status: status,
      );
}

// ═══════════════════════════════════════════════════════════════════════
// CREATE ADMISSION APPLICATION USE CASE
// ═══════════════════════════════════════════════════════════════════════

class CreateAdmissionApplicationUseCase {
  final AdmissionHubRepository _repository;
  CreateAdmissionApplicationUseCase(this._repository);

  Future<Result<AdmissionApplication>> call({
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
      _repository.createAdmissionApplication(
        userId: userId,
        universityId: universityId,
        departmentId: departmentId,
        course: course,
        applicationYear: applicationYear,
        jambScore: jambScore,
        postUtmeScore: postUtmeScore,
        oLevelResults: oLevelResults,
        documents: documents,
        notes: notes,
      );
}

// ═══════════════════════════════════════════════════════════════════════
// COMPARE UNIVERSITIES USE CASE
// ═══════════════════════════════════════════════════════════════════════

class CompareUniversitiesUseCase {
  final AdmissionHubRepository _repository;
  CompareUniversitiesUseCase(this._repository);

  Future<Result<UniversityComparison>> call({
    required List<String> universityIds,
  }) =>
      _repository.compareUniversities(universityIds: universityIds);
}
