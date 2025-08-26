import 'dart:async';

import 'package:budgget_buddy/core/config.dart';
import 'package:budgget_buddy/core/routes.dart';
import 'package:budgget_buddy/core/snackbar.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';

class NetworkService {
  static final Connectivity _connectivity = Connectivity();
  static bool _hasInternet = false;
  static bool _firstRun = true;
  static StreamSubscription? _subscription;

  static void initialize(BuildContext context) {
    _dispose();
    _subscription = _connectivity.onConnectivityChanged.listen((result) async {
      await _handleConnectivityChange(result, context);
    });
  }

  static Future<void> _handleConnectivityChange(
      List<ConnectivityResult> result, BuildContext context) async {
    final newStatus =
        result.isNotEmpty && result.any((r) => r != ConnectivityResult.none);

    if (newStatus != _hasInternet || _firstRun) {
      _hasInternet = newStatus;
      Config.setHasInternet(_hasInternet);

      if (!_firstRun && context.mounted) {
        if (_hasInternet) {
          _handleConnectionRestored(context);
        } else {
          _handleConnectionLost(context);
        }
      }
      _firstRun = false;
    }
  }

  static void _handleConnectionRestored(BuildContext context) {
    showSnackBar(
      context: context,
      message: 'Internet available',
    );
    Future.delayed(const Duration(seconds: 1), () {
      if (context.mounted) {
        Navigator.pushNamedAndRemoveUntil(
          context,
          AppRoute.splashRoute,
          (route) => false,
        );
      }
    });
  }

  static void _handleConnectionLost(BuildContext context) {
    showSnackBar(
      removeBar: false,
      context: context,
      message: 'No internet connection',
      color: Colors.red,
    );
  }

  static Future<bool> checkNetwork() async {
    try {
      final result = await _connectivity.checkConnectivity();
      return result.isNotEmpty &&
          result.any((r) => r != ConnectivityResult.none);
    } catch (e) {
      debugPrint('Network check error: $e');
      return false;
    }
  }

  static void _dispose() {
    _subscription?.cancel();
    _subscription = null;
  }
}
