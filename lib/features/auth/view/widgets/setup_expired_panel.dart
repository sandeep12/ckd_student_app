import 'package:ckd_design_system/ckd_design_system.dart';
import 'package:material_ui/material_ui.dart';

import '../../cubit/auth_error_messages.dart';
import '../login_flow.dart';

/// "Setup session expired" state (Figma "07 · … setup session expired"):
/// the 30-minute first-time setup window passed; the user signs in again.
class SetupExpiredPanel extends StatelessWidget {
  const SetupExpiredPanel({super.key, required this.compact});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Session expired',
          style: compact ? DsTypography.h3 : DsTypography.h2,
        ),
        const SizedBox(height: DsSpacing.stackLg),
        const DsDangerBanner(message: AuthErrorMessages.sessionExpired),
        const SizedBox(height: DsSpacing.stackLg),
        DsButton(
          label: 'Back to sign in',
          onPressed: () => LoginFlow.backToSignIn(context),
        ),
      ],
    );
  }
}
