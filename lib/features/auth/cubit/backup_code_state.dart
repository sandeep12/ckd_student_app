part of 'backup_code_cubit.dart';

enum BackupCodeStatus { idle, verifying, success, failure }

class BackupCodeState extends Equatable {
  const BackupCodeState({
    required this.challenge,
    this.code = '',
    this.status = BackupCodeStatus.idle,
    this.showEmpty = false,
    this.errorKind,
    this.errorMessage,
    this.session,
  });

  final MfaChallenge challenge;
  final String code;
  final BackupCodeStatus status;
  final bool showEmpty;
  final MfaErrorKind? errorKind;
  final String? errorMessage;
  final AuthSession? session;

  bool get isVerifying => status == BackupCodeStatus.verifying;
  bool get isBlocked =>
      errorKind == MfaErrorKind.expired || errorKind == MfaErrorKind.locked;
  bool get isExpired => errorKind == MfaErrorKind.expired;
  bool get canSubmit => code.trim().isNotEmpty && !isVerifying && !isBlocked;

  /// Inline field error (empty input or rejected code).
  String? get fieldError {
    if (showEmpty) return 'Enter one of your backup codes.';
    if (errorKind == MfaErrorKind.invalidCode) return 'Check the code.';
    return null;
  }

  BackupCodeState copyWith({
    String? code,
    BackupCodeStatus? status,
    bool? showEmpty,
    MfaErrorKind? Function()? errorKind,
    String? Function()? errorMessage,
    AuthSession? Function()? session,
  }) {
    return BackupCodeState(
      challenge: challenge,
      code: code ?? this.code,
      status: status ?? this.status,
      showEmpty: showEmpty ?? this.showEmpty,
      errorKind: errorKind != null ? errorKind() : this.errorKind,
      errorMessage: errorMessage != null ? errorMessage() : this.errorMessage,
      session: session != null ? session() : this.session,
    );
  }

  @override
  List<Object?> get props =>
      [challenge, code, status, showEmpty, errorKind, errorMessage, session];
}
