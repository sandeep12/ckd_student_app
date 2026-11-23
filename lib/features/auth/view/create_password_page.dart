import 'package:ckd_design_system/ckd_design_system.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';

import '../cubit/create_password_cubit.dart';
import '../data/auth_repository.dart';
import '../data/models/auth_models.dart';
import 'login_flow.dart';
import 'widgets/auth_shell.dart';
import 'widgets/setup_expired_panel.dart';

/// Forced first-login "Create new password" (adapted from Figma
/// "04 · Create new password").
class CreatePasswordPage extends StatelessWidget {
  const CreatePasswordPage({super.key, required this.ticket});

  final SetupTicket ticket;

  static Route<void> route(SetupTicket ticket) => MaterialPageRoute(
        builder: (_) => CreatePasswordPage(ticket: ticket),
      );

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => CreatePasswordCubit(
        authRepository: context.read<AuthRepository>(),
        ticket: ticket,
      ),
      child: BlocListener<CreatePasswordCubit, CreatePasswordState>(
        listenWhen: (previous, current) =>
            previous.status != current.status &&
            current.status == CreatePasswordStatus.success,
        listener: (context, state) {
          final outcome = state.outcome;
          if (outcome != null) {
            LoginFlow.continueWith(context, outcome, replace: true);
          }
        },
        child: AuthShell(
          heroArt: DsAuthArt.graduationCap,
          heroTitle: 'One step to go',
          heroBody: 'Your temporary password works only once. Choose a '
              'password only you know to finish setting up your account.',
          minCardHeight: 600,
          form: (context, compact) => _CreatePasswordForm(compact: compact),
        ),
      ),
    );
  }
}

class _CreatePasswordForm extends StatelessWidget {
  const _CreatePasswordForm({required this.compact});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final fieldSize = compact ? DsFieldSize.lg : DsFieldSize.md;

    return BlocBuilder<CreatePasswordCubit, CreatePasswordState>(
      builder: (context, state) {
        if (state.status == CreatePasswordStatus.expired) {
          return SetupExpiredPanel(compact: compact);
        }
        final cubit = context.read<CreatePasswordCubit>();
        final failed = state.password.isNotEmpty && !state.isCompliant;

        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Create new password',
              style: compact ? DsTypography.h3 : DsTypography.h2,
            ),
            const SizedBox(height: DsSpacing.stackXs),
            Text(
              'Your temporary password is single-use. Choose a new one to '
              'finish setting up your account.',
              style:
                  DsTypography.bodySm.copyWith(color: DsColors.textSecondary),
            ),
            const SizedBox(height: DsSpacing.stackLg),
            if (state.errorMessage != null) ...[
              DsDangerBanner(message: state.errorMessage!),
              const SizedBox(height: DsSpacing.stackLg),
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
              enabled: !state.isSubmitting,
              onChanged: cubit.passwordChanged,
            ),
            const SizedBox(height: DsSpacing.stackSm),
            _Rule('Minimum 8 characters', state.hasMinLength, failed),
            _Rule('One uppercase letter', state.hasUpper, failed),
            _Rule('One number', state.hasNumber, failed),
            _Rule('One special character', state.hasSpecial, failed),
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
              enabled: !state.isSubmitting,
              onChanged: cubit.confirmChanged,
              onSubmitted: (_) => cubit.submit(),
            ),
            const SizedBox(height: DsSpacing.stackLg),
            DsButton(
              label: 'Set password and continue',
              loading: state.isSubmitting,
              onPressed: state.canSubmit ? cubit.submit : null,
            ),
            const SizedBox(height: DsSpacing.stackLg),
            DsLink(
              label: 'Back to sign in',
              touchRow: compact,
              onTap: state.isSubmitting
                  ? null
                  : () => LoginFlow.backToSignIn(context),
            ),
          ],
        );
      },
    );
  }
}

/// One line of the live password-policy checklist.
class _Rule extends StatelessWidget {
  const _Rule(this.label, this.met, this.failed);

  final String label;
  final bool met;
  final bool failed;

  @override
  Widget build(BuildContext context) {
    final color = met
        ? DsColors.statusSuccessText
        : failed
            ? DsColors.statusDangerText
            : DsColors.textTertiary;
    return Padding(
      padding: const EdgeInsets.only(top: DsSpacing.stackXs),
      child: Row(
        children: [
          DsIcon(
            met ? DsAssets.icCheckCircle : DsAssets.icDot,
            size: DsSizes.iconSm,
            color: color,
          ),
          const SizedBox(width: DsSpacing.inlineSm),
          Text(label, style: DsTypography.caption.copyWith(color: color)),
        ],
      ),
    );
  }
}
