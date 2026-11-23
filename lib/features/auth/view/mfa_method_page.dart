import 'package:ckd_design_system/ckd_design_system.dart';
import 'package:material_ui/material_ui.dart';

import '../data/models/auth_models.dart';
import 'backup_code_page.dart';
import 'widgets/auth_shell.dart';

/// "Choose how to verify" — reached from "Try another way" on the
/// Verify page. No Figma frame exists; built to match "Verify it's you".
class MfaMethodPage extends StatelessWidget {
  const MfaMethodPage({super.key, required this.challenge});

  final MfaChallenge challenge;

  static Route<void> route(MfaChallenge challenge) => MaterialPageRoute(
        builder: (_) => MfaMethodPage(challenge: challenge),
      );

  @override
  Widget build(BuildContext context) {
    return AuthShell(
      heroArt: DsAuthArt.mailSent,
      heroTitle: 'One more step\nto keep you safe',
      heroBody: 'Can’t get to your email? Use one of the backup codes you '
          'saved when you set up sign-in protection.',
      minCardHeight: 600,
      form: (context, compact) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Choose how to verify',
            style: compact ? DsTypography.h3 : DsTypography.h2,
          ),
          const SizedBox(height: DsSpacing.stackXs),
          Text(
            'Pick another way to confirm it’s you.',
            style: DsTypography.bodySm.copyWith(color: DsColors.textSecondary),
          ),
          const SizedBox(height: DsSpacing.stackLg),
          _MethodOption(
            title: 'Email code',
            body: 'Get a 6-digit code at '
                '${challenge.user?.maskedEmail ?? 'your school email'}.',
            onTap: () => Navigator.of(context).pop(),
          ),
          const SizedBox(height: DsSpacing.cardGap),
          _MethodOption(
            title: 'Use a backup code',
            body: 'Enter one of the one-time backup codes you saved.',
            onTap: () =>
                Navigator.of(context).push(BackupCodePage.route(challenge)),
          ),
          const SizedBox(height: DsSpacing.stackLg),
          DsLink(
            label: 'Back to sign in',
            touchRow: compact,
            onTap: () =>
                Navigator.of(context).popUntil((route) => route.isFirst),
          ),
        ],
      ),
    );
  }
}

class _MethodOption extends StatelessWidget {
  const _MethodOption({
    required this.title,
    required this.body,
    required this.onTap,
  });

  final String title;
  final String body;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(DsRadii.control);
    return Semantics(
      button: true,
      child: Material(
        color: DsColors.surfaceRaised,
        borderRadius: radius,
        child: InkWell(
          borderRadius: radius,
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(DsSpacing.insetLg),
            decoration: BoxDecoration(
              borderRadius: radius,
              border: Border.all(
                color: DsColors.inputBorder,
                width: DsSizes.borderWidthDefault,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: DsTypography.label),
                      const SizedBox(height: DsSpacing.stackXs),
                      Text(
                        body,
                        style: DsTypography.caption
                            .copyWith(color: DsColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: DsSpacing.inlineMd),
                Text(
                  '›',
                  style: DsTypography.h3.copyWith(color: DsColors.textLink),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
