import '../../../core/utils/logger.dart';
import '../../features/ai_generator/domain/entities/ai_entities.dart';
import '../../features/question_bank/domain/entities/question_entities.dart';

// ═══════════════════════════════════════════════════════════════════════
// VALIDATION ENGINE
// ═══════════════════════════════════════════════════════════════════════

/// Automated validation engine for generated questions.
///
/// Runs a comprehensive suite of checks on each question, covering
/// grammar, answer accuracy, ambiguity, clarity, reading level,
/// curriculum alignment, difficulty consistency, and duplicate detection.
///
/// Each check returns a [ValidationResultEntity] (or null if the check
/// passes). The main [validate] method runs all checks and returns
/// the aggregated list.
class ValidationEngine {
  // ─── Common grammatical error patterns ─────────────────────────────

  static const List<_GrammarPattern> _grammarPatterns = [
    _GrammarPattern(
      pattern: r'\btheir\s+is\b',
      message: 'Possible grammar error: "their is" — did you mean "there is"?',
    ),
    _GrammarPattern(
      pattern: r'\byour\s+is\b',
      message: 'Possible grammar error: "your is" — did you mean "you\'re is" or "there is"?',
    ),
    _GrammarPattern(
      pattern: r'\bits\s+a\b',
      message: 'Check: "its a" — did you mean "it\'s a"?',
    ),
    _GrammarPattern(
      pattern: r'\bshould\s+of\b',
      message: 'Grammar error: "should of" — should be "should have"',
    ),
    _GrammarPattern(
      pattern: r'\bcould\s+of\b',
      message: 'Grammar error: "could of" — should be "could have"',
    ),
    _GrammarPattern(
      pattern: r'\bwould\s+of\b',
      message: 'Grammar error: "would of" — should be "would have"',
    ),
    _GrammarPattern(
      pattern: r'\beffect\s+on\b',
      message: 'Check: "effect on" — verify if "affect" is the intended word',
    ),
    _GrammarPattern(
      pattern: r'\bless\s+\w+s\b',
      message: 'Check: "less" with plural noun — consider "fewer"',
    ),
    _GrammarPattern(
      pattern: r'\bwhich\s+\w+\s+\w+\s+,\s*which\b',
      message: 'Possible ambiguous "which" reference',
    ),
  ];

  // ─── Ambiguity indicators ──────────────────────────────────────────

  static const List<String> _ambiguityIndicators = [
    'it refers to',
    'this could mean',
    'that is to say',
    'in other words',
    'some people say',
    'sometimes',
    'maybe',
    'perhaps',
    'might be considered',
  ];

  // ─── Main validation entry point ──────────────────────────────────

  /// Validate a generated question by running all automated checks.
  ///
  /// Returns a list of [ValidationResultEntity] instances. An empty list
  /// means the question passed all checks.
  Future<List<ValidationResultEntity>> validate(
    GeneratedQuestionEntity question,
  ) async {
    final results = <ValidationResultEntity>[];

    // Run each check and collect non-null results
    final grammar = checkGrammar(question.content);
    if (grammar != null) results.add(grammar);

    // Check answer options for grammar too
    for (final option in question.answerOptions) {
      final optionText = option['text'] as String? ?? option['content'] as String? ?? '';
      if (optionText.isNotEmpty) {
        final optionGrammar = checkGrammar(optionText);
        if (optionGrammar != null) {
          results.add(optionGrammar.copyWith(
            validationType: 'grammar_option',
            message: 'Option ${option['label'] ?? ""}: ${optionGrammar.message}',
          ));
        }
      }
    }

    final ambiguity = checkAmbiguity(question.content);
    if (ambiguity != null) results.add(ambiguity);

    final clarity = checkClarity(question.content);
    if (clarity != null) results.add(clarity);

    final answerAccuracy = checkAnswerAccuracy(question);
    if (answerAccuracy != null) results.add(answerAccuracy);

    final difficultyConsistency = checkDifficultyConsistency(question);
    if (difficultyConsistency != null) results.add(difficultyConsistency);

    final readingLevel = checkReadingLevel(
      question.content,
      question.curriculumAlignment?['class_level'] as String? ?? '',
    );
    if (readingLevel != null) results.add(readingLevel);

    AppLogger.info('Validation complete for question ${question.id}: '
        '${results.length} issue(s) found');

    return results;
  }

  /// Validate with duplicate checking against existing questions.
  Future<List<ValidationResultEntity>> validateWithDuplicates(
    GeneratedQuestionEntity question,
    List<QuestionEntity> existingQuestions,
  ) async {
    final results = await validate(question);

    final duplicate = await checkDuplicate(question, existingQuestions);
    if (duplicate != null) results.add(duplicate);

    return results;
  }

  /// Validate with curriculum alignment checking.
  Future<List<ValidationResultEntity>> validateWithCurriculum(
    GeneratedQuestionEntity question,
    CurriculumMappingEntity? mapping,
  ) async {
    final results = await validate(question);

    if (mapping != null) {
      final alignment = checkCurriculumAlignment(question, mapping);
      if (alignment != null) results.add(alignment);
    }

    return results;
  }

  // ─── Individual Checks ────────────────────────────────────────────

  /// Check grammar and spelling using rule-based patterns.
  ///
  /// This is a lightweight heuristic check. For production-grade
  /// grammar checking, consider integrating with a language tool API.
  ValidationResultEntity? checkGrammar(String content) {
    if (content.trim().isEmpty) {
      return ValidationResultEntity(
        id: '',
        generatedQuestionId: '',
        validationType: 'grammar',
        severity: ValidationSeverity.critical,
        message: 'Question content is empty',
        suggestion: 'Provide non-empty question content',
        isResolved: false,
        resolvedBy: null,
        resolvedAt: null,
        createdAt: DateTime.now(),
      );
    }

    final issues = <String>[];

    for (final pattern in _grammarPatterns) {
      if (RegExp(pattern.pattern, caseSensitive: false).hasMatch(content)) {
        issues.add(pattern.message);
      }
    }

    // Check for double spaces
    if (RegExp(r'  +').hasMatch(content)) {
      issues.add('Text contains double spaces');
    }

    // Check for missing question mark at end of direct questions
    final trimmedContent = content.trim();
    if (trimmedContent.contains('?') == false &&
        (trimmedContent.startsWithWh('Wh') ||
            trimmedContent.toLowerCase().startsWith('how') ||
            trimmedContent.toLowerCase().startsWith('what') ||
            trimmedContent.toLowerCase().startsWith('which') ||
            trimmedContent.toLowerCase().startsWith('who') ||
            trimmedContent.toLowerCase().startsWith('where') ||
            trimmedContent.toLowerCase().startsWith('when') ||
            trimmedContent.toLowerCase().startsWith('why'))) {
      issues.add('Question appears to be a direct question but is missing a question mark');
    }

    // Check for very short content
    if (content.split(' ').length < 4) {
      issues.add('Question content is very short (less than 4 words)');
    }

    if (issues.isEmpty) return null;

    return ValidationResultEntity(
      id: '',
      generatedQuestionId: '',
      validationType: 'grammar',
      severity: issues.length > 2 ? ValidationSeverity.warning : ValidationSeverity.info,
      message: 'Grammar/spelling issues found: ${issues.join("; ")}',
      suggestion: 'Review and correct the identified grammar issues',
      isResolved: false,
      resolvedBy: null,
      resolvedAt: null,
      createdAt: DateTime.now(),
    );
  }

  /// Check for duplicate questions by comparing content similarity.
  ///
  /// Uses a Jaccard similarity measure on word sets. Questions with
  /// >80% word overlap are flagged as potential duplicates.
  Future<ValidationResultEntity?> checkDuplicate(
    GeneratedQuestionEntity question,
    List<QuestionEntity> existingQuestions,
  ) async {
    final questionWords = _normalizeAndTokenize(question.content);

    if (questionWords.isEmpty) return null;

    for (final existing in existingQuestions) {
      final existingWords = _normalizeAndTokenize(existing.content);

      if (existingWords.isEmpty) continue;

      // Calculate Jaccard similarity
      final intersection = questionWords.intersection(existingWords).length;
      final union = questionWords.union(existingWords).length;
      final similarity = union > 0 ? intersection / union : 0.0;

      if (similarity > 0.8) {
        return ValidationResultEntity(
          id: '',
          generatedQuestionId: question.id,
          validationType: 'duplicate',
          severity: ValidationSeverity.error,
          message: 'Potential duplicate detected (similarity: '
              '${(similarity * 100).toStringAsFixed(1)}%)',
          suggestion: 'Modify the question to make it distinct, or use the '
              'existing question',
          isResolved: false,
          resolvedBy: null,
          resolvedAt: null,
          createdAt: DateTime.now(),
        );
      }
    }

    return null;
  }

  /// Check answer accuracy: correct answer should be clearly correct,
  /// and distractors should be plausible but definitively wrong.
  ValidationResultEntity? checkAnswerAccuracy(
    GeneratedQuestionEntity question,
  ) {
    final options = question.answerOptions;
    if (options.isEmpty) return null; // Not a multiple-choice question

    // Check that exactly one option is marked correct
    final correctOptions = options.where((o) {
      return (o['is_correct'] as bool?) ?? (o['isCorrect'] as bool?) ?? false;
    }).toList();

    if (correctOptions.isEmpty) {
      return ValidationResultEntity(
        id: '',
        generatedQuestionId: question.id,
        validationType: 'answer_accuracy',
        severity: ValidationSeverity.critical,
        message: 'No correct answer is marked in the answer options',
        suggestion: 'Mark exactly one option as the correct answer',
        isResolved: false,
        resolvedBy: null,
        resolvedAt: null,
        createdAt: DateTime.now(),
      );
    }

    // For single-answer MCQs, check that only one is correct
    if (question.questionType == QuestionType.multipleChoice &&
        correctOptions.length > 1) {
      return ValidationResultEntity(
        id: '',
        generatedQuestionId: question.id,
        validationType: 'answer_accuracy',
        severity: ValidationSeverity.error,
        message: 'Multiple-choice question has ${correctOptions.length} '
            'correct answers; expected exactly 1',
        suggestion: 'For MCQs, only one option should be correct. '
            'Use multiple_response type for multiple correct answers.',
        isResolved: false,
        resolvedBy: null,
        resolvedAt: null,
        createdAt: DateTime.now(),
      );
    }

    // Check that option texts are not empty
    for (int i = 0; i < options.length; i++) {
      final text = options[i]['text'] as String? ??
          options[i]['content'] as String? ?? '';
      if (text.trim().isEmpty) {
        return ValidationResultEntity(
          id: '',
          generatedQuestionId: question.id,
          validationType: 'answer_accuracy',
          severity: ValidationSeverity.error,
          message: 'Answer option ${i + 1} has empty text',
          suggestion: 'Provide text for all answer options',
          isResolved: false,
          resolvedBy: null,
          resolvedAt: null,
          createdAt: DateTime.now(),
        );
      }
    }

    // Check for duplicate option texts
    final optionTexts = options
        .map((o) => (o['text'] as String? ?? o['content'] as String? ?? '')
            .trim()
            .toLowerCase())
        .toList();
    if (optionTexts.toSet().length != optionTexts.length) {
      return ValidationResultEntity(
        id: '',
        generatedQuestionId: question.id,
        validationType: 'answer_accuracy',
        severity: ValidationSeverity.error,
        message: 'Two or more answer options have identical text',
        suggestion: 'Make each option distinct',
        isResolved: false,
        resolvedBy: null,
        resolvedAt: null,
        createdAt: DateTime.now(),
      );
    }

    // Check for "All of the above" / "None of the above" patterns
    // These can sometimes indicate poor distractor quality
    for (final option in options) {
      final text = (option['text'] as String? ?? '').toLowerCase();
      final isCorrect = (option['is_correct'] as bool?) ??
          (option['isCorrect'] as bool?) ??
          false;
      if ((text.contains('all of the above') ||
              text.contains('none of the above')) &&
          isCorrect) {
        return ValidationResultEntity(
          id: '',
          generatedQuestionId: question.id,
          validationType: 'answer_accuracy',
          severity: ValidationSeverity.warning,
          message: '"All/None of the above" is marked as correct — '
              'this can be a poor testing strategy',
          suggestion:
              'Consider using specific correct answers instead of catch-all options',
          isResolved: false,
          resolvedBy: null,
          resolvedAt: null,
          createdAt: DateTime.now(),
        );
      }
    }

    // Check that option lengths are not wildly different
    // (could give away the answer)
    if (options.length >= 3) {
      final lengths = options
          .map((o) =>
              (o['text'] as String? ?? o['content'] as String? ?? '').length)
          .toList();
      final avgLength = lengths.reduce((a, b) => a + b) / lengths.length;
      for (int i = 0; i < lengths.length; i++) {
        if (avgLength > 0 && (lengths[i] / avgLength) > 2.0) {
          return ValidationResultEntity(
            id: '',
            generatedQuestionId: question.id,
            validationType: 'answer_accuracy',
            severity: ValidationSeverity.warning,
            message: 'Option ${i + 1} is significantly longer than other '
                'options, which may give away the answer',
            suggestion:
                'Make all options roughly the same length',
            isResolved: false,
            resolvedBy: null,
            resolvedAt: null,
            createdAt: DateTime.now(),
          );
        }
      }
    }

    return null;
  }

  /// Check for ambiguous wording in the question content.
  ValidationResultEntity? checkAmbiguity(String content) {
    final lowerContent = content.toLowerCase();

    // Check for ambiguity indicators
    final foundIndicators = <String>[];
    for (final indicator in _ambiguityIndicators) {
      if (lowerContent.contains(indicator.toLowerCase())) {
        foundIndicators.add(indicator);
      }
    }

    // Check for pronouns without clear antecedents
    final pronounPattern = RegExp(r'\b(it|they|this|that|these|those)\b',
        caseSensitive: false);
    final pronounMatches = pronounPattern.allMatches(content);
    if (pronounMatches.length > 2) {
      foundIndicators.add(
          'Excessive use of pronouns (it/they/this/that) — '
          'antecedents may be unclear');
    }

    // Check for "not" and "except" which can create confusion
    if (lowerContent.contains(' not ') && lowerContent.contains(' except ')) {
      foundIndicators.add(
          'Double negative pattern detected (both "not" and "except")');
    }

    // Check for "which of the following" without a specific criteria
    if (lowerContent.contains('which of the following') &&
        !lowerContent.contains('is true') &&
        !lowerContent.contains('is correct') &&
        !lowerContent.contains('is false') &&
        !lowerContent.contains('are true') &&
        !lowerContent.contains('are correct')) {
      foundIndicators.add(
          '"Which of the following" without clear selection criteria');
    }

    if (foundIndicators.isEmpty) return null;

    return ValidationResultEntity(
      id: '',
      generatedQuestionId: '',
      validationType: 'ambiguity',
      severity: ValidationSeverity.warning,
      message: 'Potential ambiguity detected: ${foundIndicators.join("; ")}',
      suggestion: 'Rewrite the question to eliminate ambiguous wording',
      isResolved: false,
      resolvedBy: null,
      resolvedAt: null,
      createdAt: DateTime.now(),
    );
  }

  /// Check clarity of the question content.
  ValidationResultEntity? checkClarity(String content) {
    final issues = <String>[];

    // Check for overly long sentences
    final sentences = content.split(RegExp(r'[.!?]'));
    for (final sentence in sentences) {
      final wordCount = sentence.trim().split(RegExp(r'\s+')).length;
      if (wordCount > 40) {
        issues.add('Sentence with $wordCount words is too long '
            '(recommended max: 40 words)');
      }
    }

    // Check for nested clauses (multiple commas might indicate complexity)
    final commaCount = ','.allMatches(content).length;
    if (commaCount > 4) {
      issues.add('High number of commas ($commaCount) suggests '
          'complex sentence structure');
    }

    // Check for parenthetical expressions that might confuse
    final parenCount = '('.allMatches(content).length;
    if (parenCount > 2) {
      issues.add('Multiple parenthetical expressions may reduce clarity');
    }

    // Check overall word count
    final totalWords = content.split(RegExp(r'\s+')).length;
    if (totalWords > 100) {
      issues.add('Question is very long ($totalWords words) — '
          'consider simplifying');
    }

    // Check for double negatives
    if (RegExp(r'\bnot\s+\w+\s+not\b', caseSensitive: false)
        .hasMatch(content)) {
      issues.add('Double negative detected — can confuse students');
    }

    if (issues.isEmpty) return null;

    return ValidationResultEntity(
      id: '',
      generatedQuestionId: '',
      validationType: 'clarity',
      severity: ValidationSeverity.info,
      message: 'Clarity concerns: ${issues.join("; ")}',
      suggestion: 'Simplify the question wording for better student comprehension',
      isResolved: false,
      resolvedBy: null,
      resolvedAt: null,
      createdAt: DateTime.now(),
    );
  }

  /// Estimate reading level using a simplified Flesch-Kincaid approach.
  ValidationResultEntity? checkReadingLevel(
    String content,
    String classLevel,
  ) {
    if (content.trim().isEmpty || classLevel.isEmpty) return null;

    // Flesch-Kincaid Grade Level estimation
    final words = content.split(RegExp(r'\s+'));
    final wordCount = words.length;
    if (wordCount == 0) return null;

    // Count syllables (simplified estimation)
    int totalSyllables = 0;
    for (final word in words) {
      totalSyllables += _countSyllables(word);
    }

    // Count sentences
    final sentences = content.split(RegExp(r'[.!?]'));
    final sentenceCount = sentences.where((s) => s.trim().isNotEmpty).length;
    if (sentenceCount == 0) return null;

    // Flesch-Kincaid Grade Level formula
    final gradeLevel = (0.39 * (wordCount / sentenceCount)) +
        (11.8 * (totalSyllables / wordCount)) -
        15.59;

    // Map class level to expected reading level
    final expectedLevel = _classLevelToReadingLevel(classLevel);

    if (gradeLevel > expectedLevel + 2) {
      return ValidationResultEntity(
        id: '',
        generatedQuestionId: '',
        validationType: 'reading_level',
        severity: ValidationSeverity.warning,
        message: 'Reading level (grade ${gradeLevel.toStringAsFixed(1)}) '
            'is significantly above expected level (grade $expectedLevel) '
            'for class $classLevel',
        suggestion: 'Simplify vocabulary and sentence structure to match '
            'the target reading level',
        isResolved: false,
        resolvedBy: null,
        resolvedAt: null,
        createdAt: DateTime.now(),
      );
    }

    return null;
  }

  /// Check curriculum alignment of the question.
  ValidationResultEntity? checkCurriculumAlignment(
    GeneratedQuestionEntity question,
    CurriculumMappingEntity? mapping,
  ) {
    if (mapping == null) return null;

    final issues = <String>[];

    // Check if question difficulty matches suggested difficulty
    if (mapping.suggestedDifficulty != null &&
        question.difficulty != mapping.suggestedDifficulty) {
      issues.add(
          'Question difficulty (${question.difficulty.label}) does not match '
              'curriculum suggestion (${mapping.suggestedDifficulty!.label})');
    }

    // Check if Bloom's level is in the curriculum's suggested levels
    if (question.bloomLevel != null &&
        mapping.bloomLevels.isNotEmpty &&
        !mapping.bloomLevels.contains(question.bloomLevel)) {
      issues.add(
          "Question Bloom's level (${question.bloomLevel!.label}) is not "
              'in the curriculum\'s suggested levels '
              '(${mapping.bloomLevels.map((b) => b.label).join(", ")})');
    }

    // Check if the topic matches
    if (mapping.learningObjectives.isEmpty) {
      issues.add(
          'No learning objectives defined in the curriculum mapping');
    }

    if (issues.isEmpty) return null;

    return ValidationResultEntity(
      id: '',
      generatedQuestionId: question.id,
      validationType: 'curriculum_alignment',
      severity: ValidationSeverity.warning,
      message: 'Curriculum alignment issues: ${issues.join("; ")}',
      suggestion: 'Adjust the question to better align with curriculum standards',
      isResolved: false,
      resolvedBy: null,
      resolvedAt: null,
      createdAt: DateTime.now(),
    );
  }

  /// Check difficulty consistency between stated difficulty and
  /// question characteristics.
  ValidationResultEntity? checkDifficultyConsistency(
    GeneratedQuestionEntity question,
  ) {
    final issues = <String>[];

    // Check if Bloom's level and difficulty are consistent
    if (question.bloomLevel != null) {
      final expectedDifficulty = _bloomToExpectedDifficulty(question.bloomLevel!);
      if (question.difficulty != expectedDifficulty &&
          !_isCompatibleDifficulty(question.difficulty, expectedDifficulty)) {
        issues.add(
            "Bloom's level (${question.bloomLevel!.label}) typically "
                'corresponds to ${expectedDifficulty.label} difficulty, '
                'but question is marked as ${question.difficulty.label}');
      }
    }

    // Check if answer options count is appropriate for difficulty
    if (question.answerOptions.isNotEmpty) {
      final optionCount = question.answerOptions.length;
      if (question.difficulty == DifficultyLevel.easy && optionCount > 4) {
        issues.add(
            'Easy questions typically have 3-4 options, but this has $optionCount');
      }
      if (question.difficulty == DifficultyLevel.hard && optionCount < 4) {
        issues.add(
            'Hard questions typically have 4+ options for adequate '
                'discrimination, but this has only $optionCount');
      }
    }

    // Check if marks are appropriate for difficulty
    if (question.difficulty == DifficultyLevel.expert && question.marks < 3) {
      issues.add(
          'Expert-level questions should typically carry more marks '
              '(currently ${question.marks})');
    }

    if (issues.isEmpty) return null;

    return ValidationResultEntity(
      id: '',
      generatedQuestionId: question.id,
      validationType: 'difficulty_consistency',
      severity: ValidationSeverity.info,
      message: 'Difficulty consistency issues: ${issues.join("; ")}',
      suggestion: 'Review the difficulty level and adjust question '
          'parameters accordingly',
      isResolved: false,
      resolvedBy: null,
      resolvedAt: null,
      createdAt: DateTime.now(),
    );
  }

  // ─── Private Utility Methods ──────────────────────────────────────

  /// Normalize text and split into a set of unique words for comparison.
  Set<String> _normalizeAndTokenize(String text) {
    return text
        .toLowerCase()
        .replaceAll(RegExp(r'[^\w\s]'), '')
        .split(RegExp(r'\s+'))
        .where((w) => w.length > 2) // Ignore very short words
        .toSet();
  }

  /// Count syllables in a word using a simple heuristic.
  int _countSyllables(String word) {
    final w = word.toLowerCase().replaceAll(RegExp(r'[^a-z]'), '');
    if (w.isEmpty) return 0;
    if (w.length <= 3) return 1;

    int count = 0;
    final vowels = RegExp(r'[aeiouy]');
    bool prevVowel = false;

    for (int i = 0; i < w.length; i++) {
      final isVowel = vowels.hasMatch(w[i]);
      if (isVowel && !prevVowel) count++;
      prevVowel = isVowel;
    }

    // Handle silent 'e' at end
    if (w.endsWith('e') && count > 1) count--;

    // Handle 'le' at end
    if (w.endsWith('le') && w.length > 2 && !vowels.hasMatch(w[w.length - 3])) {
      count++;
    }

    return count.clamp(1, 20);
  }

  /// Map a class level string to an approximate reading grade level.
  int _classLevelToReadingLevel(String classLevel) {
    // Try to parse numeric class level
    final numericMatch = RegExp(r'(\d+)').firstMatch(classLevel);
    if (numericMatch != null) {
      final grade = int.tryParse(numericMatch.group(1)!) ?? 6;
      return grade + 5; // Class 6 ≈ grade 11 reading level, etc.
    }

    // Map common class level names
    final lower = classLevel.toLowerCase();
    if (lower.contains('primary') || lower.contains('elementary')) return 5;
    if (lower.contains('junior') || lower.contains('middle')) return 8;
    if (lower.contains('senior') || lower.contains('secondary')) return 11;
    if (lower.contains('university') || lower.contains('college')) return 14;

    return 10; // Default
  }

  /// Map Bloom's taxonomy level to an expected difficulty level.
  DifficultyLevel _bloomToExpectedDifficulty(BloomTaxonomy bloom) {
    switch (bloom) {
      case BloomTaxonomy.remember:
      case BloomTaxonomy.understand:
        return DifficultyLevel.easy;
      case BloomTaxonomy.apply:
        return DifficultyLevel.medium;
      case BloomTaxonomy.analyze:
        return DifficultyLevel.medium;
      case BloomTaxonomy.evaluate:
        return DifficultyLevel.hard;
      case BloomTaxonomy.create:
        return DifficultyLevel.expert;
    }
  }

  /// Check if two difficulty levels are compatible (adjacent).
  bool _isCompatibleDifficulty(DifficultyLevel actual, DifficultyLevel expected) {
    const order = [
      DifficultyLevel.easy,
      DifficultyLevel.medium,
      DifficultyLevel.hard,
      DifficultyLevel.expert,
    ];
    final actualIndex = order.indexOf(actual);
    final expectedIndex = order.indexOf(expected);
    return (actualIndex - expectedIndex).abs() <= 1;
  }
}

// ═══════════════════════════════════════════════════════════════════════
// INTERNAL HELPER CLASSES
// ═══════════════════════════════════════════════════════════════════════

class _GrammarPattern {
  const _GrammarPattern({
    required this.pattern,
    required this.message,
  });

  final String pattern;
  final String message;
}

/// Extension on [String] to check if it starts with common question words.
extension _StringQuestionExtension on String {
  bool startsWithWh(String prefix) {
    final lower = toLowerCase();
    return lower.startsWith('${prefix.toLowerCase()}wh') ||
        lower.startsWith('wh');
  }
}
