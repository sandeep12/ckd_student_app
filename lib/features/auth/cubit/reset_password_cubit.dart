import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/api/api_exception.dart';
import '../data/password_reset_repository.dart';

part 'reset_password_state.dart';

/// Drives "Set new password" (`POST /api/v1/auth/forgot-password/reset`).
class ResetPasswordCubit extends Cubit<ResetPasswordState> {
  ResetPasswordCubit({
    required PasswordResetRepository repository,
    String? initialToken,
  })  : _repository = repository,
        super(ResetPasswordState(
          token: initialToken ?? '',
          tokenLocked: (initialToken ?? '').isNotEmpty,
        ));

  final PasswordResetRepository _repository;

  void tokenChanged(String value) => emit(state.copyWith(
        token: value,
        tokenError: () => null,
        errorMessage: () => null,
      ));

  void passwordChanged(String value) => emit(state.copyWith(
        password: value,
        passwordError: () => null,
        errorMessage: () => null,
      ));

  void confirmChanged(String value) => emit(state.copyWith(
        confirm: value,
        confirmError: () => null,
        errorMessage: () => null,
      ));

  void togglePasswordVisibility() =>
      emit(state.copyWith(obscurePassword: !state.obscurePassword));

  void toggleConfirmVisibility() =>
      emit(state.copyWith(obscureConfirm: !state.obscureConfirm));

  Future<void> submit() async {
    if (state.isSubmitting) return;
    final token = PasswordResetRepository.extractToken(state.token);
    String? tokenError;
    String? passwordError;
    String? confirmError;
    if (token.isEmpty) {
      tokenError = 'Paste the reset link from your email.';
    }
    if (!PasswordRules.allMet(state.password)) {
      passwordError = 'Your password does not meet all the rules below.';
    }
    if (state.confirm.isEmpty) {
      confirmError = 'Re-enter your new password.';
    } else if (state.confirm != state.password) {
      confirmError = 'The passwords do not match.';
    }
    if (tokenError != null || passwordError != null || confirmError != null) {
      emit(state.copyWith(
        tokenError: () => tokenError,
        passwordError: () => passwordError,
        confirmError: () => confirmError,
      ));
      return;
    }

    emit(state.copyWith(
      status: ResetPasswordStatus.submitting,
      errorMessage: () => null,
    ));
    try {
      await _repository.resetPassword(token: token, password: state.password);
      if (isClosed) return;
      emit(state.copyWith(status: ResetPasswordStatus.success));
    } on ApiException catch (e) {
      if (isClosed) return;
      final fieldPassword = e.fieldErrors['password'];
      final fieldToken = e.fieldErrors['token'];
      emit(state.copyWith(
        status: ResetPasswordStatus.failure,
        tokenInvalid: e.code == PasswordResetRepository.tokenInvalidCode,
        passwordError: () => fieldPassword,
        tokenError: () => fieldToken,
        errorMessage: () =>
            fieldPassword != null || fieldToken != null ? null : e.message,
      ));
    }
  }
}

/// Client mirror of the backend rule: "Password must be at least 8
/// characters and include an uppercase letter, a number and a special
/// character".
class PasswordRules {
  const PasswordRules._();

  static const List<(String, bool Function(String))> rules = [
    ('At least 8 characters', _length),
    ('One uppercase letter', _upper),
    ('One number', _digit),
    ('One special character', _special),
  ];

  static bool _length(String p) => p.length >= 8;
  static bool _upper(String p) => RegExp('[A-Z]').hasMatch(p);
  static bool _digit(String p) => RegExp('[0-9]').hasMatch(p);
  static bool _special(String p) => RegExp(r'[^A-Za-z0-9\s]').hasMatch(p);

  static bool allMet(String p) => rules.every((r) => r.$2(p));
}
