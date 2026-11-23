/// Error thrown by [ApiClient] for failed requests.
///
/// The backend wraps every response in `{data, error, code, details}`;
/// validation failures carry `details.issues: [{path, message}]`.
class ApiException implements Exception {
  const ApiException({
    required this.message,
    required this.code,
    this.statusCode,
    this.fieldErrors = const {},
  });

  const ApiException.network()
      : this(
          message: 'We can’t reach the server right now. '
              'Check your connection and try again.',
          code: networkErrorCode,
        );

  final String message;

  /// Backend error code, e.g. `INVALID_CREDENTIALS`, `VALIDATION_ERROR`,
  /// `TERMS_NOT_ACCEPTED`, `ACCOUNT_LOCKED` — or [networkErrorCode] when
  /// the server could not be reached at all.
  final String code;

  final int? statusCode;

  /// Field path → message, from `details.issues` on `VALIDATION_ERROR`.
  final Map<String, String> fieldErrors;

  static const String networkErrorCode = 'NETWORK_UNAVAILABLE';

  @override
  String toString() => 'ApiException($code, $statusCode): $message';
}
