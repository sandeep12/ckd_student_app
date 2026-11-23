import '../storage/token_storage.dart';
import 'api_client.dart';
import 'api_exception.dart';

/// Calls authenticated endpoints with the stored access token.
///
/// On a 401 it runs [refreshSession] once and retries. If that fails too,
/// [onSessionExpired] fires so the app can return to the login screen.
class AuthorizedApi {
  AuthorizedApi({
    required ApiClient apiClient,
    required TokenStorage tokenStorage,
    required Future<void> Function() refreshSession,
    this.onSessionExpired,
  })  : _api = apiClient,
        _tokens = tokenStorage,
        _refreshSession = refreshSession;

  final ApiClient _api;
  final TokenStorage _tokens;
  final Future<void> Function() _refreshSession;

  /// Set by the app shell; called when the session can't be recovered.
  void Function()? onSessionExpired;

  Future<dynamic> get(String path) =>
      _withRetry((token) => _api.get(path, accessToken: token));

  Future<dynamic> post(String path, {Object? body}) =>
      _withRetry((token) => _api.post(path, body: body, accessToken: token));

  Future<dynamic> _withRetry(
    Future<dynamic> Function(String? token) call,
  ) async {
    try {
      return await call(await _tokens.readAccessToken());
    } on ApiException catch (e) {
      if (e.statusCode != 401) rethrow;
      try {
        await _refreshSession();
      } on ApiException {
        onSessionExpired?.call();
        rethrow;
      }
      return call(await _tokens.readAccessToken());
    }
  }
}
