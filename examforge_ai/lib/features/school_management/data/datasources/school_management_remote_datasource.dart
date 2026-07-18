import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart' as sb;

import '../../../../core/errors/exceptions.dart';
import '../../../../core/utils/logger.dart';
import '../models/school_management_models.dart';

// ═══════════════════════════════════════════════════════════════════════
// ABSTRACT INTERFACE
// ═══════════════════════════════════════════════════════════════════════

/// Abstract interface for all remote School Management data operations.
///
/// Implementations handle all network communication with the Supabase
/// backend and return plain model instances. Exceptions are allowed to
/// propagate so the repository layer can catch and convert them to
/// domain [Failure] types.
abstract class SchoolManagementRemoteDataSource {
  // ─── School CRUD ──────────────────────────────────────────────────────

  Future<SchoolModel> createSchool(Map<String, dynamic> schoolData);
  Future<SchoolModel> updateSchool(String schoolId, Map<String, dynamic> schoolData);
  Future<void> deleteSchool(String schoolId);
  Future<SchoolModel> getSchool(String schoolId);
  Future<List<SchoolModel>> getSchools(Map<String, dynamic> filters);

  // ─── Branches ─────────────────────────────────────────────────────────

  Future<SchoolBranchModel> createBranch(Map<String, dynamic> branchData);
  Future<SchoolBranchModel> updateBranch(String branchId, Map<String, dynamic> branchData);
  Future<void> deleteBranch(String branchId);
  Future<List<SchoolBranchModel>> getBranches(String schoolId);

  // ─── Departments ──────────────────────────────────────────────────────

  Future<DepartmentModel> createDepartment(Map<String, dynamic> departmentData);
  Future<DepartmentModel> updateDepartment(String departmentId, Map<String, dynamic> departmentData);
  Future<void> deleteDepartment(String departmentId);
  Future<List<DepartmentModel>> getDepartments(String schoolId);

  // ─── Student Profiles ─────────────────────────────────────────────────

  Future<StudentProfileModel> createStudentProfile(Map<String, dynamic> profileData);
  Future<StudentProfileModel> updateStudentProfile(String profileId, Map<String, dynamic> profileData);
  Future<StudentProfileModel> getStudentProfile(String userId);
  Future<List<StudentProfileModel>> getStudentProfiles({
    required String schoolId,
    String? classId,
    bool? isActive,
    bool? isGraduated,
    String? searchQuery,
    int page = 1,
    int perPage = 20,
  });
  Future<PromotionHistoryModel> promoteStudent(Map<String, dynamic> data);
  Future<StudentProfileModel> graduateStudent(String studentId, String schoolId);
  Future<List<PromotionHistoryModel>> getPromotionHistory(String studentId);

  // ─── Teacher Profiles ─────────────────────────────────────────────────

  Future<TeacherProfileModel> createTeacherProfile(Map<String, dynamic> profileData);
  Future<TeacherProfileModel> updateTeacherProfile(String profileId, Map<String, dynamic> profileData);
  Future<TeacherProfileModel> getTeacherProfile(String userId);
  Future<List<TeacherProfileModel>> getTeacherProfiles({
    required String schoolId,
    String? departmentId,
    bool? isActive,
    String? searchQuery,
    int page = 1,
    int perPage = 20,
  });

  // ─── Parent Profiles ──────────────────────────────────────────────────

  Future<ParentProfileModel> createParentProfile(Map<String, dynamic> profileData);
  Future<ParentProfileModel> updateParentProfile(String profileId, Map<String, dynamic> profileData);
  Future<ParentProfileModel> getParentProfile(String userId);
  Future<List<ParentProfileModel>> getParentProfiles({
    required String schoolId,
    String? searchQuery,
    int page = 1,
    int perPage = 20,
  });
  Future<ParentStudentLinkModel> linkParentToStudent(Map<String, dynamic> data);
  Future<void> unlinkParentFromStudent(String linkId);
  Future<List<ParentStudentLinkModel>> getParentStudentLinks(String studentId);

  // ─── Academic Sessions ────────────────────────────────────────────────

  Future<AcademicSessionModel> createSession(Map<String, dynamic> sessionData);
  Future<AcademicSessionModel> updateSession(String sessionId, Map<String, dynamic> sessionData);
  Future<void> deleteSession(String sessionId);
  Future<AcademicSessionModel> getSession(String sessionId);
  Future<List<AcademicSessionModel>> getSessions(String schoolId);
  Future<AcademicSessionModel> getCurrentSession(String schoolId);
  Future<AcademicSessionModel> setCurrentSession(String sessionId);

  // ─── Terms ────────────────────────────────────────────────────────────

  Future<TermModel> createTerm(Map<String, dynamic> termData);
  Future<TermModel> updateTerm(String termId, Map<String, dynamic> termData);
  Future<void> deleteTerm(String termId);
  Future<List<TermModel>> getTerms(String sessionId);
  Future<TermModel> getCurrentTerm(String schoolId);
  Future<TermModel> setCurrentTerm(String termId);

  // ─── Calendar Events ──────────────────────────────────────────────────

  Future<CalendarEventModel> createCalendarEvent(Map<String, dynamic> eventData);
  Future<CalendarEventModel> updateCalendarEvent(String eventId, Map<String, dynamic> eventData);
  Future<void> deleteCalendarEvent(String eventId);
  Future<List<CalendarEventModel>> getCalendarEvents({
    required String schoolId,
    String? termId,
    String? startDate,
    String? endDate,
    String? eventType,
  });

  // ─── Timetables ───────────────────────────────────────────────────────

  Future<TimetableModel> createTimetable(Map<String, dynamic> timetableData);
  Future<TimetableModel> updateTimetable(String timetableId, Map<String, dynamic> timetableData);
  Future<void> deleteTimetable(String timetableId);
  Future<TimetableModel> getTimetable(String timetableId);
  Future<List<TimetableModel>> getTimetables({
    required String schoolId,
    String? termId,
    String? classId,
  });
  Future<TimetableSlotModel> addTimetableSlot(Map<String, dynamic> slotData);
  Future<TimetableSlotModel> updateTimetableSlot(String slotId, Map<String, dynamic> slotData);
  Future<void> deleteTimetableSlot(String slotId);
  Future<TimetableModel> publishTimetable(String timetableId);
  Future<List<Map<String, dynamic>>> checkSlotConflicts({
    required String teacherId,
    required String classId,
    required String dayOfWeek,
    required int periodNumber,
    String? excludeSlotId,
  });

  // ─── Attendance ───────────────────────────────────────────────────────

  Future<AttendanceRecordModel> createAttendanceRecord(Map<String, dynamic> recordData);
  Future<AttendanceRecordModel> updateAttendanceRecord(String recordId, Map<String, dynamic> recordData);
  Future<AttendanceRecordModel?> getAttendanceRecord({
    required String classId,
    required String termId,
    required String date,
    required String type,
  });
  Future<List<AttendanceRecordModel>> getAttendanceRecords({
    required String schoolId,
    required String termId,
    String? classId,
    String? startDate,
    String? endDate,
    int page = 1,
    int perPage = 20,
  });
  Future<void> markAttendance(String recordId, List<Map<String, dynamic>> entries);
  Future<Map<String, dynamic>> getAttendanceSummary(String classId, String termId);

  // ─── Homework ─────────────────────────────────────────────────────────

  Future<HomeworkModel> createHomework(Map<String, dynamic> homeworkData);
  Future<HomeworkModel> updateHomework(String homeworkId, Map<String, dynamic> homeworkData);
  Future<void> deleteHomework(String homeworkId);
  Future<HomeworkModel> getHomework(String homeworkId);
  Future<List<HomeworkModel>> getHomeworkList({
    required String schoolId,
    String? classId,
    String? subjectId,
    String? teacherId,
    String? status,
    int page = 1,
    int perPage = 20,
  });
  Future<HomeworkModel> publishHomework(String homeworkId);
  Future<HomeworkSubmissionModel> submitHomework(Map<String, dynamic> submissionData);
  Future<HomeworkSubmissionModel> gradeSubmission(Map<String, dynamic> gradeData);
  Future<List<HomeworkSubmissionModel>> getHomeworkSubmissions(String homeworkId);

  // ─── Announcements ────────────────────────────────────────────────────

  Future<AnnouncementModel> createAnnouncement(Map<String, dynamic> announcementData);
  Future<AnnouncementModel> updateAnnouncement(String announcementId, Map<String, dynamic> announcementData);
  Future<void> deleteAnnouncement(String announcementId);
  Future<List<AnnouncementModel>> getAnnouncements({
    required String schoolId,
    String? type,
    bool? isPublished,
    int page = 1,
    int perPage = 20,
  });
  Future<AnnouncementModel> publishAnnouncement(String announcementId);

  // ─── Documents ────────────────────────────────────────────────────────

  Future<DocumentModel> createDocument(Map<String, dynamic> documentData);
  Future<DocumentModel> updateDocument(String documentId, Map<String, dynamic> documentData);
  Future<void> deleteDocument(String documentId);
  Future<List<DocumentModel>> getDocuments({
    required String schoolId,
    String? documentType,
    String? category,
    String? searchQuery,
    bool? isPublic,
    int page = 1,
    int perPage = 20,
  });
  Future<void> incrementDownloadCount(String documentId);

  // ─── Classes ──────────────────────────────────────────────────────────

  Future<ClassModel> getClass(String classId);
  Future<List<ClassModel>> getClasses({
    required String schoolId,
    String? academicYear,
    bool? isActive,
    int page = 1,
    int perPage = 20,
  });
  Future<ClassModel> createClass(Map<String, dynamic> classData);
  Future<ClassModel> updateClass(String classId, Map<String, dynamic> classData);
  Future<void> assignStudentsToClass(String classId, List<String> studentIds);
  Future<void> removeStudentFromClass(String classId, String studentId);

  // ─── Subjects ─────────────────────────────────────────────────────────

  Future<SubjectModel> getSubject(String subjectId);
  Future<List<SubjectModel>> getSubjects({
    required String schoolId,
    String? category,
    bool? isActive,
  });
  Future<SubjectModel> createSubject(Map<String, dynamic> subjectData);
  Future<SubjectModel> updateSubject(String subjectId, Map<String, dynamic> subjectData);
  Future<void> assignTeacherToSubject(Map<String, dynamic> data);

  // ─── Reports ──────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> getSchoolOverview(String schoolId);
  Future<List<StudentProfileModel>> getStudentListReport(String schoolId, String? classId);
  Future<List<TeacherProfileModel>> getTeacherListReport(String schoolId);
  Future<Map<String, dynamic>> getAttendanceReport({
    required String schoolId,
    required String termId,
    String? classId,
    String? startDate,
    String? endDate,
  });
}

// ═══════════════════════════════════════════════════════════════════════
// SUPABASE IMPLEMENTATION
// ═══════════════════════════════════════════════════════════════════════

class SchoolManagementRemoteDataSourceImpl
    implements SchoolManagementRemoteDataSource {
  SchoolManagementRemoteDataSourceImpl({
    required sb.SupabaseClient supabaseClient,
  }) : _supabaseClient = supabaseClient;

  final sb.SupabaseClient _supabaseClient;

  // ─── Table name constants ─────────────────────────────────────────────

  static const _schoolsTable = 'schools';
  static const _schoolBranchesTable = 'school_branches';
  static const _departmentsTable = 'departments';
  static const _studentProfilesTable = 'student_profiles';
  static const _teacherProfilesTable = 'teacher_profiles';
  static const _parentProfilesTable = 'parent_profiles';
  static const _parentStudentsTable = 'parent_students';
  static const _academicSessionsTable = 'academic_sessions';
  static const _termsTable = 'terms';
  static const _calendarEventsTable = 'school_calendar_events';
  static const _timetablesTable = 'timetables';
  static const _timetableSlotsTable = 'timetable_slots';
  static const _attendanceRecordsTable = 'attendance_records';
  static const _attendanceEntriesTable = 'attendance_entries';
  static const _homeworkTable = 'homework';
  static const _homeworkSubmissionsTable = 'homework_submissions';
  static const _announcementsTable = 'announcements';
  static const _documentsTable = 'documents';
  static const _promotionHistoryTable = 'promotion_history';
  static const _classesTable = 'classes';
  static const _subjectsTable = 'subjects';
  static const _classSubjectsTable = 'class_subjects';
  static const _classStudentsTable = 'class_students';

  // ═══════════════════════════════════════════════════════════════════
  // School CRUD
  // ═══════════════════════════════════════════════════════════════════

  @override
  Future<SchoolModel> createSchool(Map<String, dynamic> schoolData) async {
    try {
      final response = await _supabaseClient
          .from(_schoolsTable)
          .insert(schoolData)
          .select()
          .single();

      return SchoolModel.fromJson(response);
    } on sb.PostgrestException catch (e) {
      AppLogger.error('Create school failed', error: e);
      throw ServerException(
        message: e.message,
        statusCode: int.tryParse(e.code ?? '') ?? 500,
        data: e.details,
      );
    } catch (e) {
      AppLogger.error('Create school unexpected error', error: e);
      throw ServerException(
        message: 'Failed to create school: $e',
        statusCode: 500,
      );
    }
  }

  @override
  Future<SchoolModel> updateSchool(
    String schoolId,
    Map<String, dynamic> schoolData,
  ) async {
    try {
      final response = await _supabaseClient
          .from(_schoolsTable)
          .update(schoolData)
          .eq('id', schoolId)
          .select()
          .single();

      return SchoolModel.fromJson(response);
    } on sb.PostgrestException catch (e) {
      AppLogger.error('Update school failed', error: e);
      if (e.code == 'PGRST116') {
        throw NotFoundException('School not found: $schoolId');
      }
      throw ServerException(
        message: e.message,
        statusCode: int.tryParse(e.code ?? '') ?? 500,
        data: e.details,
      );
    } catch (e) {
      AppLogger.error('Update school unexpected error', error: e);
      throw ServerException(
        message: 'Failed to update school: $e',
        statusCode: 500,
      );
    }
  }

  @override
  Future<void> deleteSchool(String schoolId) async {
    try {
      await _supabaseClient
          .from(_schoolsTable)
          .delete()
          .eq('id', schoolId);
    } on sb.PostgrestException catch (e) {
      AppLogger.error('Delete school failed', error: e);
      throw ServerException(
        message: e.message,
        statusCode: int.tryParse(e.code ?? '') ?? 500,
        data: e.details,
      );
    } catch (e) {
      AppLogger.error('Delete school unexpected error', error: e);
      throw ServerException(
        message: 'Failed to delete school: $e',
        statusCode: 500,
      );
    }
  }

  @override
  Future<SchoolModel> getSchool(String schoolId) async {
    try {
      final response = await _supabaseClient
          .from(_schoolsTable)
          .select()
          .eq('id', schoolId)
          .single();

      return SchoolModel.fromJson(response);
    } on sb.PostgrestException catch (e) {
      AppLogger.error('Get school failed', error: e);
      if (e.code == 'PGRST116') {
        throw NotFoundException('School not found: $schoolId');
      }
      throw ServerException(
        message: e.message,
        statusCode: int.tryParse(e.code ?? '') ?? 500,
        data: e.details,
      );
    } catch (e) {
      AppLogger.error('Get school unexpected error', error: e);
      throw ServerException(
        message: 'Failed to get school: $e',
        statusCode: 500,
      );
    }
  }

  @override
  Future<List<SchoolModel>> getSchools(Map<String, dynamic> filters) async {
    try {
      var query = _supabaseClient.from(_schoolsTable).select();

      if (filters['is_active'] != null) {
        query = query.eq('is_active', filters['is_active'] as bool);
      }
      if (filters['search'] != null) {
        final search = filters['search'] as String;
        query = query.or('name.ilike.%$search%,code.ilike.%$search%');
      }
      if (filters['school_level'] != null) {
        query = query.eq('school_level', filters['school_level'] as String);
      }
      if (filters['subscription_status'] != null) {
        query = query.eq(
          'subscription_status',
          filters['subscription_status'] as String,
        );
      }

      final page = filters['page'] as int? ?? 1;
      final perPage = filters['per_page'] as int? ?? filters['perPage'] as int? ?? 20;
      final offset = (page - 1) * perPage;

      query = query.range(offset, offset + perPage - 1);
      query = query.order('created_at', ascending: false);

      final response = await query;

      return response
          .map<SchoolModel>((json) => SchoolModel.fromJson(json))
          .toList();
    } on sb.PostgrestException catch (e) {
      AppLogger.error('Get schools failed', error: e);
      throw ServerException(
        message: e.message,
        statusCode: int.tryParse(e.code ?? '') ?? 500,
        data: e.details,
      );
    } catch (e) {
      AppLogger.error('Get schools unexpected error', error: e);
      throw ServerException(
        message: 'Failed to get schools: $e',
        statusCode: 500,
      );
    }
  }

  // ═══════════════════════════════════════════════════════════════════
  // Branches
  // ═══════════════════════════════════════════════════════════════════

  @override
  Future<SchoolBranchModel> createBranch(Map<String, dynamic> branchData) async {
    try {
      final response = await _supabaseClient
          .from(_schoolBranchesTable)
          .insert(branchData)
          .select()
          .single();

      return SchoolBranchModel.fromJson(response);
    } on sb.PostgrestException catch (e) {
      AppLogger.error('Create branch failed', error: e);
      throw ServerException(
        message: e.message,
        statusCode: int.tryParse(e.code ?? '') ?? 500,
        data: e.details,
      );
    } catch (e) {
      AppLogger.error('Create branch unexpected error', error: e);
      throw ServerException(
        message: 'Failed to create branch: $e',
        statusCode: 500,
      );
    }
  }

  @override
  Future<SchoolBranchModel> updateBranch(
    String branchId,
    Map<String, dynamic> branchData,
  ) async {
    try {
      final response = await _supabaseClient
          .from(_schoolBranchesTable)
          .update(branchData)
          .eq('id', branchId)
          .select()
          .single();

      return SchoolBranchModel.fromJson(response);
    } on sb.PostgrestException catch (e) {
      AppLogger.error('Update branch failed', error: e);
      if (e.code == 'PGRST116') {
        throw NotFoundException('Branch not found: $branchId');
      }
      throw ServerException(
        message: e.message,
        statusCode: int.tryParse(e.code ?? '') ?? 500,
        data: e.details,
      );
    } catch (e) {
      AppLogger.error('Update branch unexpected error', error: e);
      throw ServerException(
        message: 'Failed to update branch: $e',
        statusCode: 500,
      );
    }
  }

  @override
  Future<void> deleteBranch(String branchId) async {
    try {
      await _supabaseClient
          .from(_schoolBranchesTable)
          .delete()
          .eq('id', branchId);
    } on sb.PostgrestException catch (e) {
      AppLogger.error('Delete branch failed', error: e);
      throw ServerException(
        message: e.message,
        statusCode: int.tryParse(e.code ?? '') ?? 500,
        data: e.details,
      );
    } catch (e) {
      AppLogger.error('Delete branch unexpected error', error: e);
      throw ServerException(
        message: 'Failed to delete branch: $e',
        statusCode: 500,
      );
    }
  }

  @override
  Future<List<SchoolBranchModel>> getBranches(String schoolId) async {
    try {
      final response = await _supabaseClient
          .from(_schoolBranchesTable)
          .select()
          .eq('school_id', schoolId)
          .order('created_at', ascending: false);

      return response
          .map<SchoolBranchModel>((json) => SchoolBranchModel.fromJson(json))
          .toList();
    } on sb.PostgrestException catch (e) {
      AppLogger.error('Get branches failed', error: e);
      throw ServerException(
        message: e.message,
        statusCode: int.tryParse(e.code ?? '') ?? 500,
        data: e.details,
      );
    } catch (e) {
      AppLogger.error('Get branches unexpected error', error: e);
      throw ServerException(
        message: 'Failed to get branches: $e',
        statusCode: 500,
      );
    }
  }

  // ═══════════════════════════════════════════════════════════════════
  // Departments
  // ═══════════════════════════════════════════════════════════════════

  @override
  Future<DepartmentModel> createDepartment(Map<String, dynamic> departmentData) async {
    try {
      final response = await _supabaseClient
          .from(_departmentsTable)
          .insert(departmentData)
          .select()
          .single();

      return DepartmentModel.fromJson(response);
    } on sb.PostgrestException catch (e) {
      AppLogger.error('Create department failed', error: e);
      throw ServerException(
        message: e.message,
        statusCode: int.tryParse(e.code ?? '') ?? 500,
        data: e.details,
      );
    } catch (e) {
      AppLogger.error('Create department unexpected error', error: e);
      throw ServerException(
        message: 'Failed to create department: $e',
        statusCode: 500,
      );
    }
  }

  @override
  Future<DepartmentModel> updateDepartment(
    String departmentId,
    Map<String, dynamic> departmentData,
  ) async {
    try {
      final response = await _supabaseClient
          .from(_departmentsTable)
          .update(departmentData)
          .eq('id', departmentId)
          .select()
          .single();

      return DepartmentModel.fromJson(response);
    } on sb.PostgrestException catch (e) {
      AppLogger.error('Update department failed', error: e);
      if (e.code == 'PGRST116') {
        throw NotFoundException('Department not found: $departmentId');
      }
      throw ServerException(
        message: e.message,
        statusCode: int.tryParse(e.code ?? '') ?? 500,
        data: e.details,
      );
    } catch (e) {
      AppLogger.error('Update department unexpected error', error: e);
      throw ServerException(
        message: 'Failed to update department: $e',
        statusCode: 500,
      );
    }
  }

  @override
  Future<void> deleteDepartment(String departmentId) async {
    try {
      await _supabaseClient
          .from(_departmentsTable)
          .delete()
          .eq('id', departmentId);
    } on sb.PostgrestException catch (e) {
      AppLogger.error('Delete department failed', error: e);
      throw ServerException(
        message: e.message,
        statusCode: int.tryParse(e.code ?? '') ?? 500,
        data: e.details,
      );
    } catch (e) {
      AppLogger.error('Delete department unexpected error', error: e);
      throw ServerException(
        message: 'Failed to delete department: $e',
        statusCode: 500,
      );
    }
  }

  @override
  Future<List<DepartmentModel>> getDepartments(String schoolId) async {
    try {
      final response = await _supabaseClient
          .from(_departmentsTable)
          .select()
          .eq('school_id', schoolId)
          .order('name', ascending: true);

      return response
          .map<DepartmentModel>((json) => DepartmentModel.fromJson(json))
          .toList();
    } on sb.PostgrestException catch (e) {
      AppLogger.error('Get departments failed', error: e);
      throw ServerException(
        message: e.message,
        statusCode: int.tryParse(e.code ?? '') ?? 500,
        data: e.details,
      );
    } catch (e) {
      AppLogger.error('Get departments unexpected error', error: e);
      throw ServerException(
        message: 'Failed to get departments: $e',
        statusCode: 500,
      );
    }
  }

  // ═══════════════════════════════════════════════════════════════════
  // Student Profiles
  // ═══════════════════════════════════════════════════════════════════

  @override
  Future<StudentProfileModel> createStudentProfile(
    Map<String, dynamic> profileData,
  ) async {
    try {
      final response = await _supabaseClient
          .from(_studentProfilesTable)
          .insert(profileData)
          .select()
          .single();

      return StudentProfileModel.fromJson(response);
    } on sb.PostgrestException catch (e) {
      AppLogger.error('Create student profile failed', error: e);
      throw ServerException(
        message: e.message,
        statusCode: int.tryParse(e.code ?? '') ?? 500,
        data: e.details,
      );
    } catch (e) {
      AppLogger.error('Create student profile unexpected error', error: e);
      throw ServerException(
        message: 'Failed to create student profile: $e',
        statusCode: 500,
      );
    }
  }

  @override
  Future<StudentProfileModel> updateStudentProfile(
    String profileId,
    Map<String, dynamic> profileData,
  ) async {
    try {
      final response = await _supabaseClient
          .from(_studentProfilesTable)
          .update(profileData)
          .eq('id', profileId)
          .select()
          .single();

      return StudentProfileModel.fromJson(response);
    } on sb.PostgrestException catch (e) {
      AppLogger.error('Update student profile failed', error: e);
      if (e.code == 'PGRST116') {
        throw NotFoundException('Student profile not found: $profileId');
      }
      throw ServerException(
        message: e.message,
        statusCode: int.tryParse(e.code ?? '') ?? 500,
        data: e.details,
      );
    } catch (e) {
      AppLogger.error('Update student profile unexpected error', error: e);
      throw ServerException(
        message: 'Failed to update student profile: $e',
        statusCode: 500,
      );
    }
  }

  @override
  Future<StudentProfileModel> getStudentProfile(String userId) async {
    try {
      final response = await _supabaseClient
          .from(_studentProfilesTable)
          .select('*, users!student_profiles_user_id_fkey(full_name, email, phone, avatar_url)')
          .eq('user_id', userId)
          .single();

      return StudentProfileModel.fromJson(response);
    } on sb.PostgrestException catch (e) {
      AppLogger.error('Get student profile failed', error: e);
      if (e.code == 'PGRST116') {
        throw NotFoundException('Student profile not found for user: $userId');
      }
      throw ServerException(
        message: e.message,
        statusCode: int.tryParse(e.code ?? '') ?? 500,
        data: e.details,
      );
    } catch (e) {
      AppLogger.error('Get student profile unexpected error', error: e);
      throw ServerException(
        message: 'Failed to get student profile: $e',
        statusCode: 500,
      );
    }
  }

  @override
  Future<List<StudentProfileModel>> getStudentProfiles({
    required String schoolId,
    String? classId,
    bool? isActive,
    bool? isGraduated,
    String? searchQuery,
    int page = 1,
    int perPage = 20,
  }) async {
    try {
      var query = _supabaseClient
          .from(_studentProfilesTable)
          .select('*, users!student_profiles_user_id_fkey(full_name, email, phone, avatar_url)');

      query = query.eq('school_id', schoolId);

      if (classId != null) {
        query = query.eq('current_class_id', classId);
      }
      if (isActive != null) {
        query = query.eq('is_active', isActive);
      }
      if (isGraduated != null) {
        query = query.eq('is_graduated', isGraduated);
      }
      if (searchQuery != null && searchQuery.isNotEmpty) {
        query = query.or(
          'admission_number.ilike.%$searchQuery%,'
          'users.full_name.ilike.%$searchQuery%',
        );
      }

      final offset = (page - 1) * perPage;
      query = query.range(offset, offset + perPage - 1);
      query = query.order('created_at', ascending: false);

      final response = await query;

      return response
          .map<StudentProfileModel>((json) => StudentProfileModel.fromJson(json))
          .toList();
    } on sb.PostgrestException catch (e) {
      AppLogger.error('Get student profiles failed', error: e);
      throw ServerException(
        message: e.message,
        statusCode: int.tryParse(e.code ?? '') ?? 500,
        data: e.details,
      );
    } catch (e) {
      AppLogger.error('Get student profiles unexpected error', error: e);
      throw ServerException(
        message: 'Failed to get student profiles: $e',
        statusCode: 500,
      );
    }
  }

  @override
  Future<PromotionHistoryModel> promoteStudent(Map<String, dynamic> data) async {
    try {
      // Update student profile with new class
      final studentId = data['student_id'] as String;
      final toClassId = data['to_class_id'] as String?;

      if (toClassId != null) {
        await _supabaseClient
            .from(_studentProfilesTable)
            .update({
              'current_class_id': toClassId,
              'promoted_to_class_id': toClassId,
            })
            .eq('user_id', studentId);
      }

      // Insert promotion history record
      final response = await _supabaseClient
          .from(_promotionHistoryTable)
          .insert(data)
          .select()
          .single();

      return PromotionHistoryModel.fromJson(response);
    } on sb.PostgrestException catch (e) {
      AppLogger.error('Promote student failed', error: e);
      throw ServerException(
        message: e.message,
        statusCode: int.tryParse(e.code ?? '') ?? 500,
        data: e.details,
      );
    } catch (e) {
      AppLogger.error('Promote student unexpected error', error: e);
      throw ServerException(
        message: 'Failed to promote student: $e',
        statusCode: 500,
      );
    }
  }

  @override
  Future<StudentProfileModel> graduateStudent(
    String studentId,
    String schoolId,
  ) async {
    try {
      final response = await _supabaseClient
          .from(_studentProfilesTable)
          .update({
            'is_graduated': true,
            'graduation_date': DateTime.now().toIso8601String(),
            'is_alumni': true,
            'is_active': false,
          })
          .eq('user_id', studentId)
          .eq('school_id', schoolId)
          .select()
          .single();

      return StudentProfileModel.fromJson(response);
    } on sb.PostgrestException catch (e) {
      AppLogger.error('Graduate student failed', error: e);
      if (e.code == 'PGRST116') {
        throw NotFoundException('Student profile not found: $studentId');
      }
      throw ServerException(
        message: e.message,
        statusCode: int.tryParse(e.code ?? '') ?? 500,
        data: e.details,
      );
    } catch (e) {
      AppLogger.error('Graduate student unexpected error', error: e);
      throw ServerException(
        message: 'Failed to graduate student: $e',
        statusCode: 500,
      );
    }
  }

  @override
  Future<List<PromotionHistoryModel>> getPromotionHistory(
    String studentId,
  ) async {
    try {
      final response = await _supabaseClient
          .from(_promotionHistoryTable)
          .select()
          .eq('student_id', studentId)
          .order('promoted_at', ascending: false);

      return response
          .map<PromotionHistoryModel>(
            (json) => PromotionHistoryModel.fromJson(json),
          )
          .toList();
    } on sb.PostgrestException catch (e) {
      AppLogger.error('Get promotion history failed', error: e);
      throw ServerException(
        message: e.message,
        statusCode: int.tryParse(e.code ?? '') ?? 500,
        data: e.details,
      );
    } catch (e) {
      AppLogger.error('Get promotion history unexpected error', error: e);
      throw ServerException(
        message: 'Failed to get promotion history: $e',
        statusCode: 500,
      );
    }
  }

  // ═══════════════════════════════════════════════════════════════════
  // Teacher Profiles
  // ═══════════════════════════════════════════════════════════════════

  @override
  Future<TeacherProfileModel> createTeacherProfile(
    Map<String, dynamic> profileData,
  ) async {
    try {
      final response = await _supabaseClient
          .from(_teacherProfilesTable)
          .insert(profileData)
          .select()
          .single();

      return TeacherProfileModel.fromJson(response);
    } on sb.PostgrestException catch (e) {
      AppLogger.error('Create teacher profile failed', error: e);
      throw ServerException(
        message: e.message,
        statusCode: int.tryParse(e.code ?? '') ?? 500,
        data: e.details,
      );
    } catch (e) {
      AppLogger.error('Create teacher profile unexpected error', error: e);
      throw ServerException(
        message: 'Failed to create teacher profile: $e',
        statusCode: 500,
      );
    }
  }

  @override
  Future<TeacherProfileModel> updateTeacherProfile(
    String profileId,
    Map<String, dynamic> profileData,
  ) async {
    try {
      final response = await _supabaseClient
          .from(_teacherProfilesTable)
          .update(profileData)
          .eq('id', profileId)
          .select()
          .single();

      return TeacherProfileModel.fromJson(response);
    } on sb.PostgrestException catch (e) {
      AppLogger.error('Update teacher profile failed', error: e);
      if (e.code == 'PGRST116') {
        throw NotFoundException('Teacher profile not found: $profileId');
      }
      throw ServerException(
        message: e.message,
        statusCode: int.tryParse(e.code ?? '') ?? 500,
        data: e.details,
      );
    } catch (e) {
      AppLogger.error('Update teacher profile unexpected error', error: e);
      throw ServerException(
        message: 'Failed to update teacher profile: $e',
        statusCode: 500,
      );
    }
  }

  @override
  Future<TeacherProfileModel> getTeacherProfile(String userId) async {
    try {
      final response = await _supabaseClient
          .from(_teacherProfilesTable)
          .select('*, users!teacher_profiles_user_id_fkey(full_name, email, phone, avatar_url)')
          .eq('user_id', userId)
          .single();

      return TeacherProfileModel.fromJson(response);
    } on sb.PostgrestException catch (e) {
      AppLogger.error('Get teacher profile failed', error: e);
      if (e.code == 'PGRST116') {
        throw NotFoundException('Teacher profile not found for user: $userId');
      }
      throw ServerException(
        message: e.message,
        statusCode: int.tryParse(e.code ?? '') ?? 500,
        data: e.details,
      );
    } catch (e) {
      AppLogger.error('Get teacher profile unexpected error', error: e);
      throw ServerException(
        message: 'Failed to get teacher profile: $e',
        statusCode: 500,
      );
    }
  }

  @override
  Future<List<TeacherProfileModel>> getTeacherProfiles({
    required String schoolId,
    String? departmentId,
    bool? isActive,
    String? searchQuery,
    int page = 1,
    int perPage = 20,
  }) async {
    try {
      var query = _supabaseClient
          .from(_teacherProfilesTable)
          .select('*, users!teacher_profiles_user_id_fkey(full_name, email, phone, avatar_url)');

      query = query.eq('school_id', schoolId);

      if (departmentId != null) {
        query = query.eq('department_id', departmentId);
      }
      if (isActive != null) {
        query = query.eq('is_active', isActive);
      }
      if (searchQuery != null && searchQuery.isNotEmpty) {
        query = query.or(
          'employee_id.ilike.%$searchQuery%,'
          'users.full_name.ilike.%$searchQuery%',
        );
      }

      final offset = (page - 1) * perPage;
      query = query.range(offset, offset + perPage - 1);
      query = query.order('created_at', ascending: false);

      final response = await query;

      return response
          .map<TeacherProfileModel>((json) => TeacherProfileModel.fromJson(json))
          .toList();
    } on sb.PostgrestException catch (e) {
      AppLogger.error('Get teacher profiles failed', error: e);
      throw ServerException(
        message: e.message,
        statusCode: int.tryParse(e.code ?? '') ?? 500,
        data: e.details,
      );
    } catch (e) {
      AppLogger.error('Get teacher profiles unexpected error', error: e);
      throw ServerException(
        message: 'Failed to get teacher profiles: $e',
        statusCode: 500,
      );
    }
  }

  // ═══════════════════════════════════════════════════════════════════
  // Parent Profiles
  // ═══════════════════════════════════════════════════════════════════

  @override
  Future<ParentProfileModel> createParentProfile(
    Map<String, dynamic> profileData,
  ) async {
    try {
      final response = await _supabaseClient
          .from(_parentProfilesTable)
          .insert(profileData)
          .select()
          .single();

      return ParentProfileModel.fromJson(response);
    } on sb.PostgrestException catch (e) {
      AppLogger.error('Create parent profile failed', error: e);
      throw ServerException(
        message: e.message,
        statusCode: int.tryParse(e.code ?? '') ?? 500,
        data: e.details,
      );
    } catch (e) {
      AppLogger.error('Create parent profile unexpected error', error: e);
      throw ServerException(
        message: 'Failed to create parent profile: $e',
        statusCode: 500,
      );
    }
  }

  @override
  Future<ParentProfileModel> updateParentProfile(
    String profileId,
    Map<String, dynamic> profileData,
  ) async {
    try {
      final response = await _supabaseClient
          .from(_parentProfilesTable)
          .update(profileData)
          .eq('id', profileId)
          .select()
          .single();

      return ParentProfileModel.fromJson(response);
    } on sb.PostgrestException catch (e) {
      AppLogger.error('Update parent profile failed', error: e);
      if (e.code == 'PGRST116') {
        throw NotFoundException('Parent profile not found: $profileId');
      }
      throw ServerException(
        message: e.message,
        statusCode: int.tryParse(e.code ?? '') ?? 500,
        data: e.details,
      );
    } catch (e) {
      AppLogger.error('Update parent profile unexpected error', error: e);
      throw ServerException(
        message: 'Failed to update parent profile: $e',
        statusCode: 500,
      );
    }
  }

  @override
  Future<ParentProfileModel> getParentProfile(String userId) async {
    try {
      final response = await _supabaseClient
          .from(_parentProfilesTable)
          .select('*, users!parent_profiles_user_id_fkey(full_name, email, phone, avatar_url)')
          .eq('user_id', userId)
          .single();

      return ParentProfileModel.fromJson(response);
    } on sb.PostgrestException catch (e) {
      AppLogger.error('Get parent profile failed', error: e);
      if (e.code == 'PGRST116') {
        throw NotFoundException('Parent profile not found for user: $userId');
      }
      throw ServerException(
        message: e.message,
        statusCode: int.tryParse(e.code ?? '') ?? 500,
        data: e.details,
      );
    } catch (e) {
      AppLogger.error('Get parent profile unexpected error', error: e);
      throw ServerException(
        message: 'Failed to get parent profile: $e',
        statusCode: 500,
      );
    }
  }

  @override
  Future<List<ParentProfileModel>> getParentProfiles({
    required String schoolId,
    String? searchQuery,
    int page = 1,
    int perPage = 20,
  }) async {
    try {
      var query = _supabaseClient
          .from(_parentProfilesTable)
          .select('*, users!parent_profiles_user_id_fkey(full_name, email, phone, avatar_url)');

      query = query.eq('school_id', schoolId);

      if (searchQuery != null && searchQuery.isNotEmpty) {
        query = query.or(
          'users.full_name.ilike.%$searchQuery%,'
          'occupation.ilike.%$searchQuery%',
        );
      }

      final offset = (page - 1) * perPage;
      query = query.range(offset, offset + perPage - 1);
      query = query.order('created_at', ascending: false);

      final response = await query;

      return response
          .map<ParentProfileModel>((json) => ParentProfileModel.fromJson(json))
          .toList();
    } on sb.PostgrestException catch (e) {
      AppLogger.error('Get parent profiles failed', error: e);
      throw ServerException(
        message: e.message,
        statusCode: int.tryParse(e.code ?? '') ?? 500,
        data: e.details,
      );
    } catch (e) {
      AppLogger.error('Get parent profiles unexpected error', error: e);
      throw ServerException(
        message: 'Failed to get parent profiles: $e',
        statusCode: 500,
      );
    }
  }

  @override
  Future<ParentStudentLinkModel> linkParentToStudent(
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await _supabaseClient
          .from(_parentStudentsTable)
          .insert(data)
          .select()
          .single();

      return ParentStudentLinkModel.fromJson(response);
    } on sb.PostgrestException catch (e) {
      AppLogger.error('Link parent to student failed', error: e);
      throw ServerException(
        message: e.message,
        statusCode: int.tryParse(e.code ?? '') ?? 500,
        data: e.details,
      );
    } catch (e) {
      AppLogger.error('Link parent to student unexpected error', error: e);
      throw ServerException(
        message: 'Failed to link parent to student: $e',
        statusCode: 500,
      );
    }
  }

  @override
  Future<void> unlinkParentFromStudent(String linkId) async {
    try {
      await _supabaseClient
          .from(_parentStudentsTable)
          .delete()
          .eq('id', linkId);
    } on sb.PostgrestException catch (e) {
      AppLogger.error('Unlink parent from student failed', error: e);
      throw ServerException(
        message: e.message,
        statusCode: int.tryParse(e.code ?? '') ?? 500,
        data: e.details,
      );
    } catch (e) {
      AppLogger.error('Unlink parent from student unexpected error', error: e);
      throw ServerException(
        message: 'Failed to unlink parent from student: $e',
        statusCode: 500,
      );
    }
  }

  @override
  Future<List<ParentStudentLinkModel>> getParentStudentLinks(
    String studentId,
  ) async {
    try {
      // Look up the student profile first to get the profile ID
      final studentProfile = await _supabaseClient
          .from(_studentProfilesTable)
          .select('id')
          .eq('user_id', studentId)
          .single();

      final profileId = studentProfile['id'] as String;

      final response = await _supabaseClient
          .from(_parentStudentsTable)
          .select('*, parent_profiles(*, users!parent_profiles_user_id_fkey(full_name, email, phone, avatar_url))')
          .eq('student_id', profileId)
          .order('created_at', ascending: false);

      return response
          .map<ParentStudentLinkModel>(
            (json) => ParentStudentLinkModel.fromJson(json),
          )
          .toList();
    } on sb.PostgrestException catch (e) {
      AppLogger.error('Get parent-student links failed', error: e);
      throw ServerException(
        message: e.message,
        statusCode: int.tryParse(e.code ?? '') ?? 500,
        data: e.details,
      );
    } catch (e) {
      AppLogger.error('Get parent-student links unexpected error', error: e);
      throw ServerException(
        message: 'Failed to get parent-student links: $e',
        statusCode: 500,
      );
    }
  }

  // ═══════════════════════════════════════════════════════════════════
  // Academic Sessions
  // ═══════════════════════════════════════════════════════════════════

  @override
  Future<AcademicSessionModel> createSession(
    Map<String, dynamic> sessionData,
  ) async {
    try {
      final response = await _supabaseClient
          .from(_academicSessionsTable)
          .insert(sessionData)
          .select()
          .single();

      return AcademicSessionModel.fromJson(response);
    } on sb.PostgrestException catch (e) {
      AppLogger.error('Create session failed', error: e);
      throw ServerException(
        message: e.message,
        statusCode: int.tryParse(e.code ?? '') ?? 500,
        data: e.details,
      );
    } catch (e) {
      AppLogger.error('Create session unexpected error', error: e);
      throw ServerException(
        message: 'Failed to create session: $e',
        statusCode: 500,
      );
    }
  }

  @override
  Future<AcademicSessionModel> updateSession(
    String sessionId,
    Map<String, dynamic> sessionData,
  ) async {
    try {
      final response = await _supabaseClient
          .from(_academicSessionsTable)
          .update(sessionData)
          .eq('id', sessionId)
          .select()
          .single();

      return AcademicSessionModel.fromJson(response);
    } on sb.PostgrestException catch (e) {
      AppLogger.error('Update session failed', error: e);
      if (e.code == 'PGRST116') {
        throw NotFoundException('Session not found: $sessionId');
      }
      throw ServerException(
        message: e.message,
        statusCode: int.tryParse(e.code ?? '') ?? 500,
        data: e.details,
      );
    } catch (e) {
      AppLogger.error('Update session unexpected error', error: e);
      throw ServerException(
        message: 'Failed to update session: $e',
        statusCode: 500,
      );
    }
  }

  @override
  Future<void> deleteSession(String sessionId) async {
    try {
      await _supabaseClient
          .from(_academicSessionsTable)
          .delete()
          .eq('id', sessionId);
    } on sb.PostgrestException catch (e) {
      AppLogger.error('Delete session failed', error: e);
      throw ServerException(
        message: e.message,
        statusCode: int.tryParse(e.code ?? '') ?? 500,
        data: e.details,
      );
    } catch (e) {
      AppLogger.error('Delete session unexpected error', error: e);
      throw ServerException(
        message: 'Failed to delete session: $e',
        statusCode: 500,
      );
    }
  }

  @override
  Future<AcademicSessionModel> getSession(String sessionId) async {
    try {
      final response = await _supabaseClient
          .from(_academicSessionsTable)
          .select()
          .eq('id', sessionId)
          .single();

      return AcademicSessionModel.fromJson(response);
    } on sb.PostgrestException catch (e) {
      AppLogger.error('Get session failed', error: e);
      if (e.code == 'PGRST116') {
        throw NotFoundException('Session not found: $sessionId');
      }
      throw ServerException(
        message: e.message,
        statusCode: int.tryParse(e.code ?? '') ?? 500,
        data: e.details,
      );
    } catch (e) {
      AppLogger.error('Get session unexpected error', error: e);
      throw ServerException(
        message: 'Failed to get session: $e',
        statusCode: 500,
      );
    }
  }

  @override
  Future<List<AcademicSessionModel>> getSessions(String schoolId) async {
    try {
      final response = await _supabaseClient
          .from(_academicSessionsTable)
          .select()
          .eq('school_id', schoolId)
          .order('start_date', ascending: false);

      return response
          .map<AcademicSessionModel>(
            (json) => AcademicSessionModel.fromJson(json),
          )
          .toList();
    } on sb.PostgrestException catch (e) {
      AppLogger.error('Get sessions failed', error: e);
      throw ServerException(
        message: e.message,
        statusCode: int.tryParse(e.code ?? '') ?? 500,
        data: e.details,
      );
    } catch (e) {
      AppLogger.error('Get sessions unexpected error', error: e);
      throw ServerException(
        message: 'Failed to get sessions: $e',
        statusCode: 500,
      );
    }
  }

  @override
  Future<AcademicSessionModel> getCurrentSession(String schoolId) async {
    try {
      final response = await _supabaseClient
          .from(_academicSessionsTable)
          .select()
          .eq('school_id', schoolId)
          .eq('is_current', true)
          .single();

      return AcademicSessionModel.fromJson(response);
    } on sb.PostgrestException catch (e) {
      AppLogger.error('Get current session failed', error: e);
      if (e.code == 'PGRST116') {
        throw NotFoundException('No current session found for school: $schoolId');
      }
      throw ServerException(
        message: e.message,
        statusCode: int.tryParse(e.code ?? '') ?? 500,
        data: e.details,
      );
    } catch (e) {
      AppLogger.error('Get current session unexpected error', error: e);
      throw ServerException(
        message: 'Failed to get current session: $e',
        statusCode: 500,
      );
    }
  }

  @override
  Future<AcademicSessionModel> setCurrentSession(String sessionId) async {
    try {
      final response = await _supabaseClient
          .from(_academicSessionsTable)
          .update({'is_current': true})
          .eq('id', sessionId)
          .select()
          .single();

      return AcademicSessionModel.fromJson(response);
    } on sb.PostgrestException catch (e) {
      AppLogger.error('Set current session failed', error: e);
      throw ServerException(
        message: e.message,
        statusCode: int.tryParse(e.code ?? '') ?? 500,
        data: e.details,
      );
    } catch (e) {
      AppLogger.error('Set current session unexpected error', error: e);
      throw ServerException(
        message: 'Failed to set current session: $e',
        statusCode: 500,
      );
    }
  }

  // ═══════════════════════════════════════════════════════════════════
  // Terms
  // ═══════════════════════════════════════════════════════════════════

  @override
  Future<TermModel> createTerm(Map<String, dynamic> termData) async {
    try {
      final response = await _supabaseClient
          .from(_termsTable)
          .insert(termData)
          .select()
          .single();

      return TermModel.fromJson(response);
    } on sb.PostgrestException catch (e) {
      AppLogger.error('Create term failed', error: e);
      throw ServerException(
        message: e.message,
        statusCode: int.tryParse(e.code ?? '') ?? 500,
        data: e.details,
      );
    } catch (e) {
      AppLogger.error('Create term unexpected error', error: e);
      throw ServerException(
        message: 'Failed to create term: $e',
        statusCode: 500,
      );
    }
  }

  @override
  Future<TermModel> updateTerm(
    String termId,
    Map<String, dynamic> termData,
  ) async {
    try {
      final response = await _supabaseClient
          .from(_termsTable)
          .update(termData)
          .eq('id', termId)
          .select()
          .single();

      return TermModel.fromJson(response);
    } on sb.PostgrestException catch (e) {
      AppLogger.error('Update term failed', error: e);
      if (e.code == 'PGRST116') {
        throw NotFoundException('Term not found: $termId');
      }
      throw ServerException(
        message: e.message,
        statusCode: int.tryParse(e.code ?? '') ?? 500,
        data: e.details,
      );
    } catch (e) {
      AppLogger.error('Update term unexpected error', error: e);
      throw ServerException(
        message: 'Failed to update term: $e',
        statusCode: 500,
      );
    }
  }

  @override
  Future<void> deleteTerm(String termId) async {
    try {
      await _supabaseClient
          .from(_termsTable)
          .delete()
          .eq('id', termId);
    } on sb.PostgrestException catch (e) {
      AppLogger.error('Delete term failed', error: e);
      throw ServerException(
        message: e.message,
        statusCode: int.tryParse(e.code ?? '') ?? 500,
        data: e.details,
      );
    } catch (e) {
      AppLogger.error('Delete term unexpected error', error: e);
      throw ServerException(
        message: 'Failed to delete term: $e',
        statusCode: 500,
      );
    }
  }

  @override
  Future<List<TermModel>> getTerms(String sessionId) async {
    try {
      final response = await _supabaseClient
          .from(_termsTable)
          .select()
          .eq('academic_session_id', sessionId)
          .order('term_number', ascending: true);

      return response
          .map<TermModel>((json) => TermModel.fromJson(json))
          .toList();
    } on sb.PostgrestException catch (e) {
      AppLogger.error('Get terms failed', error: e);
      throw ServerException(
        message: e.message,
        statusCode: int.tryParse(e.code ?? '') ?? 500,
        data: e.details,
      );
    } catch (e) {
      AppLogger.error('Get terms unexpected error', error: e);
      throw ServerException(
        message: 'Failed to get terms: $e',
        statusCode: 500,
      );
    }
  }

  @override
  Future<TermModel> getCurrentTerm(String schoolId) async {
    try {
      final response = await _supabaseClient
          .from(_termsTable)
          .select()
          .eq('school_id', schoolId)
          .eq('is_current', true)
          .single();

      return TermModel.fromJson(response);
    } on sb.PostgrestException catch (e) {
      AppLogger.error('Get current term failed', error: e);
      if (e.code == 'PGRST116') {
        throw NotFoundException('No current term found for school: $schoolId');
      }
      throw ServerException(
        message: e.message,
        statusCode: int.tryParse(e.code ?? '') ?? 500,
        data: e.details,
      );
    } catch (e) {
      AppLogger.error('Get current term unexpected error', error: e);
      throw ServerException(
        message: 'Failed to get current term: $e',
        statusCode: 500,
      );
    }
  }

  @override
  Future<TermModel> setCurrentTerm(String termId) async {
    try {
      final response = await _supabaseClient
          .from(_termsTable)
          .update({'is_current': true})
          .eq('id', termId)
          .select()
          .single();

      return TermModel.fromJson(response);
    } on sb.PostgrestException catch (e) {
      AppLogger.error('Set current term failed', error: e);
      throw ServerException(
        message: e.message,
        statusCode: int.tryParse(e.code ?? '') ?? 500,
        data: e.details,
      );
    } catch (e) {
      AppLogger.error('Set current term unexpected error', error: e);
      throw ServerException(
        message: 'Failed to set current term: $e',
        statusCode: 500,
      );
    }
  }

  // ═══════════════════════════════════════════════════════════════════
  // Calendar Events
  // ═══════════════════════════════════════════════════════════════════

  @override
  Future<CalendarEventModel> createCalendarEvent(
    Map<String, dynamic> eventData,
  ) async {
    try {
      final response = await _supabaseClient
          .from(_calendarEventsTable)
          .insert(eventData)
          .select()
          .single();

      return CalendarEventModel.fromJson(response);
    } on sb.PostgrestException catch (e) {
      AppLogger.error('Create calendar event failed', error: e);
      throw ServerException(
        message: e.message,
        statusCode: int.tryParse(e.code ?? '') ?? 500,
        data: e.details,
      );
    } catch (e) {
      AppLogger.error('Create calendar event unexpected error', error: e);
      throw ServerException(
        message: 'Failed to create calendar event: $e',
        statusCode: 500,
      );
    }
  }

  @override
  Future<CalendarEventModel> updateCalendarEvent(
    String eventId,
    Map<String, dynamic> eventData,
  ) async {
    try {
      final response = await _supabaseClient
          .from(_calendarEventsTable)
          .update(eventData)
          .eq('id', eventId)
          .select()
          .single();

      return CalendarEventModel.fromJson(response);
    } on sb.PostgrestException catch (e) {
      AppLogger.error('Update calendar event failed', error: e);
      if (e.code == 'PGRST116') {
        throw NotFoundException('Calendar event not found: $eventId');
      }
      throw ServerException(
        message: e.message,
        statusCode: int.tryParse(e.code ?? '') ?? 500,
        data: e.details,
      );
    } catch (e) {
      AppLogger.error('Update calendar event unexpected error', error: e);
      throw ServerException(
        message: 'Failed to update calendar event: $e',
        statusCode: 500,
      );
    }
  }

  @override
  Future<void> deleteCalendarEvent(String eventId) async {
    try {
      await _supabaseClient
          .from(_calendarEventsTable)
          .delete()
          .eq('id', eventId);
    } on sb.PostgrestException catch (e) {
      AppLogger.error('Delete calendar event failed', error: e);
      throw ServerException(
        message: e.message,
        statusCode: int.tryParse(e.code ?? '') ?? 500,
        data: e.details,
      );
    } catch (e) {
      AppLogger.error('Delete calendar event unexpected error', error: e);
      throw ServerException(
        message: 'Failed to delete calendar event: $e',
        statusCode: 500,
      );
    }
  }

  @override
  Future<List<CalendarEventModel>> getCalendarEvents({
    required String schoolId,
    String? termId,
    String? startDate,
    String? endDate,
    String? eventType,
  }) async {
    try {
      var query = _supabaseClient
          .from(_calendarEventsTable)
          .select()
          .eq('school_id', schoolId)
          .eq('is_active', true);

      if (termId != null) {
        query = query.eq('term_id', termId);
      }
      if (eventType != null) {
        query = query.eq('event_type', eventType);
      }
      if (startDate != null) {
        query = query.gte('start_date', startDate);
      }
      if (endDate != null) {
        query = query.lte('start_date', endDate);
      }

      query = query.order('start_date', ascending: true);

      final response = await query;

      return response
          .map<CalendarEventModel>((json) => CalendarEventModel.fromJson(json))
          .toList();
    } on sb.PostgrestException catch (e) {
      AppLogger.error('Get calendar events failed', error: e);
      throw ServerException(
        message: e.message,
        statusCode: int.tryParse(e.code ?? '') ?? 500,
        data: e.details,
      );
    } catch (e) {
      AppLogger.error('Get calendar events unexpected error', error: e);
      throw ServerException(
        message: 'Failed to get calendar events: $e',
        statusCode: 500,
      );
    }
  }

  // ═══════════════════════════════════════════════════════════════════
  // Timetables
  // ═══════════════════════════════════════════════════════════════════

  @override
  Future<TimetableModel> createTimetable(
    Map<String, dynamic> timetableData,
  ) async {
    try {
      final response = await _supabaseClient
          .from(_timetablesTable)
          .insert(timetableData)
          .select()
          .single();

      return TimetableModel.fromJson(response);
    } on sb.PostgrestException catch (e) {
      AppLogger.error('Create timetable failed', error: e);
      throw ServerException(
        message: e.message,
        statusCode: int.tryParse(e.code ?? '') ?? 500,
        data: e.details,
      );
    } catch (e) {
      AppLogger.error('Create timetable unexpected error', error: e);
      throw ServerException(
        message: 'Failed to create timetable: $e',
        statusCode: 500,
      );
    }
  }

  @override
  Future<TimetableModel> updateTimetable(
    String timetableId,
    Map<String, dynamic> timetableData,
  ) async {
    try {
      final response = await _supabaseClient
          .from(_timetablesTable)
          .update(timetableData)
          .eq('id', timetableId)
          .select()
          .single();

      return TimetableModel.fromJson(response);
    } on sb.PostgrestException catch (e) {
      AppLogger.error('Update timetable failed', error: e);
      if (e.code == 'PGRST116') {
        throw NotFoundException('Timetable not found: $timetableId');
      }
      throw ServerException(
        message: e.message,
        statusCode: int.tryParse(e.code ?? '') ?? 500,
        data: e.details,
      );
    } catch (e) {
      AppLogger.error('Update timetable unexpected error', error: e);
      throw ServerException(
        message: 'Failed to update timetable: $e',
        statusCode: 500,
      );
    }
  }

  @override
  Future<void> deleteTimetable(String timetableId) async {
    try {
      await _supabaseClient
          .from(_timetablesTable)
          .delete()
          .eq('id', timetableId);
    } on sb.PostgrestException catch (e) {
      AppLogger.error('Delete timetable failed', error: e);
      throw ServerException(
        message: e.message,
        statusCode: int.tryParse(e.code ?? '') ?? 500,
        data: e.details,
      );
    } catch (e) {
      AppLogger.error('Delete timetable unexpected error', error: e);
      throw ServerException(
        message: 'Failed to delete timetable: $e',
        statusCode: 500,
      );
    }
  }

  @override
  Future<TimetableModel> getTimetable(String timetableId) async {
    try {
      final response = await _supabaseClient
          .from(_timetablesTable)
          .select('*, timetable_slots(*)')
          .eq('id', timetableId)
          .single();

      return TimetableModel.fromJson(response);
    } on sb.PostgrestException catch (e) {
      AppLogger.error('Get timetable failed', error: e);
      if (e.code == 'PGRST116') {
        throw NotFoundException('Timetable not found: $timetableId');
      }
      throw ServerException(
        message: e.message,
        statusCode: int.tryParse(e.code ?? '') ?? 500,
        data: e.details,
      );
    } catch (e) {
      AppLogger.error('Get timetable unexpected error', error: e);
      throw ServerException(
        message: 'Failed to get timetable: $e',
        statusCode: 500,
      );
    }
  }

  @override
  Future<List<TimetableModel>> getTimetables({
    required String schoolId,
    String? termId,
    String? classId,
  }) async {
    try {
      var query = _supabaseClient
          .from(_timetablesTable)
          .select()
          .eq('school_id', schoolId)
          .eq('is_active', true);

      if (termId != null) {
        query = query.eq('term_id', termId);
      }
      if (classId != null) {
        query = query.eq('class_id', classId);
      }

      query = query.order('created_at', ascending: false);

      final response = await query;

      return response
          .map<TimetableModel>((json) => TimetableModel.fromJson(json))
          .toList();
    } on sb.PostgrestException catch (e) {
      AppLogger.error('Get timetables failed', error: e);
      throw ServerException(
        message: e.message,
        statusCode: int.tryParse(e.code ?? '') ?? 500,
        data: e.details,
      );
    } catch (e) {
      AppLogger.error('Get timetables unexpected error', error: e);
      throw ServerException(
        message: 'Failed to get timetables: $e',
        statusCode: 500,
      );
    }
  }

  @override
  Future<TimetableSlotModel> addTimetableSlot(
    Map<String, dynamic> slotData,
  ) async {
    try {
      final response = await _supabaseClient
          .from(_timetableSlotsTable)
          .insert(slotData)
          .select()
          .single();

      return TimetableSlotModel.fromJson(response);
    } on sb.PostgrestException catch (e) {
      AppLogger.error('Add timetable slot failed', error: e);
      throw ServerException(
        message: e.message,
        statusCode: int.tryParse(e.code ?? '') ?? 500,
        data: e.details,
      );
    } catch (e) {
      AppLogger.error('Add timetable slot unexpected error', error: e);
      throw ServerException(
        message: 'Failed to add timetable slot: $e',
        statusCode: 500,
      );
    }
  }

  @override
  Future<TimetableSlotModel> updateTimetableSlot(
    String slotId,
    Map<String, dynamic> slotData,
  ) async {
    try {
      final response = await _supabaseClient
          .from(_timetableSlotsTable)
          .update(slotData)
          .eq('id', slotId)
          .select()
          .single();

      return TimetableSlotModel.fromJson(response);
    } on sb.PostgrestException catch (e) {
      AppLogger.error('Update timetable slot failed', error: e);
      if (e.code == 'PGRST116') {
        throw NotFoundException('Timetable slot not found: $slotId');
      }
      throw ServerException(
        message: e.message,
        statusCode: int.tryParse(e.code ?? '') ?? 500,
        data: e.details,
      );
    } catch (e) {
      AppLogger.error('Update timetable slot unexpected error', error: e);
      throw ServerException(
        message: 'Failed to update timetable slot: $e',
        statusCode: 500,
      );
    }
  }

  @override
  Future<void> deleteTimetableSlot(String slotId) async {
    try {
      await _supabaseClient
          .from(_timetableSlotsTable)
          .delete()
          .eq('id', slotId);
    } on sb.PostgrestException catch (e) {
      AppLogger.error('Delete timetable slot failed', error: e);
      throw ServerException(
        message: e.message,
        statusCode: int.tryParse(e.code ?? '') ?? 500,
        data: e.details,
      );
    } catch (e) {
      AppLogger.error('Delete timetable slot unexpected error', error: e);
      throw ServerException(
        message: 'Failed to delete timetable slot: $e',
        statusCode: 500,
      );
    }
  }

  @override
  Future<TimetableModel> publishTimetable(String timetableId) async {
    try {
      final response = await _supabaseClient
          .from(_timetablesTable)
          .update({
            'is_published': true,
          })
          .eq('id', timetableId)
          .select()
          .single();

      return TimetableModel.fromJson(response);
    } on sb.PostgrestException catch (e) {
      AppLogger.error('Publish timetable failed', error: e);
      throw ServerException(
        message: e.message,
        statusCode: int.tryParse(e.code ?? '') ?? 500,
        data: e.details,
      );
    } catch (e) {
      AppLogger.error('Publish timetable unexpected error', error: e);
      throw ServerException(
        message: 'Failed to publish timetable: $e',
        statusCode: 500,
      );
    }
  }

  @override
  Future<List<Map<String, dynamic>>> checkSlotConflicts({
    required String teacherId,
    required String classId,
    required String dayOfWeek,
    required int periodNumber,
    String? excludeSlotId,
  }) async {
    try {
      final conflicts = <Map<String, dynamic>>[];

      // Check teacher conflicts
      var teacherQuery = _supabaseClient
          .from(_timetableSlotsTable)
          .select('*, timetables!timetable_slots_timetable_id_fkey(id, name, is_active)')
          .eq('teacher_id', teacherId)
          .eq('day_of_week', dayOfWeek)
          .eq('period_number', periodNumber);

      if (excludeSlotId != null) {
        teacherQuery = teacherQuery.neq('id', excludeSlotId);
      }

      final teacherResponse = await teacherQuery;

      // Filter for active timetables only
      for (final slot in teacherResponse) {
        final timetable = slot['timetables'] as Map<String, dynamic>?;
        if (timetable?['is_active'] == true) {
          conflicts.add({
            'conflict_type': 'teacher',
            'slot_id': slot['id'],
            'timetable': timetable,
          });
        }
      }

      // Check class conflicts
      var classQuery = _supabaseClient
          .from(_timetableSlotsTable)
          .select('*, timetables!timetable_slots_timetable_id_fkey(id, name, is_active)')
          .eq('class_id', classId)
          .eq('day_of_week', dayOfWeek)
          .eq('period_number', periodNumber);

      if (excludeSlotId != null) {
        classQuery = classQuery.neq('id', excludeSlotId);
      }

      final classResponse = await classQuery;

      for (final slot in classResponse) {
        final timetable = slot['timetables'] as Map<String, dynamic>?;
        if (timetable?['is_active'] == true) {
          conflicts.add({
            'conflict_type': 'class',
            'slot_id': slot['id'],
            'timetable': timetable,
          });
        }
      }

      return conflicts;
    } on sb.PostgrestException catch (e) {
      AppLogger.error('Check slot conflicts failed', error: e);
      throw ServerException(
        message: e.message,
        statusCode: int.tryParse(e.code ?? '') ?? 500,
        data: e.details,
      );
    } catch (e) {
      AppLogger.error('Check slot conflicts unexpected error', error: e);
      throw ServerException(
        message: 'Failed to check slot conflicts: $e',
        statusCode: 500,
      );
    }
  }

  // ═══════════════════════════════════════════════════════════════════
  // Attendance
  // ═══════════════════════════════════════════════════════════════════

  @override
  Future<AttendanceRecordModel> createAttendanceRecord(
    Map<String, dynamic> recordData,
  ) async {
    try {
      final response = await _supabaseClient
          .from(_attendanceRecordsTable)
          .insert(recordData)
          .select()
          .single();

      return AttendanceRecordModel.fromJson(response);
    } on sb.PostgrestException catch (e) {
      AppLogger.error('Create attendance record failed', error: e);
      throw ServerException(
        message: e.message,
        statusCode: int.tryParse(e.code ?? '') ?? 500,
        data: e.details,
      );
    } catch (e) {
      AppLogger.error('Create attendance record unexpected error', error: e);
      throw ServerException(
        message: 'Failed to create attendance record: $e',
        statusCode: 500,
      );
    }
  }

  @override
  Future<AttendanceRecordModel> updateAttendanceRecord(
    String recordId,
    Map<String, dynamic> recordData,
  ) async {
    try {
      final response = await _supabaseClient
          .from(_attendanceRecordsTable)
          .update(recordData)
          .eq('id', recordId)
          .select()
          .single();

      return AttendanceRecordModel.fromJson(response);
    } on sb.PostgrestException catch (e) {
      AppLogger.error('Update attendance record failed', error: e);
      if (e.code == 'PGRST116') {
        throw NotFoundException('Attendance record not found: $recordId');
      }
      throw ServerException(
        message: e.message,
        statusCode: int.tryParse(e.code ?? '') ?? 500,
        data: e.details,
      );
    } catch (e) {
      AppLogger.error('Update attendance record unexpected error', error: e);
      throw ServerException(
        message: 'Failed to update attendance record: $e',
        statusCode: 500,
      );
    }
  }

  @override
  Future<AttendanceRecordModel?> getAttendanceRecord({
    required String classId,
    required String termId,
    required String date,
    required String type,
  }) async {
    try {
      final response = await _supabaseClient
          .from(_attendanceRecordsTable)
          .select('*, attendance_entries(*)')
          .eq('class_id', classId)
          .eq('term_id', termId)
          .eq('date', date)
          .eq('attendance_type', type)
          .maybeSingle();

      if (response == null) return null;

      return AttendanceRecordModel.fromJson(response);
    } on sb.PostgrestException catch (e) {
      AppLogger.error('Get attendance record failed', error: e);
      throw ServerException(
        message: e.message,
        statusCode: int.tryParse(e.code ?? '') ?? 500,
        data: e.details,
      );
    } catch (e) {
      AppLogger.error('Get attendance record unexpected error', error: e);
      throw ServerException(
        message: 'Failed to get attendance record: $e',
        statusCode: 500,
      );
    }
  }

  @override
  Future<List<AttendanceRecordModel>> getAttendanceRecords({
    required String schoolId,
    required String termId,
    String? classId,
    String? startDate,
    String? endDate,
    int page = 1,
    int perPage = 20,
  }) async {
    try {
      var query = _supabaseClient
          .from(_attendanceRecordsTable)
          .select('*, attendance_entries(*)')
          .eq('school_id', schoolId)
          .eq('term_id', termId);

      if (classId != null) {
        query = query.eq('class_id', classId);
      }
      if (startDate != null) {
        query = query.gte('date', startDate);
      }
      if (endDate != null) {
        query = query.lte('date', endDate);
      }

      final offset = (page - 1) * perPage;
      query = query.range(offset, offset + perPage - 1);
      query = query.order('date', ascending: false);

      final response = await query;

      return response
          .map<AttendanceRecordModel>(
            (json) => AttendanceRecordModel.fromJson(json),
          )
          .toList();
    } on sb.PostgrestException catch (e) {
      AppLogger.error('Get attendance records failed', error: e);
      throw ServerException(
        message: e.message,
        statusCode: int.tryParse(e.code ?? '') ?? 500,
        data: e.details,
      );
    } catch (e) {
      AppLogger.error('Get attendance records unexpected error', error: e);
      throw ServerException(
        message: 'Failed to get attendance records: $e',
        statusCode: 500,
      );
    }
  }

  @override
  Future<void> markAttendance(
    String recordId,
    List<Map<String, dynamic>> entries,
  ) async {
    try {
      // Upsert attendance entries for the given record
      for (final entry in entries) {
        entry['attendance_record_id'] = recordId;
      }

      await _supabaseClient
          .from(_attendanceEntriesTable)
          .upsert(
            entries,
            onConflict: 'attendance_record_id,user_id',
          );
    } on sb.PostgrestException catch (e) {
      AppLogger.error('Mark attendance failed', error: e);
      throw ServerException(
        message: e.message,
        statusCode: int.tryParse(e.code ?? '') ?? 500,
        data: e.details,
      );
    } catch (e) {
      AppLogger.error('Mark attendance unexpected error', error: e);
      throw ServerException(
        message: 'Failed to mark attendance: $e',
        statusCode: 500,
      );
    }
  }

  @override
  Future<Map<String, dynamic>> getAttendanceSummary(
    String classId,
    String termId,
  ) async {
    try {
      // Fetch all attendance records for the class in the term
      final records = await _supabaseClient
          .from(_attendanceRecordsTable)
          .select('id')
          .eq('class_id', classId)
          .eq('term_id', termId);

      final recordIds = records.map<String>((r) => r['id'] as String).toList();

      if (recordIds.isEmpty) {
        return {
          'total_days': 0,
          'total_present': 0,
          'total_absent': 0,
          'total_late': 0,
          'total_excused': 0,
          'average_attendance_rate': 0.0,
        };
      }

      // Fetch all entries for those records
      final entries = await _supabaseClient
          .from(_attendanceEntriesTable)
          .select('status')
          .inFilter('attendance_record_id', recordIds);

      final totalEntries = entries.length;
      final presentCount = entries
          .where((e) => e['status'] == 'present')
          .length;
      final absentCount = entries
          .where((e) => e['status'] == 'absent')
          .length;
      final lateCount = entries
          .where((e) => e['status'] == 'late')
          .length;
      final excusedCount = entries
          .where((e) => e['status'] == 'excused')
          .length;

      return {
        'total_days': recordIds.length,
        'total_entries': totalEntries,
        'total_present': presentCount,
        'total_absent': absentCount,
        'total_late': lateCount,
        'total_excused': excusedCount,
        'average_attendance_rate': totalEntries > 0
            ? (presentCount + lateCount) / totalEntries * 100
            : 0.0,
      };
    } on sb.PostgrestException catch (e) {
      AppLogger.error('Get attendance summary failed', error: e);
      throw ServerException(
        message: e.message,
        statusCode: int.tryParse(e.code ?? '') ?? 500,
        data: e.details,
      );
    } catch (e) {
      AppLogger.error('Get attendance summary unexpected error', error: e);
      throw ServerException(
        message: 'Failed to get attendance summary: $e',
        statusCode: 500,
      );
    }
  }

  // ═══════════════════════════════════════════════════════════════════
  // Homework
  // ═══════════════════════════════════════════════════════════════════

  @override
  Future<HomeworkModel> createHomework(Map<String, dynamic> homeworkData) async {
    try {
      final response = await _supabaseClient
          .from(_homeworkTable)
          .insert(homeworkData)
          .select()
          .single();

      return HomeworkModel.fromJson(response);
    } on sb.PostgrestException catch (e) {
      AppLogger.error('Create homework failed', error: e);
      throw ServerException(
        message: e.message,
        statusCode: int.tryParse(e.code ?? '') ?? 500,
        data: e.details,
      );
    } catch (e) {
      AppLogger.error('Create homework unexpected error', error: e);
      throw ServerException(
        message: 'Failed to create homework: $e',
        statusCode: 500,
      );
    }
  }

  @override
  Future<HomeworkModel> updateHomework(
    String homeworkId,
    Map<String, dynamic> homeworkData,
  ) async {
    try {
      final response = await _supabaseClient
          .from(_homeworkTable)
          .update(homeworkData)
          .eq('id', homeworkId)
          .select()
          .single();

      return HomeworkModel.fromJson(response);
    } on sb.PostgrestException catch (e) {
      AppLogger.error('Update homework failed', error: e);
      if (e.code == 'PGRST116') {
        throw NotFoundException('Homework not found: $homeworkId');
      }
      throw ServerException(
        message: e.message,
        statusCode: int.tryParse(e.code ?? '') ?? 500,
        data: e.details,
      );
    } catch (e) {
      AppLogger.error('Update homework unexpected error', error: e);
      throw ServerException(
        message: 'Failed to update homework: $e',
        statusCode: 500,
      );
    }
  }

  @override
  Future<void> deleteHomework(String homeworkId) async {
    try {
      await _supabaseClient
          .from(_homeworkTable)
          .delete()
          .eq('id', homeworkId);
    } on sb.PostgrestException catch (e) {
      AppLogger.error('Delete homework failed', error: e);
      throw ServerException(
        message: e.message,
        statusCode: int.tryParse(e.code ?? '') ?? 500,
        data: e.details,
      );
    } catch (e) {
      AppLogger.error('Delete homework unexpected error', error: e);
      throw ServerException(
        message: 'Failed to delete homework: $e',
        statusCode: 500,
      );
    }
  }

  @override
  Future<HomeworkModel> getHomework(String homeworkId) async {
    try {
      final response = await _supabaseClient
          .from(_homeworkTable)
          .select()
          .eq('id', homeworkId)
          .single();

      return HomeworkModel.fromJson(response);
    } on sb.PostgrestException catch (e) {
      AppLogger.error('Get homework failed', error: e);
      if (e.code == 'PGRST116') {
        throw NotFoundException('Homework not found: $homeworkId');
      }
      throw ServerException(
        message: e.message,
        statusCode: int.tryParse(e.code ?? '') ?? 500,
        data: e.details,
      );
    } catch (e) {
      AppLogger.error('Get homework unexpected error', error: e);
      throw ServerException(
        message: 'Failed to get homework: $e',
        statusCode: 500,
      );
    }
  }

  @override
  Future<List<HomeworkModel>> getHomeworkList({
    required String schoolId,
    String? classId,
    String? subjectId,
    String? teacherId,
    String? status,
    int page = 1,
    int perPage = 20,
  }) async {
    try {
      var query = _supabaseClient
          .from(_homeworkTable)
          .select()
          .eq('school_id', schoolId);

      if (classId != null) {
        query = query.eq('class_id', classId);
      }
      if (subjectId != null) {
        query = query.eq('subject_id', subjectId);
      }
      if (teacherId != null) {
        query = query.eq('teacher_id', teacherId);
      }
      if (status != null) {
        query = query.eq('status', status);
      }

      final offset = (page - 1) * perPage;
      query = query.range(offset, offset + perPage - 1);
      query = query.order('created_at', ascending: false);

      final response = await query;

      return response
          .map<HomeworkModel>((json) => HomeworkModel.fromJson(json))
          .toList();
    } on sb.PostgrestException catch (e) {
      AppLogger.error('Get homework list failed', error: e);
      throw ServerException(
        message: e.message,
        statusCode: int.tryParse(e.code ?? '') ?? 500,
        data: e.details,
      );
    } catch (e) {
      AppLogger.error('Get homework list unexpected error', error: e);
      throw ServerException(
        message: 'Failed to get homework list: $e',
        statusCode: 500,
      );
    }
  }

  @override
  Future<HomeworkModel> publishHomework(String homeworkId) async {
    try {
      final response = await _supabaseClient
          .from(_homeworkTable)
          .update({
            'status': 'published',
            'is_published': true,
          })
          .eq('id', homeworkId)
          .select()
          .single();

      return HomeworkModel.fromJson(response);
    } on sb.PostgrestException catch (e) {
      AppLogger.error('Publish homework failed', error: e);
      throw ServerException(
        message: e.message,
        statusCode: int.tryParse(e.code ?? '') ?? 500,
        data: e.details,
      );
    } catch (e) {
      AppLogger.error('Publish homework unexpected error', error: e);
      throw ServerException(
        message: 'Failed to publish homework: $e',
        statusCode: 500,
      );
    }
  }

  @override
  Future<HomeworkSubmissionModel> submitHomework(
    Map<String, dynamic> submissionData,
  ) async {
    try {
      submissionData['submitted_at'] = DateTime.now().toIso8601String();
      submissionData['status'] = 'submitted';

      final response = await _supabaseClient
          .from(_homeworkSubmissionsTable)
          .insert(submissionData)
          .select()
          .single();

      return HomeworkSubmissionModel.fromJson(response);
    } on sb.PostgrestException catch (e) {
      AppLogger.error('Submit homework failed', error: e);
      throw ServerException(
        message: e.message,
        statusCode: int.tryParse(e.code ?? '') ?? 500,
        data: e.details,
      );
    } catch (e) {
      AppLogger.error('Submit homework unexpected error', error: e);
      throw ServerException(
        message: 'Failed to submit homework: $e',
        statusCode: 500,
      );
    }
  }

  @override
  Future<HomeworkSubmissionModel> gradeSubmission(
    Map<String, dynamic> gradeData,
  ) async {
    try {
      final submissionId = gradeData['submission_id'] as String;
      gradeData.remove('submission_id');

      gradeData['graded_at'] = DateTime.now().toIso8601String();
      gradeData['status'] = 'graded';

      final response = await _supabaseClient
          .from(_homeworkSubmissionsTable)
          .update(gradeData)
          .eq('id', submissionId)
          .select()
          .single();

      return HomeworkSubmissionModel.fromJson(response);
    } on sb.PostgrestException catch (e) {
      AppLogger.error('Grade submission failed', error: e);
      throw ServerException(
        message: e.message,
        statusCode: int.tryParse(e.code ?? '') ?? 500,
        data: e.details,
      );
    } catch (e) {
      AppLogger.error('Grade submission unexpected error', error: e);
      throw ServerException(
        message: 'Failed to grade submission: $e',
        statusCode: 500,
      );
    }
  }

  @override
  Future<List<HomeworkSubmissionModel>> getHomeworkSubmissions(
    String homeworkId,
  ) async {
    try {
      final response = await _supabaseClient
          .from(_homeworkSubmissionsTable)
          .select()
          .eq('homework_id', homeworkId)
          .order('submitted_at', ascending: false);

      return response
          .map<HomeworkSubmissionModel>(
            (json) => HomeworkSubmissionModel.fromJson(json),
          )
          .toList();
    } on sb.PostgrestException catch (e) {
      AppLogger.error('Get homework submissions failed', error: e);
      throw ServerException(
        message: e.message,
        statusCode: int.tryParse(e.code ?? '') ?? 500,
        data: e.details,
      );
    } catch (e) {
      AppLogger.error('Get homework submissions unexpected error', error: e);
      throw ServerException(
        message: 'Failed to get homework submissions: $e',
        statusCode: 500,
      );
    }
  }

  // ═══════════════════════════════════════════════════════════════════
  // Announcements
  // ═══════════════════════════════════════════════════════════════════

  @override
  Future<AnnouncementModel> createAnnouncement(
    Map<String, dynamic> announcementData,
  ) async {
    try {
      final response = await _supabaseClient
          .from(_announcementsTable)
          .insert(announcementData)
          .select()
          .single();

      return AnnouncementModel.fromJson(response);
    } on sb.PostgrestException catch (e) {
      AppLogger.error('Create announcement failed', error: e);
      throw ServerException(
        message: e.message,
        statusCode: int.tryParse(e.code ?? '') ?? 500,
        data: e.details,
      );
    } catch (e) {
      AppLogger.error('Create announcement unexpected error', error: e);
      throw ServerException(
        message: 'Failed to create announcement: $e',
        statusCode: 500,
      );
    }
  }

  @override
  Future<AnnouncementModel> updateAnnouncement(
    String announcementId,
    Map<String, dynamic> announcementData,
  ) async {
    try {
      final response = await _supabaseClient
          .from(_announcementsTable)
          .update(announcementData)
          .eq('id', announcementId)
          .select()
          .single();

      return AnnouncementModel.fromJson(response);
    } on sb.PostgrestException catch (e) {
      AppLogger.error('Update announcement failed', error: e);
      if (e.code == 'PGRST116') {
        throw NotFoundException('Announcement not found: $announcementId');
      }
      throw ServerException(
        message: e.message,
        statusCode: int.tryParse(e.code ?? '') ?? 500,
        data: e.details,
      );
    } catch (e) {
      AppLogger.error('Update announcement unexpected error', error: e);
      throw ServerException(
        message: 'Failed to update announcement: $e',
        statusCode: 500,
      );
    }
  }

  @override
  Future<void> deleteAnnouncement(String announcementId) async {
    try {
      await _supabaseClient
          .from(_announcementsTable)
          .delete()
          .eq('id', announcementId);
    } on sb.PostgrestException catch (e) {
      AppLogger.error('Delete announcement failed', error: e);
      throw ServerException(
        message: e.message,
        statusCode: int.tryParse(e.code ?? '') ?? 500,
        data: e.details,
      );
    } catch (e) {
      AppLogger.error('Delete announcement unexpected error', error: e);
      throw ServerException(
        message: 'Failed to delete announcement: $e',
        statusCode: 500,
      );
    }
  }

  @override
  Future<List<AnnouncementModel>> getAnnouncements({
    required String schoolId,
    String? type,
    bool? isPublished,
    int page = 1,
    int perPage = 20,
  }) async {
    try {
      var query = _supabaseClient
          .from(_announcementsTable)
          .select()
          .eq('school_id', schoolId);

      if (type != null) {
        query = query.eq('announcement_type', type);
      }
      if (isPublished != null) {
        query = query.eq('is_published', isPublished);
      }

      final offset = (page - 1) * perPage;
      query = query.range(offset, offset + perPage - 1);
      query = query.order('created_at', ascending: false);

      final response = await query;

      return response
          .map<AnnouncementModel>((json) => AnnouncementModel.fromJson(json))
          .toList();
    } on sb.PostgrestException catch (e) {
      AppLogger.error('Get announcements failed', error: e);
      throw ServerException(
        message: e.message,
        statusCode: int.tryParse(e.code ?? '') ?? 500,
        data: e.details,
      );
    } catch (e) {
      AppLogger.error('Get announcements unexpected error', error: e);
      throw ServerException(
        message: 'Failed to get announcements: $e',
        statusCode: 500,
      );
    }
  }

  @override
  Future<AnnouncementModel> publishAnnouncement(
    String announcementId,
  ) async {
    try {
      final response = await _supabaseClient
          .from(_announcementsTable)
          .update({
            'is_published': true,
            'published_at': DateTime.now().toIso8601String(),
          })
          .eq('id', announcementId)
          .select()
          .single();

      return AnnouncementModel.fromJson(response);
    } on sb.PostgrestException catch (e) {
      AppLogger.error('Publish announcement failed', error: e);
      throw ServerException(
        message: e.message,
        statusCode: int.tryParse(e.code ?? '') ?? 500,
        data: e.details,
      );
    } catch (e) {
      AppLogger.error('Publish announcement unexpected error', error: e);
      throw ServerException(
        message: 'Failed to publish announcement: $e',
        statusCode: 500,
      );
    }
  }

  // ═══════════════════════════════════════════════════════════════════
  // Documents
  // ═══════════════════════════════════════════════════════════════════

  @override
  Future<DocumentModel> createDocument(Map<String, dynamic> documentData) async {
    try {
      final response = await _supabaseClient
          .from(_documentsTable)
          .insert(documentData)
          .select()
          .single();

      return DocumentModel.fromJson(response);
    } on sb.PostgrestException catch (e) {
      AppLogger.error('Create document failed', error: e);
      throw ServerException(
        message: e.message,
        statusCode: int.tryParse(e.code ?? '') ?? 500,
        data: e.details,
      );
    } catch (e) {
      AppLogger.error('Create document unexpected error', error: e);
      throw ServerException(
        message: 'Failed to create document: $e',
        statusCode: 500,
      );
    }
  }

  @override
  Future<DocumentModel> updateDocument(
    String documentId,
    Map<String, dynamic> documentData,
  ) async {
    try {
      final response = await _supabaseClient
          .from(_documentsTable)
          .update(documentData)
          .eq('id', documentId)
          .select()
          .single();

      return DocumentModel.fromJson(response);
    } on sb.PostgrestException catch (e) {
      AppLogger.error('Update document failed', error: e);
      if (e.code == 'PGRST116') {
        throw NotFoundException('Document not found: $documentId');
      }
      throw ServerException(
        message: e.message,
        statusCode: int.tryParse(e.code ?? '') ?? 500,
        data: e.details,
      );
    } catch (e) {
      AppLogger.error('Update document unexpected error', error: e);
      throw ServerException(
        message: 'Failed to update document: $e',
        statusCode: 500,
      );
    }
  }

  @override
  Future<void> deleteDocument(String documentId) async {
    try {
      await _supabaseClient
          .from(_documentsTable)
          .delete()
          .eq('id', documentId);
    } on sb.PostgrestException catch (e) {
      AppLogger.error('Delete document failed', error: e);
      throw ServerException(
        message: e.message,
        statusCode: int.tryParse(e.code ?? '') ?? 500,
        data: e.details,
      );
    } catch (e) {
      AppLogger.error('Delete document unexpected error', error: e);
      throw ServerException(
        message: 'Failed to delete document: $e',
        statusCode: 500,
      );
    }
  }

  @override
  Future<List<DocumentModel>> getDocuments({
    required String schoolId,
    String? documentType,
    String? category,
    String? searchQuery,
    bool? isPublic,
    int page = 1,
    int perPage = 20,
  }) async {
    try {
      var query = _supabaseClient
          .from(_documentsTable)
          .select()
          .eq('school_id', schoolId);

      if (documentType != null) {
        query = query.eq('document_type', documentType);
      }
      if (category != null) {
        query = query.eq('category', category);
      }
      if (isPublic != null) {
        query = query.eq('is_public', isPublic);
      }
      if (searchQuery != null && searchQuery.isNotEmpty) {
        query = query.ilike('title', '%$searchQuery%');
      }

      final offset = (page - 1) * perPage;
      query = query.range(offset, offset + perPage - 1);
      query = query.order('created_at', ascending: false);

      final response = await query;

      return response
          .map<DocumentModel>((json) => DocumentModel.fromJson(json))
          .toList();
    } on sb.PostgrestException catch (e) {
      AppLogger.error('Get documents failed', error: e);
      throw ServerException(
        message: e.message,
        statusCode: int.tryParse(e.code ?? '') ?? 500,
        data: e.details,
      );
    } catch (e) {
      AppLogger.error('Get documents unexpected error', error: e);
      throw ServerException(
        message: 'Failed to get documents: $e',
        statusCode: 500,
      );
    }
  }

  @override
  Future<void> incrementDownloadCount(String documentId) async {
    try {
      await _supabaseClient.rpc(
        'increment_document_download',
        params: {'doc_id': documentId},
      );
    } on sb.PostgrestException catch (e) {
      AppLogger.error('Increment download count failed', error: e);
      // Fallback: manual increment if RPC is not available
      try {
        final doc = await _supabaseClient
            .from(_documentsTable)
            .select('download_count')
            .eq('id', documentId)
            .single();

        final currentCount = doc['download_count'] as int? ?? 0;
        await _supabaseClient
            .from(_documentsTable)
            .update({'download_count': currentCount + 1})
            .eq('id', documentId);
      } catch (fallbackError) {
        AppLogger.error('Fallback increment download count failed', error: fallbackError);
        throw ServerException(
          message: 'Failed to increment download count',
          statusCode: 500,
        );
      }
    } catch (e) {
      AppLogger.error('Increment download count unexpected error', error: e);
      throw ServerException(
        message: 'Failed to increment download count: $e',
        statusCode: 500,
      );
    }
  }

  // ═══════════════════════════════════════════════════════════════════
  // Classes
  // ═══════════════════════════════════════════════════════════════════

  @override
  Future<ClassModel> getClass(String classId) async {
    try {
      final response = await _supabaseClient
          .from(_classesTable)
          .select()
          .eq('id', classId)
          .single();

      return ClassModel.fromJson(response);
    } on sb.PostgrestException catch (e) {
      AppLogger.error('Get class failed', error: e);
      if (e.code == 'PGRST116') {
        throw NotFoundException('Class not found: $classId');
      }
      throw ServerException(
        message: e.message,
        statusCode: int.tryParse(e.code ?? '') ?? 500,
        data: e.details,
      );
    } catch (e) {
      AppLogger.error('Get class unexpected error', error: e);
      throw ServerException(
        message: 'Failed to get class: $e',
        statusCode: 500,
      );
    }
  }

  @override
  Future<List<ClassModel>> getClasses({
    required String schoolId,
    String? academicYear,
    bool? isActive,
    int page = 1,
    int perPage = 20,
  }) async {
    try {
      var query = _supabaseClient
          .from(_classesTable)
          .select()
          .eq('school_id', schoolId);

      if (academicYear != null) {
        query = query.eq('academic_year', academicYear);
      }
      if (isActive != null) {
        query = query.eq('is_active', isActive);
      }

      final offset = (page - 1) * perPage;
      query = query.range(offset, offset + perPage - 1);
      query = query.order('name', ascending: true);

      final response = await query;

      return response
          .map<ClassModel>((json) => ClassModel.fromJson(json))
          .toList();
    } on sb.PostgrestException catch (e) {
      AppLogger.error('Get classes failed', error: e);
      throw ServerException(
        message: e.message,
        statusCode: int.tryParse(e.code ?? '') ?? 500,
        data: e.details,
      );
    } catch (e) {
      AppLogger.error('Get classes unexpected error', error: e);
      throw ServerException(
        message: 'Failed to get classes: $e',
        statusCode: 500,
      );
    }
  }

  @override
  Future<ClassModel> createClass(Map<String, dynamic> classData) async {
    try {
      final response = await _supabaseClient
          .from(_classesTable)
          .insert(classData)
          .select()
          .single();

      return ClassModel.fromJson(response);
    } on sb.PostgrestException catch (e) {
      AppLogger.error('Create class failed', error: e);
      throw ServerException(
        message: e.message,
        statusCode: int.tryParse(e.code ?? '') ?? 500,
        data: e.details,
      );
    } catch (e) {
      AppLogger.error('Create class unexpected error', error: e);
      throw ServerException(
        message: 'Failed to create class: $e',
        statusCode: 500,
      );
    }
  }

  @override
  Future<ClassModel> updateClass(
    String classId,
    Map<String, dynamic> classData,
  ) async {
    try {
      final response = await _supabaseClient
          .from(_classesTable)
          .update(classData)
          .eq('id', classId)
          .select()
          .single();

      return ClassModel.fromJson(response);
    } on sb.PostgrestException catch (e) {
      AppLogger.error('Update class failed', error: e);
      if (e.code == 'PGRST116') {
        throw NotFoundException('Class not found: $classId');
      }
      throw ServerException(
        message: e.message,
        statusCode: int.tryParse(e.code ?? '') ?? 500,
        data: e.details,
      );
    } catch (e) {
      AppLogger.error('Update class unexpected error', error: e);
      throw ServerException(
        message: 'Failed to update class: $e',
        statusCode: 500,
      );
    }
  }

  @override
  Future<void> assignStudentsToClass(
    String classId,
    List<String> studentIds,
  ) async {
    try {
      final entries = studentIds.map((studentId) => {
        'class_id': classId,
        'student_id': studentId,
        'is_active': true,
      }).toList();

      await _supabaseClient
          .from(_classStudentsTable)
          .upsert(entries, onConflict: 'class_id,student_id');
    } on sb.PostgrestException catch (e) {
      AppLogger.error('Assign students to class failed', error: e);
      throw ServerException(
        message: e.message,
        statusCode: int.tryParse(e.code ?? '') ?? 500,
        data: e.details,
      );
    } catch (e) {
      AppLogger.error('Assign students to class unexpected error', error: e);
      throw ServerException(
        message: 'Failed to assign students to class: $e',
        statusCode: 500,
      );
    }
  }

  @override
  Future<void> removeStudentFromClass(String classId, String studentId) async {
    try {
      await _supabaseClient
          .from(_classStudentsTable)
          .delete()
          .eq('class_id', classId)
          .eq('student_id', studentId);
    } on sb.PostgrestException catch (e) {
      AppLogger.error('Remove student from class failed', error: e);
      throw ServerException(
        message: e.message,
        statusCode: int.tryParse(e.code ?? '') ?? 500,
        data: e.details,
      );
    } catch (e) {
      AppLogger.error('Remove student from class unexpected error', error: e);
      throw ServerException(
        message: 'Failed to remove student from class: $e',
        statusCode: 500,
      );
    }
  }

  // ═══════════════════════════════════════════════════════════════════
  // Subjects
  // ═══════════════════════════════════════════════════════════════════

  @override
  Future<SubjectModel> getSubject(String subjectId) async {
    try {
      final response = await _supabaseClient
          .from(_subjectsTable)
          .select()
          .eq('id', subjectId)
          .single();

      return SubjectModel.fromJson(response);
    } on sb.PostgrestException catch (e) {
      AppLogger.error('Get subject failed', error: e);
      if (e.code == 'PGRST116') {
        throw NotFoundException('Subject not found: $subjectId');
      }
      throw ServerException(
        message: e.message,
        statusCode: int.tryParse(e.code ?? '') ?? 500,
        data: e.details,
      );
    } catch (e) {
      AppLogger.error('Get subject unexpected error', error: e);
      throw ServerException(
        message: 'Failed to get subject: $e',
        statusCode: 500,
      );
    }
  }

  @override
  Future<List<SubjectModel>> getSubjects({
    required String schoolId,
    String? category,
    bool? isActive,
  }) async {
    try {
      var query = _supabaseClient
          .from(_subjectsTable)
          .select()
          .eq('school_id', schoolId);

      if (category != null) {
        query = query.eq('category', category);
      }
      if (isActive != null) {
        query = query.eq('is_active', isActive);
      }

      query = query.order('name', ascending: true);

      final response = await query;

      return response
          .map<SubjectModel>((json) => SubjectModel.fromJson(json))
          .toList();
    } on sb.PostgrestException catch (e) {
      AppLogger.error('Get subjects failed', error: e);
      throw ServerException(
        message: e.message,
        statusCode: int.tryParse(e.code ?? '') ?? 500,
        data: e.details,
      );
    } catch (e) {
      AppLogger.error('Get subjects unexpected error', error: e);
      throw ServerException(
        message: 'Failed to get subjects: $e',
        statusCode: 500,
      );
    }
  }

  @override
  Future<SubjectModel> createSubject(Map<String, dynamic> subjectData) async {
    try {
      final response = await _supabaseClient
          .from(_subjectsTable)
          .insert(subjectData)
          .select()
          .single();

      return SubjectModel.fromJson(response);
    } on sb.PostgrestException catch (e) {
      AppLogger.error('Create subject failed', error: e);
      throw ServerException(
        message: e.message,
        statusCode: int.tryParse(e.code ?? '') ?? 500,
        data: e.details,
      );
    } catch (e) {
      AppLogger.error('Create subject unexpected error', error: e);
      throw ServerException(
        message: 'Failed to create subject: $e',
        statusCode: 500,
      );
    }
  }

  @override
  Future<SubjectModel> updateSubject(
    String subjectId,
    Map<String, dynamic> subjectData,
  ) async {
    try {
      final response = await _supabaseClient
          .from(_subjectsTable)
          .update(subjectData)
          .eq('id', subjectId)
          .select()
          .single();

      return SubjectModel.fromJson(response);
    } on sb.PostgrestException catch (e) {
      AppLogger.error('Update subject failed', error: e);
      if (e.code == 'PGRST116') {
        throw NotFoundException('Subject not found: $subjectId');
      }
      throw ServerException(
        message: e.message,
        statusCode: int.tryParse(e.code ?? '') ?? 500,
        data: e.details,
      );
    } catch (e) {
      AppLogger.error('Update subject unexpected error', error: e);
      throw ServerException(
        message: 'Failed to update subject: $e',
        statusCode: 500,
      );
    }
  }

  @override
  Future<void> assignTeacherToSubject(Map<String, dynamic> data) async {
    try {
      await _supabaseClient
          .from(_classSubjectsTable)
          .upsert(data, onConflict: 'class_id,subject_id');
    } on sb.PostgrestException catch (e) {
      AppLogger.error('Assign teacher to subject failed', error: e);
      throw ServerException(
        message: e.message,
        statusCode: int.tryParse(e.code ?? '') ?? 500,
        data: e.details,
      );
    } catch (e) {
      AppLogger.error('Assign teacher to subject unexpected error', error: e);
      throw ServerException(
        message: 'Failed to assign teacher to subject: $e',
        statusCode: 500,
      );
    }
  }

  // ═══════════════════════════════════════════════════════════════════
  // Reports
  // ═══════════════════════════════════════════════════════════════════

  @override
  Future<Map<String, dynamic>> getSchoolOverview(String schoolId) async {
    try {
      // Aggregate counts from various tables in parallel
      final results = await Future.wait([
        _supabaseClient
            .from(_studentProfilesTable)
            .select('id')
            .eq('school_id', schoolId)
            .eq('is_active', true),
        _supabaseClient
            .from(_teacherProfilesTable)
            .select('id')
            .eq('school_id', schoolId)
            .eq('is_active', true),
        _supabaseClient
            .from(_classesTable)
            .select('id')
            .eq('school_id', schoolId)
            .eq('is_active', true),
        _supabaseClient
            .from(_subjectsTable)
            .select('id')
            .eq('school_id', schoolId),
        _supabaseClient
            .from(_parentProfilesTable)
            .select('id')
            .eq('school_id', schoolId)
            .eq('is_active', true),
        _supabaseClient
            .from(_academicSessionsTable)
            .select()
            .eq('school_id', schoolId)
            .eq('is_current', true)
            .maybeSingle(),
      ]);

      return {
        'total_students': (results[0] as List).length,
        'total_teachers': (results[1] as List).length,
        'total_classes': (results[2] as List).length,
        'total_subjects': (results[3] as List).length,
        'total_parents': (results[4] as List).length,
        'current_session': results[5],
      };
    } on sb.PostgrestException catch (e) {
      AppLogger.error('Get school overview failed', error: e);
      throw ServerException(
        message: e.message,
        statusCode: int.tryParse(e.code ?? '') ?? 500,
        data: e.details,
      );
    } catch (e) {
      AppLogger.error('Get school overview unexpected error', error: e);
      throw ServerException(
        message: 'Failed to get school overview: $e',
        statusCode: 500,
      );
    }
  }

  @override
  Future<List<StudentProfileModel>> getStudentListReport(
    String schoolId,
    String? classId,
  ) async {
    try {
      var query = _supabaseClient
          .from(_studentProfilesTable)
          .select('*, users!student_profiles_user_id_fkey(full_name, email, phone, avatar_url)')
          .eq('school_id', schoolId);

      if (classId != null) {
        query = query.eq('current_class_id', classId);
      }

      query = query.order('admission_number', ascending: true);

      final response = await query;

      return response
          .map<StudentProfileModel>((json) => StudentProfileModel.fromJson(json))
          .toList();
    } on sb.PostgrestException catch (e) {
      AppLogger.error('Get student list report failed', error: e);
      throw ServerException(
        message: e.message,
        statusCode: int.tryParse(e.code ?? '') ?? 500,
        data: e.details,
      );
    } catch (e) {
      AppLogger.error('Get student list report unexpected error', error: e);
      throw ServerException(
        message: 'Failed to get student list report: $e',
        statusCode: 500,
      );
    }
  }

  @override
  Future<List<TeacherProfileModel>> getTeacherListReport(
    String schoolId,
  ) async {
    try {
      final response = await _supabaseClient
          .from(_teacherProfilesTable)
          .select('*, users!teacher_profiles_user_id_fkey(full_name, email, phone, avatar_url)')
          .eq('school_id', schoolId)
          .eq('is_active', true)
          .order('employee_id', ascending: true);

      return response
          .map<TeacherProfileModel>((json) => TeacherProfileModel.fromJson(json))
          .toList();
    } on sb.PostgrestException catch (e) {
      AppLogger.error('Get teacher list report failed', error: e);
      throw ServerException(
        message: e.message,
        statusCode: int.tryParse(e.code ?? '') ?? 500,
        data: e.details,
      );
    } catch (e) {
      AppLogger.error('Get teacher list report unexpected error', error: e);
      throw ServerException(
        message: 'Failed to get teacher list report: $e',
        statusCode: 500,
      );
    }
  }

  @override
  Future<Map<String, dynamic>> getAttendanceReport({
    required String schoolId,
    required String termId,
    String? classId,
    String? startDate,
    String? endDate,
  }) async {
    try {
      var query = _supabaseClient
          .from(_attendanceRecordsTable)
          .select('id, date, attendance_type, attendance_entries(status)')
          .eq('school_id', schoolId)
          .eq('term_id', termId);

      if (classId != null) {
        query = query.eq('class_id', classId);
      }
      if (startDate != null) {
        query = query.gte('date', startDate);
      }
      if (endDate != null) {
        query = query.lte('date', endDate);
      }

      final records = await query;

      // Aggregate attendance data
      int totalRecords = records.length;
      int totalPresent = 0;
      int totalAbsent = 0;
      int totalLate = 0;
      int totalExcused = 0;
      int totalSick = 0;

      for (final record in records) {
        final entries = record['attendance_entries'] as List<dynamic>? ?? [];
        for (final entry in entries) {
          final status = entry['status'] as String? ?? '';
          switch (status) {
            case 'present':
              totalPresent++;
              break;
            case 'absent':
              totalAbsent++;
              break;
            case 'late':
              totalLate++;
              break;
            case 'excused':
              totalExcused++;
              break;
            case 'sick':
              totalSick++;
              break;
          }
        }
      }

      final totalEntries =
          totalPresent + totalAbsent + totalLate + totalExcused + totalSick;

      return {
        'total_records': totalRecords,
        'total_entries': totalEntries,
        'total_present': totalPresent,
        'total_absent': totalAbsent,
        'total_late': totalLate,
        'total_excused': totalExcused,
        'total_sick': totalSick,
        'attendance_rate': totalEntries > 0
            ? ((totalPresent + totalLate) / totalEntries * 100).toStringAsFixed(1)
            : '0.0',
        'absentee_rate': totalEntries > 0
            ? (totalAbsent / totalEntries * 100).toStringAsFixed(1)
            : '0.0',
        'records': records,
      };
    } on sb.PostgrestException catch (e) {
      AppLogger.error('Get attendance report failed', error: e);
      throw ServerException(
        message: e.message,
        statusCode: int.tryParse(e.code ?? '') ?? 500,
        data: e.details,
      );
    } catch (e) {
      AppLogger.error('Get attendance report unexpected error', error: e);
      throw ServerException(
        message: 'Failed to get attendance report: $e',
        statusCode: 500,
      );
    }
  }
}
