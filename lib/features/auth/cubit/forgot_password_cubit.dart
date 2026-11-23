import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/api/api_exception.dart';
import '../data/password_reset_repository.dart';

part 'forgot_password_state.dart';

/// Drives "Forgot password" and "Check your email"
/// (`POST /api/v1/auth/forgot-password`).
class ForgotPasswordCubit extends Cubit<ForgotPasswordState> {
  ForgotPasswordCubit({required PasswordResetRepository repository})
      : _repository = repository,
        super(const ForgotPasswordState());

  final PasswordResetRepository _repository;
  Timer? _cooldownTimer;

  static const int resendCooldownSeconds = 60;
  static final RegExp _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  void emailChanged(String value) {
    emit(state.copyWith(
      email: value,
      emailError: () => null,
      errorMessage: () => null,
    ));
  }

  Future<void> submit() async {
    if (state.isSubmitting) return;
    final email = state.email.trim();
    if (email.isEmpty) {
      emit(state.copyWith(emailError: () => 'Enter your email address.'));
      return;
    }
    if (!_emailPattern.hasMatch(email)) {
      emit(state.copyWith(emailError: () => 'Enter a valid email address.'));
      return;
    }
    await _send(email, ForgotPasswordStatus.submitting);
  }

  Future<void> resend() async {
    if (state.isSubmitting || state.isResending || state.cooldown > 0) return;
    await _send(state.email.trim(), ForgotPasswordStatus.resending);
  }

  Future<void> _send(String email, ForgotPasswordStatus busy) async {
    emit(state.copyWith(
      status: busy,
      errorMessage: () => null,
      infoMessage: () => null,
    ));
    try {
      await _repository.requestReset(email: email);
      if (isClosed) return;
      final resent = busy == ForgotPasswordStatus.resending;
      emit(state.copyWith(
        status: ForgotPasswordStatus.sent,
        sentCount: state.sentCount + 1,
        infoMessage: () =>
            resent ? 'We sent a new link. Earlier links no longer work.' : null,
      ));
      _startCooldown();
    } on ApiException catch (e) {
      if (isClosed) return;
      emit(state.copyWith(
        status: ForgotPasswordStatus.failure,
        emailError: () => e.fieldErrors['email'],
        errorMessage: () =>
            e.fieldErrors.containsKey('email') ? null : e.message,
      ));
    }
  }

  void _startCooldown() {
    _cooldownTimer?.cancel();
    emit(state.copyWith(cooldown: resendCooldownSeconds));
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (isClosed) return timer.cancel();
      final next = state.cooldown - 1;
      emit(state.copyWith(cooldown: next < 0 ? 0 : next));
      if (next <= 0) timer.cancel();
    });
  }

  @override
  Future<void> close() {
    _cooldownTimer?.cancel();
    return super.close();
  }
}
