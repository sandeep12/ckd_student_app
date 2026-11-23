import 'package:equatable/equatable.dart';

/// How an exam card renders (Figma ExamCard states).
enum StudentExamState {
  /// Still to sit/scan — carries the single primary action.
  scan,

  /// Paper uploaded, result not yet released.
  awaiting,

  /// Scanning window closed without an upload.
  locked,

  /// Result released.
  graded,
}

/// Released result on a My Exams card (`result`).
class StudentExamResult extends Equatable {
  const StudentExamResult({
    required this.percent,
    required this.passed,
    required this.gradeLabel,
  });

  factory StudentExamResult.fromJson(Map<String, dynamic> json) =>
      StudentExamResult(
        percent: (json['percent'] as num?)?.toDouble() ?? 0,
        passed: json['passed'] as bool? ?? false,
        gradeLabel: json['gradeLabel'] as String? ?? '',
      );

  final double percent;
  final bool passed;

  /// e.g. `B+ (88/100)`.
  final String gradeLabel;

  @override
  List<Object?> get props => [percent, passed, gradeLabel];
}

/// `GET /student-exams` item.
class StudentExam extends Equatable {
  const StudentExam({
    required this.examId,
    required this.title,
    required this.code,
    required this.status,
    this.subjectName,
    this.examDate,
    this.itemCount = 0,
    this.result,
    this.awaiting = false,
  });

  factory StudentExam.fromJson(Map<String, dynamic> json) {
    final result = json['result'];
    return StudentExam(
      examId: json['examId'] as String? ?? '',
      title: json['title'] as String? ?? '',
      code: json['code'] as String? ?? '',
      status: json['status'] as String? ?? '',
      subjectName: json['subjectName'] as String?,
      examDate: _parseDate(json['examDate']),
      itemCount: (json['itemCount'] as num?)?.toInt() ?? 0,
      result: result is Map<String, dynamic>
          ? StudentExamResult.fromJson(result)
          : null,
      awaiting: json['awaiting'] as bool? ?? false,
    );
  }

  /// Exam statuses a student never sees (not yet distributed, cancelled).
  static const hiddenStatuses = {'draft', 'finalised', 'cancelled'};

  final String examId;
  final String title;
  final String code;

  /// Raw exam lifecycle value (e.g. `distributed`, `results_released`).
  final String status;
  final String? subjectName;

  /// Calendar date (local midnight).
  final DateTime? examDate;
  final int itemCount;
  final StudentExamResult? result;
  final bool awaiting;

  bool get isHidden => hiddenStatuses.contains(status);

  /// Card state as of [today] (a date with no time component).
  StudentExamState stateOn(DateTime today) {
    if (result != null) return StudentExamState.graded;
    if (awaiting) return StudentExamState.awaiting;
    final date = examDate;
    if (status == 'distributed' && date != null && date.isBefore(today)) {
      return StudentExamState.locked;
    }
    return StudentExamState.scan;
  }

  @override
  List<Object?> get props => [
        examId,
        title,
        code,
        status,
        subjectName,
        examDate,
        itemCount,
        result,
        awaiting,
      ];
}

/// Parses `YYYY-MM-DD` (or a full ISO timestamp) as a local calendar date,
/// so no timezone shift moves the day.
DateTime? _parseDate(dynamic value) {
  if (value is! String) return null;
  final m = RegExp(r'^(\d{4})-(\d{2})-(\d{2})').firstMatch(value);
  if (m == null) return null;
  return DateTime(
    int.parse(m.group(1)!),
    int.parse(m.group(2)!),
    int.parse(m.group(3)!),
  );
}
