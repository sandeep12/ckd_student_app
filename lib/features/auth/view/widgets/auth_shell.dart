import 'package:ckd_design_system/ckd_design_system.dart';
import 'package:material_ui/material_ui.dart';

/// Below this width the mobile layout is used.
const double kAuthWebBreakpoint = 900;

/// Shared auth screen chrome: cobalt shell, logo chip, and the auth card.
///
/// Web (>=900px): two-panel card — hero on the left, [form] on the right.
/// Mobile: logo chip above a single white card with [form].
class AuthShell extends StatelessWidget {
  const AuthShell({
    super.key,
    required this.form,
    required this.heroArt,
    required this.heroTitle,
    required this.heroBody,
    this.minCardHeight = 737,
  });

  /// Builder so the form can adapt to the layout (`compact` = mobile).
  final Widget Function(BuildContext context, bool compact) form;

  final DsAuthArt heroArt;
  final String heroTitle;
  final String heroBody;
  final double minCardHeight;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DsColors.surfaceShell,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWeb = constraints.maxWidth >= kAuthWebBreakpoint;
          return isWeb ? _web(context) : _mobile(context);
        },
      ),
    );
  }

  Widget _web(BuildContext context) {
    return Stack(
      children: [
        const Positioned(left: 40, top: 32, child: DsLogoChip()),
        Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: DsSpacing.layoutPageMargin,
              vertical: 96,
            ),
            child: Container(
              width: 1000,
              constraints: BoxConstraints(minHeight: minCardHeight),
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: DsColors.surfaceRaised,
                borderRadius: BorderRadius.circular(DsRadii.overlay),
                boxShadow: DsElevation.modal,
              ),
              child: IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(
                      width: 440,
                      child: _HeroPanel(
                        art: heroArt,
                        title: heroTitle,
                        body: heroBody,
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding:
                            const EdgeInsets.all(DsSpacing.layoutPageMargin),
                        child: form(context, false),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _mobile(BuildContext context) {
    return SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: DsSpacing.insetLg,
            vertical: DsSpacing.stackXl,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const DsLogoChip(logoWidth: 104),
              const SizedBox(height: DsSpacing.stackXl),
              Container(
                width: double.infinity,
                constraints: const BoxConstraints(maxWidth: 480),
                decoration: BoxDecoration(
                  color: DsColors.surfaceOverlay,
                  borderRadius: BorderRadius.circular(DsRadii.overlay),
                  boxShadow: DsElevation.modal,
                ),
                padding: const EdgeInsets.all(DsSpacing.insetXl),
                child: form(context, true),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Cobalt hero panel on the left of the web auth card.
class _HeroPanel extends StatelessWidget {
  const _HeroPanel({
    required this.art,
    required this.title,
    required this.body,
  });

  final DsAuthArt art;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: DsColors.actionPrimaryBgHover,
      padding: const EdgeInsets.all(DsSpacing.layoutPageMargin),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DsAuthIllustration(art: art),
          const Spacer(),
          const SizedBox(height: DsSpacing.stackLg),
          Text(
            title,
            style: DsTypography.h2.copyWith(color: DsColors.textOnShell),
          ),
          const SizedBox(height: DsSpacing.stackMd),
          Text(
            body,
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
