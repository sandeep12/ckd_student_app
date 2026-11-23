import 'package:bloc_test/bloc_test.dart';
import 'package:ckd_student_app/app.dart';
import 'package:ckd_student_app/core/api/api_exception.dart';
import 'package:ckd_student_app/features/auth/cubit/login_cubit.dart';
import 'package:ckd_student_app/features/auth/cubit/mfa_cubit.dart';
import 'package:ckd_student_app/features/auth/data/auth_repository.dart';
import 'package:ckd_student_app/features/auth/data/models/auth_models.dart';
import 'package:flutter_test/flutter_test.dart';

const _challenge = MfaChallenge(
  challengeToken: 'challenge-token',
  method: 'email',
  user: AuthUser(email: 'alex.ramos@horizon.edu.ph'),
);

const _session = AuthSession(
  accessToken: 'access',
  refreshToken: 'refresh',
  user: AuthUser(email: 'alex.ramos@horizon.edu.ph', schoolName: 'demo'),
);

class _FakeAuthRepository implements AuthRepository {
  _FakeAuthRepository({this.loginHandler, this.verifyHandler});

  final Future<LoginOutcome> Function()? loginHandler;
  final Future<AuthSession> Function()? verifyHandler;

  @override
  Future<LoginOutcome> login({
    required String email,
    required String password,
    required bool termsAccepted,
  }) =>
      loginHandler?.call() ??
      Future.value(const LoginAuthenticated(_session));

  @override
  Future<AuthSession> verifyMfa({
    required String challengeToken,
    required String code,
  }) =>
      verifyHandler?.call() ?? Future.value(_session);

  @override
  Future<MfaChallenge?> resendMfa({required String challengeToken}) async =>
      const MfaChallenge(challengeToken: 'new-token');

  @override
  Future<AuthUser?> me() async => null;

  @override
  Future<AuthSession> refresh() async => _session;

  @override
  Future<void> logout() async {}
}

LoginCubit _loginCubit({Future<LoginOutcome> Function()? loginHandler}) =>
    LoginCubit(
      authRepository: _FakeAuthRepository(loginHandler: loginHandler),
    );

const _validSeed = LoginState(
  termsAccepted: true,
  email: 'alex.ramos@horizon.edu.ph',
  password: 'secret',
);

void main() {
  group('LoginCubit', () {
    test('initial state cannot submit', () {
      expect(_loginCubit().state.canSubmit, isFalse);
    });

    blocTest<LoginCubit, LoginState>(
      'submit with invalid input turns validation on',
      build: _loginCubit,
      seed: () => const LoginState(termsAccepted: true, email: 'not-an-email'),
      act: (cubit) => cubit.submit(),
      expect: () => [
        const LoginState(
          termsAccepted: true,
          email: 'not-an-email',
          showValidation: true,
        ),
      ],
    );

    blocTest<LoginCubit, LoginState>(
      'authenticated login emits success with the session',
      build: _loginCubit,
      seed: () => _validSeed,
      act: (cubit) => cubit.submit(),
      expect: () => [
        isA<LoginState>()
            .having((s) => s.status, 'status', LoginStatus.submitting),
        isA<LoginState>()
            .having((s) => s.status, 'status', LoginStatus.success)
            .having((s) => s.session, 'session', _session),
      ],
    );

    blocTest<LoginCubit, LoginState>(
      'mfa_required login emits the challenge',
      build: () => _loginCubit(
        loginHandler: () async => const LoginMfaRequired(_challenge),
      ),
      seed: () => _validSeed,
      act: (cubit) => cubit.submit(),
      expect: () => [
        isA<LoginState>()
            .having((s) => s.status, 'status', LoginStatus.submitting),
        isA<LoginState>()
            .having((s) => s.status, 'status', LoginStatus.mfaRequired)
            .having((s) => s.challenge, 'challenge', _challenge),
      ],
    );

    blocTest<LoginCubit, LoginState>(
      'INVALID_CREDENTIALS shows the error banner',
      build: () => _loginCubit(
        loginHandler: () => throw const ApiException(
          message: 'Email or password is incorrect',
          code: 'INVALID_CREDENTIALS',
          statusCode: 401,
        ),
      ),
      seed: () => _validSeed,
      act: (cubit) => cubit.submit(),
      expect: () => [
        isA<LoginState>()
            .having((s) => s.status, 'status', LoginStatus.submitting),
        isA<LoginState>()
            .having((s) => s.status, 'status', LoginStatus.failure)
            .having((s) => s.errorMessage, 'errorMessage',
                'Email or password is incorrect'),
      ],
    );

    blocTest<LoginCubit, LoginState>(
      'VALIDATION_ERROR maps issues onto the fields',
      build: () => _loginCubit(
        loginHandler: () => throw const ApiException(
          message: 'Invalid input',
          code: 'VALIDATION_ERROR',
          statusCode: 400,
          fieldErrors: {'email': 'Invalid email'},
        ),
      ),
      seed: () => _validSeed,
      act: (cubit) => cubit.submit(),
      expect: () => [
        isA<LoginState>()
            .having((s) => s.status, 'status', LoginStatus.submitting),
        isA<LoginState>()
            .having((s) => s.status, 'status', LoginStatus.idle)
            .having((s) => s.emailError, 'emailError', 'Invalid email'),
      ],
    );

    blocTest<LoginCubit, LoginState>(
      'network failure shows the unavailable banner',
      build: () => _loginCubit(
        loginHandler: () => throw const ApiException.network(),
      ),
      seed: () => _validSeed,
      act: (cubit) => cubit.submit(),
      expect: () => [
        isA<LoginState>()
            .having((s) => s.status, 'status', LoginStatus.submitting),
        isA<LoginState>()
            .having((s) => s.status, 'status', LoginStatus.failure)
            .having((s) => s.errorMessage, 'errorMessage',
                contains('reach the server')),
      ],
    );
  });

  group('MfaCubit', () {
    MfaCubit cubit({Future<AuthSession> Function()? verifyHandler}) =>
        MfaCubit(
          authRepository: _FakeAuthRepository(verifyHandler: verifyHandler),
          challenge: _challenge,
        );

    blocTest<MfaCubit, MfaState>(
      'incomplete code shows the invalid-input state',
      build: cubit,
      act: (c) {
        c.codeChanged('123');
        return c.submit();
      },
      expect: () => [
        isA<MfaState>().having((s) => s.code, 'code', '123'),
        isA<MfaState>()
            .having((s) => s.showIncomplete, 'showIncomplete', isTrue),
      ],
    );

    blocTest<MfaCubit, MfaState>(
      'correct code verifies and carries the session',
      build: cubit,
      act: (c) {
        c.codeChanged('369964');
        return c.submit();
      },
      expect: () => [
        isA<MfaState>().having((s) => s.code, 'code', '369964'),
        isA<MfaState>()
            .having((s) => s.status, 'status', MfaStatus.verifying),
        isA<MfaState>()
            .having((s) => s.status, 'status', MfaStatus.success)
            .having((s) => s.session, 'session', _session),
      ],
    );

    blocTest<MfaCubit, MfaState>(
      'incorrect code shows the error and clears the input',
      build: () => cubit(
        verifyHandler: () => throw const ApiException(
          message: 'That code is not right. Check the email and try again.',
          code: 'MFA_CODE_INCORRECT',
          statusCode: 401,
        ),
      ),
      act: (c) {
        c.codeChanged('000000');
        return c.submit();
      },
      expect: () => [
        isA<MfaState>().having((s) => s.code, 'code', '000000'),
        isA<MfaState>()
            .having((s) => s.status, 'status', MfaStatus.verifying),
        isA<MfaState>()
            .having((s) => s.status, 'status', MfaStatus.failure)
            .having((s) => s.code, 'code', isEmpty)
            .having((s) => s.errorMessage, 'errorMessage', isNotNull),
      ],
    );

    blocTest<MfaCubit, MfaState>(
      'resend swaps in the new challenge and notes it',
      build: cubit,
      act: (c) => c.resend(),
      expect: () => [
        isA<MfaState>()
            .having((s) => s.status, 'status', MfaStatus.resending),
        isA<MfaState>()
            .having((s) => s.status, 'status', MfaStatus.idle)
            .having((s) => s.challenge.challengeToken, 'token', 'new-token')
            .having((s) => s.infoMessage, 'infoMessage', isNotNull),
      ],
    );
  });

  group('models', () {
    test('masked email matches the design pattern', () {
      const user = AuthUser(email: 'alex.ramos@horizon.edu.ph');
      expect(user.maskedEmail, 'a••••••••s@horizon.edu.ph');
    });

    test('LoginOutcome parses the live mfa_required payload', () {
      final outcome = LoginOutcome.fromJson({
        'status': 'mfa_required',
        'challenge': {
          'challengeToken': 'tok',
          'method': 'email',
          'expiresAt': '2026-11-23T13:22:55.731Z',
          'user': {'email': 'student1-dms1@yopmail.com'},
        },
      });
      expect(outcome, isA<LoginMfaRequired>());
      expect((outcome as LoginMfaRequired).challenge.challengeToken, 'tok');
    });

    test('LoginOutcome parses the live authenticated payload', () {
      final outcome = LoginOutcome.fromJson({
        'status': 'authenticated',
        'session': {
          'user': {'email': 'student1-dms1@yopmail.com'},
          'accessToken': 'a',
          'refreshToken': 'r',
        },
      });
      expect(outcome, isA<LoginAuthenticated>());
      final session = (outcome as LoginAuthenticated).session;
      expect(session.accessToken, 'a');
      expect(session.user?.email, 'student1-dms1@yopmail.com');
    });
  });

  group('LoginPage', () {
    testWidgets('renders the student sign in form', (tester) async {
      await tester.pumpWidget(
        CkdStudentApp(authRepository: _FakeAuthRepository()),
      );
      await tester.pump();

      expect(find.text('Student sign in'), findsOneWidget);
      expect(find.text('Email ID'), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);
      expect(find.text('Forgot password?'), findsOneWidget);
    });
  });
}
