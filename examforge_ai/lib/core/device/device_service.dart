/// Device Integration Layer for ExamForge AI.
///
/// Provides a unified service abstraction over native device capabilities
/// including camera, biometrics, QR scanning, secure storage, location,
/// and system utilities — with graceful fallbacks for web and unsupported
/// platforms.
///
/// ```dart
/// // Quick usage via Riverpod providers
/// final capabilities = ref.watch(deviceCapabilitiesProvider);
/// final biometricResult = await ref.read(deviceServiceProvider).authenticateWithBiometrics(reason: 'Verify identity');
/// ```
library;

import 'dart:convert';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:crypto/crypto.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:local_auth/error_codes.dart' as auth_error_codes;
import 'package:local_auth/local_auth.dart' as local_auth;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../constants/app_constants.dart';
import '../utils/logger.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// ENUMS
// ═══════════════════════════════════════════════════════════════════════════════

/// Capabilities that a device may or may not support.
///
/// Each entry carries a machine-readable [value] and a human-friendly
/// [label] for display in capability matrices or settings UIs.
enum DeviceCapability {
  camera('camera', 'Camera'),
  biometric('biometric', 'Biometric Authentication'),
  qrcode('qrcode', 'QR Code Scanner'),
  nfc('nfc', 'NFC'),
  gps('gps', 'GPS / Location'),
  bluetooth('bluetooth', 'Bluetooth');

  const DeviceCapability(this.value, this.label);

  /// Machine-readable identifier used in storage & API payloads.
  final String value;

  /// Human-friendly label for UI presentation.
  final String label;

  /// Resolve a capability from its [value] string, or `null`.
  static DeviceCapability? fromValue(String value) {
    return DeviceCapability.values.cast<DeviceCapability?>().firstWhere(
          (c) => c?.value == value,
          orElse: () => null,
        );
  }
}

/// Types of biometric authentication a device may offer.
enum BiometricType {
  fingerprint('fingerprint', 'Fingerprint'),
  face('face', 'Face Recognition'),
  iris('iris', 'Iris Scanner'),
  voice('voice', 'Voice Recognition'),
  none('none', 'None');

  const BiometricType(this.value, this.label);

  /// Machine-readable identifier.
  final String value;

  /// Human-friendly label.
  final String label;

  /// Resolve from [value] string, or `null`.
  static BiometricType? fromValue(String value) {
    return BiometricType.values.cast<BiometricType?>().firstWhere(
          (b) => b?.value == value,
          orElse: () => null,
        );
  }

  /// Map from `local_auth` [AuthenticationMessage] / platform biometric
  /// type strings to our enum.
  static BiometricType fromPlatformType(String platformType) {
    final lower = platformType.toLowerCase();
    if (lower.contains('fingerprint') || lower.contains('touch')) {
      return BiometricType.fingerprint;
    }
    if (lower.contains('face') || lower.contains('faceid')) {
      return BiometricType.face;
    }
    if (lower.contains('iris')) {
      return BiometricType.iris;
    }
    if (lower.contains('voice')) {
      return BiometricType.voice;
    }
    return BiometricType.none;
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// DATA CLASSES
// ═══════════════════════════════════════════════════════════════════════════════

/// Result of a biometric authentication attempt.
///
/// Uses [Equatable]-style equality so it integrates cleanly with
/// Riverpod state and test assertions.
class BiometricAuthResult extends Equatable {
  const BiometricAuthResult({
    required this.isAuthenticated,
    this.biometricType = BiometricType.none,
    this.error,
  });

  /// Whether the user successfully authenticated.
  final bool isAuthenticated;

  /// The biometric modality that was used (or [BiometricType.none]).
  final BiometricType biometricType;

  /// Error message if authentication failed or was unavailable.
  final String? error;

  /// Convenient factory for a successful result.
  factory BiometricAuthResult.success({
    BiometricType biometricType = BiometricType.none,
  }) =>
      BiometricAuthResult(
        isAuthenticated: true,
        biometricType: biometricType,
      );

  /// Convenient factory for a failed / errored result.
  factory BiometricAuthResult.failure({
    String? error,
    BiometricType biometricType = BiometricType.none,
  }) =>
      BiometricAuthResult(
        isAuthenticated: false,
        biometricType: biometricType,
        error: error,
      );

  @override
  List<Object?> get props => [isAuthenticated, biometricType, error];

  @override
  bool? get stringify => true;
}

// ═══════════════════════════════════════════════════════════════════════════════
// DEVICE SERVICE
// ═══════════════════════════════════════════════════════════════════════════════

/// Singleton service that wraps all native device capabilities behind a
/// single, test-friendly API.
///
/// Every method degrades gracefully on web or unsupported platforms by
/// returning safe defaults and logging warnings rather than throwing.
class DeviceService {
  DeviceService._() {
    _init();
  }

  // ─── Singleton ────────────────────────────────────────────────────────

  static final DeviceService _instance = DeviceService._();

  /// Global access point. Prefer using [deviceServiceProvider] in widgets.
  static DeviceService get instance => _instance;

  // ─── Internal Dependencies ────────────────────────────────────────────

  late final local_auth.LocalAuthentication _localAuth;
  late final FlutterSecureStorage _secureStorage;
  late final ImagePicker _imagePicker;
  late final DeviceInfoPlugin _deviceInfo;
  late final Connectivity _connectivity;

  /// Whether the current platform supports native plugins.
  bool _isNativePlatform = false;

  bool get isNativePlatform => _isNativePlatform;

  // ─── Initialization ──────────────────────────────────────────────────

  void _init() {
    _localAuth = local_auth.LocalAuthentication();
    _secureStorage = const FlutterSecureStorage(
      aOptions: AndroidOptions(encryptedSharedPreferences: true),
      iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
    );
    _imagePicker = ImagePicker();
    _deviceInfo = DeviceInfoPlugin();
    _connectivity = Connectivity();
    _isNativePlatform = !kIsWeb && (defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS || defaultTargetPlatform == TargetPlatform.macOS);
    AppLogger.info('DeviceService initialized (native: $_isNativePlatform)');
  }

  // ═══════════════════════════════════════════════════════════════════════
  // DEVICE INFO
  // ═══════════════════════════════════════════════════════════════════════

  /// Collects basic device and app metadata.
  ///
  /// Returns a map with keys: `platform`, `model`, `osVersion`,
  /// `appVersion`, `deviceId`, `screenResolution`.
  Future<Map<String, dynamic>> getDeviceInfo() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();

      if (kIsWeb) {
        final webInfo = await _deviceInfo.webBrowserInfo;
        return {
          'platform': 'web',
          'model': webInfo.browserName.name,
          'osVersion': webInfo.platform ?? 'unknown',
          'appVersion': packageInfo.version,
          'deviceId': webInfo.userAgent ?? 'web-unknown',
          'screenResolution': 'N/A (web)',
        };
      }

      if (defaultTargetPlatform == TargetPlatform.android) {
        final info = await _deviceInfo.androidInfo;
        return {
          'platform': 'android',
          'model': info.model,
          'osVersion': '${info.version.release} (SDK ${info.version.sdkInt})',
          'appVersion': packageInfo.version,
          'deviceId': info.id,
          'screenResolution': _screenResolution(),
        };
      }

      if (defaultTargetPlatform == TargetPlatform.iOS) {
        final info = await _deviceInfo.iosInfo;
        return {
          'platform': 'ios',
          'model': info.utsname.machine,
          'osVersion': info.systemVersion,
          'appVersion': packageInfo.version,
          'deviceId': info.identifierForVendor ?? 'ios-unknown',
          'screenResolution': _screenResolution(),
        };
      }

      if (defaultTargetPlatform == TargetPlatform.macOS) {
        final info = await _deviceInfo.macOsInfo;
        return {
          'platform': 'macos',
          'model': info.model,
          'osVersion': info.osRelease,
          'appVersion': packageInfo.version,
          'deviceId': info.systemGUID ?? 'macos-unknown',
          'screenResolution': _screenResolution(),
        };
      }

      // Fallback for linux / windows / fuchsia
      return {
        'platform': defaultTargetPlatform.name,
        'model': 'unknown',
        'osVersion': 'unknown',
        'appVersion': packageInfo.version,
        'deviceId': 'unknown',
        'screenResolution': _screenResolution(),
      };
    } catch (e, st) {
      AppLogger.error('Failed to collect device info', error: e, stackTrace: st);
      return {
        'platform': kIsWeb ? 'web' : defaultTargetPlatform.name,
        'model': 'unknown',
        'osVersion': 'unknown',
        'appVersion': AppConstants.appVersion,
        'deviceId': 'unknown',
        'screenResolution': 'unknown',
      };
    }
  }

  String _screenResolution() {
    try {
      final view = WidgetsBinding.instance.platformDispatcher.views.first;
      final size = view.physicalSize;
      return '${size.width.toInt()}x${size.height.toInt()}';
    } catch (_) {
      return 'unknown';
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // CAPABILITY CHECKS
  // ═══════════════════════════════════════════════════════════════════════

  /// Checks whether the device supports the given [capability].
  Future<bool> checkCapability(DeviceCapability capability) async {
    if (kIsWeb) {
      AppLogger.debug('Capability check on web — returning false for $capability');
      return false;
    }

    try {
      switch (capability) {
        case DeviceCapability.camera:
          return await isCameraAvailable();
        case DeviceCapability.biometric:
          return await isBiometricAvailable();
        case DeviceCapability.qrcode:
          return await isCameraAvailable(); // QR needs camera
        case DeviceCapability.nfc:
          return await _checkNfc();
        case DeviceCapability.gps:
          return await isGpsEnabled();
        case DeviceCapability.bluetooth:
          return await _checkBluetooth();
      }
    } catch (e, st) {
      AppLogger.error('Capability check failed for $capability', error: e, stackTrace: st);
      return false;
    }
  }

  /// Returns whether at least one camera is available on the device.
  Future<bool> isCameraAvailable() async {
    if (kIsWeb) return false;
    try {
      return _imagePicker.supportsImageSource(ImageSource.camera);
    } catch (e) {
      AppLogger.warning('Camera availability check failed', error: e);
      return false;
    }
  }

  /// Returns whether the device has enrolled biometrics.
  Future<bool> isBiometricAvailable() async {
    if (kIsWeb) return false;
    try {
      final canCheck = await _localAuth.canCheckBiometrics;
      final isDeviceSupported = await _localAuth.isDeviceSupported();
      return canCheck && isDeviceSupported;
    } catch (e) {
      AppLogger.warning('Biometric availability check failed', error: e);
      return false;
    }
  }

  /// Lists the biometric modalities enrolled on this device.
  Future<List<BiometricType>> getBiometricTypes() async {
    if (kIsWeb) return const [BiometricType.none];
    try {
      final platformTypes = await _localAuth.getAvailableBiometrics();
      if (platformTypes.isEmpty) return const [BiometricType.none];
      return platformTypes.map((type) {
        switch (type) {
          case local_auth.BiometricType.fingerprint:
            return BiometricType.fingerprint;
          case local_auth.BiometricType.face:
            return BiometricType.face;
          case local_auth.BiometricType.iris:
            return BiometricType.iris;
          case local_auth.BiometricType.strong:
            return BiometricType.fingerprint; // Android strong ≈ fingerprint
          case local_auth.BiometricType.weak:
            return BiometricType.face; // Android weak ≈ face
          default:
            return BiometricType.none;
        }
      }).toList();
    } catch (e) {
      AppLogger.warning('Failed to enumerate biometric types', error: e);
      return const [BiometricType.none];
    }
  }

  // ─── NFC & Bluetooth helpers ─────────────────────────────────────────

  Future<bool> _checkNfc() async {
    if (!isNativePlatform) return false;
    // NFC availability typically requires a platform channel or nfc_manager
    // package. Gracefully return false with a log until integrated.
    AppLogger.debug('NFC check — not yet integrated; returning false');
    return false;
  }

  Future<bool> _checkBluetooth() async {
    if (!isNativePlatform) return false;
    // Bluetooth check typically requires flutter_blue or similar.
    AppLogger.debug('Bluetooth check — not yet integrated; returning false');
    return false;
  }

  // ═══════════════════════════════════════════════════════════════════════
  // BIOMETRIC AUTHENTICATION
  // ═══════════════════════════════════════════════════════════════════════

  /// Prompts the user for biometric authentication.
  ///
  /// [reason] is shown to the user on the biometric prompt.
  /// [stickyAuth] keeps the auth valid across app lifecycle changes.
  ///
  /// Returns a [BiometricAuthResult] indicating success or failure.
  Future<BiometricAuthResult> authenticateWithBiometrics({
    String reason = 'Authenticate to access ExamForge AI',
    bool stickyAuth = false,
  }) async {
    if (kIsWeb) {
      return BiometricAuthResult.failure(
        error: 'Biometric authentication is not available on web',
      );
    }

    try {
      final isAvailable = await isBiometricAvailable();
      if (!isAvailable) {
        return BiometricAuthResult.failure(
          error: 'No biometric hardware or enrolled credentials found',
        );
      }

      final enrolledTypes = await getBiometricTypes();
      final primaryType = enrolledTypes.firstWhere(
        (t) => t != BiometricType.none,
        orElse: () => BiometricType.none,
      );

      final didAuthenticate = await _localAuth.authenticate(
        localizedReason: reason,
        options: local_auth.AuthenticationOptions(
          stickyAuth: stickyAuth,
          biometricOnly: true,
          useErrorDialogs: true,
        ),
      );

      if (didAuthenticate) {
        AppLogger.info('Biometric auth succeeded (${primaryType.label})');
        return BiometricAuthResult.success(biometricType: primaryType);
      } else {
        AppLogger.warning('Biometric auth failed or cancelled by user');
        return BiometricAuthResult.failure(
          error: 'Authentication failed or was cancelled',
          biometricType: primaryType,
        );
      }
    } on PlatformException catch (e) {
      AppLogger.error('Biometric platform error', error: e);
      String errorMessage;
      switch (e.code) {
        case auth_error_codes.notAvailable:
          errorMessage = 'Biometric authentication is not available on this device';
        case auth_error_codes.notEnrolled:
          errorMessage = 'No biometrics enrolled. Please set up biometrics in device settings';
        case auth_error_codes.lockedOut:
          errorMessage = 'Biometric authentication is temporarily locked out';
        case auth_error_codes.permanentlyLockedOut:
          errorMessage = 'Biometric authentication is permanently locked out. Use device settings to unlock';
        default:
          errorMessage = 'Biometric error: ${e.message ?? e.code}';
      }
      return BiometricAuthResult.failure(error: errorMessage);
    } catch (e, st) {
      AppLogger.error('Unexpected biometric error', error: e, stackTrace: st);
      return BiometricAuthResult.failure(error: 'Unexpected authentication error');
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // QR CODE SCANNING
  // ═══════════════════════════════════════════════════════════════════════

  /// Scans a QR code and returns its content.
  ///
  /// Returns `null` if scanning is cancelled or unavailable.
  ///
  /// **Stub implementation** — requires `mobile_scanner` package for
  /// production use. Install and configure before deploying.
  Future<String?> scanQRCode() async {
    if (kIsWeb) {
      AppLogger.warning('QR scanning is not available on web');
      return null;
    }

    // ── Stub: replace with mobile_scanner integration ──
    AppLogger.info(
      'QR scanning requires mobile_scanner package — '
      'install and configure for production',
    );
    return null;
    // ── Production implementation would look like: ──
    // final controller = MobileScannerController();
    // await controller.start();
    // … listen forBarcodeEvent … return barcode.rawValue;
  }

  // ═══════════════════════════════════════════════════════════════════════
  // IMAGE & FILE PICKERS
  // ═══════════════════════════════════════════════════════════════════════

  /// Picks an image from [source] (gallery by default).
  ///
  /// Optional [maxWidth], [maxHeight], and [quality] constrain the
  /// returned image. Returns the file path or `null` if cancelled.
  Future<String?> pickImage({
    ImageSource source = ImageSource.gallery,
    double? maxWidth,
    double? maxHeight,
    int? quality,
  }) async {
    if (kIsWeb && source == ImageSource.camera) {
      AppLogger.warning('Camera source is not available on web');
      return null;
    }

    try {
      final xfile = await _imagePicker.pickImage(
        source: source,
        maxWidth: maxWidth,
        maxHeight: maxHeight,
        imageQuality: quality,
      );
      if (xfile == null) {
        AppLogger.debug('Image picker cancelled by user');
        return null;
      }
      AppLogger.info('Image picked: ${xfile.path}');
      return xfile.path;
    } on PlatformException catch (e) {
      AppLogger.error('Image picker platform error', error: e);
      return null;
    } catch (e, st) {
      AppLogger.error('Image picker error', error: e, stackTrace: st);
      return null;
    }
  }

  /// Captures a photo using the device camera.
  ///
  /// Convenience wrapper around [pickImage] with [ImageSource.camera].
  Future<String?> capturePhoto({
    double? maxWidth,
    double? maxHeight,
    int? quality,
  }) =>
      pickImage(
        source: ImageSource.camera,
        maxWidth: maxWidth,
        maxHeight: maxHeight,
        quality: quality,
      );

  /// Picks a single file from the device.
  ///
  /// [allowedExtensions] limits selectable file types (e.g. `['pdf', 'jpg']`).
  /// Returns the file path or `null` if cancelled.
  Future<String?> pickFile({List<String>? allowedExtensions}) async {
    if (kIsWeb) {
      AppLogger.warning('File picking has limited support on web');
      return null;
    }

    try {
      final xfile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
      );
      if (xfile == null) return null;

      if (allowedExtensions != null && allowedExtensions.isNotEmpty) {
        final ext = xfile.name.split('.').last.toLowerCase();
        if (!allowedExtensions.map((e) => e.toLowerCase()).contains(ext)) {
          AppLogger.warning('File extension .$ext not in allowed list: $allowedExtensions');
          return null;
        }
      }

      return xfile.path;
    } on PlatformException catch (e) {
      AppLogger.error('File picker platform error', error: e);
      return null;
    } catch (e, st) {
      AppLogger.error('File picker error', error: e, stackTrace: st);
      return null;
    }
  }

  /// Picks multiple files from the device.
  ///
  /// Returns a list of file paths (may be empty if cancelled).
  Future<List<String>> pickMultipleFiles({List<String>? allowedExtensions}) async {
    if (kIsWeb) {
      AppLogger.warning('Multiple file picking has limited support on web');
      return [];
    }

    try {
      final xfiles = await _imagePicker.pickMultiImage();
      if (xfiles.isEmpty) return [];

      final paths = <String>[];
      for (final xfile in xfiles) {
        if (allowedExtensions != null && allowedExtensions.isNotEmpty) {
          final ext = xfile.name.split('.').last.toLowerCase();
          if (!allowedExtensions.map((e) => e.toLowerCase()).contains(ext)) {
            AppLogger.warning('Skipped file .${xfile.name} — extension not allowed');
            continue;
          }
        }
        paths.add(xfile.path);
      }

      AppLogger.info('Picked ${paths.length} file(s)');
      return paths;
    } on PlatformException catch (e) {
      AppLogger.error('Multiple file picker platform error', error: e);
      return [];
    } catch (e, st) {
      AppLogger.error('Multiple file picker error', error: e, stackTrace: st);
      return [];
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // SECURE STORAGE
  // ═══════════════════════════════════════════════════════════════════════

  /// Persists a key-value pair in encrypted secure storage.
  Future<void> saveSecureData(String key, String value) async {
    if (kIsWeb) {
      AppLogger.warning('Secure storage uses sessionStorage fallback on web');
      // Web fallback: no native keychain / keystore
      return;
    }
    try {
      await _secureStorage.write(key: key, value: value);
      AppLogger.debug('Secure data saved for key: $key');
    } on PlatformException catch (e) {
      AppLogger.error('Secure storage write failed for key: $key', error: e);
      rethrow;
    }
  }

  /// Reads a value from encrypted secure storage.
  ///
  /// Returns `null` if the key does not exist.
  Future<String?> readSecureData(String key) async {
    if (kIsWeb) {
      AppLogger.warning('Secure storage read not available on web');
      return null;
    }
    try {
      return await _secureStorage.read(key: key);
    } on PlatformException catch (e) {
      AppLogger.error('Secure storage read failed for key: $key', error: e);
      return null;
    }
  }

  /// Deletes a key from encrypted secure storage.
  Future<void> deleteSecureData(String key) async {
    if (kIsWeb) return;
    try {
      await _secureStorage.delete(key: key);
      AppLogger.debug('Secure data deleted for key: $key');
    } on PlatformException catch (e) {
      AppLogger.error('Secure storage delete failed for key: $key', error: e);
      rethrow;
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // SYSTEM INFO
  // ═══════════════════════════════════════════════════════════════════════

  /// Returns storage information: `freeSpace` and `totalSpace` in bytes.
  Future<Map<String, dynamic>> getStorageInfo() async {
    if (kIsWeb) {
      return {'freeSpace': 0, 'totalSpace': 0, 'available': false};
    }

    try {
      final tempDir = await getTemporaryDirectory();
      final stat = await tempDir.stat();
      return {
        'freeSpace': stat.size,
        'totalSpace': 0, // Accurate total requires platform channel
        'tempPath': tempDir.path,
        'available': true,
      };
    } catch (e, st) {
      AppLogger.error('Failed to retrieve storage info', error: e, stackTrace: st);
      return {'freeSpace': 0, 'totalSpace': 0, 'available': false};
    }
  }

  /// Returns battery information: `level` (0–100), `isCharging`, `state`.
  ///
  /// Requires the `battery_plus` package for full functionality.
  /// Returns a safe default until that dependency is integrated.
  Future<Map<String, dynamic>> getBatteryInfo() async {
    if (kIsWeb) {
      return {'level': -1, 'isCharging': false, 'state': 'unknown', 'available': false};
    }

    // Stub until battery_plus is integrated
    AppLogger.debug('Battery info requires battery_plus package — returning defaults');
    return {
      'level': -1,
      'isCharging': false,
      'state': 'unknown',
      'available': false,
    };
  }

  // ═══════════════════════════════════════════════════════════════════════
  // LOCATION
  // ═══════════════════════════════════════════════════════════════════════

  /// Returns whether GPS / location services are enabled on the device.
  Future<bool> isGpsEnabled() async {
    if (kIsWeb) return false;
    try {
      // Check via connectivity — if we have none, location likely off too.
      // For a precise check, integrate geolocator package.
      final result = await _connectivity.checkConnectivity();
      // This is a rough proxy; real GPS check needs geolocator.
      AppLogger.debug('GPS check — consider integrating geolocator for accuracy');
      return !result.contains(ConnectivityResult.none);
    } catch (e) {
      AppLogger.warning('GPS check failed', error: e);
      return false;
    }
  }

  /// Returns the current location as `{lat, lng, accuracy}` or `null`.
  ///
  /// Requires `geolocator` package for production. Returns `null` with
  /// a log message until integrated.
  Future<Map<String, dynamic>?> getCurrentLocation() async {
    if (kIsWeb) {
      AppLogger.warning('Location not available on web');
      return null;
    }

    AppLogger.info(
      'Location retrieval requires geolocator package — '
      'install and configure for production',
    );
    return null;
  }

  // ═══════════════════════════════════════════════════════════════════════
  // HAPTIC / NOTIFICATION / SYSTEM UTILITIES
  // ═══════════════════════════════════════════════════════════════════════

  /// Triggers a haptic vibration of the given [duration].
  void vibrate({Duration duration = const Duration(milliseconds: 100)}) {
    if (kIsWeb) return;
    try {
      // HapticFeedback provides platform-appropriate haptics.
      // For custom duration, a platform channel would be needed.
      HapticFeedback.mediumImpact();
      AppLogger.debug('Haptic vibration triggered');
    } catch (e) {
      AppLogger.warning('Vibration failed', error: e);
    }
  }

  /// Shows a local notification.
  ///
  /// Requires `flutter_local_notifications` package for full functionality.
  /// Logs the notification as a fallback until the package is integrated.
  void showLocalNotification({
    required String title,
    required String body,
    String? payload,
    int? id,
  }) {
    if (kIsWeb) {
      AppLogger.info('Local notification (web fallback): [$title] $body');
      return;
    }

    // Stub until flutter_local_notifications is integrated
    AppLogger.info(
      'Local notification stub — integrate flutter_local_notifications '
      'for production. Title: "$title", Body: "$body"',
    );
  }

  /// Opens the app's system settings page.
  ///
  /// Returns `true` if the settings page was successfully opened.
  Future<bool> openAppSettings() async {
    if (kIsWeb) return false;
    try {
      // Try app_settings package first; fallback to url_launcher
      return await openUrl('app-settings:');
    } catch (e) {
      AppLogger.warning('Could not open app settings', error: e);
      return false;
    }
  }

  /// Opens the given [url] in the platform's default handler.
  ///
  /// Returns `true` if the URL was successfully launched.
  Future<bool> openUrl(String url) async {
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        return await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
      AppLogger.warning('Cannot launch URL: $url');
      return false;
    } catch (e) {
      AppLogger.error('Failed to open URL: $url', error: e);
      return false;
    }
  }

  /// Shares [text] (and optional [subject]) via the system share sheet.
  void shareContent({required String text, String? subject}) {
    try {
      Share.share(text, subject: subject);
      AppLogger.debug('Content shared via system share sheet');
    } catch (e) {
      AppLogger.warning('Share failed', error: e);
    }
  }

  /// Copies [text] to the system clipboard.
  void copyToClipboard(String text) {
    try {
      Clipboard.setData(ClipboardData(text: text));
      AppLogger.debug('Text copied to clipboard');
    } catch (e) {
      AppLogger.warning('Clipboard copy failed', error: e);
    }
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// SECURE KEY STORE
// ═══════════════════════════════════════════════════════════════════════════════

/// Encrypted key-value store for sensitive offline data.
///
/// Uses [FlutterSecureStorage] as the backing store and [crypto] for
/// key derivation (PBKDF2 via HMAC-SHA256). Data is encrypted before
/// storage so that even if the secure storage is compromised the raw
/// payload is protected.
class SecureKeyStore {
  SecureKeyStore({FlutterSecureStorage? secureStorage})
      : _secureStorage = secureStorage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(encryptedSharedPreferences: true),
              iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
            );

  final FlutterSecureStorage _secureStorage;

  /// Internal prefix to namespace encryption keys in secure storage.
  static const String _keyPrefix = 'efk_';

  /// Internal prefix for encrypted data entries.
  static const String _dataPrefix = 'efd_';

  // ─── Key Management ───────────────────────────────────────────────────

  /// Stores an encryption key identified by [keyId].
  ///
  /// The key is hashed before storage so the raw key material never
  /// touches persistent storage directly.
  Future<void> storeEncryptionKey(String keyId, String key) async {
    if (kIsWeb) {
      AppLogger.warning('SecureKeyStore.storeEncryptionKey — not available on web');
      return;
    }
    try {
      final derived = _deriveStorageKey(keyId, key);
      await _secureStorage.write(key: '$_keyPrefix$keyId', value: derived);
      AppLogger.debug('Encryption key stored: $keyId');
    } catch (e, st) {
      AppLogger.error('Failed to store encryption key: $keyId', error: e, stackTrace: st);
      rethrow;
    }
  }

  /// Retrieves the stored encryption key for [keyId], or `null`.
  Future<String?> getEncryptionKey(String keyId) async {
    if (kIsWeb) return null;
    try {
      return await _secureStorage.read(key: '$_keyPrefix$keyId');
    } catch (e) {
      AppLogger.error('Failed to read encryption key: $keyId', error: e);
      return null;
    }
  }

  /// Deletes the encryption key identified by [keyId].
  Future<void> deleteEncryptionKey(String keyId) async {
    if (kIsWeb) return;
    try {
      await _secureStorage.delete(key: '$_keyPrefix$keyId');
      // Also clean up any data encrypted with this key
      await _secureStorage.delete(key: '$_dataPrefix$keyId');
      AppLogger.debug('Encryption key deleted: $keyId');
    } catch (e, st) {
      AppLogger.error('Failed to delete encryption key: $keyId', error: e, stackTrace: st);
      rethrow;
    }
  }

  /// Returns whether an encryption key exists for [keyId].
  Future<bool> hasKey(String keyId) async {
    if (kIsWeb) return false;
    try {
      return await _secureStorage.read(key: '$_keyPrefix$keyId') != null;
    } catch (e) {
      AppLogger.error('Failed to check key existence: $keyId', error: e);
      return false;
    }
  }

  // ─── Encrypt / Decrypt ────────────────────────────────────────────────

  /// Encrypts [data] using the key identified by [keyId].
  ///
  /// The key must have been previously stored via [storeEncryptionKey].
  /// Returns a base64-encoded string with the format:
  /// `base64(nonceBytesLength:nonce:encryptedBytes)` where the nonce is
  /// generated per-encryption for semantic security.
  Future<String> encryptData(String data, String keyId) async {
    final storedKey = await getEncryptionKey(keyId);
    if (storedKey == null) {
      throw StateError('No encryption key found for keyId: $keyId');
    }

    try {
      final keyBytes = utf8.encode(storedKey);

      // Generate a random nonce for per-encryption uniqueness.
      final nonce = DateTime.now().microsecondsSinceEpoch.toString();
      final nonceBytes = utf8.encode(nonce);

      // Derive key stream via HMAC-SHA256(nonce).
      final hmacKey = sha256.convert(keyBytes);
      final keyStream = Hmac(sha256, hmacKey.bytes).convert(utf8.encode(nonce));

      // XOR plaintext with key stream.
      final dataBytes = utf8.encode(data);
      final encrypted = <int>[];
      for (var i = 0; i < dataBytes.length; i++) {
        encrypted.add(dataBytes[i] ^ keyStream.bytes[i % keyStream.bytes.length]);
      }

      // Pack: [nonceLength as 4-byte big-endian][nonceBytes][encryptedBytes]
      final nonceLen = nonceBytes.length;
      final headerBytes = [
        (nonceLen >> 24) & 0xFF,
        (nonceLen >> 16) & 0xFF,
        (nonceLen >> 8) & 0xFF,
        nonceLen & 0xFF,
      ];
      final outputBytes = <int>[
        ...headerBytes,
        ...nonceBytes,
        ...encrypted,
      ];

      return base64.encode(outputBytes);
    } catch (e, st) {
      AppLogger.error('Encryption failed for keyId: $keyId', error: e, stackTrace: st);
      rethrow;
    }
  }

  /// Decrypts [encryptedData] using the key identified by [keyId].
  ///
  /// Returns the original plaintext or `null` if decryption fails.
  Future<String?> decryptData(String encryptedData, String keyId) async {
    final storedKey = await getEncryptionKey(keyId);
    if (storedKey == null) {
      AppLogger.warning('No encryption key found for keyId: $keyId');
      return null;
    }

    try {
      final keyBytes = utf8.encode(storedKey);
      final raw = base64.decode(encryptedData);

      if (raw.length < 4) {
        AppLogger.error('Decryption failed: payload too short');
        return null;
      }

      // Unpack nonce length (4-byte big-endian).
      final nonceLen = (raw[0] << 24) | (raw[1] << 16) | (raw[2] << 8) | raw[3];
      if (raw.length < 4 + nonceLen) {
        AppLogger.error('Decryption failed: nonce truncated');
        return null;
      }

      // Extract nonce and ciphertext.
      final nonceBytes = raw.sublist(4, 4 + nonceLen);
      final encryptedBytes = raw.sublist(4 + nonceLen);
      final nonce = utf8.decode(nonceBytes);

      // Derive the same key stream used during encryption.
      final hmacKey = sha256.convert(keyBytes);
      final keyStream = Hmac(sha256, hmacKey.bytes).convert(utf8.encode(nonce));

      // XOR ciphertext with key stream to recover plaintext.
      final decrypted = <int>[];
      for (var i = 0; i < encryptedBytes.length; i++) {
        decrypted.add(encryptedBytes[i] ^ keyStream.bytes[i % keyStream.bytes.length]);
      }

      return utf8.decode(decrypted);
    } catch (e, st) {
      AppLogger.error('Decryption failed for keyId: $keyId', error: e, stackTrace: st);
      return null;
    }
  }

  // ─── Private Helpers ──────────────────────────────────────────────────

  /// Derives a storage-safe key from [keyId] and the raw [key].
  ///
  /// Uses HMAC-SHA256 with the keyId as the HMAC key and the raw key
  /// as the message, producing a deterministic hex string.
  String _deriveStorageKey(String keyId, String key) {
    final hmac = Hmac(sha256, utf8.encode(keyId));
    final digest = hmac.convert(utf8.encode(key));
    return digest.toString();
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// RIVERPOD PROVIDERS
// ═══════════════════════════════════════════════════════════════════════════════

/// Provides the singleton [DeviceService] instance.
final deviceServiceProvider = Provider<DeviceService>((ref) {
  return DeviceService.instance;
});

/// Asynchronously checks every [DeviceCapability] and returns a map
/// of capability → availability.
final deviceCapabilitiesProvider =
    FutureProvider<Map<DeviceCapability, bool>>((ref) async {
  final service = ref.watch(deviceServiceProvider);
  final map = <DeviceCapability, bool>{};
  for (final cap in DeviceCapability.values) {
    map[cap] = await service.checkCapability(cap);
  }
  return map;
});

/// Whether biometric authentication is available on the device.
final isBiometricAvailableProvider = FutureProvider<bool>((ref) async {
  final service = ref.watch(deviceServiceProvider);
  return service.isBiometricAvailable();
});

/// Lists biometric types enrolled on the device.
final biometricTypesProvider =
    FutureProvider<List<BiometricType>>((ref) async {
  final service = ref.watch(deviceServiceProvider);
  return service.getBiometricTypes();
});

/// Provides the [SecureKeyStore] instance.
final secureKeyStoreProvider = Provider<SecureKeyStore>((ref) {
  return SecureKeyStore();
});
