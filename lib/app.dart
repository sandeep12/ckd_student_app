import 'package:ckd_design_system/ckd_design_system.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';

import 'features/auth/data/auth_repository.dart';
import 'features/auth/view/login_page.dart';

class CkdStudentApp extends StatelessWidget {
  const CkdStudentApp({super.key, AuthRepository? authRepository})
      : _authRepository = authRepository;

  /// Injectable for tests.
  final AuthRepository? _authRepository;

  @override
  Widget build(BuildContext context) {
    return RepositoryProvider<AuthRepository>(
      create: (_) => _authRepository ?? AuthRepository(),
      child: MaterialApp(
        title: 'OEd · ACA Student',
        debugShowCheckedModeBanner: false,
        theme: CkdTheme.light(),
        home: const LoginPage(),
      ),
    );
  }
}
