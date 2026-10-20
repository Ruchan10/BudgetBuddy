import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';

class NetworkService {
  NetworkService._();

  static final Connectivity _connectivity = Connectivity();

  /// Emits true when a connection becomes available and false when it's lost.
  static Stream<bool> get onStatusChange =>
      _connectivity.onConnectivityChanged.map(_isOnline).distinct();

  static Future<bool> checkNetwork() async {
    try {
      return _isOnline(await _connectivity.checkConnectivity());
    } catch (e) {
      debugPrint('Network check error: $e');
      return false;
    }
  }

  static bool _isOnline(List<ConnectivityResult> result) =>
      result.any((r) => r != ConnectivityResult.none);
}
