import 'package:budgget_buddy/pages/add_budget.dart';
import 'package:budgget_buddy/pages/analytics.dart';
import 'package:budgget_buddy/pages/splash_view.dart';
import 'package:budgget_buddy/pages/starting_balance.dart';
import 'package:budgget_buddy/widgets/nav_bar.dart';

class AppRoute {
  AppRoute._();

  static const String splashRoute = '/splash';
  static const String navRoute = '/nav';
  static const String addBudgetRoute = '/addBudget';
  static const String startingBalanceRoute = '/startingBalance';
  static const String analyticsRoute = '/analytics';

  static getAppRoutes() {
    return {
      splashRoute: (context) => const SplashView(),
      navRoute: (context) => const DashBoardView(),
      addBudgetRoute: (context) => const AddBudgetPage(),
      startingBalanceRoute: (context) => const StartingBalancePage(),
      analyticsRoute: (context) => const AnalyticsPage(),
    };
  }
}
