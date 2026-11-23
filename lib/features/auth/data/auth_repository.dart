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

  /// `POST /auth/login`. Returns either an authenticated session or an
  /// MFA challenge. Throws [ApiException] on failure
  /// (`VALIDATION_ERROR`, `TERMS_NOT_ACCEPTED`, `INVALID_CREDENTIALS`,
  /// `ACCOUNT_LOCKED`, network).
  Future<LoginOutcome> login({
    required String email,
    required String password,
    required bool termsAccepted,
  }) async {
    final data = await _api.post('/auth/login', body: {
      'email': email.trim(),
      'password': password,
      'termsAccepted': termsAccepted,
    });
    final outcome = LoginOutcome.fromJson(data);
    if (outcome is LoginAuthenticated) {
      await _saveSession(outcome.session);
    }
    return outcome;
  }

  /// `POST /auth/mfa/verify` with the emailed one-time code.
  /// Throws [ApiException] (`MFA_CHALLENGE_EXPIRED`, incorrect code,
  /// too many attempts, network).
  Future<AuthSession> verifyMfa({
    required String challengeToken,
    required String code,
  }) async {
    final data = await _api.post('/auth/mfa/verify', body: {
      'challengeToken': challengeToken,
      'code': code,
    });
    final session = AuthSession.fromJson(
      data is Map<String, dynamic> ? (data['session'] ?? data) : data,
    );
    await _saveSession(session);
    return session;
  }

  /// `POST /auth/mfa/resend`. Returns the new challenge when the backend
  /// issues one, otherwise null (the old token stays valid).
  Future<MfaChallenge?> resendMfa({required String challengeToken}) async {
    final data = await _api.post('/auth/mfa/resend', body: {
      'challengeToken': challengeToken,
    });
    if (data is Map<String, dynamic>) {
      return MfaChallenge.tryParse(data['challenge'] ?? data);
    }
    return null;
  }

  /// `GET /auth/me`.
  Future<AuthUser?> me() async {
    final token = await _tokens.readAccessToken();
    final data = await _api.get('/auth/me', accessToken: token);
    return AuthUser.tryParse(data);
  }

  /// `POST /auth/refresh`.
  Future<AuthSession> refresh() async {
    final refreshToken = await _tokens.readRefreshToken();
    final data = await _api.post('/auth/refresh', body: {
      if (refreshToken != null) 'refreshToken': refreshToken,
    });
    final session = AuthSession.fromJson(
      data is Map<String, dynamic> ? (data['session'] ?? data) : data,
    );
    await _saveSession(session);
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

  Future<void> _saveSession(AuthSession session) => _tokens.save(
        accessToken: session.accessToken,
        refreshToken: session.refreshToken,
      );
}
