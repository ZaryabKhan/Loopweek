# Loopweek

**One screen, seven days, nothing else.**

Loopweek is a free, fully open-source weekly to-do app for Android, built in
Flutter. It is an original, clean-room implementation of the "one screen,
seven days" concept — no calendar grid, no month view, no navigation between
screens for the core loop. No accounts, no cloud sync, no tracking, no ads, no
paywall. 100% local, on-device storage.

## Highlights

- **Single-screen week view.** All seven days live on one screen as an
  accordion — today is expanded by default, tapping a collapsed day expands it
  and collapses whichever day was open.
- **Date-specific tasks with no automatic rollover.** Incomplete tasks stay
  on their original date forever unless the user manually moves them.
- **Recurring tasks generate independent occurrences.** Completing or
  deleting one occurrence never affects past or future occurrences, and you
  can stop future recurrence without touching history.
- **One accent color drives everything.** Pick from Orange / Pink / Blue /
  Green in Settings; the same color fills the active checkbox, the selected
  segmented-control option, toggle switches, primary actions, and the
  home-screen widget.
- **Light / dark theme.** Follows the system setting with a manual override.
- **Optional reminders.** Notification permission is requested only when you
  actually switch a reminder on — never at startup.
- **Home-screen widget.** Today's tasks on your launcher, with checkboxes
  that toggle completion in the background without opening the app.

## Tech stack

- **Flutter** (stable channel), Dart with null-safety.
- **Drift** (SQLite) for local structured storage of tasks and recurrence.
- **Riverpod** for state management.
- `flutter_local_notifications` + `timezone` for optional task reminders.
- `home_widget` for the Android App Widget.
- `shared_preferences` for the user's color + theme choice.

No backend, no analytics SDK, no crash reporting that phones home — hard
requirement.

## Architecture

The project keeps data, domain, and presentation concerns separate:

```
lib/
├── core/
│   └── theme/            AppTheme + AccentColors (light/dark/system, accent)
├── data/
│   ├── database/        Drift [Tasks] table, [LoopweekDatabase], [TaskMapper]
│   ├── repositories/    TaskRepository — persistence + recurrence materialization
│   └── services/        SettingsService, NotificationService, HomeWidgetService
├── domain/
│   ├── models/          Task, ColorTag, Recurrence
│   └── services/        RecurrenceGenerator (pure date logic — unit tested)
├── presentation/
│   ├── providers.dart   Riverpod providers (DB, repository, settings, …)
│   ├── week/            WeekView, DayHeader, TaskTile, week_providers
│   ├── task_sheet/      Add/Edit Task modal sheet
│   └── settings/        Settings screen (color, theme, alerts, widget preview)
└── main.dart            App entrypoint + home-widget background callback
```

### Recurrence — the highest-risk area

`lib/domain/services/recurrence_generator.dart` is a pure, dependency-free
class that computes forward occurrence dates for a given rule within an
inclusive window. The storage layer (`TaskRepository.materializeOccurrences`)
uses it to generate independent rows linked back to the source rule by
`recurrenceParentId`. Unit tests in `test/recurrence_generator_test.dart`
cover daily/weekly step math, window boundaries, anchor inclusion, anchor
exclusion, and multi-month spans.

## Setup

Requirements: Flutter stable (3.11.x), an Android device or emulator.

```sh
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs
flutter run
```

Build a release APK:

```sh
flutter build apk --release
```

## Tests

```sh
flutter test
```

The recurrence suite is the canonical coverage for the most bug-prone logic;
the smoke test in `test/widget_test.dart` verifies the app boots and renders
the week heading.

## Home-screen widget

The widget ships as native Android XML (`RemoteViews`):

- `android/.../LoopweekWidgetProvider.kt` — the
  `es.antonborri.home_widget.HomeWidgetProvider` subclass that renders the
  list and routes checkbox taps to a background isolate.
- `android/.../res/layout/loopweek_widget.xml` — the row layout.
- `android/.../res/xml/loopweek_widget_info.xml` — `AppWidgetProviderInfo`
  (medium size, resizable).

Flutter pushes a compact snapshot of today's tasks through
`HomeWidget.saveWidgetData`; the native side parses a newline-separated
marshalled string of rows (`id|done|title|HH:MM|`). Tapping a row fires a
broadcast that the Dart isolate callback registered in `lib/main.dart` turns
into a one-line `UPDATE tasks SET is_completed = (1 - is_completed) WHERE id = ?`
— toggling completion without launching the app.

## Privacy

Loopweek stores everything on the device. There is no network code in the
release build, no analytics, no telemetry, and no crash reporting that sends
data anywhere. Notification permission is requested only when you opt into a
reminder; nothing else asks for any permission.

## License

MIT — see [LICENSE](LICENSE). Loopweek is an original product; it is not
derived from any other app's name, logo, or code.

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md).