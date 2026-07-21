import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../utils/logger.dart';

/// Riverpod provider that exposes the [Connectivity] singleton.
final connectivityProvider = Provider<Connectivity>((ref) {
  return Connectivity();
});

/// Streams the current [ConnectivityResult] list (multi-connectivity is
/// possible on some platforms, e.g. WiFi + Cellular).
final connectivityStreamProvider = StreamProvider<List<ConnectivityResult>>(
  (ref) {
    final connectivity = ref.watch(connectivityProvider);
    return connectivity.onConnectivityChanged;
  },
);

/// A convenience provider that yields `true` whenever the device has
/// at least one active connection.
final isConnectedProvider = Provider<bool>((ref) {
  final asyncResult = ref.watch(connectivityStreamProvider);
  return asyncResult.when(
    data: (results) => results.any((r) => r != ConnectivityResult.none),
    loading: () => true, // optimistically assume connected
    error: (_, __) => false,
  );
});

/// Encapsulates network connectivity checks and streams.
///
/// Use the Riverpod providers above for reactive UI, or instantiate this
/// class directly for one-shot checks inside repositories / services.
class NetworkInfo {
  NetworkInfo(this._connectivity);

  final Connectivity _connectivity;

  /// Returns `true` if the device currently has at least one
  /// non-`none` connectivity result.
  Future<bool> get isConnected async {
    final results = await _connectivity.checkConnectivity();
    return results.any((r) => r != ConnectivityResult.none);
  }

  /// A stream that emits the latest connectivity result list.
  Stream<List<ConnectivityResult>> get onConnectivityChanged =>
      _connectivity.onConnectivityChanged;

  /// A convenience stream mapping results to a simple `bool`.
  Stream<bool> get isConnectedStream =>
      _connectivity.onConnectivityChanged.map(
        (results) => results.any((r) => r != ConnectivityResult.none),
      );

  /// Returns a human-readable description of the current connection type.
  Future<String> get connectionType async {
    final results = await _connectivity.checkConnectivity();
    if (results.contains(ConnectivityResult.wifi)) return 'WiFi';
    if (results.contains(ConnectivityResult.ethernet)) return 'Ethernet';
    if (results.contains(ConnectivityResult.mobile)) return 'Mobile';
    if (results.contains(ConnectivityResult.vpn)) return 'VPN';
    if (results.contains(ConnectivityResult.bluetooth)) return 'Bluetooth';
    if (results.contains(ConnectivityResult.other)) return 'Other';
    return 'None';
  }

  /// Calls [callback] only when the device regains connectivity.
  /// Useful for retrying failed network operations.
  void onReconnect(VoidCallback callback) {
    bool wasDisconnected = false;

    _connectivity.onConnectivityChanged.listen((results) {
      final connected = results.any((r) => r != ConnectivityResult.none);

      if (!connected) {
        wasDisconnected = true;
        AppLogger.warning('Network disconnected');
      } else if (wasDisconnected && connected) {
        wasDisconnected = false;
        AppLogger.info('Network reconnected');
        callback();
      }
    });
  }
}

/// Riverpod provider for the [NetworkInfo] service class.
///
/// Named with the `core` prefix so that the DI layer in
/// `dependency_injection.dart` can re-export it under the simpler
/// name `networkInfoProvider` without a naming conflict.
final coreNetworkInfoProvider = Provider<NetworkInfo>((ref) {
  final connectivity = ref.watch(connectivityProvider);
  return NetworkInfo(connectivity);
});
