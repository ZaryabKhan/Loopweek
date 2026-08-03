import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:loopweek/domain/models/task.dart';
import 'package:loopweek/presentation/providers.dart';

/// The 7 calendar dates of the week containing [anchor] (Sunday-first).
///
/// Always returns date-only [DateTime]s.
List<DateTime> weekDatesFor(DateTime anchor) {
  final DateTime normalized = DateTime(anchor.year, anchor.month, anchor.day);
  final int offset = normalized.weekday % 7; // Sunday=0
  final DateTime sunday = normalized.subtract(Duration(days: offset));
  return List.generate(7, (i) => sunday.add(Duration(days: i)));
}

/// Today's date, midnight-truncated. Provided as a ProviderArg so tests can
/// override; UI reads it through [todayProvider].
final todayProvider = StateProvider<DateTime>(
  (_) => DateTime(
    DateTime.now().year,
    DateTime.now().month,
    DateTime.now().day,
  ),
);

/// The 7 days shown on the main week view.
final weekDatesProvider =
    Provider<List<DateTime>>((ref) => weekDatesFor(ref.watch(todayProvider)));

/// Stream of tasks for a given date, sorted by [sortOrder] then title.
final tasksForDateProvider =
    StreamProvider.family<List<Task>, DateTime>((ref, date) {
  return ref.watch(taskRepositoryProvider).watchTasksForDate(date);
});

/// Tracks which day-section is currently expanded (accordion, single-open).
final expandedDayProvider = StateProvider<DateTime?>((ref) {
  return ref.watch(todayProvider);
});