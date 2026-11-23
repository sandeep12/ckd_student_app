import '../../../core/api/authorized_api.dart';
import '../../../core/storage/token_storage.dart';
import 'models/student_profile.dart';

/// Student profile (`/student-profile`, `/auth/me`, `/auth/change-password`).
class ProfileRepository {
  ProfileRepository({
    required AuthorizedApi api,
    required TokenStorage tokenStorage,
  })  : _api = api,
        _tokens = tokenStorage;

  final AuthorizedApi _api;
  final TokenStorage _tokens;

  /// Profile plus the sign-in email. The email is best-effort: if
  /// `/auth/me` fails the profile still loads.
  Future<StudentProfile> fetchProfile() async {
    final profileFuture = _api.get('/student-profile');
    final emailFuture = _api
        .get('/auth/me')
        .then<String?>(
            (d) => d is Map<String, dynamic> ? d['email'] as String? : null)
        .catchError((Object _) => null);
    final data = await profileFuture;
    final profile = StudentProfile.fromJson(
      data is Map<String, dynamic> ? data : const {},
    );
    return profile.copyWith(email: await emailFuture);
  }

  /// Throws `ApiException` with `VALIDATION_ERROR` (field `rollNumber`).
  Future<StudentProfile> saveRollNumber(String rollNumber) async {
    final data = await _api.put(
      '/student-profile',
      body: {'rollNumber': rollNumber.trim()},
    );
    return StudentProfile.fromJson(
      data is Map<String, dynamic> ? data : const {},
    );
  }

  /// Keeps this device signed in by sending its refresh token; other
  /// sessions end. A wrong current password is a 400.
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final refreshToken = await _tokens.readRefreshToken();
    await _api.post('/auth/change-password', body: {
      'currentPassword': currentPassword,
      'newPassword': newPassword,
      if (refreshToken != null) 'refreshToken': refreshToken,
    });
  }
}
