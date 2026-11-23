import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/api/api_exception.dart';
import '../data/auth_repository.dart';
import '../data/models/auth_models.dart';

part 'mfa_state.dart';

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
      errorMessage: () => null,
    ));
  }

  Future<void> submit() async {
    if (state.isVerifying) return;

    if (state.code.length < codeLength) {
      emit(state.copyWith(showIncomplete: true));
      return;
    }

    emit(state.copyWith(
      status: MfaStatus.verifying,
      showIncomplete: false,
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
        errorMessage: () => e.message,
      ));
    }
  }

  Future<void> resend() async {
    if (state.isVerifying || state.isResending) return;

    emit(state.copyWith(
      status: MfaStatus.resending,
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
        errorMessage: () => e.message,
      ));
    }
  }
}
