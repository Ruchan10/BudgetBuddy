import 'package:budgget_buddy/core/config.dart';
import 'package:budgget_buddy/core/routes.dart';
import 'package:budgget_buddy/provider/theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  Config.setAppVersion('1.0.8');
  runApp(ProviderScope(child: const BudgetTrackerApp()));
}

class AppColors {
  // Light Theme
  static const lightPrimary = Color(0xFF1979E6);
  static const lightBackground = Color(0xFFF8FAFC);
  static const lightTextPrimary = Color(0xFF1E293B);
  static const lightTextSecondary = Color(0xFF64748B);
  static const lightInputBackground = Color(0xFFF1F5F9);
  static const lightBorder = Color(0xFFE2E8F0);

  // Dark Theme
  static const darkPrimary = Color(0xFF3B82F6);
  static const darkBackground = Color(0xFF0F172A);
  static const darkTextPrimary = Color(0xFFF8FAFC);
  static const darkTextSecondary = Color(0xFF94A3B8);
  static const darkInputBackground = Color(0xFF1E293B);
  static const darkBorder = Color(0xFF334155);
}

class BudgetTrackerApp extends ConsumerWidget {
  const BudgetTrackerApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);
    return MaterialApp(
      title: 'Budget Tracker',
      theme: ThemeData(
        brightness: Brightness.light,
        primaryColor: AppColors.lightPrimary,
        scaffoldBackgroundColor: AppColors.lightBackground,
        textTheme: TextTheme(
          bodyLarge: TextStyle(color: AppColors.lightTextPrimary),
          bodyMedium: TextStyle(color: AppColors.lightTextSecondary),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.lightInputBackground,
          border: OutlineInputBorder(
            borderSide: BorderSide(color: AppColors.lightBorder),
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: AppColors.darkPrimary,
        scaffoldBackgroundColor: AppColors.darkBackground,
        textTheme: TextTheme(
          bodyLarge: TextStyle(color: AppColors.darkTextPrimary),
          bodyMedium: TextStyle(color: AppColors.darkTextSecondary),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.darkInputBackground,
          border: OutlineInputBorder(
            borderSide: BorderSide(color: AppColors.darkBorder),
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      themeMode: themeMode,
      initialRoute: AppRoute.splashRoute,
      routes: AppRoute.getAppRoutes(),
    );
  }
}
