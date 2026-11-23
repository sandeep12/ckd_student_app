import 'package:shared_preferences/shared_preferences.dart';

/// Persists the session tokens.
///
/// Uses shared_preferences for the frontend build; swap for
/// flutter_secure_storage before production hardening.
class TokenStorage {
  static const _accessTokenKey = 'auth.accessToken';
  static const _refreshTokenKey = 'auth.refreshToken';

  Future<void> save({String? accessToken, String? refreshToken}) async {
    final prefs = await SharedPreferences.getInstance();
    if (accessToken != null) {
      await prefs.setString(_accessTokenKey, accessToken);
    }
    if (refreshToken != null) {
      await prefs.setString(_refreshTokenKey, refreshToken);
    }
  }

  Future<String?> readAccessToken() async =>
      (await SharedPreferences.getInstance()).getString(_accessTokenKey);

  Future<String?> readRefreshToken() async =>
      (await SharedPreferences.getInstance()).getString(_refreshTokenKey);

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_accessTokenKey);
    await prefs.remove(_refreshTokenKey);
  }
}
