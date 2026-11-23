import 'package:ckd_design_system/ckd_design_system.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';

import '../../shell/view/student_shell.dart';
import '../cubit/backup_code_cubit.dart';
import '../data/mfa_backup_repository.dart';
import '../data/models/auth_models.dart';
import 'widgets/auth_shell.dart';

/// "Use a backup code" — completes MFA with a one-time backup code.
class BackupCodePage extends StatelessWidget {
  const BackupCodePage({super.key, required this.challenge, this.repository});

  final MfaChallenge challenge;
  final MfaBackupRepository? repository;

  static Route<void> route(MfaChallenge challenge) => MaterialPageRoute(
        builder: (_) => BackupCodePage(challenge: challenge),
      );

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => BackupCodeCubit(
        repository: repository ?? MfaBackupRepository(),
        challenge: challenge,
      ),
      child: BlocListener<BackupCodeCubit, BackupCodeState>(
        listenWhen: (previous, current) =>
            previous.status != current.status &&
            current.status == BackupCodeStatus.success,
        listener: (context, state) {
          Navigator.of(context).pushAndRemoveUntil(
            StudentShell.route(),
            (route) => false,
          );
        },
        child: AuthShell(
          heroArt: DsAuthArt.mailSent,
          heroTitle: 'One more step\nto keep you safe',
          heroBody: 'Each backup code works once. After you use one, cross it '
              'off your list.',
          minCardHeight: 600,
          form: (context, compact) => _BackupForm(compact: compact),
        ),
      ),
    );
  }
}

class _BackupForm extends StatelessWidget {
  const _BackupForm({required this.compact});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<BackupCodeCubit, BackupCodeState>(
      builder: (context, state) {
        final cubit = context.read<BackupCodeCubit>();
        void backToSignIn() =>
            Navigator.of(context).popUntil((route) => route.isFirst);

        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Use a backup code',
              style: compact ? DsTypography.h3 : DsTypography.h2,
            ),
            const SizedBox(height: DsSpacing.stackXs),
            Text(
              'Enter one of the backup codes you saved when you turned on '
              'sign-in protection.',
              style:
                  DsTypography.bodySm.copyWith(color: DsColors.textSecondary),
            ),
            const SizedBox(height: DsSpacing.stackLg),
            if (state.errorMessage != null) ...[
              DsDangerBanner(message: state.errorMessage!),
              const SizedBox(height: DsSpacing.stackLg),
            ],
            DsTextField(
              label: 'Backup code',
              hintText: 'Enter backup code',
              helperText: 'Letters, numbers and dashes are fine.',
              errorText: state.fieldError,
              enabled: !state.isVerifying && !state.isBlocked,
              keyboardType: TextInputType.visiblePassword,
              textInputAction: TextInputAction.done,
              autofillHints: const [AutofillHints.oneTimeCode],
              onChanged: cubit.codeChanged,
              onSubmitted: (_) => cubit.submit(),
            ),
            const SizedBox(height: DsSpacing.stackLg),
            if (state.isBlocked)
              DsButton(label: 'Back to sign in', onPressed: backToSignIn)
            else
              DsButton(
                label: 'Verify and continue',
                loading: state.isVerifying,
                onPressed: state.canSubmit ? cubit.submit : null,
              ),
            const SizedBox(height: DsSpacing.stackLg),
            DsLink(
              label: 'Try another way',
              touchRow: compact,
              onTap: state.isVerifying || state.isBlocked
                  ? null
                  : () => Navigator.of(context).pop(),
            ),
          ],
        );
      },
    );
  }
}
