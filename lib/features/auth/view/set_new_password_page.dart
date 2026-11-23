import 'package:ckd_design_system/ckd_design_system.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';

import '../cubit/reset_password_cubit.dart';
import '../data/password_reset_repository.dart';
import 'forgot_password_page.dart';
import 'reset_success_page.dart';
import 'widgets/auth_shell.dart';

/// "Set new password" (adapted from Figma "03 · Set new password").
///
/// The backend emails a link with a token. Pass [token] when opened from
/// that link; otherwise the student pastes the link (or token) here.
class SetNewPasswordPage extends StatelessWidget {
  const SetNewPasswordPage({super.key, this.token});

  final String? token;

  static Route<void> route({
    PasswordResetRepository? repository,
    String? token,
  }) =>
      MaterialPageRoute(
        settings: const RouteSettings(name: '$kPasswordResetRoutePrefix/set'),
        builder: (_) => repository != null
            ? RepositoryProvider.value(
                value: repository,
                child: SetNewPasswordPage(token: token),
              )
            : RepositoryProvider(
                create: (_) => PasswordResetRepository(),
                child: SetNewPasswordPage(token: token),
              ),
      );

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => ResetPasswordCubit(
        repository: context.read<PasswordResetRepository>(),
        initialToken: token,
      ),
      child: BlocListener<ResetPasswordCubit, ResetPasswordState>(
        listenWhen: (previous, current) =>
            previous.status != current.status &&
            current.status == ResetPasswordStatus.success,
        listener: (context, state) {
          Navigator.of(context).pushReplacement(ResetSuccessPage.route());
        },
        child: AuthShell(
          heroArt: DsAuthArt.graduationCap,
          heroTitle: 'A fresh start\nfor your account',
          heroBody: 'Pick a password you have not used here before. You’ll '
              'use it to sign in from now on.',
          minCardHeight: 640,
          form: (context, compact) => _SetPasswordForm(compact: compact),
        ),
      ),
    );
  }
}

class _SetPasswordForm extends StatelessWidget {
  const _SetPasswordForm({required this.compact});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final fieldSize = compact ? DsFieldSize.lg : DsFieldSize.md;
    return BlocBuilder<ResetPasswordCubit, ResetPasswordState>(
      builder: (context, state) {
        final cubit = context.read<ResetPasswordCubit>();
        final busy = state.isSubmitting;
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Set a new password',
              style: compact ? DsTypography.h3 : DsTypography.h2,
            ),
            const SizedBox(height: DsSpacing.stackXs),
            Text(
              'Choose a new password for your student account.',
              style:
                  DsTypography.bodySm.copyWith(color: DsColors.textSecondary),
            ),
            const SizedBox(height: DsSpacing.stackLg),
            if (state.errorMessage != null) ...[
              DsDangerBanner(message: state.errorMessage!),
              const SizedBox(height: DsSpacing.stackMd),
              if (state.tokenInvalid) ...[
                DsLink(
                  label: 'Request a new link',
                  touchRow: compact,
                  onTap: () => Navigator.of(context).pushAndRemoveUntil(
                    ForgotPasswordPage.route(),
                    (route) => !(route.settings.name
                            ?.startsWith(kPasswordResetRoutePrefix) ??
                        false),
                  ),
                ),
                const SizedBox(height: DsSpacing.stackMd),
              ],
            ],
            if (!state.tokenLocked) ...[
              DsTextField(
                label: 'Reset link',
                hintText: 'Paste the link from your email',
                helperText: 'Copy the whole link from the email and paste '
                    'it here.',
                errorText: state.tokenError,
                leadingIconAsset: DsAssets.icMail,
                size: fieldSize,
                textInputAction: TextInputAction.next,
                enabled: !busy,
                onChanged: cubit.tokenChanged,
              ),
              const SizedBox(height: DsSpacing.stackMd),
            ],
            DsTextField(
              label: 'New password',
              hintText: 'Enter a new password',
              errorText: state.passwordError,
              trailingIconAsset: DsAssets.icEye,
              onTrailingIconTap: cubit.togglePasswordVisibility,
              obscureText: state.obscurePassword,
              size: fieldSize,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.newPassword],
              enabled: !busy,
              onChanged: cubit.passwordChanged,
            ),
            const SizedBox(height: DsSpacing.stackSm),
            _PasswordRuleList(password: state.password),
            const SizedBox(height: DsSpacing.stackMd),
            DsTextField(
              label: 'Confirm new password',
              hintText: 'Re-enter the new password',
              errorText: state.confirmError,
              trailingIconAsset: DsAssets.icEye,
              onTrailingIconTap: cubit.toggleConfirmVisibility,
              obscureText: state.obscureConfirm,
              size: fieldSize,
              textInputAction: TextInputAction.done,
              autofillHints: const [AutofillHints.newPassword],
              enabled: !busy,
              onChanged: cubit.confirmChanged,
              onSubmitted: (_) => cubit.submit(),
            ),
            const SizedBox(height: DsSpacing.stackLg),
            DsButton(
              label: 'Update password',
              loading: busy,
              onPressed: busy ? null : cubit.submit,
            ),
            const SizedBox(height: DsSpacing.stackLg),
            DsLink(
              label: 'Back to sign in',
              touchRow: compact,
              onTap: busy ? null : () => popToLogin(context),
            ),
            if (!compact) const AuthFooter(),
          ],
        );
      },
    );
  }
}

class _PasswordRuleList extends StatelessWidget {
  const _PasswordRuleList({required this.password});

  final String password;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final (label, test) in PasswordRules.rules)
          Padding(
            padding: const EdgeInsets.only(bottom: DsSpacing.stackXs),
            child: Row(
              children: [
                DsIcon(
                  test(password) ? DsAssets.icCheckCircle : DsAssets.icDot,
                  size: DsSizes.iconSm,
                  color: test(password)
                      ? DsColors.statusSuccessText
                      : DsColors.textTertiary,
                ),
                const SizedBox(width: DsSpacing.inlineSm),
                Text(
                  label,
                  style: DsTypography.caption.copyWith(
                    color: test(password)
                        ? DsColors.statusSuccessText
                        : DsColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
