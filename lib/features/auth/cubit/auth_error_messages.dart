import '../../../core/api/api_exception.dart';

/// User-facing copy for backend auth refusals (`ApiException.code`).
abstract final class AuthErrorMessages {
  static const String sessionExpired =
      'Your setup session has expired. Sign in again to continue.';

  /// Banner message for a failed `POST /auth/login`.
  static String forLogin(ApiException e) {
    switch (e.code) {
      case 'ACCOUNT_LOCKED':
        return 'Your account is locked after too many attempts. '
            'Try again in 15 minutes.';
      case 'INVALID_CREDENTIALS':
      case 'SCHOOL_LOCKED':
      case 'CLIENT_NOT_ALLOWED':
        return e.message;
      case 'TERMS_NOT_ACCEPTED':
        return 'Accept the Terms & Privacy Policy to sign in.';
      case 'VALIDATION_ERROR':
        return 'Check your email and password and try again.';
      case ApiException.networkErrorCode:
        return e.message;
    }
    return _generic(e);
  }

  /// Banner message for first-time setup calls (reset / enrolment).
  static String forSetup(ApiException e) {
    switch (e.code) {
      case 'SAME_AS_TEMP':
        return 'Your new password must be different from the temporary one.';
      case 'SETUP_SESSION_EXPIRED':
        return sessionExpired;
      case 'MFA_INVALID_CODE':
        return 'That code is not valid. Check it and try again.';
      case 'EMAIL_CODE_RATE_LIMIT':
        return 'Please wait before requesting another code.';
      case 'ACCOUNT_LOCKED':
        return 'Your account is locked after too many attempts. '
            'Try again in 15 minutes.';
      case ApiException.networkErrorCode:
        return e.message;
    }
    return _generic(e);
  }

  static String _generic(ApiException e) {
    final status = e.statusCode;
    if (status == 429) {
      return 'Too many attempts. Please wait a few minutes and try again.';
    }
    if (status != null && status >= 500) {
      return 'Something went wrong on our side. Please try again in a moment.';
    }
    return e.message;
  }
}
