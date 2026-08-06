# Product Spec — Loopweek (Android, Flutter, Open Source)

---

## Project overview

Build **Loopweek**, a free, fully open-source weekly to-do app for Android, built in Flutter. It is an original product — a clean-room implementation of the "one screen, seven days" concept, not a copy of any existing app's name, logo, or code.

Core philosophy: **one screen, seven days, nothing else.** No calendar grid, no month view, no navigation between screens for the core loop. No accounts, no cloud sync, no tracking, no ads, no paywall. 100% local, on-device storage.

## Tech stack

- **Flutter** (stable channel), Dart null-safety
- **Local storage:** Drift (SQLite) for structured querying of recurrence and date logic
- **State management:** Riverpod
- **Notifications:** `flutter_local_notifications` for optional task reminders
- **Home screen widget:** `home_widget` package (Android App Widget)
- No backend, no analytics SDK, no crash reporting that phones home — hard requirement
- License: MIT. Include LICENSE, README.md, and CONTRIBUTING.md suitable for a public GitHub repo

## Data model

```
Task {
  id: uuid
  title: String
  date: DateTime            // every task belongs to a specific calendar date
  isCompleted: bool
  colorTag: enum (orange | pink | blue | green)   // default orange
  hasTime: bool
  time: TimeOfDay?
  hasReminder: bool
  recurrence: enum (never | daily | weekly)
  recurrenceParentId: uuid?   // links generated occurrences back to their source rule
  sortOrder: int              // manual ordering within a day
}
```

Behavior rules:
- Tasks are **date-specific with no automatic rollover**. An incomplete task stays on its original date forever unless the user manually moves it.
- Recurring tasks generate independent occurrences. Completing or deleting one occurrence never affects past or future occurrences. The user can stop future recurrence without touching history.

## Screens & UI

### 1. Main week view (home screen)
- Vertical list of all 7 days. Today's section is expanded by default and shows its tasks; other days are collapsed to just the bold day name.
- Tapping a collapsed day expands it and collapses whichever day was previously open — only one day is expanded at a time (accordion behavior), keeping the screen predictable and short.
- Day header: bold, condensed, all-caps sans-serif (e.g. "SUNDAY"), large size, with the date beneath it in smaller regular weight (e.g. "August 2").
- Top-right corner: small locale/flag icon + gear icon opening Settings.
- Task row: square checkbox on the left, task title, optional small bell icon + time on the right when a reminder is set, optional loop icon when the task is recurring.
- Completed tasks: checkbox fills with the active color tag, title gets a strikethrough.
- "Add a new task..." row pinned at the bottom of the expanded day, with a **+** button aligned right.
- Thin horizontal divider lines separate day sections. Flat list aesthetic — no cards, no shadows.

### 2. Add/Edit Task sheet (modal, slides up from bottom)
- Header row: "Cancel" (left) — "New Task" (center, bold) — "Add" (right, accent color).
- Title text field, plain underline style, placeholder text.
- **Day section:** label "Day", row "Scheduled for" with the date right-aligned, tappable to open a date picker.
- **Repeat section:** label "Repeat", segmented control with three options — Never / Daily / Weekly (selected option filled with accent color). When Weekly is selected, show a small caption below, e.g. "Every Sunday".
- **Time section:** label "Time", row "Task has a time" with a toggle switch; enabling it reveals a time picker row.
- **Reminder section:** label "Reminder", row "Remind me" with a toggle switch; enabling it reveals Day/At rows showing when the notification will fire.
- Each section sits in a rounded rectangle card, background color adapts to light/dark theme, generous internal padding.

### 3. Settings screen
- Back chevron + "Settings" title, large bold.
- **Task Colour:** 4 circular swatches in a row (Orange, Pink, Blue, Green) with labels beneath; the selected swatch shows a checkmark overlay. This color also drives the checkbox fill and widget accent.
- **Times & Alerts:** description text + toggle switch. Notification permission is requested only when the user saves their first alert — never requested upfront.
- **Also on your home screen:** explanatory copy about the widget, plus a compact live-style preview list mirroring the main list styling.
- **Gestures:** explanatory copy — "Hold to remove tasks or reorder by time and priority."

### 4. Home screen widget
- Medium size: today's date + up to 5 tasks, incomplete tasks prioritized to the top.
- Large size: up to 10 tasks, or today + tomorrow combined when today has few tasks.
- Widget uses the user's selected color tag from Settings so app and widget stay visually consistent.
- Tapping a checkbox in the widget toggles completion directly via a background callback, without opening the app.

## Visual design system

- **Typography:** bold, tight-tracking, condensed sans-serif for day headers and section titles — heavy weight, slightly reduced letter spacing. This is the app's main visual signature; keep it consistent everywhere a heading appears.
- **Color:** single accent color per user preference (default orange, roughly `#F4511E`), used for active checkboxes, the selected segmented control option, toggle switches, and primary actions like "Add".
- **Backgrounds:** light theme uses an off-white/light gray background (`#F2F2F2`-ish) with white content areas; dark theme uses near-black (`#121212`-ish) with dark gray content areas — avoid pure black and pure white.
- **No shadows, no heavy card elevation** — flat design, dividers do the separating.
- Follows system light/dark mode automatically, with a manual override in Settings.
- Rounded corners on interactive elements (toggles, segmented controls, modal sheet) at a moderate radius (~10-12dp); toggles themselves remain pill-shaped.

## Interaction details

- **Tap checkbox:** instantly toggles complete — fills with the color tag, strikes through the title, no confirmation dialog.
- **Tap a collapsed day name:** expands it and collapses the previously open day (accordion, single-open-day model).
- **Long-press a task:** enters reorder mode with a drag handle, and/or reveals a delete action, matching the "Hold to remove tasks or reorder" copy in Settings.
- No swipe gestures — tap and long-press are the only interaction model for tasks.

## Explicitly out of scope

No cloud sync, no accounts or login, no calendar/month view, no subtasks, no tags or projects beyond the 4 color tags, no priority levels beyond color, no AI features, no ads, no analytics, no in-app purchases.

## Deliverables

1. Flutter project scaffold with clean architecture (data/domain/presentation separation).
2. Working local database implementing the Task model and recurrence generation logic described above.
3. All four screens/surfaces (week view, add/edit sheet, settings, home screen widget) fully implemented per this spec.
4. Light/dark theme support, following system setting with manual override.
5. README.md covering setup, architecture, and contribution guidelines.
6. Unit tests covering the recurrence logic specifically, since it's the highest-risk area for bugs.
