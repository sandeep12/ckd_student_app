import 'package:ckd_design_system/ckd_design_system.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';

import '../cubit/forgot_password_cubit.dart';
import '../data/password_reset_repository.dart';
import 'forgot_password_page.dart';
import 'set_new_password_page.dart';
import 'widgets/auth_shell.dart';

/// "Check your email" — reset link sent, with resend + cooldown.
class CheckEmailPage extends StatelessWidget {
  const CheckEmailPage({super.key});

  static Route<void> route({
    required ForgotPasswordCubit cubit,
    required PasswordResetRepository repository,
  }) =>
      MaterialPageRoute(
        settings: const RouteSettings(name: '$kPasswordResetRoutePrefix/sent'),
        builder: (_) => RepositoryProvider.value(
          value: repository,
          child:
              BlocProvider.value(value: cubit, child: const CheckEmailPage()),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return AuthShell(
      heroArt: DsAuthArt.mailSent,
      heroTitle: 'Help is on\nits way',
      heroBody: 'The link works once and expires soon, so use the newest '
          'email if you ask for more than one.',
      minCardHeight: 600,
      form: (context, compact) => _CheckEmailBody(compact: compact),
    );
  }
}

class _CheckEmailBody extends StatelessWidget {
  const _CheckEmailBody({required this.compact});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ForgotPasswordCubit, ForgotPasswordState>(
      builder: (context, state) {
        final cubit = context.read<ForgotPasswordCubit>();
        final resendLabel = state.isResending
            ? 'Sending…'
            : state.cooldown > 0
                ? 'Resend in ${state.cooldown}s'
                : 'Resend link';
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Check your email',
              style: compact ? DsTypography.h3 : DsTypography.h2,
            ),
            const SizedBox(height: DsSpacing.stackXs),
            Text.rich(
              TextSpan(
                text: 'If an account exists for ',
                children: [
                  TextSpan(
                    text: state.email.trim(),
                    style: DsTypography.bodySm.copyWith(
                      color: DsColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const TextSpan(
                    text: ', we sent a link to reset your password.',
                  ),
                ],
              ),
              style:
                  DsTypography.bodySm.copyWith(color: DsColors.textSecondary),
            ),
            const SizedBox(height: DsSpacing.stackLg),
            if (state.errorMessage != null) ...[
              DsDangerBanner(message: state.errorMessage!),
              const SizedBox(height: DsSpacing.stackLg),
            ],
            Text(
              state.infoMessage ??
                  'Check your inbox — and your spam folder if it is not '
                      'there.',
              style: DsTypography.caption.copyWith(
                color: state.infoMessage != null
                    ? DsColors.statusSuccessText
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
                  label: resendLabel,
                  onTap: state.canResend ? cubit.resend : null,
                ),
              ],
            ),
            const SizedBox(height: DsSpacing.stackLg),
            DsButton(
              label: 'I have my reset link',
              onPressed: () => Navigator.of(context).push(
                SetNewPasswordPage.route(
                  repository: context.read<PasswordResetRepository>(),
                ),
              ),
            ),
            const SizedBox(height: DsSpacing.stackLg),
            DsLink(
              label: 'Back to sign in',
              touchRow: compact,
              onTap: () => popToLogin(context),
            ),
            if (!compact) const AuthFooter(),
          ],
        );
      },
    );
  }
}
