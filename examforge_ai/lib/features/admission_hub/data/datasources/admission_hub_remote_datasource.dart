import 'package:supabase_flutter/supabase_flutter.dart' as sb;
import '../../../../core/errors/exceptions.dart';
import '../../../../core/utils/logger.dart';
import '../models/admission_hub_models.dart';

/// Abstract contract for the Admission Hub remote data source.
abstract class AdmissionHubRemoteDatasource {
  Future<List<UniversityModel>> getUniversities({
    String? type,
    String? state,
    int page = 1,
    int pageSize = 20,
  });

  Future<UniversityModel> getUniversityById({required String universityId});

  Future<List<UniversityModel>> searchUniversities({
    required String query,
    String? type,
    String? state,
    int page = 1,
    int pageSize = 20,
  });

  Future<List<UniversityFacultyModel>> getFaculties({
    required String universityId,
  });

  Future<List<UniversityDepartmentModel>> getDepartments({
    required String universityId,
    String? facultyId,
  });

  Future<Map<String, dynamic>> checkAdmissionEligibility({
    required String universityId,
    required String departmentId,
    required double jambScore,
    required List<Map<String, dynamic>> oLevelResults,
    List<String>? selectedSubjects,
  });

  Future<List<PostUtmeProductModel>> getPostUtmeProducts({
    String? universityId,
    String? departmentId,
    int? year,
    int page = 1,
    int pageSize = 20,
  });

  Future<PostUtmeProductModel> createPostUtmeProduct({
    required Map<String, dynamic> data,
  });

  Future<AdmissionChecklistModel> getAdmissionChecklist({
    required String userId,
    required String universityId,
    required String departmentId,
  });

  Future<AdmissionChecklistModel> updateAdmissionChecklist({
    required String checklistId,
    required Map<String, dynamic> data,
  });

  Future<List<AdmissionApplicationModel>> getAdmissionApplications({
    required String userId,
    String? status,
    int page = 1,
    int pageSize = 20,
  });

  Future<AdmissionApplicationModel> createAdmissionApplication({
    required Map<String, dynamic> data,
  });

  Future<AdmissionApplicationModel> updateAdmissionApplication({
    required String applicationId,
    required Map<String, dynamic> data,
  });

  Future<List<UniversityModel>> compareUniversities({
    required List<String> universityIds,
  });
}

/// Supabase implementation of [AdmissionHubRemoteDatasource].
class AdmissionHubRemoteDatasourceImpl implements AdmissionHubRemoteDatasource {
  AdmissionHubRemoteDatasourceImpl({
    required sb.SupabaseClient supabaseClient,
  }) : _supabase = supabaseClient;

  final sb.SupabaseClient _supabase;

  // ── Table name constants ───────────────────────────────────────────────
  static const _universitiesTable = 'universities';
  static const _universityFacultiesTable = 'university_faculties';
  static const _universityDepartmentsTable = 'university_departments';
  static const _postUtmeProductsTable = 'post_utme_products';
  static const _admissionChecklistsTable = 'admission_checklists';
  static const _admissionApplicationsTable = 'admission_applications';

  // ── Edge function names ────────────────────────────────────────────────
  static const _checkEligibilityFunction = 'check-admission-eligibility';

  // ── Exception mapping helper ───────────────────────────────────────────

  Never _mapPostgrestException(sb.PostgrestException e) {
    AppLogger.error('Postgrest error: ${e.message}', error: e);
    switch (e.code) {
      case 'PGRST116':
        throw NotFoundException(e.message);
      case '23505':
        throw ServerException(
          message: 'A record with this data already exists.',
          statusCode: 409,
        );
      case '23503':
        throw ServerException(
          message: 'Referenced record not found.',
          statusCode: 404,
        );
      case '42501':
        throw ForbiddenException(
          message: 'You do not have permission for this action.',
        );
      default:
        throw ServerException(
          message: e.message,
          statusCode: int.tryParse(e.code ?? '') ?? 500,
        );
    }
  }

  Never _handleGenericException(Object e, String operation) {
    AppLogger.error('Failed to $operation', error: e);
    if (e is sb.AuthException) {
      throw UnauthorizedException(e.message);
    }
    throw ServerException(message: e.toString(), statusCode: 500);
  }

  // ═══════════════════════════════════════════════════════════════════════
  // UNIVERSITIES
  // ═══════════════════════════════════════════════════════════════════════

  @override
  Future<List<UniversityModel>> getUniversities({
    String? type,
    String? state,
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      var query = _supabase
          .from(_universitiesTable)
          .select()
          .eq('is_active', true)
          .order('name');

      if (type != null) {
        query = query.eq('university_type', type);
      }
      if (state != null) {
        query = query.eq('state', state);
      }

      final offset = (page - 1) * pageSize;
      final response = await query.range(offset, offset + pageSize - 1);

      return response
          .map<UniversityModel>(
              (json) => UniversityModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } on sb.PostgrestException catch (e) {
      _mapPostgrestException(e);
    } catch (e) {
      _handleGenericException(e, 'get universities');
    }
  }

  @override
  Future<UniversityModel> getUniversityById({
    required String universityId,
  }) async {
    try {
      final response = await _supabase
          .from(_universitiesTable)
          .select()
          .eq('id', universityId)
          .single();

      return UniversityModel.fromJson(response);
    } on sb.PostgrestException catch (e) {
      _mapPostgrestException(e);
    } catch (e) {
      _handleGenericException(e, 'get university by id');
    }
  }

  @override
  Future<List<UniversityModel>> searchUniversities({
    required String query,
    String? type,
    String? state,
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      var supabaseQuery = _supabase
          .from(_universitiesTable)
          .select()
          .eq('is_active', true)
          .ilike('name', '%$query%')
          .order('name');

      if (type != null) {
        supabaseQuery = supabaseQuery.eq('university_type', type);
      }
      if (state != null) {
        supabaseQuery = supabaseQuery.eq('state', state);
      }

      final offset = (page - 1) * pageSize;
      final response = await supabaseQuery.range(offset, offset + pageSize - 1);

      return response
          .map<UniversityModel>(
              (json) => UniversityModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } on sb.PostgrestException catch (e) {
      _mapPostgrestException(e);
    } catch (e) {
      _handleGenericException(e, 'search universities');
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // FACULTIES & DEPARTMENTS
  // ═══════════════════════════════════════════════════════════════════════

  @override
  Future<List<UniversityFacultyModel>> getFaculties({
    required String universityId,
  }) async {
    try {
      final response = await _supabase
          .from(_universityFacultiesTable)
          .select()
          .eq('university_id', universityId)
          .eq('is_active', true)
          .order('sort_order');

      return response
          .map<UniversityFacultyModel>(
              (json) => UniversityFacultyModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } on sb.PostgrestException catch (e) {
      _mapPostgrestException(e);
    } catch (e) {
      _handleGenericException(e, 'get faculties');
    }
  }

  @override
  Future<List<UniversityDepartmentModel>> getDepartments({
    required String universityId,
    String? facultyId,
  }) async {
    try {
      // First get the faculty IDs for this university
      var facultyQuery = _supabase
          .from(_universityFacultiesTable)
          .select('id')
          .eq('university_id', universityId)
          .eq('is_active', true);

      if (facultyId != null) {
        facultyQuery = facultyQuery.eq('id', facultyId);
      }

      final facultyResponse = await facultyQuery;
      final facultyIds = facultyResponse
          .map<String>((f) => f['id'] as String)
          .toList();

      if (facultyIds.isEmpty) return [];

      final response = await _supabase
          .from(_universityDepartmentsTable)
          .select()
          .inFilter('faculty_id', facultyIds)
          .eq('is_active', true)
          .order('sort_order');

      return response
          .map<UniversityDepartmentModel>((json) =>
              UniversityDepartmentModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } on sb.PostgrestException catch (e) {
      _mapPostgrestException(e);
    } catch (e) {
      _handleGenericException(e, 'get departments');
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // ELIGIBILITY CHECKER
  // ═══════════════════════════════════════════════════════════════════════

  @override
  Future<Map<String, dynamic>> checkAdmissionEligibility({
    required String universityId,
    required String departmentId,
    required double jambScore,
    required List<Map<String, dynamic>> oLevelResults,
    List<String>? selectedSubjects,
  }) async {
    try {
      final response = await _supabase.functions.invoke(
        _checkEligibilityFunction,
        body: {
          'university_id': universityId,
          'department_id': departmentId,
          'jamb_score': jambScore,
          'o_level_results': oLevelResults,
          if (selectedSubjects != null) 'selected_subjects': selectedSubjects,
        },
      );

      if (response.status != 200) {
        throw ServerException(
          message: 'Eligibility check failed: ${response.data}',
          statusCode: response.status,
        );
      }

      return response.data as Map<String, dynamic>;
    } on sb.PostgrestException catch (e) {
      _mapPostgrestException(e);
    } catch (e) {
      if (e is ServerException) rethrow;
      _handleGenericException(e, 'check admission eligibility');
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // POST-UTME PRODUCTS
  // ═══════════════════════════════════════════════════════════════════════

  @override
  Future<List<PostUtmeProductModel>> getPostUtmeProducts({
    String? universityId,
    String? departmentId,
    int? year,
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      var query = _supabase
          .from(_postUtmeProductsTable)
          .select()
          .eq('is_active', true)
          .order('created_at', ascending: false);

      if (universityId != null) {
        query = query.eq('university_id', universityId);
      }
      if (departmentId != null) {
        query = query.eq('department_id', departmentId);
      }
      if (year != null) {
        query = query.eq('year', year);
      }

      final offset = (page - 1) * pageSize;
      final response = await query.range(offset, offset + pageSize - 1);

      return response
          .map<PostUtmeProductModel>((json) =>
              PostUtmeProductModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } on sb.PostgrestException catch (e) {
      _mapPostgrestException(e);
    } catch (e) {
      _handleGenericException(e, 'get post-UTME products');
    }
  }

  @override
  Future<PostUtmeProductModel> createPostUtmeProduct({
    required Map<String, dynamic> data,
  }) async {
    try {
      final response = await _supabase
          .from(_postUtmeProductsTable)
          .insert(data)
          .select()
          .single();

      return PostUtmeProductModel.fromJson(response);
    } on sb.PostgrestException catch (e) {
      _mapPostgrestException(e);
    } catch (e) {
      _handleGenericException(e, 'create post-UTME product');
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // ADMISSION CHECKLIST
  // ═══════════════════════════════════════════════════════════════════════

  @override
  Future<AdmissionChecklistModel> getAdmissionChecklist({
    required String userId,
    required String universityId,
    required String departmentId,
  }) async {
    try {
      final response = await _supabase
          .from(_admissionChecklistsTable)
          .select()
          .eq('user_id', userId)
          .eq('university_id', universityId)
          .eq('department_id', departmentId)
          .maybeSingle();

      if (response == null) {
        throw NotFoundException(
          'No checklist found for this university/department combination',
        );
      }

      return AdmissionChecklistModel.fromJson(response);
    } on sb.PostgrestException catch (e) {
      _mapPostgrestException(e);
    } catch (e) {
      if (e is NotFoundException) rethrow;
      _handleGenericException(e, 'get admission checklist');
    }
  }

  @override
  Future<AdmissionChecklistModel> updateAdmissionChecklist({
    required String checklistId,
    required Map<String, dynamic> data,
  }) async {
    try {
      final response = await _supabase
          .from(_admissionChecklistsTable)
          .update(data)
          .eq('id', checklistId)
          .select()
          .single();

      return AdmissionChecklistModel.fromJson(response);
    } on sb.PostgrestException catch (e) {
      _mapPostgrestException(e);
    } catch (e) {
      _handleGenericException(e, 'update admission checklist');
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // ADMISSION APPLICATIONS
  // ═══════════════════════════════════════════════════════════════════════

  @override
  Future<List<AdmissionApplicationModel>> getAdmissionApplications({
    required String userId,
    String? status,
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      var query = _supabase
          .from(_admissionApplicationsTable)
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      if (status != null) {
        query = query.eq('admission_status', status);
      }

      final offset = (page - 1) * pageSize;
      final response = await query.range(offset, offset + pageSize - 1);

      return response
          .map<AdmissionApplicationModel>((json) =>
              AdmissionApplicationModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } on sb.PostgrestException catch (e) {
      _mapPostgrestException(e);
    } catch (e) {
      _handleGenericException(e, 'get admission applications');
    }
  }

  @override
  Future<AdmissionApplicationModel> createAdmissionApplication({
    required Map<String, dynamic> data,
  }) async {
    try {
      final response = await _supabase
          .from(_admissionApplicationsTable)
          .insert(data)
          .select()
          .single();

      return AdmissionApplicationModel.fromJson(response);
    } on sb.PostgrestException catch (e) {
      _mapPostgrestException(e);
    } catch (e) {
      _handleGenericException(e, 'create admission application');
    }
  }

  @override
  Future<AdmissionApplicationModel> updateAdmissionApplication({
    required String applicationId,
    required Map<String, dynamic> data,
  }) async {
    try {
      final response = await _supabase
          .from(_admissionApplicationsTable)
          .update(data)
          .eq('id', applicationId)
          .select()
          .single();

      return AdmissionApplicationModel.fromJson(response);
    } on sb.PostgrestException catch (e) {
      _mapPostgrestException(e);
    } catch (e) {
      _handleGenericException(e, 'update admission application');
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // UNIVERSITY COMPARISON
  // ═══════════════════════════════════════════════════════════════════════

  @override
  Future<List<UniversityModel>> compareUniversities({
    required List<String> universityIds,
  }) async {
    try {
      final response = await _supabase
          .from(_universitiesTable)
          .select()
          .inFilter('id', universityIds)
          .eq('is_active', true)
          .order('name');

      return response
          .map<UniversityModel>(
              (json) => UniversityModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } on sb.PostgrestException catch (e) {
      _mapPostgrestException(e);
    } catch (e) {
      _handleGenericException(e, 'compare universities');
    }
  }
}
