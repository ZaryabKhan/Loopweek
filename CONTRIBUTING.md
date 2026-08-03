# Contributing to Loopweek

Thanks for considering a contribution! Loopweek is an original, MIT-licensed
weekly to-do app. A few ground rules keep it on mission:

## Scope rules — please read

Loopweek is intentionally small. The spec is "one screen, seven days, nothing
else." Before opening a PR, please check that your change fits:

- **In scope:** week view polish, recurrence correctness, accessibility,
  theming, the home-screen widget, performance, tests, dependency updates,
  platform fixes, docs.
- **Out of scope:** cloud sync, accounts or login, calendar / month view,
  subtasks, tags or projects beyond the four color tags, priority levels
  beyond color, AI features, ads, analytics, in-app purchases. We will not
  merge these even if the code is good.

If you are unsure whether your idea is in scope, open an issue first and ask.

## Development workflow

1. Fork and clone the repo.
2. `flutter pub get`
3. `flutter pub run build_runner build --delete-conflicting-outputs`
   (regenerates the Drift database code; rerun after any change to
   `lib/data/database/tasks_table.dart`).
4. Make your change. Keep the
   `data / domain / presentation` separation:
   - Domain stays pure Dart (no Flutter, no Drift) so it stays unit-testable.
   - Presentation only talks to providers; it never touches the database
     or `SharedPreferences` directly.
5. Add or update tests. The recurrence generator has the highest coverage
   bar — any change to `lib/domain/services/recurrence_generator.dart`
   must come with tests in `test/recurrence_generator_test.dart`.
6. Run quality gates before pushing:

   ```sh
   flutter analyze
   flutter test
   ```

   Both must be clean.

## Code style

- Follow `flutter_lints` (already enabled in `analysis_options.yaml`).
- No `print()`; use `debugPrint` for diagnostics.
- No new runtime dependencies without an issue discussion — every dep
  increases APK size and the privacy attack surface. No analytics, no
  crash-reporting SDKs that phone home.

## Commit messages

Use the conventional format:

```
<area>: <imperative summary>

<optional body, wrap at 72>
```

Examples: `recurrence: handle months-spanning weekly windows`, `widget: fix
row tint when accent changes`, `docs: clarify privacy section`.

## Pull requests

- One PR per concern, small and reviewable.
- Reference the issue it closes (if any) in the PR description.
- Include before/after screenshots for UI changes.
- Don't commit the generated `*.g.dart` files manually if the build runner
  output already covers them — do run build_runner before pushing so CI can
  verify generated files match the source.

## Licensing

By contributing you agree that your changes will be released under the
project's [MIT License](LICENSE).

## Code of conduct

Be kind. The project is small, the scope is narrow, and "no" to an
out-of-scope idea is not a "no" to you as a person — it's a "yes" to keeping
Loopweek trustworthy.