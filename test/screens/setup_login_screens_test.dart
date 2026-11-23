// Review goldens: first-login setup + login error states (not a regression
// suite). Regenerate with --update-goldens.
import 'dart:io';
import 'dart:typed_data';

import 'package:ckd_design_system/ckd_design_system.dart';
import 'package:ckd_student_app/core/api/api_exception.dart';
import 'package:ckd_student_app/features/auth/data/auth_repository.dart';
import 'package:ckd_student_app/features/auth/data/models/auth_models.dart';
import 'package:ckd_student_app/features/auth/view/create_password_page.dart';
import 'package:ckd_student_app/features/auth/view/login_page.dart';
import 'package:ckd_student_app/features/auth/view/mfa_enrol_page.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

const _user = AuthUser(email: 'alex.ramos@horizon.edu.ph');
const _session = AuthSession(accessToken: 'a', refreshToken: 'r', user: _user);
const _ticket = SetupTicket(setupToken: 'setup', user: _user);

class _FakeRepo implements AuthRepository {
  _FakeRepo({this.loginError, this.resetError, this.confirmError, this.startError});
  final ApiException? loginError, resetError, confirmError, startError;

  @override
  Future<LoginOutcome> login({
    required String email,
    required String password,
    required bool termsAccepted,
  }) async {
    if (loginError != null) throw loginError!;
    return const LoginAuthenticated(_session);
  }

  @override
  Future<LoginOutcome> resetPassword({
    required String setupToken,
    required String password,
  }) async {
    if (resetError != null) throw resetError!;
    return const LoginAuthenticated(_session);
  }

  @override
  Future<void> startMfaEnrolment({
    required String setupToken,
    String method = 'email',
  }) async {
    if (startError != null) throw startError!;
  }

  @override
  Future<MfaEnrolmentResult> confirmMfaEnrolment({
    required String setupToken,
    required String code,
  }) async {
    if (confirmError != null) throw confirmError!;
    return const MfaEnrolmentResult(
      backupCodes: ['4F7K-2M9P', '8QXR-3T6W', 'J2NB-7D4H', 'C9VL-5A8E',
        'H6TZ-1K3S', 'P4WM-9R2Y', 'B7EQ-6N5G', 'X3DF-8J1U'],
      session: _session,
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Future<void> _loadFonts() async {
  final root = Directory('../ckd_design_system/assets/fonts');
  final loader = FontLoader('packages/ckd_design_system/Geist');
  for (final f in ['Geist-Regular.ttf', 'Geist-Bold.ttf', 'Geist-ExtraBold.ttf']) {
    final bytes = File('${root.path}/$f').readAsBytesSync();
    loader.addFont(Future.value(ByteData.view(Uint8List.fromList(bytes).buffer)));
  }
  await loader.load();
}

const _sizes = {'web': Size(1440, 900), 'mobile': Size(390, 844)};

Future<void> _pump(WidgetTester t, Size size, AuthRepository repo, Widget home) async {
  t.view.physicalSize = size;
  t.view.devicePixelRatio = 1;
  addTearDown(t.view.reset);
  await t.pumpWidget(RepositoryProvider<AuthRepository>.value(
    value: repo,
    child: MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: CkdTheme.light(),
      home: home,
    ),
  ));
  await t.pumpAndSettle();
}

Finder _field(int i) => find.byType(EditableText).at(i);

Future<void> _tap(WidgetTester t, String text) async {
  final f = find.text(text).last;
  await t.ensureVisible(f);
  await t.tap(f);
  await t.pumpAndSettle();
}

Future<void> _shot(String name) =>
    expectLater(find.byType(MaterialApp), matchesGoldenFile('goldens/setup_login/$name.png'));

typedef _Scenario = Future<void> Function(WidgetTester t);

void _case(String name, AuthRepository Function() repo, Widget home, [_Scenario? act]) {
  for (final e in _sizes.entries) {
    testWidgets('$name ${e.key}', (t) async {
      await _pump(t, e.value, repo(), home);
      if (act != null) await act(t);
      await _shot('${name}_${e.key}');
    });
  }
}

void main() {
  setUpAll(_loadFonts);

  // Create password
  const cp = CreatePasswordPage(ticket: _ticket);
  Future<void> fill(WidgetTester t, String a, String b, {bool submit = true}) async {
    await t.enterText(_field(0), a);
    await t.enterText(_field(1), b);
    await t.pumpAndSettle();
    if (submit) await _tap(t, 'Set password and continue');
  }

  _case('create_password_default', _FakeRepo.new, cp);
  _case('create_password_weak', _FakeRepo.new, cp, (t) => fill(t, 'abc', 'abc'));
  _case('create_password_mismatch', _FakeRepo.new, cp,
      (t) => fill(t, 'Str0ng!pass', 'Str0ng!pasx'));
  _case('create_password_same_as_temp',
      () => _FakeRepo(resetError: const ApiException(message: 'x', code: 'SAME_AS_TEMP', statusCode: 400)),
      cp, (t) => fill(t, 'Str0ng!pass', 'Str0ng!pass'));
  _case('create_password_could_not_save',
      () => _FakeRepo(resetError: const ApiException(message: 'x', code: 'INTERNAL', statusCode: 500)),
      cp, (t) => fill(t, 'Str0ng!pass', 'Str0ng!pass'));
  _case('create_password_expired',
      () => _FakeRepo(resetError: const ApiException(message: 'x', code: 'SETUP_SESSION_EXPIRED', statusCode: 401)),
      cp, (t) => fill(t, 'Str0ng!pass', 'Str0ng!pass'));

  // MFA enrolment
  const mfa = MfaEnrolPage(ticket: _ticket);
  Future<void> toCode(WidgetTester t) => _tap(t, 'Email me a code');
  _case('mfa_intro', _FakeRepo.new, mfa);
  _case('mfa_code_sent', _FakeRepo.new, mfa, toCode);
  _case('mfa_incomplete', _FakeRepo.new, mfa, (t) async {
    await toCode(t);
    await t.enterText(_field(0), '123');
    await t.pumpAndSettle();
    await _tap(t, 'Verify and continue');
  });
  _case('mfa_invalid',
      () => _FakeRepo(confirmError: const ApiException(message: 'x', code: 'MFA_INVALID_CODE', statusCode: 400)),
      mfa, (t) async {
    await toCode(t);
    await t.enterText(_field(0), '123456');
    await t.pumpAndSettle();
  });
  _case('mfa_expired',
      () => _FakeRepo(confirmError: const ApiException(message: 'x', code: 'SETUP_SESSION_EXPIRED', statusCode: 401)),
      mfa, (t) async {
    await toCode(t);
    await t.enterText(_field(0), '123456');
    await t.pumpAndSettle();
  });
  _case('mfa_backup_codes', _FakeRepo.new, mfa, (t) async {
    await toCode(t);
    await t.enterText(_field(0), '123456');
    await t.pumpAndSettle();
  });

  // Login
  const login = LoginPage();
  Future<void> signIn(WidgetTester t, {bool terms = true}) async {
    await t.enterText(_field(0), 'alex.ramos@horizon.edu.ph');
    await t.enterText(_field(1), 'wrong-pass');
    await t.pumpAndSettle();
    if (terms) {
      await _tap(t, 'I agree to the Terms & Privacy Policy');
      final cta = find.text('Log in').evaluate().isNotEmpty ? 'Log in' : 'Sign in';
      await _tap(t, cta);
    }
  }

  _case('login_default', _FakeRepo.new, login);
  _case('login_invalid_credentials',
      () => _FakeRepo(loginError: const ApiException(
          message: 'Incorrect email or password.', code: 'INVALID_CREDENTIALS', statusCode: 401)),
      login, signIn);
  _case('login_locked',
      () => _FakeRepo(loginError: const ApiException(message: 'x', code: 'ACCOUNT_LOCKED', statusCode: 423)),
      login, signIn);
  _case('login_terms_not_accepted', _FakeRepo.new, login, (t) => signIn(t, terms: false));
  _case('login_terms_not_accepted_server',
      () => _FakeRepo(loginError: const ApiException(message: 'x', code: 'TERMS_NOT_ACCEPTED', statusCode: 400)),
      login, signIn);
}
