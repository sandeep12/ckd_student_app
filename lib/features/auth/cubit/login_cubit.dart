import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'login_state.dart';

/// Drives the student login screen.
///
/// Frontend-only build: [submit] simulates the network round-trip. Use the
/// password `wrong-password` to exercise the invalid-credentials error state.
class LoginCubit extends Cubit<LoginState> {
  LoginCubit() : super(const LoginState());

  void emailChanged(String value) {
    emit(state.copyWith(
      email: value,
      status: LoginStatus.idle,
      errorMessage: () => null,
    ));
  }

  void passwordChanged(String value) {
    emit(state.copyWith(
      password: value,
      status: LoginStatus.idle,
      errorMessage: () => null,
    ));
  }

  void togglePasswordVisibility() {
    emit(state.copyWith(obscurePassword: !state.obscurePassword));
  }

  void termsToggled(bool accepted) {
    emit(state.copyWith(termsAccepted: accepted));
  }

  Future<void> submit() async {
    if (!state.canSubmit) return;

    if (!state.isFormValid) {
      emit(state.copyWith(showValidation: true));
      return;
    }

    emit(state.copyWith(
      showValidation: false,
      status: LoginStatus.submitting,
      errorMessage: () => null,
    ));

    // Frontend-only: stand-in for the auth API call.
    await Future<void>.delayed(const Duration(milliseconds: 1200));
    if (isClosed) return;

    if (state.password == 'wrong-password') {
      emit(state.copyWith(
        status: LoginStatus.failure,
        errorMessage: () =>
            'We could not sign you in. Check your email and password, '
            'then try again.',
      ));
      return;
    }

    emit(state.copyWith(status: LoginStatus.success));
  }
}
