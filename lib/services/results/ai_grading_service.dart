import 'dart:async';
import 'dart:convert';

import '../../core/utils/logger.dart';
import '../../features/ai_generator/domain/entities/ai_entities.dart';
import '../ai/ai_provider_interface.dart';
import '../ai/ai_service.dart';
import '../ai/prompt_engine.dart';

// ═══════════════════════════════════════════════════════════════════════
// ENUMS
// ═══════════════════════════════════════════════════════════════════════

/// Controls how strictly the AI should grade subjective answers.
///
/// - [lenient]: Favors the student; partial credit is given generously,
///   minor omissions are overlooked.
/// - [standard]: Balanced grading; follows the marking scheme closely
///   while allowing reasonable interpretation.
/// - [strict]: Rigorous grading; demands precise, complete answers that
///   closely match the marking scheme with no leniency for omissions.
enum GradingStrictness {
  lenient(
    value: 'lenient',
    label: 'Lenient',
    description: 'Favors the student; partial credit is given generously.',
  ),
  standard(
    value: 'standard',
    label: 'Standard',
    description: 'Balanced grading following the marking scheme closely.',
  ),
  strict(
    value: 'strict',
    label: 'Strict',
    description: 'Rigorous grading demanding precise, complete answers.',
  );

  const GradingStrictness({
    required this.value,
    required this.label,
    required this.description,
  });

  /// Serialized value stored in the database / API payloads.
  final String value;

  /// Human-readable display name.
  final String label;

  /// Short description for UI tooltips.
  final String description;
}

// ═══════════════════════════════════════════════════════════════════════
// DATA MODELS
// ═══════════════════════════════════════════════════════════════════════

/// The structured result returned by the AI grading service for a single
/// essay / subjective answer.
class EssayGradingResult {
  const EssayGradingResult({
    required this.suggestedScore,
    required this.maxPossible,
    required this.confidenceScore,
    required this.explanation,
    required this.strengths,
    required this.weaknesses,
    required this.suggestions,
    required this.gradingRubric,
    required this.inputTokens,
    required this.outputTokens,
    required this.processingTimeMs,
    this.error,
  });

  /// The score suggested by the AI (0 to [maxPossible]).
  final double suggestedScore;

  /// The maximum possible score for this question.
  final double maxPossible;

  /// How confident the AI is in its grading, from 0.0 (uncertain) to
  /// 1.0 (highly confident).
  final double confidenceScore;

  /// Detailed explanation of why this score was assigned.
  final String explanation;

  /// Aspects of the answer that were well done.
  final List<String> strengths;

  /// Aspects of the answer that were lacking or incorrect.
  final List<String> weaknesses;

  /// Actionable suggestions for how the student can improve.
  final List<String> suggestions;

  /// Per-criterion rubric breakdown, e.g.
  /// ```json
  /// {
  ///   "content_accuracy": {"score": 3, "max": 5, "notes": "..."},
  ///   "organization": {"score": 4, "max": 5, "notes": "..."},
  /// }
  /// ```
  final Map<String, dynamic> gradingRubric;

  /// Number of input tokens consumed by this grading call.
  final int inputTokens;

  /// Number of output tokens consumed by this grading call.
  final int outputTokens;

  /// Wall-clock time spent on the AI call, in milliseconds.
  final int processingTimeMs;

  /// Non-null when grading failed or produced an unrecoverable error.
  /// When set, callers should treat the other fields as unreliable.
  final String? error;

  /// Whether the grading completed without error.
  bool get isSuccess => error == null;

  /// Percentage score (0–100). Returns 0 if [maxPossible] is 0.
  double get percentage =>
      maxPossible > 0 ? (suggestedScore / maxPossible) * 100 : 0;

  /// Total tokens consumed (input + output).
  int get totalTokens => inputTokens + outputTokens;

  EssayGradingResult copyWith({
    double? suggestedScore,
    double? maxPossible,
    double? confidenceScore,
    String? explanation,
    List<String>? strengths,
    List<String>? weaknesses,
    List<String>? suggestions,
    Map<String, dynamic>? gradingRubric,
    int? inputTokens,
    int? outputTokens,
    int? processingTimeMs,
    String? error,
  }) {
    return EssayGradingResult(
      suggestedScore: suggestedScore ?? this.suggestedScore,
      maxPossible: maxPossible ?? this.maxPossible,
      confidenceScore: confidenceScore ?? this.confidenceScore,
      explanation: explanation ?? this.explanation,
      strengths: strengths ?? this.strengths,
      weaknesses: weaknesses ?? this.weaknesses,
      suggestions: suggestions ?? this.suggestions,
      gradingRubric: gradingRubric ?? this.gradingRubric,
      inputTokens: inputTokens ?? this.inputTokens,
      outputTokens: outputTokens ?? this.outputTokens,
      processingTimeMs: processingTimeMs ?? this.processingTimeMs,
      error: error ?? this.error,
    );
  }

  @override
  String toString() => 'EssayGradingResult(score: $suggestedScore/$maxPossible, '
      'confidence: ${confidenceScore.toStringAsFixed(2)}, '
      'time: ${processingTimeMs}ms)';
}

/// Tracks the progress of a batch grading operation.
class BatchGradingProgress {
  const BatchGradingProgress({
    required this.batchId,
    required this.totalAnswers,
    this.completedAnswers = 0,
    this.failedAnswers = 0,
    this.results = const [],
    this.currentQuestionIndex,
    this.status = BatchGradingStatus.pending,
    this.error,
  });

  /// Unique identifier for this batch operation.
  final String batchId;

  /// Total number of answers in the batch.
  final int totalAnswers;

  /// Number of answers that have been graded successfully.
  final int completedAnswers;

  /// Number of answers that failed to grade.
  final int failedAnswers;

  /// Results collected so far (populated as each answer is graded).
  final List<EssayGradingResult> results;

  /// Index of the answer currently being graded (0-based).
  final int? currentQuestionIndex;

  /// Current status of the batch operation.
  final BatchGradingStatus status;

  /// Error message if the entire batch failed.
  final String? error;

  /// Progress as a fraction (0.0–1.0).
  double get progress {
    if (totalAnswers == 0) return 0.0;
    return ((completedAnswers + failedAnswers) / totalAnswers)
        .clamp(0.0, 1.0);
  }

  /// Whether the batch has finished (completed or failed).
  bool get isDone =>
      status == BatchGradingStatus.completed ||
      status == BatchGradingStatus.failed;

  /// Total tokens consumed across all graded answers so far.
  int get totalInputTokens =>
      results.fold(0, (sum, r) => sum + r.inputTokens);

  /// Total output tokens consumed across all graded answers so far.
  int get totalOutputTokens =>
      results.fold(0, (sum, r) => sum + r.outputTokens);

  BatchGradingProgress copyWith({
    String? batchId,
    int? totalAnswers,
    int? completedAnswers,
    int? failedAnswers,
    List<EssayGradingResult>? results,
    int? currentQuestionIndex,
    BatchGradingStatus? status,
    String? error,
  }) {
    return BatchGradingProgress(
      batchId: batchId ?? this.batchId,
      totalAnswers: totalAnswers ?? this.totalAnswers,
      completedAnswers: completedAnswers ?? this.completedAnswers,
      failedAnswers: failedAnswers ?? this.failedAnswers,
      results: results ?? this.results,
      currentQuestionIndex:
          currentQuestionIndex ?? this.currentQuestionIndex,
      status: status ?? this.status,
      error: error ?? this.error,
    );
  }

  @override
  String toString() => 'BatchGradingProgress(batch: $batchId, '
      '${completedAnswers + failedAnswers}/$totalAnswers, '
      'progress: ${(progress * 100).toStringAsFixed(1)}%, '
      'status: $status)';
}

/// Status of a batch grading operation.
enum BatchGradingStatus {
  /// The batch has been created but grading has not started.
  pending,

  /// Grading is in progress.
  inProgress,

  /// All answers have been graded (some may have failed individually).
  completed,

  /// The batch operation itself failed before completing all answers.
  failed,

  /// The batch was cancelled by the caller.
  cancelled,
}

/// A single answer to be graded, bundled with its context.
class EssayAnswerInput {
  const EssayAnswerInput({
    required this.questionText,
    required this.studentAnswer,
    required this.markingScheme,
    required this.maxMarks,
    this.questionType = 'essay',
    this.subject,
    this.gradeLevel,
    this.bloomLevel,
    this.strictness = GradingStrictness.standard,
  });

  /// The full text of the question being answered.
  final String questionText;

  /// The student's answer text.
  final String studentAnswer;

  /// The marking scheme / rubric describing expected answer content
  /// and point allocation.
  final String markingScheme;

  /// Maximum marks attainable for this question.
  final double maxMarks;

  /// Type of question (e.g. "essay", "short_answer", "case_study",
  /// "practical").
  final String questionType;

  /// Optional subject context (e.g. "Biology", "History").
  final String? subject;

  /// Optional grade / class level (e.g. "SS2", "Grade 10").
  final String? gradeLevel;

  /// Optional Bloom's taxonomy level (e.g. "remember", "analyze").
  final String? bloomLevel;

  /// Grading strictness for this answer.
  final GradingStrictness strictness;
}

// ═══════════════════════════════════════════════════════════════════════
// AI GRADING SERVICE
// ═══════════════════════════════════════════════════════════════════════

/// Orchestrates AI-assisted grading of subjective questions (essays,
/// short answers, case studies, practical responses).
///
/// This service leverages the existing AI infrastructure ([AiService] for
/// provider access and [PromptEngine] for prompt construction) to evaluate
/// student answers against a marking scheme and produce structured grading
/// results with scores, feedback, and rubric breakdowns.
///
/// Usage:
/// ```dart
/// final gradingService = AiGradingService(
///   aiService: aiService,
///   promptEngine: promptEngine,
/// );
///
/// final result = await gradingService.gradeEssayAnswer(
///   questionText: 'Explain the causes of World War I...',
///   studentAnswer: 'The main causes include...',
///   markingScheme: 'Look for: alliance systems (3 marks), ...',
///   maxMarks: 20,
/// );
///
/// if (result.isSuccess) {
///   print('Score: ${result.suggestedScore}/${result.maxPossible}');
///   print('Strengths: ${result.strengths}');
/// }
/// ```
class AiGradingService {
  AiGradingService({
    required AiService aiService,
    required PromptEngine promptEngine,
    this.defaultStrictness = GradingStrictness.standard,
    this.defaultTemperature = 0.3,
    this.defaultMaxTokens = 2048,
    this.rateLimitDelay = const Duration(milliseconds: 500),
  })  : _aiService = aiService,
        _promptEngine = promptEngine;

  final AiService _aiService;
  final PromptEngine _promptEngine;

  /// Default grading strictness when not specified per-answer.
  final GradingStrictness defaultStrictness;

  /// Temperature for grading completions. Lower values produce more
  /// consistent grading. Defaults to 0.3.
  final double defaultTemperature;

  /// Maximum tokens for the AI response.
  final int defaultMaxTokens;

  /// Delay between batch grading calls to respect rate limits.
  final Duration rateLimitDelay;

  // ─── Monotonic ID counter ─────────────────────────────────────────
  static int _counter = 0;

  // ═══════════════════════════════════════════════════════════════════
  // GradeEssayAnswer
  // ═══════════════════════════════════════════════════════════════════

  /// Grade a single essay / subjective answer using AI.
  ///
  /// [questionText] – The full question prompt.
  /// [studentAnswer] – The student's written response.
  /// [markingScheme] – The official marking scheme or rubric.
  /// [maxMarks] – Maximum marks for this question.
  /// [strictness] – Grading strictness. Defaults to the service's
  ///   [defaultStrictness] when null.
  /// [providerOverride] – Optional AI provider override.
  /// [questionType] – Type of question (defaults to "essay").
  /// [subject] – Optional subject context.
  /// [gradeLevel] – Optional grade / class level.
  /// [bloomLevel] – Optional Bloom's taxonomy level.
  ///
  /// Returns an [EssayGradingResult] with the suggested score, feedback,
  /// and token usage. On failure the result's [EssayGradingResult.error]
  /// field will be set.
  Future<EssayGradingResult> gradeEssayAnswer({
    required String questionText,
    required String studentAnswer,
    required String markingScheme,
    required double maxMarks,
    GradingStrictness? strictness,
    AiProvider? providerOverride,
    String questionType = 'essay',
    String? subject,
    String? gradeLevel,
    String? bloomLevel,
  }) async {
    final stopwatch = Stopwatch()..start();

    try {
      // Validate inputs
      if (questionText.trim().isEmpty) {
        stopwatch.stop();
        return EssayGradingResult(
          suggestedScore: 0,
          maxPossible: maxMarks,
          confidenceScore: 0,
          explanation: 'Grading skipped: question text is empty.',
          strengths: [],
          weaknesses: [],
          suggestions: [],
          gradingRubric: {},
          inputTokens: 0,
          outputTokens: 0,
          processingTimeMs: stopwatch.elapsed.inMilliseconds,
          error: 'Question text is empty',
        );
      }

      if (studentAnswer.trim().isEmpty) {
        stopwatch.stop();
        return EssayGradingResult(
          suggestedScore: 0,
          maxPossible: maxMarks,
          confidenceScore: 1.0,
          explanation: 'Student submitted an empty answer; score is zero.',
          strengths: [],
          weaknesses: ['No answer was provided.'],
          suggestions: ['Attempt all questions even with partial knowledge.'],
          gradingRubric: {},
          inputTokens: 0,
          outputTokens: 0,
          processingTimeMs: stopwatch.elapsed.inMilliseconds,
        );
      }

      // Resolve strictness: use the provided value or fall back to the
      // service default (Dart does not allow instance fields as default
      // parameter values).
      final effectiveStrictness = strictness ?? defaultStrictness;

      // 1. Build the grading prompt
      final promptData = buildGradingPrompt(
        questionText: questionText,
        studentAnswer: studentAnswer,
        markingScheme: markingScheme,
        maxMarks: maxMarks,
        strictness: effectiveStrictness,
        questionType: questionType,
        subject: subject,
        gradeLevel: gradeLevel,
        bloomLevel: bloomLevel,
      );

      // 2. Build completion request
      final completionRequest = AiCompletionRequest(
        systemPrompt: promptData.systemPrompt,
        userPrompt: promptData.userPrompt,
        temperature: defaultTemperature,
        maxTokens: defaultMaxTokens,
        jsonMode: true,
      );

      // 3. Obtain a provider and call the AI
      final providerType = providerOverride ?? _aiService.defaultProvider;
      final provider = _getProvider(providerType);

      if (provider == null) {
        stopwatch.stop();
        return EssayGradingResult(
          suggestedScore: 0,
          maxPossible: maxMarks,
          confidenceScore: 0,
          explanation: 'AI provider $providerType is not available.',
          strengths: [],
          weaknesses: [],
          suggestions: [],
          gradingRubric: {},
          inputTokens: 0,
          outputTokens: 0,
          processingTimeMs: stopwatch.elapsed.inMilliseconds,
          error: 'Provider $providerType is not available',
        );
      }

      AppLogger.info('Starting AI grading for question '
          '(${effectiveStrictness.label}, max=$maxMarks)');

      final result = await provider.complete(completionRequest);

      // 4. Parse the AI response
      final parsed = _parseJsonFromResponse(result.content);

      if (parsed == null) {
        stopwatch.stop();
        AppLogger.warning('Failed to parse AI grading response as JSON');
        return EssayGradingResult(
          suggestedScore: 0,
          maxPossible: maxMarks,
          confidenceScore: 0,
          explanation: 'Failed to parse the AI grading response.',
          strengths: [],
          weaknesses: [],
          suggestions: [],
          gradingRubric: {},
          inputTokens: result.inputTokens,
          outputTokens: result.outputTokens,
          processingTimeMs: stopwatch.elapsed.inMilliseconds,
          error: 'Failed to parse AI response as JSON',
        );
      }

      // 5. Convert parsed JSON into structured result
      final gradingResult = parseGradingResponse(
        parsedJson: parsed,
        maxPossible: maxMarks,
        inputTokens: result.inputTokens,
        outputTokens: result.outputTokens,
        processingTimeMs: stopwatch.elapsed.inMilliseconds,
      );

      stopwatch.stop();

      AppLogger.info('AI grading complete: '
          '${gradingResult.suggestedScore}/${gradingResult.maxPossible} '
          '(confidence: ${gradingResult.confidenceScore.toStringAsFixed(2)}, '
          'time: ${stopwatch.elapsed.inMilliseconds}ms)');

      return gradingResult;
    } on TimeoutException {
      stopwatch.stop();
      AppLogger.error('AI grading timed out');
      return EssayGradingResult(
        suggestedScore: 0,
        maxPossible: maxMarks,
        confidenceScore: 0,
        explanation: 'AI grading request timed out.',
        strengths: [],
        weaknesses: [],
        suggestions: [],
        gradingRubric: {},
        inputTokens: 0,
        outputTokens: 0,
        processingTimeMs: stopwatch.elapsed.inMilliseconds,
        error: 'AI grading request timed out',
      );
    } on FormatException catch (e) {
      stopwatch.stop();
      AppLogger.error('Invalid AI grading response format', error: e);
      return EssayGradingResult(
        suggestedScore: 0,
        maxPossible: maxMarks,
        confidenceScore: 0,
        explanation: 'The AI returned an invalid response format.',
        strengths: [],
        weaknesses: [],
        suggestions: [],
        gradingRubric: {},
        inputTokens: 0,
        outputTokens: 0,
        processingTimeMs: stopwatch.elapsed.inMilliseconds,
        error: 'Invalid response format: ${e.message}',
      );
    } catch (e) {
      stopwatch.stop();
      AppLogger.error('AI grading failed unexpectedly', error: e);
      return EssayGradingResult(
        suggestedScore: 0,
        maxPossible: maxMarks,
        confidenceScore: 0,
        explanation: 'An unexpected error occurred during AI grading.',
        strengths: [],
        weaknesses: [],
        suggestions: [],
        gradingRubric: {},
        inputTokens: 0,
        outputTokens: 0,
        processingTimeMs: stopwatch.elapsed.inMilliseconds,
        error: e.toString(),
      );
    }
  }

  // ═══════════════════════════════════════════════════════════════════
  // BatchGradeEssayAnswers
  // ═══════════════════════════════════════════════════════════════════

  /// Grade multiple essay answers in sequence, respecting rate limits.
  ///
  /// Emits [BatchGradingProgress] updates after each answer is graded,
  /// allowing callers to track progress in real time.
  ///
  /// [answers] – The list of answers to grade.
  /// [providerOverride] – Optional AI provider override for all answers.
  /// [cancelToken] – An optional [Completer] that, when completed, will
  ///   cancel the batch operation after the current answer finishes.
  ///
  /// Returns a [Stream] of progress updates. The final update will have
  /// [BatchGradingProgress.status] set to [BatchGradingStatus.completed]
  /// or [BatchGradingStatus.failed].
  Stream<BatchGradingProgress> batchGradeEssayAnswers({
    required List<EssayAnswerInput> answers,
    AiProvider? providerOverride,
    Completer<void>? cancelToken,
  }) async* {
    final batchId = _generateBatchId();
    var progress = BatchGradingProgress(
      batchId: batchId,
      totalAnswers: answers.length,
      status: BatchGradingStatus.inProgress,
    );

    yield progress;

    final results = <EssayGradingResult>[];

    for (int i = 0; i < answers.length; i++) {
      // Check for cancellation
      if (cancelToken != null && cancelToken.isCompleted) {
        AppLogger.info('Batch grading cancelled at answer $i/${answers.length}');
        yield progress = progress.copyWith(
          currentQuestionIndex: i,
          status: BatchGradingStatus.cancelled,
          results: List.unmodifiable(results),
        );
        return;
      }

      final answer = answers[i];

      yield progress = progress.copyWith(
        currentQuestionIndex: i,
      );

      AppLogger.info('Batch grading: answer ${i + 1}/${answers.length} '
          '(batch $batchId)');

      // Grade the individual answer
      final result = await gradeEssayAnswer(
        questionText: answer.questionText,
        studentAnswer: answer.studentAnswer,
        markingScheme: answer.markingScheme,
        maxMarks: answer.maxMarks,
        strictness: answer.strictness,
        providerOverride: providerOverride,
        questionType: answer.questionType,
        subject: answer.subject,
        gradeLevel: answer.gradeLevel,
        bloomLevel: answer.bloomLevel,
      );

      results.add(result);

      if (result.isSuccess) {
        yield progress = progress.copyWith(
          completedAnswers: progress.completedAnswers + 1,
          results: List.unmodifiable(results),
          currentQuestionIndex: i,
        );
      } else {
        yield progress = progress.copyWith(
          failedAnswers: progress.failedAnswers + 1,
          results: List.unmodifiable(results),
          currentQuestionIndex: i,
        );
      }

      // Respect rate limits – wait before the next call (but not after
      // the last one).
      if (i < answers.length - 1) {
        await Future<void>.delayed(rateLimitDelay);
      }
    }

    // Final progress update
    yield progress = progress.copyWith(
      status: BatchGradingStatus.completed,
      currentQuestionIndex: null,
    );

    AppLogger.info('Batch grading complete: batch $batchId, '
        '${progress.completedAnswers} succeeded, '
        '${progress.failedAnswers} failed');
  }

  // ═══════════════════════════════════════════════════════════════════
  // BuildGradingPrompt
  // ═══════════════════════════════════════════════════════════════════

  /// Constructs the system and user prompts for AI grading.
  ///
  /// The prompt instructs the AI to:
  /// - Evaluate the student's answer against the marking scheme
  /// - Assign a score proportional to the maximum marks
  /// - Provide specific, actionable feedback
  /// - Return results in a structured JSON format
  ///
  /// Returns a [PromptResolution] with the constructed prompts.
  PromptResolution buildGradingPrompt({
    required String questionText,
    required String studentAnswer,
    required String markingScheme,
    required double maxMarks,
    GradingStrictness strictness = GradingStrictness.standard,
    String questionType = 'essay',
    String? subject,
    String? gradeLevel,
    String? bloomLevel,
  }) {
    // ── System Prompt ────────────────────────────────────────────────
    final systemBuffer = StringBuffer();

    systemBuffer.writeln(
        'You are an expert exam grader specializing in evaluating '
        'subjective student answers. Your role is to provide fair, '
        'consistent, and constructive grading that helps students '
        'understand their performance.');

    systemBuffer.writeln();
    systemBuffer.writeln('Grading Guidelines:');
    systemBuffer.writeln(
        '- Evaluate the answer strictly against the provided marking '
        'scheme / rubric.');
    systemBuffer.writeln(
        '- Assign a score between 0 and the maximum marks ($maxMarks).',);
    systemBuffer.writeln(
        '- Provide a confidence score (0.0–1.0) indicating how certain '
        'you are about the assigned score.');
    systemBuffer.writeln(
        '- Give specific, actionable feedback: identify what was done '
        'well, what was missing or incorrect, and how to improve.');
    systemBuffer.writeln(
        '- Break down the score by grading criteria when a rubric is '
        'provided.');

    // Strictness-specific instructions
    systemBuffer.writeln();
    systemBuffer.writeln('Grading Strictness: ${strictness.label}');
    switch (strictness) {
      case GradingStrictness.lenient:
        systemBuffer.writeln(
            'Apply lenient grading: give the student the benefit of the '
            'doubt. Award partial credit generously when the student shows '
            'understanding even if the expression is imperfect. Overlook '
            'minor omissions if the core idea is present.');
      case GradingStrictness.standard:
        systemBuffer.writeln(
            'Apply standard grading: follow the marking scheme closely. '
            'Award partial credit where deserved based on the rubric. '
            'Expect reasonable completeness and accuracy.');
      case GradingStrictness.strict:
        systemBuffer.writeln(
            'Apply strict grading: demand precise and complete answers. '
            'Only award marks for responses that closely match the marking '
            'scheme. Require exact terminology and thorough coverage. '
            'Omissions or imprecise language should result in mark '
            'deductions.');
    }

    systemBuffer.writeln();
    systemBuffer.writeln(
        'IMPORTANT: You MUST return your response as a valid JSON object '
        'with the exact structure specified below. Do not include any '
        'text outside the JSON object.');

    // ── User Prompt ──────────────────────────────────────────────────
    final userBuffer = StringBuffer();

    userBuffer.writeln('=== GRADING TASK ===');
    userBuffer.writeln();

    // Context
    if (subject != null) {
      userBuffer.writeln('Subject: $subject');
    }
    if (gradeLevel != null) {
      userBuffer.writeln('Grade Level: $gradeLevel');
    }
    userBuffer.writeln('Question Type: $questionType');
    if (bloomLevel != null) {
      userBuffer.writeln("Bloom's Taxonomy Level: $bloomLevel");
    }
    userBuffer.writeln('Maximum Marks: $maxMarks');
    userBuffer.writeln();

    // Question
    userBuffer.writeln('=== QUESTION ===');
    userBuffer.writeln(questionText);
    userBuffer.writeln();

    // Marking scheme
    userBuffer.writeln('=== MARKING SCHEME ===');
    userBuffer.writeln(markingScheme);
    userBuffer.writeln();

    // Student answer
    userBuffer.writeln('=== STUDENT ANSWER ===');
    userBuffer.writeln(studentAnswer);
    userBuffer.writeln();

    // Response format
    userBuffer.writeln('=== REQUIRED RESPONSE FORMAT ===');
    userBuffer.writeln('Return a JSON object with this exact structure:');
    userBuffer.writeln('{');
    userBuffer.writeln('  "suggested_score": <number between 0 and $maxMarks>,');
    userBuffer.writeln('  "confidence_score": <number between 0.0 and 1.0>,');
    userBuffer.writeln('  "explanation": "<detailed explanation of the grading rationale>",');
    userBuffer.writeln('  "strengths": [');
    userBuffer.writeln('    "<what the student did well>",');
    userBuffer.writeln('    "<another strength>"');
    userBuffer.writeln('  ],');
    userBuffer.writeln('  "weaknesses": [');
    userBuffer.writeln('    "<area needing improvement>",');
    userBuffer.writeln('    "<another weakness>"');
    userBuffer.writeln('  ],');
    userBuffer.writeln('  "suggestions": [');
    userBuffer.writeln('    "<how to improve>",');
    userBuffer.writeln('    "<another suggestion>"');
    userBuffer.writeln('  ],');
    userBuffer.writeln('  "grading_rubric": {');
    userBuffer.writeln('    "<criterion_name>": {');
    userBuffer.writeln('      "score": <points earned>,');
    userBuffer.writeln('      "max_score": <maximum points for this criterion>,');
    userBuffer.writeln('      "notes": "<brief explanation>"');
    userBuffer.writeln('    }');
    userBuffer.writeln('  }');
    userBuffer.writeln('}');

    return PromptResolution(
      systemPrompt: systemBuffer.toString(),
      userPrompt: userBuffer.toString(),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // ParseGradingResponse
  // ═══════════════════════════════════════════════════════════════════

  /// Parses the AI response JSON into a structured [EssayGradingResult].
  ///
  /// [parsedJson] – The already-decoded JSON map from the AI response.
  /// [maxPossible] – The maximum marks for the question.
  /// [inputTokens] – Tokens consumed by the prompt.
  /// [outputTokens] – Tokens consumed by the completion.
  /// [processingTimeMs] – Wall-clock time for the AI call.
  ///
  /// Returns an [EssayGradingResult]. On parse failure, the result's
  /// [EssayGradingResult.error] field is set and default values are
  /// used for fields that could not be extracted.
  EssayGradingResult parseGradingResponse({
    required Map<String, dynamic> parsedJson,
    required double maxPossible,
    required int inputTokens,
    required int outputTokens,
    required int processingTimeMs,
  }) {
    try {
      // ── Suggested Score ───────────────────────────────────────────
      final rawScore = parsedJson['suggested_score'];
      double suggestedScore;
      if (rawScore is num) {
        suggestedScore = rawScore.toDouble();
      } else if (rawScore is String) {
        suggestedScore = double.tryParse(rawScore) ?? 0.0;
      } else {
        suggestedScore = 0.0;
      }
      // Clamp to valid range
      suggestedScore = suggestedScore.clamp(0.0, maxPossible);

      // ── Confidence Score ──────────────────────────────────────────
      final rawConfidence = parsedJson['confidence_score'];
      double confidenceScore;
      if (rawConfidence is num) {
        confidenceScore = rawConfidence.toDouble();
      } else if (rawConfidence is String) {
        confidenceScore = double.tryParse(rawConfidence) ?? 0.5;
      } else {
        confidenceScore = 0.5;
      }
      confidenceScore = confidenceScore.clamp(0.0, 1.0);

      // ── Explanation ───────────────────────────────────────────────
      final explanation = parsedJson['explanation'] as String? ??
          'No explanation was provided by the AI.';

      // ── Strengths ─────────────────────────────────────────────────
      final strengths = _parseStringList(parsedJson['strengths']);

      // ── Weaknesses ────────────────────────────────────────────────
      final weaknesses = _parseStringList(parsedJson['weaknesses']);

      // ── Suggestions ───────────────────────────────────────────────
      final suggestions = _parseStringList(parsedJson['suggestions']);

      // ── Grading Rubric ────────────────────────────────────────────
      final rawRubric = parsedJson['grading_rubric'];
      Map<String, dynamic> gradingRubric;
      if (rawRubric is Map<String, dynamic>) {
        gradingRubric = rawRubric;
      } else if (rawRubric is Map) {
        gradingRubric = Map<String, dynamic>.from(rawRubric);
      } else {
        gradingRubric = {};
      }

      return EssayGradingResult(
        suggestedScore: suggestedScore,
        maxPossible: maxPossible,
        confidenceScore: confidenceScore,
        explanation: explanation,
        strengths: strengths,
        weaknesses: weaknesses,
        suggestions: suggestions,
        gradingRubric: gradingRubric,
        inputTokens: inputTokens,
        outputTokens: outputTokens,
        processingTimeMs: processingTimeMs,
      );
    } catch (e) {
      AppLogger.error('Failed to parse grading response', error: e);
      return EssayGradingResult(
        suggestedScore: 0,
        maxPossible: maxPossible,
        confidenceScore: 0,
        explanation: 'Failed to parse the grading response: ${e.toString()}',
        strengths: [],
        weaknesses: [],
        suggestions: [],
        gradingRubric: {},
        inputTokens: inputTokens,
        outputTokens: outputTokens,
        processingTimeMs: processingTimeMs,
        error: 'Parse error: ${e.toString()}',
      );
    }
  }

  // ═══════════════════════════════════════════════════════════════════
  // EstimateTokens
  // ═══════════════════════════════════════════════════════════════════

  /// Estimates the number of tokens that a grading request will consume.
  ///
  /// Uses a heuristic of ~4 characters per token (a common approximation
  /// for English text with GPT-style tokenizers). This is useful for
  /// cost tracking and for deciding whether to split large batch
  /// operations.
  ///
  /// [questionText] – The question text.
  /// [studentAnswer] – The student's answer text.
  /// [markingScheme] – The marking scheme text.
  /// [strictness] – Affects the system prompt length.
  ///
  /// Returns an [TokenEstimate] with input, expected output, and total
  /// token estimates.
  TokenEstimate estimateTokens({
    required String questionText,
    required String studentAnswer,
    required String markingScheme,
    GradingStrictness strictness = GradingStrictness.standard,
  }) {
    // Build the prompt to get accurate length
    final promptData = buildGradingPrompt(
      questionText: questionText,
      studentAnswer: studentAnswer,
      markingScheme: markingScheme,
      maxMarks: 0, // placeholder – doesn't affect token count
      strictness: strictness,
    );

    final inputText =
        '${promptData.systemPrompt}${promptData.userPrompt}';
    final estimatedInputTokens = (inputText.length / 4).ceil();

    // Expected output: the JSON grading result is typically 300–800
    // tokens depending on answer complexity and feedback detail.
    const estimatedOutputTokens = 600;

    return TokenEstimate(
      estimatedInputTokens: estimatedInputTokens,
      estimatedOutputTokens: estimatedOutputTokens,
      estimatedTotalTokens: estimatedInputTokens + estimatedOutputTokens,
    );
  }

  /// Estimate total tokens for a batch of answers.
  ///
  /// Sums the estimates for each answer individually. In practice,
  /// the system prompt is reused across calls, so the actual token
  /// usage may be slightly lower if the provider caches the system
  /// prompt.
  TokenEstimate estimateBatchTokens({
    required List<EssayAnswerInput> answers,
  }) {
    int totalInput = 0;
    int totalOutput = 0;

    for (final answer in answers) {
      final estimate = estimateTokens(
        questionText: answer.questionText,
        studentAnswer: answer.studentAnswer,
        markingScheme: answer.markingScheme,
        strictness: answer.strictness,
      );
      totalInput += estimate.estimatedInputTokens;
      totalOutput += estimate.estimatedOutputTokens;
    }

    return TokenEstimate(
      estimatedInputTokens: totalInput,
      estimatedOutputTokens: totalOutput,
      estimatedTotalTokens: totalInput + totalOutput,
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // Private Helpers
  // ═══════════════════════════════════════════════════════════════════

  /// Extract JSON from AI responses.
  ///
  /// AI models sometimes wrap JSON in markdown code blocks (e.g.
  /// ```json ... ```) or prepend conversational text. This helper
  /// attempts multiple strategies to extract valid JSON:
  ///
  /// 1. Direct `jsonDecode` of the entire content
  /// 2. Extraction from markdown code blocks
  /// 3. Finding the outermost `{ ... }` braces
  Map<String, dynamic>? _parseJsonFromResponse(String content) {
    // Strategy 1: Direct parse
    try {
      final decoded = jsonDecode(content);
      if (decoded is Map<String, dynamic>) return decoded;
      if (decoded is Map) return Map<String, dynamic>.from(decoded);
    } on FormatException {
      // Fall through to next strategy
    }

    // Strategy 2: Extract from markdown code blocks
    final jsonBlockRegex = RegExp(r'```(?:json)?\s*([\s\S]*?)```');
    final blockMatch = jsonBlockRegex.firstMatch(content);
    if (blockMatch != null) {
      try {
        final decoded = jsonDecode(blockMatch.group(1)!.trim());
        if (decoded is Map<String, dynamic>) return decoded;
        if (decoded is Map) return Map<String, dynamic>.from(decoded);
      } on FormatException {
        // Fall through to next strategy
      }
    }

    // Strategy 3: Find outermost { ... } braces
    final braceStart = content.indexOf('{');
    final braceEnd = content.lastIndexOf('}');
    if (braceStart != -1 && braceEnd > braceStart) {
      try {
        final decoded =
            jsonDecode(content.substring(braceStart, braceEnd + 1));
        if (decoded is Map<String, dynamic>) return decoded;
        if (decoded is Map) return Map<String, dynamic>.from(decoded);
      } on FormatException {
        // All strategies failed
      }
    }

    return null;
  }

  /// Parse a dynamic value into a `List<String>`.
  ///
  /// Handles both `List<String>` and `List<dynamic>` from JSON.
  List<String> _parseStringList(dynamic value) {
    if (value is List) {
      return value.map((e) => e?.toString() ?? '').toList();
    }
    return [];
  }

  /// Generate a unique batch ID.
  String _generateBatchId() {
    return 'batch_${DateTime.now().millisecondsSinceEpoch}_${_counter++}';
  }

  /// Get a provider instance by type via the AI service's registry.
  AiProviderInterface? _getProvider(AiProvider providerType) {
    // Access the providers list from the AI service and find the
    // matching one. The AiService exposes its providers registry
    // through the [providers] getter.
    try {
      for (final provider in _aiService.providers) {
        if (provider.providerType == providerType) {
          return provider;
        }
      }
    } catch (e) {
      AppLogger.warning('Failed to access AI providers registry', error: e);
    }
    return null;
  }
}

// ═══════════════════════════════════════════════════════════════════════
// TOKEN ESTIMATE
// ═══════════════════════════════════════════════════════════════════════

/// Token usage estimate for a grading operation.
class TokenEstimate {
  const TokenEstimate({
    required this.estimatedInputTokens,
    required this.estimatedOutputTokens,
    required this.estimatedTotalTokens,
  });

  /// Estimated number of input (prompt) tokens.
  final int estimatedInputTokens;

  /// Estimated number of output (completion) tokens.
  final int estimatedOutputTokens;

  /// Estimated total tokens (input + output).
  final int estimatedTotalTokens;

  @override
  String toString() => 'TokenEstimate(input: $estimatedInputTokens, '
      'output: $estimatedOutputTokens, total: $estimatedTotalTokens)';
}
