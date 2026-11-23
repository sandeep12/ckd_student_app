import 'package:ckd_design_system/ckd_design_system.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';

import '../../shell/view/student_shell.dart';
import '../cubit/login_cubit.dart';
import '../data/auth_repository.dart';
import 'mfa_verify_page.dart';
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
          switch (state.status) {
            case LoginStatus.mfaRequired:
              final challenge = state.challenge;
              if (challenge != null) {
                context.read<LoginCubit>().challengeHandled();
                Navigator.of(context).push(MfaVerifyPage.route(challenge));
              }
            case LoginStatus.success:
              Navigator.of(context).pushAndRemoveUntil(
                StudentShell.route(),
                (route) => false,
              );
            case LoginStatus.idle:
            case LoginStatus.submitting:
            case LoginStatus.failure:
              break;
          }
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
