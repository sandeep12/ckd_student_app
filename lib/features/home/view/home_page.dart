import 'package:ckd_design_system/ckd_design_system.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';

import '../../auth/data/auth_repository.dart';
import '../../auth/data/models/auth_models.dart';
import '../../auth/view/login_page.dart';

/// Placeholder landing after sign-in — the student dashboard is a later
/// module.
class HomePage extends StatelessWidget {
  const HomePage({super.key, this.user});

  final AuthUser? user;

  static Route<void> route(AuthUser? user) =>
      MaterialPageRoute(builder: (_) => HomePage(user: user));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DsColors.surfaceShell,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(DsSpacing.insetLg),
            child: Container(
              width: double.infinity,
              constraints: const BoxConstraints(maxWidth: 480),
              decoration: BoxDecoration(
                color: DsColors.surfaceRaised,
                borderRadius: BorderRadius.circular(DsRadii.overlay),
                boxShadow: DsElevation.modal,
              ),
              padding: const EdgeInsets.all(DsSpacing.insetXl),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('You’re signed in', style: DsTypography.h3),
                  const SizedBox(height: DsSpacing.stackXs),
                  Text(
                    user?.email ?? '',
                    style: DsTypography.bodySm
                        .copyWith(color: DsColors.textSecondary),
                  ),
                  if (user?.schoolName != null) ...[
                    const SizedBox(height: DsSpacing.stackMd),
                    Text('School', style: DsTypography.label),
                    Text(
                      user!.schoolName!,
                      style: DsTypography.body
                          .copyWith(color: DsColors.textSecondary),
                    ),
                  ],
                  const SizedBox(height: DsSpacing.stackLg),
                  Text(
                    'The student dashboard is not part of this build yet.',
                    style: DsTypography.caption
                        .copyWith(color: DsColors.textTertiary),
                  ),
                  const SizedBox(height: DsSpacing.stackLg),
                  DsButton(
                    label: 'Sign out',
                    onPressed: () async {
                      final navigator = Navigator.of(context);
                      await context.read<AuthRepository>().logout();
                      navigator.pushAndRemoveUntil(
                        MaterialPageRoute(
                          builder: (_) => const LoginPage(),
                        ),
                        (route) => false,
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
