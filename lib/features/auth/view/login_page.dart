import 'package:ckd_design_system/ckd_design_system.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../cubit/login_cubit.dart';
import '../data/auth_repository.dart';
import 'widgets/login_form.dart';
import 'widgets/login_hero_panel.dart';

/// Below this width the mobile layout is used.
const double _kWebBreakpoint = 900;

/// Student login (Figma: "01 · Login (Web)" / "02 · Login (Mobile)").
class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          LoginCubit(authRepository: context.read<AuthRepository>()),
      child: BlocListener<LoginCubit, LoginState>(
        listenWhen: (previous, current) =>
            previous.status != current.status &&
            current.status == LoginStatus.success,
        listener: (context, state) {
          // No post-login module exists yet.
          final name = state.user?.name ?? state.user?.email;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                name == null ? 'Signed in — welcome!' : 'Signed in — $name',
              ),
            ),
          );
        },
        child: Scaffold(
          backgroundColor: DsColors.surfaceShell,
          body: LayoutBuilder(
            builder: (context, constraints) {
              final isWeb = constraints.maxWidth >= _kWebBreakpoint;
              return isWeb ? const _WebLayout() : const _MobileLayout();
            },
          ),
        ),
      ),
    );
  }
}

/// 1440 web frame: logo chip top-left, centered two-panel auth card.
class _WebLayout extends StatelessWidget {
  const _WebLayout();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const Positioned(
          left: 40,
          top: 32,
          child: DsLogoChip(),
        ),
        Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: DsSpacing.layoutPageMargin,
              vertical: 96,
            ),
            child: Container(
              width: 1000,
              constraints: const BoxConstraints(minHeight: 737),
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: DsColors.surfaceRaised,
                borderRadius: BorderRadius.circular(DsRadii.overlay),
                boxShadow: DsElevation.modal,
              ),
              child: IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: const [
                    SizedBox(width: 440, child: LoginHeroPanel()),
                    Expanded(
                      child: Padding(
                        padding:
                            EdgeInsets.all(DsSpacing.layoutPageMargin),
                        child: LoginForm(compact: false),
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
}

/// 390 mobile frame: logo chip above a single white card.
class _MobileLayout extends StatelessWidget {
  const _MobileLayout();

  @override
  Widget build(BuildContext context) {
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
                child: const LoginForm(compact: true),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
