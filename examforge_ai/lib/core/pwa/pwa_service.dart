// =============================================================================
// ExamForge AI — PWA Service
// =============================================================================
//
// Provides Progressive Web App capabilities to the Flutter application:
//   - Detect whether the app is running as an installed PWA
//   - Trigger the native browser install prompt
//   - Register and communicate with the service worker
//   - Request push notification permission and subscribe
//   - Check for service worker updates
//
// Usage:
//   final pwaService = ref.read(pwaServiceProvider);
//   if (await pwaService.isInstallable()) {
//     final installed = await pwaService.showInstallPrompt();
//   }
// =============================================================================

import 'dart:async';
import 'dart:js_interop';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:web/web.dart' as web;

import '../utils/logger.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// PWA INSTALL STATUS ENUM
// ═══════════════════════════════════════════════════════════════════════════════

/// Represents the current PWA installation state.
enum PwaInstallStatus {
  /// The app is not installed and cannot be installed (not a PWA context).
  notSupported,

  /// The app is not installed but the browser has fired the beforeinstallprompt
  /// event, meaning installation is possible.
  installable,

  /// The app is already installed and running in standalone mode.
  installed,

  /// The app is not installed and no install prompt is available.
  notInstalled,
}

// ═══════════════════════════════════════════════════════════════════════════════
// PWA SERVICE
// ═══════════════════════════════════════════════════════════════════════════════

/// Service class that encapsulates all Progressive Web App interactions.
///
/// On non-web platforms, all methods gracefully degrade to no-ops or return
/// sensible defaults (e.g. [isPwaInstalled] returns `false`).
class PwaService {
  PwaService();

  /// The captured `beforeinstallprompt` event, if the browser fired one.
  web.BeforeInstallPromptEvent? _installPromptEvent;

  /// Stream controller for install status changes.
  final StreamController<PwaInstallStatus> _installStatusController =
      StreamController<PwaInstallStatus>.broadcast();

  /// Whether we've already set up the event listeners.
  bool _initialized = false;

  // ─── Initialization ───────────────────────────────────────────────────

  /// Sets up one-time event listeners for PWA lifecycle events.
  ///
  /// Safe to call multiple times; subsequent calls are no-ops.
  void _ensureInitialized() {
    if (_initialized || !kIsWeb) return;
    _initialized = true;

    _setupBeforeInstallPromptListener();
    _setupAppInstalledListener();
  }

  /// Listens for the browser's `beforeinstallprompt` event and captures it.
  void _setupBeforeInstallPromptListener() {
    try {
      web.window.addEventListener('beforeinstallprompt', (web.Event event) {
        event.preventDefault();
        _installPromptEvent = event as web.BeforeInstallPromptEvent;
        AppLogger.info('[PWA] beforeinstallprompt captured');
        _installStatusController.add(PwaInstallStatus.installable);
      }.toJS);
    } catch (e) {
      AppLogger.warning('[PWA] Failed to set up beforeinstallprompt listener: $e');
    }
  }

  /// Listens for the browser's `appinstalled` event.
  void _setupAppInstalledListener() {
    try {
      web.window.addEventListener('appinstalled', (web.Event _) {
        AppLogger.info('[PWA] App installed');
        _installPromptEvent = null;
        _installStatusController.add(PwaInstallStatus.installed);
      }.toJS);
    } catch (e) {
      AppLogger.warning('[PWA] Failed to set up appinstalled listener: $e');
    }
  }

  // ─── Public API ───────────────────────────────────────────────────────

  /// Returns `true` if the app is currently running in standalone / PWA mode.
  ///
  /// This checks `window.matchMedia('(display-mode: standalone)')` on web.
  /// On non-web platforms, always returns `false`.
  bool isPwaInstalled() {
    if (!kIsWeb) return false;
    _ensureInitialized();

    try {
      final mediaQuery = web.window.matchMedia('(display-mode: standalone)');
      return mediaQuery.matches;
    } catch (e) {
      AppLogger.warning('[PWA] Failed to check display-mode: $e');
      return false;
    }
  }

  /// Returns `true` if the PWA can be installed on this device.
  ///
  /// This is `true` when the browser has fired `beforeinstallprompt` and we
  /// captured the event, meaning the user can be prompted to install.
  Future<bool> isInstallable() async {
    if (!kIsWeb) return false;
    _ensureInitialized();
    return _installPromptEvent != null;
  }

  /// Triggers the native browser install prompt.
  ///
  /// Returns `true` if the user accepted the installation. Returns `false`
  /// if the prompt was dismissed or could not be shown.
  Future<bool> showInstallPrompt() async {
    if (!kIsWeb || _installPromptEvent == null) return false;

    try {
      await _installPromptEvent!.prompt().toDart;
      final choice = _installPromptEvent!.userChoice;
      // The userChoice promise resolves after the prompt is dismissed.
      final result = await choice.toDart;
      final accepted = result.outcome == 'accepted';
      AppLogger.info('[PWA] Install prompt result: ${result.outcome}');
      if (accepted) {
        _installPromptEvent = null;
      }
      return accepted;
    } catch (e) {
      AppLogger.error('[PWA] Failed to show install prompt', error: e);
      return false;
    }
  }

  /// Emits the current [PwaInstallStatus] and subsequent changes.
  ///
  /// The stream emits immediately with the current status and then again
  /// whenever the status changes (e.g. user installs the app).
  Stream<PwaInstallStatus> getInstallStatus() {
    _ensureInitialized();

    // Emit the current status immediately.
    final currentStatus = _currentStatus();
    return Stream.multi((controller) {
      controller.add(currentStatus);
      final subscription = _installStatusController.stream.listen(controller.add);
      controller.onCancel = subscription.cancel;
    });
  }

  /// Registers (or re-registers) the service worker.
  ///
  /// On non-web platforms, this is a no-op.
  Future<void> registerServiceWorker() async {
    if (!kIsWeb) return;
    _ensureInitialized();

    try {
      final registration =
          await web.window.navigator.serviceWorker?.register('/sw.js').toDart;
      if (registration != null) {
        AppLogger.info('[PWA] Service Worker registered: ${registration.scope}');
      }
    } catch (e) {
      AppLogger.warning('[PWA] Service Worker registration failed: $e');
    }
  }

  /// Requests browser permission to display push notifications.
  ///
  /// Returns `true` if permission was granted.
  Future<bool> requestNotificationPermission() async {
    if (!kIsWeb) return false;

    try {
      final permission = await web.Notification.requestPermission().toDart;
      final granted = permission == web.NotificationPermission.granted;
      AppLogger.info('[PWA] Notification permission: $permission');
      return granted;
    } catch (e) {
      AppLogger.warning('[PWA] Failed to request notification permission: $e');
      return false;
    }
  }

  /// Subscribes to push notifications via the service worker's push manager.
  ///
  /// Returns the push subscription endpoint URL on success, or `null` on
  /// failure. The [serverPublicKey] must be a VAPID public key in
  /// Base64-url-safe encoding.
  Future<String?> subscribeToPushNotifications({
    required String serverPublicKey,
  }) async {
    if (!kIsWeb) return null;

    try {
      final registration = web.window.navigator.serviceWorker;
      if (registration == null) return null;

      final readyReg = await registration.ready.toDart;
      final pushManager = readyReg.pushManager;

      final subscription = await pushManager
          .subscribe(
            web.PushSubscriptionOptions(
              userVisibleOnly: true,
              applicationServerKey: serverPublicKey.toJS,
            ),
          )
          .toDart;

      AppLogger.info('[PWA] Push subscription created: ${subscription.endpoint}');
      return subscription.endpoint;
    } catch (e) {
      AppLogger.error('[PWA] Failed to subscribe to push notifications', error: e);
      return null;
    }
  }

  /// Checks whether a new service worker version is available.
  ///
  /// Returns `true` if an update was found.
  Future<bool> checkForUpdate() async {
    if (!kIsWeb) return false;

    try {
      final registration =
          await web.window.navigator.serviceWorker?.ready.toDart;
      if (registration == null) return false;

      await registration.update().toDart;
      final waiting = registration.waiting;
      if (waiting != null) {
        AppLogger.info('[PWA] New service worker version is waiting');
        return true;
      }
      return false;
    } catch (e) {
      AppLogger.warning('[PWA] Failed to check for SW update: $e');
      return false;
    }
  }

  /// Notifies the Flutter app that a service worker update is available.
  ///
  /// This dispatches a custom DOM event that the Flutter side can listen to
  /// and display an "Update available" banner.
  void notifyUpdateAvailable() {
    if (!kIsWeb) return;

    try {
      web.window.dispatchEvent(
        web.CustomEvent('examforge-update-available'),
      );
      AppLogger.info('[PWA] Update notification dispatched');
    } catch (e) {
      AppLogger.warning('[PWA] Failed to dispatch update event: $e');
    }
  }

  // ─── Private Helpers ──────────────────────────────────────────────────

  /// Computes the current install status from available signals.
  PwaInstallStatus _currentStatus() {
    if (!kIsWeb) return PwaInstallStatus.notSupported;

    if (isPwaInstalled()) return PwaInstallStatus.installed;
    if (_installPromptEvent != null) return PwaInstallStatus.installable;

    return PwaInstallStatus.notInstalled;
  }

  /// Clean up resources. Call when the service is no longer needed.
  void dispose() {
    _installStatusController.close();
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// RIVERPOD PROVIDERS
// ═══════════════════════════════════════════════════════════════════════════════

/// Singleton provider for [PwaService].
final pwaServiceProvider = Provider<PwaService>((ref) {
  final service = PwaService();
  ref.onDispose(service.dispose);
  return service;
});

/// Provider that returns `true` when the app is running as an installed PWA.
final isPwaInstalledProvider = Provider<bool>((ref) {
  final pwaService = ref.watch(pwaServiceProvider);
  return pwaService.isPwaInstalled();
});

/// Stream provider that emits the current [PwaInstallStatus] and changes.
final pwaInstallStatusProvider = StreamProvider<PwaInstallStatus>((ref) {
  final pwaService = ref.watch(pwaServiceProvider);
  return pwaService.getInstallStatus();
});
