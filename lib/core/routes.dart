import 'package:budgget_buddy/pages/add_budget.dart';
import 'package:budgget_buddy/pages/no_internet.dart';
import 'package:budgget_buddy/pages/splash_view.dart';
import 'package:budgget_buddy/widgets/nav_bar.dart';

class AppRoute {
  AppRoute._();

  static const String splashRoute = '/splash';
  static const String navRoute = '/nav';
  static const String addBudgetRoute = '/addBudget';
  static const String noInternetRoute = '/noInternet';

  static getAppRoutes() {
    return {
      splashRoute: (context) => const SplashView(),
      navRoute: (context) => const DashBoardView(),
      noInternetRoute: (context) => const NoInternetPage(),
      addBudgetRoute: (context) => const AddBudgetPage(),
    };
  }
}
