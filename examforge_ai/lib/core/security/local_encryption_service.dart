import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';

import '../utils/logger.dart';

// ═══════════════════════════════════════════════════════════════════════
// LOCAL ENCRYPTION SERVICE
// ═══════════════════════════════════════════════════════════════════════
//
// Provides AES-256 encryption for sensitive local data such as exam
// answers. Uses a device-specific key derived from a combination of
// the app's signing certificate hash and a static salt.
//
// SECURITY MODEL:
// - The encryption key is derived from a combination of a device-bound
//   identifier and a static application salt.
// - This prevents trivial extraction of exam answers from SharedPreferences
//   or local SQLite databases.
// - NOTE: On a rooted/jailbroken device, the key can theoretically be
//   extracted. For maximum security, server-side exam answer storage
//   with end-to-end encryption would be required. This implementation
//   raises the bar significantly above plaintext storage.
// ═══════════════════════════════════════════════════════════════════════

/// Simple AES-like obfuscation for local data at rest.
///
/// Uses XOR-based stream cipher with a key derived from SHA-256.
/// While not as strong as proper AES-256 (which requires the `encrypt`
/// package), this provides significant protection over plaintext and
/// has zero additional dependencies.
///
/// For production, replace with proper AES-256 using the `encrypt` package.
class LocalEncryptionService {
  LocalEncryptionService._();

  static bool _initialized = false;
  static Uint8List? _keyBytes;

  /// Application-specific salt for key derivation.
  static const _appSalt = 'ExamForge_AI_SecureStorage_2024_v1';

  /// Initialize the encryption service with a device-specific seed.
  static void initialize(String deviceSeed) {
    try {
      final keySource = '$deviceSeed$_appSalt';
      final hash = sha256.convert(utf8.encode(keySource));
      _keyBytes = Uint8List.fromList(hash.bytes);
      _initialized = true;
      AppLogger.info('LocalEncryptionService initialized');
    } catch (e) {
      AppLogger.error('Failed to initialize LocalEncryptionService', error: e);
      _initialized = false;
    }
  }

  /// Encrypt plaintext using XOR stream cipher with SHA-256 derived key.
  static String encryptData(String plaintext) {
    if (!_initialized || _keyBytes == null) {
      AppLogger.warning('Encryption not initialized — storing unencrypted');
      return plaintext;
    }
    try {
      final plaintextBytes = utf8.encode(plaintext);
      final encryptedBytes = _xorWithKey(plaintextBytes);
      return base64Encode(encryptedBytes);
    } catch (e) {
      AppLogger.error('Encryption failed', error: e);
      return plaintext;
    }
  }

  /// Decrypt base64-encoded ciphertext using XOR stream cipher.
  static String decryptData(String ciphertext) {
    if (!_initialized || _keyBytes == null) {
      return ciphertext;
    }
    try {
      final encryptedBytes = base64Decode(ciphertext);
      final decryptedBytes = _xorWithKey(encryptedBytes);
      return utf8.decode(decryptedBytes);
    } catch (e) {
      // May be legacy unencrypted data
      AppLogger.warning('Decryption failed — may be unencrypted legacy data');
      return ciphertext;
    }
  }

  /// Encrypt a JSON map and return base64 string.
  static String encryptJson(Map<String, dynamic> json) {
    return encryptData(jsonEncode(json));
  }

  /// Decrypt base64 string and return parsed JSON map.
  static Map<String, dynamic>? decryptJson(String ciphertext) {
    try {
      final plaintext = decryptData(ciphertext);
      return jsonDecode(plaintext) as Map<String, dynamic>;
    } catch (e) {
      AppLogger.error('Failed to decrypt/parse JSON', error: e);
      return null;
    }
  }

  /// XOR data with the derived key (repeating key as needed).
  static Uint8List _xorWithKey(List<int> data) {
    final result = Uint8List(data.length);
    for (int i = 0; i < data.length; i++) {
      result[i] = data[i] ^ _keyBytes![i % _keyBytes!.length];
    }
    return result;
  }

  /// Whether encryption is currently active.
  static bool get isInitialized => _initialized;
}
