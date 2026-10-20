import 'package:budgget_buddy/core/config.dart';
import 'package:budgget_buddy/core/routes.dart';
import 'package:budgget_buddy/provider/settings_provider.dart';
import 'package:budgget_buddy/provider/sync_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SplashView extends ConsumerStatefulWidget {
  const SplashView({super.key});

  @override
  ConsumerState<SplashView> createState() => _SplashViewState();
}

class _SplashViewState extends ConsumerState<SplashView> {
  // The app works offline, so nothing here waits for the network.
  Future<void> _initializeApp() async {
    await ref.read(syncProvider.notifier).start();
    if (!mounted) return;
    final onboarded = ref.read(settingsProvider).onboardingComplete;
    Navigator.pushReplacementNamed(
      context,
      onboarded ? AppRoute.navRoute : AppRoute.onboardingRoute,
    );
  }

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    precacheImage(const AssetImage('assets/images/logo.webp'), context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    height: 100,
                    child: Image.asset('assets/images/logo.webp'),
                  ),
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
