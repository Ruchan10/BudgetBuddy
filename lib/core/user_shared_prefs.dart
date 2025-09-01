import 'dart:convert';

import 'package:budgget_buddy/models/transaction.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserSharedPrefs {
  static final UserSharedPrefs _instance = UserSharedPrefs._internal();
  late SharedPreferences _prefs;

  UserSharedPrefs._internal();

  static Future<UserSharedPrefs> init() async {
    _instance._prefs = await SharedPreferences.getInstance();
    return _instance;
  }

  factory UserSharedPrefs() => _instance;

  static const String _keyAuthToken = 'authToken';
  static const String _keyEmail = 'email';
  static const String _keyTransactionList = 'transactionList';

  Future<void> saveTransactionList(List<Transaction> list) async {
    final List<String> jsonList = list
        .map((tx) => jsonEncode(tx.toJson()))
        .toList();
    await _prefs.setStringList(_keyTransactionList, jsonList);
  }

  Future<List<Transaction>> getTransactionList() async {
    final List<String>? jsonList = _prefs.getStringList(_keyTransactionList);
    if (jsonList == null) return [];
    return jsonList
        .map((txJson) => Transaction.fromJson(jsonDecode(txJson)))
        .toList();
  }

  Future<void> addTransaction(Transaction transaction) async {
    final currentList = await getTransactionList();
    currentList.add(transaction);

    await saveTransactionList(currentList);
    debugPrint('Transaction added: ${transaction.toJson()}');
  }

  Future<void> deleteTransaction(String id) async {
    final currentList = await getTransactionList();
    currentList.removeWhere((tx) => tx.id == id);
    await saveTransactionList(currentList);
  }

  Future<void> updateTransaction(Transaction transaction) async {
    final currentList = await getTransactionList();
    final index = currentList.indexWhere((tx) => tx.id == transaction.id);
    if (index != -1) {
      currentList[index] = transaction;
      await saveTransactionList(currentList);
    }
  }

  Future<void> clearTransactionList() async {
    await _prefs.remove(_keyTransactionList);
  }

  Future<String> getToken() async => _prefs.getString(_keyAuthToken) ?? '';

  Future<void> deleteToken() async => await _prefs.remove(_keyAuthToken);

  bool isTokenExpired(String? token) => token == null || token.trim().isEmpty;

  Future<void> saveEmail(String email) async =>
      await _prefs.setString(_keyEmail, email);

  Future<String> getEmail() async => _prefs.getString(_keyEmail) ?? '';

  Future<void> deleteEmail() async => await _prefs.remove(_keyEmail);
}
