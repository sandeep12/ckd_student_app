import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/api/api_exception.dart';
import '../data/auth_repository.dart';
import '../data/models/auth_models.dart';

part 'mfa_state.dart';

/// Kind of MFA failure, used to pick the UI treatment.
enum MfaErrorKind { invalidCode, expired, locked, network, other }

/// Maps a backend error to a [MfaErrorKind].
///
/// Codes observed: `MFA_INVALID_CODE` (verify), `BACKUP_CODE_INVALID`
/// (backup-code), `MFA_CHALLENGE_EXPIRED`, `ACCOUNT_LOCKED`
/// (`details.retryAt`), `VALIDATION_ERROR`, plus the client-side
/// [ApiException.networkErrorCode].
MfaErrorKind mfaErrorKind(ApiException e) {
  switch (e.code) {
    case 'MFA_INVALID_CODE':
    case 'BACKUP_CODE_INVALID':
    case 'VALIDATION_ERROR':
      return MfaErrorKind.invalidCode;
    case 'MFA_CHALLENGE_EXPIRED':
      return MfaErrorKind.expired;
    case 'ACCOUNT_LOCKED':
    case 'MFA_TOO_MANY_ATTEMPTS':
    case 'TOO_MANY_REQUESTS':
    case 'RATE_LIMITED':
      return MfaErrorKind.locked;
    case ApiException.networkErrorCode:
      return MfaErrorKind.network;
    default:
      return MfaErrorKind.other;
  }
}

/// Friendly copy for an MFA failure.
String mfaErrorMessage(ApiException e, {bool backupCode = false}) {
  switch (mfaErrorKind(e)) {
    case MfaErrorKind.invalidCode:
      return backupCode
          ? 'That backup code is not valid. Check it and try again — '
              'each backup code works only once.'
          : 'That code is not right. Check the latest email and try again.';
    case MfaErrorKind.expired:
      return 'Your sign-in attempt has expired. Go back and sign in again.';
    case MfaErrorKind.locked:
      return 'Too many attempts. Your account is locked for a while — '
          'try again later or contact your school.';
    case MfaErrorKind.network:
      return e.message;
    case MfaErrorKind.other:
      return e.message.isNotEmpty
          ? e.message
          : 'Something went wrong. Please try again.';
  }
}

/// Drives the "Verify it's you" screen (`POST /api/v1/auth/mfa/verify`).
class MfaCubit extends Cubit<MfaState> {
  MfaCubit({
    required AuthRepository authRepository,
    required MfaChallenge challenge,
  })  : _authRepository = authRepository,
        super(MfaState(challenge: challenge));

  final AuthRepository _authRepository;

  static const int codeLength = 6;

  void codeChanged(String value) {
    emit(state.copyWith(
      code: value,
      status: MfaStatus.idle,
      showIncomplete: false,
      errorKind: () => null,
      errorMessage: () => null,
    ));
  }

  Future<void> submit() async {
    if (state.isVerifying || state.isBlocked) return;

    if (state.code.length < codeLength) {
      emit(state.copyWith(showIncomplete: true));
      return;
    }

    emit(state.copyWith(
      status: MfaStatus.verifying,
      showIncomplete: false,
      errorKind: () => null,
      errorMessage: () => null,
      infoMessage: () => null,
    ));

    try {
      final session = await _authRepository.verifyMfa(
        challengeToken: state.challenge.challengeToken,
        code: state.code,
      );
      if (isClosed) return;
      emit(state.copyWith(
        status: MfaStatus.success,
        session: () => session,
      ));
    } on ApiException catch (e) {
      if (isClosed) return;
      emit(state.copyWith(
        status: MfaStatus.failure,
        code: '',
        errorKind: () => mfaErrorKind(e),
        errorMessage: () => mfaErrorMessage(e),
      ));
    }
  }

  Future<void> resend() async {
    if (state.isVerifying || state.isResending || state.isBlocked) return;

    emit(state.copyWith(
      status: MfaStatus.resending,
      errorKind: () => null,
      errorMessage: () => null,
      infoMessage: () => null,
    ));

    try {
      final challenge = await _authRepository.resendMfa(
        challengeToken: state.challenge.challengeToken,
      );
      if (isClosed) return;
      emit(state.copyWith(
        status: MfaStatus.idle,
        challenge: challenge,
        code: '',
        infoMessage: () =>
            'We sent a new code. The previous one no longer works.',
      ));
    } on ApiException catch (e) {
      if (isClosed) return;
      emit(state.copyWith(
        status: MfaStatus.failure,
        errorKind: () => mfaErrorKind(e),
        errorMessage: () => mfaErrorMessage(e),
      ));
    }
  }
}
