import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:loopweek/data/database/database.dart';
import 'package:loopweek/data/repositories/task_repository.dart';
import 'package:loopweek/domain/models/color_tag.dart';
import 'package:loopweek/domain/models/recurrence.dart';
import 'package:loopweek/domain/models/task.dart';

DateTime _d(int y, int m, int d) => DateTime(y, m, d);

String _dateKey(DateTime d) => '${d.year}-${d.month}-${d.day}';

Task _task(String id, DateTime date, {bool completed = false}) =>
    Task(id: id, title: id, date: date, isCompleted: completed);

void main() {
  late LoopweekDatabase db;
  late TaskRepository repo;

  setUp(() {
    db = LoopweekDatabase.forTesting(NativeDatabase.memory());
    repo = TaskRepository(db);
  });

  tearDown(() async {
    await db.close();
  });

  group('watchTasksForDate', () {
    test('task at exact midnight appears only on its own day', () async {
      // Aug 8 2026 is a Saturday; a time-less task is stored at Sat 00:00:00.
      await repo.insertTask(_task('sat', _d(2026, 8, 8)));

      final friday = await repo.watchTasksForDate(_d(2026, 8, 7)).first;
      final saturday = await repo.watchTasksForDate(_d(2026, 8, 8)).first;

      expect(friday.map((t) => t.id), isNot(contains('sat')));
      expect(saturday.map((t) => t.id), contains('sat'));
    });

    test('task on Friday does not leak into Saturday', () async {
      await repo.insertTask(_task('fri', _d(2026, 8, 7)));

      final friday = await repo.watchTasksForDate(_d(2026, 8, 7)).first;
      final saturday = await repo.watchTasksForDate(_d(2026, 8, 8)).first;

      expect(friday.map((t) => t.id), contains('fri'));
      expect(saturday.map((t) => t.id), isNot(contains('fri')));
    });

    test('task with a time still stays on its own day', () async {
      // 23:59 on Saturday must still resolve to Saturday, not bleed into
      // Sunday (or back into Friday) under any timezone conversion.
      final t = _task('sat', DateTime(2026, 8, 8, 23, 59));
      await repo.insertTask(t);

      final friday = await repo.watchTasksForDate(_d(2026, 8, 7)).first;
      final saturday = await repo.watchTasksForDate(_d(2026, 8, 8)).first;
      final sunday = await repo.watchTasksForDate(_d(2026, 8, 9)).first;

      expect(friday, isEmpty);
      expect(saturday.map((t) => t.id), contains('sat'));
      expect(sunday, isEmpty);
    });

    test('re-emits when a task is inserted (reactive stream)', () async {
      final stream = repo.watchTasksForDate(_d(2026, 8, 8));
      final emissions = <List<Task>>[];
      final sub = stream.listen(emissions.add);

      // Drain the initial emission.
      await Future<void>.delayed(Duration.zero);
      expect(emissions, isNotEmpty);
      expect(emissions.first, isEmpty);

      await repo.insertTask(_task('sat', _d(2026, 8, 8)));
      await Future<void>.delayed(Duration.zero);

      expect(emissions.last.map((t) => t.id), contains('sat'));

      await sub.cancel();
    });
  });

  group('setCompleted', () {
    test('marks an existing task completed', () async {
      await repo.insertTask(_task('a', _d(2026, 8, 8)));
      await repo.setCompleted(id: 'a', completed: true);

      expect((await repo.getTask('a'))?.isCompleted, isTrue);
    });

    test('marks a completed task not completed again', () async {
      await repo.insertTask(_task('a', _d(2026, 8, 8), completed: true));
      await repo.setCompleted(id: 'a', completed: false);

      expect((await repo.getTask('a'))?.isCompleted, isFalse);
    });

    test('is a no-op on a missing id (does not throw)', () async {
      await expectLater(
        repo.setCompleted(id: 'ghost', completed: true),
        completes,
      );
    });

    test('completing one occurrence does not affect siblings', () async {
      final rule = Task(
        id: 'rule',
        title: 'r',
        date: _d(2026, 8, 1),
        recurrence: Recurrence.daily,
      );
      await repo.insertTask(rule);
      final created = await repo.materializeOccurrences(
        rule: rule,
        start: _d(2026, 8, 1),
        end: _d(2026, 8, 3),
      );
      expect(created.length, 2);

      await repo.setCompleted(id: created.first.id, completed: true);

      final first = await repo.getTask(created.first.id);
      final second = await repo.getTask(created.last.id);
      expect(first?.isCompleted, isTrue);
      expect(second?.isCompleted, isFalse);
    });
  });

  group('reorderTasksForDate', () {
    test('persists new sort order for all tasks on the date', () async {
      await repo.insertTask(_task('a', _d(2026, 8, 8)));
      await repo.insertTask(_task('b', _d(2026, 8, 8)));
      await repo.insertTask(_task('c', _d(2026, 8, 8)));

      await repo.reorderTasksForDate(
        date: _d(2026, 8, 8),
        orderedIds: ['c', 'a', 'b'],
      );

      final tasks = await repo.watchTasksForDate(_d(2026, 8, 8)).first;
      expect(tasks.map((t) => t.id), ['c', 'a', 'b']);
    });

    test('does not touch tasks on other dates', () async {
      await repo.insertTask(_task('x', _d(2026, 8, 7)));
      await repo.insertTask(_task('y', _d(2026, 8, 8)));

      await repo.reorderTasksForDate(date: _d(2026, 8, 8), orderedIds: ['y']);

      final friday = await repo.watchTasksForDate(_d(2026, 8, 7)).first;
      expect(friday.single.id, 'x');
    });

    test('empty list is a no-op', () async {
      await repo.insertTask(_task('a', _d(2026, 8, 8)));
      await repo.reorderTasksForDate(
        date: _d(2026, 8, 8),
        orderedIds: const [],
      );

      final tasks = await repo.watchTasksForDate(_d(2026, 8, 8)).first;
      expect(tasks.single.id, 'a');
    });

    test('partial order fully applied or rolled back (atomicity)', () async {
      await repo.insertTask(_task('a', _d(2026, 8, 8)));
      await repo.insertTask(_task('b', _d(2026, 8, 8)));

      // 'ghost' does not exist; the update for it is a 0-row no-op, but the
      // batch still commits the valid rows atomically.
      await repo.reorderTasksForDate(
        date: _d(2026, 8, 8),
        orderedIds: ['b', 'ghost', 'a'],
      );

      final tasks = await repo.watchTasksForDate(_d(2026, 8, 8)).first;
      expect(tasks.map((t) => t.id), ['b', 'a']);
    });
  });

  group('materializeOccurrences', () {
    test('non-recurring rule materializes nothing', () async {
      final rule = _task('rule', _d(2026, 8, 1));
      final created = await repo.materializeOccurrences(
        rule: rule,
        start: _d(2026, 8, 1),
        end: _d(2026, 8, 7),
      );
      expect(created, isEmpty);
    });

    test(
      'daily rule materializes occurrences for the window (excl anchor)',
      () async {
        final rule = Task(
          id: 'rule',
          title: 'r',
          date: _d(2026, 8, 1),
          recurrence: Recurrence.daily,
        );
        final created = await repo.materializeOccurrences(
          rule: rule,
          start: _d(2026, 8, 1),
          end: _d(2026, 8, 4),
        );
        expect(created.map((t) => t.date), [
          _d(2026, 8, 2),
          _d(2026, 8, 3),
          _d(2026, 8, 4),
        ]);
      },
    );

    test('occurrences are linked to the rule and non-recurring', () async {
      final rule = Task(
        id: 'rule',
        title: 'r',
        date: _d(2026, 8, 1),
        recurrence: Recurrence.weekly,
      );
      final created = await repo.materializeOccurrences(
        rule: rule,
        start: _d(2026, 8, 1),
        end: _d(2026, 8, 15),
      );
      expect(created, isNotEmpty);
      for (final t in created) {
        expect(t.recurrenceParentId, 'rule');
        expect(t.recurrence, Recurrence.never);
        expect(t.isCompleted, isFalse);
      }
    });

    test('idempotent: rematerializing the same window adds no rows', () async {
      final rule = Task(
        id: 'rule',
        title: 'r',
        date: _d(2026, 8, 1),
        recurrence: Recurrence.weekly,
      );
      final first = await repo.materializeOccurrences(
        rule: rule,
        start: _d(2026, 8, 1),
        end: _d(2026, 8, 31),
      );
      final second = await repo.materializeOccurrences(
        rule: rule,
        start: _d(2026, 8, 1),
        end: _d(2026, 8, 31),
      );

      expect(first, isNotEmpty);
      expect(second, isEmpty);

      final all = await repo.getOccurrencesOf('rule');
      final dateKeys = all.map((t) => _dateKey(t.date)).toSet();
      expect(all.length, dateKeys.length);
      expect(first.length, all.length);
    });

    test(
      'concurrent materialization of the same rule does not duplicate',
      () async {
        final rule = Task(
          id: 'rule',
          title: 'r',
          date: _d(2026, 8, 1),
          recurrence: Recurrence.daily,
        );
        await Future.wait([
          repo.materializeOccurrences(
            rule: rule,
            start: _d(2026, 8, 1),
            end: _d(2026, 8, 5),
          ),
          repo.materializeOccurrences(
            rule: rule,
            start: _d(2026, 8, 1),
            end: _d(2026, 8, 5),
          ),
        ]);

        final all = await repo.getOccurrencesOf('rule');
        final dateKeys = all.map((t) => _dateKey(t.date)).toSet();
        expect(all.length, dateKeys.length);
        expect(dateKeys, {
          _dateKey(_d(2026, 8, 2)),
          _dateKey(_d(2026, 8, 3)),
          _dateKey(_d(2026, 8, 4)),
          _dateKey(_d(2026, 8, 5)),
        });
      },
    );

    test(
      'extending the window later materializes only the new dates',
      () async {
        final rule = Task(
          id: 'rule',
          title: 'r',
          date: _d(2026, 8, 1),
          recurrence: Recurrence.weekly,
        );
        await repo.materializeOccurrences(
          rule: rule,
          start: _d(2026, 8, 1),
          end: _d(2026, 8, 15),
        );
        final more = await repo.materializeOccurrences(
          rule: rule,
          start: _d(2026, 8, 1),
          end: _d(2026, 8, 31),
        );

        expect(more.map((t) => t.date), [_d(2026, 8, 22), _d(2026, 8, 29)]);
      },
    );
  });

  group('syncFutureOccurrences', () {
    test(
      'propagates title/color/reminder changes to future occurrences',
      () async {
        final rule = Task(
          id: 'rule',
          title: 'Old title',
          date: _d(2026, 8, 1),
          recurrence: Recurrence.weekly,
          hasReminder: false,
          colorTag: ColorTag.orange,
        );
        await repo.insertTask(rule);
        await repo.materializeOccurrences(
          rule: rule,
          start: _d(2026, 8, 1),
          end: _d(2026, 8, 31),
        );

        final updated = rule.copyWith(
          title: 'New title',
          colorTag: ColorTag.blue,
          hasReminder: true,
        );
        await repo.syncFutureOccurrences(rule: updated, today: _d(2026, 8, 1));

        final occurrences = await repo.getOccurrencesOf('rule');
        expect(occurrences, isNotEmpty);
        for (final o in occurrences) {
          expect(o.title, 'New title');
          expect(o.colorTag, ColorTag.blue);
          expect(o.hasReminder, isTrue);
        }
      },
    );

    test('deletes future occurrences when recurrence is turned off', () async {
      final rule = Task(
        id: 'rule',
        title: 'r',
        date: _d(2026, 8, 1),
        recurrence: Recurrence.weekly,
      );
      await repo.insertTask(rule);
      await repo.materializeOccurrences(
        rule: rule,
        start: _d(2026, 8, 1),
        end: _d(2026, 8, 31),
      );

      final stopped = rule.copyWith(recurrence: Recurrence.never);
      await repo.updateTask(stopped);
      await repo.syncFutureOccurrences(rule: stopped, today: _d(2026, 8, 8));

      final occurrences = await repo.getOccurrencesOf('rule');
      expect(occurrences, isEmpty);

      // The anchor rule row still exists.
      expect((await repo.getTask('rule'))?.recurrence, Recurrence.never);
    });
    test('keeps past occurrences as history when rule changes',
        () async {
      final rule = Task(
        id: 'rule',
        title: 'r',
        date: _d(2026, 8, 1),
        recurrence: Recurrence.weekly,
      );
      await repo.insertTask(rule);
      await repo.materializeOccurrences(
        rule: rule,
        start: _d(2026, 8, 1),
        end: _d(2026, 8, 31),
      );

      // Move the rule to a different weekday. Aug 8 is now "past" and should
      // stay as history; Aug 15/22/29 no longer match and are replaced by
      // Wednesday dates.
      final moved = rule.copyWith(date: _d(2026, 8, 5));
      await repo.syncFutureOccurrences(rule: moved, today: _d(2026, 8, 15));

      final occurrences = await repo.getOccurrencesOf('rule');
      final dates = occurrences.map((t) => t.date).toSet();
      expect(dates, contains(_d(2026, 8, 8))); // past, preserved
      expect(dates, isNot(contains(_d(2026, 8, 15)))); // old future, removed
      expect(dates, contains(_d(2026, 8, 19))); // new future, created
    });

    test('removes dates that no longer match the changed pattern', () async {
      final rule = Task(
        id: 'rule',
        title: 'r',
        date: _d(2026, 8, 1),
        recurrence: Recurrence.daily,
      );
      await repo.insertTask(rule);
      await repo.materializeOccurrences(
        rule: rule,
        start: _d(2026, 8, 1),
        end: _d(2026, 8, 10),
      );

      final weekly = rule.copyWith(recurrence: Recurrence.weekly);
      await repo.syncFutureOccurrences(rule: weekly, today: _d(2026, 8, 1));

      final occurrences = await repo.getOccurrencesOf('rule');
      final dates = occurrences.map((t) => t.date).toSet();
      // Only weekly dates (Aug 8, 15, 22...) remain from the future window.
      expect(dates, isNot(contains(_d(2026, 8, 2))));
      expect(dates, isNot(contains(_d(2026, 8, 9))));
      expect(dates, contains(_d(2026, 8, 8)));
      expect(dates, contains(_d(2026, 8, 15)));
    });
  });
}
