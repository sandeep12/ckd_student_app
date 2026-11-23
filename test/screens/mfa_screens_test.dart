// Golden renders of the MFA screens for Figma comparison (review only).
//   flutter test --update-goldens test/screens/mfa_screens_test.dart
import 'dart:io';

import 'package:ckd_design_system/ckd_design_system.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'package:ckd_student_app/core/api/api_exception.dart';
import 'package:ckd_student_app/features/auth/cubit/backup_code_cubit.dart';
import 'package:ckd_student_app/features/auth/cubit/mfa_cubit.dart';
import 'package:ckd_student_app/features/auth/data/auth_repository.dart';
import 'package:ckd_student_app/features/auth/data/mfa_backup_repository.dart';
import 'package:ckd_student_app/features/auth/data/models/auth_models.dart';
import 'package:ckd_student_app/features/auth/view/backup_code_page.dart';
import 'package:ckd_student_app/features/auth/view/mfa_method_page.dart';
import 'package:ckd_student_app/features/auth/view/mfa_verify_page.dart';

const _challenge = MfaChallenge(
  challengeToken: 'preview',
  method: 'email',
  user: AuthUser(email: 'alex.ramos@horizon.edu.ph'),
);

String _errorCode = 'MFA_INVALID_CODE';

class _FakeAuthRepository extends AuthRepository {
  @override
  Future<AuthSession> verifyMfa(
      {required String challengeToken, required String code}) async {
    throw ApiException(message: '', code: _errorCode, statusCode: 401);
  }
}

class _FakeBackupRepository extends MfaBackupRepository {
  @override
  Future<AuthSession> verifyBackupCode(
      {required String challengeToken, required String code}) async {
    throw const ApiException(
        message: '', code: 'BACKUP_CODE_INVALID', statusCode: 401);
  }
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

Future<void> _pump(WidgetTester tester, Widget home, Size size) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(RepositoryProvider<AuthRepository>(
    create: (_) => _FakeAuthRepository(),
    child: MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: CkdTheme.light(),
      home: home,
    ),
  ));
  await tester.pump(const Duration(milliseconds: 500));
}

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 5; i++) {
    await tester.pump(const Duration(milliseconds: 200));
  }
}

void main() {
  setUpAll(_loadFonts);

  const sizes = {'web': Size(1440, 900), 'mobile': Size(390, 844)};

  sizes.forEach((suffix, size) {
    MfaCubit mfa(WidgetTester t) =>
        BlocProvider.of<MfaCubit>(t.element(find.byType(DsOtpInput)));

    testWidgets('verify default $suffix', (t) async {
      await _pump(t, const MfaVerifyPage(challenge: _challenge), size);
      await expectLater(find.byType(MaterialApp),
          matchesGoldenFile('goldens/mfa/verify_default_$suffix.png'));
    });

    testWidgets('verify incomplete $suffix', (t) async {
      await _pump(t, const MfaVerifyPage(challenge: _challenge), size);
      mfa(t).codeChanged('123');
      await mfa(t).submit();
      await _settle(t);
      await expectLater(find.byType(MaterialApp),
          matchesGoldenFile('goldens/mfa/verify_incomplete_$suffix.png'));
    });

    for (final entry in {
      'invalid': 'MFA_INVALID_CODE',
      'expired': 'MFA_CHALLENGE_EXPIRED',
      'locked': 'ACCOUNT_LOCKED',
      'network': ApiException.networkErrorCode,
    }.entries) {
      testWidgets('verify ${entry.key} $suffix', (t) async {
        _errorCode = entry.value;
        await _pump(t, const MfaVerifyPage(challenge: _challenge), size);
        mfa(t).codeChanged('123456');
        await t.runAsync(() => mfa(t).submit());
        await _settle(t);
        await expectLater(find.byType(MaterialApp),
            matchesGoldenFile('goldens/mfa/verify_${entry.key}_$suffix.png'));
      });
    }

    testWidgets('method selection $suffix', (t) async {
      await _pump(t, const MfaMethodPage(challenge: _challenge), size);
      await expectLater(find.byType(MaterialApp),
          matchesGoldenFile('goldens/mfa/method_$suffix.png'));
    });

    testWidgets('backup default $suffix', (t) async {
      await _pump(
          t,
          BackupCodePage(
              challenge: _challenge, repository: _FakeBackupRepository()),
          size);
      await expectLater(find.byType(MaterialApp),
          matchesGoldenFile('goldens/mfa/backup_default_$suffix.png'));
    });

    testWidgets('backup error $suffix', (t) async {
      await _pump(
          t,
          BackupCodePage(
              challenge: _challenge, repository: _FakeBackupRepository()),
          size);
      await t.enterText(find.byType(TextField), 'ABCD-1234');
      final cubit = BlocProvider.of<BackupCodeCubit>(
          t.element(find.byType(TextField)));
      await t.runAsync(cubit.submit);
      await _settle(t);
      await expectLater(find.byType(MaterialApp),
          matchesGoldenFile('goldens/mfa/backup_error_$suffix.png'));
    });
  });
}
