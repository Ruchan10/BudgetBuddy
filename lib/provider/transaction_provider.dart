import 'package:budgget_buddy/core/user_shared_prefs.dart';
import 'package:budgget_buddy/models/transaction.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final transactionListProvider =
    StateNotifierProvider<TransactionNotifier, List<Transaction>>((ref) {
      return TransactionNotifier();
    });

class TransactionNotifier extends StateNotifier<List<Transaction>> {
  TransactionNotifier() : super([]) {
    _loadTransactions();
  }

  Future<void> _loadTransactions() async {
    final prefs = UserSharedPrefs();
    final list = await prefs.getTransactionList();
    state = list;
  }

  Future<void> addTransaction(Transaction tx) async {
    final prefs = UserSharedPrefs();
    await prefs.addTransaction(tx);
    await _loadTransactions();
  }

  Future<void> updateTransaction(Transaction tx) async {
    final prefs = UserSharedPrefs();
    await prefs.updateTransaction(tx);
    await _loadTransactions();
  }

  Future<void> deleteTransaction(String id) async {
    debugPrint('Deleting transaction: $id');
    final prefs = UserSharedPrefs();
    await prefs.deleteTransaction(id);
    await _loadTransactions();
  }
}
