import 'package:ckd_design_system/ckd_design_system.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';

import '../cubit/login_cubit.dart';
import '../data/auth_repository.dart';
import '../data/models/auth_models.dart';
import 'login_flow.dart';
import 'widgets/auth_shell.dart';
import 'widgets/login_form.dart';

/// Student login (Figma: "01 · Login (Web)" / "02 · Login (Mobile)").
class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          LoginCubit(authRepository: context.read<AuthRepository>()),
      child: BlocListener<LoginCubit, LoginState>(
        listenWhen: (previous, current) => previous.status != current.status,
        listener: (context, state) {
          final cubit = context.read<LoginCubit>();
          final LoginOutcome? outcome = switch (state.status) {
            LoginStatus.mfaRequired => state.challenge == null
                ? null
                : LoginMfaRequired(state.challenge!),
            LoginStatus.passwordResetRequired ||
            LoginStatus.mfaEnrolmentRequired =>
              state.setupTicket == null
                  ? null
                  : state.status == LoginStatus.passwordResetRequired
                      ? LoginPasswordResetRequired(state.setupTicket!)
                      : LoginMfaEnrolmentRequired(state.setupTicket!),
            LoginStatus.success => LoginAuthenticated(
                state.session ?? const AuthSession(),
              ),
            _ => null,
          };
          if (outcome == null) return;
          if (outcome is! LoginAuthenticated) cubit.challengeHandled();
          LoginFlow.continueWith(context, outcome);
        },
        child: AuthShell(
          heroArt: DsAuthArt.graduationCap,
          heroTitle: 'Your exams,\nall in one place',
          heroBody: 'See what is coming up, scan your answer sheet from your '
              'phone, and read your results and feedback the moment they '
              'are released.',
          form: (context, compact) => LoginForm(compact: compact),
        ),
      ),
    );
  }
}
