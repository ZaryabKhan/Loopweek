import 'package:loopweek/domain/models/recurrence.dart';
import 'package:loopweek/domain/models/task.dart';

/// Pure functions that generate occurrences for a recurring task rule.
///
/// Design (per spec): recurrences produce *independent* occurrences. Each
/// generated occurrence records the rule's id as its `recurrenceParentId` so
/// the user can stop future recurrence without affecting already-generated
/// history. Completing/deleting one occurrence never touches others.
class RecurrenceGenerator {
  /// Generate occurrence dates for [rule] within the window
  /// [startInclusive .. endInclusive], inclusive on both ends.
  ///
  /// Supported rules: daily, weekly and biweekly repeat on fixed day-steps
  /// from the anchor; monthly and yearly repeat on the anchor's day of month,
  /// clamped to the target month's length (Jan 31 -> Feb 28, Feb 29 -> Feb 28
  /// in common years). Only forward occurrences are considered (n >= 0). The
  /// anchor itself is included when [includeAnchor] is true and falls inside
  /// the window. Dates are returned as date-only `DateTime`s.
  static List<DateTime> occurrencesForWindow({
    required Task rule,
    required DateTime startInclusive,
    required DateTime endInclusive,
    bool includeAnchor = true,
  }) {
    final DateTime anchor = _dateOnly(rule.date);
    final DateTime windowStart = _dateOnly(startInclusive);
    final DateTime windowEnd = _dateOnly(endInclusive);

    if (windowStart.isAfter(windowEnd)) return const [];

    if (rule.recurrence == Recurrence.never) {
      if (!includeAnchor) return const [];
      return (anchor.isAfter(windowEnd) || anchor.isBefore(windowStart))
          ? const []
          : [anchor];
    }

    final int stepDays = switch (rule.recurrence) {
      Recurrence.daily => 1,
      Recurrence.weekly => 7,
      Recurrence.biweekly => 14,
      _ => 0,
    };

    if (stepDays > 0) {
      final int diffDays = windowStart.difference(anchor).inDays;

      // First index n >= 0 such that anchor + n*step >= windowStart.
      int n;
      if (diffDays <= 0) {
        n = 0;
      } else {
        n = (diffDays + stepDays - 1) ~/ stepDays; // ceil(diff / step)
        if (anchor.add(Duration(days: n * stepDays)).isBefore(windowStart)) {
          n += 1;
        }
      }

      final List<DateTime> result = [];
      DateTime cursor = anchor.add(Duration(days: n * stepDays));
      while (!cursor.isAfter(windowEnd)) {
        final isAnchor = cursor == anchor;
        if (!isAnchor || includeAnchor) {
          result.add(cursor);
        }
        cursor = cursor.add(Duration(days: stepDays));
      }
      return result;
    }

    // Monthly/yearly: walk occurrence index n = 0, 1, 2, ... from the anchor.
    // Clamping keeps candidates monotonic, but bail out if that ever breaks.
    final bool isMonthly = rule.recurrence == Recurrence.monthly;
    final List<DateTime> result = [];
    DateTime previous = anchor;
    for (int n = 0; n < 5000; n++) {
      final DateTime candidate = isMonthly
          ? _monthlyOccurrence(anchor, n)
          : _yearlyOccurrence(anchor, n);
      if (n > 0 && !candidate.isAfter(previous)) break;
      previous = candidate;
      if (candidate.isAfter(windowEnd)) break;
      if (candidate.isBefore(windowStart)) continue;
      final isAnchor = candidate == anchor;
      if (!isAnchor || includeAnchor) {
        result.add(candidate);
      }
    }
    return result;
  }

  /// True if [candidate] is a valid forward occurrence of [rule]
  /// (anchor itself counts only because it is one occurrence).
  static bool isValidOccurrenceOf(Task rule, DateTime candidate) {
    final DateTime a = _dateOnly(rule.date);
    final DateTime c = _dateOnly(candidate);
    if (a == c) return true;
    if (c.isBefore(a)) return false;
    switch (rule.recurrence) {
      case Recurrence.never:
        return false;
      case Recurrence.daily:
      case Recurrence.weekly:
      case Recurrence.biweekly:
        final int diff = c.difference(a).inDays;
        final int step = switch (rule.recurrence) {
          Recurrence.daily => 1,
          Recurrence.weekly => 7,
          Recurrence.biweekly => 14,
          _ => 0,
        };
        return diff % step == 0;
      case Recurrence.monthly:
        final int months = (c.year - a.year) * 12 + (c.month - a.month);
        return months > 0 && _monthlyOccurrence(a, months) == c;
      case Recurrence.yearly:
        final int years = c.year - a.year;
        return years > 0 && _yearlyOccurrence(a, years) == c;
    }
  }

  /// Occurrence [n] months after the [anchor], with the anchor's day clamped
  /// to the target month's length.
  static DateTime _monthlyOccurrence(DateTime anchor, int n) {
    final DateTime monthStart = DateTime(anchor.year, anchor.month + n, 1);
    return DateTime(
      monthStart.year,
      monthStart.month,
      _clampedDay(anchor.day, monthStart.year, monthStart.month),
    );
  }

  /// Occurrence [n] years after the [anchor], with the anchor's day clamped
  /// (Feb 29 -> Feb 28 in common years).
  static DateTime _yearlyOccurrence(DateTime anchor, int n) {
    final int year = anchor.year + n;
    return DateTime(
      year,
      anchor.month,
      _clampedDay(anchor.day, year, anchor.month),
    );
  }

  static int _daysInMonth(int year, int month) =>
      DateTime(year, month + 1, 0).day;

  static int _clampedDay(int day, int year, int month) {
    final int lastDay = _daysInMonth(year, month);
    return day < lastDay ? day : lastDay;
  }

  static DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);
}
