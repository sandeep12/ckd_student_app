import 'package:ckd_design_system/ckd_design_system.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/format/formatters.dart';
import '../cubit/dashboard_cubit.dart';
import '../cubit/open_exam_cubit.dart';
import '../data/models/dashboard_models.dart';
import 'widgets/open_exam_form.dart';

/// Student dashboard (Figma 03 web / 04 mobile).
///
/// Expects [DashboardCubit] and [OpenExamCubit] above it (provided by the
/// app shell). [wide] picks the web layout.
class DashboardPage extends StatelessWidget {
  const DashboardPage({
    super.key,
    required this.wide,
    this.onViewAllExams,
    this.onViewAllNotifications,
    this.onViewAllResults,
  });

  final bool wide;
  final VoidCallback? onViewAllExams;
  final VoidCallback? onViewAllNotifications;
  final VoidCallback? onViewAllResults;

  @override
  Widget build(BuildContext context) {
    return BlocListener<OpenExamCubit, OpenExamState>(
      listenWhen: (a, b) =>
          b.status == OpenExamStatus.success && a.status != b.status,
      listener: (context, state) {
        final navigator = Navigator.of(context);
        if (navigator.canPop() && !wide) navigator.pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Found “${state.exam?.title}”. '
              'Scan and upload your paper in the CKD mobile app.',
            ),
          ),
        );
      },
      child: BlocBuilder<DashboardCubit, DashboardState>(
        builder: (context, state) {
          if (state.isLoading && state.dashboard == null) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(DsSpacing.layoutPageMargin),
                child: CircularProgressIndicator(
                  color: DsColors.actionPrimaryBg,
                ),
              ),
            );
          }
          if (state.status == DashboardStatus.failure &&
              state.dashboard == null) {
            return _Failure(wide: wide);
          }
          return wide
              ? _WebDashboard(
                  state: state,
                  onViewAllExams: onViewAllExams,
                  onViewAllNotifications: onViewAllNotifications,
                )
              : _MobileDashboard(
                  state: state,
                  onViewAllResults: onViewAllResults,
                );
        },
      ),
    );
  }
}

// ---------------------------------------------------------------- web ---

class _WebDashboard extends StatelessWidget {
  const _WebDashboard({
    required this.state,
    this.onViewAllExams,
    this.onViewAllNotifications,
  });

  final DashboardState state;
  final VoidCallback? onViewAllExams;
  final VoidCallback? onViewAllNotifications;

  static const double _hubWidth = 372;
  static const double _stackColumnsBelow = 860;

  @override
  Widget build(BuildContext context) {
    final d = state.dashboard!;
    final waiting = d.activeExams.length;
    final firstRun = waiting == 0 && state.results.isEmpty;

    return RefreshIndicator(
      onRefresh: context.read<DashboardCubit>().load,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(DsSpacing.layoutPageMargin),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final stacked = constraints.maxWidth < _stackColumnsBelow;
            final exams = _ActiveExamsSection(
              exams: d.activeExams,
              schoolName: d.schoolName,
              onViewAll: onViewAllExams,
            );
            final hub = _NotificationsHub(
              dashboard: d,
              onViewAll: onViewAllNotifications,
            );
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // PageHeader
                Text(
                  firstRun
                      ? 'Welcome, ${d.firstName}'
                      : 'Welcome back, ${d.firstName}',
                  style: DsTypography.h1,
                ),
                const SizedBox(height: DsSpacing.stackXs),
                Text(
                  _subtitle(waiting, firstRun),
                  style:
                      DsTypography.body.copyWith(color: DsColors.textSecondary),
                ),
                const SizedBox(height: DsSpacing.layoutSectionGap),
                _HeroJoin(stacked: stacked),
                const SizedBox(height: DsSpacing.layoutSectionGap),
                if (stacked) ...[
                  exams,
                  const SizedBox(height: DsSpacing.layoutGutter),
                  hub,
                ] else
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: exams),
                      const SizedBox(width: DsSpacing.layoutGutter),
                      SizedBox(width: _hubWidth, child: hub),
                    ],
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  static String _subtitle(int waiting, bool firstRun) {
    if (firstRun) {
      return 'Your first exam will appear here as soon as your teacher '
          'schedules it.';
    }
    if (waiting == 0) return 'You’re all caught up. Nothing is waiting on you.';
    final count = switch (waiting) {
      1 => 'One exam is',
      2 => 'Two exams are',
      3 => 'Three exams are',
      _ => '$waiting exams are',
    };
    return '$count waiting on you. Everything else is up to date.';
  }
}

class _HeroJoin extends StatelessWidget {
  const _HeroJoin({required this.stacked});

  final bool stacked;

  @override
  Widget build(BuildContext context) {
    final copy = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Ready for your next paper?', style: DsTypography.h2),
        const SizedBox(height: DsSpacing.stackSm),
        Text(
          'Enter the exam code printed at the top of your answer sheet to '
          'open the right exam. Scanning and uploading happen in the CKD '
          'mobile app.',
          style: DsTypography.body.copyWith(color: DsColors.textSecondary),
        ),
      ],
    );
    return DsCard(
      color: DsColors.surfaceBrandSubtle,
      child: stacked
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                copy,
                const SizedBox(height: DsSpacing.stackMd),
                const OpenExamForm(),
              ],
            )
          : Row(
              children: [
                Expanded(child: copy),
                const SizedBox(width: DsSpacing.layoutGutter),
                const OpenExamForm(),
              ],
            ),
    );
  }
}

class _ActiveExamsSection extends StatelessWidget {
  const _ActiveExamsSection({
    required this.exams,
    required this.schoolName,
    this.onViewAll,
  });

  final List<ActiveExam> exams;
  final String schoolName;
  final VoidCallback? onViewAll;

  /// The design shows two cards side by side.
  static const int _maxCards = 2;
  static const double _minCardWidth = 260;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text('My active exams', style: DsTypography.h3),
            ),
            if (exams.isNotEmpty) DsLink(label: 'View all', onTap: onViewAll),
          ],
        ),
        const SizedBox(height: DsSpacing.stackMd),
        if (exams.isEmpty)
          DsEmptyState(
            icon: Icons.home_outlined,
            title: 'No exams yet',
            message: 'Your teacher hasn’t scheduled an exam for you at '
                '$schoolName yet. When they do, it appears here and you '
                'are notified.',
          )
        else
          LayoutBuilder(
            builder: (context, constraints) {
              final perRow =
                  constraints.maxWidth >= _minCardWidth * 2 + DsSpacing.inlineMd
                      ? 2
                      : 1;
              final width =
                  (constraints.maxWidth - DsSpacing.inlineMd * (perRow - 1)) /
                      perRow;
              return Wrap(
                spacing: DsSpacing.inlineMd,
                runSpacing: DsSpacing.inlineMd,
                children: [
                  for (final exam in exams.take(_maxCards))
                    SizedBox(width: width, child: _ActiveExamCard(exam)),
                ],
              );
            },
          ),
      ],
    );
  }
}

class _ActiveExamCard extends StatelessWidget {
  const _ActiveExamCard(this.exam);

  final ActiveExam exam;

  @override
  Widget build(BuildContext context) {
    return DsExamCard(
      code: exam.code,
      title: exam.title,
      action: DsButton(
        label: 'Scan in the mobile app',
        size: DsButtonSize.md,
        onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Open the CKD mobile app and enter ${exam.code} to scan '
              'your paper.',
            ),
          ),
        ),
      ),
    );
  }
}

class _NotificationsHub extends StatelessWidget {
  const _NotificationsHub({required this.dashboard, this.onViewAll});

  final StudentDashboard dashboard;
  final VoidCallback? onViewAll;

  static const int _maxRows = 4;

  @override
  Widget build(BuildContext context) {
    final recent = dashboard.recentNotifications.take(_maxRows).toList();
    return DsCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text('Notifications', style: DsTypography.h4),
              ),
              if (dashboard.unreadNotifications > 0)
                DsBadge(label: '${dashboard.unreadNotifications} new'),
            ],
          ),
          const SizedBox(height: DsSpacing.stackMd),
          if (recent.isEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: DsSpacing.stackMd),
              child: Text(
                'You’re all caught up. New results and exam updates will '
                'show up here.',
                style:
                    DsTypography.bodySm.copyWith(color: DsColors.textSecondary),
              ),
            )
          else
            for (final n in recent) ...[
              DsNotificationRow(
                iconAsset: notificationIcon(n.eventKey),
                title: n.title,
                subtitle: n.body,
                timeAgo:
                    n.createdAt == null ? null : formatTimeAgo(n.createdAt!),
                muted: n.read,
                onTap: onViewAll,
              ),
              const SizedBox(height: DsSpacing.stackMd),
            ],
          DsButton(
            label: 'View all notifications',
            size: DsButtonSize.md,
            tone: DsButtonTone.secondary,
            onPressed: onViewAll,
          ),
        ],
      ),
    );
  }
}

/// Picks the row glyph from the notification's event key.
String notificationIcon(String? eventKey) {
  final key = (eventKey ?? '').toLowerCase();
  if (key.contains('result') || key.contains('release')) {
    return DsAssets.icCheckCircle;
  }
  if (key.contains('schedul') || key.contains('assign')) {
    return DsAssets.icCalendar;
  }
  if (key.contains('scan') || key.contains('upload') || key.contains('paper')) {
    return DsAssets.icUploadCloud;
  }
  if (key.contains('regrade') || key.contains('re-grade')) {
    return DsAssets.icClock;
  }
  return DsAssets.icBell;
}

// ------------------------------------------------------------- mobile ---

class _MobileDashboard extends StatelessWidget {
  const _MobileDashboard({required this.state, this.onViewAllResults});

  final DashboardState state;
  final VoidCallback? onViewAllResults;

  static const int _maxResults = 3;

  @override
  Widget build(BuildContext context) {
    final d = state.dashboard!;
    final results = state.results.take(_maxResults).toList();

    return RefreshIndicator(
      onRefresh: context.read<DashboardCubit>().load,
      child: ListView(
        padding: const EdgeInsets.all(DsSpacing.insetLg),
        children: [
          Text(
            'WELCOME BACK',
            style:
                DsTypography.overline.copyWith(color: DsColors.textSecondary),
          ),
          const SizedBox(height: DsSpacing.stackXs),
          Text(d.studentName, style: DsTypography.h3),
          const SizedBox(height: DsSpacing.stackLg),
          DsButton(
            label: 'Open an exam',
            onPressed: () => _showOpenExamSheet(context),
          ),
          const SizedBox(height: DsSpacing.stackLg),
          Text('Academic summary', style: DsTypography.h4),
          const SizedBox(height: DsSpacing.stackLg),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: DsStatTile(
                    label: 'Exams done',
                    value: '${state.results.length}',
                    iconAsset: DsAssets.icFileText,
                  ),
                ),
                const SizedBox(width: DsSpacing.inlineMd),
                Expanded(
                  child: DsStatTile(
                    label: 'Subjects',
                    value: '${state.subjectCount}',
                    iconAsset: DsAssets.icGraduationCap,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: DsSpacing.stackLg),
          Row(
            children: [
              Expanded(
                child: Text('Recent results', style: DsTypography.h4),
              ),
              if (results.isNotEmpty)
                DsLink(
                  label: 'View all',
                  touchRow: true,
                  onTap: onViewAllResults,
                ),
            ],
          ),
          const SizedBox(height: DsSpacing.stackLg),
          if (state.resultsUnavailable)
            const DsDangerBanner(
              message: 'We couldn’t load your results. Pull down to retry.',
            )
          else if (results.isEmpty)
            const DsEmptyState(
              icon: Icons.emoji_events_outlined,
              title: 'No results yet',
              message: 'Results appear here once your teacher releases them.',
            )
          else
            for (final r in results) ...[
              _ResultCard(r),
              const SizedBox(height: DsSpacing.stackMd),
            ],
        ],
      ),
    );
  }

  void _showOpenExamSheet(BuildContext context) {
    final cubit = context.read<OpenExamCubit>()..codeChanged('');
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: DsColors.surfaceRaised,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(DsRadii.overlay),
        ),
      ),
      builder: (sheetContext) => BlocProvider.value(
        value: cubit,
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            DsSpacing.insetLg,
            DsSpacing.insetXl,
            DsSpacing.insetLg,
            DsSpacing.insetLg + MediaQuery.viewInsetsOf(sheetContext).bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Open an exam', style: DsTypography.h3),
              const SizedBox(height: DsSpacing.stackXs),
              Text(
                'Enter the exam code printed at the top of your answer '
                'sheet.',
                style:
                    DsTypography.bodySm.copyWith(color: DsColors.textSecondary),
              ),
              const SizedBox(height: DsSpacing.stackLg),
              const OpenExamForm(compact: false),
            ],
          ),
        ),
      ),
    );
  }
}

class _ResultCard extends StatelessWidget {
  const _ResultCard(this.result);

  final ExamResult result;

  @override
  Widget build(BuildContext context) {
    final r = result;
    final hasScore = r.totalAwarded != null && r.totalMarks != null;
    return DsExamCard(
      code: r.code,
      title: r.title,
      score: r.percentage == null
          ? null
          : DsExamScore(
              value: '${r.percentage!.round()}%',
              caption: switch (r.passed) {
                true => 'Passed',
                false => 'Not passed',
                null => 'Released',
              },
              passed: r.passed,
            ),
      meta: [
        if (r.subjectName != null)
          DsExamMeta(
            iconAsset: DsAssets.icGraduationCapSm,
            label: r.subjectName!,
          ),
        if (r.examDate != null)
          DsExamMeta(
            iconAsset: DsAssets.icCalendarSm,
            label: formatDate(r.examDate!),
          ),
      ],
      status: DsExamStatus(
        iconAsset: DsAssets.icCheckCircle,
        message: 'Grade',
        trailing: [
          if (r.gradeBand != null) r.gradeBand!,
          if (hasScore)
            '(${formatNumber(r.totalAwarded!)}/${formatNumber(r.totalMarks!)})',
        ].join(' '),
      ),
    );
  }
}

// ------------------------------------------------------------ failure ---

class _Failure extends StatelessWidget {
  const _Failure({required this.wide});

  final bool wide;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(
        wide ? DsSpacing.layoutPageMargin : DsSpacing.insetLg,
      ),
      child: DsEmptyState(
        tone: DsEmptyStateTone.danger,
        icon: Icons.error_outline,
        title: 'We could not load your dashboard',
        message: 'The connection dropped while fetching your exams. Nothing '
            'has changed on your account — try again, or come back in a few '
            'minutes.',
        action: DsButton(
          label: 'Try again',
          size: DsButtonSize.md,
          expand: false,
          onPressed: context.read<DashboardCubit>().load,
        ),
      ),
    );
  }
}
