import '../../../core/api/api_client.dart';
import '../../../core/api/api_config.dart';
import '../../../core/storage/token_storage.dart';
import 'models/auth_models.dart';

/// Auth endpoints (`/api/v1/auth/*`).
class AuthRepository {
  AuthRepository({ApiClient? apiClient, TokenStorage? tokenStorage})
      : _api = apiClient ?? ApiClient(baseUrl: ApiConfig.baseUrl),
        _tokens = tokenStorage ?? TokenStorage();

  final ApiClient _api;
  final TokenStorage _tokens;

  /// `POST /auth/login`. Throws [ApiException] on failure
  /// (`VALIDATION_ERROR`, `TERMS_NOT_ACCEPTED`, `INVALID_CREDENTIALS`,
  /// `ACCOUNT_LOCKED`, network).
  Future<AuthSession> login({
    required String email,
    required String password,
    required bool termsAccepted,
  }) async {
    final data = await _api.post('/auth/login', body: {
      'email': email.trim(),
      'password': password,
      'termsAccepted': termsAccepted,
    });
    final session = AuthSession.fromJson(data);
    await _tokens.save(
      accessToken: session.accessToken,
      refreshToken: session.refreshToken,
    );
    return session;
  }

  /// `GET /auth/me`.
  Future<AuthUser?> me() async {
    final token = await _tokens.readAccessToken();
    final data = await _api.get('/auth/me', accessToken: token);
    return AuthUser.tryParse(
      data is Map<String, dynamic> ? (data['user'] ?? data) : data,
    );
  }

  /// `POST /auth/refresh`.
  Future<AuthSession> refresh() async {
    final refreshToken = await _tokens.readRefreshToken();
    final data = await _api.post('/auth/refresh', body: {
      if (refreshToken != null) 'refreshToken': refreshToken,
    });
    final session = AuthSession.fromJson(data);
    await _tokens.save(
      accessToken: session.accessToken,
      refreshToken: session.refreshToken,
    );
    return session;
  }

  /// `POST /auth/logout`. Always clears local tokens.
  Future<void> logout() async {
    try {
      final token = await _tokens.readAccessToken();
      await _api.post('/auth/logout', accessToken: token);
    } finally {
      await _tokens.clear();
    }
  }
}
