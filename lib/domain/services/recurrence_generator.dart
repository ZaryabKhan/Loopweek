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
  /// Only forward occurrences are considered (anchor + n*step, n >= 0). The
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

    final int stepDays = rule.recurrence == Recurrence.daily ? 1 : 7;
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

  /// True if [candidate] is a valid forward occurrence of [rule]
  /// (anchor itself counts only because it is one occurrence).
  static bool isValidOccurrenceOf(Task rule, DateTime candidate) {
    final DateTime a = _dateOnly(rule.date);
    final DateTime c = _dateOnly(candidate);
    if (a == c) return true;
    if (c.isBefore(a)) return false;
    if (rule.recurrence == Recurrence.never) return false;
    final int diff = c.difference(a).inDays;
    final int step = rule.recurrence == Recurrence.daily ? 1 : 7;
    return diff % step == 0;
  }

  static DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);
}