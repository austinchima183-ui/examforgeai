import 'package:equatable/equatable.dart';

import '../../../question_bank/domain/entities/question_entities.dart';


// ═══════════════════════════════════════════════════════════════════════
// ENUMS
// ═══════════════════════════════════════════════════════════════════════

/// Represents the lifecycle status of an exam.
enum ExamStatus {
  draft(
    value: 'draft',
    label: 'Draft',
    color: '#9CA3AF',
    isEditable: true,
  ),
  published(
    value: 'published',
    label: 'Published',
    color: '#3B82F6',
    isEditable: false,
  ),
  active(
    value: 'active',
    label: 'Active',
    color: '#22C55E',
    isEditable: false,
  ),
  completed(
    value: 'completed',
    label: 'Completed',
    color: '#6366F1',
    isEditable: false,
  ),
  archived(
    value: 'archived',
    label: 'Archived',
    color: '#78716C',
    isEditable: false,
  ),
  cancelled(
    value: 'cancelled',
    label: 'Cancelled',
    color: '#EF4444',
    isEditable: false,
  );

  const ExamStatus({
    required this.value,
    required this.label,
    required this.color,
    required this.isEditable,
  });

  /// The string representation stored in the backend.
  final String value;

  /// Human-readable label for display in the UI.
  final String label;

  /// Hex color string for UI rendering.
  final String color;

  /// Whether the exam can still be edited in this status.
  final bool isEditable;

  /// Parses a raw [value] string into an [ExamStatus].
  ///
  /// Returns `null` if the value does not match any known status.
  static ExamStatus? fromString(String? value) {
    if (value == null) return null;
    return ExamStatus.values.cast<ExamStatus?>().firstWhere(
          (status) => status?.value == value,
          orElse: () => null,
        );
  }
}

/// Represents the status of a student's exam attempt.
enum AttemptStatus {
  notStarted(
    value: 'not_started',
    label: 'Not Started',
    isTerminal: false,
    isActive: false,
  ),
  inProgress(
    value: 'in_progress',
    label: 'In Progress',
    isTerminal: false,
    isActive: true,
  ),
  submitted(
    value: 'submitted',
    label: 'Submitted',
    isTerminal: true,
    isActive: false,
  ),
  autoSubmitted(
    value: 'auto_submitted',
    label: 'Auto Submitted',
    isTerminal: true,
    isActive: false,
  ),
  timedOut(
    value: 'timed_out',
    label: 'Timed Out',
    isTerminal: true,
    isActive: false,
  ),
  disqualified(
    value: 'disqualified',
    label: 'Disqualified',
    isTerminal: true,
    isActive: false,
  ),
  abandoned(
    value: 'abandoned',
    label: 'Abandoned',
    isTerminal: true,
    isActive: false,
  );

  const AttemptStatus({
    required this.value,
    required this.label,
    required this.isTerminal,
    required this.isActive,
  });

  /// The string representation stored in the backend.
  final String value;

  /// Human-readable label for display in the UI.
  final String label;

  /// Whether this status represents a final, non-transitionable state.
  final bool isTerminal;

  /// Whether the attempt is currently active (student is taking the exam).
  final bool isActive;

  /// Parses a raw [value] string into an [AttemptStatus].
  ///
  /// Returns `null` if the value does not match any known status.
  static AttemptStatus? fromString(String? value) {
    if (value == null) return null;
    return AttemptStatus.values.cast<AttemptStatus?>().firstWhere(
          (status) => status?.value == value,
          orElse: () => null,
        );
  }
}

/// Represents how an exam attempt was submitted.
enum SubmissionType {
  manual(
    value: 'manual',
    label: 'Manual Submit',
  ),
  autoSubmit(
    value: 'auto_submit',
    label: 'Auto Submit',
  ),
  timedOut(
    value: 'timed_out',
    label: 'Timed Out',
  ),
  forceSubmit(
    value: 'force_submit',
    label: 'Force Submit',
  );

  const SubmissionType({
    required this.value,
    required this.label,
  });

  /// The string representation stored in the backend.
  final String value;

  /// Human-readable label for display in the UI.
  final String label;

  /// Parses a raw [value] string into a [SubmissionType].
  ///
  /// Returns `null` if the value does not match any known type.
  static SubmissionType? fromString(String? value) {
    if (value == null) return null;
    return SubmissionType.values.cast<SubmissionType?>().firstWhere(
          (type) => type?.value == value,
          orElse: () => null,
        );
  }
}

/// Represents the grading status of an exam attempt.
enum GradingStatus {
  pending(
    value: 'pending',
    label: 'Pending',
    isComplete: false,
  ),
  autoGraded(
    value: 'auto_graded',
    label: 'Auto Graded',
    isComplete: true,
  ),
  partiallyGraded(
    value: 'partially_graded',
    label: 'Partially Graded',
    isComplete: false,
  ),
  fullyGraded(
    value: 'fully_graded',
    label: 'Fully Graded',
    isComplete: true,
  ),
  disputed(
    value: 'disputed',
    label: 'Disputed',
    isComplete: false,
  );

  const GradingStatus({
    required this.value,
    required this.label,
    required this.isComplete,
  });

  /// The string representation stored in the backend.
  final String value;

  /// Human-readable label for display in the UI.
  final String label;

  /// Whether the grading process is considered complete.
  final bool isComplete;

  /// Parses a raw [value] string into a [GradingStatus].
  ///
  /// Returns `null` if the value does not match any known status.
  static GradingStatus? fromString(String? value) {
    if (value == null) return null;
    return GradingStatus.values.cast<GradingStatus?>().firstWhere(
          (status) => status?.value == value,
          orElse: () => null,
        );
  }
}

/// Represents the type of a monitoring event during an exam.
enum MonitoringEventType {
  tabSwitch(
    value: 'tab_switch',
    label: 'Tab Switch',
    severity: 'warning',
    icon: 'tab_switch',
  ),
  focusLost(
    value: 'focus_lost',
    label: 'Focus Lost',
    severity: 'warning',
    icon: 'eye_off',
  ),
  copyAttempt(
    value: 'copy_attempt',
    label: 'Copy Attempt',
    severity: 'critical',
    icon: 'copy',
  ),
  pasteAttempt(
    value: 'paste_attempt',
    label: 'Paste Attempt',
    severity: 'critical',
    icon: 'clipboard_paste',
  ),
  multipleLogin(
    value: 'multiple_login',
    label: 'Multiple Login',
    severity: 'critical',
    icon: 'users',
  ),
  idleTimeout(
    value: 'idle_timeout',
    label: 'Idle Timeout',
    severity: 'warning',
    icon: 'clock',
  ),
  browserResize(
    value: 'browser_resize',
    label: 'Browser Resize',
    severity: 'info',
    icon: 'maximize',
  ),
  rightClick(
    value: 'right_click',
    label: 'Right Click',
    severity: 'warning',
    icon: 'mouse_pointer_click',
  ),
  screenshotAttempt(
    value: 'screenshot_attempt',
    label: 'Screenshot Attempt',
    severity: 'critical',
    icon: 'camera',
  ),
  fullScreenExit(
    value: 'full_screen_exit',
    label: 'Full Screen Exit',
    severity: 'warning',
    icon: 'minimize',
  ),
  sessionRecovery(
    value: 'session_recovery',
    label: 'Session Recovery',
    severity: 'info',
    icon: 'refresh_cw',
  ),
  suspiciousActivity(
    value: 'suspicious_activity',
    label: 'Suspicious Activity',
    severity: 'critical',
    icon: 'alert_triangle',
  );

  const MonitoringEventType({
    required this.value,
    required this.label,
    required this.severity,
    required this.icon,
  });

  /// The string representation stored in the backend.
  final String value;

  /// Human-readable label for display in the UI.
  final String label;

  /// Severity level: 'info', 'warning', or 'critical'.
  final String severity;

  /// Icon identifier for UI rendering.
  final String icon;

  /// Parses a raw [value] string into a [MonitoringEventType].
  ///
  /// Returns `null` if the value does not match any known type.
  static MonitoringEventType? fromString(String? value) {
    if (value == null) return null;
    return MonitoringEventType.values.cast<MonitoringEventType?>().firstWhere(
          (type) => type?.value == value,
          orElse: () => null,
        );
  }
}

/// Represents the category of an exam notification.
enum NotificationCategory {
  examAvailable(
    value: 'exam_available',
    label: 'Exam Available',
  ),
  examStarting(
    value: 'exam_starting',
    label: 'Exam Starting',
  ),
  timeWarning(
    value: 'time_warning',
    label: 'Time Warning',
  ),
  examSubmitted(
    value: 'exam_submitted',
    label: 'Exam Submitted',
  ),
  resultsReleased(
    value: 'results_released',
    label: 'Results Released',
  ),
  gradingRequired(
    value: 'grading_required',
    label: 'Grading Required',
  ),
  examReminder(
    value: 'exam_reminder',
    label: 'Exam Reminder',
  );

  const NotificationCategory({
    required this.value,
    required this.label,
  });

  /// The string representation stored in the backend.
  final String value;

  /// Human-readable label for display in the UI.
  final String label;

  /// Parses a raw [value] string into a [NotificationCategory].
  ///
  /// Returns `null` if the value does not match any known category.
  static NotificationCategory? fromString(String? value) {
    if (value == null) return null;
    return NotificationCategory.values
        .cast<NotificationCategory?>()
        .firstWhere(
          (cat) => cat?.value == value,
          orElse: () => null,
        );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// ENTITY CLASSES
// ═══════════════════════════════════════════════════════════════════════

/// Represents a section within an exam.
///
/// Exams can be divided into sections (e.g., Section A - Objective,
/// Section B - Theory) each with its own instructions and optional
/// time limits.
class ExamSectionEntity extends Equatable {
  const ExamSectionEntity({
    required this.id,
    required this.examId,
    required this.title,
    this.description,
    this.instructions,
    required this.sortOrder,
    this.timeLimitMinutes,
    this.randomizeQuestions = false,
    required this.createdAt,
  });

  final String id;
  final String examId;
  final String title;
  final String? description;
  final String? instructions;
  final int sortOrder;
  final int? timeLimitMinutes;
  final bool randomizeQuestions;
  final DateTime createdAt;

  ExamSectionEntity copyWith({
    String? id,
    String? examId,
    String? title,
    String? description,
    String? instructions,
    int? sortOrder,
    int? timeLimitMinutes,
    bool? randomizeQuestions,
    DateTime? createdAt,
  }) {
    return ExamSectionEntity(
      id: id ?? this.id,
      examId: examId ?? this.examId,
      title: title ?? this.title,
      description: description ?? this.description,
      instructions: instructions ?? this.instructions,
      sortOrder: sortOrder ?? this.sortOrder,
      timeLimitMinutes: timeLimitMinutes ?? this.timeLimitMinutes,
      randomizeQuestions: randomizeQuestions ?? this.randomizeQuestions,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        examId,
        title,
        description,
        instructions,
        sortOrder,
        timeLimitMinutes,
        randomizeQuestions,
        createdAt,
      ];
}

/// Represents a question linked to an exam, with exam-specific overrides
/// for marks and ordering.
class ExamQuestionEntity extends Equatable {
  const ExamQuestionEntity({
    required this.id,
    required this.examId,
    this.sectionId,
    required this.questionId,
    required this.sortOrder,
    required this.marks,
    this.negativeMarks = 0.0,
    this.isCompulsory = true,
    this.question,
    required this.createdAt,
  });

  final String id;
  final String examId;
  final String? sectionId;
  final String questionId;
  final int sortOrder;
  final double marks;
  final double negativeMarks;
  final bool isCompulsory;

  /// The full question entity, loaded when [withDetails] is requested.
  final QuestionEntity? question;

  final DateTime createdAt;

  ExamQuestionEntity copyWith({
    String? id,
    String? examId,
    String? sectionId,
    String? questionId,
    int? sortOrder,
    double? marks,
    double? negativeMarks,
    bool? isCompulsory,
    QuestionEntity? question,
    DateTime? createdAt,
  }) {
    return ExamQuestionEntity(
      id: id ?? this.id,
      examId: examId ?? this.examId,
      sectionId: sectionId ?? this.sectionId,
      questionId: questionId ?? this.questionId,
      sortOrder: sortOrder ?? this.sortOrder,
      marks: marks ?? this.marks,
      negativeMarks: negativeMarks ?? this.negativeMarks,
      isCompulsory: isCompulsory ?? this.isCompulsory,
      question: question ?? this.question,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        examId,
        sectionId,
        questionId,
        sortOrder,
        marks,
        negativeMarks,
        isCompulsory,
        question,
        createdAt,
      ];
}

/// Represents a student assigned to an exam with per-student overrides.
class ExamStudentEntity extends Equatable {
  const ExamStudentEntity({
    required this.id,
    required this.examId,
    required this.studentId,
    this.allowedAttempts,
    this.extraTimeMinutes = 0,
    this.isExempt = false,
    this.startedAt,
    this.completedAt,
    required this.createdAt,
  });

  final String id;
  final String examId;
  final String studentId;
  final int? allowedAttempts;
  final int extraTimeMinutes;
  final bool isExempt;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final DateTime createdAt;

  ExamStudentEntity copyWith({
    String? id,
    String? examId,
    String? studentId,
    int? allowedAttempts,
    int? extraTimeMinutes,
    bool? isExempt,
    DateTime? startedAt,
    DateTime? completedAt,
    DateTime? createdAt,
  }) {
    return ExamStudentEntity(
      id: id ?? this.id,
      examId: examId ?? this.examId,
      studentId: studentId ?? this.studentId,
      allowedAttempts: allowedAttempts ?? this.allowedAttempts,
      extraTimeMinutes: extraTimeMinutes ?? this.extraTimeMinutes,
      isExempt: isExempt ?? this.isExempt,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        examId,
        studentId,
        allowedAttempts,
        extraTimeMinutes,
        isExempt,
        startedAt,
        completedAt,
        createdAt,
      ];
}

/// Represents a single answer submitted by a student during an exam attempt.
class StudentAnswerEntity extends Equatable {
  const StudentAnswerEntity({
    required this.id,
    required this.attemptId,
    required this.questionId,
    this.examQuestionId,
    required this.answerData,
    this.isCorrect,
    this.marksAwarded = 0.0,
    this.marksDeducted = 0.0,
    this.timeSpentSeconds = 0,
    this.isFlagged = false,
    this.teacherComment,
    this.gradedBy,
    this.gradedAt,
    this.answeredAt,
    this.updatedAt,
  });

  final String id;
  final String attemptId;
  final String questionId;
  final String? examQuestionId;

  /// Flexible answer payload that accommodates all question types.
  ///
  /// For multiple choice: `{'selected_option_id': 'abc123'}`
  /// For multiple response: `{'selected_option_ids': ['abc123', 'def456']}`
  /// For fill-in-blank: `{'blanks': [{'index': 0, 'answer': 'photosynthesis'}]}`
  /// For matching: `{'pairs': [{'left_id': 'l1', 'right_id': 'r2'}]}`
  /// For ordering: `{'ordered_ids': ['q1', 'q3', 'q2']}`
  /// For essay/short answer: `{'text': 'Student response...'}`
  /// For numerical: `{'value': 42.5}`
  final Map<String, dynamic> answerData;

  final bool? isCorrect;
  final double marksAwarded;
  final double marksDeducted;
  final int timeSpentSeconds;
  final bool isFlagged;
  final String? teacherComment;
  final String? gradedBy;
  final DateTime? gradedAt;
  final DateTime? answeredAt;
  final DateTime? updatedAt;

  StudentAnswerEntity copyWith({
    String? id,
    String? attemptId,
    String? questionId,
    String? examQuestionId,
    Map<String, dynamic>? answerData,
    bool? isCorrect,
    double? marksAwarded,
    double? marksDeducted,
    int? timeSpentSeconds,
    bool? isFlagged,
    String? teacherComment,
    String? gradedBy,
    DateTime? gradedAt,
    DateTime? answeredAt,
    DateTime? updatedAt,
  }) {
    return StudentAnswerEntity(
      id: id ?? this.id,
      attemptId: attemptId ?? this.attemptId,
      questionId: questionId ?? this.questionId,
      examQuestionId: examQuestionId ?? this.examQuestionId,
      answerData: answerData ?? this.answerData,
      isCorrect: isCorrect ?? this.isCorrect,
      marksAwarded: marksAwarded ?? this.marksAwarded,
      marksDeducted: marksDeducted ?? this.marksDeducted,
      timeSpentSeconds: timeSpentSeconds ?? this.timeSpentSeconds,
      isFlagged: isFlagged ?? this.isFlagged,
      teacherComment: teacherComment ?? this.teacherComment,
      gradedBy: gradedBy ?? this.gradedBy,
      gradedAt: gradedAt ?? this.gradedAt,
      answeredAt: answeredAt ?? this.answeredAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        attemptId,
        questionId,
        examQuestionId,
        answerData,
        isCorrect,
        marksAwarded,
        marksDeducted,
        timeSpentSeconds,
        isFlagged,
        teacherComment,
        gradedBy,
        gradedAt,
        answeredAt,
        updatedAt,
      ];
}

/// Represents a student's attempt at an exam.
class ExamAttemptEntity extends Equatable {
  const ExamAttemptEntity({
    required this.id,
    required this.examId,
    required this.studentId,
    required this.attemptNumber,
    required this.status,
    required this.startedAt,
    this.submittedAt,
    this.submissionType,
    this.timeSpentSeconds = 0,
    this.totalMarks = 0.0,
    this.scorePercentage = 0.0,
    this.isPassed = false,
    required this.gradingStatus,
    this.gradedBy,
    this.gradedAt,
    this.deviceInfo,
    this.ipAddress,
    this.userAgent,
    this.lastActivityAt,
    this.autoSaveData,
    this.metadata,
    this.answers = const [],
    this.exam,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String examId;
  final String studentId;
  final int attemptNumber;
  final AttemptStatus status;
  final DateTime startedAt;
  final DateTime? submittedAt;
  final SubmissionType? submissionType;
  final int timeSpentSeconds;
  final double totalMarks;
  final double scorePercentage;
  final bool isPassed;
  final GradingStatus gradingStatus;
  final String? gradedBy;
  final DateTime? gradedAt;
  final Map<String, dynamic>? deviceInfo;
  final String? ipAddress;
  final String? userAgent;
  final DateTime? lastActivityAt;
  final Map<String, dynamic>? autoSaveData;
  final Map<String, dynamic>? metadata;

  /// All answers submitted in this attempt, loaded when [withAnswers] is
  /// requested.
  final List<StudentAnswerEntity> answers;

  /// The parent exam entity, loaded for display purposes.
  final ExamEntity? exam;

  final DateTime createdAt;
  final DateTime updatedAt;

  ExamAttemptEntity copyWith({
    String? id,
    String? examId,
    String? studentId,
    int? attemptNumber,
    AttemptStatus? status,
    DateTime? startedAt,
    DateTime? submittedAt,
    SubmissionType? submissionType,
    int? timeSpentSeconds,
    double? totalMarks,
    double? scorePercentage,
    bool? isPassed,
    GradingStatus? gradingStatus,
    String? gradedBy,
    DateTime? gradedAt,
    Map<String, dynamic>? deviceInfo,
    String? ipAddress,
    String? userAgent,
    DateTime? lastActivityAt,
    Map<String, dynamic>? autoSaveData,
    Map<String, dynamic>? metadata,
    List<StudentAnswerEntity>? answers,
    ExamEntity? exam,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ExamAttemptEntity(
      id: id ?? this.id,
      examId: examId ?? this.examId,
      studentId: studentId ?? this.studentId,
      attemptNumber: attemptNumber ?? this.attemptNumber,
      status: status ?? this.status,
      startedAt: startedAt ?? this.startedAt,
      submittedAt: submittedAt ?? this.submittedAt,
      submissionType: submissionType ?? this.submissionType,
      timeSpentSeconds: timeSpentSeconds ?? this.timeSpentSeconds,
      totalMarks: totalMarks ?? this.totalMarks,
      scorePercentage: scorePercentage ?? this.scorePercentage,
      isPassed: isPassed ?? this.isPassed,
      gradingStatus: gradingStatus ?? this.gradingStatus,
      gradedBy: gradedBy ?? this.gradedBy,
      gradedAt: gradedAt ?? this.gradedAt,
      deviceInfo: deviceInfo ?? this.deviceInfo,
      ipAddress: ipAddress ?? this.ipAddress,
      userAgent: userAgent ?? this.userAgent,
      lastActivityAt: lastActivityAt ?? this.lastActivityAt,
      autoSaveData: autoSaveData ?? this.autoSaveData,
      metadata: metadata ?? this.metadata,
      answers: answers ?? this.answers,
      exam: exam ?? this.exam,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        examId,
        studentId,
        attemptNumber,
        status,
        startedAt,
        submittedAt,
        submissionType,
        timeSpentSeconds,
        totalMarks,
        scorePercentage,
        isPassed,
        gradingStatus,
        gradedBy,
        gradedAt,
        deviceInfo,
        ipAddress,
        userAgent,
        lastActivityAt,
        autoSaveData,
        metadata,
        answers,
        exam,
        createdAt,
        updatedAt,
      ];
}

/// Represents a real-time session for an active exam attempt.
///
/// This entity is updated frequently via WebSocket/Supabase Realtime
/// and is used for live monitoring dashboards.
class ExamSessionEntity extends Equatable {
  const ExamSessionEntity({
    required this.id,
    required this.attemptId,
    required this.examId,
    required this.studentId,
    this.isActive = true,
    this.currentQuestionIndex = 0,
    this.questionsAnswered = 0,
    this.questionsFlagged = 0,
    required this.lastHeartbeat,
    this.connectionStatus = 'connected',
    this.ipAddress,
    this.deviceFingerprint,
    this.tabSwitchCount = 0,
    this.focusLostCount = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String attemptId;
  final String examId;
  final String studentId;
  final bool isActive;
  final int currentQuestionIndex;
  final int questionsAnswered;
  final int questionsFlagged;
  final DateTime lastHeartbeat;

  /// One of: 'connected', 'disconnected', 'reconnecting'.
  final String connectionStatus;
  final String? ipAddress;
  final String? deviceFingerprint;
  final int tabSwitchCount;
  final int focusLostCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  ExamSessionEntity copyWith({
    String? id,
    String? attemptId,
    String? examId,
    String? studentId,
    bool? isActive,
    int? currentQuestionIndex,
    int? questionsAnswered,
    int? questionsFlagged,
    DateTime? lastHeartbeat,
    String? connectionStatus,
    String? ipAddress,
    String? deviceFingerprint,
    int? tabSwitchCount,
    int? focusLostCount,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ExamSessionEntity(
      id: id ?? this.id,
      attemptId: attemptId ?? this.attemptId,
      examId: examId ?? this.examId,
      studentId: studentId ?? this.studentId,
      isActive: isActive ?? this.isActive,
      currentQuestionIndex: currentQuestionIndex ?? this.currentQuestionIndex,
      questionsAnswered: questionsAnswered ?? this.questionsAnswered,
      questionsFlagged: questionsFlagged ?? this.questionsFlagged,
      lastHeartbeat: lastHeartbeat ?? this.lastHeartbeat,
      connectionStatus: connectionStatus ?? this.connectionStatus,
      ipAddress: ipAddress ?? this.ipAddress,
      deviceFingerprint: deviceFingerprint ?? this.deviceFingerprint,
      tabSwitchCount: tabSwitchCount ?? this.tabSwitchCount,
      focusLostCount: focusLostCount ?? this.focusLostCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        attemptId,
        examId,
        studentId,
        isActive,
        currentQuestionIndex,
        questionsAnswered,
        questionsFlagged,
        lastHeartbeat,
        connectionStatus,
        ipAddress,
        deviceFingerprint,
        tabSwitchCount,
        focusLostCount,
        createdAt,
        updatedAt,
      ];
}

/// Represents a monitoring event logged during an exam attempt.
///
/// Used for anti-cheating detection and audit trails.
class MonitoringLogEntity extends Equatable {
  const MonitoringLogEntity({
    required this.id,
    required this.attemptId,
    required this.examId,
    required this.studentId,
    required this.eventType,
    this.eventData,
    required this.severity,
    this.isResolved = false,
    this.resolvedBy,
    this.resolvedAt,
    required this.createdAt,
  });

  final String id;
  final String attemptId;
  final String examId;
  final String studentId;
  final MonitoringEventType eventType;
  final Map<String, dynamic>? eventData;

  /// One of: 'info', 'warning', 'critical'.
  final String severity;
  final bool isResolved;
  final String? resolvedBy;
  final DateTime? resolvedAt;
  final DateTime createdAt;

  MonitoringLogEntity copyWith({
    String? id,
    String? attemptId,
    String? examId,
    String? studentId,
    MonitoringEventType? eventType,
    Map<String, dynamic>? eventData,
    String? severity,
    bool? isResolved,
    String? resolvedBy,
    DateTime? resolvedAt,
    DateTime? createdAt,
  }) {
    return MonitoringLogEntity(
      id: id ?? this.id,
      attemptId: attemptId ?? this.attemptId,
      examId: examId ?? this.examId,
      studentId: studentId ?? this.studentId,
      eventType: eventType ?? this.eventType,
      eventData: eventData ?? this.eventData,
      severity: severity ?? this.severity,
      isResolved: isResolved ?? this.isResolved,
      resolvedBy: resolvedBy ?? this.resolvedBy,
      resolvedAt: resolvedAt ?? this.resolvedAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        attemptId,
        examId,
        studentId,
        eventType,
        eventData,
        severity,
        isResolved,
        resolvedBy,
        resolvedAt,
        createdAt,
      ];
}

/// Represents the computed result for a student's exam attempt.
class ExamResultEntity extends Equatable {
  const ExamResultEntity({
    required this.id,
    required this.examId,
    required this.studentId,
    required this.attemptId,
    required this.totalMarks,
    required this.totalPossible,
    required this.scorePercentage,
    this.grade,
    required this.isPassed,
    this.rank,
    this.subjectAverage,
    required this.timeSpentSeconds,
    required this.gradingStatus,
    this.releasedAt,
    this.isReleased = false,
    this.metadata,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String examId;
  final String studentId;
  final String attemptId;
  final double totalMarks;
  final double totalPossible;
  final double scorePercentage;
  final String? grade;
  final bool isPassed;
  final int? rank;
  final double? subjectAverage;
  final int timeSpentSeconds;
  final GradingStatus gradingStatus;
  final DateTime? releasedAt;
  final bool isReleased;
  final Map<String, dynamic>? metadata;
  final DateTime createdAt;
  final DateTime updatedAt;

  ExamResultEntity copyWith({
    String? id,
    String? examId,
    String? studentId,
    String? attemptId,
    double? totalMarks,
    double? totalPossible,
    double? scorePercentage,
    String? grade,
    bool? isPassed,
    int? rank,
    double? subjectAverage,
    int? timeSpentSeconds,
    GradingStatus? gradingStatus,
    DateTime? releasedAt,
    bool? isReleased,
    Map<String, dynamic>? metadata,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ExamResultEntity(
      id: id ?? this.id,
      examId: examId ?? this.examId,
      studentId: studentId ?? this.studentId,
      attemptId: attemptId ?? this.attemptId,
      totalMarks: totalMarks ?? this.totalMarks,
      totalPossible: totalPossible ?? this.totalPossible,
      scorePercentage: scorePercentage ?? this.scorePercentage,
      grade: grade ?? this.grade,
      isPassed: isPassed ?? this.isPassed,
      rank: rank ?? this.rank,
      subjectAverage: subjectAverage ?? this.subjectAverage,
      timeSpentSeconds: timeSpentSeconds ?? this.timeSpentSeconds,
      gradingStatus: gradingStatus ?? this.gradingStatus,
      releasedAt: releasedAt ?? this.releasedAt,
      isReleased: isReleased ?? this.isReleased,
      metadata: metadata ?? this.metadata,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        examId,
        studentId,
        attemptId,
        totalMarks,
        totalPossible,
        scorePercentage,
        grade,
        isPassed,
        rank,
        subjectAverage,
        timeSpentSeconds,
        gradingStatus,
        releasedAt,
        isReleased,
        metadata,
        createdAt,
        updatedAt,
      ];
}

/// Represents a student's ranking in an exam leaderboard.
class ExamRankingEntity extends Equatable {
  const ExamRankingEntity({
    required this.id,
    required this.examId,
    required this.studentId,
    required this.attemptId,
    required this.rank,
    required this.totalMarks,
    required this.scorePercentage,
    required this.createdAt,
  });

  final String id;
  final String examId;
  final String studentId;
  final String attemptId;
  final int rank;
  final double totalMarks;
  final double scorePercentage;
  final DateTime createdAt;

  ExamRankingEntity copyWith({
    String? id,
    String? examId,
    String? studentId,
    String? attemptId,
    int? rank,
    double? totalMarks,
    double? scorePercentage,
    DateTime? createdAt,
  }) {
    return ExamRankingEntity(
      id: id ?? this.id,
      examId: examId ?? this.examId,
      studentId: studentId ?? this.studentId,
      attemptId: attemptId ?? this.attemptId,
      rank: rank ?? this.rank,
      totalMarks: totalMarks ?? this.totalMarks,
      scorePercentage: scorePercentage ?? this.scorePercentage,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        examId,
        studentId,
        attemptId,
        rank,
        totalMarks,
        scorePercentage,
        createdAt,
      ];
}

/// Represents a notification related to an exam.
class ExamNotificationEntity extends Equatable {
  const ExamNotificationEntity({
    required this.id,
    this.examId,
    this.studentId,
    required this.category,
    required this.title,
    required this.message,
    this.data,
    this.isRead = false,
    this.readAt,
    this.scheduledFor,
    this.sentAt,
    required this.createdAt,
  });

  final String id;
  final String? examId;
  final String? studentId;
  final NotificationCategory category;
  final String title;
  final String message;
  final Map<String, dynamic>? data;
  final bool isRead;
  final DateTime? readAt;
  final DateTime? scheduledFor;
  final DateTime? sentAt;
  final DateTime createdAt;

  ExamNotificationEntity copyWith({
    String? id,
    String? examId,
    String? studentId,
    NotificationCategory? category,
    String? title,
    String? message,
    Map<String, dynamic>? data,
    bool? isRead,
    DateTime? readAt,
    DateTime? scheduledFor,
    DateTime? sentAt,
    DateTime? createdAt,
  }) {
    return ExamNotificationEntity(
      id: id ?? this.id,
      examId: examId ?? this.examId,
      studentId: studentId ?? this.studentId,
      category: category ?? this.category,
      title: title ?? this.title,
      message: message ?? this.message,
      data: data ?? this.data,
      isRead: isRead ?? this.isRead,
      readAt: readAt ?? this.readAt,
      scheduledFor: scheduledFor ?? this.scheduledFor,
      sentAt: sentAt ?? this.sentAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        examId,
        studentId,
        category,
        title,
        message,
        data,
        isRead,
        readAt,
        scheduledFor,
        sentAt,
        createdAt,
      ];
}

/// Represents a single entry in a grade scale (e.g., A: 70-100, B: 60-69).
class GradeScaleEntry extends Equatable {
  const GradeScaleEntry({
    required this.minPercentage,
    required this.maxPercentage,
    required this.grade,
    this.description,
    required this.isPassing,
  });

  final double minPercentage;
  final double maxPercentage;
  final String grade;
  final String? description;
  final bool isPassing;

  GradeScaleEntry copyWith({
    double? minPercentage,
    double? maxPercentage,
    String? grade,
    String? description,
    bool? isPassing,
  }) {
    return GradeScaleEntry(
      minPercentage: minPercentage ?? this.minPercentage,
      maxPercentage: maxPercentage ?? this.maxPercentage,
      grade: grade ?? this.grade,
      description: description ?? this.description,
      isPassing: isPassing ?? this.isPassing,
    );
  }

  @override
  List<Object?> get props => [
        minPercentage,
        maxPercentage,
        grade,
        description,
        isPassing,
      ];
}

/// Represents a grading scale used to convert percentage scores to letter
/// grades.
class GradeScaleEntity extends Equatable {
  const GradeScaleEntity({
    required this.id,
    required this.schoolId,
    required this.name,
    this.isDefault = false,
    this.scaleEntries = const [],
    this.createdBy,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String schoolId;
  final String name;
  final bool isDefault;
  final List<GradeScaleEntry> scaleEntries;
  final String? createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  GradeScaleEntity copyWith({
    String? id,
    String? schoolId,
    String? name,
    bool? isDefault,
    List<GradeScaleEntry>? scaleEntries,
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return GradeScaleEntity(
      id: id ?? this.id,
      schoolId: schoolId ?? this.schoolId,
      name: name ?? this.name,
      isDefault: isDefault ?? this.isDefault,
      scaleEntries: scaleEntries ?? this.scaleEntries,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        schoolId,
        name,
        isDefault,
        scaleEntries,
        createdBy,
        createdAt,
        updatedAt,
      ];
}

/// THE MAIN EXAM entity representing a computer-based test.
///
/// Contains all configuration for exam delivery including timing, security,
/// randomization, result visibility, and relations to sections, questions,
/// and student assignments.
class ExamEntity extends Equatable {
  const ExamEntity({
    required this.id,
    required this.schoolId,
    required this.createdBy,
    required this.title,
    this.description,
    required this.subjectId,
    required this.classId,
    required this.academicSessionId,
    required this.examType,
    required this.status,
    required this.startTime,
    required this.endTime,
    required this.timeLimitMinutes,
    required this.totalMarks,
    required this.passMark,
    this.passMarkType = 'percentage',
    this.instructions,
    this.allowedAttempts = 1,
    this.negativeMarkingEnabled = false,
    this.negativeMarkValue = 0.0,
    this.gracePeriodMinutes = 0,
    this.autoSubmit = true,
    this.randomizeQuestions = false,
    this.randomizeOptions = false,
    this.showResults = 'after_submission',
    this.showCorrectAnswers = false,
    this.showExplanations = false,
    this.isTemplate = false,
    this.templateId,
    this.maxStudents,
    this.ipRestriction,
    this.requireFullScreen = false,
    this.allowResume = true,
    this.browserLockdown = false,
    this.metadata,
    this.publishedAt,
    this.sections = const [],
    this.questions = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  // ── Identifiers ─────────────────────────────────────────────────────
  final String id;
  final String schoolId;
  final String createdBy;

  // ── Content ─────────────────────────────────────────────────────────
  final String title;
  final String? description;

  // ── Classification ──────────────────────────────────────────────────
  final String subjectId;
  final String classId;
  final String academicSessionId;
  final ExamType examType;
  final ExamStatus status;

  // ── Scheduling ──────────────────────────────────────────────────────
  final DateTime startTime;
  final DateTime endTime;
  final int timeLimitMinutes;

  // ── Scoring ─────────────────────────────────────────────────────────
  final double totalMarks;
  final double passMark;

  /// Either 'percentage' or 'absolute'.
  final String passMarkType;

  // ── Instructions ────────────────────────────────────────────────────
  final String? instructions;

  // ── Attempt Rules ───────────────────────────────────────────────────
  final int allowedAttempts;

  // ── Negative Marking ────────────────────────────────────────────────
  final bool negativeMarkingEnabled;
  final double negativeMarkValue;

  // ── Timing ──────────────────────────────────────────────────────────
  final int gracePeriodMinutes;
  final bool autoSubmit;

  // ── Randomization ───────────────────────────────────────────────────
  final bool randomizeQuestions;
  final bool randomizeOptions;

  // ── Result Visibility ───────────────────────────────────────────────
  /// One of: 'immediate', 'after_submission', 'after_grading', 'manual'.
  final String showResults;
  final bool showCorrectAnswers;
  final bool showExplanations;

  // ── Template ────────────────────────────────────────────────────────
  final bool isTemplate;
  final String? templateId;

  // ── Capacity & Access ───────────────────────────────────────────────
  final int? maxStudents;
  final List<String>? ipRestriction;

  // ── Security ────────────────────────────────────────────────────────
  final bool requireFullScreen;
  final bool allowResume;
  final bool browserLockdown;

  // ── Extensibility ───────────────────────────────────────────────────
  final Map<String, dynamic>? metadata;
  final DateTime? publishedAt;

  // ── Relations ───────────────────────────────────────────────────────
  final List<ExamSectionEntity> sections;
  final List<ExamQuestionEntity> questions;

  // ── Timestamps ──────────────────────────────────────────────────────
  final DateTime createdAt;
  final DateTime updatedAt;

  ExamEntity copyWith({
    String? id,
    String? schoolId,
    String? createdBy,
    String? title,
    String? description,
    String? subjectId,
    String? classId,
    String? academicSessionId,
    ExamType? examType,
    ExamStatus? status,
    DateTime? startTime,
    DateTime? endTime,
    int? timeLimitMinutes,
    double? totalMarks,
    double? passMark,
    String? passMarkType,
    String? instructions,
    int? allowedAttempts,
    bool? negativeMarkingEnabled,
    double? negativeMarkValue,
    int? gracePeriodMinutes,
    bool? autoSubmit,
    bool? randomizeQuestions,
    bool? randomizeOptions,
    String? showResults,
    bool? showCorrectAnswers,
    bool? showExplanations,
    bool? isTemplate,
    String? templateId,
    int? maxStudents,
    List<String>? ipRestriction,
    bool? requireFullScreen,
    bool? allowResume,
    bool? browserLockdown,
    Map<String, dynamic>? metadata,
    DateTime? publishedAt,
    List<ExamSectionEntity>? sections,
    List<ExamQuestionEntity>? questions,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ExamEntity(
      id: id ?? this.id,
      schoolId: schoolId ?? this.schoolId,
      createdBy: createdBy ?? this.createdBy,
      title: title ?? this.title,
      description: description ?? this.description,
      subjectId: subjectId ?? this.subjectId,
      classId: classId ?? this.classId,
      academicSessionId: academicSessionId ?? this.academicSessionId,
      examType: examType ?? this.examType,
      status: status ?? this.status,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      timeLimitMinutes: timeLimitMinutes ?? this.timeLimitMinutes,
      totalMarks: totalMarks ?? this.totalMarks,
      passMark: passMark ?? this.passMark,
      passMarkType: passMarkType ?? this.passMarkType,
      instructions: instructions ?? this.instructions,
      allowedAttempts: allowedAttempts ?? this.allowedAttempts,
      negativeMarkingEnabled:
          negativeMarkingEnabled ?? this.negativeMarkingEnabled,
      negativeMarkValue: negativeMarkValue ?? this.negativeMarkValue,
      gracePeriodMinutes: gracePeriodMinutes ?? this.gracePeriodMinutes,
      autoSubmit: autoSubmit ?? this.autoSubmit,
      randomizeQuestions: randomizeQuestions ?? this.randomizeQuestions,
      randomizeOptions: randomizeOptions ?? this.randomizeOptions,
      showResults: showResults ?? this.showResults,
      showCorrectAnswers: showCorrectAnswers ?? this.showCorrectAnswers,
      showExplanations: showExplanations ?? this.showExplanations,
      isTemplate: isTemplate ?? this.isTemplate,
      templateId: templateId ?? this.templateId,
      maxStudents: maxStudents ?? this.maxStudents,
      ipRestriction: ipRestriction ?? this.ipRestriction,
      requireFullScreen: requireFullScreen ?? this.requireFullScreen,
      allowResume: allowResume ?? this.allowResume,
      browserLockdown: browserLockdown ?? this.browserLockdown,
      metadata: metadata ?? this.metadata,
      publishedAt: publishedAt ?? this.publishedAt,
      sections: sections ?? this.sections,
      questions: questions ?? this.questions,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Convenience getter to compute the effective pass mark based on
  /// [passMarkType].
  ///
  /// If [passMarkType] is 'percentage', the pass mark is computed as
  /// a percentage of [totalMarks]. Otherwise, [passMark] is treated
  /// as an absolute value.
  double get effectivePassMark {
    if (passMarkType == 'percentage') {
      return totalMarks * (passMark / 100);
    }
    return passMark;
  }

  /// Whether the exam is currently within its active time window.
  bool get isWithinTimeWindow {
    final now = DateTime.now();
    return now.isAfter(startTime) && now.isBefore(endTime);
  }

  /// Whether the exam has not yet started.
  bool get hasNotStarted => DateTime.now().isBefore(startTime);

  /// Whether the exam time window has ended.
  bool get hasEnded => DateTime.now().isAfter(endTime);

  @override
  List<Object?> get props => [
        id,
        schoolId,
        createdBy,
        title,
        description,
        subjectId,
        classId,
        academicSessionId,
        examType,
        status,
        startTime,
        endTime,
        timeLimitMinutes,
        totalMarks,
        passMark,
        passMarkType,
        instructions,
        allowedAttempts,
        negativeMarkingEnabled,
        negativeMarkValue,
        gracePeriodMinutes,
        autoSubmit,
        randomizeQuestions,
        randomizeOptions,
        showResults,
        showCorrectAnswers,
        showExplanations,
        isTemplate,
        templateId,
        maxStudents,
        ipRestriction,
        requireFullScreen,
        allowResume,
        browserLockdown,
        metadata,
        publishedAt,
        sections,
        questions,
        createdAt,
        updatedAt,
      ];
}

/// Aggregated statistics for an exam. Not persisted — computed on demand.
class ExamStatistics extends Equatable {
  const ExamStatistics({
    required this.examId,
    required this.totalStudents,
    required this.startedStudents,
    required this.completedStudents,
    required this.submittedStudents,
    required this.averageScore,
    required this.highestScore,
    required this.lowestScore,
    required this.medianScore,
    required this.passRate,
    required this.questionsByCorrectRate,
    required this.averageTimeSpentSeconds,
    required this.gradingCompletionPercentage,
  });

  final String examId;
  final int totalStudents;
  final int startedStudents;
  final int completedStudents;
  final int submittedStudents;
  final double averageScore;
  final double highestScore;
  final double lowestScore;
  final double medianScore;
  final double passRate;

  /// Map of question ID to the percentage of students who answered correctly.
  final Map<String, double> questionsByCorrectRate;
  final int averageTimeSpentSeconds;
  final double gradingCompletionPercentage;

  ExamStatistics copyWith({
    String? examId,
    int? totalStudents,
    int? startedStudents,
    int? completedStudents,
    int? submittedStudents,
    double? averageScore,
    double? highestScore,
    double? lowestScore,
    double? medianScore,
    double? passRate,
    Map<String, double>? questionsByCorrectRate,
    int? averageTimeSpentSeconds,
    double? gradingCompletionPercentage,
  }) {
    return ExamStatistics(
      examId: examId ?? this.examId,
      totalStudents: totalStudents ?? this.totalStudents,
      startedStudents: startedStudents ?? this.startedStudents,
      completedStudents: completedStudents ?? this.completedStudents,
      submittedStudents: submittedStudents ?? this.submittedStudents,
      averageScore: averageScore ?? this.averageScore,
      highestScore: highestScore ?? this.highestScore,
      lowestScore: lowestScore ?? this.lowestScore,
      medianScore: medianScore ?? this.medianScore,
      passRate: passRate ?? this.passRate,
      questionsByCorrectRate:
          questionsByCorrectRate ?? this.questionsByCorrectRate,
      averageTimeSpentSeconds:
          averageTimeSpentSeconds ?? this.averageTimeSpentSeconds,
      gradingCompletionPercentage:
          gradingCompletionPercentage ?? this.gradingCompletionPercentage,
    );
  }

  @override
  List<Object?> get props => [
        examId,
        totalStudents,
        startedStudents,
        completedStudents,
        submittedStudents,
        averageScore,
        highestScore,
        lowestScore,
        medianScore,
        passRate,
        questionsByCorrectRate,
        averageTimeSpentSeconds,
        gradingCompletionPercentage,
      ];
}

/// Live exam stats for the real-time monitoring dashboard.
///
/// Not persisted — computed on demand from active sessions and recent
/// events.
class LiveExamStats extends Equatable {
  const LiveExamStats({
    required this.examId,
    required this.totalEligible,
    required this.activeNow,
    required this.completed,
    required this.notStarted,
    required this.averageProgress,
    this.recentSubmissions = const [],
    this.activeSessions = const [],
    this.recentMonitoringEvents = const [],
  });

  final String examId;
  final int totalEligible;
  final int activeNow;
  final int completed;
  final int notStarted;
  final double averageProgress;
  final List<ExamAttemptEntity> recentSubmissions;
  final List<ExamSessionEntity> activeSessions;
  final List<MonitoringLogEntity> recentMonitoringEvents;

  LiveExamStats copyWith({
    String? examId,
    int? totalEligible,
    int? activeNow,
    int? completed,
    int? notStarted,
    double? averageProgress,
    List<ExamAttemptEntity>? recentSubmissions,
    List<ExamSessionEntity>? activeSessions,
    List<MonitoringLogEntity>? recentMonitoringEvents,
  }) {
    return LiveExamStats(
      examId: examId ?? this.examId,
      totalEligible: totalEligible ?? this.totalEligible,
      activeNow: activeNow ?? this.activeNow,
      completed: completed ?? this.completed,
      notStarted: notStarted ?? this.notStarted,
      averageProgress: averageProgress ?? this.averageProgress,
      recentSubmissions: recentSubmissions ?? this.recentSubmissions,
      activeSessions: activeSessions ?? this.activeSessions,
      recentMonitoringEvents:
          recentMonitoringEvents ?? this.recentMonitoringEvents,
    );
  }

  @override
  List<Object?> get props => [
        examId,
        totalEligible,
        activeNow,
        completed,
        notStarted,
        averageProgress,
        recentSubmissions,
        activeSessions,
        recentMonitoringEvents,
      ];
}

/// Input data for creating a new exam (used by teachers).
///
/// This is a DTO-style class used solely in the [CreateExamUseCase]
/// to carry the raw input from the presentation layer before it is
/// transformed into a full [ExamEntity] with server-generated fields.
class ExamCreateInput extends Equatable {
  const ExamCreateInput({
    required this.title,
    this.description,
    required this.subjectId,
    required this.classId,
    required this.academicSessionId,
    required this.examType,
    required this.startTime,
    required this.endTime,
    required this.timeLimitMinutes,
    required this.passMark,
    this.passMarkType = 'percentage',
    this.instructions,
    this.allowedAttempts = 1,
    this.negativeMarkingEnabled = false,
    this.negativeMarkValue = 0.0,
    this.gracePeriodMinutes = 0,
    this.autoSubmit = true,
    this.randomizeQuestions = false,
    this.randomizeOptions = false,
    this.showResults = 'after_submission',
    this.showCorrectAnswers = false,
    this.showExplanations = false,
    this.maxStudents,
    this.requireFullScreen = false,
    this.allowResume = true,
    this.browserLockdown = false,
  });

  final String title;
  final String? description;
  final String subjectId;
  final String classId;
  final String academicSessionId;
  final ExamType examType;
  final DateTime startTime;
  final DateTime endTime;
  final int timeLimitMinutes;
  final double passMark;
  final String passMarkType;
  final String? instructions;
  final int allowedAttempts;
  final bool negativeMarkingEnabled;
  final double negativeMarkValue;
  final int gracePeriodMinutes;
  final bool autoSubmit;
  final bool randomizeQuestions;
  final bool randomizeOptions;
  final String showResults;
  final bool showCorrectAnswers;
  final bool showExplanations;
  final int? maxStudents;
  final bool requireFullScreen;
  final bool allowResume;
  final bool browserLockdown;

  @override
  List<Object?> get props => [
        title,
        description,
        subjectId,
        classId,
        academicSessionId,
        examType,
        startTime,
        endTime,
        timeLimitMinutes,
        passMark,
        passMarkType,
        instructions,
        allowedAttempts,
        negativeMarkingEnabled,
        negativeMarkValue,
        gracePeriodMinutes,
        autoSubmit,
        randomizeQuestions,
        randomizeOptions,
        showResults,
        showCorrectAnswers,
        showExplanations,
        maxStudents,
        requireFullScreen,
        allowResume,
        browserLockdown,
      ];
}
