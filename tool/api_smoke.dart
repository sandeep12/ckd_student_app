// Live smoke test against the local backend:
//   dart run tool/api_smoke.dart
// Verifies the envelope/error handling in ApiClient against /auth/login.
import 'dart:io';

import 'package:ckd_student_app/core/api/api_client.dart';
import 'package:ckd_student_app/core/api/api_exception.dart';

Future<void> main() async {
  final client = ApiClient(baseUrl: 'http://localhost:3001');
  var failures = 0;

  Future<void> expectError(
    String name,
    Map<String, Object> body,
    String expectedCode, {
    bool expectFieldErrors = false,
  }) async {
    try {
      await client.post('/auth/login', body: body);
      stderr.writeln('FAIL $name: expected $expectedCode, got success');
      failures++;
    } on ApiException catch (e) {
      final codeOk = e.code == expectedCode;
      final fieldsOk = !expectFieldErrors || e.fieldErrors.isNotEmpty;
      if (codeOk && fieldsOk) {
        stdout.writeln(
            'PASS $name: $expectedCode "${e.message}" ${e.fieldErrors}');
      } else {
        stderr.writeln('FAIL $name: got ${e.code} ${e.fieldErrors}');
        failures++;
      }
    }
  }

  await expectError('missing fields', {}, 'VALIDATION_ERROR',
      expectFieldErrors: true);
  await expectError(
    'terms not accepted',
    {'email': 'a@b.com', 'password': 'x', 'termsAccepted': false},
    'TERMS_NOT_ACCEPTED',
  );
  await expectError(
    'invalid credentials',
    {'email': 'a@b.com', 'password': 'x', 'termsAccepted': true},
    'INVALID_CREDENTIALS',
  );

  client.close();
  exit(failures == 0 ? 0 : 1);
}
