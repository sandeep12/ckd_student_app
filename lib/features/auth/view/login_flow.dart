import 'package:material_ui/material_ui.dart';

import '../../shell/view/student_shell.dart';
import '../data/models/auth_models.dart';
import 'create_password_page.dart';
import 'mfa_enrol_page.dart';
import 'mfa_verify_page.dart';

/// Routes a [LoginOutcome] (from login or a setup step) to the next screen.
///
/// Setup steps replace the current route so "back" returns to sign-in;
/// an authenticated outcome clears the stack into the student shell.
abstract final class LoginFlow {
  static void continueWith(
    BuildContext context,
    LoginOutcome outcome, {
    bool replace = false,
  }) {
    final navigator = Navigator.of(context);
    final Route<void> route;
    switch (outcome) {
      case LoginAuthenticated():
        navigator.pushAndRemoveUntil(StudentShell.route(), (_) => false);
        return;
      case LoginMfaRequired(:final challenge):
        route = MfaVerifyPage.route(challenge);
      case LoginPasswordResetRequired(:final ticket):
        route = CreatePasswordPage.route(ticket);
      case LoginMfaEnrolmentRequired(:final ticket):
        route = MfaEnrolPage.route(ticket);
    }
    if (replace) {
      navigator.pushReplacement(route);
    } else {
      navigator.push(route);
    }
  }

  /// Returns to the sign-in screen (the first route).
  static void backToSignIn(BuildContext context) =>
      Navigator.of(context).popUntil((route) => route.isFirst);
}
