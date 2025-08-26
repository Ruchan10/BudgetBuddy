import 'package:budgget_buddy/pages/add_budget.dart';
import 'package:budgget_buddy/pages/no_internet.dart';
import 'package:budgget_buddy/pages/splash_view.dart';

class AppRoute {
  AppRoute._();

  static const String splashRoute = '/splash';
  static const String loginRoute = '/login';
  static const String addBudgetRoute = '/addBudget';
  static const String noInternetRoute = '/noInternet';

  static getAppRoutes() {
    return {
      splashRoute: (context) => const SplashView(),
      noInternetRoute: (context) => const NoInternetPage(),
      addBudgetRoute: (context) => const AddBudgetPage(),
    };
  }
}
