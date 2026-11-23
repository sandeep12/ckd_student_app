# ckd_student_app

ACA CKD **student** application — Flutter, mobile (iOS/Android) + web.
Frontend only; currently ships the Student Login module.

Design source: Figma **ACA-CKD-V2**, page `08_Student_Web_And_Mobile`
("01 · Login (Web)", "02 · Login (Mobile)").

## Architecture

- **State management:** `flutter_bloc` Cubits.
  - `LoginCubit` + `LoginState` (`lib/features/auth/cubit/`) own all form
    state: input values, password visibility, terms acceptance, validation,
    and the submit lifecycle (`idle → submitting → success | failure`).
  - Views are dumb: `BlocBuilder`/`BlocListener` over the cubit.
- **Design system:** every color, text style, spacing, radius and component
  comes from the separate [`ckd_design_system`](../ckd_design_system) repo
  (path dependency during development).
- **Responsive:** `LoginPage` switches at 900px — two-panel auth card with
  hero illustration on web, single card on mobile.

```
lib/
  main.dart
  app.dart
  features/auth/
    cubit/login_cubit.dart   # + login_state.dart (part)
    view/login_page.dart
    view/widgets/login_form.dart
    view/widgets/login_hero_panel.dart
```

## Run

```sh
flutter pub get
flutter run -d chrome        # web
flutter run                  # connected device / simulator
flutter test
```

## Demo behaviour (no backend yet)

- The CTA stays disabled until "I agree to the Terms & Privacy Policy" is
  checked (as designed).
- Submitting with invalid input shows field errors.
- Any credentials sign in after a simulated delay; use the password
  `wrong-password` to see the invalid-credentials error banner.
