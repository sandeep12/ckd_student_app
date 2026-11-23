import 'package:ckd_design_system/ckd_design_system.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';

import '../cubit/forgot_password_cubit.dart';
import '../data/password_reset_repository.dart';
import 'check_email_page.dart';
import 'widgets/auth_shell.dart';

/// Route names of the reset flow share this prefix so the flow can pop
/// straight back to whatever screen opened it (the login page).
const String kPasswordResetRoutePrefix = '/password-reset';

/// Pops every password-reset route, returning to the login page.
void popToLogin(BuildContext context) {
  Navigator.of(context).popUntil(
    (route) =>
        !(route.settings.name?.startsWith(kPasswordResetRoutePrefix) ?? false),
  );
}

/// "Forgot password" (adapted from Figma "02 · Forgot password").
class ForgotPasswordPage extends StatelessWidget {
  const ForgotPasswordPage({super.key, this.initialEmail = ''});

  final String initialEmail;

  static Route<void> route({String initialEmail = ''}) => MaterialPageRoute(
        settings:
            const RouteSettings(name: '$kPasswordResetRoutePrefix/forgot'),
        builder: (_) => ForgotPasswordPage(initialEmail: initialEmail),
      );

  @override
  Widget build(BuildContext context) {
    return RepositoryProvider(
      create: (_) => PasswordResetRepository(),
      child: BlocProvider(
        create: (context) => ForgotPasswordCubit(
          repository: context.read<PasswordResetRepository>(),
        )..emailChanged(initialEmail.trim()),
        child: BlocListener<ForgotPasswordCubit, ForgotPasswordState>(
          listenWhen: (previous, current) =>
              previous.sentCount == 0 && current.sentCount == 1,
          listener: (context, state) {
            Navigator.of(context).push(CheckEmailPage.route(
              cubit: context.read<ForgotPasswordCubit>(),
              repository: context.read<PasswordResetRepository>(),
            ));
          },
          child: AuthShell(
            heroArt: DsAuthArt.graduationCap,
            heroTitle: 'Locked out?\nWe’ll get you back in',
            heroBody: 'Tell us the email your school registered for you and '
                'we’ll send a link to set a new password.',
            minCardHeight: 600,
            form: (context, compact) => _ForgotForm(compact: compact),
          ),
        ),
      ),
    );
  }
}

class _ForgotForm extends StatefulWidget {
  const _ForgotForm({required this.compact});

  final bool compact;

  @override
  State<_ForgotForm> createState() => _ForgotFormState();
}

class _ForgotFormState extends State<_ForgotForm> {
  late final TextEditingController _emailController = TextEditingController(
    text: context.read<ForgotPasswordCubit>().state.email,
  );

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final compact = widget.compact;
    return BlocBuilder<ForgotPasswordCubit, ForgotPasswordState>(
      builder: (context, state) {
        final cubit = context.read<ForgotPasswordCubit>();
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Forgot your password?',
              style: compact ? DsTypography.h3 : DsTypography.h2,
            ),
            const SizedBox(height: DsSpacing.stackXs),
            Text(
              'Enter your school email and we’ll send you a link to reset '
              'your password.',
              style:
                  DsTypography.bodySm.copyWith(color: DsColors.textSecondary),
            ),
            const SizedBox(height: DsSpacing.stackLg),
            if (state.errorMessage != null) ...[
              DsDangerBanner(message: state.errorMessage!),
              const SizedBox(height: DsSpacing.stackLg),
            ],
            DsTextField(
              label: 'Email ID',
              controller: _emailController,
              hintText: 'alex.ramos@horizon.edu.ph',
              errorText: state.emailError,
              leadingIconAsset: DsAssets.icMail,
              size: compact ? DsFieldSize.lg : DsFieldSize.md,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.done,
              autofillHints: const [AutofillHints.email],
              enabled: !state.isSubmitting,
              onChanged: cubit.emailChanged,
              onSubmitted: (_) => cubit.submit(),
            ),
            const SizedBox(height: DsSpacing.stackLg),
            DsButton(
              label: 'Send reset link',
              loading: state.isSubmitting,
              onPressed: state.isSubmitting ? null : cubit.submit,
            ),
            const SizedBox(height: DsSpacing.stackLg),
            DsLink(
              label: 'Back to sign in',
              touchRow: compact,
              onTap: state.isSubmitting ? null : () => popToLogin(context),
            ),
            if (!compact) const AuthFooter(),
          ],
        );
      },
    );
  }
}

/// Copyright line shown under the web forms of the reset flow.
class AuthFooter extends StatelessWidget {
  const AuthFooter({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: DsSpacing.stackXl * 2),
      child: Text(
        '© 2026 OEd · ACA. All rights reserved.',
        style: DsTypography.caption.copyWith(color: DsColors.textTertiary),
      ),
    );
  }
}
