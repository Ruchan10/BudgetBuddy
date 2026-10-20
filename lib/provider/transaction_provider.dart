import 'package:budgget_buddy/core/user_shared_prefs.dart';
import 'package:budgget_buddy/models/category.dart';
import 'package:budgget_buddy/models/transaction.dart';
import 'package:budgget_buddy/provider/settings_provider.dart';
import 'package:budgget_buddy/services/categorizer.dart';
import 'package:budgget_buddy/services/sync_merge.dart' as merge;
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Visible (not deleted) transactions.
final transactionListProvider =
    StateNotifierProvider<TransactionNotifier, List<Transaction>>((ref) {
      return TransactionNotifier(ref);
    });

/// Categories the user made up, for the category picker.
final customCategoriesProvider = Provider<List<String>>((ref) {
  final names = {
    for (final t in ref.watch(transactionListProvider))
      if (t.category != null && !Categories.isBuiltIn(t.category!)) t.category!,
  };
  return names.toList()..sort();
});

class TransactionNotifier extends StateNotifier<List<Transaction>> {
  TransactionNotifier(this._ref) : super(const []) {
    _all = _prefs.getTransactionList();
    _publish();
  }

  final Ref _ref;
  final _prefs = UserSharedPrefs();

  /// Everything stored, including deletions that still have to be synced.
  List<Transaction> _all = [];

  bool get hasPendingChanges => _all.any((t) => t.pendingSync);

  List<Transaction> get pendingChanges =>
      _all.where((t) => t.pendingSync).toList();

  bool get hasUncategorized => state.any((t) => t.category == null);

  /// Sum of all visible amounts; the balance is this plus the opening balance.
  double get total => state.fold(0.0, (sum, t) => sum + t.amount);

  Future<void> addTransaction(Transaction tx) async {
    final autoCategorize = _ref.read(settingsProvider).autoCategorize;
    final category =
        tx.category ??
        (autoCategorize
            ? Categorizer.suggest(tx.title, tx.amount, _all)
            : null);
    await _save([..._all, tx.copyWith(category: category)]);
  }

  Future<void> updateTransaction(Transaction tx) => _save([
    for (final t in _all)
      t.id == tx.id
          ? tx.copyWith(updatedAt: DateTime.now(), pendingSync: true)
          : t,
  ]);

  Future<void> deleteTransaction(String id) {
    // With sync set up, keep a marker so the deletion reaches other devices.
    final keepTombstone = _prefs.hasSupabaseConfig;
    return _save([
      for (final t in _all)
        if (t.id != id)
          t
        else if (keepTombstone)
          t.copyWith(
            deleted: true,
            updatedAt: DateTime.now(),
            pendingSync: true,
          ),
    ]);
  }

  /// Fills in categories that are still empty. Returns how many changed.
  Future<int> categorizeUncategorized() async {
    final now = DateTime.now();
    var changed = 0;
    final next = <Transaction>[];
    for (final t in _all) {
      final category = t.deleted || t.category != null
          ? null
          : Categorizer.suggest(t.title, t.amount, _all);
      if (category == null) {
        next.add(t);
      } else {
        changed++;
        next.add(
          t.copyWith(category: category, updatedAt: now, pendingSync: true),
        );
      }
    }
    if (changed > 0) await _save(next);
    return changed;
  }

  // Used by sync.

  Future<void> applyRemote(List<Transaction> rows) =>
      _save(merge.mergeRemote(_all, rows));

  Future<void> markPushed(List<Transaction> pushed) =>
      _save(merge.markPushed(_all, pushed));

  /// Queues everything for upload, e.g. after signing in to a new account.
  Future<void> markAllPending() =>
      _save([for (final t in _all) t.copyWith(pendingSync: true)]);

  Future<void> dropTombstones() =>
      _save(_all.where((t) => !t.deleted).toList());

  Future<void> _save(List<Transaction> next) async {
    _all = next;
    _publish();
    await _prefs.saveTransactionList(_all);
  }

  void _publish() => state = _all.where((t) => !t.deleted).toList();
}
