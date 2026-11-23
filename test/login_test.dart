import 'package:bloc_test/bloc_test.dart';
import 'package:ckd_student_app/app.dart';
import 'package:ckd_student_app/core/api/api_exception.dart';
import 'package:ckd_student_app/features/auth/cubit/login_cubit.dart';
import 'package:ckd_student_app/features/auth/data/auth_repository.dart';
import 'package:ckd_student_app/features/auth/data/models/auth_models.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeAuthRepository implements AuthRepository {
  _FakeAuthRepository({this.loginHandler});

  final Future<AuthSession> Function()? loginHandler;

  @override
  Future<AuthSession> login({
    required String email,
    required String password,
    required bool termsAccepted,
  }) =>
      loginHandler?.call() ??
      Future.value(const AuthSession(accessToken: 'token'));

  @override
  Future<AuthUser?> me() async => null;

  @override
  Future<AuthSession> refresh() async => const AuthSession();

  @override
  Future<void> logout() async {}
}

LoginCubit _cubit({Future<AuthSession> Function()? loginHandler}) =>
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
      expect(_cubit().state.canSubmit, isFalse);
    });

    blocTest<LoginCubit, LoginState>(
      'submit with invalid input turns validation on',
      build: _cubit,
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
      'successful login emits success with the user',
      build: () => _cubit(
        loginHandler: () async => const AuthSession(
          accessToken: 't',
          user: AuthUser(name: 'Alex Ramos'),
        ),
      ),
      seed: () => _validSeed,
      act: (cubit) => cubit.submit(),
      expect: () => [
        isA<LoginState>()
            .having((s) => s.status, 'status', LoginStatus.submitting),
        isA<LoginState>()
            .having((s) => s.status, 'status', LoginStatus.success)
            .having((s) => s.user?.name, 'user.name', 'Alex Ramos'),
      ],
    );

    blocTest<LoginCubit, LoginState>(
      'INVALID_CREDENTIALS shows the error banner',
      build: () => _cubit(
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
      build: () => _cubit(
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
      build: () => _cubit(
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
