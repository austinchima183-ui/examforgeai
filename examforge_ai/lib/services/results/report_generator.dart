/// Report Generator — pure computation service for structured report outputs.
///
/// Transforms domain entities (results, exam, and CBT data) into structured
/// [ReportData] objects ready for export to PDF, Excel, or CSV by the
/// datasource layer (Supabase Edge Functions or local generators).
///
/// ## Design Principles
///
/// - **Pure transformation**: Every public method accepts entities and returns
///   a [ReportData] with no I/O, no database access, no side effects.
/// - **Self-contained DTOs**: Output content types are defined in this file to
///   avoid coupling to persistence-layer models.
/// - **Null-safe**: All methods handle missing or partial data gracefully,
///   providing sensible defaults rather than throwing.
/// - **Format-agnostic**: This service produces structured data only; the
///   actual file generation is handled downstream.
///
/// ## Usage
///
/// ```dart
/// final generator = ReportGenerator();
/// final report = generator.generateStudentReport(
///   overallResult: studentOverall,
///   subjectResults: subjectList,
///   studentName: 'John Doe',
///   className: 'SS2A',
///   sessionName: '2025/2026',
///   trendData: trendPoints,
/// );
/// // Pass report to datasource layer for PDF/Excel/CSV generation
/// ```
library;

import 'package:examforge_ai/features/cbt_engine/domain/entities/cbt_entities.dart' hide GradeScaleEntity;
import 'package:examforge_ai/features/results/domain/entities/results_entities.dart';


// ═══════════════════════════════════════════════════════════════════════
// OUTPUT DATA TYPES
// ═══════════════════════════════════════════════════════════════════════

/// Top-level wrapper for all report outputs.
///
/// Contains the report [type], a human-readable [title], structured [content]
/// specific to the report type, and [metadata] about generation context.
class ReportData {
  const ReportData({
    required this.type,
    required this.title,
    required this.content,
    required this.metadata,
  });

  final ReportType type;
  final String title;
  final Map<String, dynamic> content;
  final Map<String, dynamic> metadata;

  /// Serializes the report data to a JSON-compatible map for transport.
  Map<String, dynamic> toJson() => {
        'type': type.value,
        'title': title,
        'content': content,
        'metadata': metadata,
      };
}

/// A single data point in a performance trend chart.
class TrendDataPoint {
  const TrendDataPoint({
    required this.period,
    required this.score,
  });

  final String period;
  final double score;

  Map<String, dynamic> toJson() => {
        'period': period,
        'score': score,
      };
}

/// A row in the subject-by-subject breakdown of a student report.
class SubjectResultRow {
  const SubjectResultRow({
    required this.subjectName,
    required this.score,
    required this.percentage,
    required this.grade,
    this.classAverage,
    this.position,
    this.trend,
  });

  final String subjectName;
  final double score;
  final double percentage;
  final String grade;
  final double? classAverage;
  final int? position;
  final String? trend;

  /// Deviation from class average (null if classAverage is null).
  double? get deviation =>
      classAverage != null ? percentage - classAverage! : null;

  Map<String, dynamic> toJson() => {
        'subjectName': subjectName,
        'score': score,
        'percentage': percentage,
        'grade': grade,
        'classAverage': classAverage,
        'position': position,
        'trend': trend,
        'deviation': deviation,
      };
}

/// Content for a comprehensive student report.
class StudentReportContent {
  const StudentReportContent({
    required this.studentName,
    required this.className,
    required this.sessionName,
    required this.overallScore,
    required this.overallGrade,
    this.overallGpa,
    this.classPosition,
    this.classSize,
    required this.subjectResults,
    required this.strengths,
    required this.weaknesses,
    required this.recommendations,
    this.teacherComment,
    required this.trendData,
  });

  final String studentName;
  final String className;
  final String sessionName;
  final double overallScore;
  final String overallGrade;
  final double? overallGpa;
  final int? classPosition;
  final int? classSize;
  final List<SubjectResultRow> subjectResults;
  final List<String> strengths;
  final List<String> weaknesses;
  final List<String> recommendations;
  final String? teacherComment;
  final List<TrendDataPoint> trendData;

  Map<String, dynamic> toJson() => {
        'studentName': studentName,
        'className': className,
        'sessionName': sessionName,
        'overallScore': overallScore,
        'overallGrade': overallGrade,
        'overallGpa': overallGpa,
        'classPosition': classPosition,
        'classSize': classSize,
        'subjectResults': subjectResults.map((r) => r.toJson()).toList(),
        'strengths': strengths,
        'weaknesses': weaknesses,
        'recommendations': recommendations,
        'teacherComment': teacherComment,
        'trendData': trendData.map((t) => t.toJson()).toList(),
      };
}

/// A row in the student rankings table within a class report.
class StudentRankingRow {
  const StudentRankingRow({
    required this.position,
    required this.studentName,
    required this.totalScore,
    required this.percentage,
    required this.grade,
    required this.isPassed,
  });

  final int position;
  final String studentName;
  final double totalScore;
  final double percentage;
  final String grade;
  final bool isPassed;

  Map<String, dynamic> toJson() => {
        'position': position,
        'studentName': studentName,
        'totalScore': totalScore,
        'percentage': percentage,
        'grade': grade,
        'isPassed': isPassed,
      };
}

/// Performance comparison entry for a single subject in a class report.
class SubjectComparisonEntry {
  const SubjectComparisonEntry({
    required this.subjectName,
    required this.classAverage,
    required this.highestScore,
    required this.lowestScore,
    required this.passRate,
  });

  final String subjectName;
  final double classAverage;
  final double highestScore;
  final double lowestScore;
  final double passRate;

  Map<String, dynamic> toJson() => {
        'subjectName': subjectName,
        'classAverage': classAverage,
        'highestScore': highestScore,
        'lowestScore': lowestScore,
        'passRate': passRate,
      };
}

/// Content for a class-wide report.
class ClassReportContent {
  const ClassReportContent({
    required this.className,
    required this.sessionName,
    required this.totalStudents,
    required this.averageScore,
    required this.highestScore,
    required this.lowestScore,
    required this.passRate,
    required this.gradeDistribution,
    required this.studentRankings,
    required this.subjectComparisons,
    required this.difficultTopics,
  });

  final String className;
  final String sessionName;
  final int totalStudents;
  final double averageScore;
  final double highestScore;
  final double lowestScore;
  final double passRate;
  final Map<String, int> gradeDistribution;
  final List<StudentRankingRow> studentRankings;
  final List<SubjectComparisonEntry> subjectComparisons;
  final List<String> difficultTopics;

  Map<String, dynamic> toJson() => {
        'className': className,
        'sessionName': sessionName,
        'totalStudents': totalStudents,
        'averageScore': averageScore,
        'highestScore': highestScore,
        'lowestScore': lowestScore,
        'passRate': passRate,
        'gradeDistribution': gradeDistribution,
        'studentRankings': studentRankings.map((r) => r.toJson()).toList(),
        'subjectComparisons':
            subjectComparisons.map((s) => s.toJson()).toList(),
        'difficultTopics': difficultTopics,
      };
}

/// A ranking entry for a class within a school report.
class ClassRankingEntry {
  const ClassRankingEntry({
    required this.className,
    required this.averageScore,
    required this.passRate,
    required this.totalStudents,
  });

  final String className;
  final double averageScore;
  final double passRate;
  final int totalStudents;

  Map<String, dynamic> toJson() => {
        'className': className,
        'averageScore': averageScore,
        'passRate': passRate,
        'totalStudents': totalStudents,
      };
}

/// A ranking entry for a subject within a school report.
class SubjectRankingEntry {
  const SubjectRankingEntry({
    required this.subjectName,
    required this.averageScore,
    required this.passRate,
    required this.studentCount,
  });

  final String subjectName;
  final double averageScore;
  final double passRate;
  final int studentCount;

  Map<String, dynamic> toJson() => {
        'subjectName': subjectName,
        'averageScore': averageScore,
        'passRate': passRate,
        'studentCount': studentCount,
      };
}

/// Content for a school-level report.
class SchoolReportContent {
  const SchoolReportContent({
    required this.schoolName,
    required this.sessionName,
    required this.totalStudents,
    required this.totalClasses,
    required this.averageScore,
    required this.passRate,
    required this.distinctionRate,
    required this.gradeDistribution,
    required this.classRankings,
    required this.subjectRankings,
    required this.trendData,
  });

  final String schoolName;
  final String sessionName;
  final int totalStudents;
  final int totalClasses;
  final double averageScore;
  final double passRate;
  final double distinctionRate;
  final Map<String, int> gradeDistribution;
  final List<ClassRankingEntry> classRankings;
  final List<SubjectRankingEntry> subjectRankings;
  final List<TrendDataPoint> trendData;

  Map<String, dynamic> toJson() => {
        'schoolName': schoolName,
        'sessionName': sessionName,
        'totalStudents': totalStudents,
        'totalClasses': totalClasses,
        'averageScore': averageScore,
        'passRate': passRate,
        'distinctionRate': distinctionRate,
        'gradeDistribution': gradeDistribution,
        'classRankings': classRankings.map((c) => c.toJson()).toList(),
        'subjectRankings': subjectRankings.map((s) => s.toJson()).toList(),
        'trendData': trendData.map((t) => t.toJson()).toList(),
      };
}

/// A score range bucket for score distribution in a subject report.
class ScoreBucket {
  const ScoreBucket({
    required this.range,
    required this.count,
    required this.percentage,
  });

  final String range;
  final int count;
  final double percentage;

  Map<String, dynamic> toJson() => {
        'range': range,
        'count': count,
        'percentage': percentage,
      };
}

/// Topic mastery overview entry for a subject report.
class TopicMasteryEntry {
  const TopicMasteryEntry({
    required this.topicName,
    required this.masteryLevel,
    required this.averageAccuracy,
    required this.studentsAttempted,
  });

  final String topicName;
  final String masteryLevel;
  final double averageAccuracy;
  final int studentsAttempted;

  Map<String, dynamic> toJson() => {
        'topicName': topicName,
        'masteryLevel': masteryLevel,
        'averageAccuracy': averageAccuracy,
        'studentsAttempted': studentsAttempted,
      };
}

/// A row in the student performance table for a subject report.
class SubjectStudentRow {
  const SubjectStudentRow({
    required this.position,
    required this.studentName,
    required this.score,
    required this.percentage,
    required this.grade,
    required this.isPassed,
  });

  final int position;
  final String studentName;
  final double score;
  final double percentage;
  final String grade;
  final bool isPassed;

  Map<String, dynamic> toJson() => {
        'position': position,
        'studentName': studentName,
        'score': score,
        'percentage': percentage,
        'grade': grade,
        'isPassed': isPassed,
      };
}

/// Content for a subject-level report.
class SubjectReportContent {
  const SubjectReportContent({
    required this.subjectName,
    required this.className,
    required this.sessionName,
    required this.totalStudents,
    required this.averageScore,
    required this.highestScore,
    required this.lowestScore,
    required this.passRate,
    required this.scoreDistribution,
    required this.topicMastery,
    required this.studentPerformance,
  });

  final String subjectName;
  final String className;
  final String sessionName;
  final int totalStudents;
  final double averageScore;
  final double highestScore;
  final double lowestScore;
  final double passRate;
  final List<ScoreBucket> scoreDistribution;
  final List<TopicMasteryEntry> topicMastery;
  final List<SubjectStudentRow> studentPerformance;

  Map<String, dynamic> toJson() => {
        'subjectName': subjectName,
        'className': className,
        'sessionName': sessionName,
        'totalStudents': totalStudents,
        'averageScore': averageScore,
        'highestScore': highestScore,
        'lowestScore': lowestScore,
        'passRate': passRate,
        'scoreDistribution':
            scoreDistribution.map((b) => b.toJson()).toList(),
        'topicMastery': topicMastery.map((t) => t.toJson()).toList(),
        'studentPerformance':
            studentPerformance.map((s) => s.toJson()).toList(),
      };
}

/// Per-question analysis entry for an exam summary report.
class QuestionAnalysisEntry {
  const QuestionAnalysisEntry({
    required this.questionNumber,
    required this.questionId,
    required this.correctRate,
    required this.averageTimeSeconds,
    required this.skippedCount,
  });

  final int questionNumber;
  final String questionId;
  final double correctRate;
  final int averageTimeSeconds;
  final int skippedCount;

  Map<String, dynamic> toJson() => {
        'questionNumber': questionNumber,
        'questionId': questionId,
        'correctRate': correctRate,
        'averageTimeSeconds': averageTimeSeconds,
        'skippedCount': skippedCount,
      };
}

/// A performer entry for the top/bottom sections of an exam summary.
class PerformerEntry {
  const PerformerEntry({
    required this.studentName,
    required this.score,
    required this.percentage,
    required this.grade,
  });

  final String studentName;
  final double score;
  final double percentage;
  final String grade;

  Map<String, dynamic> toJson() => {
        'studentName': studentName,
        'score': score,
        'percentage': percentage,
        'grade': grade,
      };
}

/// Content for an exam summary report.
class ExamSummaryContent {
  const ExamSummaryContent({
    required this.examTitle,
    required this.examDate,
    required this.duration,
    required this.totalMarks,
    required this.passMark,
    required this.totalStudents,
    required this.completedStudents,
    required this.averageScore,
    required this.highestScore,
    required this.lowestScore,
    required this.passRate,
    required this.gradeDistribution,
    required this.questionAnalysis,
    required this.topPerformers,
    required this.bottomPerformers,
  });

  final String examTitle;
  final String examDate;
  final String duration;
  final double totalMarks;
  final double passMark;
  final int totalStudents;
  final int completedStudents;
  final double averageScore;
  final double highestScore;
  final double lowestScore;
  final double passRate;
  final Map<String, int> gradeDistribution;
  final List<QuestionAnalysisEntry> questionAnalysis;
  final List<PerformerEntry> topPerformers;
  final List<PerformerEntry> bottomPerformers;

  Map<String, dynamic> toJson() => {
        'examTitle': examTitle,
        'examDate': examDate,
        'duration': duration,
        'totalMarks': totalMarks,
        'passMark': passMark,
        'totalStudents': totalStudents,
        'completedStudents': completedStudents,
        'averageScore': averageScore,
        'highestScore': highestScore,
        'lowestScore': lowestScore,
        'passRate': passRate,
        'gradeDistribution': gradeDistribution,
        'questionAnalysis':
            questionAnalysis.map((q) => q.toJson()).toList(),
        'topPerformers': topPerformers.map((p) => p.toJson()).toList(),
        'bottomPerformers': bottomPerformers.map((p) => p.toJson()).toList(),
      };
}

// ═══════════════════════════════════════════════════════════════════════
// REPORT GENERATOR SERVICE
// ═══════════════════════════════════════════════════════════════════════

/// Generates structured report data from domain entities.
///
/// This service is a pure computation layer — it transforms raw entity data
/// into [ReportData] structures that the datasource layer can then render
/// into PDF, Excel, or CSV files. No file I/O is performed here.
class ReportGenerator {
  // ── Student Report ─────────────────────────────────────────────────

  /// Creates a comprehensive report for a single student.
  ///
  /// Requires the student's [overallResult] entity, their [subjectResults],
  /// and contextual information like [studentName], [className], and
  /// [sessionName]. Optional [trendData] provides historical performance
  /// for chart rendering.
  ///
  /// The optional [gradeScale] is used to derive the overall grade from the
  /// overall percentage if [StudentOverallResultEntity.overallGrade] is null.
  ReportData generateStudentReport({
    required StudentOverallResultEntity overallResult,
    required List<StudentSubjectResultEntity> subjectResults,
    required String studentName,
    required String className,
    required String sessionName,
    List<TrendDataPoint>? trendData,
    GradeScaleEntity? gradeScale,
  }) {
    // Resolve the overall grade — use the entity's grade first, then
    // fall back to the grade scale if available.
    final overallGrade = overallResult.overallGrade ??
        gradeScale?.applyToPercentage(overallResult.overallPercentage)?.grade ??
        _defaultGrade(overallResult.overallPercentage);

    // Build subject-by-subject breakdown rows.
    final subjectRows = subjectResults.map((sr) {
      final grade = sr.grade ??
          gradeScale?.applyToPercentage(sr.percentage)?.grade ??
          _defaultGrade(sr.percentage);
      return SubjectResultRow(
        subjectName: sr.subjectId, // Caller should map ID → name upstream
        score: sr.totalMarksObtained,
        percentage: sr.percentage,
        grade: grade,
        classAverage: sr.classAverage,
        position: sr.classPosition,
        trend: sr.performanceTrend.label,
      );
    }).toList();

    // Collect strengths and weaknesses from subject results.
    final strengths = <String>[
      ...overallResult.metadata['strengths'] as List<dynamic>? ?? [],
      ...subjectResults
          .where((sr) => sr.performanceTrend == PerformanceTrend.improving)
          .map((sr) => 'Strong performance in ${sr.subjectId}'),
    ];

    final weaknesses = <String>[
      ...overallResult.metadata['weaknesses'] as List<dynamic>? ?? [],
      ...subjectResults
          .where((sr) => sr.performanceTrend == PerformanceTrend.declining)
          .map((sr) => 'Needs improvement in ${sr.subjectId}'),
    ];

    // AI study recommendations from the overall result entity.
    final recommendations = overallResult.aiStudyRecommendations;

    // Build trend data from supplied points, or default to a single point.
    final trend = trendData ??
        [
          TrendDataPoint(
            period: sessionName,
            score: overallResult.overallPercentage,
          ),
        ];

    final content = StudentReportContent(
      studentName: studentName,
      className: className,
      sessionName: sessionName,
      overallScore: overallResult.overallPercentage,
      overallGrade: overallGrade,
      overallGpa: overallResult.overallGpa,
      classPosition: overallResult.classPosition,
      classSize: overallResult.classSize,
      subjectResults: subjectRows,
      strengths: strengths,
      weaknesses: weaknesses,
      recommendations: recommendations,
      teacherComment: overallResult.teacherComment,
      trendData: trend,
    );

    return ReportData(
      type: ReportType.student,
      title: 'Student Report — $studentName',
      content: content.toJson(),
      metadata: _buildMetadata(),
    );
  }

  // ── Class Report ───────────────────────────────────────────────────

  /// Creates a class-wide performance report.
  ///
  /// Accepts a [ClassPerformanceEntity] for the class statistics,
  /// [studentResults] for building the rankings table, and
  /// [subjectResults] for subject performance comparisons.
  ///
  /// Optional [gradeScale] is used to derive grades from percentages.
  ReportData generateClassReport({
    required ClassPerformanceEntity classPerformance,
    required List<StudentOverallResultEntity> studentResults,
    required String className,
    required String sessionName,
    List<StudentSubjectResultEntity>? subjectResults,
    GradeScaleEntity? gradeScale,
    Map<String, String>? subjectNameMap,
    Map<String, String>? studentNameMap,
  }) {
    // Build student rankings sorted by overall percentage descending.
    final sorted = List<StudentOverallResultEntity>.from(studentResults)
      ..sort((a, b) => b.overallPercentage.compareTo(a.overallPercentage));

    final rankings = sorted.asMap().entries.map((entry) {
      final sr = entry.value;
      final grade = sr.overallGrade ??
          gradeScale?.applyToPercentage(sr.overallPercentage)?.grade ??
          _defaultGrade(sr.overallPercentage);
      return StudentRankingRow(
        position: entry.key + 1,
        studentName: studentNameMap?[sr.studentId] ?? sr.studentId,
        totalScore: sr.totalMarksObtained,
        percentage: sr.overallPercentage,
        grade: grade,
        isPassed: sr.subjectsFailed == 0,
      );
    }).toList();

    // Build subject performance comparison entries.
    final subjectComparisons = <SubjectComparisonEntry>[];
    if (subjectResults != null) {
      // Group by subject and compute aggregated stats.
      final bySubject = <String, List<StudentSubjectResultEntity>>{};
      for (final sr in subjectResults) {
        bySubject.putIfAbsent(sr.subjectId, () => []).add(sr);
      }
      for (final entry in bySubject.entries) {
        final scores = entry.value.map((e) => e.percentage).toList();
        if (scores.isEmpty) continue;
        scores.sort();
        final avg = scores.reduce((a, b) => a + b) / scores.length;
        final passed = entry.value.where((e) => e.isPassed).length;
        subjectComparisons.add(SubjectComparisonEntry(
          subjectName: subjectNameMap?[entry.key] ?? entry.key,
          classAverage: avg,
          highestScore: scores.last,
          lowestScore: scores.first,
          passRate: scores.isNotEmpty
              ? (passed / scores.length) * 100
              : 0,
        ),);
      }
    }

    // Identify difficult topics from class performance metadata.
    final difficultTopics = <String>[];
    final topicPerf = classPerformance.topicPerformance;
    for (final entry in topicPerf.entries) {
      final avgScore = entry.value is num ? (entry.value as num).toDouble() : 0.0;
      if (avgScore < 50) {
        difficultTopics.add(entry.key);
      }
    }

    // Build grade distribution from class performance entity.
    final gradeDist = <String, int>{};
    for (final entry in classPerformance.gradeDistribution.entries) {
      gradeDist[entry.key] = (entry.value is num
          ? (entry.value as num).toInt()
          : int.tryParse(entry.value.toString()) ?? 0);
    }

    final content = ClassReportContent(
      className: className,
      sessionName: sessionName,
      totalStudents: classPerformance.totalStudents,
      averageScore: classPerformance.averageScore,
      highestScore: classPerformance.highestScore,
      lowestScore: classPerformance.lowestScore,
      passRate: classPerformance.passRate,
      gradeDistribution: gradeDist,
      studentRankings: rankings,
      subjectComparisons: subjectComparisons,
      difficultTopics: difficultTopics,
    );

    return ReportData(
      type: ReportType.classReport,
      title: 'Class Report — $className',
      content: content.toJson(),
      metadata: _buildMetadata(),
    );
  }

  // ── School Report ──────────────────────────────────────────────────

  /// Creates a school-level performance report.
  ///
  /// Uses [SchoolPerformanceEntity] for school-wide statistics and
  /// optional [classPerformances] and [subjectPerformances] for detailed
  /// rankings.
  ReportData generateSchoolReport({
    required SchoolPerformanceEntity schoolPerformance,
    required String schoolName,
    required String sessionName,
    List<ClassPerformanceEntity>? classPerformances,
    Map<String, String>? classNameMap,
    List<StudentSubjectResultEntity>? subjectResults,
    Map<String, String>? subjectNameMap,
    GradeScaleEntity? gradeScale,
  }) {
    // Build class rankings from supplied class performance data.
    final classRankings = <ClassRankingEntry>[];
    if (classPerformances != null) {
      final sorted = List<ClassPerformanceEntity>.from(classPerformances)
        ..sort((a, b) => b.averageScore.compareTo(a.averageScore));
      for (final cp in sorted) {
        classRankings.add(ClassRankingEntry(
          className: classNameMap?[cp.classId] ?? cp.classId,
          averageScore: cp.averageScore,
          passRate: cp.passRate,
          totalStudents: cp.totalStudents,
        ),);
      }
    }

    // Build subject rankings from supplied subject results.
    final subjectRankings = <SubjectRankingEntry>[];
    if (subjectResults != null) {
      final bySubject = <String, List<StudentSubjectResultEntity>>{};
      for (final sr in subjectResults) {
        bySubject.putIfAbsent(sr.subjectId, () => []).add(sr);
      }
      final subjectStats = <String, ({double avg, double passRate, int count})>{};
      for (final entry in bySubject.entries) {
        final scores = entry.value.map((e) => e.percentage).toList();
        if (scores.isEmpty) continue;
        final avg = scores.reduce((a, b) => a + b) / scores.length;
        final passed = entry.value.where((e) => e.isPassed).length;
        subjectStats[entry.key] = (
          avg: avg,
          passRate: (passed / scores.length) * 100,
          count: scores.length,
        );
      }
      // Sort by average descending.
      final sortedSubjects = subjectStats.entries.toList()
        ..sort((a, b) => b.value.avg.compareTo(a.value.avg));
      for (final entry in sortedSubjects) {
        subjectRankings.add(SubjectRankingEntry(
          subjectName: subjectNameMap?[entry.key] ?? entry.key,
          averageScore: entry.value.avg,
          passRate: entry.value.passRate,
          studentCount: entry.value.count,
        ),);
      }
    }

    // Build historical trend data from the entity.
    final trendData = <TrendDataPoint>[];
    for (final point in schoolPerformance.trendData) {
      if (point is Map<String, dynamic>) {
        trendData.add(TrendDataPoint(
          period: point['period'] as String? ?? '',
          score: (point['score'] as num?)?.toDouble() ?? 0,
        ),);
      }
    }

    // Build grade distribution.
    final gradeDist = <String, int>{};
    for (final entry in schoolPerformance.gradeDistribution.entries) {
      gradeDist[entry.key] = (entry.value is num
          ? (entry.value as num).toInt()
          : int.tryParse(entry.value.toString()) ?? 0);
    }

    final content = SchoolReportContent(
      schoolName: schoolName,
      sessionName: sessionName,
      totalStudents: schoolPerformance.totalStudents,
      totalClasses: schoolPerformance.totalClasses,
      averageScore: schoolPerformance.averageScore,
      passRate: schoolPerformance.passRate,
      distinctionRate: schoolPerformance.distinctionRate,
      gradeDistribution: gradeDist,
      classRankings: classRankings,
      subjectRankings: subjectRankings,
      trendData: trendData,
    );

    return ReportData(
      type: ReportType.school,
      title: 'School Report — $schoolName',
      content: content.toJson(),
      metadata: _buildMetadata(),
    );
  }

  // ── Subject Report ─────────────────────────────────────────────────

  /// Creates a subject-level report with statistics, score distribution,
  /// topic mastery, and student performance table.
  ///
  /// Uses [ClassPerformanceEntity] scoped to a subject for statistics,
  /// and [studentSubjectResults] for the per-student breakdown.
  ReportData generateSubjectReport({
    required ClassPerformanceEntity subjectPerformance,
    required List<StudentSubjectResultEntity> studentSubjectResults,
    required String subjectName,
    required String className,
    required String sessionName,
    List<TopicMasteryEntity>? topicMasteryData,
    Map<String, String>? studentNameMap,
    Map<String, String>? topicNameMap,
    GradeScaleEntity? gradeScale,
  }) {
    // Build score distribution buckets.
    final buckets = _computeScoreBuckets(studentSubjectResults);

    // Build topic mastery overview.
    final topicEntries = <TopicMasteryEntry>[];
    if (topicMasteryData != null) {
      // Group by topic and compute averages.
      final byTopic = <String, List<TopicMasteryEntity>>{};
      for (final tm in topicMasteryData) {
        byTopic.putIfAbsent(tm.topicId, () => []).add(tm);
      }
      for (final entry in byTopic.entries) {
        final items = entry.value;
        final avgAccuracy = items.isEmpty
            ? 0.0
            : items.map((t) => t.accuracyPercentage).reduce((a, b) => a + b) /
                items.length;
        topicEntries.add(TopicMasteryEntry(
          topicName: topicNameMap?[entry.key] ?? entry.key,
          masteryLevel: _dominantMasteryLevel(items),
          averageAccuracy: avgAccuracy,
          studentsAttempted: items
              .where((t) => t.questionsAttempted > 0)
              .length,
        ),);
      }
    }

    // Build student performance table sorted by percentage descending.
    final sorted = List<StudentSubjectResultEntity>.from(studentSubjectResults)
      ..sort((a, b) => b.percentage.compareTo(a.percentage));

    final studentRows = sorted.asMap().entries.map((entry) {
      final sr = entry.value;
      final grade = sr.grade ??
          gradeScale?.applyToPercentage(sr.percentage)?.grade ??
          _defaultGrade(sr.percentage);
      return SubjectStudentRow(
        position: entry.key + 1,
        studentName: studentNameMap?[sr.studentId] ?? sr.studentId,
        score: sr.totalMarksObtained,
        percentage: sr.percentage,
        grade: grade,
        isPassed: sr.isPassed,
      );
    }).toList();

    final content = SubjectReportContent(
      subjectName: subjectName,
      className: className,
      sessionName: sessionName,
      totalStudents: subjectPerformance.totalStudents,
      averageScore: subjectPerformance.averageScore,
      highestScore: subjectPerformance.highestScore,
      lowestScore: subjectPerformance.lowestScore,
      passRate: subjectPerformance.passRate,
      scoreDistribution: buckets,
      topicMastery: topicEntries,
      studentPerformance: studentRows,
    );

    return ReportData(
      type: ReportType.subject,
      title: 'Subject Report — $subjectName',
      content: content.toJson(),
      metadata: _buildMetadata(),
    );
  }

  // ── Exam Summary ───────────────────────────────────────────────────

  /// Creates an exam summary report with overview, statistics, question
  /// analysis, and top/bottom performers.
  ///
  /// Uses [ExamEntity] for exam metadata, [ExamStatistics] for computed
  /// statistics, and [ExamResultEntity] list for student-level data.
  ReportData generateExamSummary({
    required ExamEntity exam,
    required ExamStatistics statistics,
    required List<ExamResultEntity> results,
    Map<String, String>? studentNameMap,
    GradeScaleEntity? gradeScale,
  }) {
    // Build question analysis from statistics.
    final questionAnalysis = <QuestionAnalysisEntry>[];
    final sortedQuestions = statistics.questionsByCorrectRate.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    for (var i = 0; i < sortedQuestions.length; i++) {
      final entry = sortedQuestions[i];
      questionAnalysis.add(QuestionAnalysisEntry(
        questionNumber: i + 1,
        questionId: entry.key,
        correctRate: entry.value,
        averageTimeSeconds: 0, // Derived from attempt data if available
        skippedCount: 0, // Derived from attempt data if available
      ),);
    }

    // Build grade distribution from results.
    final gradeDist = <String, int>{};
    for (final result in results) {
      final grade = result.grade ??
          gradeScale?.applyToPercentage(result.scorePercentage)?.grade ??
          _defaultGrade(result.scorePercentage);
      gradeDist[grade] = (gradeDist[grade] ?? 0) + 1;
    }

    // Sort results for top/bottom performers.
    final sorted = List<ExamResultEntity>.from(results)
      ..sort((a, b) => b.scorePercentage.compareTo(a.scorePercentage));

    final topN = sorted.take(5).map((r) => PerformerEntry(
          studentName: studentNameMap?[r.studentId] ?? r.studentId,
          score: r.totalMarks,
          percentage: r.scorePercentage,
          grade: r.grade ??
              gradeScale?.applyToPercentage(r.scorePercentage)?.grade ??
              _defaultGrade(r.scorePercentage),
        ),).toList();

    final bottomN = sorted.reversed.take(5).map((r) => PerformerEntry(
          studentName: studentNameMap?[r.studentId] ?? r.studentId,
          score: r.totalMarks,
          percentage: r.scorePercentage,
          grade: r.grade ??
              gradeScale?.applyToPercentage(r.scorePercentage)?.grade ??
              _defaultGrade(r.scorePercentage),
        ),).toList();

    final content = ExamSummaryContent(
      examTitle: exam.title,
      examDate: formatDate(exam.startTime),
      duration: formatDuration(exam.timeLimitMinutes * 60),
      totalMarks: exam.totalMarks,
      passMark: exam.passMark,
      totalStudents: statistics.totalStudents,
      completedStudents: statistics.completedStudents,
      averageScore: statistics.averageScore,
      highestScore: statistics.highestScore,
      lowestScore: statistics.lowestScore,
      passRate: statistics.passRate,
      gradeDistribution: gradeDist,
      questionAnalysis: questionAnalysis,
      topPerformers: topN,
      bottomPerformers: bottomN,
    );

    return ReportData(
      type: ReportType.examSummary,
      title: 'Exam Summary — ${exam.title}',
      content: content.toJson(),
      metadata: _buildMetadata(),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // FORMATTING HELPERS
  // ═══════════════════════════════════════════════════════════════════════

  /// Formats a score to 1 decimal place (e.g., `85.3`).
  static String formatScore(double score) {
    return score.toStringAsFixed(1);
  }

  /// Formats a percentage with 1 decimal place and % sign (e.g., `85.3%`).
  static String formatPercentage(double percentage) {
    return '${percentage.toStringAsFixed(1)}%';
  }

  /// Formats a position as an ordinal string (e.g., `1st`, `2nd`, `3rd`,
  /// `4th`, `11th`, `21st`).
  ///
  /// Returns `N/A` if [position] is null.
  static String formatPosition(int? position) {
    if (position == null) return 'N/A';
    if (position < 1) return position.toString();

    final lastTwo = position % 100;
    if (lastTwo >= 11 && lastTwo <= 13) return '${position}th';

    switch (position % 10) {
      case 1:
        return '${position}st';
      case 2:
        return '${position}nd';
      case 3:
        return '${position}rd';
      default:
        return '${position}th';
    }
  }

  /// Formats a duration in seconds to a human-readable string.
  ///
  /// Examples:
  /// - `3612` → `"1h 0m"`
  /// - `2712` → `"45m 12s"`
  /// - `60` → `"1m 0s"`
  /// - `30` → `"0m 30s"`
  static String formatDuration(int seconds) {
    if (seconds < 0) seconds = 0;
    final hours = seconds ~/ 3600;
    final remainingSeconds = seconds % 3600;
    final minutes = remainingSeconds ~/ 60;
    final secs = remainingSeconds % 60;

    if (hours > 0) {
      return '${hours}h ${minutes}m';
    }
    return '${minutes}m ${secs}s';
  }

  /// Formats a date as `"Jan 15, 2026"`.
  static String formatDate(DateTime date) {
    const months = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[date.month]} ${date.day}, ${date.year}';
  }

  // ═══════════════════════════════════════════════════════════════════════
  // PRIVATE HELPERS
  // ═══════════════════════════════════════════════════════════════════════

  /// Derives a default letter grade from a percentage when no grade scale
  /// is available.
  static String _defaultGrade(double percentage) {
    if (percentage >= 70) return 'A';
    if (percentage >= 60) return 'B';
    if (percentage >= 50) return 'C';
    if (percentage >= 45) return 'D';
    if (percentage >= 40) return 'E';
    return 'F';
  }

  /// Builds metadata common to all reports.
  static Map<String, dynamic> _buildMetadata() {
    return {
      'generatedAt': DateTime.now().toUtc().toIso8601String(),
      'generatorVersion': '1.0.0',
    };
  }

  /// Computes score distribution buckets from a list of subject results.
  ///
  /// Standard ranges: 0–19, 20–39, 40–49, 50–59, 60–69, 70–79, 80–89,
  /// 90–100.
  static List<ScoreBucket> _computeScoreBuckets(
    List<StudentSubjectResultEntity> results,
  ) {
    const ranges = [
      (label: '0–19', min: 0.0, max: 19.99),
      (label: '20–39', min: 20.0, max: 39.99),
      (label: '40–49', min: 40.0, max: 49.99),
      (label: '50–59', min: 50.0, max: 59.99),
      (label: '60–69', min: 60.0, max: 69.99),
      (label: '70–79', min: 70.0, max: 79.99),
      (label: '80–89', min: 80.0, max: 89.99),
      (label: '90–100', min: 90.0, max: 100.0),
    ];

    final total = results.length.toDouble();
    return ranges.map((range) {
      final count = results
          .where((r) => r.percentage >= range.min && r.percentage <= range.max)
          .length;
      return ScoreBucket(
        range: range.label,
        count: count,
        percentage: total > 0 ? (count / total) * 100 : 0,
      );
    }).toList();
  }

  /// Determines the most common mastery level among a list of topic
  /// mastery entries.
  static String _dominantMasteryLevel(List<TopicMasteryEntity> items) {
    if (items.isEmpty) return MasteryLevel.notStarted.label;
    final counts = <MasteryLevel, int>{};
    for (final item in items) {
      counts[item.masteryLevel] = (counts[item.masteryLevel] ?? 0) + 1;
    }
    final dominant = counts.entries.reduce(
      (a, b) => a.value >= b.value ? a : b,
    );
    return dominant.key.label;
  }
}
