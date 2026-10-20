class AppSettings {
  const AppSettings({
    required this.currencySymbol,
    this.openingBalance = 0,
    this.openingBalanceUpdatedAt,
    this.openKeyboardOnStart = true,
    this.checkUpdatesOnStart = true,
    this.autoCategorize = true,
    this.aiCategorize = false,
    this.onboardingComplete = false,
  });

  /// Shown next to amounts. Empty hides the currency.
  final String currencySymbol;

  /// Money the user had before the first recorded transaction.
  /// Current balance = openingBalance + sum of all transactions.
  final double openingBalance;

  /// When [openingBalance] was last set; sync keeps the newest value.
  /// Null until the user enters a balance.
  final DateTime? openingBalanceUpdatedAt;

  final bool openKeyboardOnStart;
  final bool checkUpdatesOnStart;

  /// Guess categories on the device for new transactions.
  final bool autoCategorize;

  /// Ask the optional Supabase `categorize` function to fill in categories.
  final bool aiCategorize;

  final bool onboardingComplete;

  AppSettings copyWith({
    String? currencySymbol,
    double? openingBalance,
    DateTime? openingBalanceUpdatedAt,
    bool? openKeyboardOnStart,
    bool? checkUpdatesOnStart,
    bool? autoCategorize,
    bool? aiCategorize,
    bool? onboardingComplete,
  }) {
    return AppSettings(
      currencySymbol: currencySymbol ?? this.currencySymbol,
      openingBalance: openingBalance ?? this.openingBalance,
      openingBalanceUpdatedAt:
          openingBalanceUpdatedAt ?? this.openingBalanceUpdatedAt,
      openKeyboardOnStart: openKeyboardOnStart ?? this.openKeyboardOnStart,
      checkUpdatesOnStart: checkUpdatesOnStart ?? this.checkUpdatesOnStart,
      autoCategorize: autoCategorize ?? this.autoCategorize,
      aiCategorize: aiCategorize ?? this.aiCategorize,
      onboardingComplete: onboardingComplete ?? this.onboardingComplete,
    );
  }
}
