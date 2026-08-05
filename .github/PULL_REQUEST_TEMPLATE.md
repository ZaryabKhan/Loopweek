## Description

<!-- What does this PR do? Link any related issues, e.g. "Closes #123". -->

## Type of change

- [ ] Bug fix (non-breaking change which fixes an issue)
- [ ] New feature (non-breaking change which adds functionality)
- [ ] Breaking change (fix or feature that would cause existing functionality to not work as expected)
- [ ] Documentation / chore

## Scope check

<!-- Loopweek is intentionally small. Confirm this change is in scope (see CONTRIBUTING.md). -->
- [ ] This change fits the "one screen, seven days, nothing else" spec
- [ ] This change does **not** add cloud sync, accounts, calendar view, subtasks, tags beyond the four colors, ads, analytics, or IAP

## Checklist

- [ ] My code follows the existing style of the project (`flutter_lints`)
- [ ] I kept the `data / domain / presentation` separation (domain stays pure Dart)
- [ ] I ran `flutter pub run build_runner build --delete-conflicting-outputs` if I changed `tasks_table.dart`
- [ ] I have built the project (`flutter build apk --debug`) and it compiles
- [ ] I have run `flutter analyze` and `flutter test` and both pass
- [ ] I have **not** committed any secrets, keystores, or private credentials
- [ ] I have not introduced analytics, tracking, or ads
- [ ] I have updated documentation where relevant
- [ ] I added/updated tests for changes to `recurrence_generator.dart`