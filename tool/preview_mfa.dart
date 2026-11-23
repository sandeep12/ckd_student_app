// Visual preview of the MFA verify screen without a live login:
//   flutter run -t tool/preview_mfa.dart -d chrome
import 'package:ckd_design_system/ckd_design_system.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';

import 'package:ckd_student_app/features/auth/data/auth_repository.dart';
import 'package:ckd_student_app/features/auth/data/models/auth_models.dart';
import 'package:ckd_student_app/features/auth/view/mfa_verify_page.dart';

void main() {
  runApp(
    RepositoryProvider<AuthRepository>(
      create: (_) => AuthRepository(),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: CkdTheme.light(),
        home: const MfaVerifyPage(
          challenge: MfaChallenge(
            challengeToken: 'preview',
            method: 'email',
            user: AuthUser(email: 'alex.ramos@horizon.edu.ph'),
          ),
        ),
      ),
    ),
  );
}
