import 'package:ckd_design_system/ckd_design_system.dart';
import 'package:material_ui/material_ui.dart';

import 'forgot_password_page.dart';
import 'widgets/auth_shell.dart';

/// "Password updated" — final step, back to sign in.
class ResetSuccessPage extends StatelessWidget {
  const ResetSuccessPage({super.key});

  static Route<void> route() => MaterialPageRoute(
        settings: const RouteSettings(name: '$kPasswordResetRoutePrefix/done'),
        builder: (_) => const ResetSuccessPage(),
      );

  @override
  Widget build(BuildContext context) {
    return AuthShell(
      heroArt: DsAuthArt.graduationCap,
      heroTitle: 'You’re all set',
      heroBody: 'Your results, exams and answer sheets are waiting for you.',
      minCardHeight: 560,
      form: (context, compact) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DsIcon(
            DsAssets.icCheckCircle,
            size: DsSizes.iconLg,
            color: DsColors.statusSuccessText,
          ),
          const SizedBox(height: DsSpacing.stackMd),
          Text(
            'Password updated',
            style: compact ? DsTypography.h3 : DsTypography.h2,
          ),
          const SizedBox(height: DsSpacing.stackXs),
          Text(
            'Your password has been changed. Sign in with your new password '
            'to continue.',
            style: DsTypography.bodySm.copyWith(color: DsColors.textSecondary),
          ),
          const SizedBox(height: DsSpacing.stackLg),
          DsButton(
            label: 'Back to sign in',
            onPressed: () => popToLogin(context),
          ),
          if (!compact) const AuthFooter(),
        ],
      ),
    );
  }
}
