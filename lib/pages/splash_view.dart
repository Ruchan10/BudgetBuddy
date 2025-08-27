import 'dart:async';

import 'package:budgget_buddy/core/config.dart';
import 'package:budgget_buddy/core/listen_internet.dart';
import 'package:budgget_buddy/core/routes.dart';
import 'package:budgget_buddy/core/user_shared_prefs.dart';
import 'package:budgget_buddy/widgets/update_manager.dart';
import 'package:flutter/material.dart';

class SplashView extends StatefulWidget {
  const SplashView({super.key});

  @override
  State<SplashView> createState() => _SplashViewState();
}

class _SplashViewState extends State<SplashView> {
  bool _initialized = false;
  final Completer<void> _navigationCompleter = Completer<void>();

  Future<void> _initializeApp() async {
    await UserSharedPrefs.init();

    if (_navigationCompleter.isCompleted) return;
    _navigationCompleter.complete();

    bool hasInternet = await NetworkService.checkNetwork();
    if (hasInternet) {
      Navigator.popAndPushNamed(context, AppRoute.addBudgetRoute);

      // try {
      //   final token = await UserSharedPrefs().getToken();
      //   if (token.trim().isNotEmpty) {
      //     if (!mounted) return;
      //     Navigator.popAndPushNamed(context, AppRoute.addBudgetRoute);
      //   } else {
      //     if (!mounted) return;
      //     Navigator.popAndPushNamed(context, AppRoute.loginRoute);
      //   }
      // } catch (e) {
      //   if (!mounted) return;
      //   Navigator.popAndPushNamed(context, AppRoute.loginRoute);
      // }
    } else {
      if (!mounted) return;
      Navigator.popAndPushNamed(context, AppRoute.noInternetRoute);
    }
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      UpdateManager.checkForUpdates();
      _initializeApp();

      _initialized = true;
    }

    precacheImage(const AssetImage('assets/images/logo.webp'), context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset('assets/images/logo.webp'),
                  SizedBox(height: 50),
                  TickerMode(
                    enabled: ModalRoute.of(context)?.isCurrent ?? true,
                    child: const CircularProgressIndicator(),
                  ),
                ],
              ),
            ),
            Positioned(
              bottom: 50,
              left: 0,
              right: 0,
              child: Center(
                child: Text(
                  'Version: ${Config.getAppVersion()}',
                  style: TextStyle(fontSize: 20),
                ),
              ),
            ),
            const Positioned(
              bottom: 20,
              left: 0,
              right: 0,
              child: Center(
                child: Text('Developed by: RK', style: TextStyle(fontSize: 18)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
