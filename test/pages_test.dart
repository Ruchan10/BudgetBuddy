import 'package:budgget_buddy/core/app_info.dart';
import 'package:budgget_buddy/core/user_shared_prefs.dart';
import 'package:budgget_buddy/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> openSettings(WidgetTester tester) async {
  SharedPreferences.setMockInitialValues({
    'onboardingComplete': true,
    'checkUpdatesOnStart': false,
    'currencySymbol': 'Rs',
  });
  await UserSharedPrefs.init();
  await tester.pumpWidget(const ProviderScope(child: BudgetTrackerApp()));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Settings'));
  await tester.pumpAndSettle();
}

Future<void> scrollTo(WidgetTester tester, Finder finder) => tester
    .scrollUntilVisible(finder, 200, scrollable: find.byType(Scrollable).first);

void main() {
  testWidgets('settings shows every section', (tester) async {
    await openSettings(tester);

    for (final label in [
      'Appearance',
      'Currency symbol',
      'Open keyboard on start',
      'Auto-categorize',
      'Sync with Supabase',
      if (AppInfo.updateCheckerEnabled) 'Check for updates on start',
      'Support',
      'Star on GitHub',
      'Source code',
      'Open-source licenses',
    ]) {
      await scrollTo(tester, find.text(label));
      expect(find.text(label), findsOneWidget);
    }
    if (!AppInfo.updateCheckerEnabled) {
      // F-Droid builds: the section right above Support is gone.
      expect(find.text('Updates', skipOffstage: false), findsNothing);
      expect(
        find.text('Check for updates now', skipOffstage: false),
        findsNothing,
      );
    }
  });

  testWidgets('currency and theme changes apply right away', (tester) async {
    await openSettings(tester);

    await tester.tap(find.text('Dark'));
    await tester.pumpAndSettle();
    expect(
      tester.widget<MaterialApp>(find.byType(MaterialApp)).themeMode,
      ThemeMode.dark,
    );

    await tester.tap(find.text('Currency symbol'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ChoiceChip, '€'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(find.text('€0.00'), findsOneWidget, reason: 'current balance');
    expect(UserSharedPrefs().getSettings().currencySymbol, '€');
    expect(UserSharedPrefs().getThemeMode(), ThemeMode.dark);
  });

  testWidgets('setup guide shows the bundled SQL and function code', (
    tester,
  ) async {
    await openSettings(tester);
    await scrollTo(tester, find.text('Setup guide'));
    await tester.tap(find.text('Setup guide'));
    await tester.pumpAndSettle();

    expect(find.text('Create the tables'), findsOneWidget);
    expect(
      find.textContaining(
        'create or replace function public.push_transactions',
      ),
      findsOneWidget,
    );
    // Jump rather than drag: drags over a code block scroll the code instead.
    final page = tester
        .state<ScrollableState>(find.byType(Scrollable).first)
        .position;
    final functionCode = find.textContaining(
      "Supabase.ai.Session('gte-small')",
    );
    for (var i = 0; i < 40 && functionCode.evaluate().isEmpty; i++) {
      page.jumpTo(page.pixels + 300);
      await tester.pump();
    }
    expect(find.text('Optional: AI categorization'), findsOneWidget);
    expect(functionCode, findsOneWidget);
  });

  testWidgets('cloud sync refuses a secret key', (tester) async {
    await openSettings(tester);
    await scrollTo(tester, find.text('Sync with Supabase'));
    await tester.tap(find.text('Sync with Supabase'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextField, 'Project URL'),
      'https://abcd1234.supabase.co',
    );
    await tester.enterText(
      find.widgetWithText(TextField, 'Publishable (anon) key'),
      'sb_secret_123',
    );
    await tester.tap(find.text('Connect'));
    await tester.pumpAndSettle();

    expect(find.textContaining('That is a secret key'), findsOneWidget);
    expect(UserSharedPrefs().hasSupabaseConfig, isFalse);
  });
}
