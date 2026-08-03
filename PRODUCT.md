# Product

<!-- impeccable:product-schema 1 -->

## Platform

android

## Stack

Flutter (stable), Dart with null-safety.
- Local storage: Drift (SQLite) via `sqlite3_flutter_libs`, `path_provider`, `path`.
- State management: Riverpod (`flutter_riverpod`).
- IDs: `uuid`.
- Notifications: `flutter_local_notifications` + `timezone` (opt-in reminders).
- Home screen widget: `home_widget` (Android App Widget, native `RemoteViews`).
- Preferences: `shared_preferences` (accent color + theme override).
- Misc: `intl`, `collection`.
- Dev: `flutter_lints`, `drift_dev`, `build_runner`.

No backend, no analytics SDK, no crash reporting that phones home — hard requirement. License: MIT.

## Users

Primary user: someone who wants a dead-simple weekly task list — one screen, seven days — with no accounts, no cloud, and no clutter. The job is to see the week at a glance and check off today's tasks without the overhead of calendars, projects, or tags.

## Product Purpose

Loopweek is a free, fully open-source weekly to-do app whose entire value is constraint: one screen, seven days, nothing else. No calendar grid, no month view, no navigation between screens for the core loop. Success means the user can plan and complete a week without ever leaving a single screen, and without the app asking anything of them (no account, no permission, no payment).

## Positioning

An original, clean-room implementation of the "one screen, seven days" concept. Its meaningfully different position is a weekly planner that makes constraint the feature: the accordion single-open-day model keeps the screen short and predictable, tasks are date-specific with no automatic rollover (incomplete tasks stay on their original date forever), and recurring tasks generate independent occurrences so editing one never touches past or future.

## Operating Context

- Daily-driving on a phone; the week view is the home destination, reached repeatedly through the day.
- Optional home-screen widget puts today's tasks on the launcher with checkboxes that toggle completion in the background without opening the app.
- 100% local, on-device storage; everything works offline.
- System light/dark mode is followed automatically with a manual override in Settings.
- Reminder notifications are optional and opt-in.

## Capabilities and Constraints

- Single-screen week view as an accordion: exactly one day expanded at a time; today is expanded by default. Tapping a collapsed day expands it and collapses the previously open day.
- Day-specific tasks with **no automatic rollover**. An incomplete task stays on its original date forever unless the user manually moves it.
- Recurrence (never / daily / weekly) materializes independent rows linked back to the source rule by `recurrenceParentId`. Completing or deleting one occurrence never affects past or future occurrences; future recurrence can be stopped without touching history.
- Task fields: `id`, `title`, `date`, `isCompleted`, `colorTag` (orange | pink | blue | green, default orange), `hasTime`, `time`, `hasReminder`, `recurrence`, `recurrenceParentId`, `sortOrder`.
- One accent color per user preference drives the active checkbox, the selected segmented-control option, toggle switches, primary actions, and the home-screen widget.
- Light/dark theme follows system with manual override.
- Optional reminders; notification permission is requested only when the user actually switches a reminder on — never at startup.
- Home-screen widget: medium size shows today + up to 5 tasks (incomplete prioritized); large size shows up to 10 tasks, or today + tomorrow when today is sparse. Widget uses the user's selected accent color.
- Interaction model is tap and long-press only (long-press to remove or reorder). No swipe gestures.

### Out of scope (hard)
No cloud sync, no accounts or login, no calendar/month view, no subtasks, no tags or projects beyond the 4 color tags, no priority levels beyond color, no AI features, no ads, no analytics, no in-app purchases.

## Brand Commitments

- Name: **Loopweek** — an original product, not derived from any other app's name, logo, or code.
- Voice: plain, direct, de-emphasized. Copy is minimal and functional ("Add a new task...", "Scheduled for", "Remind me", "Hold to remove tasks or reorder by time and priority.").
- Binding visual constraint (recorded, not expanded): bold, tight-tracking, condensed sans-serif for day headers and section titles — heavy weight, slightly reduced letter spacing. This is the app's stated main visual signature to keep consistent everywhere a heading appears.
- Binding visual constraint (recorded, not expanded): single accent color per user (default orange, roughly `#F4511E`) for active checkboxes, selected segmented control, toggles, and primary actions; light theme off-white `#F2F2F2`-ish with white content areas; dark theme near-black `#121212`-ish with dark gray content areas (avoid pure black/pure white); flat design, no shadows/heavy card elevation, dividers do the separating; moderate corner radius (~10-12dp), toggles remain pill-shaped.

## Evidence on Hand

- `README.md` — full setup, architecture, recurrence-risk, privacy, and home-widget description.
- `docs/Loopweek product spec.md` — the complete original project brief handed to the implementation.
- `CONTRIBUTING.md`, `LICENSE` (MIT) — present and public-repo-ready.
- No logo or named brand asset is provided in-repo; future work must not fabricate one.
- No testimonials, customers, benchmarks, pricing, or deployment evidence exists; future work must not invent any.

## Product Principles

1. **Constraint is the feature.** One screen, seven days, nothing else — refusing features is a principle, not a backlog gap.
2. **The week is the screen.** No navigation for the core loop; the accordion keeps the single-open-day model short and predictable.
3. **Tasks belong to their date.** No rollover, ever — an incomplete task stays where it was put until the user moves it.
4. **Nothing asks anything of the user.** No account, no cloud, no ads, no paywall, no upfront permission; notifications and widget are pure opt-in.
5. **One color, flat design, marks the surface.** A single accent color and dividers (never shadows) carry the entire visual system.

## Accessibility & Inclusion

- Light/dark follows system with manual override.
- No product-specific accessibility standard beyond Flutter/Material defaults has been established; treat as an open decision.