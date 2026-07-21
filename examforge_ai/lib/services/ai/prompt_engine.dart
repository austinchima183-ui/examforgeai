import 'dart:convert';

import '../../../core/security/ai_security_service.dart';
import '../../core/utils/logger.dart';
import '../../features/ai_generator/domain/entities/ai_entities.dart';
import '../../features/question_bank/domain/entities/question_entities.dart';

// ═══════════════════════════════════════════════════════════════════════
// PROMPT RESOLUTION
// ═══════════════════════════════════════════════════════════════════════

/// Result of resolving a prompt template with input variables.
class PromptResolution {
  const PromptResolution({
    required this.systemPrompt,
    required this.userPrompt,
    this.templateUsed,
    this.resolvedVariables = const {},
  });

  /// The fully-resolved system prompt.
  final String systemPrompt;

  /// The fully-resolved user prompt.
  final String userPrompt;

  /// The template that was used (null if using a built-in default).
  final PromptTemplateEntity? templateUsed;

  /// The variables that were resolved and substituted.
  final Map<String, dynamic> resolvedVariables;
}

// ═══════════════════════════════════════════════════════════════════════
// PROMPT ENGINE
// ═══════════════════════════════════════════════════════════════════════

/// The Prompt Engine is the brain of the AI question generation system.
///
/// It is responsible for:
/// - Resolving prompt templates with input variables
/// - Selecting the best template for a given generation request
/// - Building generation, improvement, validation, and extraction prompts
/// - Parsing AI responses into structured domain entities
class PromptEngine {
  // ─── Template Resolution ──────────────────────────────────────────

  /// Resolve a prompt template by replacing `{{variable_name}}` placeholders
  /// with actual values from [variables].
  ///
  /// Required variables that are missing will produce a warning log but
  /// will be replaced with an empty string so generation can continue.
  String resolvePrompt(
    PromptTemplateEntity template,
    Map<String, dynamic> variables,
  ) {
    String resolved = template.userPromptTemplate;

    // Replace all {{variable_name}} occurrences
    final variablePattern = RegExp(r'\{\{(\w+)\}\}');
    resolved = resolved.replaceAllMapped(variablePattern, (match) {
      final varName = match.group(1)!;
      if (variables.containsKey(varName)) {
        return variables[varName].toString();
      }
      // Check if template declares this variable with a default
      final templateVar = template.variables
          .where((v) => v.name == varName)
          .firstOrNull;
      if (templateVar?.defaultValue != null) {
        return templateVar!.defaultValue!;
      }
      if (templateVar?.isRequired ?? false) {
        AppLogger.warning('Missing required variable: $varName in template '
            '"${template.name}"');
      }
      return '';
    });

    return resolved;
  }

  /// Build a generation prompt from teacher inputs.
  ///
  /// Selects the best matching template from [templates] based on
  /// subject, question type, difficulty, curriculum, and language.
  /// If no suitable template is found, falls back to the built-in
  /// default generation prompt.
  PromptResolution resolveGenerationPrompt(
    GenerationInputEntity input,
    List<PromptTemplateEntity> templates,
  ) {
    // ─── AI SECURITY: Check user inputs for prompt injection ──────────
    // Validate the topic, custom instructions, and other user-supplied
    // fields before incorporating them into the prompt.
    final topicCheck = AiSecurityService.checkInput(input.topic);
    if (!topicCheck.isSafe) {
      AppLogger.error(
        'AI SECURITY: Prompt injection detected in topic. '
        'Blocking generation request.',
      );
      // Return a safe resolution that will result in an error message
      return PromptResolution(
        systemPrompt: 'You are a helpful educational assistant.',
        userPrompt: 'The provided topic contains potentially unsafe content. '
            'Please revise and try again.',
        templateUsed: null,
        resolvedVariables: {},
      );
    }

    final instructionsCheck = AiSecurityService.checkInput(
      input.customInstructions ?? '',
    );
    if (!instructionsCheck.isSafe && instructionsCheck.sanitizedInput != null) {
      AppLogger.warning(
        'AI SECURITY: Sanitizing custom instructions due to injection patterns.',
      );
      // Use sanitized version instead of blocking
    }

    final activeTemplates = templates
        .where((t) =>
            t.isActive &&
            t.promptType == PromptType.questionGeneration)
        .toList();

    // Score each template based on how well it matches the input
    PromptTemplateEntity? bestMatch;
    int bestScore = -1;

    for (final template in activeTemplates) {
      int score = 0;

      // Match on question type (high weight)
      if (template.questionType == input.questionType) {
        score += 50;
      }

      // Match on difficulty (medium weight)
      if (template.difficulty == input.difficulty) {
        score += 20;
      }

      // Match on subject (high weight)
      if (template.subjectId == input.subjectId) {
        score += 30;
      }

      // Match on curriculum (medium weight)
      if (template.curriculum == input.curriculum) {
        score += 15;
      }

      // Match on Bloom's level (medium weight)
      if (template.bloomLevel == input.bloomLevel) {
        score += 15;
      }

      // Match on language (low weight)
      if (template.language == input.language) {
        score += 10;
      }

      // Match on provider preference (low weight)
      if (template.provider == input.provider) {
        score += 5;
      }

      // Default templates get a small bonus
      if (template.isDefault) {
        score += 3;
      }

      // Higher quality score gets a bonus
      if (template.qualityScore != null) {
        score += (template.qualityScore! * 10).round();
      }

      // Higher success rate gets a bonus
      if (template.successRate != null) {
        score += (template.successRate! * 10).round();
      }

      if (score > bestScore) {
        bestScore = score;
        bestMatch = template;
      }
    }

    // Build resolved variables from input
    final resolvedVariables = _buildGenerationVariables(input);

    if (bestMatch != null) {
      final systemPrompt = bestMatch.systemPrompt;
      final userPrompt = resolvePrompt(bestMatch, resolvedVariables);

      // Append few-shot examples if available
      final fullUserPrompt = _appendFewShotExamples(userPrompt, bestMatch);

      // Append chain-of-thought instruction if enabled
      final finalUserPrompt = bestMatch.chainOfThought
          ? '$fullUserPrompt\n\nThink through this step by step before generating the questions.'
          : fullUserPrompt;

      return PromptResolution(
        systemPrompt: systemPrompt,
        userPrompt: finalUserPrompt,
        templateUsed: bestMatch,
        resolvedVariables: resolvedVariables,
      );
    }

    // Fallback to built-in default prompt
    return PromptResolution(
      systemPrompt: _defaultSystemPrompt,
      userPrompt: _buildDefaultUserPrompt(input),
      templateUsed: null,
      resolvedVariables: resolvedVariables,
    );
  }

  // ─── Improvement Prompt ───────────────────────────────────────────

  /// Build an improvement prompt for a generated question.
  ///
  /// [improvementType] can be: "clarity", "distractors", "difficulty",
  /// "explanation", "curriculum_alignment", "grammar", "general".
  String buildImprovementPrompt(
    String improvementType,
    GeneratedQuestionEntity question, {
    String? customInstructions,
  }) {
    final buffer = StringBuffer();

    buffer.writeln('You are an expert educational content improver. '
        'Your task is to improve the following question.');

    // Add improvement-specific instructions
    switch (improvementType) {
      case 'clarity':
        buffer.writeln(
            'Focus on making the question clearer and more unambiguous.');
        buffer.writeln('- Remove any confusing wording');
        buffer.writeln('- Ensure the question has a single correct interpretation');
        buffer.writeln('- Simplify complex sentence structures while preserving meaning');
      case 'distractors':
        buffer.writeln(
            'Focus on improving the answer options/distractors.');
        buffer.writeln('- Make incorrect options (distractors) more plausible');
        buffer.writeln('- Ensure distractors represent common misconceptions');
        buffer.writeln('- Make all options roughly the same length');
        buffer.writeln('- Avoid obviously wrong distractors');
      case 'difficulty':
        buffer.writeln(
            'Focus on adjusting the difficulty level of the question.');
        buffer.writeln(
            '- Current difficulty: ${question.difficulty.label}');
        buffer.writeln(
            '- Adjust cognitive demand appropriately');
        buffer.writeln(
            '- Align with Bloom\'s taxonomy level if specified');
      case 'explanation':
        buffer.writeln(
            'Focus on creating or improving the explanation for this question.');
        buffer.writeln('- Provide a clear, step-by-step explanation');
        buffer.writeln('- Explain why the correct answer is right');
        buffer.writeln('- Explain why each distractor is wrong');
        buffer.writeln(
            '- Include relevant references or learning resources');
      case 'curriculum_alignment':
        buffer.writeln(
            'Focus on improving curriculum alignment.');
        buffer.writeln(
            '- Ensure the question directly assesses a learning objective');
        buffer.writeln('- Use curriculum-appropriate terminology');
        buffer.writeln(
            '- Align the difficulty with the expected level for this class');
      case 'grammar':
        buffer.writeln(
            'Focus on correcting grammar and spelling errors.');
        buffer.writeln('- Fix any grammatical errors');
        buffer.writeln('- Correct spelling mistakes');
        buffer.writeln(
            '- Improve sentence structure while preserving meaning');
      default:
        buffer.writeln(
            'Improve this question in any way that enhances its quality.');
    }

    if (customInstructions != null && customInstructions.isNotEmpty) {
      buffer.writeln();
      buffer.writeln('Additional instructions from the teacher:');
      buffer.writeln(customInstructions);
    }

    buffer.writeln();
    buffer.writeln('--- ORIGINAL QUESTION ---');
    buffer.writeln('Question Type: ${question.questionType.label}');
    buffer.writeln('Difficulty: ${question.difficulty.label}');
    buffer.writeln('Bloom\'s Level: ${question.bloomLevel?.label ?? "Not specified"}');
    buffer.writeln();
    buffer.writeln('Content: ${question.content}');

    if (question.answerOptions.isNotEmpty) {
      buffer.writeln();
      buffer.writeln('Answer Options:');
      for (int i = 0; i < question.answerOptions.length; i++) {
        final option = question.answerOptions[i];
        final label = option['label'] as String? ?? String.fromCharCode(65 + i);
        final text = option['text'] as String? ?? option['content'] as String? ?? '';
        final isCorrect = option['is_correct'] as bool? ?? option['isCorrect'] as bool? ?? false;
        buffer.writeln('  $label. $text ${isCorrect ? "✓ (correct)" : ""}');
      }
    }

    if (question.explanation != null) {
      buffer.writeln();
      buffer.writeln('Current Explanation: ${question.explanation}');
    }

    buffer.writeln();
    buffer.writeln('--- END ORIGINAL QUESTION ---');
    buffer.writeln();
    buffer.writeln('Return a JSON object with the following structure:');
    buffer.writeln('{');
    buffer.writeln('  "improved_content": "The improved question text",');
    buffer.writeln('  "improved_answer_options": [');
    buffer.writeln(
        '    {"label": "A", "text": "option text", "is_correct": false},');
    buffer.writeln('    ...');
    buffer.writeln('  ],');
    buffer.writeln('  "improved_explanation": "The improved explanation",');
    buffer.writeln(
        '  "improvement_notes": "Description of changes made"');
    buffer.writeln('}');

    return buffer.toString();
  }

  // ─── Validation Prompt ────────────────────────────────────────────

  /// Build a validation prompt for a generated question.
  String buildValidationPrompt(GeneratedQuestionEntity question) {
    final buffer = StringBuffer();

    buffer.writeln('You are an expert educational content validator. '
        'Analyze the following question for quality issues.');
    buffer.writeln();
    buffer.writeln('Check for:');
    buffer.writeln('1. Grammar and spelling errors');
    buffer.writeln('2. Ambiguous or unclear wording');
    buffer.writeln('3. Answer accuracy (correct answer must be clearly correct, '
        'distractors must be clearly wrong)');
    buffer.writeln('4. Plausible distractors (incorrect options should be '
        'reasonable but definitively wrong)');
    buffer.writeln('5. Difficulty level consistency (does the question match '
        'its stated difficulty?)');
    buffer.writeln('6. Curriculum alignment (is the question appropriate for '
        'the stated class level and subject?)');
    buffer.writeln('7. Clarity of the question (is there only one correct '
        'interpretation?)');
    buffer.writeln();
    buffer.writeln('--- QUESTION TO VALIDATE ---');
    buffer.writeln('Question Type: ${question.questionType.label}');
    buffer.writeln('Difficulty: ${question.difficulty.label}');
    buffer.writeln('Bloom\'s Level: ${question.bloomLevel?.label ?? "Not specified"}');
    buffer.writeln();
    buffer.writeln('Content: ${question.content}');

    if (question.answerOptions.isNotEmpty) {
      buffer.writeln();
      buffer.writeln('Answer Options:');
      for (int i = 0; i < question.answerOptions.length; i++) {
        final option = question.answerOptions[i];
        final label = option['label'] as String? ?? String.fromCharCode(65 + i);
        final text = option['text'] as String? ?? option['content'] as String? ?? '';
        final isCorrect = option['is_correct'] as bool? ?? option['isCorrect'] as bool? ?? false;
        buffer.writeln('  $label. $text ${isCorrect ? "✓ (correct)" : ""}');
      }
    }

    if (question.explanation != null) {
      buffer.writeln();
      buffer.writeln('Explanation: ${question.explanation}');
    }

    buffer.writeln();
    buffer.writeln('--- END QUESTION ---');
    buffer.writeln();
    buffer.writeln('Return a JSON object with the following structure:');
    buffer.writeln('{');
    buffer.writeln('  "is_valid": true/false,');
    buffer.writeln('  "overall_quality_score": 0.0-1.0,');
    buffer.writeln('  "validation_results": [');
    buffer.writeln('    {');
    buffer.writeln('      "type": "grammar|ambiguity|answer_accuracy|'
        'distractor_quality|difficulty_consistency|curriculum_alignment|clarity",');
    buffer.writeln('      "severity": "info|warning|error|critical",');
    buffer.writeln('      "message": "Description of the issue",');
    buffer.writeln('      "suggestion": "How to fix the issue (optional)"');
    buffer.writeln('    }');
    buffer.writeln('  ]');
    buffer.writeln('}');

    return buffer.toString();
  }

  // ─── Document Extraction Prompt ───────────────────────────────────

  /// Build a document extraction prompt.
  ///
  /// Used to extract questions, topics, and learning objectives from
  /// a document's text content.
  String buildDocumentExtractionPrompt(
    String extractedText,
    GenerationInputEntity input,
  ) {
    final buffer = StringBuffer();

    buffer.writeln('You are an expert educational content analyst. '
        'Analyze the following document and extract information useful '
        'for generating exam questions.');
    buffer.writeln();
    buffer.writeln('Subject: ${input.subjectId}');
    buffer.writeln('Topic: ${input.topicId}');
    if (input.curriculum != null) {
      buffer.writeln('Curriculum: ${input.curriculum!.label}');
    }
    if (input.classId != null) {
      buffer.writeln('Class Level: ${input.classId}');
    }
    buffer.writeln();
    buffer.writeln('--- DOCUMENT TEXT ---');
    // Truncate very long documents to avoid token limits
    final maxChars = 50000;
    if (extractedText.length > maxChars) {
      buffer.writeln(extractedText.substring(0, maxChars));
      buffer.writeln();
      buffer.writeln('[Document truncated - showing first $maxChars characters]');
    } else {
      buffer.writeln(extractedText);
    }
    buffer.writeln('--- END DOCUMENT TEXT ---');
    buffer.writeln();
    buffer.writeln('Return a JSON object with the following structure:');
    buffer.writeln('{');
    buffer.writeln('  "identified_topics": [');
    buffer.writeln('    {');
    buffer.writeln('      "name": "Topic name",');
    buffer.writeln('      "confidence": 0.0-1.0,');
    buffer.writeln('      "subtopics": ["Subtopic 1", "Subtopic 2"]');
    buffer.writeln('    }');
    buffer.writeln('  ],');
    buffer.writeln('  "suggested_objectives": [');
    buffer.writeln('    {');
    buffer.writeln('      "objective": "Learning objective text",');
    buffer.writeln('      "bloom_level": "remember|understand|apply|analyze|evaluate|create",');
    buffer.writeln('      "suggested_difficulty": "easy|medium|hard|expert",');
    buffer.writeln('      "suggested_question_types": ["multiple_choice", "short_answer"]');
    buffer.writeln('    }');
    buffer.writeln('  ],');
    buffer.writeln('  "key_concepts": ["Concept 1", "Concept 2"],');
    buffer.writeln('  "summary": "Brief summary of the document content"');
    buffer.writeln('}');

    return buffer.toString();
  }

  // ─── Response Parsing ─────────────────────────────────────────────

  /// Parse AI response into structured generated questions.
  ///
  /// The response should be a JSON object or a list of question objects.
  /// This method handles multiple response formats:
  /// 1. `{ "questions": [...] }` — standard format
  /// 2. `[...]` — direct list of questions
  /// 3. `{ "question": {...} }` — single question wrapper
  List<GeneratedQuestionEntity> parseGeneratedQuestions(
    Map<String, dynamic> response,
    GenerationRequestEntity request,
  ) {
    try {
      List<dynamic> questionsList;

      if (response.containsKey('questions')) {
        questionsList = response['questions'] as List<dynamic>;
      } else if (response.containsKey('question')) {
        questionsList = [response['question']];
      } else if (response.values.any((v) => v is List)) {
        // Try to find the list of questions
        final listEntry = response.entries
            .firstWhere((e) => e.value is List && (e.value as List).isNotEmpty);
        questionsList = listEntry.value as List<dynamic>;
      } else {
        // Assume the entire response is a single question
        questionsList = [response];
      }

      return questionsList
          .whereType<Map<String, dynamic>>()
          .map((q) => _mapToGeneratedQuestion(q, request))
          .toList();
    } catch (e) {
      AppLogger.error('Failed to parse generated questions from response', error: e);
      return [];
    }
  }

  /// Parse AI improvement response.
  QuestionImprovementEntity parseImprovementResponse(
    Map<String, dynamic> response,
    GeneratedQuestionEntity original,
    String improvementType,
  ) {
    return QuestionImprovementEntity(
      id: '',
      generatedQuestionId: original.id,
      improvementType: improvementType,
      provider: AiProvider.openai, // Will be overwritten by caller
      originalContent: original.content,
      improvedContent: response['improved_content'] as String? ??
          original.content,
      originalAnswerOptions: original.answerOptions.isNotEmpty
          ? List<Map<String, dynamic>>.from(original.answerOptions)
          : null,
      improvedAnswerOptions: response['improved_answer_options'] != null
          ? List<Map<String, dynamic>>.from(
              response['improved_answer_options'] as List)
          : null,
      improvementPrompt: null,
      inputTokens: null,
      outputTokens: null,
      cost: null,
      isAccepted: false,
      createdBy: null,
      createdAt: DateTime.now(),
    );
  }

  /// Parse validation results from AI response.
  List<ValidationResultEntity> parseValidationResults(
    Map<String, dynamic> response,
    String questionId,
  ) {
    try {
      final results = <ValidationResultEntity>[];

      // If response has validation_results array
      if (response.containsKey('validation_results')) {
        final validationResults =
            response['validation_results'] as List<dynamic>;
        for (int i = 0; i < validationResults.length; i++) {
          final result = validationResults[i] as Map<String, dynamic>;
          results.add(ValidationResultEntity(
            id: '',
            generatedQuestionId: questionId,
            validationType: result['type'] as String? ?? 'general',
            severity: ValidationSeverity.fromString(
                    result['severity'] as String?) ??
                ValidationSeverity.info,
            message: result['message'] as String? ?? 'No message provided',
            suggestion: result['suggestion'] as String?,
            isResolved: false,
            resolvedBy: null,
            resolvedAt: null,
            createdAt: DateTime.now(),
          ));
        }
      }

      // If no structured results, create one from the overall validity
      if (results.isEmpty) {
        final isValid = response['is_valid'] as bool? ?? true;
        results.add(ValidationResultEntity(
          id: '',
          generatedQuestionId: questionId,
          validationType: 'overall',
          severity: isValid ? ValidationSeverity.info : ValidationSeverity.error,
          message: isValid
              ? 'Question passed validation'
              : 'Question failed validation',
          suggestion: response['suggestion'] as String?,
          isResolved: false,
          resolvedBy: null,
          resolvedAt: null,
          createdAt: DateTime.now(),
        ));
      }

      return results;
    } catch (e) {
      AppLogger.error('Failed to parse validation results', error: e);
      return [
        ValidationResultEntity(
          id: '',
          generatedQuestionId: questionId,
          validationType: 'parse_error',
          severity: ValidationSeverity.warning,
          message: 'Could not parse validation results from AI response',
          isResolved: false,
          resolvedBy: null,
          resolvedAt: null,
          createdAt: DateTime.now(),
        ),
      ];
    }
  }

  // ─── Private Helpers ──────────────────────────────────────────────

  /// Build the variable map from a [GenerationInputEntity].
  Map<String, dynamic> _buildGenerationVariables(GenerationInputEntity input) {
    return {
      'subject_id': input.subjectId,
      'topic_id': input.topicId,
      'subtopic_id': input.subtopicId ?? '',
      'class_id': input.classId ?? '',
      'curriculum': input.curriculum?.label ?? '',
      'difficulty': input.difficulty.label,
      'bloom_level': input.bloomLevel?.label ?? '',
      'question_type': input.questionType?.label ?? 'Any',
      'num_questions': input.numQuestions.toString(),
      'language': input.language,
      'exam_type': input.examType?.label ?? '',
      'keywords': input.keywords.join(', '),
      'custom_instructions': input.customInstructions ?? '',
    };
  }

  /// Append few-shot examples to the user prompt.
  String _appendFewShotExamples(String userPrompt, PromptTemplateEntity template) {
    if (template.fewShotExamples.isEmpty) return userPrompt;

    final buffer = StringBuffer(userPrompt);
    buffer.writeln();
    buffer.writeln();
    buffer.writeln('Here are some examples:');
    buffer.writeln();

    for (int i = 0; i < template.fewShotExamples.length; i++) {
      final example = template.fewShotExamples[i];
      buffer.writeln('Example ${i + 1}:');
      buffer.writeln('Input: ${jsonEncode(example.input)}');
      buffer.writeln('Output: ${jsonEncode(example.output)}');
      buffer.writeln();
    }

    return buffer.toString();
  }

  /// Maps a raw question JSON object to a [GeneratedQuestionEntity].
  GeneratedQuestionEntity _mapToGeneratedQuestion(
    Map<String, dynamic> q,
    GenerationRequestEntity request,
  ) {
    // Determine question type
    final questionTypeStr = q['question_type'] as String? ??
        q['type'] as String? ??
        request.inputParams['question_type'] as String? ??
        'multiple_choice';
    final questionType = QuestionType.values.cast<QuestionType?>().firstWhere(
          (t) => t?.value == questionTypeStr,
          orElse: () => QuestionType.multipleChoice,
        ) ?? QuestionType.multipleChoice;

    // Determine difficulty
    final difficultyStr = q['difficulty'] as String? ??
        request.inputParams['difficulty'] as String? ??
        'medium';
    final difficulty = DifficultyLevel.values.cast<DifficultyLevel?>().firstWhere(
          (d) => d?.value == difficultyStr,
          orElse: () => DifficultyLevel.medium,
        ) ?? DifficultyLevel.medium;

    // Determine Bloom's level
    final bloomStr = q['bloom_level'] as String? ??
        request.inputParams['bloom_level'] as String?;
    final bloomLevel = BloomTaxonomy.fromString(bloomStr);

    // Parse answer options
    List<Map<String, dynamic>> answerOptions = [];
    if (q['answer_options'] != null) {
      answerOptions = (q['answer_options'] as List<dynamic>)
          .whereType<Map<String, dynamic>>()
          .toList();
    } else if (q['options'] != null) {
      answerOptions = (q['options'] as List<dynamic>)
          .whereType<Map<String, dynamic>>()
          .toList();
    }

    // Parse matching pairs
    List<Map<String, dynamic>> matchingPairs = [];
    if (q['matching_pairs'] != null) {
      matchingPairs = (q['matching_pairs'] as List<dynamic>)
          .whereType<Map<String, dynamic>>()
          .toList();
    }

    // Parse ordering items
    List<Map<String, dynamic>> orderingItems = [];
    if (q['ordering_items'] != null) {
      orderingItems = (q['ordering_items'] as List<dynamic>)
          .whereType<Map<String, dynamic>>()
          .toList();
    }

    // Parse fill-in-blank answers
    List<Map<String, dynamic>> fillInBlankAnswers = [];
    if (q['fill_in_blank_answers'] != null) {
      fillInBlankAnswers = (q['fill_in_blank_answers'] as List<dynamic>)
          .whereType<Map<String, dynamic>>()
          .toList();
    }

    // Parse suggested references
    List<String> references = [];
    if (q['references'] != null) {
      references = (q['references'] as List<dynamic>)
          .whereType<String>()
          .toList();
    } else if (q['suggested_references'] != null) {
      references = (q['suggested_references'] as List<dynamic>)
          .whereType<String>()
          .toList();
    }

    return GeneratedQuestionEntity(
      id: '',
      generationRequestId: request.id,
      questionBankId: null,
      schoolId: request.schoolId,
      questionType: questionType,
      difficulty: difficulty,
      bloomLevel: bloomLevel,
      content: q['content'] as String? ?? q['question'] as String? ?? '',
      contentJson: q['content_json'] as Map<String, dynamic>?,
      answerOptions: answerOptions,
      matchingPairs: matchingPairs,
      orderingItems: orderingItems,
      fillInBlankAnswers: fillInBlankAnswers,
      explanation: q['explanation'] as String?,
      suggestedReferences: references,
      marks: q['marks'] as int? ?? 1,
      estimatedTimeSeconds: q['estimated_time_seconds'] as int?,
      confidenceScore: (q['confidence_score'] as num?)?.toDouble(),
      curriculumAlignment: q['curriculum_alignment'] as Map<String, dynamic>?,
      reviewStatus: ReviewStatus.pending,
      reviewedBy: null,
      reviewedAt: null,
      reviewNotes: null,
      teacherEdits: null,
      isEdited: false,
      isApproved: false,
      metadata: q['metadata'] as Map<String, dynamic>?,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  // ─── Built-in Default Prompts ─────────────────────────────────────

  static const String _defaultSystemPrompt = '''You are an expert educational content creator specializing in generating high-quality exam questions. Your task is to generate questions that:

1. Are pedagogically sound and test meaningful understanding
2. Have clear, unambiguous wording
3. Include plausible distractors for multiple-choice questions
4. Align with the specified difficulty level and Bloom's taxonomy level
5. Include helpful explanations for the correct answer
6. Are culturally sensitive and inclusive
7. Follow the specified curriculum standards

Always return your response as a valid JSON object matching the requested format.''';

  String _buildDefaultUserPrompt(GenerationInputEntity input) {
    final buffer = StringBuffer();

    buffer.writeln('Generate ${input.numQuestions} exam question(s) with the '
        'following specifications:');
    buffer.writeln();
    buffer.writeln('- Subject: ${input.subjectId}');
    buffer.writeln('- Topic: ${input.topicId}');
    if (input.subtopicId != null) {
      buffer.writeln('- Subtopic: ${input.subtopicId}');
    }
    if (input.classId != null) {
      buffer.writeln('- Class Level: ${input.classId}');
    }
    if (input.curriculum != null) {
      buffer.writeln('- Curriculum: ${input.curriculum!.label}');
    }
    buffer.writeln('- Difficulty: ${input.difficulty.label}');
    if (input.bloomLevel != null) {
      buffer.writeln(
          "- Bloom's Taxonomy Level: ${input.bloomLevel!.label}");
    }
    buffer.writeln(
        '- Question Type: ${input.questionType?.label ?? "Mixed"}');
    buffer.writeln('- Language: ${input.language}');
    if (input.examType != null) {
      buffer.writeln('- Exam Type: ${input.examType!.label}');
    }
    if (input.keywords.isNotEmpty) {
      buffer.writeln('- Keywords: ${input.keywords.join(", ")}');
    }
    if (input.customInstructions != null &&
        input.customInstructions!.isNotEmpty) {
      buffer.writeln('- Additional Instructions: ${input.customInstructions}');
    }

    buffer.writeln();
    buffer.writeln('Return a JSON object with the following structure:');
    buffer.writeln('{');
    buffer.writeln('  "questions": [');
    buffer.writeln('    {');
    buffer.writeln('      "question_type": "multiple_choice",');
    buffer.writeln('      "content": "The question text",');
    buffer.writeln('      "difficulty": "medium",');
    buffer.writeln('      "bloom_level": "apply",');
    buffer.writeln('      "answer_options": [');
    buffer.writeln('        {"label": "A", "text": "First option", '
        '"is_correct": false},');
    buffer.writeln('        {"label": "B", "text": "Second option", '
        '"is_correct": true},');
    buffer.writeln('        {"label": "C", "text": "Third option", '
        '"is_correct": false},');
    buffer.writeln('        {"label": "D", "text": "Fourth option", '
        '"is_correct": false}');
    buffer.writeln('      ],');
    buffer.writeln('      "explanation": "Why B is correct and others are not",');
    buffer.writeln('      "marks": 1,');
    buffer.writeln('      "estimated_time_seconds": 60,');
    buffer.writeln('      "confidence_score": 0.9,');
    buffer.writeln('      "references": ["Reference 1"]');
    buffer.writeln('    }');
    buffer.writeln('  ]');
    buffer.writeln('}');

    return buffer.toString();
  }
}
