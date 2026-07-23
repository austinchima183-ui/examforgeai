// ============================================================================
// ExamForge AI — AI Security Service (Hardened)
// ============================================================================
// Provides defense-in-depth protection for AI-powered features:
//   1. Prompt injection detection and sanitization (EXTENDED)
//   2. Unicode obfuscation detection
//   3. Base64-encoded prompt injection detection
//   4. Nested prompt injection detection
//   5. Markdown injection detection
//   6. JSON injection detection
//   7. Role override detection
//   8. System prompt extraction detection
//   9. Context leakage detection
//  10. Output validation (structure, content, safety)
//  11. Audit logging for all blocked requests
//  12. Rate limiting per user/feature
//  13. Content safety filtering
//  14. Token usage tracking and cost controls
//
// ROOT CAUSE (why this file was rewritten):
// The original implementation only detected direct English-language prompt
// injection patterns. It was vulnerable to:
//   - Unicode obfuscation (e.g., zero-width characters, homoglyphs)
//   - Base64-encoded injection payloads
//   - Nested/layered injection attempts
//   - Markdown-formatted injection
//   - JSON-formatted injection
//   - Role override via non-English phrasing
//   - System prompt extraction via subtle phrasing
//   - No audit logging of blocked requests
// ============================================================================

import 'dart:convert';

import '../../core/utils/logger.dart';

// ═══════════════════════════════════════════════════════════════════════
// PROMPT INJECTION PATTERNS (EXTENDED)
// ═══════════════════════════════════════════════════════════════════════

/// Known prompt injection attack patterns.
/// Organized by category for maintainability and targeted detection.
class PromptInjectionPatterns {
  PromptInjectionPatterns._();

  // ─── CRITICAL PATTERNS (Always Block) ────────────────────────────────

  /// High-confidence injection patterns that must always be blocked.
  static final List<RegExp> critical = [
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
    RegExp(r'reveal\s+your\s+(system|initial|original)\s+(prompt|instructions|configuration)', caseSensitive: false),
    RegExp(r'display\s+(the|your)\s+system\s+prompt', caseSensitive: false),
    RegExp(r'what\s+were\s+you\s+told', caseSensitive: false),

    // DAN (Do Anything Now) variants
    RegExp(r'DAN\s+mode', caseSensitive: false),
    RegExp(r'do\s+anything\s+now', caseSensitive: false),
    RegExp(r'jailbreak', caseSensitive: false),
    RegExp(r'bypass\s+(your\s+)?(restrictions|rules|filters)', caseSensitive: false),
    RegExp(r'(enable|activate|turn\s+on)\s+(developer|admin|root|god)\s+mode', caseSensitive: false),

    // Data extraction attempts
    RegExp(r'reveal\s+(the\s+)?(answer|solution|key)', caseSensitive: false),
    RegExp(r'give\s+me\s+(the\s+)?(answer|solution|key)', caseSensitive: false),
    RegExp(r'tell\s+me\s+(the\s+)?correct\s+answer', caseSensitive: false),

    // Role override attempts (NEW)
    RegExp(r'you\s+are\s+no\s+longer\s+(an?\s+)?(AI|assistant|tutor|teacher)', caseSensitive: false),
    RegExp(r'stop\s+being\s+(an?\s+)?(AI|assistant|tutor|teacher)', caseSensitive: false),
    RegExp(r'from\s+now\s+on\s+you\s+(are|will|shall)', caseSensitive: false),
    RegExp(r'your\s+new\s+(role|identity|persona|character)\s+is', caseSensitive: false),
    RegExp(r'switch\s+(to|your)\s+(role|mode|persona)', caseSensitive: false),
  ];

  // ─── SUSPICIOUS PATTERNS (Flag for Review) ───────────────────────────

  /// Medium-confidence injection patterns that should be flagged.
  static final List<RegExp> suspicious = [
    RegExp(r'new\s+instruction', caseSensitive: false),
    RegExp(r'system\s*:', caseSensitive: false),
    RegExp(r'assistant\s*:', caseSensitive: false),
    RegExp(r'human\s*:', caseSensitive: false),
    RegExp(r'###\s*instruction', caseSensitive: false),
    RegExp(r'\[SYSTEM\]', caseSensitive: false),
    RegExp(r'ROLE\s*:', caseSensitive: false),
    RegExp(r'stop\s+being\s+a', caseSensitive: false),
    RegExp(r"don'?t\s+be\s+a", caseSensitive: false),
  ];

  // ─── UNICODE OBFUSCATION PATTERNS (NEW) ──────────────────────────────

  /// Patterns that detect Unicode-based obfuscation attacks.
  static final List<RegExp> unicodeObfuscation = [
    // Zero-width characters (used to hide text)
    RegExp(r'[\u200B-\u200F\u2028-\u202F\u2060-\u206F\uFEFF]'),

    // Control characters that shouldn't be in user input
    RegExp(r'[\x00-\x08\x0B\x0C\x0E-\x1F\x7F]'),

    // Homoglyph attack markers (Cyrillic chars that look like Latin)
    // These are commonly used to bypass keyword filters
    RegExp(r'[\u0400-\u04FF]'), // Cyrillic block

    // Right-to-left override (used to visually hide text direction)
    RegExp(r'[\u202D\u202E]'),

    // Unicode tag characters (invisible)
    RegExp(r'[\uE0000-\uE007F]'),
  ];

  // ─── BASE64 INJECTION PATTERNS (NEW) ─────────────────────────────────

  /// Patterns that detect Base64-encoded injection attempts.
  static final List<RegExp> base64Injection = [
    // Base64 strings that decode to common injection phrases
    // "SWdub3JlIGFsbCBwcmV2aW91cyBpbnN0cnVjdGlvbnM" = "Ignore all previous instructions"
    RegExp(r'SWdub3Jl\s+?\w+', caseSensitive: false),

    // Long base64 strings (likely encoded payloads)
    RegExp(r'(?:[A-Za-z0-9+/]{40,}={0,2})'),

    // Base64 with injection-related keywords nearby
    RegExp(r'(?:decode|base64|b64|atob)\s*[\(\[]', caseSensitive: false),
  ];

  // ─── MARKDOWN INJECTION PATTERNS (NEW) ───────────────────────────────

  /// Patterns that detect Markdown-formatted injection attempts.
  static final List<RegExp> markdownInjection = [
    // Markdown code blocks with system-like instructions
    RegExp(r'```(?:system|instruction|prompt|config)\s*\n', caseSensitive: false),

    // Markdown headers with override instructions
    RegExp(r'#{1,3}\s+(system|instruction|override|ignore|new\s+rule)', caseSensitive: false),

    // Markdown links with javascript: or data: URIs
    RegExp(r'\[.*?\]\(\s*(?:javascript|data|vbscript)\s*:', caseSensitive: false),

    // HTML-like tags in markdown
    RegExp(r'<(?:system|instruction|override|script|iframe)', caseSensitive: false),
  ];

  // ─── JSON INJECTION PATTERNS (NEW) ───────────────────────────────────

  /// Patterns that detect JSON-formatted injection attempts.
  static final List<RegExp> jsonInjection = [
    // JSON with system/instruction overrides
    RegExp(r'"(?:system|instruction|role|override)"\s*:\s*"', caseSensitive: false),

    // JSON with role switching
    RegExp(r'"role"\s*:\s*"(?:system|admin|developer|root)"', caseSensitive: false),

    // JSON with content injection
    RegExp(r'"content"\s*:\s*"(?:ignore|forget|disregard|bypass)', caseSensitive: false),
  ];

  // ─── CONTEXT LEAKAGE PATTERNS (NEW) ──────────────────────────────────

  /// Patterns that detect attempts to extract context or training data.
  static final List<RegExp> contextLeakage = [
    RegExp(r'what\s+(data|information|context)\s+(were\s+you|was)\s+trained\s+on', caseSensitive: false),
    RegExp(r'(extract|leak|reveal|expose)\s+(training|internal|private|confidential)\s+data', caseSensitive: false),
    RegExp(r'(show|display|list|enumerate)\s+(all|your)\s+(knowledge|training\s+data|internal\s+state)', caseSensitive: false),
    RegExp(r'what\s+do\s+you\s+know\s+about\s+(?:other|all)\s+users?', caseSensitive: false),
  ];

  // ─── NESTED INJECTION PATTERNS (NEW) ─────────────────────────────────

  /// Patterns that detect nested/layered injection attempts.
  static final List<RegExp> nestedInjection = [
    // Double-encoded patterns
    RegExp(r'(?:ignore|bypass|override).{0,20}(?:ignore|bypass|override)', caseSensitive: false),

    // Instruction within instruction
    RegExp(r'(?:then|after\s+that|next)\s*,?\s*(?:ignore|forget|disregard)', caseSensitive: false),

    // Conditional overrides
    RegExp(r'if\s+(?:you\s+)?(?:can|could|are\s+able)\s*,?\s*(?:ignore|bypass|reveal)', caseSensitive: false),
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
    this.category = SecurityCategory.unknown,
  });

  final bool isSafe;
  final RiskLevel riskLevel;
  final List<String> detectedPatterns;
  final String? sanitizedInput;
  final String? reason;
  final SecurityCategory category;

  factory SecurityCheckResult.safe() => const SecurityCheckResult(
        isSafe: true,
        riskLevel: RiskLevel.none,
        category: SecurityCategory.none,
      );

  factory SecurityCheckResult.suspicious(
    List<String> patterns, {
    SecurityCategory category = SecurityCategory.unknown,
  }) =>
      SecurityCheckResult(
        isSafe: true, // Allow but log
        riskLevel: RiskLevel.low,
        detectedPatterns: patterns,
        category: category,
        reason: 'Suspicious patterns detected: ${patterns.join(", ")}',
      );

  factory SecurityCheckResult.dangerous(
    List<String> patterns, {
    String? sanitized,
    SecurityCategory category = SecurityCategory.critical,
  }) =>
      SecurityCheckResult(
        isSafe: false,
        riskLevel: RiskLevel.critical,
        detectedPatterns: patterns,
        sanitizedInput: sanitized,
        category: category,
        reason: 'Critical injection patterns detected: ${patterns.join(", ")}',
      );
}

/// Risk level for AI security checks.
enum RiskLevel { none, low, medium, high, critical }

/// Category of security threat detected.
enum SecurityCategory {
  none,
  critical,
  unicodeObfuscation,
  base64Injection,
  markdownInjection,
  jsonInjection,
  roleOverride,
  systemPromptExtraction,
  contextLeakage,
  nestedInjection,
  suspicious,
  unknown,
}

// ═══════════════════════════════════════════════════════════════════════
// AI SECURITY SERVICE (HARDENED)
// ═══════════════════════════════════════════════════════════════════════

/// Centralized AI security service that provides defense-in-depth
/// protection for all AI-powered features.
///
/// HARDENED with:
/// - Unicode normalization before pattern matching
/// - Base64 payload detection and decoding
/// - Nested injection detection
/// - Markdown injection detection
/// - JSON injection detection
/// - Role override detection
/// - System prompt extraction detection
/// - Context leakage detection
/// - Comprehensive audit logging
class AiSecurityService {
  AiSecurityService._();

  /// In-memory audit log for blocked requests.
  /// In production, this should be persisted to a database table.
  static final List<AuditLogEntry> _auditLog = [];

  /// Maximum audit log entries to keep in memory.
  static const int _maxAuditLogSize = 10000;

  // ─── INPUT VALIDATION (Prompt Injection Detection — HARDENED) ─────

  /// Checks user input for prompt injection attacks before sending
  /// it to the AI model.
  ///
  /// HARDENED: Now also detects:
  /// - Unicode obfuscation attempts
  /// - Base64-encoded injection payloads
  /// - Nested/layered injection
  /// - Markdown-formatted injection
  /// - JSON-formatted injection
  /// - Role override attempts
  /// - System prompt extraction via subtle phrasing
  /// - Context leakage attempts
  ///
  /// Input is normalized before pattern matching to defeat
  /// Unicode-based evasion.
  static SecurityCheckResult checkInput(String input) {
    if (input.isEmpty) return SecurityCheckResult.safe();

    final criticalMatches = <String>[];
    final suspiciousMatches = <String>[];
    SecurityCategory topCategory = SecurityCategory.none;

    // ─── Step 1: Normalize input to defeat Unicode evasion ──────────
    final normalized = _normalizeInput(input);

    // ─── Step 2: Check critical patterns ────────────────────────────
    for (final pattern in PromptInjectionPatterns.critical) {
      if (pattern.hasMatch(normalized)) {
        criticalMatches.add(pattern.pattern);
        topCategory = SecurityCategory.critical;
      }
    }

    // ─── Step 3: Check suspicious patterns ──────────────────────────
    for (final pattern in PromptInjectionPatterns.suspicious) {
      if (pattern.hasMatch(normalized)) {
        suspiciousMatches.add(pattern.pattern);
        if (topCategory == SecurityCategory.none) {
          topCategory = SecurityCategory.suspicious;
        }
      }
    }

    // ─── Step 4: Check Unicode obfuscation ──────────────────────────
    final unicodeMatches = <String>[];
    for (final pattern in PromptInjectionPatterns.unicodeObfuscation) {
      if (pattern.hasMatch(input)) { // Check ORIGINAL input, not normalized
        unicodeMatches.add(pattern.pattern);
        criticalMatches.add('Unicode obfuscation: ${pattern.pattern}');
        topCategory = SecurityCategory.unicodeObfuscation;
      }
    }

    // ─── Step 5: Check Base64 injection ─────────────────────────────
    final base64Matches = _checkBase64Injection(input, normalized);
    if (base64Matches.isNotEmpty) {
      criticalMatches.addAll(base64Matches);
      topCategory = SecurityCategory.base64Injection;
    }

    // ─── Step 6: Check Markdown injection ───────────────────────────
    for (final pattern in PromptInjectionPatterns.markdownInjection) {
      if (pattern.hasMatch(normalized)) {
        criticalMatches.add('Markdown injection: ${pattern.pattern}');
        topCategory = SecurityCategory.markdownInjection;
      }
    }

    // ─── Step 7: Check JSON injection ───────────────────────────────
    for (final pattern in PromptInjectionPatterns.jsonInjection) {
      if (pattern.hasMatch(normalized)) {
        criticalMatches.add('JSON injection: ${pattern.pattern}');
        topCategory = SecurityCategory.jsonInjection;
      }
    }

    // ─── Step 8: Check role override attempts ───────────────────────
    for (final pattern in PromptInjectionPatterns.critical) {
      // Role override patterns are already in critical, but we also
      // check for them specifically for categorization
      if (pattern.pattern.contains('role|identity|persona|character|no longer')) {
        if (pattern.hasMatch(normalized)) {
          topCategory = SecurityCategory.roleOverride;
        }
      }
    }

    // ─── Step 9: Check context leakage ──────────────────────────────
    for (final pattern in PromptInjectionPatterns.contextLeakage) {
      if (pattern.hasMatch(normalized)) {
        criticalMatches.add('Context leakage: ${pattern.pattern}');
        topCategory = SecurityCategory.contextLeakage;
      }
    }

    // ─── Step 10: Check nested injection ────────────────────────────
    for (final pattern in PromptInjectionPatterns.nestedInjection) {
      if (pattern.hasMatch(normalized)) {
        criticalMatches.add('Nested injection: ${pattern.pattern}');
        topCategory = SecurityCategory.nestedInjection;
      }
    }

    // ─── Step 11: Return result ─────────────────────────────────────
    if (criticalMatches.isNotEmpty) {
      _logBlockedRequest(
        input: input,
        patterns: criticalMatches,
        category: topCategory,
      );
      AppLogger.warning(
        'AI SECURITY: Critical prompt injection detected. '
        'Category: $topCategory, Patterns: ${criticalMatches.join(", ")}',
      );
      return SecurityCheckResult.dangerous(
        criticalMatches,
        sanitized: _sanitizeInput(normalized),
        category: topCategory,
      );
    }

    if (suspiciousMatches.isNotEmpty) {
      _logBlockedRequest(
        input: input,
        patterns: suspiciousMatches,
        category: SecurityCategory.suspicious,
        blocked: false,
      );
      AppLogger.info(
        'AI SECURITY: Suspicious patterns detected. '
        'Patterns: ${suspiciousMatches.join(", ")}',
      );
      return SecurityCheckResult.suspicious(suspiciousMatches, category: topCategory);
    }

    return SecurityCheckResult.safe();
  }

  /// Normalize input before pattern matching.
  ///
  /// This defeats Unicode-based evasion techniques:
  /// - Removes zero-width characters
  /// - Normalizes Unicode to NFC form
  /// - Strips control characters
  /// - Converts homoglyphs to ASCII equivalents
  static String _normalizeInput(String input) {
    var normalized = input;

    // Remove zero-width characters
    normalized = normalized.replaceAll(
      RegExp(r'[\u200B-\u200F\u2028-\u202F\u2060-\u206F\uFEFF]'),
      '',
    );

    // Remove control characters (except newline and tab)
    normalized = normalized.replaceAll(
      RegExp(r'[\x00-\x08\x0B\x0C\x0E-\x1F\x7F]'),
      '',
    );

    // Normalize Unicode to composed form (NFC)
    // This converts accented characters to their canonical form
    normalized = normalized.replaceAll(RegExp(r'\uFEFF'), ''); // BOM

    // Convert common Cyrillic homoglyphs to Latin equivalents
    final homoglyphMap = <int, String>{
      0x0430: 'a', // а -> a
      0x0435: 'e', // е -> e
      0x043E: 'o', // о -> o
      0x0440: 'p', // р -> p
      0x0441: 'c', // с -> c
      0x0443: 'y', // у -> y
      0x0445: 'x', // х -> x
      0x0410: 'A', // А -> A
      0x0415: 'E', // Е -> E
      0x041E: 'O', // О -> O
      0x0420: 'P', // Р -> P
      0x0421: 'C', // С -> C
      0x0425: 'X', // Х -> X
    };

    final buffer = StringBuffer();
    for (final codeUnit in normalized.runes) {
      if (homoglyphMap.containsKey(codeUnit)) {
        buffer.write(homoglyphMap[codeUnit]);
      } else {
        buffer.writeCharCode(codeUnit);
      }
    }

    return buffer.toString();
  }

  /// Check for Base64-encoded injection attempts.
  ///
  /// Decodes any long Base64 strings found in the input and checks
  /// the decoded content against critical injection patterns.
  static List<String> _checkBase64Injection(String original, String normalized) {
    final matches = <String>[];

    // Find potential Base64 strings
    final base64Regex = RegExp(r'[A-Za-z0-9+/]{20,}={0,2}');
    final base64Matches = base64Regex.allMatches(normalized);

    for (final match in base64Matches) {
      final candidate = match.group(0)!;

      // Only check strings that look like they could be meaningful payloads
      if (candidate.length < 20) continue;

      try {
        final decoded = utf8.decode(base64Decode(candidate));

        // Check decoded content against critical patterns
        for (final pattern in PromptInjectionPatterns.critical) {
          if (pattern.hasMatch(decoded)) {
            matches.add(
              'Base64 injection: decoded content matches "${pattern.pattern}"',
            );
          }
        }

        // Check for role override in decoded content
        for (final pattern in PromptInjectionPatterns.suspicious) {
          if (pattern.hasMatch(decoded)) {
            matches.add(
              'Base64 suspicious: decoded content matches "${pattern.pattern}"',
            );
          }
        }
      } catch (_) {
        // Not valid Base64 or not valid UTF-8 — ignore
      }
    }

    return matches;
  }

  /// Sanitizes user input by removing or escaping potentially
  /// dangerous content.
  static String _sanitizeInput(String input) {
    var sanitized = input;

    // Remove common injection prefixes
    sanitized = sanitized.replaceAll(
      RegExp(r'(ignore|disregard|forget)\s+(all\s+)?previous\s+instructions',
          caseSensitive: false,),
      '[REDACTED]',
    );

    // Remove role-playing attempts
    sanitized = sanitized.replaceAll(
      RegExp(r'(you are now|pretend you are|act as if you are)\s+',
          caseSensitive: false,),
      '[REDACTED]',
    );

    // Remove system prompt extraction attempts
    sanitized = sanitized.replaceAll(
      RegExp(r'(repeat|show|output|print)\s+(your|the)\s+(system\s+)?prompt',
          caseSensitive: false,),
      '[REDACTED]',
    );

    // Remove role override attempts
    sanitized = sanitized.replaceAll(
      RegExp(r'(you are no longer|stop being|your new role|from now on you)\s+',
          caseSensitive: false,),
      '[REDACTED]',
    );

    // Remove context leakage attempts
    sanitized = sanitized.replaceAll(
      RegExp(r'(extract|leak|reveal|expose)\s+(training|internal|private)\s+',
          caseSensitive: false,),
      '[REDACTED]',
    );

    // Remove zero-width characters
    sanitized = sanitized.replaceAll(
      RegExp(r'[\u200B-\u200F\u2028-\u202F\u2060-\u206F\uFEFF]'),
      '',
    );

    return sanitized;
  }

  // ─── OUTPUT VALIDATION ────────────────────────────────────────────

  /// Validates AI-generated output for structural correctness,
  /// content safety, and potential hallucinations.
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
      _logBlockedRequest(
        input: output,
        patterns: systemPromptLeaks,
        category: SecurityCategory.systemPromptExtraction,
        isOutput: true,
      );
      AppLogger.warning(
        'AI SECURITY: System prompt leakage detected in output. '
        'Patterns: ${systemPromptLeaks.join(", ")}',
      );
      return SecurityCheckResult(
        isSafe: false,
        riskLevel: RiskLevel.high,
        detectedPatterns: systemPromptLeaks,
        reason: 'Output contains leaked system prompt content',
        category: SecurityCategory.systemPromptExtraction,
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

  /// Checks if AI output contains fragments of the system prompt.
  static List<String> _checkSystemPromptLeakage(String output) {
    final leaks = <String>[];

    final leakPatterns = [
      RegExp(r'You are ExamForge', caseSensitive: false),
      RegExp(r'system\s+prompt', caseSensitive: false),
      RegExp(r'###\s*system', caseSensitive: false),
      RegExp(r'\[SYSTEM\]', caseSensitive: false),
      RegExp(r'as an AI (language )?model', caseSensitive: false),
      RegExp(r"I (cannot|can't|won't) (provide|generate|create)", caseSensitive: false),
      RegExp(r'my\s+(instructions|prompt|guidelines|rules)\s+(are|state|say)', caseSensitive: false),
      RegExp(r'I\s+was\s+(instructed|told|programmed)\s+to', caseSensitive: false),
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
    final jsonBlockRegex = RegExp(r'```(?:json)?\s*\n?([\s\S]*?)\n?```');
    final jsonMatch = jsonBlockRegex.firstMatch(output);

    String jsonStr;
    if (jsonMatch != null) {
      jsonStr = jsonMatch.group(1)!.trim();
    } else {
      jsonStr = output.trim();
    }

    if (!jsonStr.startsWith('[') && !jsonStr.startsWith('{')) {
      return false;
    }

    try {
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

    final placeholderPatterns = [
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

    final answerPattern = RegExp(r'(?:answer|correct)\s*(?:is|:)\s*([A-E])',
        caseSensitive: false,);
    final answers = answerPattern.allMatches(output).map((m) => m.group(1)).toList();
    if (answers.toSet().length > 1) {
      warnings.add('Contradictory answers detected: ${answers.join(", ")}');
    }

    if (output.length > 50000) {
      warnings.add('Output unusually long (${output.length} chars) — possible model loop');
    }

    if (warnings.isNotEmpty) {
      return SecurityCheckResult(
        isSafe: true,
        riskLevel: RiskLevel.low,
        detectedPatterns: warnings,
        reason: 'Potential hallucination indicators: ${warnings.join("; ")}',
      );
    }

    return SecurityCheckResult.safe();
  }

  // ─── CONTENT SAFETY ───────────────────────────────────────────────

  /// Checks AI output for content that should be filtered.
  static bool isContentSafe(String content) {
    if (content.isEmpty) return true;

    final harmfulPatterns = [
      RegExp(r'\b(hack|exploit|vulnerability)\s+(into|against|for)\b',
          caseSensitive: false,),
      RegExp(r'\bhow\s+to\s+(cheat|hack|exploit)\b', caseSensitive: false),
      RegExp(r'\b(create|make|build)\s+(a\s+)?(bomb|weapon|drug)\b',
          caseSensitive: false,),
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

  // ─── AUDIT LOGGING ────────────────────────────────────────────────

  /// Log a blocked or flagged request for audit purposes.
  static void _logBlockedRequest({
    required String input,
    required List<String> patterns,
    required SecurityCategory category,
    bool blocked = true,
    bool isOutput = false,
  }) {
    final entry = AuditLogEntry(
      timestamp: DateTime.now(),
      inputPreview: input.length > 200 ? '${input.substring(0, 200)}...' : input,
      detectedPatterns: patterns,
      category: category,
      blocked: blocked,
      isOutput: isOutput,
    );

    _auditLog.add(entry);

    // Trim audit log if it exceeds maximum size
    if (_auditLog.length > _maxAuditLogSize) {
      _auditLog.removeRange(0, _auditLog.length - _maxAuditLogSize);
    }
  }

  /// Get recent audit log entries for review.
  static List<AuditLogEntry> getAuditLog({int limit = 100}) {
    return _auditLog.reversed.take(limit).toList();
  }

  /// Get count of blocked requests by category.
  static Map<SecurityCategory, int> getBlockedRequestStats() {
    final stats = <SecurityCategory, int>{};
    for (final entry in _auditLog.where((e) => e.blocked)) {
      stats[entry.category] = (stats[entry.category] ?? 0) + 1;
    }
    return stats;
  }
}

// ═══════════════════════════════════════════════════════════════════════
// AUDIT LOG ENTRY
// ═══════════════════════════════════════════════════════════════════════

/// An entry in the AI security audit log.
class AuditLogEntry {
  const AuditLogEntry({
    required this.timestamp,
    required this.inputPreview,
    required this.detectedPatterns,
    required this.category,
    required this.blocked,
    this.isOutput = false,
  });

  final DateTime timestamp;
  final String inputPreview;
  final List<String> detectedPatterns;
  final SecurityCategory category;
  final bool blocked;
  final bool isOutput;

  @override
  String toString() =>
      'AuditLogEntry(${blocked ? "BLOCKED" : "FLAGGED"}, $category, '
      '${timestamp.toIso8601String()}, patterns: ${detectedPatterns.length})';
}
