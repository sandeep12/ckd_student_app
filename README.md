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

## API integration

The login screen talks to the backend (`POST /api/v1/auth/login`):

- Base URL defaults to `http://localhost:3001` (`http://10.0.2.2:3001` on
  Android emulators). Override with
  `flutter run --dart-define=API_BASE_URL=https://api.example.com`.
- `lib/core/api/` — `ApiClient` unwraps the backend's
  `{data, error, code, details}` envelope and throws typed `ApiException`s.
- `lib/features/auth/data/` — `AuthRepository` (login / me / refresh /
  logout) and tolerant payload models; tokens persist via
  `shared_preferences` (swap for secure storage before production).
- Error mapping in `LoginCubit`: `VALIDATION_ERROR` issues land on the
  fields, `INVALID_CREDENTIALS` / `ACCOUNT_LOCKED` / network failures show
  the danger banner, matching the Figma error states.
- `dart run tool/api_smoke.dart` smoke-tests the client against the live
  local backend.

Behaviour: the CTA stays disabled until "I agree to the Terms & Privacy
Policy" is checked; invalid input shows field errors before any request
is made.
