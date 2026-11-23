import 'package:ckd_design_system/ckd_design_system.dart';
import 'package:material_ui/material_ui.dart';

import 'features/auth/view/login_page.dart';

class CkdStudentApp extends StatelessWidget {
  const CkdStudentApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'OEd · ACA Student',
      debugShowCheckedModeBanner: false,
      theme: CkdTheme.light(),
      home: const LoginPage(),
    );
  }
}
