import '../../../core/api/authorized_api.dart';
import 'models/student_exam.dart';

/// The signed-in student's own exam list (`GET /student-exams`).
class ExamsRepository {
  ExamsRepository({required AuthorizedApi api}) : _api = api;

  final AuthorizedApi _api;

  /// Visible exams, newest exam date first (undated last).
  Future<List<StudentExam>> fetchExams() async {
    final data = await _api.get('/student-exams');
    final exams = data is List
        ? data
            .whereType<Map<String, dynamic>>()
            .map(StudentExam.fromJson)
            .where((e) => !e.isHidden)
            .toList()
        : <StudentExam>[];
    exams.sort((a, b) {
      final ad = a.examDate, bd = b.examDate;
      if (ad == null && bd == null) return 0;
      if (ad == null) return 1;
      if (bd == null) return -1;
      return bd.compareTo(ad);
    });
    return exams;
  }
}
