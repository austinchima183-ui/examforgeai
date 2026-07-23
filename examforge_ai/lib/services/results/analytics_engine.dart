/// Analytics Engine — pure computation service for results analytics.
///
/// This service provides powerful insights for teachers, schools, and students
/// by operating on raw result data and producing computed analytics. It is a
/// computation-only module with zero database access and no external
/// dependencies beyond the entity types defined in the results and CBT domains.
///
/// ## Design Principles
///
/// - **Pure functions**: Every public method is deterministic — same inputs
///   always produce the same outputs. No hidden state, no I/O.
/// - **Static helpers**: Core statistical primitives are exposed as `static`
///   methods for maximum testability and reusability.
/// - **Null-safe**: All methods handle empty input lists gracefully, returning
///   sensible defaults rather than throwing.
/// - **Self-contained DTOs**: Output types are defined in this file to avoid
///   coupling to persistence-layer entities.
///
/// ## Usage
///
/// ```dart
/// final engine = AnalyticsEngine();
/// final summary = engine.computeClassPerformance(overallResults,
///     subjectResults: subjectResults);
/// print('Class average: ${summary.averageScore}');
/// print('Pass rate: ${summary.passRate}%');
/// ```
library;

import 'package:examforge_ai/features/results/domain/entities/results_entities.dart';


// ═══════════════════════════════════════════════════════════════════════
// OUTPUT DTOs
// ═══════════════════════════════════════════════════════════════════════

/// Computed performance summary for a single class.
///
/// Aggregates individual student results into class-level statistics
/// including central tendency measures, pass/distinction rates, grade and
/// score distributions, topic-level performance, and improvement metrics.
class ClassPerformanceSummary {
  const ClassPerformanceSummary({
    required this.classId,
    required this.totalStudents,
    required this.averageScore,
    required this.highestScore,
    required this.lowestScore,
    required this.medianScore,
    required this.passRate,
    required this.distinctionRate,
    required this.gradeDistribution,
    required this.scoreDistribution,
    required this.topicPerformance,
    required this.improvementRate,
    this.subjectId,
    this.subjectBreakdown = const {},
  });

  /// The class identifier.
  final String classId;

  /// Optional subject filter — when set, metrics are scoped to this subject.
  final String? subjectId;

  /// Number of students included in the computation.
  final int totalStudents;

  /// Arithmetic mean of all student percentages.
  final double averageScore;

  /// Highest individual percentage in the class.
  final double highestScore;

  /// Lowest individual percentage in the class.
  final double lowestScore;

  /// Median percentage (50th percentile).
  final double medianScore;

  /// Percentage of students who passed (0–100).
  final double passRate;

  /// Percentage of students who achieved distinction (≥ 75% or as defined).
  final double distinctionRate;

  /// Map of grade label → count of students receiving that grade.
  final Map<String, int> gradeDistribution;

  /// Histogram buckets for score ranges.
  final List<ScoreBucket> scoreDistribution;

  /// Map of topic ID → [TopicPerformanceData] with aggregated accuracy.
  final Map<String, TopicPerformanceData> topicPerformance;

  /// Improvement rate compared to the previous period (−100 to +100).
  ///
  /// Positive values indicate class-wide improvement; negative values indicate
  /// decline. Computed as the average delta between current and previous
  /// percentages.
  final double improvementRate;

  /// Per-subroid breakdown when [subjectResults] are supplied.
  /// Key: subject ID, value: subject-specific summary.
  final Map<String, ClassPerformanceSummary> subjectBreakdown;
}

/// Computed performance summary for an entire school.
///
/// Aggregates class-level summaries into school-wide metrics with
/// cross-class rankings, trend data, and identification of best/most
/// difficult areas.
class SchoolPerformanceSummary {
  const SchoolPerformanceSummary({
    required this.schoolId,
    required this.academicSessionId,
    required this.totalStudents,
    required this.totalClasses,
    required this.averageScore,
    required this.passRate,
    required this.distinctionRate,
    required this.bestClassId,
    required this.bestSubjectId,
    required this.mostDifficultTopicId,
    required this.classRankings,
    required this.subjectRankings,
    required this.gradeDistribution,
    required this.trendData,
    this.totalExams = 0,
  });

  final String schoolId;
  final String academicSessionId;

  final int totalStudents;
  final int totalClasses;
  final int totalExams;

  final double averageScore;
  final double passRate;
  final double distinctionRate;

  /// Class with the highest average score.
  final String? bestClassId;

  /// Subject with the highest average score across the school.
  final String? bestSubjectId;

  /// Topic with the lowest average accuracy across the school.
  final String? mostDifficultTopicId;

  /// Classes ranked by average score (descending).
  final List<RankedEntity> classRankings;

  /// Subjects ranked by average score (descending).
  final List<RankedEntity> subjectRankings;

  /// School-wide grade distribution (grade label → count).
  final Map<String, int> gradeDistribution;

  /// Performance trend over multiple periods.
  final List<TrendData> trendData;
}

/// A ranked entity (class or subject) with its score.
class RankedEntity {
  const RankedEntity({
    required this.entityId,
    required this.rank,
    required this.score,
    this.label,
  });

  final String entityId;
  final int rank;
  final double score;
  final String? label;
}

/// A student with their computed rank.
class RankedStudent {
  const RankedStudent({
    required this.studentId,
    required this.rank,
    required this.score,
    this.classId,
  });

  /// The student identifier.
  final String studentId;

  /// 1-based rank. Students with identical scores share the same rank, and
  /// the next rank is skipped (standard competition ranking).
  final int rank;

  /// The student's overall percentage.
  final double score;

  /// Optional class ID for cross-class ranking context.
  final String? classId;
}

/// A single bucket in a score histogram.
class ScoreBucket {
  const ScoreBucket({
    required this.rangeLabel,
    required this.min,
    required this.max,
    required this.count,
    required this.percentage,
  });

  /// Human-readable label like "0–10" or "90–100".
  final String rangeLabel;

  /// Inclusive lower bound of the bucket.
  final double min;

  /// Inclusive upper bound of the bucket.
  final double max;

  /// Number of scores falling within this range.
  final int count;

  /// Proportion of total scores in this bucket (0–100).
  final double percentage;
}

/// Aggregated performance data for a single topic.
class TopicPerformanceData {
  const TopicPerformanceData({
    required this.topicId,
    required this.averageAccuracy,
    required this.studentCount,
    required this.masteryLevel,
    this.averageTimePerQuestion,
    this.improvementStreak = 0,
  });

  /// The topic identifier.
  final String topicId;

  /// Average accuracy percentage across all students (0–100).
  final double averageAccuracy;

  /// Number of students who attempted questions in this topic.
  final int studentCount;

  /// Derived mastery level from [averageAccuracy].
  final MasteryLevel masteryLevel;

  /// Average seconds per question (null if no data).
  final double? averageTimePerQuestion;

  /// Longest consecutive improvement streak observed.
  final int improvementStreak;
}

/// An identified difficult topic with its metrics.
class IdentifiedTopic {
  const IdentifiedTopic({
    required this.topicId,
    required this.averageAccuracy,
    required this.studentCount,
    required this.masteryLevel,
    this.subjectId,
  });

  final String topicId;
  final double averageAccuracy;
  final int studentCount;
  final MasteryLevel masteryLevel;
  final String? subjectId;
}

/// A single data point in a performance trend series.
class TrendData {
  const TrendData({
    required this.periodLabel,
    required this.averageScore,
    required this.studentCount,
    this.periodStart,
    this.periodEnd,
  });

  /// Label for the period (e.g., "Term 1", "2024-Q2").
  final String periodLabel;

  /// Average score during this period.
  final double averageScore;

  /// Number of students included.
  final int studentCount;

  /// Optional start of the period.
  final DateTime? periodStart;

  /// Optional end of the period.
  final DateTime? periodEnd;
}

/// Computed student trend analysis.
class StudentTrendAnalysis {
  const StudentTrendAnalysis({
    required this.studentId,
    required this.trend,
    required this.slope,
    required this.confidence,
    required this.strengths,
    required this.weaknesses,
    required this.recommendations,
  });

  /// The student identifier.
  final String studentId;

  /// Overall performance trend direction.
  final PerformanceTrend trend;

  /// Slope of the linear regression line (points per period).
  /// Positive → improving, near-zero → stable, negative → declining.
  final double slope;

  /// R² confidence value of the regression (0–1). Higher values indicate
  /// a more reliable trend.
  final double confidence;

  /// Subject IDs or topic IDs where the student performs well.
  final List<String> strengths;

  /// Subject IDs or topic IDs where the student struggles.
  final List<String> weaknesses;

  /// AI-style study recommendations based on the analysis.
  final List<String> recommendations;
}

/// Result of an attendance-performance correlation computation.
class AttendanceCorrelation {
  const AttendanceCorrelation({
    required this.correlationCoefficient,
    required this.sampleSize,
    required this.interpretation,
    this.highAttendanceAvgScore,
    this.lowAttendanceAvgScore,
  });

  /// Pearson correlation coefficient (−1 to +1).
  final double correlationCoefficient;

  /// Number of data points used.
  final int sampleSize;

  /// Human-readable interpretation.
  final String interpretation;

  /// Average score of students with ≥ 80% attendance (null if unavailable).
  final double? highAttendanceAvgScore;

  /// Average score of students with < 80% attendance (null if unavailable).
  final double? lowAttendanceAvgScore;
}

/// Computed topic mastery for a student.
class ComputedTopicMastery {
  const ComputedTopicMastery({
    required this.topicId,
    required this.masteryLevel,
    required this.accuracy,
    required this.avgTimePerQuestion,
    required this.improvementStreak,
    required this.questionsAttempted,
    required this.questionsCorrect,
  });

  final String topicId;
  final MasteryLevel masteryLevel;
  final double accuracy;
  final int avgTimePerQuestion;
  final int improvementStreak;
  final int questionsAttempted;
  final int questionsCorrect;
}

// ═══════════════════════════════════════════════════════════════════════
// ANALYTICS ENGINE
// ═══════════════════════════════════════════════════════════════════════

/// Pure-computation analytics engine for exam result data.
///
/// All methods are side-effect-free and operate solely on the data passed
/// to them. No database access, no network calls, no mutable state.
///
/// The engine is designed to be instantiated once and reused across the
/// application lifecycle, though it carries no state of its own.
///
/// ### Threading
///
/// Because all operations are pure and synchronous, this class is safe to
/// use from any isolate. For large datasets, consider running computations
/// in a background isolate via `Isolate.run`.
///
/// ### Distinction Threshold
///
/// The default distinction threshold is **75%**. This can be overridden via
/// the [distinctionThreshold] parameter on relevant methods.
class AnalyticsEngine {
  // ── Constants ──────────────────────────────────────────────────────

  /// Default distinction threshold (percentage).
  static const double defaultDistinctionThreshold = 75.0;

  /// Default pass mark (percentage).
  static const double defaultPassMark = 50.0;

  /// Number of standard histogram buckets (0–10, 10–20, …, 90–100).
  static const int defaultBucketCount = 10;

  /// Minimum data points required for a reliable trend calculation.
  static const int minTrendDataPoints = 3;

  /// Attendance threshold for the "high attendance" group.
  static const double highAttendanceThreshold = 80.0;

  // ── 1. Class Performance ──────────────────────────────────────────

  /// Computes a comprehensive performance summary for a class.
  ///
  /// Given a list of [results] (overall results for each student in the
  /// class), this method calculates central tendency, pass/distinction
  /// rates, grade and score distributions, and topic-level aggregations.
  ///
  /// When [subjectResults] are provided, a per-subject breakdown is
  /// included in [ClassPerformanceSummary.subjectBreakdown] and topic
  /// performance is aggregated from those results' metadata.
  ///
  /// Set [previousResults] to compute the [ClassPerformanceSummary.improvementRate]
  /// by comparing the current period's average to the previous period's.
  ///
  /// [distinctionThreshold] defaults to [defaultDistinctionThreshold] (75%).
  /// [passMark] defaults to [defaultPassMark] (50%).
  ClassPerformanceSummary computeClassPerformance(
    List<StudentOverallResultEntity> results, {
    List<StudentSubjectResultEntity>? subjectResults,
    List<StudentOverallResultEntity>? previousResults,
    double distinctionThreshold = defaultDistinctionThreshold,
    double passMark = defaultPassMark,
  }) {
    if (results.isEmpty) {
      return ClassPerformanceSummary(
        classId: '',
        totalStudents: 0,
        averageScore: 0,
        highestScore: 0,
        lowestScore: 0,
        medianScore: 0,
        passRate: 0,
        distinctionRate: 0,
        gradeDistribution: {},
        scoreDistribution: _buildEmptyBuckets(),
        topicPerformance: {},
        improvementRate: 0,
      );
    }

    final scores = results.map((r) => r.overallPercentage).toList();
    final classId = results.first.classId;

    // Central tendency
    final average = _mean(scores);
    final highest = _max(scores);
    final lowest = _min(scores);
    final median = _median(scores);

    // Pass & distinction rates
    final passCount = scores.where((s) => s >= passMark).length;
    final distinctionCount = scores.where((s) => s >= distinctionThreshold).length;
    final passRate = (passCount / scores.length) * 100;
    final distinctionRate = (distinctionCount / scores.length) * 100;

    // Grade distribution
    final gradeDistribution = <String, int>{};
    for (final r in results) {
      final grade = r.overallGrade ?? _gradeFromPercentage(r.overallPercentage);
      gradeDistribution[grade] = (gradeDistribution[grade] ?? 0) + 1;
    }

    // Score distribution
    final scoreDistribution = computeScoreDistribution(scores);

    // Topic performance from subject results metadata
    final topicPerformance = _computeTopicPerformanceFromResults(
      subjectResults ?? [],
    );

    // Subject breakdown
    final subjectBreakdown = <String, ClassPerformanceSummary>{};
    if (subjectResults != null && subjectResults.isNotEmpty) {
      final bySubject = _groupBy<String, StudentSubjectResultEntity>(
        subjectResults,
        (r) => r.subjectId,
      );
      for (final entry in bySubject.entries) {
        subjectBreakdown[entry.key] = _computeSubjectSummary(
          entry.value,
          distinctionThreshold: distinctionThreshold,
          passMark: passMark,
        );
      }
    }

    // Improvement rate
    final improvementRate = _computeImprovementRate(results, previousResults);

    return ClassPerformanceSummary(
      classId: classId,
      totalStudents: results.length,
      averageScore: _round2(average),
      highestScore: _round2(highest),
      lowestScore: _round2(lowest),
      medianScore: _round2(median),
      passRate: _round2(passRate),
      distinctionRate: _round2(distinctionRate),
      gradeDistribution: gradeDistribution,
      scoreDistribution: scoreDistribution,
      topicPerformance: topicPerformance,
      improvementRate: _round2(improvementRate),
      subjectBreakdown: subjectBreakdown,
    );
  }

  // ── 2. School Performance ──────────────────────────────────────────

  /// Aggregates multiple [ClassPerformanceSummary] instances into a
  /// school-level summary with cross-class and cross-subject rankings.
  ///
  /// [topicMasteryData] is used to identify the most difficult topic
  /// across the entire school.
  ///
  /// [trendData] provides historical performance data for trend
  /// visualization on dashboards.
  SchoolPerformanceSummary computeSchoolPerformance(
    List<ClassPerformanceSummary> classPerformances, {
    required String schoolId,
    required String academicSessionId,
    List<TopicMasteryEntity>? topicMasteryData,
    List<TrendData>? trendData,
    int totalExams = 0,
  }) {
    if (classPerformances.isEmpty) {
      return SchoolPerformanceSummary(
        schoolId: schoolId,
        academicSessionId: academicSessionId,
        totalStudents: 0,
        totalClasses: 0,
        averageScore: 0,
        passRate: 0,
        distinctionRate: 0,
        bestClassId: null,
        bestSubjectId: null,
        mostDifficultTopicId: null,
        classRankings: [],
        subjectRankings: [],
        gradeDistribution: {},
        trendData: trendData ?? [],
        totalExams: totalExams,
      );
    }

    final totalStudents = classPerformances.fold<int>(
      0,
      (sum, c) => sum + c.totalStudents,
    );

    // Weighted average: weight each class by its student count.
    final weightedSum = classPerformances.fold<double>(
      0,
      (sum, c) => sum + (c.averageScore * c.totalStudents),
    );
    final averageScore = totalStudents > 0 ? weightedSum / totalStudents : 0.0;

    // Weighted pass rate
    final passWeightedSum = classPerformances.fold<double>(
      0,
      (sum, c) => sum + (c.passRate * c.totalStudents),
    );
    final passRate = totalStudents > 0 ? passWeightedSum / totalStudents : 0.0;

    // Weighted distinction rate
    final distinctionWeightedSum = classPerformances.fold<double>(
      0,
      (sum, c) => sum + (c.distinctionRate * c.totalStudents),
    );
    final distinctionRate =
        totalStudents > 0 ? distinctionWeightedSum / totalStudents : 0.0;

    // Class rankings
    final classRankings = _rankEntities(
      classPerformances.map((c) => MapEntry(c.classId, c.averageScore)).toList(),
    );

    // Subject rankings from breakdowns
    final subjectScores = <String, List<double>>{};
    for (final cp in classPerformances) {
      for (final sb in cp.subjectBreakdown.entries) {
        subjectScores.putIfAbsent(sb.key, () => []).add(sb.value.averageScore);
      }
    }
    final subjectAverages = subjectScores.map(
      (k, v) => MapEntry(k, _mean(v)),
    );
    final subjectRankings = _rankEntities(
      subjectAverages.entries.map((e) => MapEntry(e.key, e.value)).toList(),
    );

    // Best class & subject
    final bestClassId = classRankings.isNotEmpty ? classRankings.first.entityId : null;
    final bestSubjectId = subjectRankings.isNotEmpty ? subjectRankings.first.entityId : null;

    // Most difficult topic
    String? mostDifficultTopicId;
    if (topicMasteryData != null && topicMasteryData.isNotEmpty) {
      final difficultTopics = identifyDifficultTopics(topicMasteryData);
      if (difficultTopics.isNotEmpty) {
        mostDifficultTopicId = difficultTopics.first.topicId;
      }
    } else {
      // Fallback: look at topic performance from class summaries
      final allTopics = <String, List<TopicPerformanceData>>{};
      for (final cp in classPerformances) {
        for (final tp in cp.topicPerformance.entries) {
          allTopics.putIfAbsent(tp.key, () => []).add(tp.value);
        }
      }
      if (allTopics.isNotEmpty) {
        String? worstTopic;
        double worstAccuracy = 101;
        for (final entry in allTopics.entries) {
          final avg = _mean(entry.value.map((t) => t.averageAccuracy).toList());
          if (avg < worstAccuracy) {
            worstAccuracy = avg;
            worstTopic = entry.key;
          }
        }
        mostDifficultTopicId = worstTopic;
      }
    }

    // Grade distribution: merge all class distributions
    final gradeDistribution = <String, int>{};
    for (final cp in classPerformances) {
      for (final entry in cp.gradeDistribution.entries) {
        gradeDistribution[entry.key] =
            (gradeDistribution[entry.key] ?? 0) + entry.value;
      }
    }

    return SchoolPerformanceSummary(
      schoolId: schoolId,
      academicSessionId: academicSessionId,
      totalStudents: totalStudents,
      totalClasses: classPerformances.length,
      averageScore: _round2(averageScore),
      passRate: _round2(passRate),
      distinctionRate: _round2(distinctionRate),
      bestClassId: bestClassId,
      bestSubjectId: bestSubjectId,
      mostDifficultTopicId: mostDifficultTopicId,
      classRankings: classRankings,
      subjectRankings: subjectRankings,
      gradeDistribution: gradeDistribution,
      trendData: trendData ?? [],
      totalExams: totalExams,
    );
  }

  // ── 3. Student Trends ─────────────────────────────────────────────

  /// Computes a student's performance trend from historical scores using
  /// simple linear regression.
  ///
  /// [historicalScores] should be ordered chronologically (oldest first).
  /// At least [minTrendDataPoints] data points are needed for a reliable
  /// result; fewer will still produce a trend but with low confidence.
  ///
  /// [strengths] and [weaknesses] are subject/topic IDs where the student
  /// consistently scores above or below their own average.
  StudentTrendAnalysis computeStudentTrends({
    required String studentId,
    required List<double> historicalScores,
    List<String> strengths = const [],
    List<String> weaknesses = const [],
  }) {
    if (historicalScores.length < 2) {
      return StudentTrendAnalysis(
        studentId: studentId,
        trend: PerformanceTrend.stable,
        slope: 0,
        confidence: 0,
        strengths: strengths,
        weaknesses: weaknesses,
        recommendations: _generateRecommendations(
          PerformanceTrend.stable,
          0,
          strengths,
          weaknesses,
        ),
      );
    }

    final regression = _linearRegression(historicalScores);
    final slope = regression.slope;
    final confidence = regression.rSquared;

    // Determine trend from slope
    PerformanceTrend trend;
    if (slope > 1.5) {
      trend = PerformanceTrend.improving;
    } else if (slope < -1.5) {
      trend = PerformanceTrend.declining;
    } else {
      trend = PerformanceTrend.stable;
    }

    final recommendations = _generateRecommendations(
      trend,
      slope,
      strengths,
      weaknesses,
    );

    return StudentTrendAnalysis(
      studentId: studentId,
      trend: trend,
      slope: _round2(slope),
      confidence: _round4(confidence),
      strengths: strengths,
      weaknesses: weaknesses,
      recommendations: recommendations,
    );
  }

  // ── 4. Topic Mastery ──────────────────────────────────────────────

  /// Computes mastery information from a list of [TopicMasteryEntity].
  ///
  /// Each entity is mapped to a [ComputedTopicMastery] with the mastery
  /// level derived from its accuracy percentage. This is useful when you
  /// need to re-evaluate mastery levels based on updated accuracy data.
  List<ComputedTopicMastery> computeTopicMastery(
    List<TopicMasteryEntity> masteryData,
  ) {
    return masteryData.map((m) {
      final derivedLevel = MasteryLevel.fromAccuracy(m.accuracyPercentage);
      return ComputedTopicMastery(
        topicId: m.topicId,
        masteryLevel: derivedLevel,
        accuracy: m.accuracyPercentage,
        avgTimePerQuestion: m.avgTimePerQuestion,
        improvementStreak: m.improvementStreak,
        questionsAttempted: m.questionsAttempted,
        questionsCorrect: m.questionsCorrect,
      );
    }).toList();
  }

  // ── 5. Rankings ───────────────────────────────────────────────────

  /// Generates a ranked list of students from their overall results.
  ///
  /// Uses standard competition ranking (also known as "1224" ranking):
  /// students with identical scores share the same rank, and the next
  /// rank is skipped. For example: 1st, 2nd, 2nd, 4th.
  ///
  /// Results are sorted by [StudentOverallResultEntity.overallPercentage]
  /// in descending order.
  List<RankedStudent> generateRankings(
    List<StudentOverallResultEntity> results,
  ) {
    if (results.isEmpty) return [];

    // Sort descending by percentage
    final sorted = List<StudentOverallResultEntity>.from(results)
      ..sort((a, b) => b.overallPercentage.compareTo(a.overallPercentage));

    final rankings = <RankedStudent>[];
    int? lastRank;
    double? lastScore;

    for (int i = 0; i < sorted.length; i++) {
      final result = sorted[i];
      final position = i + 1;

      // Same score → same rank; otherwise rank = position
      final rank = (lastScore != null &&
              _round2(result.overallPercentage) == _round2(lastScore))
          ? lastRank!
          : position;

      rankings.add(RankedStudent(
        studentId: result.studentId,
        rank: rank,
        score: _round2(result.overallPercentage),
        classId: result.classId,
      ),);

      lastRank = rank;
      lastScore = _round2(result.overallPercentage);
    }

    return rankings;
  }

  // ── 6. Score Distribution ─────────────────────────────────────────

  /// Creates histogram buckets for score visualization.
  ///
  /// By default, creates [defaultBucketCount] buckets of equal width
  /// (0–10, 10–20, …, 90–100). Each bucket is inclusive of its lower
  /// bound and inclusive of its upper bound, except the last bucket
  /// which includes 100.
  ///
  /// Returns a map of range label → midpoint for quick chart integration.
  Map<String, double> computeScoreDistributionMap(List<double> scores) {
    final buckets = computeScoreDistribution(scores);
    return {for (final b in buckets) b.rangeLabel: (b.min + b.max) / 2};
  }

  /// Creates histogram buckets for score visualization.
  ///
  /// Returns a list of [ScoreBucket] instances with count and percentage
  /// for each range.
  List<ScoreBucket> computeScoreDistribution(
    List<double> scores, {
    int bucketCount = defaultBucketCount,
  }) {
    if (scores.isEmpty) return _buildEmptyBuckets(bucketCount: bucketCount);

    final bucketWidth = 100.0 / bucketCount;
    final buckets = <ScoreBucket>[];

    for (int i = 0; i < bucketCount; i++) {
      final min = i * bucketWidth;
      final max = (i + 1) * bucketWidth;

      // For the last bucket, include 100. For others, use strict upper bound.
      final count = scores.where((s) {
        if (i == bucketCount - 1) {
          return s >= min && s <= max;
        }
        return s >= min && s < max;
      }).length;

      final percentage = (count / scores.length) * 100;

      buckets.add(ScoreBucket(
        rangeLabel: '${min.round()}–${max.round()}',
        min: min,
        max: max,
        count: count,
        percentage: _round2(percentage),
      ),);
    }

    return buckets;
  }

  // ── 7. Identify Difficult Topics ──────────────────────────────────

  /// Identifies topics with the lowest accuracy across a class or school.
  ///
  /// Topics are sorted by ascending accuracy (worst first). Use
  /// [maxResults] to limit the number of topics returned.
  List<IdentifiedTopic> identifyDifficultTopics(
    List<TopicMasteryEntity> masteryData, {
    int? maxResults,
  }) {
    if (masteryData.isEmpty) return [];

    // Aggregate by topic ID
    final topicAggregation = <String, _TopicAggregation>{};
    for (final m in masteryData) {
      final agg = topicAggregation.putIfAbsent(
        m.topicId,
        () => _TopicAggregation(topicId: m.topicId, subjectId: m.subjectId),
      );
      agg.addAccuracy(m.accuracyPercentage);
    }

    // Convert and sort by accuracy ascending
    var topics = topicAggregation.values.map((agg) {
      final avgAccuracy = agg.averageAccuracy;
      return IdentifiedTopic(
        topicId: agg.topicId,
        averageAccuracy: _round2(avgAccuracy),
        studentCount: agg.studentCount,
        masteryLevel: MasteryLevel.fromAccuracy(avgAccuracy),
        subjectId: agg.subjectId,
      );
    }).toList()
      ..sort((a, b) => a.averageAccuracy.compareTo(b.averageAccuracy));

    if (maxResults != null && maxResults > 0) {
      topics = topics.take(maxResults).toList();
    }

    return topics;
  }

  // ── 8. Attendance Correlation ─────────────────────────────────────

  /// Computes the Pearson correlation coefficient between attendance
  /// percentage and performance score.
  ///
  /// [attendancePerformancePairs] is a list of (attendance%, score%)
  /// pairs for each student.
  ///
  /// Returns an [AttendanceCorrelation] with the coefficient, sample
  /// size, and a human-readable interpretation.
  AttendanceCorrelation computeAttendanceCorrelation(
    List<({double attendance, double performance})> attendancePerformancePairs,
  ) {
    if (attendancePerformancePairs.length < 3) {
      return AttendanceCorrelation(
        correlationCoefficient: 0,
        sampleSize: attendancePerformancePairs.length,
        interpretation: 'Insufficient data for correlation analysis '
            '(need at least 3 data points)',
      );
    }

    final n = attendancePerformancePairs.length;
    final attendanceValues =
        attendancePerformancePairs.map((p) => p.attendance).toList();
    final performanceValues =
        attendancePerformancePairs.map((p) => p.performance).toList();

    final coefficient =
        _pearsonCorrelation(attendanceValues, performanceValues);

    // Compute average scores for high/low attendance groups
    final highAttendance = attendancePerformancePairs
        .where((p) => p.attendance >= highAttendanceThreshold)
        .map((p) => p.performance)
        .toList();
    final lowAttendance = attendancePerformancePairs
        .where((p) => p.attendance < highAttendanceThreshold)
        .map((p) => p.performance)
        .toList();

    final highAvg = highAttendance.isNotEmpty ? _mean(highAttendance) : null;
    final lowAvg = lowAttendance.isNotEmpty ? _mean(lowAttendance) : null;

    final interpretation = _interpretCorrelation(coefficient);

    return AttendanceCorrelation(
      correlationCoefficient: _round4(coefficient),
      sampleSize: n,
      interpretation: interpretation,
      highAttendanceAvgScore: highAvg != null ? _round2(highAvg) : null,
      lowAttendanceAvgScore: lowAvg != null ? _round2(lowAvg) : null,
    );
  }

  // ── Trend Helper ──────────────────────────────────────────────────

  /// Computes the performance trend from a list of historical scores
  /// using simple linear regression.
  ///
  /// Returns the slope of the best-fit line. A positive slope indicates
  /// improvement, negative indicates decline, and near-zero indicates
  /// stability.
  ///
  /// Requires at least 2 data points; returns 0 otherwise.
  double computeTrend(List<double> historicalScores) {
    if (historicalScores.length < 2) return 0;
    return _round2(_linearRegression(historicalScores).slope);
  }

  // ═══════════════════════════════════════════════════════════════════
  // PRIVATE HELPERS
  // ═══════════════════════════════════════════════════════════════════

  // ── Statistics ─────────────────────────────────────────────────────

  /// Arithmetic mean of a list of numbers.
  static double _mean(List<double> values) {
    if (values.isEmpty) return 0;
    return values.reduce((a, b) => a + b) / values.length;
  }

  /// Maximum value in a list, or 0 if empty.
  static double _max(List<double> values) {
    if (values.isEmpty) return 0;
    return values.reduce((a, b) => a > b ? a : b);
  }

  /// Minimum value in a list, or 0 if empty.
  static double _min(List<double> values) {
    if (values.isEmpty) return 0;
    return values.reduce((a, b) => a < b ? a : b);
  }

  /// Median (50th percentile) of a sorted copy of [values].
  static double _median(List<double> values) {
    if (values.isEmpty) return 0;
    final sorted = List<double>.from(values)..sort();
    final mid = sorted.length ~/ 2;
    if (sorted.length.isEven) {
      return (sorted[mid - 1] + sorted[mid]) / 2;
    }
    return sorted[mid];
  }

  /// Standard deviation (population) of a list.
  static double _standardDeviation(List<double> values) {
    if (values.length < 2) return 0;
    final mean = _mean(values);
    final sumSquaredDiff = values.fold<double>(
      0,
      (sum, v) => sum + (v - mean) * (v - mean),
    );
    return _sqrt(sumSquaredDiff / values.length);
  }

  /// Integer square root approximation for standard deviation.
  /// Uses Newton's method for reasonable precision.
  static double _sqrt(double value) {
    if (value < 0) return 0;
    if (value == 0) return 0;
    double x = value;
    double prev = 0;
    for (int i = 0; i < 20; i++) {
      prev = x;
      x = 0.5 * (x + value / x);
      if ((x - prev).abs() < 0.000001) break;
    }
    return x;
  }

  // ── Linear Regression ──────────────────────────────────────────────

  /// Simple linear regression (OLS) on [y] values with implicit
  /// x = 0, 1, 2, …, n−1.
  ///
  /// Returns the slope, intercept, and R² value.
  static _LinearRegressionResult _linearRegression(List<double> y) {
    final n = y.length;
    if (n < 2) {
      return _LinearRegressionResult(slope: 0, intercept: _mean(y), rSquared: 0);
    }

    // x values: 0, 1, 2, ..., n-1
    final xMean = (n - 1) / 2.0;
    final yMean = _mean(y);

    double sumXY = 0;
    double sumX2 = 0;
    for (int i = 0; i < n; i++) {
      final xDiff = i - xMean;
      final yDiff = y[i] - yMean;
      sumXY += xDiff * yDiff;
      sumX2 += xDiff * xDiff;
    }

    final slope = sumX2 != 0 ? sumXY / sumX2 : 0.0;
    final intercept = yMean - slope * xMean;

    // R² calculation
    final ssTotal = y.fold<double>(0, (sum, v) => sum + (v - yMean) * (v - yMean));
    double ssResidual = 0;
    for (int i = 0; i < n; i++) {
      final predicted = intercept + slope * i;
      ssResidual += (y[i] - predicted) * (y[i] - predicted);
    }
    final rSquared = ssTotal != 0 ? 1 - (ssResidual / ssTotal) : 0.0;

    return _LinearRegressionResult(
      slope: slope,
      intercept: intercept,
      rSquared: rSquared.clamp(0, 1),
    );
  }

  // ── Pearson Correlation ────────────────────────────────────────────

  /// Computes the Pearson correlation coefficient between [x] and [y].
  static double _pearsonCorrelation(List<double> x, List<double> y) {
    assert(x.length == y.length);
    final n = x.length;
    if (n < 2) return 0;

    final xMean = _mean(x);
    final yMean = _mean(y);

    double sumXY = 0;
    double sumX2 = 0;
    double sumY2 = 0;

    for (int i = 0; i < n; i++) {
      final dx = x[i] - xMean;
      final dy = y[i] - yMean;
      sumXY += dx * dy;
      sumX2 += dx * dx;
      sumY2 += dy * dy;
    }

    final denominator = _sqrt(sumX2) * _sqrt(sumY2);
    if (denominator == 0) return 0;
    return (sumXY / denominator).clamp(-1.0, 1.0);
  }

  // ── Grouping & Ranking ────────────────────────────────────────────

  /// Groups [items] by a key extracted via [keyExtractor].
  static Map<K, List<T>> _groupBy<K, T>(
    List<T> items,
    K Function(T) keyExtractor,
  ) {
    final map = <K, List<T>>{};
    for (final item in items) {
      final key = keyExtractor(item);
      map.putIfAbsent(key, () => []).add(item);
    }
    return map;
  }

  /// Ranks entities by score (descending) using competition ranking.
  static List<RankedEntity> _rankEntities(
    List<MapEntry<String, double>> entries,
  ) {
    if (entries.isEmpty) return [];

    // Sort descending by score
    entries.sort((a, b) => b.value.compareTo(a.value));

    final rankings = <RankedEntity>[];
    int? lastRank;
    double? lastScore;

    for (int i = 0; i < entries.length; i++) {
      final position = i + 1;
      final score = _round2(entries[i].value);

      final rank = (lastScore != null && score == lastScore)
          ? lastRank!
          : position;

      rankings.add(RankedEntity(
        entityId: entries[i].key,
        rank: rank,
        score: score,
      ),);

      lastRank = rank;
      lastScore = score;
    }

    return rankings;
  }

  // ── Grade Mapping ──────────────────────────────────────────────────

  /// Maps a percentage to a letter grade using standard Nigerian/WAEC
  /// scale. This is a fallback when [overallGrade] is null.
  static String _gradeFromPercentage(double percentage) {
    if (percentage >= 75) return 'A';
    if (percentage >= 70) return 'B';
    if (percentage >= 65) return 'C';
    if (percentage >= 60) return 'D';
    if (percentage >= 55) return 'E';
    if (percentage >= 50) return 'P';
    return 'F';
  }

  // ── Topic Performance ──────────────────────────────────────────────

  /// Computes topic-level performance from subject results' metadata.
  ///
  /// Subject results may contain topic-level data in their [metadata]
  /// under a `'topic_results'` key, structured as:
  /// ```json
  /// {
  ///   "topicId": { "accuracy": 75.0, "questionsAttempted": 10 },
  ///   ...
  /// }
  /// ```
  Map<String, TopicPerformanceData> _computeTopicPerformanceFromResults(
    List<StudentSubjectResultEntity> subjectResults,
  ) {
    final topicAccuracies = <String, _TopicAggregation>{};

    for (final r in subjectResults) {
      final topicResults = r.metadata['topic_results'];
      if (topicResults is Map<String, dynamic>) {
        for (final entry in topicResults.entries) {
          final topicId = entry.key;
          final data = entry.value;
          if (data is Map<String, dynamic>) {
            final accuracy = (data['accuracy'] as num?)?.toDouble() ?? 0.0;
            final timePerQ = (data['avgTimePerQuestion'] as num?)?.toDouble();
            final agg = topicAccuracies.putIfAbsent(
              topicId,
              () => _TopicAggregation(topicId: topicId),
            );
            agg.addAccuracy(accuracy);
            if (timePerQ != null) {
              agg.addTimePerQuestion(timePerQ);
            }
          }
        }
      }
    }

    return topicAccuracies.map((topicId, agg) {
      final avg = agg.averageAccuracy;
      return MapEntry(
        topicId,
        TopicPerformanceData(
          topicId: topicId,
          averageAccuracy: _round2(avg),
          studentCount: agg.studentCount,
          masteryLevel: MasteryLevel.fromAccuracy(avg),
          averageTimePerQuestion: agg.avgTimePerQuestion != null
              ? _round2(agg.avgTimePerQuestion!)
              : null,
        ),
      );
    });
  }

  // ── Subject Summary ────────────────────────────────────────────────

  /// Computes a [ClassPerformanceSummary] scoped to a single subject.
  ClassPerformanceSummary _computeSubjectSummary(
    List<StudentSubjectResultEntity> results, {
    double distinctionThreshold = defaultDistinctionThreshold,
    double passMark = defaultPassMark,
  }) {
    if (results.isEmpty) {
      return ClassPerformanceSummary(
        classId: '',
        totalStudents: 0,
        averageScore: 0,
        highestScore: 0,
        lowestScore: 0,
        medianScore: 0,
        passRate: 0,
        distinctionRate: 0,
        gradeDistribution: {},
        scoreDistribution: _buildEmptyBuckets(),
        topicPerformance: {},
        improvementRate: 0,
      );
    }

    final scores = results.map((r) => r.percentage).toList();
    final subjectId = results.first.subjectId;
    final classId = results.first.classId;

    final gradeDistribution = <String, int>{};
    for (final r in results) {
      final grade = r.grade ?? _gradeFromPercentage(r.percentage);
      gradeDistribution[grade] = (gradeDistribution[grade] ?? 0) + 1;
    }

    return ClassPerformanceSummary(
      classId: classId,
      subjectId: subjectId,
      totalStudents: results.length,
      averageScore: _round2(_mean(scores)),
      highestScore: _round2(_max(scores)),
      lowestScore: _round2(_min(scores)),
      medianScore: _round2(_median(scores)),
      passRate: _round2(
        (scores.where((s) => s >= passMark).length / scores.length) * 100,
      ),
      distinctionRate: _round2(
        (scores.where((s) => s >= distinctionThreshold).length / scores.length) *
            100,
      ),
      gradeDistribution: gradeDistribution,
      scoreDistribution: computeScoreDistribution(scores),
      topicPerformance: _computeTopicPerformanceFromResults(results),
      improvementRate: 0,
    );
  }

  // ── Improvement Rate ───────────────────────────────────────────────

  /// Computes the improvement rate between current and previous results.
  ///
  /// Returns the average delta in percentage points (positive = improvement).
  /// Matches students by ID. Students not in both lists are excluded.
  static double _computeImprovementRate(
    List<StudentOverallResultEntity> current,
    List<StudentOverallResultEntity>? previous,
  ) {
    if (previous == null || previous.isEmpty) return 0;

    final previousMap = <String, double>{};
    for (final r in previous) {
      previousMap[r.studentId] = r.overallPercentage;
    }

    double totalDelta = 0;
    int matchedCount = 0;
    for (final r in current) {
      final prevScore = previousMap[r.studentId];
      if (prevScore != null) {
        totalDelta += r.overallPercentage - prevScore;
        matchedCount++;
      }
    }

    return matchedCount > 0 ? totalDelta / matchedCount : 0;
  }

  // ── Recommendation Generation ──────────────────────────────────────

  /// Generates AI-style study recommendations based on trend analysis.
  static List<String> _generateRecommendations(
    PerformanceTrend trend,
    double slope,
    List<String> strengths,
    List<String> weaknesses,
  ) {
    final recommendations = <String>[];

    switch (trend) {
      case PerformanceTrend.improving:
        recommendations.add(
          'Your performance is improving! Keep up the consistent effort.',
        );
        if (slope > 5) {
          recommendations.add(
            'Your rate of improvement is impressive. Consider challenging '
            'yourself with more advanced material.',
          );
        }
      case PerformanceTrend.stable:
        recommendations.add(
          'Your performance has been stable. To break through to the next '
          'level, try changing your study approach.',
        );
      case PerformanceTrend.declining:
        recommendations.add(
          'Your performance is trending downward. Consider reviewing '
          'fundamentals and seeking additional help.',
        );
        if (slope < -5) {
          recommendations.add(
            'The decline is significant. It may help to speak with a teacher '
            'or counselor about potential challenges.',
          );
        }
    }

    if (weaknesses.isNotEmpty) {
      recommendations.add(
        'Focus extra study time on your weak areas: '
        '${weaknesses.take(3).join(', ')}.',
      );
    }

    if (strengths.isNotEmpty) {
      recommendations.add(
        'Continue building on your strengths: '
        '${strengths.take(3).join(', ')}.',
      );
    }

    // General study tips based on performance level
    recommendations.add(
      'Practice with past exam questions to identify recurring patterns '
      'and improve time management.',
    );

    return recommendations;
  }

  // ── Correlation Interpretation ─────────────────────────────────────

  /// Returns a human-readable interpretation of a correlation coefficient.
  static String _interpretCorrelation(double r) {
    final absR = r.abs();
    final direction = r >= 0 ? 'positive' : 'negative';

    String strength;
    if (absR >= 0.8) {
      strength = 'very strong';
    } else if (absR >= 0.6) {
      strength = 'strong';
    } else if (absR >= 0.4) {
      strength = 'moderate';
    } else if (absR >= 0.2) {
      strength = 'weak';
    } else {
      strength = 'very weak';
    }

    return 'There is a $strength $direction correlation between attendance '
        'and performance (r = ${r.toStringAsFixed(3)}).';
  }

  // ── Empty Buckets ──────────────────────────────────────────────────

  /// Builds empty histogram buckets for the no-data case.
  static List<ScoreBucket> _buildEmptyBuckets({
    int bucketCount = defaultBucketCount,
  }) {
    final bucketWidth = 100.0 / bucketCount;
    return List.generate(bucketCount, (i) {
      final min = i * bucketWidth;
      final max = (i + 1) * bucketWidth;
      return ScoreBucket(
        rangeLabel: '${min.round()}–${max.round()}',
        min: min,
        max: max,
        count: 0,
        percentage: 0,
      );
    });
  }

  // ── Rounding ──────────────────────────────────────────────────────

  /// Rounds to 2 decimal places.
  static double _round2(double value) {
    return (value * 100).roundToDouble() / 100;
  }

  /// Rounds to 4 decimal places.
  static double _round4(double value) {
    return (value * 10000).roundToDouble() / 10000;
  }
}

// ═══════════════════════════════════════════════════════════════════════
// INTERNAL HELPERS
// ═══════════════════════════════════════════════════════════════════════

/// Result of a simple linear regression.
class _LinearRegressionResult {
  const _LinearRegressionResult({
    required this.slope,
    required this.intercept,
    required this.rSquared,
  });

  final double slope;
  final double intercept;
  final double rSquared;
}

/// Mutable accumulator for topic-level aggregation.
class _TopicAggregation {
  _TopicAggregation({required this.topicId, this.subjectId});

  final String topicId;
  final String? subjectId;

  final List<double> _accuracies = [];
  final List<double> _timesPerQuestion = [];

  void addAccuracy(double accuracy) => _accuracies.add(accuracy);
  void addTimePerQuestion(double seconds) => _timesPerQuestion.add(seconds);

  int get studentCount => _accuracies.length;

  double get averageAccuracy =>
      _accuracies.isNotEmpty ? _accuracies.reduce((a, b) => a + b) / _accuracies.length : 0;

  double? get avgTimePerQuestion =>
      _timesPerQuestion.isNotEmpty
          ? _timesPerQuestion.reduce((a, b) => a + b) / _timesPerQuestion.length
          : null;
}
