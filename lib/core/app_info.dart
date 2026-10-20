/// Static facts about the app plus build-time switches.
class AppInfo {
  AppInfo._();

  static const name = 'Budget Buddy';
  static const developer = 'RK';
  static const repoUrl = 'https://github.com/Ruchan10/BudgetBuddy';
  static const issuesUrl = '$repoUrl/issues';
  static const supabaseDashboardUrl = 'https://supabase.com/dashboard';

  /// In-app update checks against GitHub releases.
  ///
  /// F-Droid builds should pass `--dart-define=UPDATE_CHECKER=false`: F-Droid
  /// delivers updates itself and signs APKs with its own key, so a GitHub APK
  /// could not be installed over an F-Droid one anyway.
  static const updateCheckerEnabled = bool.fromEnvironment(
    'UPDATE_CHECKER',
    defaultValue: true,
  );

  /// Buttons shown in Settings → Support. Add your own, for example:
  /// `DonationLink('Ko-fi', 'https://ko-fi.com/yourname')`.
  static const donationLinks = <DonationLink>[];
}

class DonationLink {
  const DonationLink(this.label, this.url);

  final String label;
  final String url;
}
