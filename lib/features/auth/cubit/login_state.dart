part of 'login_cubit.dart';

/// Submission lifecycle of the login form.
enum LoginStatus {
  idle,
  submitting,
  success,
  mfaRequired,
  passwordResetRequired,
  mfaEnrolmentRequired,
  failure,
}

class LoginState extends Equatable {
  const LoginState({
    this.email = '',
    this.password = '',
    this.obscurePassword = true,
    this.termsAccepted = false,
    this.showValidation = false,
    this.status = LoginStatus.idle,
    this.errorMessage,
    this.serverFieldErrors = const {},
    this.session,
    this.challenge,
    this.setupTicket,
  });

  final String email;
  final String password;
  final bool obscurePassword;
  final bool termsAccepted;

  /// True once the user attempted to submit with invalid input; field
  /// errors are only rendered from then on (Figma "invalid input" state).
  final bool showValidation;

  final LoginStatus status;

  /// Banner message for failed sign-in attempts
  /// (Figma "error: invalid credentials" state).
  final String? errorMessage;

  /// Field path → message from the backend's `VALIDATION_ERROR` details.
  final Map<String, String> serverFieldErrors;

  /// Authenticated session after a successful (non-MFA) login.
  final AuthSession? session;

  /// MFA challenge when the backend requires a one-time code.
  final MfaChallenge? challenge;

  /// First-time setup ticket (forced password change / MFA enrolment).
  final SetupTicket? setupTicket;

  static final RegExp _emailPattern =
      RegExp(r'^[\w.\-+]+@[\w\-]+(\.[\w\-]+)+$');

  bool get isEmailValid => _emailPattern.hasMatch(email.trim());
  bool get isPasswordValid => password.isNotEmpty;
  bool get isFormValid => isEmailValid && isPasswordValid;

  String? get emailError {
    final server = serverFieldErrors['email'];
    if (server != null) return server;
    if (!showValidation || isEmailValid) return null;
    return email.trim().isEmpty
        ? 'Enter your email address.'
        : 'Enter a valid email address.';
  }

  String? get passwordError {
    final server = serverFieldErrors['password'];
    if (server != null) return server;
    return !showValidation || isPasswordValid ? null : 'Enter your password.';
  }

  /// The CTA is disabled until the terms are accepted.
  bool get canSubmit => termsAccepted && status != LoginStatus.submitting;

  bool get isSubmitting => status == LoginStatus.submitting;

  LoginState copyWith({
    String? email,
    String? password,
    bool? obscurePassword,
    bool? termsAccepted,
    bool? showValidation,
    LoginStatus? status,
    String? Function()? errorMessage,
    Map<String, String>? serverFieldErrors,
    AuthSession? Function()? session,
    MfaChallenge? Function()? challenge,
    SetupTicket? Function()? setupTicket,
  }) {
    return LoginState(
      email: email ?? this.email,
      password: password ?? this.password,
      obscurePassword: obscurePassword ?? this.obscurePassword,
      termsAccepted: termsAccepted ?? this.termsAccepted,
      showValidation: showValidation ?? this.showValidation,
      status: status ?? this.status,
      errorMessage: errorMessage != null ? errorMessage() : this.errorMessage,
      serverFieldErrors: serverFieldErrors ?? this.serverFieldErrors,
      session: session != null ? session() : this.session,
      challenge: challenge != null ? challenge() : this.challenge,
      setupTicket: setupTicket != null ? setupTicket() : this.setupTicket,
    );
  }

  @override
  List<Object?> get props => [
        email,
        password,
        obscurePassword,
        termsAccepted,
        showValidation,
        status,
        errorMessage,
        serverFieldErrors,
        session,
        challenge,
        setupTicket,
      ];
}
