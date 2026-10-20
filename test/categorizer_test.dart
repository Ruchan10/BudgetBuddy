import 'package:budgget_buddy/models/category.dart';
import 'package:budgget_buddy/models/transaction.dart';
import 'package:budgget_buddy/services/categorizer.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  String? suggest(
    String title, {
    double amount = -100,
    List<Transaction>? history,
  }) => Categorizer.suggest(title, amount, history ?? const []);

  group('Categorizer', () {
    test('recognises common words and merchants', () {
      expect(suggest('Coffee at Himalayan Java'), 'Food & Drinks');
      expect(suggest('Chicken momo'), 'Food & Drinks');
      expect(suggest('Uber Eats order'), 'Food & Drinks');
      expect(suggest('Uber to airport'), 'Transport');
      expect(suggest('Groceries'), 'Groceries');
      expect(suggest('Petrol'), 'Transport');
      expect(suggest('Electricity bill'), 'Bills & Utilities');
      expect(suggest('Ncell recharge'), 'Bills & Utilities');
      expect(suggest('Netflix subscription'), 'Entertainment');
      expect(suggest('Medical bill'), 'Health');
      expect(suggest('Room rent'), 'Rent & Housing');
      expect(suggest('Haircut'), 'Personal Care');
      expect(suggest('Semester fee'), 'Education');
      expect(suggest('Flight to Pokhara'), 'Travel');
      expect(suggest('New shoes'), 'Shopping');
      expect(suggest('Birthday gift'), 'Gifts & Donations');
    });

    test('matches whole words only', () {
      expect(suggest('Business lunch'), 'Food & Drinks');
      expect(
        suggest('Business card'),
        isNull,
        reason: '"bus" is not "business"',
      );
      expect(suggest('Booking.com'), 'Travel', reason: 'not "book"');
    });

    test('treats money coming in as income', () {
      expect(suggest('Salary', amount: 50000), Categories.income);
      expect(suggest('Coffee refund', amount: 120), Categories.income);
    });

    test('leaves unknown titles empty', () {
      expect(suggest('xyz'), isNull);
      expect(suggest('   '), isNull);
    });

    test('learns from the latest category given to the same title', () {
      final history = [
        Transaction(
          title: 'Starbucks',
          amount: -5,
          date: DateTime(2025),
          category: 'Treats',
          updatedAt: DateTime(2025, 1, 2),
        ),
        Transaction(
          title: 'starbucks #12',
          amount: -5,
          date: DateTime(2025),
          category: 'Coffee',
          updatedAt: DateTime(2025, 3, 1),
        ),
        Transaction(
          title: 'Starbucks',
          amount: -5,
          date: DateTime(2025),
          category: 'Ignored',
          updatedAt: DateTime(2025, 6, 1),
          deleted: true,
        ),
      ];

      expect(suggest('STARBUCKS', history: history), 'Coffee');
      // History beats the income rule too.
      expect(suggest('Starbucks', amount: 5, history: history), 'Coffee');
    });

    test('normalises titles', () {
      expect(Categorizer.normalize('  Lunch #2!  '), 'lunch');
      expect(Categorizer.normalize('Café  au   lait'), 'café au lait');
      expect(
        Categorizer.normalize('खाना'),
        'खाना',
        reason: 'keeps vowel signs',
      );
    });
  });
}
