<p align="center">
  <img src="docs/brand/logo-mark-transparent.png" width="120" height="120" alt="Loopweek logo" />
</p>

<h1 align="center">Loopweek</h1>

<p align="center">
  <em>One screen, seven days, nothing else.</em><br>
  A free, fully open-source weekly to-do app for Android, built in Flutter.<br>
  No accounts · No cloud sync · No tracking · No ads · No paywall
</p>

<p align="center">
  <a href="https://github.com/ZaryabKhan/loopweek/actions/workflows/build.yml"><img src="https://github.com/ZaryabKhan/loopweek/actions/workflows/build.yml/badge.svg" alt="Build"></a>
  <a href="https://github.com/ZaryabKhan/loopweek/releases/latest"><img src="https://img.shields.io/github/v/release/ZaryabKhan/loopweek?display_name=tag&include_prereleases&logo=semantic-release&logoColor=white" alt="Latest Release"></a>
  <a href="https://github.com/ZaryabKhan/loopweek/releases"><img src="https://img.shields.io/github/downloads/ZaryabKhan/loopweek/total?logo=github" alt="Downloads"></a>
  <a href="https://github.com/ZaryabKhan/loopweek/stargazers"><img src="https://img.shields.io/github/stars/ZaryabKhan/loopweek?style=social" alt="Stars"></a>
  <a href="https://github.com/ZaryabKhan/loopweek/forks"><img src="https://img.shields.io/github/forks/ZaryabKhan/loopweek?style=social" alt="Forks"></a>
  <br>
  <a href="LICENSE"><img src="https://img.shields.io/badge/License-MIT-yellow.svg?logo=opensourceinitiative&logoColor=black" alt="License: MIT"></a>
  <a href="#"><img src="https://img.shields.io/badge/Platform-Android-3DDC84?logo=android&logoColor=white" alt="Platform"></a>
  <a href="https://flutter.dev"><img src="https://img.shields.io/badge/Flutter-stable-02569B?logo=flutter&logoColor=white" alt="Flutter"></a>
  <a href="https://dart.dev"><img src="https://img.shields.io/badge/Dart-3.x-0175C2?logo=dart&logoColor=white" alt="Dart"></a>
  <a href="https://github.com/ZaryabKhan/loopweek/issues"><img src="https://img.shields.io/github/issues/ZaryabKhan/loopweek?logo=github" alt="Issues"></a>
  <a href="https://github.com/ZaryabKhan/loopweek/pulls"><img src="https://img.shields.io/github/issues-pr/ZaryabKhan/loopweek?logo=github" alt="PRs"></a>
  <a href="CONTRIBUTING.md"><img src="https://img.shields.io/badge/PRs-welcome-brightgreen?logo=git&logoColor=white" alt="PRs Welcome"></a>
  <a href="https://github.com/ZaryabKhan/loopweek/graphs/contributors"><img src="https://img.shields.io/github/contributors/ZaryabKhan/loopweek?logo=github" alt="Contributors"></a>
  <a href="SECURITY.md"><img src="https://img.shields.io/badge/Security-Policy-blue?logo=shield&logoColor=white" alt="Security"></a>
</p>

Jump to: [Features](#-features) · [Screenshots](#-screenshots) · [Tech Stack](#%EF%B8%8F-tech-stack) · [Getting Started](#-getting-started) · [Contributing](#-contributing) · [Security](#-security) · [License](#-license)

---

## ✨ Features

Loopweek is an original, clean-room implementation of the "one screen, seven
days" concept — no calendar grid, no month view, no navigation between screens
for the core loop. 100% local, on-device storage.

| Feature | Description |
| --- | --- |
| 📅 | **Single-screen week view** — All seven days live on one screen as an accordion; today is expanded by default, tapping a collapsed day expands it and collapses the open one. |
| ⏳ | **Date-specific tasks, no auto-rollover** — Incomplete tasks stay on their original date forever unless you manually move them. |
| 🔁 | **Independent recurring occurrences** — Completing or deleting one occurrence never affects past or future occurrences; stop future recurrence without touching history. |
| 🎨 | **One accent color drives everything** — Pick Orange / Pink / Blue / Green in Settings; the same color fills checkboxes, segmented controls, toggles, primary actions, and the home-screen widget. |
| 🌗 | **Light / dark theme** — Follows the system setting with a manual override. |
| 🔔 | **Optional reminders** — Notification permission is requested only when you actually switch a reminder on — never at startup. |
| 📱 | **Home-screen widget** — Today's tasks on your launcher, with checkboxes that toggle completion in the background without opening the app. |
| 🧭 | **Drag-and-drop reordering** — Reorder tasks within a day by dragging. |
| 🔒 | **No ads · No analytics · No accounts** — Your data never leaves the device. |

## 📸 Screenshots

> Screenshots coming soon. Place captures in `docs/images/` and reference them above.

## 🛠️ Tech stack

| Layer | Technology |
| --- | --- |
| 💻 Language | [Dart](https://dart.dev) (null-safe) |
| 📱 Framework | [Flutter](https://flutter.dev) (stable channel) |
| 🎨 UI | Material 3 (Material widgets + custom theme tokens) |
| 🏛️ Architecture | Clean separation: `data` / `domain` / `presentation` |
| 🗃️ Database | [Drift](https://drift.simonbinder.eu/) (SQLite) for tasks & recurrence |
| 🔄 State | [Riverpod](https://riverpod.dev) (`flutter_riverpod`) |
| 🔔 Notifications | [`flutter_local_notifications`](https://pub.dev/packages/flutter_local_notifications) + [`timezone`](https://pub.dev/packages/timezone) |
| 📱 Widget | [`home_widget`](https://pub.dev/packages/home_widget) for the Android App Widget |
| ⚙️ Preferences | [`shared_preferences`](https://pub.dev/packages/shared_preferences) |
| 🧪 Testing | Flutter test (`flutter test`) — recurrence suite is the canonical coverage |

**📦 Full dependency list**

- `flutter` SDK
- `cupertino_icons`
- `drift`, `sqlite3_flutter_libs`, `path_provider`, `path`
- `flutter_riverpod`
- `uuid`
- `flutter_local_notifications`, `timezone`
- `home_widget`
- `shared_preferences`
- `intl`, `collection`, `url_launcher`
- dev: `flutter_test`, `flutter_lints`, `drift_dev`, `build_runner`

## 📋 Requirements

- **Flutter** stable channel (3.11.x / SDK `^3.11.4`)
- **JDK 17** or newer (for Android Gradle builds)
- **Android SDK 36** (`compileSdk = 36`, `targetSdk = 36`), `minSdk` = Flutter default
- An Android device or emulator (API 21+)

## 🚀 Getting started

```sh
# 1. Clone the repository
git clone https://github.com/ZaryabKhan/loopweek.git
cd loopweek

# 2. Install dependencies
flutter pub get

# 3. Generate the Drift database code (rerun after any change to tasks_table.dart)
dart run build_runner build --delete-conflicting-outputs

# 4. Run on a device/emulator
flutter run

# 5. Build a debug APK
flutter build apk --debug
```

The debug APK will be at `build/app/outputs/flutter-apk/app-debug.apk`.

**🎁 JDK note for CLI builds**

Gradle uses the JDK on your `JAVA_HOME`/`PATH`. To pin a specific JDK for local
CLI builds, set `org.gradle.java.home=...` in `~/.gradle/gradle.properties`
(user-level, **not** committed).

## 🧭 Project structure

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

## 🧪 Tests

```sh
flutter analyze   # lint
flutter test     # unit + widget tests
```

The recurrence suite is the canonical coverage for the most bug-prone logic;
the smoke test in `test/widget_test.dart` verifies the app boots and renders
the week heading.

## 📱 Home-screen widget

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

## 🔒 Privacy

Loopweek stores everything on the device. There is no network code in the
release build, no analytics, no telemetry, and no crash reporting that sends
data anywhere. Notification permission is requested only when you opt into a
reminder; nothing else asks for any permission.

## 🤝 Contributing

Contributions are welcome! Please read [CONTRIBUTING.md](CONTRIBUTING.md) to
learn how to set up the project and submit pull requests.

> **Loopweek is intentionally small.** The spec is "one screen, seven days,
> nothing else." Out-of-scope ideas (cloud sync, accounts, calendar view,
> subtasks, tags beyond the four colors, ads, analytics, IAP) won't be merged
> even if the code is good. When unsure, open an issue first and ask.

Looking for a good place to start? Check for issues labeled
[`good first issue`](https://github.com/ZaryabKhan/loopweek/labels/good%20first%20issue)
and [`help wanted`](https://github.com/ZaryabKhan/loopweek/labels/help%20wanted).

```sh
# Fork → Branch → Commit → PR
git checkout -b feat/my-awesome-feature
```

**📜 Code of conduct**

By participating you agree to abide by the [Code of Conduct](CODE_OF_CONDUCT.md). Be kind and respectful.

## 🔒 Security

Found a vulnerability? Please **do not** open a public issue. See
[SECURITY.md](SECURITY.md) for how to report it privately.

## 📝 Changelog

See the [Releases](https://github.com/ZaryabKhan/loopweek/releases) page for version history.
For how to publish a release, see [RELEASE.md](RELEASE.md) and [RELEASE-CHEATSHEET.md](RELEASE-CHEATSHEET.md).

## 📜 License

Loopweek is licensed under the **MIT License** — see [LICENSE](LICENSE).
Loopweek is an original product; it is not derived from any other app's name,
logo, or code.

---

<p align="center">
  Built with ❤️ by <a href="https://github.com/ZaryabKhan">Zaryab Khan</a> & <a href="https://github.com/ZaryabKhan/loopweek/graphs/contributors">contributors</a>.<br>
  If Loopweek is useful to you, consider ⭐ starring the repo to support development.
  <br><br>
  <a href="https://github.com/ZaryabKhan/loopweek/issues/new?labels=bug&template=bug_report.yml">Report a bug</a> · <a href="https://github.com/ZaryabKhan/loopweek/issues/new?labels=enhancement&template=feature_request.yml">Request a feature</a> · <a href="https://github.com/ZaryabKhan/loopweek/discussions">Discussions</a>
</p>