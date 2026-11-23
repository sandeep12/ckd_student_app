part of 'reset_password_cubit.dart';

enum ResetPasswordStatus { idle, submitting, success, failure }

class ResetPasswordState extends Equatable {
  const ResetPasswordState({
    this.token = '',
    this.tokenLocked = false,
    this.password = '',
    this.confirm = '',
    this.obscurePassword = true,
    this.obscureConfirm = true,
    this.status = ResetPasswordStatus.idle,
    this.tokenError,
    this.passwordError,
    this.confirmError,
    this.errorMessage,
    this.tokenInvalid = false,
  });

  /// Raw token or pasted reset link.
  final String token;

  /// True when the token came from a deep link, so the field is hidden.
  final bool tokenLocked;
  final String password;
  final String confirm;
  final bool obscurePassword;
  final bool obscureConfirm;
  final ResetPasswordStatus status;
  final String? tokenError;
  final String? passwordError;
  final String? confirmError;
  final String? errorMessage;

  /// Backend said `PASSWORD_RESET_TOKEN_INVALID` — offer a new link.
  final bool tokenInvalid;

  bool get isSubmitting => status == ResetPasswordStatus.submitting;

  ResetPasswordState copyWith({
    String? token,
    String? password,
    String? confirm,
    bool? obscurePassword,
    bool? obscureConfirm,
    ResetPasswordStatus? status,
    String? Function()? tokenError,
    String? Function()? passwordError,
    String? Function()? confirmError,
    String? Function()? errorMessage,
    bool? tokenInvalid,
  }) {
    return ResetPasswordState(
      token: token ?? this.token,
      tokenLocked: tokenLocked,
      password: password ?? this.password,
      confirm: confirm ?? this.confirm,
      obscurePassword: obscurePassword ?? this.obscurePassword,
      obscureConfirm: obscureConfirm ?? this.obscureConfirm,
      status: status ?? this.status,
      tokenError: tokenError != null ? tokenError() : this.tokenError,
      passwordError:
          passwordError != null ? passwordError() : this.passwordError,
      confirmError: confirmError != null ? confirmError() : this.confirmError,
      errorMessage: errorMessage != null ? errorMessage() : this.errorMessage,
      tokenInvalid:
          tokenInvalid ?? (status == null ? this.tokenInvalid : false),
    );
  }

  @override
  List<Object?> get props => [
        token,
        tokenLocked,
        password,
        confirm,
        obscurePassword,
        obscureConfirm,
        status,
        tokenError,
        passwordError,
        confirmError,
        errorMessage,
        tokenInvalid,
      ];
}
