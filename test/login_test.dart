import 'package:bloc_test/bloc_test.dart';
import 'package:ckd_student_app/app.dart';
import 'package:ckd_student_app/features/auth/cubit/login_cubit.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('LoginCubit', () {
    test('initial state cannot submit', () {
      expect(LoginCubit().state.canSubmit, isFalse);
    });

    blocTest<LoginCubit, LoginState>(
      'submit with invalid input turns validation on',
      build: LoginCubit.new,
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
      'valid credentials sign in',
      build: LoginCubit.new,
      seed: () => const LoginState(
        termsAccepted: true,
        email: 'alex.ramos@horizon.edu.ph',
        password: 'secret',
      ),
      act: (cubit) => cubit.submit(),
      wait: const Duration(milliseconds: 1500),
      expect: () => [
        isA<LoginState>()
            .having((s) => s.status, 'status', LoginStatus.submitting),
        isA<LoginState>()
            .having((s) => s.status, 'status', LoginStatus.success),
      ],
    );

    blocTest<LoginCubit, LoginState>(
      'wrong password shows invalid-credentials error',
      build: LoginCubit.new,
      seed: () => const LoginState(
        termsAccepted: true,
        email: 'alex.ramos@horizon.edu.ph',
        password: 'wrong-password',
      ),
      act: (cubit) => cubit.submit(),
      wait: const Duration(milliseconds: 1500),
      expect: () => [
        isA<LoginState>()
            .having((s) => s.status, 'status', LoginStatus.submitting),
        isA<LoginState>()
            .having((s) => s.status, 'status', LoginStatus.failure)
            .having((s) => s.errorMessage, 'errorMessage', isNotNull),
      ],
    );
  });

  group('LoginPage', () {
    testWidgets('renders the student sign in form', (tester) async {
      await tester.pumpWidget(const CkdStudentApp());
      await tester.pump();

      expect(find.text('Student sign in'), findsOneWidget);
      expect(find.text('Email ID'), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);
      expect(find.text('Forgot password?'), findsOneWidget);
    });
  });
}
