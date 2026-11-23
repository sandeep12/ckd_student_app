import 'package:ckd_design_system/ckd_design_system.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/format/formatters.dart';
import '../cubit/my_exams_cubit.dart';
import '../data/models/student_exam.dart';

/// My Exams (Figma 06 web / 07 mobile). Expects [MyExamsCubit] above it.
class MyExamsPage extends StatelessWidget {
  const MyExamsPage({super.key, required this.wide, this.onScan});

  final bool wide;

  /// Mobile "Scan Paper" action. Web shows an informational button only —
  /// scanning happens in the mobile app.
  final void Function(StudentExam exam)? onScan;

  static const double searchWidth = 320;
  static const double _twoColumnsFrom = 720;

  @override
  Widget build(BuildContext context) {
    final pad = wide ? DsSpacing.layoutPageMargin : DsSpacing.insetLg;
    return BlocBuilder<MyExamsCubit, MyExamsState>(
      builder: (context, state) {
        final cubit = context.read<MyExamsCubit>();
        return RefreshIndicator(
          onRefresh: cubit.load,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.all(pad),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (wide) ...[
                  Text('My exams', style: DsTypography.h1),
                  const SizedBox(height: DsSpacing.stackXs),
                  Text(
                    _subtitle(state),
                    style: DsTypography.body
                        .copyWith(color: DsColors.textSecondary),
                  ),
                  const SizedBox(height: DsSpacing.layoutSectionGap),
                ],
                _Toolbar(state: state, wide: wide),
                const SizedBox(height: DsSpacing.layoutSectionGap),
                _body(context, state),
              ],
            ),
          ),
        );
      },
    );
  }

  String _subtitle(MyExamsState state) {
    const tail = 'Scanning and uploading happen in the CKD mobile app.';
    if (state.status != MyExamsStatus.loaded) return tail;
    final n = state.exams.length;
    return n == 1 ? 'One exam. $tail' : '$n exams. $tail';
  }

  Widget _body(BuildContext context, MyExamsState state) {
    final cubit = context.read<MyExamsCubit>();
    if (state.isLoading && state.exams.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(DsSpacing.layoutPageMargin),
        child: Center(
          child: CircularProgressIndicator(color: DsColors.actionPrimaryBg),
        ),
      );
    }
    if (state.status == MyExamsStatus.failure && state.exams.isEmpty) {
      return DsEmptyState(
        tone: DsEmptyStateTone.danger,
        icon: Icons.error_outline,
        title: 'Couldn’t load your exams',
        message: 'Something went wrong. Check your connection and try again.',
        action: DsButton(
          label: 'Try again',
          size: DsButtonSize.md,
          expand: false,
          onPressed: cubit.load,
        ),
      );
    }
    if (state.exams.isEmpty) {
      return const DsEmptyState(
        icon: Icons.assignment_outlined,
        title: 'No exams yet',
        message: 'When a teacher schedules an exam for you, it will show up '
            'here.',
      );
    }
    final visible = state.visible;
    if (visible.isEmpty) {
      return DsEmptyState(
        icon: Icons.search_off,
        title: 'No matching exams',
        message: 'Try a different search or filter.',
        action: DsButton(
          label: 'Clear filters',
          size: DsButtonSize.md,
          tone: DsButtonTone.secondary,
          expand: false,
          onPressed: cubit.clearFilters,
        ),
      );
    }

    final cards = [
      for (final exam in visible)
        _ExamCard(
          exam: exam,
          state: state.stateOf(exam),
          wide: wide,
          onScan: onScan,
        ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        if (!wide || constraints.maxWidth < _twoColumnsFrom) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = 0; i < cards.length; i++) ...[
                if (i > 0) const SizedBox(height: DsSpacing.cardGap),
                cards[i],
              ],
            ],
          );
        }
        // exam-grid: rows of two, cards top-aligned.
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var i = 0; i < cards.length; i += 2) ...[
              if (i > 0) const SizedBox(height: DsSpacing.cardGap),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: cards[i]),
                  const SizedBox(width: DsSpacing.cardGap),
                  Expanded(
                    child: i + 1 < cards.length
                        ? cards[i + 1]
                        : const SizedBox.shrink(),
                  ),
                ],
              ),
            ],
          ],
        );
      },
    );
  }
}

class _Toolbar extends StatefulWidget {
  const _Toolbar({required this.state, required this.wide});

  final MyExamsState state;
  final bool wide;

  @override
  State<_Toolbar> createState() => _ToolbarState();
}

class _ToolbarState extends State<_Toolbar> {
  final _controller = TextEditingController();

  @override
  void didUpdateWidget(covariant _Toolbar oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Keep the field in sync when filters are cleared from elsewhere.
    if (widget.state.query != _controller.text) {
      _controller.text = widget.state.query;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _pickSubject(BuildContext context) async {
    final cubit = context.read<MyExamsCubit>();
    final subjects = widget.state.subjects;
    const all = '\u0000all';
    final picked = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: DsColors.surfaceOverlay,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(DsSpacing.insetLg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Filter by subject', style: DsTypography.h4),
              const SizedBox(height: DsSpacing.stackMd),
              Wrap(
                spacing: DsSpacing.inlineSm,
                runSpacing: DsSpacing.stackSm,
                children: [
                  DsTag(
                    label: 'All subjects',
                    selected: widget.state.subject == null,
                    onTap: () => Navigator.pop(context, all),
                  ),
                  for (final s in subjects)
                    DsTag(
                      label: s,
                      selected: widget.state.subject == s,
                      onTap: () => Navigator.pop(context, s),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    if (picked == null) return;
    cubit.setSubject(picked == all ? null : picked);
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<MyExamsCubit>();
    final s = widget.state;
    final search = DsTextField(
      controller: _controller,
      hintText: 'Search exams…',
      leadingIconAsset: DsAssets.icSearch,
      size: widget.wide ? DsFieldSize.md : DsFieldSize.lg,
      textInputAction: TextInputAction.search,
      onChanged: cubit.search,
    );
    final tags = Wrap(
      spacing: DsSpacing.inlineSm,
      runSpacing: DsSpacing.stackSm,
      children: [
        DsTag(
          label: 'All',
          selected: s.filter == MyExamsFilter.all,
          onTap: () => cubit.setFilter(MyExamsFilter.all),
        ),
        DsTag(
          label: 'Active',
          selected: s.filter == MyExamsFilter.active,
          onTap: () => cubit.setFilter(MyExamsFilter.active),
        ),
        DsTag(
          label: 'Graded',
          selected: s.filter == MyExamsFilter.graded,
          onTap: () => cubit.setFilter(MyExamsFilter.graded),
        ),
        DsTag(
          label: s.subject ?? 'Subject',
          selected: s.subject != null,
          onTap: s.subjects.isEmpty ? null : () => _pickSubject(context),
        ),
      ],
    );

    if (!widget.wide) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          search,
          const SizedBox(height: DsSpacing.stackMd),
          tags,
        ],
      );
    }
    return Wrap(
      spacing: DsSpacing.inlineMd,
      runSpacing: DsSpacing.stackSm,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        SizedBox(width: MyExamsPage.searchWidth, child: search),
        tags,
      ],
    );
  }
}

class _ExamCard extends StatelessWidget {
  const _ExamCard({
    required this.exam,
    required this.state,
    required this.wide,
    this.onScan,
  });

  final StudentExam exam;
  final StudentExamState state;
  final bool wide;
  final void Function(StudentExam exam)? onScan;

  @override
  Widget build(BuildContext context) {
    final result = exam.result;
    return DsExamCard(
      code: exam.code,
      title: exam.title,
      meta: [
        if (exam.subjectName != null)
          DsExamMeta(
            iconAsset: DsAssets.icGraduationCapSm,
            label: exam.subjectName!,
          ),
        if (exam.examDate != null)
          DsExamMeta(
            iconAsset: DsAssets.icCalendarSm,
            label: formatDate(exam.examDate!),
          ),
        if (exam.itemCount > 0)
          DsExamMeta(
            iconAsset: DsAssets.icFileTextSm,
            label: exam.itemCount == 1 ? '1 item' : '${exam.itemCount} items',
          ),
      ],
      score: result == null
          ? null
          : DsExamScore(
              value: '${result.percent.round()}%',
              caption: result.passed ? 'Passed' : 'Failed',
              passed: result.passed,
            ),
      action: state == StudentExamState.scan
          ? DsButton(
              label: wide ? 'Scan in the mobile app' : 'Scan Paper',
              size: wide ? DsButtonSize.md : DsButtonSize.lg,
              onPressed: () => onScan?.call(exam),
            )
          : null,
      status: switch (state) {
        StudentExamState.scan => null,
        StudentExamState.awaiting => const DsExamStatus(
            iconAsset: DsAssets.icClock,
            message: 'Paper uploaded. Awaiting results.',
          ),
        StudentExamState.locked => const DsExamStatus(
            iconAsset: DsAssets.icLock,
            message: 'Scanning window closed.',
          ),
        StudentExamState.graded => DsExamStatus(
            iconAsset: DsAssets.icCheckCircle,
            message: 'Grade',
            trailing: result!.gradeLabel,
          ),
      },
    );
  }
}
