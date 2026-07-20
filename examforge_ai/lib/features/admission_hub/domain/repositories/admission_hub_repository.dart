import '../../../../core/utils/result.dart';
import '../entities/admission_hub_entities.dart';

/// Abstract contract for the Admission Hub repository.
///
/// Defines all operations the Admission Hub feature requires from
/// the data layer. The implementation maps Supabase / network
/// exceptions to domain [Failure]s and wraps results in [Result<T>].
abstract class AdmissionHubRepository {
  // ═══════════════════════════════════════════════════════════════════════
  // UNIVERSITIES
  // ═══════════════════════════════════════════════════════════════════════

  /// Fetches all universities with optional filtering.
  Future<Result<List<University>>> getUniversities({
    UniversityType? type,
    String? state,
    int page = 1,
    int pageSize = 20,
  });

  /// Gets a single university by ID.
  Future<Result<University>> getUniversityById({required String universityId});

  /// Searches universities by name, state, type, or keyword.
  Future<Result<List<University>>> searchUniversities({
    required String query,
    UniversityType? type,
    String? state,
    int page = 1,
    int pageSize = 20,
  });

  // ═══════════════════════════════════════════════════════════════════════
  // FACULTIES & DEPARTMENTS
  // ═══════════════════════════════════════════════════════════════════════

  /// Gets all faculties for a university.
  Future<Result<List<UniversityFaculty>>> getFaculties({
    required String universityId,
  });

  /// Gets all departments for a faculty or university.
  Future<Result<List<UniversityDepartment>>> getDepartments({
    required String universityId,
    String? facultyId,
  });

  // ═══════════════════════════════════════════════════════════════════════
  // ELIGIBILITY CHECKER
  // ═══════════════════════════════════════════════════════════════════════

  /// Checks admission eligibility for a given university/department.
  Future<Result<EligibilityResult>> checkAdmissionEligibility({
    required String universityId,
    required String departmentId,
    required double jambScore,
    required List<Map<String, dynamic>> oLevelResults,
    List<String>? selectedSubjects,
  });

  // ═══════════════════════════════════════════════════════════════════════
  // POST-UTME PRODUCTS
  // ═══════════════════════════════════════════════════════════════════════

  /// Gets Post-UTME practice test products.
  Future<Result<List<PostUtmeProduct>>> getPostUtmeProducts({
    String? universityId,
    String? departmentId,
    int? year,
    int page = 1,
    int pageSize = 20,
  });

  /// Creates a new Post-UTME product (admin/content-creator only).
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
  });

  // ═══════════════════════════════════════════════════════════════════════
  // ADMISSION CHECKLIST
  // ═══════════════════════════════════════════════════════════════════════

  /// Gets the admission checklist for a user/university/department.
  Future<Result<AdmissionChecklist>> getAdmissionChecklist({
    required String userId,
    required String universityId,
    required String departmentId,
  });

  /// Updates the admission checklist (marks items complete, etc.).
  Future<Result<AdmissionChecklist>> updateAdmissionChecklist({
    required String checklistId,
    List<Map<String, dynamic>>? completedItems,
    List<Map<String, dynamic>>? documents,
    double? overallReadinessScore,
    String? status,
  });

  // ═══════════════════════════════════════════════════════════════════════
  // ADMISSION APPLICATIONS
  // ═══════════════════════════════════════════════════════════════════════

  /// Gets all admission applications for a user.
  Future<Result<List<AdmissionApplication>>> getAdmissionApplications({
    required String userId,
    AdmissionStatus? status,
    int page = 1,
    int pageSize = 20,
  });

  /// Creates a new admission application.
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
  });

  /// Updates an admission application.
  Future<Result<AdmissionApplication>> updateAdmissionApplication({
    required String applicationId,
    AdmissionStatus? admissionStatus,
    double? jambScore,
    double? postUtmeScore,
    List<Map<String, dynamic>>? oLevelResults,
    List<Map<String, dynamic>>? documents,
    String? notes,
  });

  // ═══════════════════════════════════════════════════════════════════════
  // UNIVERSITY COMPARISON
  // ═══════════════════════════════════════════════════════════════════════

  /// Compares two or more universities side by side.
  Future<Result<UniversityComparison>> compareUniversities({
    required List<String> universityIds,
  });
}
