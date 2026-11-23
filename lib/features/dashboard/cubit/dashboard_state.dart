part of 'dashboard_cubit.dart';

enum DashboardStatus { initial, loading, loaded, failure }

class DashboardState extends Equatable {
  const DashboardState({
    this.status = DashboardStatus.initial,
    this.dashboard,
    this.results = const [],
    this.resultsUnavailable = false,
    this.errorMessage,
  });

  final DashboardStatus status;
  final StudentDashboard? dashboard;

  /// Released results, newest first.
  final List<ExamResult> results;

  /// True when `/results` failed but the dashboard itself loaded.
  final bool resultsUnavailable;

  final String? errorMessage;

  bool get isLoading =>
      status == DashboardStatus.initial || status == DashboardStatus.loading;

  /// Distinct subjects across released results.
  int get subjectCount =>
      results.map((r) => r.subjectName).whereType<String>().toSet().length;

  DashboardState copyWith({
    DashboardStatus? status,
    String? Function()? errorMessage,
  }) {
    return DashboardState(
      status: status ?? this.status,
      dashboard: dashboard,
      results: results,
      resultsUnavailable: resultsUnavailable,
      errorMessage: errorMessage != null ? errorMessage() : this.errorMessage,
    );
  }

  @override
  List<Object?> get props =>
      [status, dashboard, results, resultsUnavailable, errorMessage];
}
