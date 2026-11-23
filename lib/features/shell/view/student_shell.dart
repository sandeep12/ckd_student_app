import 'package:ckd_design_system/ckd_design_system.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_config.dart';
import '../../../core/api/authorized_api.dart';
import '../../../core/storage/token_storage.dart';
import '../../auth/data/auth_repository.dart';
import '../../auth/view/login_page.dart';
import '../../dashboard/cubit/dashboard_cubit.dart';
import '../../dashboard/cubit/open_exam_cubit.dart';
import '../../dashboard/data/dashboard_repository.dart';
import '../../dashboard/view/dashboard_page.dart';
import '../../exams/cubit/my_exams_cubit.dart';
import '../../exams/data/models/student_exam.dart';
import '../../exams/data/exams_repository.dart';
import '../../exams/view/my_exams_page.dart';
import '../../profile/cubit/profile_cubit.dart';
import '../../profile/data/profile_repository.dart';
import '../../profile/view/profile_page.dart';
import 'placeholder_section.dart';

/// Top-level sections of the student app.
enum ShellSection { dashboard, exams, grades, notifications, profile }

/// Signed-in app shell.
///
/// ≥ [wideBreakpoint]: cobalt TopBar + SidebarNav + floating page panel
/// (web). Below: light app bar + bottom TabBar (mobile).
class StudentShell extends StatefulWidget {
  const StudentShell({
    super.key,
    this.dashboardRepository,
    this.examsRepository,
    this.profileRepository,
  });

  /// Injectable for tests.
  final DashboardRepository? dashboardRepository;
  final ExamsRepository? examsRepository;
  final ProfileRepository? profileRepository;

  static const double wideBreakpoint = 900;

  static Route<void> route() =>
      MaterialPageRoute(builder: (_) => const StudentShell());

  @override
  State<StudentShell> createState() => _StudentShellState();
}

class _StudentShellState extends State<StudentShell> {
  static const _webSections = [
    ShellSection.dashboard,
    ShellSection.exams,
    ShellSection.notifications,
    ShellSection.profile,
  ];
  static const _webDestinations = [
    DsNavDestination(label: 'Dashboard', iconAsset: DsAssets.icLayoutGrid),
    DsNavDestination(label: 'My Exams', iconAsset: DsAssets.icClipboardList),
    DsNavDestination(label: 'Notifications', iconAsset: DsAssets.icBell),
    DsNavDestination(label: 'Profile', iconAsset: DsAssets.icUser),
  ];

  static const _mobileSections = [
    ShellSection.dashboard,
    ShellSection.exams,
    ShellSection.grades,
    ShellSection.profile,
  ];
  static const _mobileDestinations = [
    DsNavDestination(label: 'Home', iconAsset: DsAssets.icLayoutGrid),
    DsNavDestination(label: 'Exams', iconAsset: DsAssets.icClipboardList),
    DsNavDestination(label: 'Grades', iconAsset: DsAssets.icAward),
    DsNavDestination(label: 'Profile', iconAsset: DsAssets.icUser),
  ];

  ShellSection _section = ShellSection.dashboard;
  late final DashboardRepository _repository;
  late final ProfileRepository _profileRepository;
  late final DashboardCubit _dashboardCubit;
  late final OpenExamCubit _openExamCubit;
  late final MyExamsCubit _myExamsCubit;
  late final ProfileCubit _profileCubit;

  @override
  void initState() {
    super.initState();
    final auth = context.read<AuthRepository>();
    final tokens = TokenStorage();
    final api = AuthorizedApi(
      apiClient: ApiClient(baseUrl: ApiConfig.baseUrl),
      tokenStorage: tokens,
      refreshSession: auth.refresh,
      onSessionExpired: _signOut,
    );
    _repository = widget.dashboardRepository ?? DashboardRepository(api: api);
    _profileRepository = widget.profileRepository ??
        ProfileRepository(api: api, tokenStorage: tokens);
    _dashboardCubit = DashboardCubit(repository: _repository)..load();
    _openExamCubit = OpenExamCubit(repository: _repository);
    // Loaded on first visit to each section.
    _myExamsCubit = MyExamsCubit(
      repository: widget.examsRepository ?? ExamsRepository(api: api),
    );
    _profileCubit = ProfileCubit(repository: _profileRepository);
  }

  @override
  void dispose() {
    _dashboardCubit.close();
    _openExamCubit.close();
    _myExamsCubit.close();
    _profileCubit.close();
    super.dispose();
  }

  void _go(ShellSection section) {
    if (section == ShellSection.exams &&
        _myExamsCubit.state.status == MyExamsStatus.initial) {
      _myExamsCubit.load();
    }
    if (section == ShellSection.profile &&
        _profileCubit.state.status == ProfileStatus.initial) {
      _profileCubit.load();
    }
    setState(() => _section = section);
  }

  void _onScan(StudentExam exam) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Scanning “${exam.title}” is coming in the Scan Paper module.',
        ),
      ),
    );
  }

  Future<void> _signOut() async {
    final navigator = Navigator.of(context);
    try {
      await context.read<AuthRepository>().logout();
    } on Object {
      // Local tokens are cleared regardless.
    }
    if (!mounted) return;
    navigator.pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (route) => false,
    );
  }

  Widget _body(bool wide) {
    return switch (_section) {
      ShellSection.dashboard => DashboardPage(
          wide: wide,
          onViewAllExams: () => _go(ShellSection.exams),
          onViewAllNotifications: () => _go(ShellSection.notifications),
          onViewAllResults: () => _go(ShellSection.grades),
        ),
      ShellSection.exams => MyExamsPage(
          wide: wide,
          onScan: wide ? null : _onScan,
        ),
      ShellSection.grades => const PlaceholderSection(
          title: 'Grades',
          message: 'Your grades overview is coming in a later module.',
        ),
      ShellSection.notifications => const PlaceholderSection(
          title: 'Notifications',
          message: 'The full notifications inbox is coming in a later module.',
        ),
      ShellSection.profile => ProfilePage(
          wide: wide,
          onSignOut: _signOut,
          schoolName: _dashboardCubit.state.dashboard?.schoolName,
        ),
    };
  }

  @override
  Widget build(BuildContext context) {
    return RepositoryProvider.value(
      value: _profileRepository,
      child: MultiBlocProvider(
        providers: [
          BlocProvider.value(value: _dashboardCubit),
          BlocProvider.value(value: _openExamCubit),
          BlocProvider.value(value: _myExamsCubit),
          BlocProvider.value(value: _profileCubit),
        ],
        child: LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= StudentShell.wideBreakpoint;
            return BlocBuilder<DashboardCubit, DashboardState>(
              buildWhen: (a, b) => a.dashboard != b.dashboard,
              builder: (context, state) {
                final hasUnread =
                    (state.dashboard?.unreadNotifications ?? 0) > 0;
                return wide
                    ? _buildWeb(state, hasUnread)
                    : _buildMobile(hasUnread);
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildWeb(DashboardState state, bool hasUnread) {
    final d = state.dashboard;
    return Scaffold(
      backgroundColor: DsColors.surfaceShell,
      body: Column(
        children: [
          DsTopBar(
            hasUnread: hasUnread,
            onBellTap: () => _go(ShellSection.notifications),
          ),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                DsSidebarNav(
                  title: 'Academic Portal',
                  subtitle: d?.schoolName,
                  destinations: _webDestinations,
                  selectedIndex: _webSections.indexOf(_section),
                  onSelected: (i) => _go(_webSections[i]),
                  userName: d?.studentName ?? '',
                  userCaption: d?.schoolName,
                  onUserTap: () => _go(ShellSection.profile),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(
                      top: DsSpacing.insetXl,
                      right: DsSpacing.layoutPageMargin,
                      bottom: DsSpacing.insetXl,
                    ),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: DsColors.surfacePage,
                        borderRadius: BorderRadius.circular(DsRadii.overlay),
                        boxShadow: DsElevation.modal,
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(DsRadii.overlay),
                        child: _body(true),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobile(bool hasUnread) {
    final index = _mobileSections.indexOf(_section);
    return Scaffold(
      backgroundColor: DsColors.surfacePage,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            DsMobileAppBar(
              hasUnread: hasUnread,
              onBellTap: () => _go(ShellSection.notifications),
            ),
            Expanded(child: _body(false)),
          ],
        ),
      ),
      bottomNavigationBar: DsTabBar(
        destinations: _mobileDestinations,
        // Notifications is reached from the bell, not a tab.
        selectedIndex: index,
        onSelected: (i) => _go(_mobileSections[i]),
      ),
    );
  }
}
