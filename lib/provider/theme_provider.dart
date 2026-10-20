import 'package:budgget_buddy/core/user_shared_prefs.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ThemeNotifier extends StateNotifier<ThemeMode> {
  ThemeNotifier() : super(UserSharedPrefs().getThemeMode());

  Future<void> setTheme(ThemeMode mode) async {
    state = mode;
    await UserSharedPrefs().saveThemeMode(mode);
  }
}

final themeProvider = StateNotifierProvider<ThemeNotifier, ThemeMode>((ref) {
  return ThemeNotifier();
});
