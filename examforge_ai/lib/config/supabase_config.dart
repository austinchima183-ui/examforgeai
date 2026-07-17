import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart' as sb;

import '../core/errors/exceptions.dart';
import '../core/utils/logger.dart';
import 'env_config.dart';

/// Centralized Supabase configuration and access point.
///
/// Wraps the `Supabase` singleton and provides convenient getters for
/// the client, current user, and current session. Also exposes helpers
/// for real-time subscriptions and authentication sign-out.
///
/// Call [initialize] once during app startup, after [EnvConfig.initialize].
class SupabaseConfig {
  SupabaseConfig._();

  static bool _initialized = false;

  // ─── Initialization ─────────────────────────────────────────────

  /// Initializes the Supabase Flutter SDK using values from [EnvConfig].
  ///
  /// Must be called after [EnvConfig.initialize] so that the Supabase
  /// URL and anon key are available.
  static Future<void> initialize() async {
    if (_initialized) {
      AppLogger.warning('SupabaseConfig already initialized — skipping.');
      return;
    }

    final url = EnvConfig.supabaseUrl;
    final anonKey = EnvConfig.supabaseAnonKey;

    if (url.isEmpty || anonKey.isEmpty) {
      throw StateError(
        'Supabase URL and Anon Key must be provided. '
        'Check your .env file or --dart-define flags.',
      );
    }

    await sb.Supabase.initialize(
      url: url,
      anonKey: anonKey,
      debug: EnvConfig.isDevelopment,
    );

    _initialized = true;
    AppLogger.info('SupabaseConfig initialized — url: $url');
  }

  // ─── Client Access ──────────────────────────────────────────────

  /// The primary Supabase client instance.
  ///
  /// Throws [StateError] if accessed before [initialize].
  static sb.SupabaseClient get client {
    _assertInitialized();
    return sb.Supabase.instance.client;
  }

  // ─── Auth Accessors ─────────────────────────────────────────────

  /// The currently authenticated Supabase user, or `null` if no
  /// session is active.
  static sb.User? get currentUser {
    _assertInitialized();
    return client.auth.currentUser;
  }

  /// The current auth session, or `null` if not authenticated.
  static sb.Session? get currentSession {
    _assertInitialized();
    return client.auth.currentSession;
  }

  /// `true` if there is an active, non-expired session.
  static bool get isAuthenticated {
    _assertInitialized();
    final session = currentSession;
    if (session == null) return false;
    // Check if the access token has expired.
    final expiresAt = session.expiresAt;
    if (expiresAt == null) return true; // no expiry info, assume valid
    return DateTime.now().millisecondsSinceEpoch ~/ 1000 < expiresAt;
  }

  /// The current access token, or `null` if no session.
  static String? get accessToken {
    _assertInitialized();
    return currentSession?.accessToken;
  }

  // ─── Auth State Stream ──────────────────────────────────────────

  /// A stream of [sb.AuthState] changes from Supabase.
  ///
  /// Emits whenever the user signs in, signs out, the token is
  /// refreshed, or the session expires.
  static Stream<sb.AuthState> get onAuthStateChanged {
    _assertInitialized();
    return client.auth.onAuthStateChange;
  }

  // ─── Sign Out ───────────────────────────────────────────────────

  /// Signs the current user out.
  ///
  /// If [scope] is `SignOutScope.global` (default) all devices are
  /// signed out. Use `SignOutScope.local` to sign out only on this
  /// device.
  static Future<void> signOut({
    sb.SignOutScope scope = sb.SignOutScope.global,
  }) async {
    _assertInitialized();
    try {
      await client.auth.signOut(scope: scope);
      AppLogger.info('User signed out (scope: ${scope.name})');
    } on sb.AuthException catch (e) {
      AppLogger.error('Supabase sign-out failed', error: e);
      throw AuthException(
        message: e.message,
        code: e.code ?? 'sign_out_failed',
      );
    } catch (e) {
      AppLogger.error('Unexpected sign-out error', error: e);
      throw const AuthException(
        message: 'Failed to sign out. Please try again.',
        code: 'sign_out_failed',
      );
    }
  }

  // ─── Real-Time Subscriptions ────────────────────────────────────

  /// Subscribes to real-time changes on a PostgreSQL table via
  /// Supabase Realtime.
  ///
  /// [table] — the table name to watch (e.g. `'notifications'`).
  /// [schema] — the Postgres schema (default `'public'`).
  /// [filter] — optional PostgREST filter string (e.g. `'user_id=eq.123'`).
  /// [onInsert] — callback for inserted rows.
  /// [onUpdate] — callback for updated rows.
  /// [onDelete] — callback for deleted rows.
  ///
  /// Returns a [sb.RealtimeChannel] that the caller can use to unsubscribe.
  static sb.RealtimeChannel subscribeToTable({
    required String table,
    String schema = 'public',
    String? filter,
    void Function(sb.PostgresChangePayload)? onInsert,
    void Function(sb.PostgresChangePayload)? onUpdate,
    void Function(sb.PostgresChangePayload)? onDelete,
  }) {
    _assertInitialized();

    final channelName = 'realtime_${table}_${filter ?? 'all'}';

    final channel = client.channel(channelName);

    var postgresChangeConfig = sb.PostgresChangeEventConfig(
      schema: schema,
      table: table,
    );

    if (filter != null) {
      postgresChangeConfig = sb.PostgresChangeEventConfig(
        schema: schema,
        table: table,
        filter: sb.PostgresChangeFilter(
          type: sb.PostgresChangeFilterType.eq,
          column: filter.split('=eq.').first,
          value: filter.split('=eq.').last,
        ),
      );
    }

    channel.onPostgresChanges(
      sb.PostgresChangeEvent.insert,
      postgresChangeConfig,
      (payload) => onInsert?.call(payload),
    );

    channel.onPostgresChanges(
      sb.PostgresChangeEvent.update,
      postgresChangeConfig,
      (payload) => onUpdate?.call(payload),
    );

    channel.onPostgresChanges(
      sb.PostgresChangeEvent.delete,
      postgresChangeConfig,
      (payload) => onDelete?.call(payload),
    );

    channel.subscribe();

    AppLogger.info('Subscribed to real-time channel: $channelName');
    return channel;
  }

  /// Subscribes to a Supabase Realtime Broadcast channel.
  ///
  /// Use for ephemeral, non-persisted messages (e.g. typing indicators).
  static sb.RealtimeChannel subscribeToBroadcast({
    required String channelName,
    required String event,
    required void Function(Map<String, dynamic>) onMessage,
  }) {
    _assertInitialized();

    final channel = client.channel(channelName);

    channel.onBroadcastMessage(event, (payload) {
      onMessage(payload);
    });

    channel.subscribe();

    AppLogger.info('Subscribed to broadcast channel: $channelName');
    return channel;
  }

  /// Subscribes to a Supabase Realtime Presence channel.
  ///
  /// Use for tracking online/offline status of users.
  static sb.RealtimeChannel subscribeToPresence({
    required String channelName,
    required void Function(sb.PresenceState) onSync,
    Map<String, dynamic>? presenceData,
  }) {
    _assertInitialized();

    final channel = client.channel(channelName);

    channel.onPresenceSync((payload) {
      onSync(payload);
    });

    channel.subscribe(
      (event, state) {
        if (state == sb.RealtimeSubscribeState.subscribed && presenceData != null) {
          channel.track(presenceData);
        }
      },
    );

    AppLogger.info('Subscribed to presence channel: $channelName');
    return channel;
  }

  /// Unsubscribes and removes a previously created channel.
  static Future<void> unsubscribeChannel(sb.RealtimeChannel channel) async {
    _assertInitialized();
    await client.removeChannel(channel);
    AppLogger.info('Unsubscribed from channel: ${channel.topic}');
  }

  /// Unsubscribes all active real-time channels.
  static Future<void> unsubscribeAllChannels() async {
    _assertInitialized();
    await client.removeAllChannels();
    AppLogger.info('Unsubscribed from all real-time channels');
  }

  // ─── Private ────────────────────────────────────────────────────

  static void _assertInitialized() {
    if (!_initialized) {
      throw StateError(
        'SupabaseConfig has not been initialized. '
        'Call SupabaseConfig.initialize() before accessing any properties.',
      );
    }
  }
}
