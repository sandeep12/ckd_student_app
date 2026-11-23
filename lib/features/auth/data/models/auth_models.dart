import 'package:equatable/equatable.dart';

/// The signed-in (or signing-in) user, as returned by the backend.
class AuthUser extends Equatable {
  const AuthUser({
    this.id,
    this.email,
    this.schoolId,
    this.schoolName,
    this.permissions = const [],
    this.mfaMethod,
  });

  final String? id;
  final String? email;
  final String? schoolId;
  final String? schoolName;
  final List<String> permissions;
  final String? mfaMethod;

  static AuthUser? tryParse(dynamic json) {
    if (json is! Map<String, dynamic>) return null;
    return AuthUser(
      id: json['id'] as String?,
      email: json['email'] as String?,
      schoolId: json['schoolId'] as String?,
      schoolName: json['schoolName'] as String?,
      permissions: json['permissions'] is List
          ? (json['permissions'] as List).whereType<String>().toList()
          : const [],
      mfaMethod: json['mfaMethod'] as String?,
    );
  }

  /// `a•••••••s@horizon.edu.ph`-style masking for the verify screen.
  String? get maskedEmail {
    final email = this.email;
    if (email == null) return null;
    final at = email.indexOf('@');
    if (at <= 1) return email;
    final local = email.substring(0, at);
    final domain = email.substring(at);
    if (local.length <= 2) return '${local[0]}•$domain';
    return '${local[0]}${'•' * (local.length - 2)}'
        '${local[local.length - 1]}$domain';
  }

  @override
  List<Object?> get props =>
      [id, email, schoolId, schoolName, permissions, mfaMethod];
}

/// An MFA challenge returned by `POST /auth/login`
/// (`data.status == "mfa_required"`).
class MfaChallenge extends Equatable {
  const MfaChallenge({
    required this.challengeToken,
    this.method,
    this.expiresAt,
    this.user,
  });

  final String challengeToken;

  /// Delivery method, e.g. `email`.
  final String? method;

  final DateTime? expiresAt;
  final AuthUser? user;

  static MfaChallenge? tryParse(dynamic json) {
    if (json is! Map<String, dynamic>) return null;
    final token = json['challengeToken'];
    if (token is! String || token.isEmpty) return null;
    return MfaChallenge(
      challengeToken: token,
      method: json['method'] as String?,
      expiresAt: json['expiresAt'] is String
          ? DateTime.tryParse(json['expiresAt'] as String)
          : null,
      user: AuthUser.tryParse(json['user']),
    );
  }

  @override
  List<Object?> get props => [challengeToken, method, expiresAt, user];
}

/// An authenticated session (`data.session` from login or MFA verify).
class AuthSession extends Equatable {
  const AuthSession({
    this.user,
    this.accessToken,
    this.accessTokenExpiresAt,
    this.refreshToken,
    this.refreshTokenExpiresAt,
  });

  final AuthUser? user;
  final String? accessToken;
  final DateTime? accessTokenExpiresAt;
  final String? refreshToken;
  final DateTime? refreshTokenExpiresAt;

  factory AuthSession.fromJson(dynamic json) {
    if (json is! Map<String, dynamic>) return const AuthSession();
    DateTime? date(String key) =>
        json[key] is String ? DateTime.tryParse(json[key] as String) : null;
    return AuthSession(
      user: AuthUser.tryParse(json['user']),
      accessToken: json['accessToken'] as String?,
      accessTokenExpiresAt: date('accessTokenExpiresAt'),
      refreshToken: json['refreshToken'] as String?,
      refreshTokenExpiresAt: date('refreshTokenExpiresAt'),
    );
  }

  @override
  List<Object?> get props => [
        user,
        accessToken,
        accessTokenExpiresAt,
        refreshToken,
        refreshTokenExpiresAt,
      ];
}

/// Result of `POST /auth/login`: either a session or an MFA challenge.
sealed class LoginOutcome {
  const LoginOutcome();

  static LoginOutcome fromJson(dynamic json) {
    if (json is Map<String, dynamic>) {
      if (json['status'] == 'mfa_required') {
        final challenge = MfaChallenge.tryParse(json['challenge']);
        if (challenge != null) return LoginMfaRequired(challenge);
      }
      final session = json['session'];
      if (session != null) {
        return LoginAuthenticated(AuthSession.fromJson(session));
      }
    }
    // Fall back to treating the payload itself as the session.
    return LoginAuthenticated(AuthSession.fromJson(json));
  }
}

class LoginAuthenticated extends LoginOutcome {
  const LoginAuthenticated(this.session);
  final AuthSession session;
}

class LoginMfaRequired extends LoginOutcome {
  const LoginMfaRequired(this.challenge);
  final MfaChallenge challenge;
}
