import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/api/api_exception.dart';
import '../data/dashboard_repository.dart';
import '../data/models/dashboard_models.dart';

enum OpenExamStatus { idle, submitting, success, failure }

class OpenExamState extends Equatable {
  const OpenExamState({
    this.code = '',
    this.status = OpenExamStatus.idle,
    this.errorMessage,
    this.exam,
  });

  final String code;
  final OpenExamStatus status;
  final String? errorMessage;
  final ResolvedExam? exam;

  bool get canSubmit =>
      code.trim().isNotEmpty && status != OpenExamStatus.submitting;

  @override
  List<Object?> get props => [code, status, errorMessage, exam];
}

/// "Open exam" by the code printed on the answer sheet.
class OpenExamCubit extends Cubit<OpenExamState> {
  OpenExamCubit({required DashboardRepository repository})
      : _repository = repository,
        super(const OpenExamState());

  final DashboardRepository _repository;

  void codeChanged(String code) => emit(OpenExamState(code: code));

  Future<void> submit() async {
    if (!state.canSubmit) {
      emit(OpenExamState(
        code: state.code,
        status: OpenExamStatus.failure,
        errorMessage: 'Enter the exam code from your answer sheet.',
      ));
      return;
    }
    emit(OpenExamState(code: state.code, status: OpenExamStatus.submitting));
    try {
      final exam = await _repository.resolveExamCode(state.code);
      emit(OpenExamState(
        code: state.code,
        status: OpenExamStatus.success,
        exam: exam,
      ));
    } on ApiException catch (e) {
      emit(OpenExamState(
        code: state.code,
        status: OpenExamStatus.failure,
        errorMessage: e.message,
      ));
    }
  }
}
