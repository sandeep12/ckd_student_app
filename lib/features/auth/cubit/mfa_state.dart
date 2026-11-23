part of 'mfa_cubit.dart';

enum MfaStatus { idle, verifying, resending, success, failure }

class MfaState extends Equatable {
  const MfaState({
    required this.challenge,
    this.code = '',
    this.status = MfaStatus.idle,
    this.showIncomplete = false,
    this.errorMessage,
    this.infoMessage,
    this.session,
  });

  final MfaChallenge challenge;
  final String code;
  final MfaStatus status;

  /// Figma "invalid input: incomplete code" state.
  final bool showIncomplete;

  /// Banner message (incorrect code, expired, too many attempts, network).
  final String? errorMessage;

  /// Figma "screen-specific: new code sent" state.
  final String? infoMessage;

  final AuthSession? session;

  bool get isVerifying => status == MfaStatus.verifying;
  bool get isResending => status == MfaStatus.resending;
  bool get canSubmit =>
      code.length == MfaCubit.codeLength && !isVerifying && !isResending;

  String? get incompleteError =>
      showIncomplete ? 'Enter all 6 digits of the code.' : null;

  MfaState copyWith({
    MfaChallenge? challenge,
    String? code,
    MfaStatus? status,
    bool? showIncomplete,
    String? Function()? errorMessage,
    String? Function()? infoMessage,
    AuthSession? Function()? session,
  }) {
    return MfaState(
      challenge: challenge ?? this.challenge,
      code: code ?? this.code,
      status: status ?? this.status,
      showIncomplete: showIncomplete ?? this.showIncomplete,
      errorMessage: errorMessage != null ? errorMessage() : this.errorMessage,
      infoMessage: infoMessage != null ? infoMessage() : this.infoMessage,
      session: session != null ? session() : this.session,
    );
  }

  @override
  List<Object?> get props => [
        challenge,
        code,
        status,
        showIncomplete,
        errorMessage,
        infoMessage,
        session,
      ];
}
