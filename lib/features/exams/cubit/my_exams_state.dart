part of 'my_exams_cubit.dart';

enum MyExamsStatus { initial, loading, loaded, failure }

/// The status tags on the My Exams toolbar.
enum MyExamsFilter { all, active, graded }

class MyExamsState extends Equatable {
  const MyExamsState({
    this.status = MyExamsStatus.initial,
    this.exams = const [],
    this.today,
    this.query = '',
    this.filter = MyExamsFilter.all,
    this.subject,
    this.errorMessage,
  });

  final MyExamsStatus status;
  final List<StudentExam> exams;
  final DateTime? today;
  final String query;
  final MyExamsFilter filter;
  final String? subject;
  final String? errorMessage;

  bool get isLoading =>
      status == MyExamsStatus.initial || status == MyExamsStatus.loading;

  bool get hasFilters =>
      query.trim().isNotEmpty || filter != MyExamsFilter.all || subject != null;

  StudentExamState stateOf(StudentExam exam) =>
      exam.stateOn(today ?? DateTime.now());

  /// Distinct subjects, alphabetical.
  List<String> get subjects =>
      (exams.map((e) => e.subjectName).whereType<String>().toSet().toList()
        ..sort());

  /// Exams matching search, status tag and subject.
  List<StudentExam> get visible {
    final needle = query.trim().toLowerCase();
    return exams.where((e) {
      if (subject != null && e.subjectName != subject) return false;
      final graded = stateOf(e) == StudentExamState.graded;
      if (filter == MyExamsFilter.active && graded) return false;
      if (filter == MyExamsFilter.graded && !graded) return false;
      if (needle.isEmpty) return true;
      return [e.title, e.code, e.subjectName ?? '']
          .any((f) => f.toLowerCase().contains(needle));
    }).toList(growable: false);
  }

  MyExamsState copyWith({
    MyExamsStatus? status,
    List<StudentExam>? exams,
    DateTime? today,
    String? query,
    MyExamsFilter? filter,
    String? Function()? subject,
    String? Function()? errorMessage,
  }) {
    return MyExamsState(
      status: status ?? this.status,
      exams: exams ?? this.exams,
      today: today ?? this.today,
      query: query ?? this.query,
      filter: filter ?? this.filter,
      subject: subject != null ? subject() : this.subject,
      errorMessage: errorMessage != null ? errorMessage() : this.errorMessage,
    );
  }

  @override
  List<Object?> get props =>
      [status, exams, today, query, filter, subject, errorMessage];
}
