import 'package:budgget_buddy/pages/add_budget.dart';
import 'package:budgget_buddy/pages/cloud_sync.dart';
import 'package:budgget_buddy/pages/onboarding.dart';
import 'package:budgget_buddy/pages/splash_view.dart';
import 'package:budgget_buddy/pages/supabase_guide.dart';
import 'package:budgget_buddy/widgets/nav_bar.dart';

class AppRoute {
  AppRoute._();

  static const String splashRoute = '/splash';
  static const String onboardingRoute = '/welcome';
  static const String navRoute = '/nav';
  static const String addBudgetRoute = '/addBudget';
  static const String cloudSyncRoute = '/cloudSync';
  static const String supabaseGuideRoute = '/supabaseGuide';

  static getAppRoutes() {
    return {
      splashRoute: (context) => const SplashView(),
      onboardingRoute: (context) => const OnboardingPage(),
      navRoute: (context) => const DashBoardView(),
      addBudgetRoute: (context) => const AddBudgetPage(),
      cloudSyncRoute: (context) => const CloudSyncPage(),
      supabaseGuideRoute: (context) => const SupabaseGuidePage(),
    };
  }
}
