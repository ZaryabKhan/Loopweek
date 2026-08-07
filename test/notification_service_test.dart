// Pure-logic tests for NotificationService. The scheduling paths talk to the
// flutter_local_notifications platform channel and are exercised manually /
// in integration tests; here we pin down the deterministic helpers that both
// the save flow and the startup reconciler depend on.
import 'package:flutter/material.dart' show TimeOfDay;
import 'package:flutter_test/flutter_test.dart';

import 'package:loopweek/data/services/notification_service.dart';
import 'package:loopweek/domain/models/task.dart';

Task _task({
  required String id,
  required DateTime date,
  TimeOfDay? time,
  int reminderOffsetDays = 0,
}) {
  return Task(
    id: id,
    title: id,
    date: date,
    hasTime: time != null,
    time: time,
    hasReminder: true,
    reminderOffsetDays: reminderOffsetDays,
  );
}

void main() {
  group('notificationIdFor', () {
    test('always produces a non-negative 31-bit id', () {
      const ids = [
        '',
        'a',
        'task-1',
        'b7f1f7b0-2f3b-4f7d-9a1e-5c9d3f8a2e11',
        'zzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzz',
      ];
      for (final id in ids) {
        final n = NotificationService.notificationIdFor(id);
        expect(n, greaterThanOrEqualTo(0));
        expect(n, lessThanOrEqualTo(0x7FFFFFFF));
      }
    });

    test('is deterministic and sensitive to the task id', () {
      expect(
        NotificationService.notificationIdFor('task-1'),
        NotificationService.notificationIdFor('task-1'),
      );
      expect(
        NotificationService.notificationIdFor('task-1'),
        isNot(NotificationService.notificationIdFor('task-2')),
      );
    });

    test('matches pinned FNV-1a vectors so an SDK change cannot silently '
        're-map every pending reminder', () {
      // FNV-1a 32 offset basis, masked to 31 bits.
      expect(NotificationService.notificationIdFor(''), 0x011c9dc5);
      // Known FNV-1a 32 hash of 'a' is 0xe40c292c; masked -> 0x640c292c.
      expect(NotificationService.notificationIdFor('a'), 0x640c292c);
    });
  });

  group('fireDateTimeFor', () {
    test('uses the task time when one is set', () {
      final task = _task(
        id: 't',
        date: DateTime(2026, 8, 8),
        time: const TimeOfDay(hour: 14, minute: 30),
      );
      expect(
        NotificationService.fireDateTimeFor(task),
        DateTime(2026, 8, 8, 14, 30),
      );
    });

    test('falls back to 09:00 for time-less tasks', () {
      final task = _task(id: 't', date: DateTime(2026, 8, 8));
      expect(NotificationService.fireDateTimeFor(task), DateTime(2026, 8, 8, 9));
    });

    test('subtracts the persisted reminder offset', () {
      final task = _task(
        id: 't',
        date: DateTime(2026, 8, 8),
        time: const TimeOfDay(hour: 8, minute: 0),
        reminderOffsetDays: 1,
      );
      expect(
        NotificationService.fireDateTimeFor(task),
        DateTime(2026, 8, 7, 8),
      );
    });

    test('offset can move the fire time into the previous month', () {
      final task = _task(
        id: 't',
        date: DateTime(2026, 9, 1),
        reminderOffsetDays: 2,
      );
      expect(
        NotificationService.fireDateTimeFor(task),
        DateTime(2026, 8, 30, 9),
      );
    });
  });
}