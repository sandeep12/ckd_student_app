import 'package:ckd_design_system/ckd_design_system.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';

import '../cubit/mfa_enrol_cubit.dart';
import '../data/auth_repository.dart';
import '../data/models/auth_models.dart';
import 'login_flow.dart';
import 'widgets/auth_shell.dart';
import 'widgets/setup_expired_panel.dart';

/// MFA enrolment for an account without a second factor (adapted from
/// Figma "05 · MFA enrolment"). Students enrol the email method only.
class MfaEnrolPage extends StatelessWidget {
  const MfaEnrolPage({super.key, required this.ticket});

  final SetupTicket ticket;

  static Route<void> route(SetupTicket ticket) => MaterialPageRoute(
        builder: (_) => MfaEnrolPage(ticket: ticket),
      );

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => MfaEnrolCubit(
        authRepository: context.read<AuthRepository>(),
        ticket: ticket,
      ),
      child: AuthShell(
        heroArt: DsAuthArt.mailSent,
        heroTitle: 'Keep your account\nyours alone',
        heroBody: 'Each time you sign in we will email a short code to your '
            'school email, so only you can see your results and answer '
            'sheets.',
        minCardHeight: 600,
        form: (context, compact) => _MfaEnrolForm(compact: compact),
      ),
    );
  }
}

class _MfaEnrolForm extends StatelessWidget {
  const _MfaEnrolForm({required this.compact});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MfaEnrolCubit, MfaEnrolState>(
      builder: (context, state) {
        if (state.expired) return SetupExpiredPanel(compact: compact);

        final cubit = context.read<MfaEnrolCubit>();
        final email = state.ticket.user?.maskedEmail ?? 'your school email';
        final heading = compact ? DsTypography.h3 : DsTypography.h2;
        final subtitle =
            DsTypography.bodySm.copyWith(color: DsColors.textSecondary);

        final List<Widget> body;
        switch (state.step) {
          case MfaEnrolStep.intro:
            body = [
              Text('Set up sign-in codes', style: heading),
              const SizedBox(height: DsSpacing.stackXs),
              Text(
                'We will email a 6-digit code to $email. You will enter a '
                'code like this every time you sign in.',
                style: subtitle,
              ),
              const SizedBox(height: DsSpacing.stackLg),
              ..._error(state),
              DsButton(
                label: 'Email me a code',
                loading: state.sending,
                onPressed: state.busy ? null : cubit.sendCode,
              ),
            ];
          case MfaEnrolStep.code:
            final hasError = state.errorMessage != null;
            body = [
              Text('Enter your code', style: heading),
              const SizedBox(height: DsSpacing.stackXs),
              Text(
                'Enter the 6-digit code we emailed to $email.',
                style: subtitle,
              ),
              const SizedBox(height: DsSpacing.stackLg),
              ..._error(state),
              Text('One-time code', style: DsTypography.label),
              const SizedBox(height: DsSpacing.stackLg),
              DsOtpInput(
                value: state.code,
                compact: compact,
                error: state.showIncomplete || hasError,
                enabled: !state.busy,
                autofocus: true,
                onChanged: cubit.codeChanged,
                onCompleted: (_) => cubit.confirm(),
              ),
              const SizedBox(height: DsSpacing.stackLg),
              Text(
                state.showIncomplete
                    ? 'Enter the 6-digit code.'
                    : 'Check your inbox — and your spam folder if it is '
                        'not there.',
                style: DsTypography.caption.copyWith(
                  color: state.showIncomplete
                      ? DsColors.statusDangerText
                      : DsColors.textTertiary,
                ),
              ),
              const SizedBox(height: DsSpacing.stackLg),
              Row(
                children: [
                  Text(
                    'Did not get it?',
                    style: DsTypography.bodySm
                        .copyWith(color: DsColors.textSecondary),
                  ),
                  const SizedBox(width: DsSpacing.inlineSm),
                  DsLink(
                    label: state.sending ? 'Sending…' : 'Send a new code',
                    onTap: state.busy ? null : cubit.sendCode,
                  ),
                ],
              ),
              const SizedBox(height: DsSpacing.stackLg),
              DsButton(
                label: 'Verify and continue',
                loading: state.confirming,
                onPressed: state.busy ? null : cubit.confirm,
              ),
            ];
          case MfaEnrolStep.backupCodes:
            final codes = state.result?.backupCodes ?? const <String>[];
            body = [
              Text('Save your backup codes', style: heading),
              const SizedBox(height: DsSpacing.stackXs),
              Text(
                'If you cannot get an emailed code, use one of these to '
                'sign in. Each works once and they are shown only now.',
                style: subtitle,
              ),
              const SizedBox(height: DsSpacing.stackLg),
              DsCard(
                child: Wrap(
                  spacing: DsSpacing.inlineLg,
                  runSpacing: DsSpacing.stackSm,
                  children: [
                    for (final code in codes)
                      SelectableText(code, style: DsTypography.label),
                  ],
                ),
              ),
              const SizedBox(height: DsSpacing.stackLg),
              DsCheckbox(
                value: state.savedCodes,
                label: 'I have saved my backup codes',
                size: compact ? DsCheckboxSize.lg : DsCheckboxSize.md,
                onChanged: cubit.savedToggled,
              ),
              const SizedBox(height: DsSpacing.stackLg),
              DsButton(
                label: 'Continue',
                onPressed: state.savedCodes && state.result != null
                    ? () => LoginFlow.continueWith(
                          context,
                          LoginAuthenticated(state.result!.session),
                        )
                    : null,
              ),
            ];
        }

        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ...body,
            if (state.step != MfaEnrolStep.backupCodes) ...[
              const SizedBox(height: DsSpacing.stackLg),
              DsLink(
                label: 'Back to sign in',
                touchRow: compact,
                onTap:
                    state.busy ? null : () => LoginFlow.backToSignIn(context),
              ),
            ],
          ],
        );
      },
    );
  }

  List<Widget> _error(MfaEnrolState state) => [
        if (state.errorMessage != null) ...[
          DsDangerBanner(message: state.errorMessage!),
          const SizedBox(height: DsSpacing.stackLg),
        ],
      ];
}
