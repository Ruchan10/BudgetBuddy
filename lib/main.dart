import 'package:budgget_buddy/core/routes.dart';
import 'package:budgget_buddy/core/user_shared_prefs.dart';
import 'package:budgget_buddy/provider/theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Settings and transactions are read synchronously from here on.
  await UserSharedPrefs.init();
  runApp(const ProviderScope(child: BudgetTrackerApp()));
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

ThemeData buildTheme(Brightness brightness) {
  final isDark = brightness == Brightness.dark;
  final primary = isDark ? AppColors.darkPrimary : AppColors.lightPrimary;
  final textPrimary = isDark
      ? AppColors.darkTextPrimary
      : AppColors.lightTextPrimary;
  final textSecondary = isDark
      ? AppColors.darkTextSecondary
      : AppColors.lightTextSecondary;
  final border = isDark ? AppColors.darkBorder : AppColors.lightBorder;

  // Without a scheme, widgets fall back to Material's default purple.
  final colorScheme =
      ColorScheme.fromSeed(seedColor: primary, brightness: brightness).copyWith(
        primary: primary,
        surface: isDark ? AppColors.darkInputBackground : Colors.white,
        onSurface: textPrimary,
        onSurfaceVariant: textSecondary,
        outlineVariant: border,
      );

  return ThemeData(
    colorScheme: colorScheme,
    primaryColor: primary,
    scaffoldBackgroundColor: isDark
        ? AppColors.darkBackground
        : AppColors.lightBackground,
    textTheme: TextTheme(
      bodyLarge: TextStyle(color: textPrimary),
      bodyMedium: TextStyle(color: textSecondary),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: isDark
          ? AppColors.darkInputBackground
          : AppColors.lightInputBackground,
      border: OutlineInputBorder(
        borderSide: BorderSide(color: border),
        borderRadius: BorderRadius.circular(12),
      ),
    ),
  );
}

class BudgetTrackerApp extends ConsumerWidget {
  const BudgetTrackerApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);
    return MaterialApp(
      title: 'Budget Tracker',
      theme: buildTheme(Brightness.light),
      darkTheme: buildTheme(Brightness.dark),
      themeMode: themeMode,
      initialRoute: AppRoute.splashRoute,
      routes: AppRoute.getAppRoutes(),
    );
  }
}
