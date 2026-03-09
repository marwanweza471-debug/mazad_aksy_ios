import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

/// ConnectivityService — singleton that monitors network status in real-time.
///
/// Usage:
///   ConnectivityService().isOnline  — current status (bool)
///   ConnectivityService().stream    — listen to changes (bool)
///   ConnectivityService().init()    — call once in main() before runApp
class ConnectivityService {
  static final ConnectivityService _instance = ConnectivityService._internal();
  factory ConnectivityService() => _instance;
  ConnectivityService._internal();

  final Connectivity _connectivity = Connectivity();

  // Internal broadcast stream controller so multiple widgets can listen.
  final StreamController<bool> _controller =
      StreamController<bool>.broadcast();

  /// Public stream: emits `true` when online, `false` when offline.
  Stream<bool> get stream => _controller.stream;

  bool _isOnline = true;
  bool get isOnline => _isOnline;

  StreamSubscription<List<ConnectivityResult>>? _subscription;

  /// Call once in [main] before [runApp].
  /// Checks the current status and starts listening for changes.
  Future<void> init() async {
    // Check current state immediately.
    final results = await _connectivity.checkConnectivity();
    _isOnline = _hasConnection(results);

    // Subscribe to future changes.
    _subscription = _connectivity.onConnectivityChanged.listen((results) {
      final online = _hasConnection(results);
      if (online != _isOnline) {
        _isOnline = online;
        _controller.add(_isOnline);
        debugPrint('[Connectivity] Status changed → ${_isOnline ? "ONLINE" : "OFFLINE"}');
      }
    });
  }

  bool _hasConnection(List<ConnectivityResult> results) {
    return results.any((r) =>
        r == ConnectivityResult.mobile ||
        r == ConnectivityResult.wifi ||
        r == ConnectivityResult.ethernet ||
        r == ConnectivityResult.vpn);
  }

  void dispose() {
    _subscription?.cancel();
    _controller.close();
  }
}
