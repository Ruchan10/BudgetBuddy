import 'package:budgget_buddy/models/transaction.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Transaction', () {
    test('reads entries saved before categories and sync existed', () {
      final tx = Transaction.fromJson({
        'title': 'Lunch',
        'description': null,
        'amount': -250,
        'date': '2025-06-01T12:30:00.000',
        'id': 'abc',
      });

      expect(tx.id, 'abc');
      expect(tx.amount, -250.0);
      expect(tx.category, isNull);
      expect(tx.updatedAt, tx.date);
      expect(tx.deleted, isFalse);
      expect(tx.pendingSync, isTrue, reason: 'never uploaded');
    });

    test('survives a local save and load unchanged', () {
      final tx = Transaction(
        title: 'Rent',
        description: 'June',
        amount: -15000,
        date: DateTime(2025, 6, 1, 9),
        category: 'Rent & Housing',
        pendingSync: false,
      );

      final copy = Transaction.fromJson(tx.toJson());

      expect(copy.id, tx.id);
      expect(copy.title, 'Rent');
      expect(copy.description, 'June');
      expect(copy.category, 'Rent & Housing');
      expect(copy.date, tx.date);
      expect(copy.updatedAt.isAtSameMomentAs(tx.updatedAt), isTrue);
      expect(copy.pendingSync, isFalse);
    });

    test('maps to and from a Supabase row', () {
      final tx = Transaction(
        title: 'Bus',
        amount: -30.5,
        date: DateTime(2025, 6, 2, 8, 15),
        category: 'Transport',
        updatedAt: DateTime.utc(2025, 6, 2, 3, 0, 0, 123, 456),
      );

      final row = tx.toRemote();
      expect(row['occurred_at'], endsWith('Z'));
      expect(row['updated_at'], '2025-06-02T03:00:00.123456Z');

      // PostgREST answers with +00:00 offsets and adds server columns.
      final back = Transaction.fromRemote({
        ...row,
        'updated_at': '2025-06-02T03:00:00.123456+00:00',
        'user_id': 'someone',
        'server_updated_at': '2025-06-02T03:00:01+00:00',
      });
      expect(back.id, tx.id);
      expect(back.amount, -30.5);
      expect(back.date.isAtSameMomentAs(tx.date), isTrue);
      expect(back.updatedAt.isAtSameMomentAs(tx.updatedAt), isTrue);
      expect(back.pendingSync, isFalse);
    });

    test('copyWith can clear optional fields', () {
      final tx = Transaction(
        title: 'Gift',
        description: 'for mum',
        amount: -500,
        date: DateTime(2025),
        category: 'Gifts & Donations',
      );

      expect(tx.copyWith(title: 'Present').description, 'for mum');
      expect(tx.copyWith(description: null).description, isNull);
      expect(tx.copyWith(category: null).category, isNull);
      expect(tx.copyWith(amount: -1).category, 'Gifts & Donations');
    });
  });
}
