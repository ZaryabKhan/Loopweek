import 'package:flutter/material.dart' show TimeOfDay;
import 'package:flutter_test/flutter_test.dart';
import 'package:loopweek/domain/models/recurrence.dart';
import 'package:loopweek/domain/models/task.dart';
import 'package:loopweek/domain/services/recurrence_generator.dart';

Task _rule({
  required DateTime date,
  Recurrence recurrence = Recurrence.never,
}) =>
    Task(
      id: 'rule',
      title: 'r',
      date: date,
      recurrence: recurrence,
    );

DateTime _d(int y, int m, int d) => DateTime(y, m, d);

void main() {
  group('RecurrenceGenerator.occurrencesForWindow', () {
    test('non-recurring returns the anchor alone when in window', () {
      final result = RecurrenceGenerator.occurrencesForWindow(
        rule: _rule(date: _d(2026, 8, 3)),
        startInclusive: _d(2026, 8, 1),
        endInclusive: _d(2026, 8, 7),
      );
      expect(result, [_d(2026, 8, 3)]);
    });

    test('non-recurring returns empty when anchor outside window', () {
      final result = RecurrenceGenerator.occurrencesForWindow(
        rule: _rule(date: _d(2026, 7, 1)),
        startInclusive: _d(2026, 8, 1),
        endInclusive: _d(2026, 8, 7),
      );
      expect(result, isEmpty);
    });

    test('non-recurring includesAnchor=false excludes the anchor', () {
      final result = RecurrenceGenerator.occurrencesForWindow(
        rule: _rule(date: _d(2026, 8, 3)),
        startInclusive: _d(2026, 8, 1),
        endInclusive: _d(2026, 8, 7),
        includeAnchor: false,
      );
      expect(result, isEmpty);
    });

    test('daily produces every day in window, no anchor in this test', () {
      final result = RecurrenceGenerator.occurrencesForWindow(
        rule: _rule(date: _d(2026, 8, 1), recurrence: Recurrence.daily),
        startInclusive: _d(2026, 8, 1),
        endInclusive: _d(2026, 8, 5),
        includeAnchor: false,
      );
      expect(result, [_d(2026, 8, 2), _d(2026, 8, 3), _d(2026, 8, 4), _d(2026, 8, 5)]);
    });

    test('daily includes anchor when includeAnchor=true', () {
      final result = RecurrenceGenerator.occurrencesForWindow(
        rule: _rule(date: _d(2026, 8, 1), recurrence: Recurrence.daily),
        startInclusive: _d(2026, 8, 1),
        endInclusive: _d(2026, 8, 5),
      );
      expect(result, [
        _d(2026, 8, 1), _d(2026, 8, 2), _d(2026, 8, 3),
        _d(2026, 8, 4), _d(2026, 8, 5),
      ]);
    });

    test('daily when window starts before anchor starts at anchor', () {
      final result = RecurrenceGenerator.occurrencesForWindow(
        rule: _rule(date: _d(2026, 8, 5), recurrence: Recurrence.daily),
        startInclusive: _d(2026, 8, 1),
        endInclusive: _d(2026, 8, 7),
        includeAnchor: false,
      );
      expect(result, [_d(2026, 8, 6), _d(2026, 8, 7)]);
    });

    test('daily when anchor is after window returns empty', () {
      final result = RecurrenceGenerator.occurrencesForWindow(
        rule: _rule(date: _d(2026, 12, 31), recurrence: Recurrence.daily),
        startInclusive: _d(2026, 8, 1),
        endInclusive: _d(2026, 8, 7),
      );
      expect(result, isEmpty);
    });

    test('weekly produces same weekday within window', () {
      // Anchor is a Sunday (Aug 2 2026 is a Sunday).
      final result = RecurrenceGenerator.occurrencesForWindow(
        rule: _rule(date: _d(2026, 8, 2), recurrence: Recurrence.weekly),
        startInclusive: _d(2026, 8, 1),
        endInclusive: _d(2026, 8, 31),
        includeAnchor: true,
      );
      expect(result, [
        _d(2026, 8, 2), _d(2026, 8, 9),
        _d(2026, 8, 16), _d(2026, 8, 23), _d(2026, 8, 30),
      ]);
    });

    test('weekly respects window boundaries', () {
      // Window starts mid-week, only occurrences >= start included.
      final result = RecurrenceGenerator.occurrencesForWindow(
        rule: _rule(date: _d(2026, 8, 2), recurrence: Recurrence.weekly),
        startInclusive: _d(2026, 8, 10),
        endInclusive: _d(2026, 8, 25),
      );
      expect(result, [_d(2026, 8, 16), _d(2026, 8, 23)]);
    });

    test('weekly months-spanning window', () {
      // Anchor Sun Aug 2; window Sun Aug 25 .. Mon Sep 15 includes Aug 30.
      final result = RecurrenceGenerator.occurrencesForWindow(
        rule: _rule(date: _d(2026, 8, 2), recurrence: Recurrence.weekly),
        startInclusive: _d(2026, 8, 25),
        endInclusive: _d(2026, 9, 15),
      );
      expect(result, [_d(2026, 8, 30), _d(2026, 9, 6), _d(2026, 9, 13)]);
    });

    test('empty when start is after end', () {
      final result = RecurrenceGenerator.occurrencesForWindow(
        rule: _rule(date: _d(2026, 8, 2), recurrence: Recurrence.daily),
        startInclusive: _d(2026, 8, 10),
        endInclusive: _d(2026, 8, 1),
      );
      expect(result, isEmpty);
    });

    test('daily emits aligned step when window start is not aligned', () {
      // Anchor Aug 1, window starts Aug 3: first occurrence is Aug 3 (diff=2
      // is a multiple of step=1). All days emitted.
      final result = RecurrenceGenerator.occurrencesForWindow(
        rule: _rule(date: _d(2026, 8, 1), recurrence: Recurrence.daily),
        startInclusive: _d(2026, 8, 3),
        endInclusive: _d(2026, 8, 5),
        includeAnchor: false,
      );
      expect(result, [_d(2026, 8, 3), _d(2026, 8, 4), _d(2026, 8, 5)]);
    });

    test('weekly only emits anchor-aligned dates when window starts mid-step', () {
      // Anchor Aug 2 (Sun), window starts Aug 5: first occurrence is Aug 9.
      final result = RecurrenceGenerator.occurrencesForWindow(
        rule: _rule(date: _d(2026, 8, 2), recurrence: Recurrence.weekly),
        startInclusive: _d(2026, 8, 5),
        endInclusive: _d(2026, 8, 20),
      );
      expect(result, [_d(2026, 8, 9), _d(2026, 8, 16)]);
    });

    test('weekly includes the anchor itself when inside window and requested', () {
      final result = RecurrenceGenerator.occurrencesForWindow(
        rule: _rule(date: _d(2026, 8, 2), recurrence: Recurrence.weekly),
        startInclusive: _d(2026, 8, 1),
        endInclusive: _d(2026, 8, 3),
        includeAnchor: true,
      );
      expect(result, [_d(2026, 8, 2)]);
    });
  });

  group('RecurrenceGenerator.isValidOccurrenceOf', () {
    final rule = _rule(date: _d(2026, 8, 2), recurrence: Recurrence.weekly);

    test('anchor is a valid occurrence', () {
      expect(RecurrenceGenerator.isValidOccurrenceOf(rule, _d(2026, 8, 2)), isTrue);
    });

    test('forward same weekday occurrences are valid', () {
      expect(RecurrenceGenerator.isValidOccurrenceOf(rule, _d(2026, 8, 9)), isTrue);
      expect(RecurrenceGenerator.isValidOccurrenceOf(rule, _d(2026, 9, 6)), isTrue);
    });

    test('forward different weekday is not valid', () {
      expect(RecurrenceGenerator.isValidOccurrenceOf(rule, _d(2026, 8, 3)), isFalse);
      expect(RecurrenceGenerator.isValidOccurrenceOf(rule, _d(2026, 8, 7)), isFalse);
    });

    test('past dates are never valid (other than the anchor itself)', () {
      expect(RecurrenceGenerator.isValidOccurrenceOf(rule, _d(2026, 7, 26)), isFalse);
    });

    test('non-recurring rule only accepts the anchor', () {
      final nr = _rule(date: _d(2026, 8, 2), recurrence: Recurrence.never);
      expect(RecurrenceGenerator.isValidOccurrenceOf(nr, _d(2026, 8, 2)), isTrue);
      expect(RecurrenceGenerator.isValidOccurrenceOf(nr, _d(2026, 8, 3)), isFalse);
    });
  });

  group('Task domain behaviour', () {
    test('weekly caption weekday index is Sunday-first', () {
      // DateTime.weekday: Sunday = 7. We want Sunday -> 0, Monday -> 1, etc.
      final sunday = Task(id: 'a', title: 't', date: _d(2026, 8, 2)); // Aug 2 2026 is Sunday
      expect(sunday.weekdayIndex, 0);
      final monday = Task(id: 'a', title: 't', date: _d(2026, 8, 3));
      expect(monday.weekdayIndex, 1);
      final saturday = Task(id: 'a', title: 't', date: _d(2026, 8, 8));
      expect(saturday.weekdayIndex, 6);
    });

    test('copyWith clears optional fields when requested', () {
      final t = Task(
        id: 'x', title: 't', date: _d(2026, 8, 2),
        time: const TimeOfDay(hour: 9, minute: 30),
        hasTime: true,
        recurrenceParentId: 'p',
      );
      final cleared = t.copyWith(clearTime: true, clearRecurrenceParent: true);
      expect(cleared.time, isNull);
      expect(cleared.recurrenceParentId, isNull);
    });
  });
}