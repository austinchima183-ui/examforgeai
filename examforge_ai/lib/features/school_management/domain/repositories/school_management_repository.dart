import '../../../../core/utils/result.dart';
import '../entities/school_management_entities.dart';
import '../../../../features/school_management/domain/entities/school_management_entities.dart';


/// Abstract contract for all School Management operations.
///
/// Every method returns a [Result] to force callers to handle both
/// success and failure at compile time, avoiding uncaught exceptions
/// across layer boundaries.
abstract class SchoolManagementRepository {
  // ═══════════════════════════════════════════════════════════════════════
  // SCHOOL CRUD
  // ═══════════════════════════════════════════════════════════════════════

  Future<Result<SchoolEntity>> createSchool(SchoolEntity school);
  Future<Result<SchoolEntity>> updateSchool(SchoolEntity school);
  Future<Result<void>> deleteSchool(String schoolId);
  Future<Result<SchoolEntity>> getSchool(String schoolId);
  Future<Result<List<SchoolEntity>>> getSchools({
    bool? isActive,
    int page = 1,
    int perPage = 20,
  });

  // ═══════════════════════════════════════════════════════════════════════
  // SCHOOL BRANCHES
  // ═══════════════════════════════════════════════════════════════════════

  Future<Result<SchoolBranchEntity>> createBranch(SchoolBranchEntity branch);
  Future<Result<SchoolBranchEntity>> updateBranch(SchoolBranchEntity branch);
  Future<Result<void>> deleteBranch(String branchId);
  Future<Result<List<SchoolBranchEntity>>> getBranches(String schoolId);

  // ═══════════════════════════════════════════════════════════════════════
  // DEPARTMENTS
  // ═══════════════════════════════════════════════════════════════════════

  Future<Result<DepartmentEntity>> createDepartment(DepartmentEntity department);
  Future<Result<DepartmentEntity>> updateDepartment(DepartmentEntity department);
  Future<Result<void>> deleteDepartment(String departmentId);
  Future<Result<List<DepartmentEntity>>> getDepartments(String schoolId);

  // ═══════════════════════════════════════════════════════════════════════
  // STUDENT PROFILES
  // ═══════════════════════════════════════════════════════════════════════

  Future<Result<StudentProfileEntity>> createStudentProfile(StudentProfileEntity profile);
  Future<Result<StudentProfileEntity>> updateStudentProfile(StudentProfileEntity profile);
  Future<Result<StudentProfileEntity>> getStudentProfile(String userId);
  Future<Result<List<StudentProfileEntity>>> getStudentProfiles({
    required String schoolId,
    String? classId,
    bool? isActive,
    bool? isGraduated,
    String? searchQuery,
    int page = 1,
    int perPage = 20,
  });
  Future<Result<void>> promoteStudent({
    required String studentId,
    required String schoolId,
    required String toClassId,
    required PromotionStatus promotionStatus,
    String? fromClassId,
    String? academicSessionId,
    double? averageScore,
    String? comment,
  });
  Future<Result<void>> graduateStudent(String studentId, String schoolId);
  Future<Result<List<PromotionHistoryEntity>>> getPromotionHistory(String studentId);

  // ═══════════════════════════════════════════════════════════════════════
  // TEACHER PROFILES
  // ═══════════════════════════════════════════════════════════════════════

  Future<Result<TeacherProfileEntity>> createTeacherProfile(TeacherProfileEntity profile);
  Future<Result<TeacherProfileEntity>> updateTeacherProfile(TeacherProfileEntity profile);
  Future<Result<TeacherProfileEntity>> getTeacherProfile(String userId);
  Future<Result<List<TeacherProfileEntity>>> getTeacherProfiles({
    required String schoolId,
    String? departmentId,
    bool? isActive,
    String? searchQuery,
    int page = 1,
    int perPage = 20,
  });

  // ═══════════════════════════════════════════════════════════════════════
  // PARENT PROFILES
  // ═══════════════════════════════════════════════════════════════════════

  Future<Result<ParentProfileEntity>> createParentProfile(ParentProfileEntity profile);
  Future<Result<ParentProfileEntity>> updateParentProfile(ParentProfileEntity profile);
  Future<Result<ParentProfileEntity>> getParentProfile(String userId);
  Future<Result<List<ParentProfileEntity>>> getParentProfiles({
    required String schoolId,
    String? searchQuery,
    int page = 1,
    int perPage = 20,
  });
  Future<Result<void>> linkParentToStudent({
    required String parentId,
    required String studentId,
    required String relationship,
    bool isPrimaryContact = false,
  });
  Future<Result<void>> unlinkParentFromStudent(String linkId);
  Future<Result<List<ParentStudentLinkEntity>>> getParentStudentLinks(String studentId);

  // ═══════════════════════════════════════════════════════════════════════
  // ACADEMIC SESSIONS
  // ═══════════════════════════════════════════════════════════════════════

  Future<Result<AcademicSessionEntity>> createSession(AcademicSessionEntity session);
  Future<Result<AcademicSessionEntity>> updateSession(AcademicSessionEntity session);
  Future<Result<void>> deleteSession(String sessionId);
  Future<Result<AcademicSessionEntity>> getSession(String sessionId);
  Future<Result<List<AcademicSessionEntity>>> getSessions(String schoolId);
  Future<Result<AcademicSessionEntity>> getCurrentSession(String schoolId);
  Future<Result<void>> setCurrentSession(String sessionId);

  // ═══════════════════════════════════════════════════════════════════════
  // TERMS
  // ═══════════════════════════════════════════════════════════════════════

  Future<Result<TermEntity>> createTerm(TermEntity term);
  Future<Result<TermEntity>> updateTerm(TermEntity term);
  Future<Result<void>> deleteTerm(String termId);
  Future<Result<List<TermEntity>>> getTerms(String academicSessionId);
  Future<Result<TermEntity>> getCurrentTerm(String schoolId);
  Future<Result<void>> setCurrentTerm(String termId);

  // ═══════════════════════════════════════════════════════════════════════
  // SCHOOL CALENDAR
  // ═══════════════════════════════════════════════════════════════════════

  Future<Result<CalendarEventEntity>> createCalendarEvent(CalendarEventEntity event);
  Future<Result<CalendarEventEntity>> updateCalendarEvent(CalendarEventEntity event);
  Future<Result<void>> deleteCalendarEvent(String eventId);
  Future<Result<List<CalendarEventEntity>>> getCalendarEvents({
    required String schoolId,
    String? termId,
    DateTime? startDate,
    DateTime? endDate,
    CalendarEventType? eventType,
  });

  // ═══════════════════════════════════════════════════════════════════════
  // TIMETABLES
  // ═══════════════════════════════════════════════════════════════════════

  Future<Result<TimetableEntity>> createTimetable(TimetableEntity timetable);
  Future<Result<TimetableEntity>> updateTimetable(TimetableEntity timetable);
  Future<Result<void>> deleteTimetable(String timetableId);
  Future<Result<TimetableEntity>> getTimetable(String timetableId);
  Future<Result<List<TimetableEntity>>> getTimetables({
    required String schoolId,
    String? termId,
    String? classId,
  });
  Future<Result<TimetableSlotEntity>> addTimetableSlot(TimetableSlotEntity slot);
  Future<Result<TimetableSlotEntity>> updateTimetableSlot(TimetableSlotEntity slot);
  Future<Result<void>> deleteTimetableSlot(String slotId);
  Future<Result<void>> publishTimetable(String timetableId);
  Future<Result<List<TimetableSlotEntity>>> checkSlotConflicts(TimetableSlotEntity slot);

  // ═══════════════════════════════════════════════════════════════════════
  // ATTENDANCE
  // ═══════════════════════════════════════════════════════════════════════

  Future<Result<AttendanceRecordEntity>> createAttendanceRecord(AttendanceRecordEntity record);
  Future<Result<AttendanceRecordEntity>> updateAttendanceRecord(AttendanceRecordEntity record);
  Future<Result<AttendanceRecordEntity>> getAttendanceRecord({
    required String classId,
    required String termId,
    required DateTime date,
    String attendanceType = 'student',
  });
  Future<Result<List<AttendanceRecordEntity>>> getAttendanceRecords({
    required String schoolId,
    required String termId,
    String? classId,
    DateTime? startDate,
    DateTime? endDate,
    int page = 1,
    int perPage = 20,
  });
  Future<Result<AttendanceSummaryEntity>> getAttendanceSummary({
    required String classId,
    required String termId,
  });
  Future<Result<void>> markAttendance({
    required String recordId,
    required List<AttendanceEntryEntity> entries,
  });

  // ═══════════════════════════════════════════════════════════════════════
  // HOMEWORK
  // ═══════════════════════════════════════════════════════════════════════

  Future<Result<HomeworkEntity>> createHomework(HomeworkEntity homework);
  Future<Result<HomeworkEntity>> updateHomework(HomeworkEntity homework);
  Future<Result<void>> deleteHomework(String homeworkId);
  Future<Result<HomeworkEntity>> getHomework(String homeworkId);
  Future<Result<List<HomeworkEntity>>> getHomeworkList({
    required String schoolId,
    String? classId,
    String? subjectId,
    String? teacherId,
    HomeworkStatus? status,
    int page = 1,
    int perPage = 20,
  });
  Future<Result<void>> publishHomework(String homeworkId);
  Future<Result<HomeworkSubmissionEntity>> submitHomework(HomeworkSubmissionEntity submission);
  Future<Result<HomeworkSubmissionEntity>> gradeSubmission(HomeworkSubmissionEntity submission);
  Future<Result<List<HomeworkSubmissionEntity>>> getHomeworkSubmissions(String homeworkId);

  // ═══════════════════════════════════════════════════════════════════════
  // ANNOUNCEMENTS
  // ═══════════════════════════════════════════════════════════════════════

  Future<Result<AnnouncementEntity>> createAnnouncement(AnnouncementEntity announcement);
  Future<Result<AnnouncementEntity>> updateAnnouncement(AnnouncementEntity announcement);
  Future<Result<void>> deleteAnnouncement(String announcementId);
  Future<Result<List<AnnouncementEntity>>> getAnnouncements({
    required String schoolId,
    AnnouncementType? type,
    bool? isPublished,
    int page = 1,
    int perPage = 20,
  });
  Future<Result<void>> publishAnnouncement(String announcementId);

  // ═══════════════════════════════════════════════════════════════════════
  // DOCUMENTS
  // ═══════════════════════════════════════════════════════════════════════

  Future<Result<DocumentEntity>> createDocument(DocumentEntity document);
  Future<Result<DocumentEntity>> updateDocument(DocumentEntity document);
  Future<Result<void>> deleteDocument(String documentId);
  Future<Result<List<DocumentEntity>>> getDocuments({
    required String schoolId,
    DocumentType? documentType,
    String? category,
    String? searchQuery,
    bool? isPublic,
    int page = 1,
    int perPage = 20,
  });
  Future<Result<void>> incrementDownloadCount(String documentId);

  // ═══════════════════════════════════════════════════════════════════════
  // CLASSES (enhanced queries)
  // ═══════════════════════════════════════════════════════════════════════

  Future<Result<ClassEntity>> getClass(String classId);
  Future<Result<List<ClassEntity>>> getClasses({
    required String schoolId,
    String? academicYear,
    bool? isActive,
    int page = 1,
    int perPage = 20,
  });
  Future<Result<ClassEntity>> createClass(ClassEntity classEntity);
  Future<Result<ClassEntity>> updateClass(ClassEntity classEntity);
  Future<Result<void>> assignStudentsToClass(String classId, List<String> studentIds);
  Future<Result<void>> removeStudentFromClass(String classId, String studentId);

  // ═══════════════════════════════════════════════════════════════════════
  // SUBJECTS (enhanced queries)
  // ═══════════════════════════════════════════════════════════════════════

  Future<Result<SubjectEntity>> getSubject(String subjectId);
  Future<Result<List<SubjectEntity>>> getSubjects({
    String? schoolId,
    String? category,
    bool? isActive,
  });
  Future<Result<SubjectEntity>> createSubject(SubjectEntity subject);
  Future<Result<SubjectEntity>> updateSubject(SubjectEntity subject);
  Future<Result<void>> assignTeacherToSubject({
    required String classId,
    required String subjectId,
    required String teacherId,
  });

  // ═══════════════════════════════════════════════════════════════════════
  // REPORTS
  // ═══════════════════════════════════════════════════════════════════════

  Future<Result<Map<String, dynamic>>> getSchoolOverview(String schoolId);
  Future<Result<List<Map<String, dynamic>>>> getStudentListReport({
    required String schoolId,
    String? classId,
  });
  Future<Result<List<Map<String, dynamic>>>> getTeacherListReport(String schoolId);
  Future<Result<List<Map<String, dynamic>>>> getAttendanceReport({
    required String schoolId,
    required String termId,
    String? classId,
    DateTime? startDate,
    DateTime? endDate,
  });
}
