import 'dart:io';

import 'package:ckd_design_system/ckd_design_system.dart';
import 'package:ckd_student_app/core/api/api_exception.dart';
import 'package:ckd_student_app/features/auth/cubit/forgot_password_cubit.dart';
import 'package:ckd_student_app/features/auth/data/password_reset_repository.dart';
import 'package:ckd_student_app/features/auth/view/check_email_page.dart';
import 'package:ckd_student_app/features/auth/view/forgot_password_page.dart';
import 'package:ckd_student_app/features/auth/view/reset_success_page.dart';
import 'package:ckd_student_app/features/auth/view/set_new_password_page.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

class _FakeRepo implements PasswordResetRepository {
  _FakeRepo({this.resetError});
  final ApiException? resetError;

  @override
  Future<void> requestReset({required String email}) async {}

  @override
  Future<void> resetPassword(
      {required String token, required String password}) async {
    if (resetError != null) throw resetError!;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      super.noSuchMethod(invocation);
}

Future<void> _loadFonts() async {
  const dir = '../ckd_design_system/assets/fonts';
  final loader = FontLoader('packages/ckd_design_system/Geist');
  for (final f in ['Geist-Regular', 'Geist-Bold', 'Geist-ExtraBold']) {
    final bytes = File('$dir/$f.ttf').readAsBytesSync();
    loader.addFont(Future.value(ByteData.view(bytes.buffer)));
  }
  await loader.load();
}

const _sizes = {'web': Size(1440, 900), 'mobile': Size(390, 844)};

Widget _app(Widget home) => MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: CkdTheme.light(),
      home: home,
    );

Future<void> _pushRoute(WidgetTester tester, Route<void> route) async {
  await tester.pumpWidget(_app(Builder(
    builder: (context) => Scaffold(
      body: Center(
        child: TextButton(
          onPressed: () => Navigator.of(context).push(route),
          child: const Text('go'),
        ),
      ),
    ),
  )));
  await tester.tap(find.text('go'));
  await tester.pumpAndSettle();
}

Future<void> _shot(WidgetTester tester, String name) async {
  await tester.pumpAndSettle();
  await expectLater(find.byType(MaterialApp),
      matchesGoldenFile('goldens/forgot_password/$name.png'));
}

void main() {
  setUpAll(_loadFonts);

  for (final entry in _sizes.entries) {
    final v = entry.key;
    group(v, () {
      setUp(() {
        final view =
            TestWidgetsFlutterBinding.instance.platformDispatcher.implicitView!;
        view.physicalSize = entry.value;
        view.devicePixelRatio = 1;
      });
      tearDown(() {
        final view =
            TestWidgetsFlutterBinding.instance.platformDispatcher.implicitView!;
        view.resetPhysicalSize();
        view.resetDevicePixelRatio();
      });

      testWidgets('forgot default', (tester) async {
        await tester.pumpWidget(_app(const ForgotPasswordPage()));
        await _shot(tester, '${v}_forgot_default');
      });

      testWidgets('forgot empty error', (tester) async {
        await tester.pumpWidget(_app(const ForgotPasswordPage()));
        await tester.tap(find.text('Send reset link'));
        await _shot(tester, '${v}_forgot_error_empty');
      });

      testWidgets('forgot invalid', (tester) async {
        await tester.pumpWidget(_app(const ForgotPasswordPage()));
        await tester.enterText(find.byType(TextField).first, 'alex.ramos@');
        await tester.tap(find.text('Send reset link'));
        await _shot(tester, '${v}_forgot_error_invalid');
      });

      testWidgets('forgot filled', (tester) async {
        await tester.pumpWidget(_app(
            const ForgotPasswordPage(initialEmail: 'alex.ramos@horizon.edu.ph')));
        await _shot(tester, '${v}_forgot_filled');
      });

      testWidgets('check email (cooldown)', (tester) async {
        final repo = _FakeRepo();
        final cubit = ForgotPasswordCubit(repository: repo)
          ..emailChanged('alex.ramos@horizon.edu.ph');
        await tester.runAsync(cubit.submit);
        await _pushRoute(
            tester, CheckEmailPage.route(cubit: cubit, repository: repo));
        await _shot(tester, '${v}_check_email');
        await cubit.close();
      });

      Future<void> openSet(WidgetTester tester, {ApiException? err}) =>
          _pushRoute(
              tester,
              SetNewPasswordPage.route(
                  repository: _FakeRepo(resetError: err), token: 'tok123'));

      testWidgets('set default', (tester) async {
        await openSet(tester);
        await _shot(tester, '${v}_set_default');
      });

      testWidgets('set default (no deep-link token)', (tester) async {
        await _pushRoute(
            tester, SetNewPasswordPage.route(repository: _FakeRepo()));
        await _shot(tester, '${v}_set_default_paste_link');
      });

      testWidgets('set weak', (tester) async {
        await openSet(tester);
        await tester.enterText(find.byType(TextField).at(0), 'abc');
        await tester.enterText(find.byType(TextField).at(1), 'abc');
        await tester.ensureVisible(find.text('Update password'));
        await tester.tap(find.text('Update password'));
        await _shot(tester, '${v}_set_weak');
      });

      testWidgets('set mismatch', (tester) async {
        await openSet(tester);
        await tester.enterText(find.byType(TextField).at(0), 'Strong#Pass1');
        await tester.enterText(find.byType(TextField).at(1), 'Strong#Pass2');
        await tester.ensureVisible(find.text('Update password'));
        await tester.tap(find.text('Update password'));
        await _shot(tester, '${v}_set_mismatch');
      });

      testWidgets('set link expired', (tester) async {
        await openSet(tester,
            err: const ApiException(
                message: 'This reset link is invalid or has expired.',
                code: PasswordResetRepository.tokenInvalidCode));
        await tester.enterText(find.byType(TextField).at(0), 'Strong#Pass1');
        await tester.enterText(find.byType(TextField).at(1), 'Strong#Pass1');
        await tester.ensureVisible(find.text('Update password'));
        await tester.tap(find.text('Update password'));
        await _shot(tester, '${v}_set_link_expired');
      });

      testWidgets('reset success', (tester) async {
        await _pushRoute(tester, ResetSuccessPage.route());
        await _shot(tester, '${v}_reset_success');
      });
    });
  }
}
