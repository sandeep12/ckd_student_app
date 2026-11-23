import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/api/api_exception.dart';
import '../data/mfa_backup_repository.dart';
import '../data/models/auth_models.dart';
import 'mfa_cubit.dart';

part 'backup_code_state.dart';

/// Drives the "Use a backup code" screen (`POST /auth/mfa/backup-code`).
class BackupCodeCubit extends Cubit<BackupCodeState> {
  BackupCodeCubit({
    required MfaBackupRepository repository,
    required MfaChallenge challenge,
  })  : _repository = repository,
        super(BackupCodeState(challenge: challenge));

  final MfaBackupRepository _repository;

  void codeChanged(String value) {
    if (state.isBlocked) return;
    emit(state.copyWith(
      code: value,
      status: BackupCodeStatus.idle,
      showEmpty: false,
      errorKind: () => null,
      errorMessage: () => null,
    ));
  }

  Future<void> submit() async {
    if (state.isVerifying || state.isBlocked) return;
    if (state.code.trim().isEmpty) {
      emit(state.copyWith(showEmpty: true));
      return;
    }

    emit(state.copyWith(
      status: BackupCodeStatus.verifying,
      showEmpty: false,
      errorKind: () => null,
      errorMessage: () => null,
    ));

    try {
      final session = await _repository.verifyBackupCode(
        challengeToken: state.challenge.challengeToken,
        code: state.code,
      );
      if (isClosed) return;
      emit(state.copyWith(
        status: BackupCodeStatus.success,
        session: () => session,
      ));
    } on ApiException catch (e) {
      if (isClosed) return;
      emit(state.copyWith(
        status: BackupCodeStatus.failure,
        errorKind: () => mfaErrorKind(e),
        errorMessage: () => mfaErrorMessage(e, backupCode: true),
      ));
    }
  }
}
