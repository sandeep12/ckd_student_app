import 'package:ckd_design_system/ckd_design_system.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';

import '../../cubit/open_exam_cubit.dart';

/// Exam-code input + "Open exam" button (`join-row`).
///
/// [compact] lays the two out side by side (web hero); otherwise they
/// stack full width (mobile sheet).
class OpenExamForm extends StatelessWidget {
  const OpenExamForm({super.key, this.compact = true});

  final bool compact;

  static const double _webFieldWidth = 240;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<OpenExamCubit, OpenExamState>(
      builder: (context, state) {
        final cubit = context.read<OpenExamCubit>();
        final field = DsTextField(
          hintText: 'e.g. MATH201-B2',
          size: compact ? DsFieldSize.md : DsFieldSize.lg,
          textInputAction: TextInputAction.go,
          onChanged: cubit.codeChanged,
          onSubmitted: (_) => cubit.submit(),
          errorText: state.status == OpenExamStatus.failure
              ? state.errorMessage
              : null,
        );
        final button = DsButton(
          label: 'Open exam',
          size: compact ? DsButtonSize.md : DsButtonSize.lg,
          expand: !compact,
          loading: state.status == OpenExamStatus.submitting,
          onPressed: cubit.submit,
        );

        if (!compact) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              field,
              const SizedBox(height: DsSpacing.stackMd),
              button,
            ],
          );
        }
        return Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(width: _webFieldWidth, child: field),
            const SizedBox(width: DsSpacing.inlineMd),
            button,
          ],
        );
      },
    );
  }
}
