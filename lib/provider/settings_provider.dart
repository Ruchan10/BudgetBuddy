import 'package:budgget_buddy/core/user_shared_prefs.dart';
import 'package:budgget_buddy/models/app_settings.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final settingsProvider = StateNotifierProvider<SettingsNotifier, AppSettings>((
  ref,
) {
  return SettingsNotifier();
});

class SettingsNotifier extends StateNotifier<AppSettings> {
  SettingsNotifier() : super(UserSharedPrefs().getSettings());

  Future<void> update(AppSettings Function(AppSettings current) change) async {
    state = change(state);
    await UserSharedPrefs().saveSettings(state);
  }

  /// [updatedAt] is only passed when applying a value that came from sync.
  Future<void> setOpeningBalance(double value, {DateTime? updatedAt}) => update(
    (s) => s.copyWith(
      openingBalance: value,
      openingBalanceUpdatedAt: updatedAt ?? DateTime.now(),
    ),
  );
}
