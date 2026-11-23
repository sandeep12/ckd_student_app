import 'package:equatable/equatable.dart';

/// The signed-in user, parsed leniently from the backend payload.
class AuthUser extends Equatable {
  const AuthUser({this.id, this.email, this.name, this.role});

  final String? id;
  final String? email;
  final String? name;
  final String? role;

  static AuthUser? tryParse(dynamic json) {
    if (json is! Map<String, dynamic>) return null;
    String? str(List<String> keys) {
      for (final k in keys) {
        final v = json[k];
        if (v is String && v.isNotEmpty) return v;
        if (v is num) return v.toString();
      }
      return null;
    }

    return AuthUser(
      id: str(['id', 'userId', 'uid']),
      email: str(['email', 'emailAddress']),
      name: str(['name', 'fullName', 'displayName', 'firstName']),
      role: str(['role', 'userRole', 'type']),
    );
  }

  @override
  List<Object?> get props => [id, email, name, role];
}

/// Result of a successful `POST /auth/login`.
///
/// The exact payload shape is not pinned down by the OpenAPI spec
/// (generic `{data, error}` envelope), so parsing is tolerant: tokens and
/// the user object are looked up under their common key spellings and the
/// raw payload is kept for anything else.
class AuthSession extends Equatable {
  const AuthSession({
    this.accessToken,
    this.refreshToken,
    this.user,
    this.mfaRequired = false,
    this.raw,
  });

  final String? accessToken;
  final String? refreshToken;
  final AuthUser? user;

  /// True when the backend answered with an MFA challenge instead of
  /// tokens (`/auth/mfa/verify` flow — not part of this build yet).
  final bool mfaRequired;

  final Map<String, dynamic>? raw;

  factory AuthSession.fromJson(dynamic json) {
    if (json is! Map<String, dynamic>) return const AuthSession();
    String? str(List<String> keys) {
      for (final k in keys) {
        final v = json[k];
        if (v is String && v.isNotEmpty) return v;
      }
      return null;
    }

    final tokens = json['tokens'];
    final nested = tokens is Map<String, dynamic> ? tokens : null;

    bool truthy(List<String> keys) => keys.any((k) => json[k] == true);

    return AuthSession(
      accessToken: str(['accessToken', 'access_token', 'token']) ??
          (nested == null
              ? null
              : AuthSession.fromJson(nested).accessToken),
      refreshToken: str(['refreshToken', 'refresh_token']) ??
          (nested == null
              ? null
              : AuthSession.fromJson(nested).refreshToken),
      user: AuthUser.tryParse(json['user'] ?? json['profile']),
      mfaRequired: truthy(['mfaRequired', 'mfa_required', 'requiresMfa']) ||
          str(['challenge', 'mfaToken', 'mfa_token']) != null,
      raw: json,
    );
  }

  @override
  List<Object?> get props =>
      [accessToken, refreshToken, user, mfaRequired, raw];
}
