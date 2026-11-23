import 'package:bloc_test/bloc_test.dart';
import 'package:ckd_student_app/core/api/api_exception.dart';
import 'package:ckd_student_app/features/auth/data/auth_repository.dart';
import 'package:ckd_student_app/features/dashboard/cubit/dashboard_cubit.dart';
import 'package:ckd_student_app/features/dashboard/cubit/open_exam_cubit.dart';
import 'package:ckd_student_app/features/dashboard/data/dashboard_repository.dart';
import 'package:ckd_student_app/features/dashboard/data/models/dashboard_models.dart';
import 'package:ckd_student_app/features/shell/view/student_shell.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

// Shapes captured from the live API (GET /student-dashboard, GET /results).
final _dashboard = StudentDashboard.fromJson(const {
  'studentName': 'student1-dms1',
  'firstName': 'student1-dms1',
  'schoolName': 'demo-school-1',
  'activeExams': [
    {'examId': 'e1', 'title': 'realnumbers4', 'code': 'MATH-10A-A23A'},
    {'examId': 'e2', 'title': 'realnumbers3', 'code': 'MATH-10A-D2F4'},
  ],
  'exams': {'active': 2, 'upcoming': 0},
  'notifications': {'unread': 0, 'recent': []},
});

final _results = [
  ExamResult.fromJson(const {
    'examId': 'r1',
    'title': 'test-exam-2 (copy)',
    'code': 'MATH-10A-2288',
    'subjectName': 'Maths',
    'examDate': '2026-09-03',
    'totalAwarded': 21,
    'totalMarks': 23,
    'percentage': 91,
    'passed': true,
    'gradeBand': 'A',
  }),
];

class _FakeDashboardRepository implements DashboardRepository {
  _FakeDashboardRepository({
    this.failDashboard = false,
    this.failResults = false,
  });

  bool failDashboard;
  final bool failResults;

  @override
  Future<StudentDashboard> fetchDashboard() async {
    if (failDashboard) throw const ApiException.network();
    return _dashboard;
  }

  @override
  Future<List<ExamResult>> fetchResults() async {
    if (failResults) throw const ApiException.network();
    return _results;
  }

  @override
  Future<ResolvedExam> resolveExamCode(String code) async {
    if (code != 'MATH-10A-A23A') {
      throw const ApiException(
        message: 'We couldn\'t find an exam open for that code.',
        code: 'STUDENT_SCAN_CODE_NOT_FOUND',
        statusCode: 404,
      );
    }
    return ResolvedExam(examId: 'e1', code: code, title: 'realnumbers4');
  }
}

class _NoopAuthRepository implements AuthRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Widget _shell(DashboardRepository repo) => RepositoryProvider<AuthRepository>(
      create: (_) => _NoopAuthRepository(),
      child: MaterialApp(home: StudentShell(dashboardRepository: repo)),
    );

void main() {
  group('DashboardCubit', () {
    blocTest<DashboardCubit, DashboardState>(
      'loads dashboard and results',
      build: () => DashboardCubit(repository: _FakeDashboardRepository()),
      act: (c) => c.load(),
      expect: () => [
        isA<DashboardState>()
            .having((s) => s.status, 'status', DashboardStatus.loading),
        isA<DashboardState>()
            .having((s) => s.status, 'status', DashboardStatus.loaded)
            .having((s) => s.dashboard?.activeExams.length, 'active', 2)
            .having((s) => s.subjectCount, 'subjects', 1),
      ],
    );

    blocTest<DashboardCubit, DashboardState>(
      'still loads when only results fail',
      build: () => DashboardCubit(
        repository: _FakeDashboardRepository(failResults: true),
      ),
      act: (c) => c.load(),
      skip: 1,
      expect: () => [
        isA<DashboardState>()
            .having((s) => s.status, 'status', DashboardStatus.loaded)
            .having((s) => s.resultsUnavailable, 'resultsUnavailable', true),
      ],
    );

    blocTest<DashboardCubit, DashboardState>(
      'fails when the dashboard fails',
      build: () => DashboardCubit(
        repository: _FakeDashboardRepository(failDashboard: true),
      ),
      act: (c) => c.load(),
      skip: 1,
      expect: () => [
        isA<DashboardState>()
            .having((s) => s.status, 'status', DashboardStatus.failure),
      ],
    );
  });

  group('OpenExamCubit', () {
    blocTest<OpenExamCubit, OpenExamState>(
      'resolves a valid code',
      build: () => OpenExamCubit(repository: _FakeDashboardRepository()),
      act: (c) => c
        ..codeChanged('MATH-10A-A23A')
        ..submit(),
      skip: 2,
      expect: () => [
        isA<OpenExamState>()
            .having((s) => s.status, 'status', OpenExamStatus.success)
            .having((s) => s.exam?.title, 'title', 'realnumbers4'),
      ],
    );

    blocTest<OpenExamCubit, OpenExamState>(
      'surfaces the backend message for an unknown code',
      build: () => OpenExamCubit(repository: _FakeDashboardRepository()),
      act: (c) => c
        ..codeChanged('NOPE')
        ..submit(),
      skip: 2,
      expect: () => [
        isA<OpenExamState>()
            .having((s) => s.status, 'status', OpenExamStatus.failure)
            .having((s) => s.errorMessage, 'message', contains('couldn')),
      ],
    );

    blocTest<OpenExamCubit, OpenExamState>(
      'asks for a code when empty',
      build: () => OpenExamCubit(repository: _FakeDashboardRepository()),
      act: (c) => c.submit(),
      expect: () => [
        isA<OpenExamState>()
            .having((s) => s.status, 'status', OpenExamStatus.failure),
      ],
    );
  });

  group('StudentShell', () {
    testWidgets('web layout shows sidebar, hero and active exams',
        (tester) async {
      tester.view.physicalSize = const Size(1440, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(_shell(_FakeDashboardRepository()));
      await tester.pumpAndSettle();

      expect(find.text('Academic Portal'), findsOneWidget);
      expect(find.text('Welcome back, student1-dms1'), findsOneWidget);
      expect(
        find.text('Two exams are waiting on you. Everything else is up to '
            'date.'),
        findsOneWidget,
      );
      expect(find.text('Ready for your next paper?'), findsOneWidget);
      expect(find.text('CODE: MATH-10A-A23A'), findsOneWidget);
      expect(find.text('Scan in the mobile app'), findsNWidgets(2));
      expect(find.text('View all notifications'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('mobile layout shows summary and recent results',
        (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(_shell(_FakeDashboardRepository()));
      await tester.pumpAndSettle();

      expect(find.text('WELCOME BACK'), findsOneWidget);
      expect(find.text('Open an exam'), findsOneWidget);
      expect(find.text('EXAMS DONE'), findsOneWidget);
      expect(find.text('91%'), findsOneWidget);
      expect(find.text('A (21/23)'), findsOneWidget);
      expect(find.text('Grades'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('failure state retries', (tester) async {
      tester.view.physicalSize = const Size(1440, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      final repo = _FakeDashboardRepository(failDashboard: true);
      await tester.pumpWidget(_shell(repo));
      await tester.pumpAndSettle();
      expect(find.text('We could not load your dashboard'), findsOneWidget);

      repo.failDashboard = false;
      await tester.tap(find.text('Try again'));
      await tester.pumpAndSettle();
      expect(find.text('Ready for your next paper?'), findsOneWidget);
    });

    testWidgets('tab bar switches sections', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(_shell(_FakeDashboardRepository()));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Profile'));
      await tester.pumpAndSettle();
      expect(find.text('Sign out'), findsOneWidget);
    });
  });
}
