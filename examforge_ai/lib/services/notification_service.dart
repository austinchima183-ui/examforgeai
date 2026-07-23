import 'dart:async';
import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;

import '../core/errors/exceptions.dart';
import '../core/utils/logger.dart';
import 'storage_service.dart';

/// Callback type for when a notification message is received while
/// the app is in the foreground.
typedef ForegroundMessageCallback = void Function(RemoteMessage message);

/// Callback type for when a notification is tapped by the user.
typedef NotificationTapCallback = void Function(RemoteMessage message);

/// Top-level background message handler.
///
/// Must be a top-level function (not a class method or closure) so that
/// Firebase Messaging can invoke it outside the main isolate.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Initialize Firebase in the background isolate if needed.
  // Note: You must ensure Firebase is initialized before calling
  // any Firebase APIs in this handler. If you use other plugins
  // that require Firebase, initialize them here as well.
  AppLogger.info(
    'Background message received: ${message.messageId}',
  );
}

/// Comprehensive push notification service built on Firebase Cloud
/// Messaging (FCM).
///
/// Responsibilities:
/// - Request notification permissions (iOS + Android).
/// - Obtain and persist the FCM device token.
/// - Subscribe / unsubscribe to role- and school-based topics.
/// - Display local notifications for foreground messages.
/// - Handle notification taps (foreground, background, terminated).
/// - Persist the token to Supabase for server-side targeting.
///
/// ```dart
/// final service = NotificationService(supabaseClient, storageService);
/// await service.initialize();
/// ```
class NotificationService {
  NotificationService({
    required sb.SupabaseClient supabaseClient,
    required StorageService storageService,
    FirebaseMessaging? firebaseMessaging,
  })  : _supabase = supabaseClient,
        _storage = storageService,
        _messaging = firebaseMessaging ?? FirebaseMessaging.instance;

  final sb.SupabaseClient _supabase;
  final StorageService _storage;
  final FirebaseMessaging _messaging;

  // ─── State ──────────────────────────────────────────────────────

  static const String _fcmTokenKey = 'fcm_device_token';
  static const String _subscribedTopicsKey = 'fcm_subscribed_topics';

  String? _currentToken;
  ForegroundMessageCallback? _onForegroundMessage;
  NotificationTapCallback? _onNotificationTap;
  StreamSubscription<RemoteMessage>? _onMessageSubscription;
  StreamSubscription<RemoteMessage>? _onMessageOpenedAppSubscription;
  StreamSubscription<String>? _onTokenRefreshSubscription;
  final Set<String> _subscribedTopics = {};

  bool _initialized = false;

  // ─── Initialization ─────────────────────────────────────────────

  /// Initializes the notification service.
  ///
  /// Steps:
  /// 1. Requests notification permissions.
  /// 2. Obtains the FCM device token.
  /// 3. Registers background and foreground handlers.
  /// 4. Handles initial message (app opened from terminated state
  ///    via notification tap).
  /// 5. Sets up token-refresh listener.
  /// 6. Persists the token to Supabase.
  ///
  /// [onForegroundMessage] — callback invoked when a message arrives
  ///   while the app is in the foreground.
  /// [onNotificationTap] — callback invoked when the user taps a
  ///   notification that opens the app.
  Future<void> initialize({
    ForegroundMessageCallback? onForegroundMessage,
    NotificationTapCallback? onNotificationTap,
  }) async {
    if (_initialized) {
      AppLogger.warning('NotificationService already initialized — skipping.');
      return;
    }

    _onForegroundMessage = onForegroundMessage;
    _onNotificationTap = onNotificationTap;

    try {
      // 1. Request permissions.
      final permissionGranted = await _requestPermissions();
      if (!permissionGranted) {
        AppLogger.warning('Notification permissions not granted.');
        _initialized = true;
        return;
      }

      // 2. Register background handler.
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

      // 3. Get FCM token.
      await _obtainToken();

      // 4. Handle foreground messages.
      _setupForegroundHandler();

      // 5. Handle notification taps (background state).
      _setupBackgroundTapHandler();

      // 6. Handle notification taps (terminated state).
      await _handleInitialMessage();

      // 7. Listen for token refresh.
      _setupTokenRefreshListener();

      // 8. Restore previously subscribed topics.
      await _restoreSubscribedTopics();

      _initialized = true;
      AppLogger.info('NotificationService initialized successfully');
    } catch (e) {
      AppLogger.error('Failed to initialize NotificationService', error: e);
      // Mark initialized anyway so the app can continue — push
      // notifications are a non-critical feature.
      _initialized = true;
    }
  }

  // ─── Permissions ────────────────────────────────────────────────

  /// Requests notification permissions from the OS.
  ///
  /// Returns `true` if the user granted permission (or if on Android
  /// where permissions are granted by default on most API levels).
  Future<bool> _requestPermissions() async {
    try {
      if (Platform.isIOS) {
        final settings = await _messaging.requestPermission(
          alert: true,
          announcement: false,
          badge: true,
          carPlay: false,
          criticalAlert: false,
          provisional: false,
          sound: true,
        );

        final granted = settings.authorizationStatus ==
                AuthorizationStatus.authorized ||
            settings.authorizationStatus ==
                AuthorizationStatus.provisional;

        AppLogger.info(
          'iOS notification permission: ${settings.authorizationStatus.name}',
        );
        return granted;
      }

      if (Platform.isAndroid) {
        final settings = await _messaging.requestPermission();
        final granted = settings.authorizationStatus ==
                AuthorizationStatus.authorized ||
            settings.authorizationStatus ==
                AuthorizationStatus.provisional;

        AppLogger.info(
          'Android notification permission: ${settings.authorizationStatus.name}',
        );
        return granted;
      }

      // Other platforms (web, macOS, etc.) — attempt the default request.
      final settings = await _messaging.requestPermission();
      return settings.authorizationStatus == AuthorizationStatus.authorized;
    } catch (e) {
      AppLogger.error('Failed to request notification permissions', error: e);
      return false;
    }
  }

  /// Checks the current permission status without showing a dialog.
  Future<AuthorizationStatus> getPermissionStatus() async {
    try {
      final settings = await _messaging.getNotificationSettings();
      return settings.authorizationStatus;
    } catch (e) {
      AppLogger.error('Failed to check permission status', error: e);
      return AuthorizationStatus.notDetermined;
    }
  }

  // ─── Token Management ──────────────────────────────────────────

  /// Obtains the FCM device token, persists it locally, and syncs
  /// it to Supabase.
  Future<void> _obtainToken() async {
    try {
      _currentToken = await _messaging.getToken();
      if (_currentToken != null) {
        await _persistTokenLocally(_currentToken!);
        await _syncTokenToSupabase(_currentToken!);
        AppLogger.info('FCM token obtained: [REDACTED]');
      }
    } catch (e) {
      AppLogger.error('Failed to obtain FCM token', error: e);
    }
  }

  /// Returns the current FCM token, or `null` if unavailable.
  String? get currentToken => _currentToken;

  /// Deletes the current FCM token and obtains a new one.
  ///
  /// Useful when the user signs out and signs back in on a different
  /// account, or when the token becomes invalid.
  Future<String?> refreshToken() async {
    try {
      await _messaging.deleteToken();
      _currentToken = await _messaging.getToken();

      if (_currentToken != null) {
        await _persistTokenLocally(_currentToken!);
        await _syncTokenToSupabase(_currentToken!);
        AppLogger.info('FCM token refreshed');
      }

      return _currentToken;
    } catch (e) {
      AppLogger.error('Failed to refresh FCM token', error: e);
      return null;
    }
  }

  // ─── Topic Subscriptions ────────────────────────────────────────

  /// Subscribes the device to a Firebase Messaging topic.
  ///
  /// Topics are used for role-based and school-based notification
  /// targeting. The subscription is persisted so it can be restored
  /// after app restart.
  Future<void> subscribeToTopic(String topic) async {
    if (!_initialized) {
      AppLogger.warning(
          'NotificationService not initialized; cannot subscribe to topic.');
      return;
    }

    try {
      await _messaging.subscribeToTopic(topic);
      _subscribedTopics.add(topic);
      await _persistSubscribedTopics();
      AppLogger.info('Subscribed to topic: $topic');
    } catch (e) {
      AppLogger.error('Failed to subscribe to topic: $topic', error: e);
    }
  }

  /// Unsubscribes the device from a Firebase Messaging topic.
  Future<void> unsubscribeFromTopic(String topic) async {
    if (!_initialized) {
      AppLogger.warning(
          'NotificationService not initialized; cannot unsubscribe from topic.');
      return;
    }

    try {
      await _messaging.unsubscribeFromTopic(topic);
      _subscribedTopics.remove(topic);
      await _persistSubscribedTopics();
      AppLogger.info('Unsubscribed from topic: $topic');
    } catch (e) {
      AppLogger.error('Failed to unsubscribe from topic: $topic', error: e);
    }
  }

  /// Subscribes to standard role-based topics for [role].
  ///
  /// Creates topic names like `role_admin`, `role_teacher`, etc.
  Future<void> subscribeToRoleTopic(String role) async {
    await subscribeToTopic('role_$role');
  }

  /// Unsubscribes from a role-based topic.
  Future<void> unsubscribeFromRoleTopic(String role) async {
    await unsubscribeFromTopic('role_$role');
  }

  /// Subscribes to a school-specific topic.
  ///
  /// Creates topic names like `school_<schoolId>`.
  Future<void> subscribeToSchoolTopic(String schoolId) async {
    await subscribeToTopic('school_$schoolId');
  }

  /// Unsubscribes from a school-specific topic.
  Future<void> unsubscribeFromSchoolTopic(String schoolId) async {
    await unsubscribeFromTopic('school_$schoolId');
  }

  /// Unsubscribes from all currently subscribed topics.
  ///
  /// Typically called when the user signs out.
  Future<void> unsubscribeFromAllTopics() async {
    final topics = Set<String>.from(_subscribedTopics);
    for (final topic in topics) {
      await unsubscribeFromTopic(topic);
    }
    AppLogger.info('Unsubscribed from all topics');
  }

  /// Returns an unmodifiable set of currently subscribed topics.
  Set<String> get subscribedTopics => Set.unmodifiable(_subscribedTopics);

  // ─── Foreground Message Handling ────────────────────────────────

  void _setupForegroundHandler() {
    _onMessageSubscription = FirebaseMessaging.onMessage.listen(
      (RemoteMessage message) {
        AppLogger.info(
          'Foreground message received: ${message.messageId}',
        );

        // Invoke the user-supplied callback.
        _onForegroundMessage?.call(message);

        // Display a local notification for the message so the user
        // can see it even when the app is in the foreground.
        _displayLocalNotification(message);
      },
      onError: (e) {
        AppLogger.error('Foreground message stream error', error: e);
      },
    );
  }

  // ─── Background Tap Handling ────────────────────────────────────

  void _setupBackgroundTapHandler() {
    _onMessageOpenedAppSubscription =
        FirebaseMessaging.onMessageOpenedApp.listen(
      (RemoteMessage message) {
        AppLogger.info(
          'Notification tap (background): ${message.messageId}',
        );
        _onNotificationTap?.call(message);
      },
      onError: (e) {
        AppLogger.error('onMessageOpenedApp stream error', error: e);
      },
    );
  }

  // ─── Terminated State Tap Handling ──────────────────────────────

  /// Handles the case where the app was in the terminated state when
  /// the user tapped the notification.
  Future<void> _handleInitialMessage() async {
    try {
      final initialMessage = await _messaging.getInitialMessage();
      if (initialMessage != null) {
        AppLogger.info(
          'Notification tap (terminated): ${initialMessage.messageId}',
        );
        _onNotificationTap?.call(initialMessage);
      }
    } catch (e) {
      AppLogger.error('Failed to get initial message', error: e);
    }
  }

  // ─── Local Notification Display ─────────────────────────────────

  /// Displays a local notification for a foreground [RemoteMessage].
  ///
  /// In production, this should use `flutter_local_notifications`
  /// for rich notifications (images, actions). For now, we log
  /// the notification data so it can be wired up later.
  void _displayLocalNotification(RemoteMessage message) {
    final notification = message.notification;
    if (notification == null) return;

    final title = notification.title ?? 'ExamForge AI';
    final body = notification.body ?? '';

    AppLogger.info('Local notification — title: $title, body: $body');

    // TODO: Integrate flutter_local_notifications for actual heads-up
    // notification display on Android and iOS. The package provides
    // platform-specific channel configuration, custom sounds, and
    // notification actions. For now, the foreground callback and
    // logging are sufficient for development.
  }

  // ─── Token Refresh Listener ─────────────────────────────────────

  void _setupTokenRefreshListener() {
    _onTokenRefreshSubscription = _messaging.onTokenRefresh.listen(
      (String newToken) async {
        AppLogger.info('FCM token refreshed');
        _currentToken = newToken;
        await _persistTokenLocally(newToken);
        await _syncTokenToSupabase(newToken);
      },
      onError: (e) {
        AppLogger.error('FCM token refresh error', error: e);
      },
    );
  }

  // ─── Supabase Token Sync ────────────────────────────────────────

  /// Persists the FCM token to the `device_tokens` table in Supabase
  /// so that the server can target this specific device.
  Future<void> _syncTokenToSupabase(String token) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        AppLogger.warning('Cannot sync FCM token — no authenticated user.');
        return;
      }

      await _supabase.from('device_tokens').upsert(
            {
              'user_id': userId,
              'fcm_token': token,
              'platform': Platform.operatingSystem,
              'updated_at': DateTime.now().toIso8601String(),
            },
            onConflict: 'user_id,fcm_token',
          );

      AppLogger.info('FCM token synced to Supabase');
    } on sb.PostgrestException catch (e) {
      AppLogger.error('Supabase FCM token sync failed', error: e);
    } catch (e) {
      AppLogger.error('Unexpected FCM token sync error', error: e);
    }
  }

  /// Removes the FCM token from Supabase (e.g. on logout).
  Future<void> removeTokenFromSupabase() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null || _currentToken == null) return;

      await _supabase
          .from('device_tokens')
          .delete()
          .eq('user_id', userId)
          .eq('fcm_token', _currentToken!);

      AppLogger.info('FCM token removed from Supabase');
    } on sb.PostgrestException catch (e) {
      AppLogger.error('Failed to remove FCM token from Supabase', error: e);
    } catch (e) {
      AppLogger.error('Unexpected error removing FCM token', error: e);
    }
  }

  // ─── Local Persistence ──────────────────────────────────────────

  Future<void> _persistTokenLocally(String token) async {
    try {
      await _storage.writeSecure(_fcmTokenKey, token);
    } catch (e) {
      AppLogger.error('Failed to persist FCM token locally', error: e);
    }
  }

  Future<String?> _readPersistedToken() async {
    try {
      return await _storage.readSecure(_fcmTokenKey);
    } catch (e) {
      AppLogger.error('Failed to read persisted FCM token', error: e);
      return null;
    }
  }

  Future<void> _persistSubscribedTopics() async {
    try {
      final topicsList = _subscribedTopics.join(',');
      await _storage.writePreference(_subscribedTopicsKey, topicsList);
    } catch (e) {
      AppLogger.error('Failed to persist subscribed topics', error: e);
    }
  }

  Future<void> _restoreSubscribedTopics() async {
    try {
      final topicsString = await _storage.readPreference(_subscribedTopicsKey);
      if (topicsString == null || topicsString.isEmpty) return;

      final topics = topicsString.split(',');
      for (final topic in topics) {
        final trimmed = topic.trim();
        if (trimmed.isNotEmpty) {
          _subscribedTopics.add(trimmed);
          // Re-subscribe in case the subscription was lost.
          try {
            await _messaging.subscribeToTopic(trimmed);
          } catch (e) {
            AppLogger.warning(
                'Failed to re-subscribe to topic: $trimmed', error: e);
          }
        }
      }

      AppLogger.info(
          'Restored ${_subscribedTopics.length} topic subscriptions');
    } catch (e) {
      AppLogger.error('Failed to restore subscribed topics', error: e);
    }
  }

  // ─── Cleanup ────────────────────────────────────────────────────

  /// Disposes all stream subscriptions. Call when the service is no
  /// longer needed (e.g. during app lifecycle teardown).
  void dispose() {
    _onMessageSubscription?.cancel();
    _onMessageOpenedAppSubscription?.cancel();
    _onTokenRefreshSubscription?.cancel();
    AppLogger.info('NotificationService disposed');
  }

  /// Full cleanup for sign-out: removes the token from Supabase,
  /// unsubscribes from all topics, and cancels stream subscriptions.
  Future<void> handleSignOut() async {
    try {
      await removeTokenFromSupabase();
      await unsubscribeFromAllTopics();
      await _storage.writeSecure(_fcmTokenKey, '');
      await _storage.writePreference(_subscribedTopicsKey, '');
      _currentToken = null;
      dispose();
      AppLogger.info('NotificationService cleaned up for sign-out');
    } catch (e) {
      AppLogger.error('Error during notification sign-out cleanup', error: e);
    }
  }
}
