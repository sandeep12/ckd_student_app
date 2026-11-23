// Visual preview of the forgot-password flow:
//   flutter run -t tool/preview_forgot_password.dart -d chrome
import 'package:ckd_design_system/ckd_design_system.dart';
import 'package:material_ui/material_ui.dart';

import 'package:ckd_student_app/features/auth/view/forgot_password_page.dart';

void main() {
  runApp(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: CkdTheme.light(),
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: DsButton(
              label: 'Open forgot password',
              expand: false,
              onPressed: () =>
                  Navigator.of(context).push(ForgotPasswordPage.route()),
            ),
          ),
        ),
      ),
    ),
  );
}
