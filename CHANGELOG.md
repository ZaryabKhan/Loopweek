# Changelog

## 1.2.0

- Plan ahead: switch between This week and Next week right on the main screen.
- Weeks can start on Sunday or Monday (System follows your device).
- New recurrence options: biweekly, monthly, yearly — reminders follow along.
- Export and import a local JSON backup of tasks and settings.
- Task removal now offers undo, and tasks can be moved to another day from long-press.
- Save a week as a template and re-apply it when starting a fresh week.
- Browse past weeks read-only from the new history icon.
- Park day-less ideas in the new Someday list until you give them a day.
- Home-screen widget gains a small 1x1 size with the same dark-mode behavior.
- Print the current week to paper or PDF from Settings.
- One-time "Finding Loopweek useful?" rating prompt on Google Play builds.

## 1.1.0

- Added in-app donation tip tiers (small, medium, large) shown on Google Play builds; the polar.sh support link stays on GitHub builds.
- Added a CI lane that builds the playstore-flavor AAB and uploads it to the Google Play internal testing track.
- Home-screen widget checkboxes now work — taps register instantly.
- Added a "Send feedback" row in Settings that opens a pre-addressed email with the app version in the subject.

## 1.0.3

- Made notifications robust and reliable on Android (ProGuard keep rules, stable notification IDs, exact-alarm fallback, startup reconciliation).
- Fixed bugs where reminders could silently fail or get lost on release builds.
- Added haptic feedback throughout the app, with a setting to disable it (enabled by default).
