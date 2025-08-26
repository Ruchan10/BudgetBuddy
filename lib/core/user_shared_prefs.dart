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

  Future<void> saveToken(String token) async =>
      await _prefs.setString(_keyAuthToken, token);

  Future<String> getToken() async => _prefs.getString(_keyAuthToken) ?? '';

  Future<void> deleteToken() async => await _prefs.remove(_keyAuthToken);

  bool isTokenExpired(String? token) => token == null || token.trim().isEmpty;

  Future<void> saveEmail(String email) async =>
      await _prefs.setString(_keyEmail, email);

  Future<String> getEmail() async => _prefs.getString(_keyEmail) ?? '';

  Future<void> deleteEmail() async => await _prefs.remove(_keyEmail);

}
