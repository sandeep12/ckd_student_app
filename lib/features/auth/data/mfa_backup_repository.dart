import '../../../core/api/api_client.dart';
import '../../../core/api/api_config.dart';
import '../../../core/storage/token_storage.dart';
import 'models/auth_models.dart';

/// `POST /auth/mfa/backup-code` — completes an MFA challenge with a
/// one-time backup code instead of the emailed code.
///
/// Contract (probed against the backend):
/// request `{challengeToken: string, code: string (min 1)}`;
/// errors `BACKUP_CODE_INVALID` (401), `MFA_CHALLENGE_EXPIRED`,
/// `ACCOUNT_LOCKED` (403, `details.retryAt`), `VALIDATION_ERROR`.
/// The success body is assumed to match `/auth/mfa/verify`.
class MfaBackupRepository {
  MfaBackupRepository({ApiClient? apiClient, TokenStorage? tokenStorage})
      : _api = apiClient ?? ApiClient(baseUrl: ApiConfig.baseUrl),
        _tokens = tokenStorage ?? TokenStorage();

  final ApiClient _api;
  final TokenStorage _tokens;

  Future<AuthSession> verifyBackupCode({
    required String challengeToken,
    required String code,
  }) async {
    final data = await _api.post('/auth/mfa/backup-code', body: {
      'challengeToken': challengeToken,
      'code': code.trim(),
    });
    final session = AuthSession.fromJson(data);
    await _tokens.save(
      accessToken: session.accessToken,
      refreshToken: session.refreshToken,
    );
    return session;
  }
}
