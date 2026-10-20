import 'package:budgget_buddy/core/user_shared_prefs.dart';
import 'package:budgget_buddy/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Finder textFieldWithHint(String hint) => find.byWidgetPredicate(
  (w) => w is TextField && w.decoration?.hintText == hint,
);

// Text fields contain scrollables too, so name the page's list explicitly.
Future<void> scrollTo(WidgetTester tester, Finder finder) => tester
    .scrollUntilVisible(finder, 200, scrollable: find.byType(Scrollable).first);

Future<void> startApp(WidgetTester tester, Map<String, Object> prefs) async {
  SharedPreferences.setMockInitialValues({
    // Keeps the test offline.
    'checkUpdatesOnStart': false,
    ...prefs,
  });
  await UserSharedPrefs.init();
  await tester.pumpWidget(const ProviderScope(child: BudgetTrackerApp()));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('first run: onboarding, then adding a transaction', (
    tester,
  ) async {
    await startApp(tester, {});

    expect(find.text('Welcome to Budget Buddy'), findsOneWidget);
    await tester.tap(find.widgetWithText(ChoiceChip, 'Rs'));
    await tester.enterText(textFieldWithHint('0'), '1000');
    await scrollTo(tester, find.text('Get started'));
    await tester.tap(find.text('Get started'));
    await tester.pumpAndSettle();

    expect(find.text('Rs 1,000.00'), findsOneWidget);
    expect(find.text('No transactions'), findsOneWidget);

    await tester.enterText(textFieldWithHint('Title'), 'Coffee');
    await tester.enterText(textFieldWithHint('Amount'), '50');
    await tester.tap(find.byTooltip('Add'));
    await tester.pumpAndSettle();

    expect(find.text('- Coffee'), findsOneWidget);
    expect(find.text('Food & Drinks'), findsOneWidget);
    expect(find.text('Rs 50.00'), findsOneWidget);
    expect(find.text('Rs 950.00'), findsOneWidget, reason: 'new balance');

    final saved = UserSharedPrefs().getTransactionList().single;
    expect(saved.amount, -50);
    expect(saved.category, 'Food & Drinks');
  });

  testWidgets('typing + makes the amount income', (tester) async {
    await startApp(tester, {'onboardingComplete': true});

    await tester.enterText(textFieldWithHint('Title'), 'Salary');
    await tester.enterText(textFieldWithHint('Amount'), '+2000');
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Add'));
    await tester.pumpAndSettle();

    final saved = UserSharedPrefs().getTransactionList().single;
    expect(saved.amount, 2000);
    expect(saved.category, 'Income');
  });

  testWidgets('each month and year header shows its own totals', (
    tester,
  ) async {
    String entry(String id, String date, double amount) =>
        '{"title":"$id","amount":$amount,"date":"$date","id":"$id"}';
    await startApp(tester, {
      'onboardingComplete': true,
      'transactionList': [
        entry('a', '2025-01-10T09:00:00.000', -100),
        entry('b', '2025-02-10T09:00:00.000', -300),
        entry('c', '2024-03-10T09:00:00.000', -50),
      ],
    });

    // Money out: every day row matches its month row.
    expect(find.text('100', skipOffstage: false), findsNWidgets(2));
    expect(find.text('300', skipOffstage: false), findsNWidgets(2));
    expect(
      find.text('400', skipOffstage: false),
      findsOneWidget,
      reason: '2025',
    );
    expect(
      find.text('50', skipOffstage: false),
      findsNWidgets(3),
      reason: '2024',
    );
  });

  testWidgets('existing data from an older version still shows', (
    tester,
  ) async {
    await startApp(tester, {
      'transactionList': [
        '{"title":"Old lunch","description":null,"amount":-120.0,'
            '"date":"2025-06-01T12:00:00.000","id":"legacy-1"}',
      ],
    });

    // Upgrading users go through onboarding once, keeping "Rs" preselected.
    expect(find.text('Welcome to Budget Buddy'), findsOneWidget);
    await scrollTo(tester, find.text('Get started'));
    await tester.tap(find.text('Get started'));
    await tester.pumpAndSettle();

    expect(find.text('- Old lunch'), findsOneWidget);
    expect(find.text('Rs 120.00'), findsOneWidget);
    expect(find.text('Uncategorized'), findsOneWidget);
  });
}
