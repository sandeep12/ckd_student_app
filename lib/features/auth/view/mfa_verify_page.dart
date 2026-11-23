import 'package:ckd_design_system/ckd_design_system.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';

import '../../shell/view/student_shell.dart';
import '../cubit/mfa_cubit.dart';
import '../data/auth_repository.dart';
import '../data/models/auth_models.dart';
import 'widgets/auth_shell.dart';

/// "Verify it's you" (Figma: "17 · Verify it's you (Web)" /
/// "18 · Verify it's you (Mobile)") — one-time code entry after login.
class MfaVerifyPage extends StatelessWidget {
  const MfaVerifyPage({super.key, required this.challenge});

  final MfaChallenge challenge;

  static Route<void> route(MfaChallenge challenge) => MaterialPageRoute(
        builder: (_) => MfaVerifyPage(challenge: challenge),
      );

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => MfaCubit(
        authRepository: context.read<AuthRepository>(),
        challenge: challenge,
      ),
      child: BlocListener<MfaCubit, MfaState>(
        listenWhen: (previous, current) =>
            previous.status != current.status &&
            current.status == MfaStatus.success,
        listener: (context, state) {
          Navigator.of(context).pushAndRemoveUntil(
            StudentShell.route(),
            (route) => false,
          );
        },
        child: AuthShell(
          heroArt: DsAuthArt.mailSent,
          heroTitle: 'One more step\nto keep you safe',
          heroBody: 'We send a short code to your school email every time you '
              'sign in. It keeps your results and answer sheets yours '
              'alone.',
          minCardHeight: 600,
          form: (context, compact) => _MfaForm(compact: compact),
        ),
      ),
    );
  }
}

class _MfaForm extends StatelessWidget {
  const _MfaForm({required this.compact});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MfaCubit, MfaState>(
      builder: (context, state) {
        final cubit = context.read<MfaCubit>();
        final maskedEmail =
            state.challenge.user?.maskedEmail ?? 'your school email';
        final hasError = state.errorMessage != null;
        final helper = state.incompleteError ??
            state.infoMessage ??
            'Check your inbox — and your spam folder if it is not '
                'there.';
        final helperColor = state.showIncomplete
            ? DsColors.statusDangerText
            : DsColors.textTertiary;

        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Head
            Text(
              'Verify it’s you',
              style: compact ? DsTypography.h3 : DsTypography.h2,
            ),
            const SizedBox(height: DsSpacing.stackXs),
            Text(
              'Enter the 6-digit code we emailed to $maskedEmail. '
              'It expires in 10 minutes.',
              style:
                  DsTypography.bodySm.copyWith(color: DsColors.textSecondary),
            ),
            const SizedBox(height: DsSpacing.stackLg),

            // Error banner (incorrect code / expired / too many attempts)
            if (hasError) ...[
              DsDangerBanner(message: state.errorMessage!),
              const SizedBox(height: DsSpacing.stackLg),
            ],

            Text('One-time code', style: DsTypography.label),
            const SizedBox(height: DsSpacing.stackLg),
            DsOtpInput(
              value: state.code,
              compact: compact,
              error: state.showIncomplete || hasError,
              enabled: !state.isVerifying,
              autofocus: true,
              onChanged: cubit.codeChanged,
              onCompleted: (_) => cubit.submit(),
            ),
            const SizedBox(height: DsSpacing.stackLg),
            Text(
              helper,
              style: DsTypography.caption.copyWith(color: helperColor),
            ),
            const SizedBox(height: DsSpacing.stackLg),

            // Resend row
            Row(
              children: [
                Text(
                  'Did not get it?',
                  style: DsTypography.bodySm
                      .copyWith(color: DsColors.textSecondary),
                ),
                const SizedBox(width: DsSpacing.inlineSm),
                DsLink(
                  label: state.isResending ? 'Sending…' : 'Send a new code',
                  onTap: state.isResending || state.isVerifying
                      ? null
                      : cubit.resend,
                ),
              ],
            ),
            const SizedBox(height: DsSpacing.stackLg),

            DsButton(
              label: 'Verify and continue',
              loading: state.isVerifying,
              onPressed: state.canSubmit ? cubit.submit : null,
            ),
            const SizedBox(height: DsSpacing.stackLg),
            DsLink(
              label: 'Use a different account',
              touchRow: compact,
              onTap:
                  state.isVerifying ? null : () => Navigator.of(context).pop(),
            ),

            if (!compact) ...[
              const SizedBox(height: DsSpacing.stackXl * 2),
              Text(
                '© 2026 OEd · ACA. All rights reserved.',
                style:
                    DsTypography.caption.copyWith(color: DsColors.textTertiary),
              ),
            ],
          ],
        );
      },
    );
  }
}
