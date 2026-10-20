import 'dart:convert';

import 'package:budgget_buddy/core/money.dart';
import 'package:budgget_buddy/models/app_settings.dart';
import 'package:budgget_buddy/models/transaction.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserSharedPrefs {
  static final UserSharedPrefs _instance = UserSharedPrefs._internal();
  late SharedPreferences _prefs;

  UserSharedPrefs._internal();

  /// Must finish before anything reads preferences (see main()).
  static Future<UserSharedPrefs> init() async {
    _instance._prefs = await SharedPreferences.getInstance();
    return _instance;
  }

  factory UserSharedPrefs() => _instance;

  static const String _keyAuthToken = 'authToken';
  static const String _keyEmail = 'email';
  static const String _keyTransactionList = 'transactionList';
  static const String _keyThemeMode = 'themeMode';
  static const String _keyCurrencySymbol = 'currencySymbol';
  static const String _keyOpeningBalance = 'openingBalance';
  static const String _keyOpeningBalanceUpdatedAt = 'openingBalanceUpdatedAt';
  static const String _keyOpenKeyboard = 'openKeyboardOnStart';
  static const String _keyCheckUpdates = 'checkUpdatesOnStart';
  static const String _keyAutoCategorize = 'autoCategorize';
  static const String _keyAiCategorize = 'aiCategorize';
  static const String _keyOnboardingComplete = 'onboardingComplete';
  static const String _keySupabaseUrl = 'supabaseUrl';
  static const String _keySupabaseKey = 'supabaseKey';
  static const String _keySyncUserId = 'syncUserId';
  static const String _keySyncCursor = 'syncCursor';
  static const String _keyLastSyncedAt = 'lastSyncedAt';

  // Transactions

  Future<void> saveTransactionList(List<Transaction> list) async {
    final List<String> jsonList = list
        .map((tx) => jsonEncode(tx.toJson()))
        .toList();
    await _prefs.setStringList(_keyTransactionList, jsonList);
  }

  List<Transaction> getTransactionList() {
    final List<String>? jsonList = _prefs.getStringList(_keyTransactionList);
    if (jsonList == null) return [];
    return jsonList
        .map((txJson) => Transaction.fromJson(jsonDecode(txJson)))
        .toList();
  }

  // Settings

  ThemeMode getThemeMode() =>
      ThemeMode.values[_prefs.getInt(_keyThemeMode) ?? ThemeMode.system.index];

  Future<void> saveThemeMode(ThemeMode mode) async =>
      await _prefs.setInt(_keyThemeMode, mode.index);

  AppSettings getSettings() {
    final balanceAt = _prefs.getString(_keyOpeningBalanceUpdatedAt);
    return AppSettings(
      // People upgrading from a version without this setting saw "Rs".
      currencySymbol:
          _prefs.getString(_keyCurrencySymbol) ??
          (_prefs.containsKey(_keyTransactionList)
              ? 'Rs'
              : defaultCurrencySymbol()),
      openingBalance: _prefs.getDouble(_keyOpeningBalance) ?? 0,
      openingBalanceUpdatedAt: balanceAt == null
          ? null
          : DateTime.parse(balanceAt),
      openKeyboardOnStart: _prefs.getBool(_keyOpenKeyboard) ?? true,
      checkUpdatesOnStart: _prefs.getBool(_keyCheckUpdates) ?? true,
      autoCategorize: _prefs.getBool(_keyAutoCategorize) ?? true,
      aiCategorize: _prefs.getBool(_keyAiCategorize) ?? false,
      onboardingComplete: _prefs.getBool(_keyOnboardingComplete) ?? false,
    );
  }

  Future<void> saveSettings(AppSettings settings) async {
    await _prefs.setString(_keyCurrencySymbol, settings.currencySymbol);
    await _prefs.setDouble(_keyOpeningBalance, settings.openingBalance);
    final balanceAt = settings.openingBalanceUpdatedAt;
    if (balanceAt != null) {
      await _prefs.setString(
        _keyOpeningBalanceUpdatedAt,
        balanceAt.toUtc().toIso8601String(),
      );
    }
    await _prefs.setBool(_keyOpenKeyboard, settings.openKeyboardOnStart);
    await _prefs.setBool(_keyCheckUpdates, settings.checkUpdatesOnStart);
    await _prefs.setBool(_keyAutoCategorize, settings.autoCategorize);
    await _prefs.setBool(_keyAiCategorize, settings.aiCategorize);
    await _prefs.setBool(_keyOnboardingComplete, settings.onboardingComplete);
  }

  // Supabase sync

  ({String url, String key})? get supabaseConfig {
    final url = _prefs.getString(_keySupabaseUrl);
    final key = _prefs.getString(_keySupabaseKey);
    if (url == null || key == null) return null;
    return (url: url, key: key);
  }

  bool get hasSupabaseConfig => supabaseConfig != null;

  Future<void> saveSupabaseConfig(String url, String key) async {
    await _prefs.setString(_keySupabaseUrl, url);
    await _prefs.setString(_keySupabaseKey, key);
  }

  /// Forgets the project and everything sync remembered about it.
  Future<void> clearSupabaseConfig() async {
    for (final key in [
      _keySupabaseUrl,
      _keySupabaseKey,
      _keySyncUserId,
      _keySyncCursor,
      _keyLastSyncedAt,
    ]) {
      await _prefs.remove(key);
    }
  }

  /// The Supabase user whose data is on this device.
  String? get syncUserId => _prefs.getString(_keySyncUserId);

  Future<void> setSyncUserId(String id) async =>
      await _prefs.setString(_keySyncUserId, id);

  /// Newest server change already downloaded.
  DateTime? get syncCursor => _getDate(_keySyncCursor);

  Future<void> setSyncCursor(DateTime? at) => _setDate(_keySyncCursor, at);

  DateTime? get lastSyncedAt => _getDate(_keyLastSyncedAt);

  Future<void> setLastSyncedAt(DateTime at) => _setDate(_keyLastSyncedAt, at);

  DateTime? _getDate(String key) {
    final value = _prefs.getString(key);
    return value == null ? null : DateTime.parse(value);
  }

  Future<void> _setDate(String key, DateTime? at) async => at == null
      ? await _prefs.remove(key)
      : await _prefs.setString(key, at.toUtc().toIso8601String());

  Future<String> getToken() async => _prefs.getString(_keyAuthToken) ?? '';

  Future<void> deleteToken() async => await _prefs.remove(_keyAuthToken);

  bool isTokenExpired(String? token) => token == null || token.trim().isEmpty;

  Future<void> saveEmail(String email) async =>
      await _prefs.setString(_keyEmail, email);

  Future<String> getEmail() async => _prefs.getString(_keyEmail) ?? '';

  Future<void> deleteEmail() async => await _prefs.remove(_keyEmail);
}
