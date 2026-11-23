import 'package:ckd_design_system/ckd_design_system.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../cubit/login_cubit.dart';

/// The sign-in form, shared by the web and mobile layouts.
///
/// [compact] renders the mobile variant: H3 heading, 48-high controls,
/// 24 checkbox box, "Sign in" CTA.
class LoginForm extends StatefulWidget {
  const LoginForm({super.key, required this.compact});

  final bool compact;

  @override
  State<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  late final TextEditingController _emailController;
  late final TextEditingController _passwordController;

  @override
  void initState() {
    super.initState();
    final state = context.read<LoginCubit>().state;
    _emailController = TextEditingController(text: state.email);
    _passwordController = TextEditingController(text: state.password);
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final compact = widget.compact;
    final fieldSize = compact ? DsFieldSize.lg : DsFieldSize.md;

    return BlocBuilder<LoginCubit, LoginState>(
      builder: (context, state) {
        final cubit = context.read<LoginCubit>();

        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Head
            Text(
              'Student sign in',
              style: compact ? DsTypography.h3 : DsTypography.h2,
            ),
            const SizedBox(height: DsSpacing.stackXs),
            Text(
              compact
                  ? 'Use the email your school registered for you.'
                  : 'Use the email address your school registered for you.',
              style: DsTypography.bodySm
                  .copyWith(color: DsColors.textSecondary),
            ),
            const SizedBox(height: DsSpacing.stackLg),

            // Error banner (invalid credentials)
            if (state.errorMessage != null) ...[
              DsDangerBanner(message: state.errorMessage!),
              const SizedBox(height: DsSpacing.stackLg),
            ],

            // Email
            DsTextField(
              label: 'Email ID',
              controller: _emailController,
              hintText: 'alex.ramos@horizon.edu.ph',
              errorText: state.emailError,
              leadingIconAsset: DsAssets.icMail,
              size: fieldSize,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.email],
              enabled: !state.isSubmitting,
              onChanged: cubit.emailChanged,
            ),
            const SizedBox(height: DsSpacing.stackMd),

            // Password
            DsTextField(
              label: 'Password',
              controller: _passwordController,
              hintText: 'Enter your password',
              errorText: state.passwordError,
              trailingIconAsset: DsAssets.icEye,
              onTrailingIconTap: cubit.togglePasswordVisibility,
              obscureText: state.obscurePassword,
              size: fieldSize,
              textInputAction: TextInputAction.done,
              autofillHints: const [AutofillHints.password],
              enabled: !state.isSubmitting,
              onChanged: cubit.passwordChanged,
              onSubmitted: (_) => cubit.submit(),
            ),
            const SizedBox(height: DsSpacing.stackMd),

            // Forgot password
            DsLink(
              label: 'Forgot password?',
              touchRow: compact,
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content:
                        Text('Password reset is not part of this build.'),
                  ),
                );
              },
            ),
            const SizedBox(height: DsSpacing.stackLg),

            // Terms
            DsCheckbox(
              value: state.termsAccepted,
              label: 'I agree to the Terms & Privacy Policy',
              size: compact ? DsCheckboxSize.lg : DsCheckboxSize.md,
              onChanged:
                  state.isSubmitting ? null : cubit.termsToggled,
            ),
            const SizedBox(height: DsSpacing.stackLg),

            // CTA
            DsButton(
              label: compact ? 'Sign in' : 'Log in',
              loading: state.isSubmitting,
              onPressed: state.canSubmit ? cubit.submit : null,
            ),

            if (!state.termsAccepted) ...[
              const SizedBox(height: DsSpacing.stackLg),
              Text(
                'Accept the Terms & Privacy Policy to continue.',
                style: DsTypography.caption
                    .copyWith(color: DsColors.textTertiaryOnPage),
              ),
            ],

            if (!compact) ...[
              const SizedBox(height: DsSpacing.stackXl * 2),
              Text(
                '© 2026 OEd · ACA. All rights reserved.',
                style: DsTypography.caption
                    .copyWith(color: DsColors.textTertiary),
              ),
            ],
          ],
        );
      },
    );
  }
}
