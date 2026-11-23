import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/api/api_exception.dart';
import '../data/auth_repository.dart';
import '../data/models/auth_models.dart';
import 'auth_error_messages.dart';

enum CreatePasswordStatus { idle, submitting, success, expired, failure }

/// "Create new password" — the forced first-login password change
/// (`POST /auth/reset-password`).
class CreatePasswordCubit extends Cubit<CreatePasswordState> {
  CreatePasswordCubit({
    required AuthRepository authRepository,
    required SetupTicket ticket,
  })  : _authRepository = authRepository,
        super(CreatePasswordState(ticket: ticket));

  final AuthRepository _authRepository;

  void passwordChanged(String value) => emit(state.copyWith(
        password: value,
        status: CreatePasswordStatus.idle,
        errorMessage: () => null,
        serverError: () => null,
      ));

  void confirmChanged(String value) => emit(state.copyWith(
        confirm: value,
        status: CreatePasswordStatus.idle,
        errorMessage: () => null,
      ));

  void togglePasswordVisibility() =>
      emit(state.copyWith(obscurePassword: !state.obscurePassword));

  void toggleConfirmVisibility() =>
      emit(state.copyWith(obscureConfirm: !state.obscureConfirm));

  Future<void> submit() async {
    if (state.isSubmitting) return;
    if (!state.isValid) {
      emit(state.copyWith(showValidation: true));
      return;
    }
    emit(state.copyWith(
      showValidation: false,
      status: CreatePasswordStatus.submitting,
      errorMessage: () => null,
      serverError: () => null,
    ));
    try {
      final outcome = await _authRepository.resetPassword(
        setupToken: state.ticket.setupToken,
        password: state.password,
      );
      if (isClosed) return;
      emit(state.copyWith(
        status: CreatePasswordStatus.success,
        outcome: () => outcome,
      ));
    } on ApiException catch (e) {
      if (isClosed) return;
      if (e.code == 'SETUP_SESSION_EXPIRED') {
        emit(state.copyWith(status: CreatePasswordStatus.expired));
        return;
      }
      if (e.code == 'VALIDATION_ERROR' && e.fieldErrors['password'] != null) {
        emit(state.copyWith(
          status: CreatePasswordStatus.idle,
          serverError: () => e.fieldErrors['password'],
        ));
        return;
      }
      emit(state.copyWith(
        status: CreatePasswordStatus.failure,
        errorMessage: () => AuthErrorMessages.forSetup(e),
      ));
    }
  }
}

class CreatePasswordState extends Equatable {
  const CreatePasswordState({
    required this.ticket,
    this.password = '',
    this.confirm = '',
    this.obscurePassword = true,
    this.obscureConfirm = true,
    this.showValidation = false,
    this.status = CreatePasswordStatus.idle,
    this.errorMessage,
    this.serverError,
    this.outcome,
  });

  final SetupTicket ticket;
  final String password;
  final String confirm;
  final bool obscurePassword;
  final bool obscureConfirm;
  final bool showValidation;
  final CreatePasswordStatus status;
  final String? errorMessage;

  /// `VALIDATION_ERROR` message for the password field.
  final String? serverError;

  /// Next login step after a successful reset.
  final LoginOutcome? outcome;

  // Password policy (CMP-006), mirrored from the backend.
  bool get hasMinLength => password.length >= 8;
  bool get hasUpper => password.contains(RegExp('[A-Z]'));
  bool get hasNumber => password.contains(RegExp('[0-9]'));
  bool get hasSpecial => password.contains(RegExp('[^A-Za-z0-9]'));
  bool get isCompliant => hasMinLength && hasUpper && hasNumber && hasSpecial;
  bool get matches => password == confirm;
  bool get isValid => isCompliant && matches && password.length <= 128;

  bool get isSubmitting => status == CreatePasswordStatus.submitting;
  bool get canSubmit =>
      password.isNotEmpty && confirm.isNotEmpty && !isSubmitting;

  String? get passwordError {
    if (serverError != null) return serverError;
    if (!showValidation || isCompliant) return null;
    return 'Your password does not meet the rules below.';
  }

  String? get confirmError {
    if (confirm.isEmpty || matches) return null;
    if (!showValidation && confirm.length < password.length) return null;
    return 'The passwords do not match.';
  }

  CreatePasswordState copyWith({
    String? password,
    String? confirm,
    bool? obscurePassword,
    bool? obscureConfirm,
    bool? showValidation,
    CreatePasswordStatus? status,
    String? Function()? errorMessage,
    String? Function()? serverError,
    LoginOutcome? Function()? outcome,
  }) {
    return CreatePasswordState(
      ticket: ticket,
      password: password ?? this.password,
      confirm: confirm ?? this.confirm,
      obscurePassword: obscurePassword ?? this.obscurePassword,
      obscureConfirm: obscureConfirm ?? this.obscureConfirm,
      showValidation: showValidation ?? this.showValidation,
      status: status ?? this.status,
      errorMessage: errorMessage != null ? errorMessage() : this.errorMessage,
      serverError: serverError != null ? serverError() : this.serverError,
      outcome: outcome != null ? outcome() : this.outcome,
    );
  }

  @override
  List<Object?> get props => [
        ticket,
        password,
        confirm,
        obscurePassword,
        obscureConfirm,
        showValidation,
        status,
        errorMessage,
        serverError,
        outcome,
      ];
}
