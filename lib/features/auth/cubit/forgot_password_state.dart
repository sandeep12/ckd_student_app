part of 'forgot_password_cubit.dart';

enum ForgotPasswordStatus { idle, submitting, resending, sent, failure }

class ForgotPasswordState extends Equatable {
  const ForgotPasswordState({
    this.email = '',
    this.status = ForgotPasswordStatus.idle,
    this.emailError,
    this.errorMessage,
    this.infoMessage,
    this.cooldown = 0,
    this.sentCount = 0,
  });

  final String email;
  final ForgotPasswordStatus status;
  final String? emailError;

  /// Banner message (network / server errors).
  final String? errorMessage;

  /// "New link sent" confirmation on the check-email screen.
  final String? infoMessage;

  /// Seconds left before another link can be requested.
  final int cooldown;

  /// Number of successful requests; first success navigates onward.
  final int sentCount;

  bool get isSubmitting => status == ForgotPasswordStatus.submitting;
  bool get isResending => status == ForgotPasswordStatus.resending;
  bool get canResend => !isSubmitting && !isResending && cooldown == 0;

  ForgotPasswordState copyWith({
    String? email,
    ForgotPasswordStatus? status,
    String? Function()? emailError,
    String? Function()? errorMessage,
    String? Function()? infoMessage,
    int? cooldown,
    int? sentCount,
  }) {
    return ForgotPasswordState(
      email: email ?? this.email,
      status: status ?? this.status,
      emailError: emailError != null ? emailError() : this.emailError,
      errorMessage: errorMessage != null ? errorMessage() : this.errorMessage,
      infoMessage: infoMessage != null ? infoMessage() : this.infoMessage,
      cooldown: cooldown ?? this.cooldown,
      sentCount: sentCount ?? this.sentCount,
    );
  }

  @override
  List<Object?> get props => [
        email,
        status,
        emailError,
        errorMessage,
        infoMessage,
        cooldown,
        sentCount
      ];
}
