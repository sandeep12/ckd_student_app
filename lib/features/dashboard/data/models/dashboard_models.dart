import 'package:equatable/equatable.dart';

/// `GET /student-dashboard`.
class StudentDashboard extends Equatable {
  const StudentDashboard({
    required this.studentName,
    required this.firstName,
    required this.schoolName,
    required this.activeExams,
    required this.activeCount,
    required this.upcomingCount,
    required this.unreadNotifications,
    required this.recentNotifications,
  });

  factory StudentDashboard.fromJson(Map<String, dynamic> json) {
    final exams = _map(json['exams']);
    final notifications = _map(json['notifications']);
    return StudentDashboard(
      studentName: json['studentName'] as String? ?? '',
      firstName:
          json['firstName'] as String? ?? json['studentName'] as String? ?? '',
      schoolName: json['schoolName'] as String? ?? '',
      activeExams: _list(json['activeExams'])
          .map(ActiveExam.fromJson)
          .toList(growable: false),
      activeCount: (exams['active'] as num?)?.toInt() ?? 0,
      upcomingCount: (exams['upcoming'] as num?)?.toInt() ?? 0,
      unreadNotifications: (notifications['unread'] as num?)?.toInt() ?? 0,
      recentNotifications: _list(notifications['recent'])
          .map(DashboardNotification.fromJson)
          .toList(growable: false),
    );
  }

  final String studentName;
  final String firstName;
  final String schoolName;
  final List<ActiveExam> activeExams;
  final int activeCount;
  final int upcomingCount;
  final int unreadNotifications;
  final List<DashboardNotification> recentNotifications;

  @override
  List<Object?> get props => [
        studentName,
        firstName,
        schoolName,
        activeExams,
        activeCount,
        upcomingCount,
        unreadNotifications,
        recentNotifications,
      ];
}

/// An exam the student still needs to scan (`activeExams[]`).
class ActiveExam extends Equatable {
  const ActiveExam({
    required this.examId,
    required this.title,
    required this.code,
  });

  factory ActiveExam.fromJson(Map<String, dynamic> json) => ActiveExam(
        examId: json['examId'] as String? ?? '',
        title: json['title'] as String? ?? '',
        code: json['code'] as String? ?? '',
      );

  final String examId;
  final String title;
  final String code;

  @override
  List<Object?> get props => [examId, title, code];
}

/// A notification preview (`notifications.recent[]`).
///
/// The backend's field names aren't documented and the seeded student has
/// none yet, so parsing is lenient across the likely keys.
class DashboardNotification extends Equatable {
  const DashboardNotification({
    required this.id,
    required this.title,
    this.body,
    this.createdAt,
    this.eventKey,
    this.read = false,
  });

  factory DashboardNotification.fromJson(Map<String, dynamic> json) {
    String? str(List<String> keys) {
      for (final k in keys) {
        final v = json[k];
        if (v is String && v.isNotEmpty) return v;
      }
      return null;
    }

    return DashboardNotification(
      id: str(['id', 'notificationId']) ?? '',
      title: str(['title', 'subject', 'headline']) ??
          str(['eventKey', 'type']) ??
          'Notification',
      body: str(['body', 'message', 'summary', 'description']),
      createdAt: DateTime.tryParse(str(['createdAt', 'sentAt']) ?? ''),
      eventKey: str(['eventKey', 'type', 'event']),
      read: json['acknowledgedAt'] != null || json['read'] == true,
    );
  }

  final String id;
  final String title;
  final String? body;
  final DateTime? createdAt;
  final String? eventKey;
  final bool read;

  @override
  List<Object?> get props => [id, title, body, createdAt, eventKey, read];
}

/// A released exam result (`GET /results` item).
class ExamResult extends Equatable {
  const ExamResult({
    required this.examId,
    required this.title,
    required this.code,
    this.subjectName,
    this.examDate,
    this.totalAwarded,
    this.totalMarks,
    this.percentage,
    this.passed,
    this.gradeBand,
  });

  factory ExamResult.fromJson(Map<String, dynamic> json) => ExamResult(
        examId: json['examId'] as String? ?? '',
        title: json['title'] as String? ?? '',
        code: json['code'] as String? ?? '',
        subjectName: json['subjectName'] as String?,
        examDate: DateTime.tryParse(json['examDate'] as String? ?? ''),
        totalAwarded: (json['totalAwarded'] as num?)?.toDouble(),
        totalMarks: (json['totalMarks'] as num?)?.toDouble(),
        percentage: (json['percentage'] as num?)?.toDouble(),
        passed: json['passed'] as bool?,
        gradeBand: json['gradeBand'] as String?,
      );

  final String examId;
  final String title;
  final String code;
  final String? subjectName;
  final DateTime? examDate;
  final double? totalAwarded;
  final double? totalMarks;
  final double? percentage;
  final bool? passed;
  final String? gradeBand;

  @override
  List<Object?> get props => [
        examId,
        title,
        code,
        subjectName,
        examDate,
        totalAwarded,
        totalMarks,
        percentage,
        passed,
        gradeBand,
      ];
}

/// `POST /student/exams/resolve-code` result.
class ResolvedExam extends Equatable {
  const ResolvedExam({
    required this.examId,
    required this.code,
    required this.title,
  });

  factory ResolvedExam.fromJson(Map<String, dynamic> json) => ResolvedExam(
        examId: json['examId'] as String? ?? '',
        code: json['code'] as String? ?? '',
        title: json['title'] as String? ?? '',
      );

  final String examId;
  final String code;
  final String title;

  @override
  List<Object?> get props => [examId, code, title];
}

Map<String, dynamic> _map(dynamic v) =>
    v is Map<String, dynamic> ? v : const {};

Iterable<Map<String, dynamic>> _list(dynamic v) =>
    v is List ? v.whereType<Map<String, dynamic>>() : const [];
