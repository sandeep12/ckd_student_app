import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/api/api_exception.dart';
import '../data/exams_repository.dart';
import '../data/models/student_exam.dart';

part 'my_exams_state.dart';

class MyExamsCubit extends Cubit<MyExamsState> {
  MyExamsCubit(
      {required ExamsRepository repository, DateTime Function()? clock})
      : _repository = repository,
        _clock = clock ?? DateTime.now,
        super(const MyExamsState());

  final ExamsRepository _repository;
  final DateTime Function() _clock;

  Future<void> load() async {
    emit(state.copyWith(status: MyExamsStatus.loading));
    try {
      final exams = await _repository.fetchExams();
      final now = _clock();
      emit(state.copyWith(
        status: MyExamsStatus.loaded,
        exams: exams,
        today: DateTime(now.year, now.month, now.day),
        errorMessage: () => null,
      ));
    } on ApiException catch (e) {
      emit(state.copyWith(
        status: MyExamsStatus.failure,
        errorMessage: () => e.message,
      ));
    }
  }

  void search(String query) => emit(state.copyWith(query: query));

  void setFilter(MyExamsFilter filter) => emit(state.copyWith(filter: filter));

  /// Null clears the subject filter.
  void setSubject(String? subject) =>
      emit(state.copyWith(subject: () => subject));

  void clearFilters() => emit(state.copyWith(
        query: '',
        filter: MyExamsFilter.all,
        subject: () => null,
      ));
}
