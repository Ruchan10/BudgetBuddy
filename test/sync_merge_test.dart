import 'package:budgget_buddy/models/transaction.dart';
import 'package:budgget_buddy/services/sync_merge.dart';
import 'package:flutter_test/flutter_test.dart';

Transaction tx(
  String id, {
  String title = 'Item',
  String? category,
  required int editedDay,
  bool deleted = false,
  bool pendingSync = false,
}) => Transaction(
  id: id,
  title: title,
  amount: -10,
  date: DateTime(2025, 1, 1),
  category: category,
  updatedAt: DateTime.utc(2025, 1, editedDay),
  deleted: deleted,
  pendingSync: pendingSync,
);

Transaction byId(List<Transaction> list, String id) =>
    list.singleWhere((t) => t.id == id);

void main() {
  group('mergeRemote', () {
    test('adds new rows and ignores deletions of unknown rows', () {
      final merged = mergeRemote(
        [tx('a', editedDay: 1)],
        [tx('b', editedDay: 2), tx('c', editedDay: 2, deleted: true)],
      );

      expect(merged.map((t) => t.id), ['a', 'b']);
    });

    test('newer remote edit replaces the local copy', () {
      final merged = mergeRemote(
        [tx('a', title: 'old', editedDay: 1, pendingSync: true)],
        [tx('a', title: 'new', editedDay: 2)],
      );

      expect(byId(merged, 'a').title, 'new');
      expect(byId(merged, 'a').pendingSync, isFalse);
    });

    test('newer local edit is kept and still uploads', () {
      final merged = mergeRemote(
        [tx('a', title: 'mine', editedDay: 3, pendingSync: true)],
        [tx('a', title: 'theirs', editedDay: 2)],
      );

      expect(byId(merged, 'a').title, 'mine');
      expect(byId(merged, 'a').pendingSync, isTrue);
    });

    test('newer remote deletion removes the row', () {
      final merged = mergeRemote(
        [tx('a', editedDay: 1)],
        [tx('a', editedDay: 2, deleted: true)],
      );

      expect(merged, isEmpty);
    });

    test('newer remote edit brings back a locally deleted row', () {
      final merged = mergeRemote(
        [tx('a', editedDay: 1, deleted: true, pendingSync: true)],
        [tx('a', title: 'edited elsewhere', editedDay: 2)],
      );

      expect(byId(merged, 'a').deleted, isFalse);
      expect(byId(merged, 'a').title, 'edited elsewhere');
    });

    test('adopts a category the server filled in without a newer edit', () {
      final merged = mergeRemote(
        [tx('a', editedDay: 3, pendingSync: true)],
        [tx('a', category: 'Groceries', editedDay: 2)],
      );

      expect(byId(merged, 'a').category, 'Groceries');
      expect(byId(merged, 'a').pendingSync, isTrue);
    });

    test('never overrides a category chosen locally', () {
      final merged = mergeRemote(
        [tx('a', category: 'Mine', editedDay: 2)],
        [tx('a', category: 'Theirs', editedDay: 2)],
      );

      expect(byId(merged, 'a').category, 'Mine');
    });
  });

  group('markPushed', () {
    test('clears pending for uploaded rows and forgets uploaded deletions', () {
      final local = [
        tx('a', editedDay: 1, pendingSync: true),
        tx('b', editedDay: 1, deleted: true, pendingSync: true),
        tx('c', editedDay: 1, pendingSync: true),
      ];

      final result = markPushed(local, local.sublist(0, 2));

      expect(result.map((t) => t.id), ['a', 'c']);
      expect(byId(result, 'a').pendingSync, isFalse);
      expect(byId(result, 'c').pendingSync, isTrue, reason: 'not uploaded');
    });

    test('keeps pending when the row changed during the upload', () {
      final sent = tx('a', title: 'v1', editedDay: 1, pendingSync: true);
      final local = [tx('a', title: 'v2', editedDay: 2, pendingSync: true)];

      final result = markPushed(local, [sent]);

      expect(byId(result, 'a').title, 'v2');
      expect(byId(result, 'a').pendingSync, isTrue);
    });
  });
}
