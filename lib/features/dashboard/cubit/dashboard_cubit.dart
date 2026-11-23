import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/api/api_exception.dart';
import '../data/dashboard_repository.dart';
import '../data/models/dashboard_models.dart';

part 'dashboard_state.dart';

class DashboardCubit extends Cubit<DashboardState> {
  DashboardCubit({required DashboardRepository repository})
      : _repository = repository,
        super(const DashboardState());

  final DashboardRepository _repository;

  /// Loads the dashboard. Results are secondary: if only `/results`
  /// fails, the dashboard still renders without the results section.
  Future<void> load() async {
    emit(state.copyWith(status: DashboardStatus.loading));
    try {
      final dashboardFuture = _repository.fetchDashboard();
      final resultsFuture = _repository
          .fetchResults()
          .then<List<ExamResult>?>((r) => r)
          .catchError((Object _) => null);

      final dashboard = await dashboardFuture;
      final results = await resultsFuture;
      emit(DashboardState(
        status: DashboardStatus.loaded,
        dashboard: dashboard,
        results: results ?? const [],
        resultsUnavailable: results == null,
      ));
    } on ApiException catch (e) {
      emit(state.copyWith(
        status: DashboardStatus.failure,
        errorMessage: () => e.message,
      ));
    }
  }
}
