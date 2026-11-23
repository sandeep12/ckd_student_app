import '../../../core/api/api_client.dart';
import '../../../core/api/api_config.dart';

/// Password reset endpoints (`/api/v1/auth/forgot-password*`).
///
/// Contracts (probed against the live backend):
/// - `POST /auth/forgot-password` `{email}` → `{requested: true}`. Always
///   succeeds for any well-formed email (no account enumeration). The
///   backend emails a reset *link* carrying a token.
/// - `POST /auth/forgot-password/reset` `{token, password}`. Bad tokens fail
///   with `PASSWORD_RESET_TOKEN_INVALID`; weak passwords with
///   `VALIDATION_ERROR` on `password`.
class PasswordResetRepository {
  PasswordResetRepository({ApiClient? apiClient})
      : _api = apiClient ?? ApiClient(baseUrl: ApiConfig.baseUrl);

  final ApiClient _api;

  static const String tokenInvalidCode = 'PASSWORD_RESET_TOKEN_INVALID';

  Future<void> requestReset({required String email}) async {
    await _api.post('/auth/forgot-password', body: {'email': email});
  }

  Future<void> resetPassword({
    required String token,
    required String password,
  }) async {
    await _api.post('/auth/forgot-password/reset', body: {
      'token': token,
      'password': password,
    });
  }

  /// Accepts either a raw token or the full emailed link and returns the
  /// token (the `token` query parameter when a URL is pasted).
  static String extractToken(String input) {
    final trimmed = input.trim();
    final uri = Uri.tryParse(trimmed);
    final fromQuery = uri?.queryParameters['token'];
    if (fromQuery != null && fromQuery.isNotEmpty) return fromQuery;
    return trimmed;
  }
}
