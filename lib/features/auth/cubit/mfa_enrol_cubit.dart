import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/api/api_exception.dart';
import '../data/auth_repository.dart';
import '../data/models/auth_models.dart';
import 'auth_error_messages.dart';

/// Steps of the email-MFA enrolment flow.
enum MfaEnrolStep { intro, code, backupCodes }

/// MFA enrolment (`/auth/mfa/enrol/start` + `/confirm`). The student app
/// offers the `email` method only.
class MfaEnrolCubit extends Cubit<MfaEnrolState> {
  MfaEnrolCubit({
    required AuthRepository authRepository,
    required SetupTicket ticket,
  })  : _authRepository = authRepository,
        super(MfaEnrolState(ticket: ticket));

  final AuthRepository _authRepository;

  /// Sends (or re-sends) the enrolment code by email.
  Future<void> sendCode() async {
    if (state.busy) return;
    emit(state.copyWith(sending: true, errorMessage: () => null));
    try {
      await _authRepository.startMfaEnrolment(
        setupToken: state.ticket.setupToken,
      );
      if (isClosed) return;
      emit(state.copyWith(
        sending: false,
        step: MfaEnrolStep.code,
        code: '',
        showIncomplete: false,
      ));
    } on ApiException catch (e) {
      _fail(e, sending: false);
    }
  }

  void codeChanged(String value) => emit(state.copyWith(
        code: value,
        showIncomplete: false,
        errorMessage: () => null,
      ));

  Future<void> confirm() async {
    if (state.busy) return;
    if (state.code.length != 6) {
      emit(state.copyWith(showIncomplete: true));
      return;
    }
    emit(state.copyWith(confirming: true, errorMessage: () => null));
    try {
      final result = await _authRepository.confirmMfaEnrolment(
        setupToken: state.ticket.setupToken,
        code: state.code,
      );
      if (isClosed) return;
      emit(state.copyWith(
        confirming: false,
        result: () => result,
        step: MfaEnrolStep.backupCodes,
      ));
    } on ApiException catch (e) {
      _fail(e, confirming: false);
    }
  }

  void savedToggled(bool value) => emit(state.copyWith(savedCodes: value));

  void _fail(ApiException e, {bool? sending, bool? confirming}) {
    if (isClosed) return;
    emit(state.copyWith(
      sending: sending,
      confirming: confirming,
      expired: e.code == 'SETUP_SESSION_EXPIRED',
      errorMessage: () => AuthErrorMessages.forSetup(e),
    ));
  }
}

class MfaEnrolState extends Equatable {
  const MfaEnrolState({
    required this.ticket,
    this.step = MfaEnrolStep.intro,
    this.code = '',
    this.sending = false,
    this.confirming = false,
    this.showIncomplete = false,
    this.expired = false,
    this.savedCodes = false,
    this.errorMessage,
    this.result,
  });

  final SetupTicket ticket;
  final MfaEnrolStep step;
  final String code;
  final bool sending;
  final bool confirming;
  final bool showIncomplete;

  /// The setup session timed out (`SETUP_SESSION_EXPIRED`).
  final bool expired;
  final bool savedCodes;
  final String? errorMessage;
  final MfaEnrolmentResult? result;

  bool get busy => sending || confirming;

  MfaEnrolState copyWith({
    MfaEnrolStep? step,
    String? code,
    bool? sending,
    bool? confirming,
    bool? showIncomplete,
    bool? expired,
    bool? savedCodes,
    String? Function()? errorMessage,
    MfaEnrolmentResult? Function()? result,
  }) {
    return MfaEnrolState(
      ticket: ticket,
      step: step ?? this.step,
      code: code ?? this.code,
      sending: sending ?? this.sending,
      confirming: confirming ?? this.confirming,
      showIncomplete: showIncomplete ?? this.showIncomplete,
      expired: expired ?? this.expired,
      savedCodes: savedCodes ?? this.savedCodes,
      errorMessage: errorMessage != null ? errorMessage() : this.errorMessage,
      result: result != null ? result() : this.result,
    );
  }

  @override
  List<Object?> get props => [
        ticket,
        step,
        code,
        sending,
        confirming,
        showIncomplete,
        expired,
        savedCodes,
        errorMessage,
        result,
      ];
}
