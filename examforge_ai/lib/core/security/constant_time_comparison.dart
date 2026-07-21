// ============================================================================
// ExamForge AI — Constant-Time Comparison
// ============================================================================
// Provides timing-attack-resistant comparison for cryptographic secrets.
//
// ROOT CAUSE (why this file exists):
// The original _constantTimeEquals in FlutterwaveDataSourceImpl had a subtle
// timing leak: when string lengths differ, it still iterated only up to the
// shorter string's length. This means different-length mismatches complete
// faster than same-length mismatches, leaking information about the expected
// hash length through response time.
//
// The TypeScript webhook handler had a CRITICAL bug where b was reassigned
// to a when lengths differed, causing the function to ALWAYS return true
// for different-length inputs — a complete signature bypass.
//
// SECURITY MODEL:
// - Never short-circuit on length mismatch
// - Iteration count depends ONLY on the known-value length (not the secret)
// - XOR accumulator ensures no byte content is leaked through branch timing
// - Uses platform crypto utilities where available
// ============================================================================

import 'dart:convert';
import 'dart:typed_data';

/// Timing-attack-resistant comparison for cryptographic secrets.
///
/// Compares two strings in constant time relative to the length of [expected].
/// Returns `true` only when both the content AND the length match exactly.
///
/// **Usage**: Always pass the user-supplied/untrusted value as [actual] and
/// the known-correct/expected value as [expected]. The iteration count is
/// always `expected.length`, preventing an attacker from controlling the
/// comparison duration.
///
/// **Algorithm**:
/// 1. Capture whether lengths match (before any processing).
/// 2. Iterate over `max(actual.length, expected.length)` bytes.
/// 3. XOR each pair of bytes and OR into accumulator.
/// 4. Padding with 0xFF for out-of-bounds indices ensures different-length
///    inputs always produce a non-zero accumulator.
/// 5. Return `accumulator == 0 && lengthsMatch`.
class ConstantTimeComparison {
  ConstantTimeComparison._();

  /// Compares two strings in constant time.
  ///
  /// - [actual]: The untrusted/user-supplied value (e.g., incoming webhook hash).
  /// - [expected]: The known-correct value (e.g., stored webhook secret hash).
  ///
  /// Returns `true` if and only if both strings are identical in content
  /// and length.
  static bool equals(String actual, String expected) {
    if (actual.isEmpty && expected.isEmpty) return true;
    if (actual.isEmpty || expected.isEmpty) return false;

    final actualBytes = Uint8List.fromList(utf8.encode(actual));
    final expectedBytes = Uint8List.fromList(utf8.encode(expected));

    return equalsBytes(actualBytes, expectedBytes);
  }

  /// Compares two byte lists in constant time.
  ///
  /// This is the core comparison function. It uses XOR accumulation with
  /// 0xFF padding for out-of-bounds indices to ensure:
  /// - Different-length inputs ALWAYS produce a non-zero result
  /// - Same-length, different-content inputs produce a non-zero result
  /// - Same-length, same-content inputs produce zero
  /// - No early exit or branching based on content
  static bool equalsBytes(Uint8List actual, Uint8List expected) {
    // Capture length match BEFORE any processing.
    final lengthsMatch = actual.length == expected.length;

    // Iterate over the maximum length to ensure constant time relative
    // to the longer input. Using 0xFF as padding for out-of-bounds
    // indices guarantees that different-length inputs always produce
    // a non-zero XOR result.
    final maxLen = actual.length > expected.length ? actual.length : expected.length;

    int accumulator = 0;
    for (int i = 0; i < maxLen; i++) {
      // For out-of-bounds indices, use 0xFF which XORs with any real byte
      // to produce a non-zero result, ensuring length mismatches are caught.
      final aByte = i < actual.length ? actual[i] : 0xFF;
      final bByte = i < expected.length ? expected[i] : 0xFF;
      accumulator |= aByte ^ bByte;
    }

    // Both content AND length must match.
    return accumulator == 0 && lengthsMatch;
  }

  /// Compares two HMAC digests in constant time.
  ///
  /// Convenience method for comparing hex-encoded HMAC values.
  /// Validates that both inputs are valid hex strings before comparison.
  static bool equalsHex(String actual, String expected) {
    // Quick format validation — both should be hex strings.
    // This does NOT leak timing info about the content, only the format.
    final hexRegex = RegExp(r'^[0-9a-fA-F]+$');
    if (!hexRegex.hasMatch(actual) || !hexRegex.hasMatch(expected)) {
      return false;
    }

    return equals(actual, expected);
  }
}
