import 'package:bloc_test/bloc_test.dart';
import 'package:ckd_student_app/core/api/api_exception.dart';
import 'package:ckd_student_app/features/auth/data/auth_repository.dart';
import 'package:ckd_student_app/features/dashboard/data/dashboard_repository.dart';
import 'package:ckd_student_app/features/dashboard/data/models/dashboard_models.dart';
import 'package:ckd_student_app/features/exams/cubit/my_exams_cubit.dart';
import 'package:ckd_student_app/features/exams/data/exams_repository.dart';
import 'package:ckd_student_app/features/exams/data/models/student_exam.dart';
import 'package:ckd_student_app/features/profile/cubit/profile_cubit.dart';
import 'package:ckd_student_app/features/profile/data/models/student_profile.dart';
import 'package:ckd_student_app/features/profile/data/profile_repository.dart';
import 'package:ckd_student_app/features/shell/view/student_shell.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

// Shape per the backend's StudentExam read model (GET /student-exams).
final _exams = [
  for (final j in const [
    {
      'examId': 'a',
      'title': 'Mathematics Midterm',
      'code': 'MATH201-B2',
      'subjectName': 'Gen Math',
      'examDate': '2026-12-20',
      'status': 'distributed',
      'itemCount': 25,
      'result': null,
      'awaiting': false,
    },
    {
      'examId': 'b',
      'title': 'Advanced Physics II',
      'code': 'PHYS210-A1',
      'subjectName': 'Physics',
      'examDate': '2026-11-18',
      'status': 'distributed',
      'itemCount': 30,
      'result': null,
      'awaiting': true,
    },
    {
      'examId': 'c',
      'title': 'Filipino sa Piling Larangan',
      'code': 'FIL110-C3',
      'subjectName': 'Filipino',
      'examDate': '2026-11-12',
      'status': 'results_released',
      'itemCount': 20,
      'result': {'percent': 88, 'passed': true, 'gradeLabel': 'B+ (88/100)'},
      'awaiting': false,
    },
    {
      'examId': 'd',
      'title': 'Araling Panlipunan',
      'code': 'AP120-D2',
      'subjectName': 'Soc. Studies',
      'examDate': '2026-11-08',
      'status': 'distributed',
      'itemCount': 40,
      'result': null,
      'awaiting': false,
    },
  ])
    StudentExam.fromJson(j),
];

class _FakeExams implements ExamsRepository {
  _FakeExams({this.fail = false});
  final bool fail;

  @override
  Future<List<StudentExam>> fetchExams() async {
    if (fail) throw const ApiException.network();
    return _exams;
  }
}

class _FakeProfile implements ProfileRepository {
  String? roll = '11-SI-24';

  @override
  Future<StudentProfile> fetchProfile() async => StudentProfile(
        fullName: 'Alex Ramos',
        className: 'Grade 11',
        rollNumber: roll,
        firstRunCompleted: true,
        email: 'alex@example.com',
      );

  @override
  Future<StudentProfile> saveRollNumber(String rollNumber) async {
    if (rollNumber == 'BAD') {
      throw const ApiException(
        message: 'Invalid input',
        code: 'VALIDATION_ERROR',
        statusCode: 400,
        fieldErrors: {'rollNumber': 'Too odd.'},
      );
    }
    roll = rollNumber;
    return fetchProfile();
  }

  @override
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {}
}

class _FakeDashboard implements DashboardRepository {
  @override
  Future<StudentDashboard> fetchDashboard() async =>
      StudentDashboard.fromJson(const {
        'studentName': 'Alex Ramos',
        'firstName': 'Alex',
        'schoolName': 'Horizon',
        'activeExams': [],
        'exams': {'active': 0, 'upcoming': 0},
        'notifications': {'unread': 0, 'recent': []},
      });

  @override
  Future<List<ExamResult>> fetchResults() async => const [];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _NoopAuth implements AuthRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

final _today = DateTime(2026, 11, 23);

void main() {
  group('StudentExam.stateOn', () {
    test('derives scan / awaiting / graded / locked', () {
      expect(_exams.map((e) => e.stateOn(_today)), [
        StudentExamState.scan,
        StudentExamState.awaiting,
        StudentExamState.graded,
        StudentExamState.locked,
      ]);
    });

    test('hides draft and cancelled exams', () {
      expect(
        StudentExam.fromJson(const {'status': 'cancelled'}).isHidden,
        isTrue,
      );
    });
  });

  group('MyExamsCubit', () {
    blocTest<MyExamsCubit, MyExamsState>(
      'loads and filters',
      build: () => MyExamsCubit(repository: _FakeExams(), clock: () => _today),
      act: (c) async {
        await c.load();
        c.setFilter(MyExamsFilter.graded);
      },
      skip: 2,
      expect: () => [
        isA<MyExamsState>()
            .having((s) => s.visible.map((e) => e.examId), 'visible', ['c']),
      ],
    );

    blocTest<MyExamsCubit, MyExamsState>(
      'search matches code and subject',
      build: () => MyExamsCubit(repository: _FakeExams(), clock: () => _today),
      act: (c) async {
        await c.load();
        c.search('phys');
      },
      skip: 2,
      expect: () => [
        isA<MyExamsState>()
            .having((s) => s.visible.map((e) => e.examId), 'visible', ['b']),
      ],
    );

    blocTest<MyExamsCubit, MyExamsState>(
      'fails',
      build: () => MyExamsCubit(repository: _FakeExams(fail: true)),
      act: (c) => c.load(),
      skip: 1,
      expect: () => [
        isA<MyExamsState>()
            .having((s) => s.status, 'status', MyExamsStatus.failure),
      ],
    );
  });

  group('ProfileCubit', () {
    blocTest<ProfileCubit, ProfileState>(
      'rejects an empty roll number locally',
      build: () => ProfileCubit(repository: _FakeProfile()),
      act: (c) => c.saveRollNumber('  '),
      expect: () => [
        isA<ProfileState>()
            .having((s) => s.fieldError, 'error', 'Enter your roll number.'),
      ],
    );

    blocTest<ProfileCubit, ProfileState>(
      'maps a backend field error',
      build: () => ProfileCubit(repository: _FakeProfile()),
      act: (c) => c.saveRollNumber('BAD'),
      skip: 1,
      expect: () => [
        isA<ProfileState>()
            .having((s) => s.saveStatus, 'save', SaveStatus.failed)
            .having((s) => s.fieldError, 'field', 'Too odd.'),
      ],
    );

    blocTest<ProfileCubit, ProfileState>(
      'saves and keeps the email',
      build: () => ProfileCubit(repository: _FakeProfile()),
      act: (c) async {
        await c.load();
        c.startEditing();
        await c.saveRollNumber('12-A-01');
      },
      verify: (c) {
        expect(c.state.saveStatus, SaveStatus.saved);
        expect(c.state.editing, isFalse);
        expect(c.state.profile?.rollNumber, '12-A-01');
        expect(c.state.profile?.email, 'alex@example.com');
      },
    );
  });

  Widget shell() => RepositoryProvider<AuthRepository>(
        create: (_) => _NoopAuth(),
        child: MaterialApp(
          home: StudentShell(
            dashboardRepository: _FakeDashboard(),
            examsRepository: _FakeExams(),
            profileRepository: _FakeProfile(),
          ),
        ),
      );

  for (final (name, size) in [
    ('web', const Size(1440, 900)),
    ('mobile', const Size(390, 844)),
  ]) {
    testWidgets('$name: My Exams and Profile render', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(shell());
      await tester.pumpAndSettle();

      await tester.tap(find.text(name == 'web' ? 'My Exams' : 'Exams').last);
      await tester.pumpAndSettle();
      expect(find.text('CODE: MATH201-B2'), findsOneWidget);
      expect(find.text('Paper uploaded. Awaiting results.'), findsOneWidget);
      expect(find.text('B+ (88/100)'), findsOneWidget);
      expect(tester.takeException(), isNull);

      await tester.tap(find.text('Profile').last);
      await tester.pumpAndSettle();
      expect(find.text('Alex Ramos'), findsWidgets);
      expect(find.text('alex@example.com'), findsOneWidget);
      expect(find.text('11-SI-24'), findsOneWidget);
      expect(find.text('Log out'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
