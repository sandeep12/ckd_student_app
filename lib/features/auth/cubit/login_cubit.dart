import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/api/api_exception.dart';
import '../data/auth_repository.dart';
import '../data/models/auth_models.dart';

part 'login_state.dart';

/// Drives the student login screen against `POST /api/v1/auth/login`.
class LoginCubit extends Cubit<LoginState> {
  LoginCubit({required AuthRepository authRepository})
      : _authRepository = authRepository,
        super(const LoginState());

  final AuthRepository _authRepository;

  void emailChanged(String value) {
    emit(state.copyWith(
      email: value,
      status: LoginStatus.idle,
      errorMessage: () => null,
      serverFieldErrors: const {},
    ));
  }

  void passwordChanged(String value) {
    emit(state.copyWith(
      password: value,
      status: LoginStatus.idle,
      errorMessage: () => null,
      serverFieldErrors: const {},
    ));
  }

  void togglePasswordVisibility() {
    emit(state.copyWith(obscurePassword: !state.obscurePassword));
  }

  void termsToggled(bool accepted) {
    emit(state.copyWith(termsAccepted: accepted));
  }

  /// Called after navigating to the verify screen, so returning to the
  /// login page does not re-trigger navigation.
  void challengeHandled() {
    emit(state.copyWith(
      status: LoginStatus.idle,
      challenge: () => null,
      password: '',
    ));
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
      serverFieldErrors: const {},
    ));

    try {
      final outcome = await _authRepository.login(
        email: state.email,
        password: state.password,
        termsAccepted: state.termsAccepted,
      );
      if (isClosed) return;

      switch (outcome) {
        case LoginMfaRequired(:final challenge):
          emit(state.copyWith(
            status: LoginStatus.mfaRequired,
            challenge: () => challenge,
          ));
        case LoginAuthenticated(:final session):
          emit(state.copyWith(
            status: LoginStatus.success,
            session: () => session,
          ));
      }
    } on ApiException catch (e) {
      if (isClosed) return;

      if (e.code == 'VALIDATION_ERROR' && e.fieldErrors.isNotEmpty) {
        emit(state.copyWith(
          status: LoginStatus.idle,
          showValidation: true,
          serverFieldErrors: e.fieldErrors,
        ));
        return;
      }

      emit(state.copyWith(
        status: LoginStatus.failure,
        errorMessage: () => e.message,
      ));
    }
  }
}
