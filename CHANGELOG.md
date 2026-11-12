# Changelog

## 1.1.0

- Added in-app donation tip tiers (small, medium, large) shown on Google Play builds; the polar.sh support link stays on GitHub builds.
- Added a CI lane that builds the playstore-flavor AAB and uploads it to the Google Play internal testing track.
- Added a "Send feedback" row in Settings that opens a pre-addressed email with the app version in the subject.

## 1.0.3

- Made notifications robust and reliable on Android (ProGuard keep rules, stable notification IDs, exact-alarm fallback, startup reconciliation).
- Fixed bugs where reminders could silently fail or get lost on release builds.
- Added haptic feedback throughout the app, with a setting to disable it (enabled by default).
