import '../../../core/api/authorized_api.dart';
import 'models/dashboard_models.dart';

/// Student dashboard data (`/student-dashboard`, `/results`,
/// `/student/exams/resolve-code`).
class DashboardRepository {
  DashboardRepository({required AuthorizedApi api}) : _api = api;

  final AuthorizedApi _api;

  Future<StudentDashboard> fetchDashboard() async {
    final data = await _api.get('/student-dashboard');
    return StudentDashboard.fromJson(
      data is Map<String, dynamic> ? data : const {},
    );
  }

  /// Released results, newest exam first.
  Future<List<ExamResult>> fetchResults() async {
    final data = await _api.get('/results');
    final results = data is List
        ? data
            .whereType<Map<String, dynamic>>()
            .map(ExamResult.fromJson)
            .toList()
        : <ExamResult>[];
    results.sort((a, b) {
      final ad = a.examDate, bd = b.examDate;
      if (ad == null && bd == null) return 0;
      if (ad == null) return 1;
      if (bd == null) return -1;
      return bd.compareTo(ad);
    });
    return results;
  }

  /// Throws `ApiException` with `STUDENT_SCAN_CODE_NOT_FOUND` for an
  /// unknown or closed code.
  Future<ResolvedExam> resolveExamCode(String code) async {
    final data = await _api.post(
      '/student/exams/resolve-code',
      body: {'code': code.trim().toUpperCase()},
    );
    return ResolvedExam.fromJson(
      data is Map<String, dynamic> ? data : const {},
    );
  }
}
