import 'package:ckd_design_system/ckd_design_system.dart';
import 'package:material_ui/material_ui.dart';

/// Cobalt hero panel on the left of the web auth card.
class LoginHeroPanel extends StatelessWidget {
  const LoginHeroPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: DsColors.actionPrimaryBgHover,
      padding: const EdgeInsets.all(DsSpacing.layoutPageMargin),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const DsAuthIllustration(),
          const Spacer(),
          const SizedBox(height: DsSpacing.stackLg),
          Text(
            'Your exams,\nall in one place',
            style: DsTypography.h2.copyWith(color: DsColors.textOnShell),
          ),
          const SizedBox(height: DsSpacing.stackMd),
          Text(
            'See what is coming up, scan your answer sheet from your '
            'phone, and read your results and feedback the moment they '
            'are released.',
            style: DsTypography.bodySm
                .copyWith(color: DsColors.textOnShellSecondary),
          ),
          const SizedBox(height: DsSpacing.stackMd),
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: DsColors.statusInfoBgBold,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: DsSpacing.inlineSm),
              Text(
                'Ituloy ang pangarap!',
                style: DsTypography.label
                    .copyWith(color: DsColors.textOnShell),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
