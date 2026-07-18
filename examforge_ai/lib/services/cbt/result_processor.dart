import '../../../features/cbt_engine/domain/entities/cbt_entities.dart';
import '../../../features/question_bank/domain/entities/question_entities.dart';
import '../../core/utils/logger.dart';

// ═══════════════════════════════════════════════════════════════════════
// RESULT PROCESSOR SERVICE
// ═══════════════════════════════════════════════════════════════════════
// Handles auto-grading of objective questions, score calculation,
// grade scale application, statistics computation, and ranking
// generation for exam results.
// ═══════════════════════════════════════════════════════════════════════

class ResultProcessor {
  // ═══════════════════════════════════════════════════════════════════
  // Auto-Grade Objective Questions
  // ═══════════════════════════════════════════════════════════════════

  /// Auto-grade all objective (auto-gradable) questions in an attempt.
  ///
  /// Returns an [ExamResultEntity] with computed scores. Subjective
  /// questions (essay, short answer) are left ungraded (marksAwarded = 0).
  ExamResultEntity autoGradeObjective(
    ExamAttemptEntity attempt,
    ExamEntity exam,
    List<StudentAnswerEntity> answers,
  ) {
    AppLogger.info(
      'Auto-grading ${answers.length} answers for attempt ${attempt.id}',
    );

    double totalMarks = 0;
    double totalPossible = exam.totalMarks;
    int autoGradedCount = 0;
    int subjectiveCount = 0;

    for (final answer in answers) {
      final examQuestion = exam.questions
          .where((q) => q.questionId == answer.questionId)
          .firstOrNull;

      if (examQuestion == null) continue;

      final question = examQuestion.question;
      if (question == null) continue;

      // Only auto-grade objective question types
      if (_isAutoGradable(question.questionType)) {
        final gradedAnswer = gradeAnswer(answer, question, examQuestion);
        totalMarks += gradedAnswer.marksAwarded - gradedAnswer.marksDeducted;
        autoGradedCount++;
      } else {
        subjectiveCount++;
      }
    }

    final scorePercentage =
        totalPossible > 0 ? (totalMarks / totalPossible) * 100 : 0.0;

    // Determine effective pass mark
    final effectivePassMark = exam.passMarkType == 'percentage'
        ? exam.passMark
        : (totalPossible > 0 ? (exam.passMark / totalPossible) * 100 : 0.0);

    final isPassed = scorePercentage >= effectivePassMark;
    final gradingStatus = subjectiveCount > 0
        ? GradingStatus.partiallyGraded
        : GradingStatus.autoGraded;

    final now = DateTime.now();

    return ExamResultEntity(
      id: 'result_${attempt.id}',
      examId: exam.id,
      studentId: attempt.studentId,
      attemptId: attempt.id,
      totalMarks: totalMarks,
      totalPossible: totalPossible,
      scorePercentage: scorePercentage,
      isPassed: isPassed,
      timeSpentSeconds: attempt.timeSpentSeconds,
      gradingStatus: gradingStatus,
      isReleased: false,
      createdAt: now,
      updatedAt: now,
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // Grade a Single Answer
  // ═══════════════════════════════════════════════════════════════════

  /// Grade a single student answer against the correct answer.
  ///
  /// Handles all question types:
  /// - Multiple choice: check selected option against correct option
  /// - Multiple response: check all selected options
  /// - True/false: check boolean value
  /// - Fill-in-blank: check each blank answer
  /// - Matching: check each pair
  /// - Ordering: check order of items
  /// - Numerical: check numeric value within tolerance
  /// - Essay/short answer: cannot auto-grade
  StudentAnswerEntity gradeAnswer(
    StudentAnswerEntity answer,
    QuestionEntity question,
    ExamQuestionEntity examQuestion,
  ) {
    double marksAwarded = 0;
    double marksDeducted = 0;
    bool? isCorrect;

    switch (question.questionType) {
      case QuestionType.multipleChoice:
        final result = _gradeMultipleChoice(answer, question, examQuestion);
        marksAwarded = result.marksAwarded;
        marksDeducted = result.marksDeducted;
        isCorrect = result.isCorrect;

      case QuestionType.multipleResponse:
        final result = _gradeMultipleResponse(answer, question, examQuestion);
        marksAwarded = result.marksAwarded;
        marksDeducted = result.marksDeducted;
        isCorrect = result.isCorrect;

      case QuestionType.trueFalse:
        final result = _gradeTrueFalse(answer, question, examQuestion);
        marksAwarded = result.marksAwarded;
        marksDeducted = result.marksDeducted;
        isCorrect = result.isCorrect;

      case QuestionType.fillInBlank:
        final result = _gradeFillInTheBlank(answer, question, examQuestion);
        marksAwarded = result.marksAwarded;
        marksDeducted = result.marksDeducted;
        isCorrect = result.isCorrect;

      case QuestionType.matching:
        final result = _gradeMatching(answer, question, examQuestion);
        marksAwarded = result.marksAwarded;
        marksDeducted = result.marksDeducted;
        isCorrect = result.isCorrect;

      case QuestionType.ordering:
        final result = _gradeOrdering(answer, question, examQuestion);
        marksAwarded = result.marksAwarded;
        marksDeducted = result.marksDeducted;
        isCorrect = result.isCorrect;

      case QuestionType.numerical:
        final result = _gradeNumerical(answer, question, examQuestion);
        marksAwarded = result.marksAwarded;
        marksDeducted = result.marksDeducted;
        isCorrect = result.isCorrect;

      case QuestionType.imageBased:
      case QuestionType.audioBased:
      case QuestionType.videoBased:
        // Media-based questions use the same grading as multiple choice
        // since they have options and correct answers
        final result = _gradeMultipleChoice(answer, question, examQuestion);
        marksAwarded = result.marksAwarded;
        marksDeducted = result.marksDeducted;
        isCorrect = result.isCorrect;

      case QuestionType.essay:
      case QuestionType.shortAnswer:
      case QuestionType.practical:
      case QuestionType.caseStudy:
        // Cannot auto-grade subjective questions
        marksAwarded = 0;
        marksDeducted = 0;
        isCorrect = null;
    }

    return answer.copyWith(
      marksAwarded: marksAwarded,
      marksDeducted: marksDeducted,
      isCorrect: isCorrect,
      gradedAt: DateTime.now(),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // Calculate Total Score
  // ═══════════════════════════════════════════════════════════════════

  /// Calculate the total score from a list of graded answers.
  ///
  /// Sums marksAwarded and subtracts marksDeducted for all answers.
  double calculateTotalScore(List<StudentAnswerEntity> answers) {
    double total = 0;
    for (final answer in answers) {
      total += answer.marksAwarded - answer.marksDeducted;
    }
    return total;
  }

  // ═══════════════════════════════════════════════════════════════════
  // Apply Grade Scale
  // ═══════════════════════════════════════════════════════════════════

  /// Apply a grade scale to convert a percentage score to a letter grade.
  ///
  /// Iterates through [GradeScaleEntry] items in the scale and returns
  /// the grade of the first entry where [percentage] falls within the
  /// min/max range. Returns 'N/A' if no matching entry is found.
  String applyGradeScale(double percentage, GradeScaleEntity scale) {
    for (final entry in scale.scaleEntries) {
      if (percentage >= entry.minPercentage && percentage <= entry.maxPercentage) {
        return entry.grade;
      }
    }
    return 'N/A';
  }

  // ═══════════════════════════════════════════════════════════════════
  // Calculate Statistics
  // ═══════════════════════════════════════════════════════════════════

  /// Calculate comprehensive statistics for an exam from its results.
  ///
  /// Computes average, highest, lowest, median scores, pass rate,
  /// per-question correct rates, and grading completion percentage.
  ExamStatistics calculateStatistics(
    List<ExamResultEntity> results,
    ExamEntity exam,
  ) {
    if (results.isEmpty) {
      return ExamStatistics(
        examId: exam.id,
        totalStudents: 0,
        startedStudents: 0,
        completedStudents: 0,
        submittedStudents: 0,
        averageScore: 0,
        highestScore: 0,
        lowestScore: 0,
        medianScore: 0,
        passRate: 0,
        questionsByCorrectRate: {},
        averageTimeSpentSeconds: 0,
        gradingCompletionPercentage: 0,
      );
    }

    final scores = results.map((r) => r.scorePercentage).toList();
    final sortedScores = List<double>.from(scores)..sort();

    final totalStudents = exam.maxStudents ?? results.length;
    final startedStudents = results.length;
    final completedStudents =
        results.where((r) => r.gradingStatus.isComplete).length;
    final submittedStudents = results.length;

    // Average score
    final averageScore =
        scores.reduce((a, b) => a + b) / scores.length;

    // Highest / lowest
    final highestScore = sortedScores.last;
    final lowestScore = sortedScores.first;

    // Median
    final mid = sortedScores.length ~/ 2;
    final medianScore = sortedScores.length.isEven
        ? (sortedScores[mid - 1] + sortedScores[mid]) / 2
        : sortedScores[mid];

    // Pass rate
    final passedCount = results.where((r) => r.isPassed).length;
    final passRate = (passedCount / results.length) * 100;

    // Average time spent
    final timeSpent = results.map((r) => r.timeSpentSeconds).toList();
    final averageTimeSpent =
        timeSpent.reduce((a, b) => a + b) ~/ timeSpent.length;

    // Grading completion
    final fullyGradedCount =
        results.where((r) => r.gradingStatus.isComplete).length;
    final gradingCompletion =
        (fullyGradedCount / results.length) * 100;

    // Per-question correct rate (computed from answer data if available)
    final questionsByCorrectRate = <String, double>{};
    for (final question in exam.questions) {
      questionsByCorrectRate[question.questionId] = 0.0;
      // Actual per-question rates require access to individual answer data
      // which is not in the result entity. This would require additional
      // data fetching in a real implementation.
    }

    return ExamStatistics(
      examId: exam.id,
      totalStudents: totalStudents,
      startedStudents: startedStudents,
      completedStudents: completedStudents,
      submittedStudents: submittedStudents,
      averageScore: averageScore,
      highestScore: highestScore,
      lowestScore: lowestScore,
      medianScore: medianScore,
      passRate: passRate,
      questionsByCorrectRate: questionsByCorrectRate,
      averageTimeSpentSeconds: averageTimeSpent,
      gradingCompletionPercentage: gradingCompletion,
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // Generate Rankings
  // ═══════════════════════════════════════════════════════════════════

  /// Generate exam rankings from a list of results.
  ///
  /// Sorts results by score (descending) and assigns ranks.
  /// Ties receive the same rank with the next rank(s) skipped.
  List<ExamRankingEntity> generateRankings(
    List<ExamResultEntity> results,
    String examId,
  ) {
    // Sort by score percentage descending
    final sorted = List<ExamResultEntity>.from(results)
      ..sort((a, b) => b.scorePercentage.compareTo(a.scorePercentage));

    final rankings = <ExamRankingEntity>[];
    int currentRank = 1;

    for (var i = 0; i < sorted.length; i++) {
      final result = sorted[i];

      // Handle ties: same score = same rank
      if (i > 0 && result.scorePercentage < sorted[i - 1].scorePercentage) {
        currentRank = i + 1;
      }

      rankings.add(ExamRankingEntity(
        id: 'rank_${result.attemptId}',
        examId: examId,
        studentId: result.studentId,
        attemptId: result.attemptId,
        rank: currentRank,
        totalMarks: result.totalMarks,
        scorePercentage: result.scorePercentage,
        createdAt: DateTime.now(),
      ));
    }

    return rankings;
  }

  // ═══════════════════════════════════════════════════════════════════
  // PRIVATE GRADING HELPERS
  // ═══════════════════════════════════════════════════════════════════

  /// Check if a question type can be auto-graded.
  bool _isAutoGradable(QuestionType type) {
    return switch (type) {
      QuestionType.multipleChoice ||
      QuestionType.multipleResponse ||
      QuestionType.trueFalse ||
      QuestionType.fillInBlank ||
      QuestionType.matching ||
      QuestionType.ordering ||
      QuestionType.numerical ||
      QuestionType.imageBased ||
      QuestionType.audioBased ||
      QuestionType.videoBased =>
        true,
      QuestionType.essay ||
      QuestionType.shortAnswer ||
      QuestionType.practical ||
      QuestionType.caseStudy =>
        false,
    };
  }

  /// Grade a multiple choice answer.
  _GradeResult _gradeMultipleChoice(
    StudentAnswerEntity answer,
    QuestionEntity question,
    ExamQuestionEntity examQuestion,
  ) {
    final selectedOptionId =
        answer.answerData['selected_option_id'] as String? ??
            answer.answerData['selectedOptionId'] as String?;

    if (selectedOptionId == null) {
      // No answer provided
      return _GradeResult(
        marksAwarded: 0,
        marksDeducted: 0,
        isCorrect: false,
      );
    }

    // Find the correct option
    final correctOption = question.answerOptions
        .where((o) => o.isCorrect)
        .firstOrNull;

    final isCorrect = correctOption != null && selectedOptionId == correctOption.id;

    return _GradeResult(
      marksAwarded: isCorrect ? examQuestion.marks : 0,
      marksDeducted: isCorrect
          ? 0
          : (examQuestion.negativeMarks > 0 ? examQuestion.negativeMarks : 0),
      isCorrect: isCorrect,
    );
  }

  /// Grade a multiple response answer.
  _GradeResult _gradeMultipleResponse(
    StudentAnswerEntity answer,
    QuestionEntity question,
    ExamQuestionEntity examQuestion,
  ) {
    final selectedIds = (answer.answerData['selected_option_ids'] as List<dynamic>? ??
            answer.answerData['selectedOptionIds'] as List<dynamic>? ??
            [])
        .cast<String>();

    final correctIds = question.answerOptions
        .where((o) => o.isCorrect)
        .map((o) => o.id)
        .toSet();

    final selectedSet = selectedIds.toSet();

    // All correct selected and no incorrect selected = full marks
    final isFullyCorrect =
        selectedSet.containsAll(correctIds) && selectedSet.length == correctIds.length;

    if (isFullyCorrect) {
      return _GradeResult(
        marksAwarded: examQuestion.marks,
        marksDeducted: 0,
        isCorrect: true,
      );
    }

    // Partial credit: count correct selections minus incorrect selections
    final correctSelections = selectedSet.intersection(correctIds).length;
    final incorrectSelections = selectedSet.difference(correctIds).length;

    if (correctSelections == 0) {
      // No correct selections at all
      return _GradeResult(
        marksAwarded: 0,
        marksDeducted: examQuestion.negativeMarks > 0 ? examQuestion.negativeMarks : 0,
        isCorrect: false,
      );
    }

    // Partial credit proportional to correct selections
    final partialMarks =
        (examQuestion.marks * correctSelections / correctIds.length) -
            (incorrectSelections * (examQuestion.negativeMarks > 0
                ? examQuestion.negativeMarks / correctIds.length
                : 0));

    return _GradeResult(
      marksAwarded: partialMarks > 0 ? partialMarks : 0,
      marksDeducted: 0,
      isCorrect: false,
    );
  }

  /// Grade a true/false answer.
  _GradeResult _gradeTrueFalse(
    StudentAnswerEntity answer,
    QuestionEntity question,
    ExamQuestionEntity examQuestion,
  ) {
    final selectedOptionId =
        answer.answerData['selected_option_id'] as String? ??
            answer.answerData['selectedOptionId'] as String?;

    if (selectedOptionId == null) {
      return _GradeResult(
        marksAwarded: 0,
        marksDeducted: 0,
        isCorrect: false,
      );
    }

    final correctOption = question.answerOptions
        .where((o) => o.isCorrect)
        .firstOrNull;

    final isCorrect = correctOption != null && selectedOptionId == correctOption.id;

    return _GradeResult(
      marksAwarded: isCorrect ? examQuestion.marks : 0,
      marksDeducted: isCorrect
          ? 0
          : (examQuestion.negativeMarks > 0 ? examQuestion.negativeMarks : 0),
      isCorrect: isCorrect,
    );
  }

  /// Grade a fill-in-the-blank answer.
  _GradeResult _gradeFillInTheBlank(
    StudentAnswerEntity answer,
    QuestionEntity question,
    ExamQuestionEntity examQuestion,
  ) {
    final blanks = answer.answerData['blanks'] as List<dynamic>? ?? [];

    if (blanks.isEmpty) {
      return _GradeResult(
        marksAwarded: 0,
        marksDeducted: 0,
        isCorrect: false,
      );
    }

    int correctBlanks = 0;
    final totalBlanks = question.fillInBlankAnswers.length;

    for (final blank in blanks) {
      if (blank is! Map<String, dynamic>) continue;

      final index = blank['index'] as int? ?? -1;
      final studentAnswerRaw = blank['answer'] as String? ?? '';
      final studentAnswerLower = studentAnswerRaw.trim().toLowerCase();

      if (index < 0 || index >= question.fillInBlankAnswers.length) continue;

      final fillBlank = question.fillInBlankAnswers[index];
      final isCaseSensitive = fillBlank.isCaseSensitive;
      final acceptableAnswers = fillBlank.acceptableAnswers;

      // Check if student's answer matches any acceptable answer
      final isMatch = acceptableAnswers.any((acceptable) {
        if (isCaseSensitive) {
          return studentAnswerRaw.trim() == acceptable.trim();
        }
        return studentAnswerLower == acceptable.trim().toLowerCase();
      });

      if (isMatch) {
        correctBlanks++;
      }
    }

    final isFullyCorrect = correctBlanks == totalBlanks && totalBlanks > 0;
    final partialMarks =
        totalBlanks > 0 ? (examQuestion.marks * correctBlanks / totalBlanks) : 0.0;

    return _GradeResult(
      marksAwarded: partialMarks,
      marksDeducted: isFullyCorrect ? 0 : (examQuestion.negativeMarks > 0 && correctBlanks == 0 ? examQuestion.negativeMarks : 0),
      isCorrect: isFullyCorrect,
    );
  }

  /// Grade a matching answer.
  _GradeResult _gradeMatching(
    StudentAnswerEntity answer,
    QuestionEntity question,
    ExamQuestionEntity examQuestion,
  ) {
    final pairs = answer.answerData['pairs'] as List<dynamic>? ?? [];

    if (pairs.isEmpty) {
      return _GradeResult(
        marksAwarded: 0,
        marksDeducted: 0,
        isCorrect: false,
      );
    }

    int correctPairs = 0;
    final totalPairs = question.matchingPairs.length;

    // Build a map of correct left → right using pair IDs.
    // Each MatchingPairEntity has an `id`, `leftContent`, and `rightContent`.
    // In the student answer, `left_id` is the pair ID of the left item,
    // and `right_id` is the pair ID of the right item the student selected.
    // A correct match is when left_id maps to right_id, where right_id
    // points to the same pair (since each pair represents a correct
    // left-right relationship).
    final correctMapping = <String, String>{};
    for (final pair in question.matchingPairs) {
      // Each pair's id serves as both the left and right identifier
      // for the correct mapping.
      correctMapping[pair.id] = pair.id;
    }

    for (final pair in pairs) {
      if (pair is! Map<String, dynamic>) continue;

      final leftId = pair['left_id'] as String? ?? pair['leftId'] as String? ?? '';
      final rightId = pair['right_id'] as String? ?? pair['rightId'] as String? ?? '';

      if (correctMapping[leftId] == rightId) {
        correctPairs++;
      }
    }

    final isFullyCorrect = correctPairs == totalPairs && totalPairs > 0;
    final partialMarks =
        totalPairs > 0 ? (examQuestion.marks * correctPairs / totalPairs) : 0.0;

    return _GradeResult(
      marksAwarded: partialMarks,
      marksDeducted: 0,
      isCorrect: isFullyCorrect,
    );
  }

  /// Grade an ordering answer.
  _GradeResult _gradeOrdering(
    StudentAnswerEntity answer,
    QuestionEntity question,
    ExamQuestionEntity examQuestion,
  ) {
    final orderedIds = (answer.answerData['ordered_ids'] as List<dynamic>? ??
            answer.answerData['orderedIds'] as List<dynamic>? ??
            [])
        .cast<String>();

    if (orderedIds.isEmpty) {
      return _GradeResult(
        marksAwarded: 0,
        marksDeducted: 0,
        isCorrect: false,
      );
    }

    final correctOrder = question.orderingItems
        .toList()
      ..sort((a, b) => a.correctPosition.compareTo(b.correctPosition));

    final correctIds = correctOrder.map((item) => item.id).toList();

    int correctPositions = 0;
    for (var i = 0; i < orderedIds.length && i < correctIds.length; i++) {
      if (orderedIds[i] == correctIds[i]) {
        correctPositions++;
      }
    }

    final isFullyCorrect = correctPositions == correctIds.length && correctIds.isNotEmpty;
    final partialMarks = correctIds.isNotEmpty
        ? (examQuestion.marks * correctPositions / correctIds.length)
        : 0.0;

    return _GradeResult(
      marksAwarded: partialMarks,
      marksDeducted: 0,
      isCorrect: isFullyCorrect,
    );
  }

  /// Grade a numerical answer.
  _GradeResult _gradeNumerical(
    StudentAnswerEntity answer,
    QuestionEntity question,
    ExamQuestionEntity examQuestion,
  ) {
    final studentValue = answer.answerData['value'];

    if (studentValue == null) {
      return _GradeResult(
        marksAwarded: 0,
        marksDeducted: 0,
        isCorrect: false,
      );
    }

    // Try to parse the student's answer as a double
    double? studentNum;
    if (studentValue is num) {
      studentNum = studentValue.toDouble();
    } else if (studentValue is String) {
      studentNum = double.tryParse(studentValue);
    }

    if (studentNum == null) {
      return _GradeResult(
        marksAwarded: 0,
        marksDeducted: examQuestion.negativeMarks > 0 ? examQuestion.negativeMarks : 0,
        isCorrect: false,
      );
    }

    // Get the correct value from metadata or content
    final correctValue = question.metadata?['numerical_answer'] as num?;
    final tolerance = question.metadata?['tolerance'] as num? ?? 0.01;

    if (correctValue == null) {
      // Cannot grade without a correct value
      return _GradeResult(
        marksAwarded: 0,
        marksDeducted: 0,
        isCorrect: null,
      );
    }

    final difference = (studentNum - correctValue).abs();
    final isCorrect = difference <= tolerance;

    return _GradeResult(
      marksAwarded: isCorrect ? examQuestion.marks : 0,
      marksDeducted: isCorrect
          ? 0
          : (examQuestion.negativeMarks > 0 ? examQuestion.negativeMarks : 0),
      isCorrect: isCorrect,
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// INTERNAL GRADING RESULT
// ═══════════════════════════════════════════════════════════════════════

/// Internal helper class to return grading results from individual
/// grading methods.
class _GradeResult {
  const _GradeResult({
    required this.marksAwarded,
    required this.marksDeducted,
    required this.isCorrect,
  });

  final double marksAwarded;
  final double marksDeducted;
  final bool? isCorrect;
}
