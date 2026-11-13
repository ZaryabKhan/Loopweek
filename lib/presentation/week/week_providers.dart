import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:loopweek/domain/models/first_day_of_week.dart';
import 'package:loopweek/domain/models/task.dart';
import 'package:loopweek/presentation/providers.dart';

/// The 7 calendar dates of the week containing [anchor], starting on
/// [firstDay].
///
/// Always returns date-only [DateTime]s.
List<DateTime> weekDatesFor(DateTime anchor, FirstDayOfWeek firstDay) {
  final DateTime normalized = DateTime(anchor.year, anchor.month, anchor.day);
  final int firstDayDart = _firstDayAsDartWeekday(firstDay);
  final int offset = (normalized.weekday - firstDayDart) % 7;
  final int positive = offset < 0 ? offset + 7 : offset;
  final DateTime start = normalized.subtract(Duration(days: positive));
  return List.generate(7, (i) => start.add(Duration(days: i)));
}

/// Resolves the setting to a Dart weekday constant (Mon=1 ... Sun=7).
/// System reads the device locale's first-day-of-week from intl date
/// symbols; falls back to Sunday when a locale has no data.
int _firstDayAsDartWeekday(FirstDayOfWeek firstDay) {
  switch (firstDay) {
    case FirstDayOfWeek.sunday:
      return DateTime.sunday;
    case FirstDayOfWeek.monday:
      return DateTime.monday;
    case FirstDayOfWeek.system:
      try {
        final symbols = DateFormat('EEEE', Platform.localeName).dateSymbols;
        // ICU numbering: 0 = Sunday ... 6 = Saturday.
        final int icu = symbols.FIRSTDAYOFWEEK;
        return icu == 0 ? DateTime.sunday : icu + 1;
      } catch (_) {
        return DateTime.sunday;
      }
  }
}

/// Today's date, midnight-truncated. Provided as a ProviderArg so tests can
/// override; UI reads it through [todayProvider].
final todayProvider = StateProvider<DateTime>(
  (_) =>
      DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day),
);

/// Which week is shown on the main view: 0 = this week, 7 = next week.
/// Session-only — the view always starts on this week.
final weekOffsetProvider = StateProvider<int>((ref) => 0);

/// The 7 days shown on the main week view, anchored on today plus the
/// [weekOffsetProvider] day-shift.
final weekDatesProvider = Provider<List<DateTime>>((ref) {
  return weekDatesFor(
    ref.watch(todayProvider).add(Duration(days: ref.watch(weekOffsetProvider))),
    ref.watch(settingsProvider).firstDayOfWeek,
  );
});

/// Stream of tasks for a given date, sorted by [sortOrder] then title.
final tasksForDateProvider = StreamProvider.family<List<Task>, DateTime>((
  ref,
  date,
) {
  return ref.watch(taskRepositoryProvider).watchTasksForDate(date);
});

/// Tracks which day-section is currently expanded (accordion, single-open).
final expandedDayProvider = StateProvider<DateTime?>((ref) {
  return ref.watch(todayProvider);
});

/// Whether the database holds any task at all. Drives the first-task
/// orientation shown on an empty week.
final hasAnyTasksProvider = StreamProvider<bool>((ref) {
  return ref
      .watch(taskRepositoryProvider)
      .watchTaskCount()
      .map((count) => count > 0);
});
