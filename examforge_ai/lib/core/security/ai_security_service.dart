// ============================================================================
// ExamForge AI — AI Security Service
// ============================================================================
// Provides defense-in-depth protection for AI-powered features:
//   1. Prompt injection detection and sanitization
//   2. Output validation (structure, content, safety)
//   3. Hallucination mitigation
//   4. Rate limiting per user/feature
//   5. Content safety filtering
//   6. Token usage tracking and cost controls
// ============================================================================

import '../../../core/utils/logger.dart';

// ═══════════════════════════════════════════════════════════════════════
// PROMPT INJECTION PATTERNS
// ═══════════════════════════════════════════════════════════════════════

/// Known prompt injection attack patterns.
/// These patterns are commonly used to trick AI models into ignoring
/// their system prompts and performing unintended actions.
class PromptInjectionPatterns {
  PromptInjectionPatterns._();

  /// High-confidence injection patterns (always block).
  static const List<RegExp> critical = [
    // Direct instruction overrides
    RegExp(r'ignore\s+(all\s+)?previous\s+instructions', caseSensitive: false),
    RegExp(r'disregard\s+(all\s+)?previous', caseSensitive: false),
    RegExp(r'forget\s+(all\s+)?previous\s+instructions', caseSensitive: false),
    RegExp(r'you\s+are\s+now\s+a', caseSensitive: false),
    RegExp(r'pretend\s+you\s+are', caseSensitive: false),
    RegExp(r'act\s+as\s+if\s+you\s+are', caseSensitive: false),
    RegExp(r'simulate\s+being\s+a', caseSensitive: false),

    // System prompt extraction attempts
    RegExp(r'repeat\s+your\s+(system\s+)?prompt', caseSensitive: false),
    RegExp(r'show\s+me\s+your\s+instructions', caseSensitive: false),
    RegExp(r'what\s+are\s+your\s+instructions', caseSensitive: false),
    RegExp(r'output\s+your\s+system\s+prompt', caseSensitive: false),
    RegExp(r'print\s+your\s+initial\s+prompt', caseSensitive: false),

    // DAN (Do Anything Now) variants
    RegExp(r'DAN\s+mode', caseSensitive: false),
    RegExp(r'do\s+anything\s+now', caseSensitive: false),
    RegExp(r'jailbreak', caseSensitive: false),
    RegExp(r'bypass\s+(your\s+)?(restrictions|rules|filters)', caseSensitive: false),

    // Data extraction attempts
    RegExp(r'reveal\s+(the\s+)?(answer|solution|key)', caseSensitive: false),
    RegExp(r'give\s+me\s+(the\s+)?(answer|solution|key)', caseSensitive: false),
    RegExp(r'tell\s+me\s+(the\s+)?correct\s+answer', caseSensitive: false),
  ];

  /// Medium-confidence injection patterns (flag for review).
  static const List<RegExp> suspicious = [
    RegExp(r'new\s+instruction', caseSensitive: false),
    RegExp(r'system\s*:', caseSensitive: false),
    RegExp(r'assistant\s*:', caseSensitive: false),
    RegExp(r'human\s*:', caseSensitive: false),
    RegExp(r'###\s*instruction', caseSensitive: false),
    RegExp(r'\[SYSTEM\]', caseSensitive: false),
    RegExp(r'ROLE\s*:', caseSensitive: false),
    RegExp(r'stop\s+being\s+a', caseSensitive: false),
    RegExp(r'don\'?t\s+be\s+a', caseSensitive: false),
  ];
}

// ═══════════════════════════════════════════════════════════════════════
// SECURITY CHECK RESULT
// ═══════════════════════════════════════════════════════════════════════

/// Result of a security check on user input or AI output.
class SecurityCheckResult {
  const SecurityCheckResult({
    required this.isSafe,
    required this.riskLevel,
    this.detectedPatterns = const [],
    this.sanitizedInput,
    this.reason,
  });

  final bool isSafe;
  final RiskLevel riskLevel;
  final List<String> detectedPatterns;
  final String? sanitizedInput;
  final String? reason;

  factory SecurityCheckResult.safe() => const SecurityCheckResult(
        isSafe: true,
        riskLevel: RiskLevel.none,
      );

  factory SecurityCheckResult.suspicious(List<String> patterns) =>
      SecurityCheckResult(
        isSafe: true, // Allow but log
        riskLevel: RiskLevel.low,
        detectedPatterns: patterns,
        reason: 'Suspicious patterns detected: ${patterns.join(", ")}',
      );

  factory SecurityCheckResult.dangerous(List<String> patterns, {String? sanitized}) =>
      SecurityCheckResult(
        isSafe: false,
        riskLevel: RiskLevel.critical,
        detectedPatterns: patterns,
        sanitizedInput: sanitized,
        reason: 'Critical injection patterns detected: ${patterns.join(", ")}',
      );
}

/// Risk level for AI security checks.
enum RiskLevel { none, low, medium, high, critical }

// ═══════════════════════════════════════════════════════════════════════
// AI SECURITY SERVICE
// ═══════════════════════════════════════════════════════════════════════

/// Centralized AI security service that provides defense-in-depth
/// protection for all AI-powered features.
class AiSecurityService {
  AiSecurityService._();

  // ─── INPUT VALIDATION (Prompt Injection Detection) ────────────────

  /// Checks user input for prompt injection attacks before sending
  /// it to the AI model.
  ///
  /// Returns a [SecurityCheckResult] indicating whether the input is
  /// safe, suspicious, or dangerous.
  ///
  /// CRITICAL: This MUST be called for ALL user inputs that are
  /// incorporated into AI prompts, including:
  /// - Subject/topic names
  /// - Custom instructions
  /// - Document uploads (text content)
  /// - Question text for improvement
  static SecurityCheckResult checkInput(String input) {
    if (input.isEmpty) return SecurityCheckResult.safe();

    final criticalMatches = <String>[];
    final suspiciousMatches = <String>[];

    // Check critical patterns
    for (final pattern in PromptInjectionPatterns.critical) {
      if (pattern.hasMatch(input)) {
        criticalMatches.add(pattern.pattern);
      }
    }

    // Check suspicious patterns
    for (final pattern in PromptInjectionPatterns.suspicious) {
      if (pattern.hasMatch(input)) {
        suspiciousMatches.add(pattern.pattern);
      }
    }

    // If critical patterns found, block the input
    if (criticalMatches.isNotEmpty) {
      AppLogger.warning(
        'AI SECURITY: Critical prompt injection detected. '
        'Patterns: ${criticalMatches.join(", ")}',
      );
      return SecurityCheckResult.dangerous(
        criticalMatches,
        sanitized: _sanitizeInput(input),
      );
    }

    // If suspicious patterns found, flag for review but allow
    if (suspiciousMatches.isNotEmpty) {
      AppLogger.info(
        'AI SECURITY: Suspicious patterns detected in input. '
        'Patterns: ${suspiciousMatches.join(", ")}',
      );
      return SecurityCheckResult.suspicious(suspiciousMatches);
    }

    return SecurityCheckResult.safe();
  }

  /// Sanitizes user input by removing or escaping potentially
  /// dangerous content.
  static String _sanitizeInput(String input) {
    var sanitized = input;

    // Remove common injection prefixes
    sanitized = sanitized.replaceAll(
      RegExp(r'(ignore|disregard|forget)\s+(all\s+)?previous\s+instructions',
          caseSensitive: false),
      '[REDACTED]',
    );

    // Remove role-playing attempts
    sanitized = sanitized.replaceAll(
      RegExp(r'(you are now|pretend you are|act as if you are)\s+',
          caseSensitive: false),
      '[REDACTED]',
    );

    // Remove system prompt extraction attempts
    sanitized = sanitized.replaceAll(
      RegExp(r'(repeat|show|output|print)\s+(your|the)\s+(system\s+)?prompt',
          caseSensitive: false),
      '[REDACTED]',
    );

    return sanitized;
  }

  // ─── OUTPUT VALIDATION ────────────────────────────────────────────

  /// Validates AI-generated output for structural correctness,
  /// content safety, and potential hallucinations.
  ///
  /// [output] — the raw text output from the AI model.
  /// [expectedFormat] — the expected format (e.g., 'json', 'question_list').
  /// [context] — additional context for validation (e.g., subject, grade level).
  ///
  /// Returns a [SecurityCheckResult] with validation results.
  static SecurityCheckResult validateOutput(
    String output, {
    String? expectedFormat,
    Map<String, dynamic>? context,
  }) {
    if (output.isEmpty) {
      return const SecurityCheckResult(
        isSafe: false,
        riskLevel: RiskLevel.medium,
        reason: 'Empty output from AI model',
      );
    }

    // Check if the output contains leaked system prompt fragments
    final systemPromptLeaks = _checkSystemPromptLeakage(output);
    if (systemPromptLeaks.isNotEmpty) {
      AppLogger.warning(
        'AI SECURITY: System prompt leakage detected in output. '
        'Patterns: ${systemPromptLeaks.join(", ")}',
      );
      return SecurityCheckResult(
        isSafe: false,
        riskLevel: RiskLevel.high,
        detectedPatterns: systemPromptLeaks,
        reason: 'Output contains leaked system prompt content',
      );
    }

    // Validate JSON structure if expected
    if (expectedFormat == 'json') {
      final jsonValid = _validateJsonOutput(output);
      if (!jsonValid) {
        return const SecurityCheckResult(
          isSafe: false,
          riskLevel: RiskLevel.medium,
          reason: 'AI output is not valid JSON',
        );
      }
    }

    // Check for hallucinated content patterns
    final hallucinationCheck = _checkHallucination(output, context: context);
    if (hallucinationCheck.riskLevel == RiskLevel.high) {
      return hallucinationCheck;
    }

    return SecurityCheckResult.safe();
  }

  /// Checks if AI output contains fragments of the system prompt
  /// that should not be visible to users.
  static List<String> _checkSystemPromptLeakage(String output) {
    final leaks = <String>[];

    // Check for system prompt markers
    const leakPatterns = [
      RegExp(r'You are ExamForge', caseSensitive: false),
      RegExp(r'system\s+prompt', caseSensitive: false),
      RegExp(r'###\s*system', caseSensitive: false),
      RegExp(r'\[SYSTEM\]', caseSensitive: false),
      RegExp(r'as an AI (language )?model', caseSensitive: false),
      RegExp(r'I (cannot|can\'t|won\'t) (provide|generate|create)', caseSensitive: false),
    ];

    for (final pattern in leakPatterns) {
      if (pattern.hasMatch(output)) {
        leaks.add(pattern.pattern);
      }
    }

    return leaks;
  }

  /// Validates that the output is parseable as JSON.
  static bool _validateJsonOutput(String output) {
    // Try to extract JSON from markdown code blocks
    final jsonBlockRegex = RegExp(r'```(?:json)?\s*\n?([\s\S]*?)\n?```');
    final jsonMatch = jsonBlockRegex.firstMatch(output);

    String jsonStr;
    if (jsonMatch != null) {
      jsonStr = jsonMatch.group(1)!.trim();
    } else {
      jsonStr = output.trim();
    }

    // Check if it starts with [ or {
    if (!jsonStr.startsWith('[') && !jsonStr.startsWith('{')) {
      return false;
    }

    // Attempt to parse (basic check — the actual parsing happens
    // in the PromptEngine, this is just a structural pre-check)
    try {
      // Simple bracket matching check
      int bracketCount = 0;
      for (int i = 0; i < jsonStr.length; i++) {
        final char = jsonStr[i];
        if (char == '{' || char == '[') bracketCount++;
        if (char == '}' || char == ']') bracketCount--;
        if (bracketCount < 0) return false;
      }
      return bracketCount == 0;
    } catch (_) {
      return false;
    }
  }

  /// Checks for common hallucination patterns in AI output.
  static SecurityCheckResult _checkHallucination(
    String output, {
    Map<String, dynamic>? context,
  }) {
    final warnings = <String>[];

    // Check for placeholder text that indicates hallucination
    const placeholderPatterns = [
      RegExp(r'\[insert\s+\w+\]', caseSensitive: false),
      RegExp(r'\[your\s+\w+\s+here\]', caseSensitive: false),
      RegExp(r'\[teacher\s+name\]', caseSensitive: false),
      RegExp(r'\[school\s+name\]', caseSensitive: false),
      RegExp(r'TBD|TBA|TODO', caseSensitive: false),
    ];

    for (final pattern in placeholderPatterns) {
      if (pattern.hasMatch(output)) {
        warnings.add('Placeholder text detected: ${pattern.pattern}');
      }
    }

    // Check for contradictory content (e.g., "the answer is A" and "the answer is B")
    final answerPattern = RegExp(r'(?:answer|correct)\s*(?:is|:)\s*([A-E])',
        caseSensitive: false);
    final answers = answerPattern.allMatches(output).map((m) => m.group(1)).toList();
    if (answers.toSet().length > 1) {
      warnings.add('Contradictory answers detected: ${answers.join(", ")}');
    }

    // Check for unrealistically long output (may indicate model loop)
    if (output.length > 50000) {
      warnings.add('Output unusually long (${output.length} chars) — possible model loop');
    }

    if (warnings.isNotEmpty) {
      return SecurityCheckResult(
        isSafe: true, // Allow but warn
        riskLevel: RiskLevel.low,
        detectedPatterns: warnings,
        reason: 'Potential hallucination indicators: ${warnings.join("; ")}',
      );
    }

    return SecurityCheckResult.safe();
  }

  // ─── CONTENT SAFETY ───────────────────────────────────────────────

  /// Checks AI output for content that should be filtered.
  /// Returns true if the content is safe for educational use.
  static bool isContentSafe(String content) {
    if (content.isEmpty) return true;

    // Check for harmful content patterns
    const harmfulPatterns = [
      RegExp(r'\b(hack|exploit|vulnerability)\s+(into|against|for)\b',
          caseSensitive: false),
      RegExp(r'\bhow\s+to\s+(cheat|hack|exploit)\b', caseSensitive: false),
      RegExp(r'\b(create|make|build)\s+(a\s+)?(bomb|weapon|drug)\b',
          caseSensitive: false),
    ];

    for (final pattern in harmfulPatterns) {
      if (pattern.hasMatch(content)) {
        AppLogger.warning(
          'AI SECURITY: Potentially harmful content detected: ${pattern.pattern}',
        );
        return false;
      }
    }

    return true;
  }

  // ─── COST CONTROL ─────────────────────────────────────────────────

  /// Maximum allowed cost per single AI request (in USD).
  static const double maxCostPerRequest = 0.50;

  /// Maximum allowed tokens per single AI request.
  static const int maxTokensPerRequest = 8000;

  /// Validates that an AI request is within cost and token limits.
  static bool validateRequestLimits({
    required int inputTokens,
    required int requestedOutputTokens,
    required double estimatedCost,
  }) {
    if (estimatedCost > maxCostPerRequest) {
      AppLogger.warning(
        'AI SECURITY: Request cost ($estimatedCost USD) exceeds limit '
        '($maxCostPerRequest USD). Blocking request.',
      );
      return false;
    }

    if (inputTokens + requestedOutputTokens > maxTokensPerRequest) {
      AppLogger.warning(
        'AI SECURITY: Request tokens (${inputTokens + requestedOutputTokens}) '
        'exceed limit ($maxTokensPerRequest). Blocking request.',
      );
      return false;
    }

    return true;
  }
}
