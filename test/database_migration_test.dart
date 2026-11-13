import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:loopweek/data/database/database.dart';
import 'package:loopweek/data/repositories/task_repository.dart';
import 'package:loopweek/data/repositories/week_template_repository.dart';
import 'package:loopweek/domain/models/task.dart';

DateTime _d(int y, int m, int d) => DateTime(y, m, d);

Task _task(String id, DateTime date) => Task(id: id, title: id, date: date);

/// The schema as a v4 install has it: only the tasks table plus its
/// indexes. v5 adds the week template tables without touching tasks, so the
/// v4 layout already is the current one (is_someday arrived in v4). The DDL
/// mirrors the conventions of the v5 statements in database.dart, which in
/// turn mirror drift_dev's generated layout.
const List<String> _v4Schema = [
  'CREATE TABLE IF NOT EXISTS "tasks" ('
      '"id" TEXT NOT NULL, '
      '"title" TEXT NOT NULL, '
      '"date" INTEGER NOT NULL, '
      '"is_completed" INTEGER NOT NULL DEFAULT 0 '
      'CHECK ("is_completed" IN (0, 1)), '
      '"color_tag" TEXT NOT NULL DEFAULT \'orange\', '
      '"has_time" INTEGER NOT NULL DEFAULT 0 CHECK ("has_time" IN (0, 1)), '
      '"time_minutes" INTEGER NULL, '
      '"has_reminder" INTEGER NOT NULL DEFAULT 0 '
      'CHECK ("has_reminder" IN (0, 1)), '
      '"reminder_offset_days" INTEGER NOT NULL DEFAULT 0, '
      '"recurrence" TEXT NOT NULL DEFAULT \'never\', '
      '"recurrence_parent_id" TEXT NULL, '
      '"sort_order" INTEGER NOT NULL DEFAULT 0, '
      '"is_someday" INTEGER NOT NULL DEFAULT 0 '
      'CHECK ("is_someday" IN (0, 1)), '
      'PRIMARY KEY ("id"));',
  'CREATE INDEX IF NOT EXISTS tasks_date_idx ON tasks(date);',
  'CREATE INDEX IF NOT EXISTS tasks_parent_idx '
      'ON tasks(recurrence_parent_id);',
  'CREATE UNIQUE INDEX IF NOT EXISTS tasks_parent_date_uniq '
      'ON tasks(recurrence_parent_id, date) '
      'WHERE recurrence_parent_id IS NOT NULL;',
];

/// Opens the database on an in-memory connection pre-seeded with the v4
/// schema and user_version = 4. The setup callback runs when drift opens
/// the underlying sqlite connection, before drift reads user_version, so
/// the first query on the returned database runs the hand-written
/// v4 -> v5 upgrade — same as an app updated from v4.
LoopweekDatabase _v4Database() {
  return LoopweekDatabase.forTesting(NativeDatabase.memory(setup: (rawDb) {
    for (final statement in _v4Schema) {
      rawDb.execute(statement);
    }
    final epochSeconds = _d(2026, 8, 8).millisecondsSinceEpoch ~/ 1000;
    rawDb.execute(
      "INSERT INTO tasks (id, title, date) VALUES ('pre', 'pre', $epochSeconds);",
    );
    rawDb.execute('PRAGMA user_version = 4;');
  }));
}

void main() {
  group('migration v4 -> v5', () {
    late LoopweekDatabase db;

    setUp(() {
      db = _v4Database();
    });

    tearDown(() async {
      await db.close();
    });

    test('creates the week template tables and bumps user_version to 5',
        () async {
      final tables = await db
          .customSelect(
            "SELECT name FROM sqlite_master WHERE type = 'table' "
            "AND name IN ('week_templates', 'week_template_items');",
          )
          .get();
      expect(
        tables.map((row) => row.data['name']),
        unorderedEquals(['week_templates', 'week_template_items']),
      );

      final version =
          await db.customSelect('PRAGMA user_version;').getSingle();
      expect(version.data['user_version'], 5);
    });

    test('migrated schema matches a fresh install column-for-column',
        () async {
      // Opening runs the migration; any query suffices.
      await db.select(db.tasks).get();

      Future<Map<String, List<Map<String, Object?>>>> structure(
        LoopweekDatabase database,
      ) async {
        final out = <String, List<Map<String, Object?>>>{};
        for (final table in database.allTables) {
          final name = table.actualTableName;
          out[name] = await database
              .customSelect('PRAGMA table_info($name);')
              .get()
              .then((rows) => rows.map((r) => r.data).toList());
        }
        return out;
      }

      final migrated = await structure(db);
      final fresh = await structure(LoopweekDatabase.forTesting(
        NativeDatabase.memory(),
      ));
      expect(migrated.keys, unorderedEquals(fresh.keys));
      for (final table in fresh.keys) {
        expect(
          migrated[table],
          fresh[table],
          reason: 'table $table must match a fresh install exactly '
              '(name, type, notnull, default, pk)',
        );
      }
    });

    test('keeps v4 rows and makes the new tables usable', () async {
      final tasks = TaskRepository(db);
      final templates = WeekTemplateRepository(db, tasks);

      // The task written before the upgrade survives the migration.
      final kept = await tasks.getTask('pre');
      expect(kept?.title, 'pre');
      expect(kept?.date, _d(2026, 8, 8));

      // Aug 3 - 9 2026 is a Monday - Sunday week.
      final week = List.generate(7, (i) => _d(2026, 8, 3 + i));
      await tasks.insertTask(_task('monday', _d(2026, 8, 3)));
      // The pre-existing v4 row (Aug 8) is in the same week, so both rows
      // are captured.
      final captured = await templates.saveFromWeek('my week', week);
      expect(captured, 2);

      final summaries = await templates.watchTemplates().first;
      expect(summaries.single.name, 'my week');
      expect(summaries.single.itemCount, 2);

      final items = await db.select(db.weekTemplateItems).get();
      expect(items, hasLength(2));
      final monday = items.singleWhere((i) => i.title == 'monday');
      expect(monday.templateId, summaries.single.id);
      expect(monday.weekday, 1);
      expect(monday.hasTime, isFalse);
      expect(monday.timeMinutes, isNull);
      final saturday = items.singleWhere((i) => i.title == 'pre');
      expect(saturday.weekday, 6); // Aug 8 2026 is a Saturday (Mon=1..Sun=7).
    });
  });
  group('migration v3 -> v5 (release 1.0.3 update path)', () {
    late LoopweekDatabase db;

    setUp(() {
      db = _v3Database();
    });

    tearDown(() async {
      await db.close();
    });

    test('v3 rows survive the upgrade and stay visible to week queries',
        () async {
      // Opening runs the v3 -> v5 upgrade (is_someday + template tables).
      final repo = TaskRepository(db);
      final today = _d(2026, 8, 8);

      final all = await repo.getAllTasks();
      expect(all, hasLength(2));
      expect(all.map((t) => t.id), containsAll(['keep1', 'keep2']));

      // is_someday must default to 0 so upgraded rows are NOT filtered out
      // of the week view / widget / archive queries.
      final todayTasks = await repo.watchTasksForDate(today).first;
      expect(todayTasks.map((t) => t.id), contains('keep1'));
      expect(todayTasks.every((t) => t.isSomeday == false), isTrue);

      final yesterdayTasks = await repo.watchTasksForDate(_d(2026, 8, 7)).first;
      expect(yesterdayTasks.map((t) => t.id), contains('keep2'));

      final version =
          await db.customSelect('PRAGMA user_version;').getSingle();
      expect(version.data['user_version'], 5);
    });
  });
}

/// The schema as a v3 install (release 1.0.3) has it: no is_someday column
/// and no week template tables yet.
const List<String> _v3Schema = [
  'CREATE TABLE IF NOT EXISTS "tasks" ('
      '"id" TEXT NOT NULL, '
      '"title" TEXT NOT NULL, '
      '"date" INTEGER NOT NULL, '
      '"is_completed" INTEGER NOT NULL DEFAULT 0 '
      'CHECK ("is_completed" IN (0, 1)), '
      '"color_tag" TEXT NOT NULL DEFAULT \'orange\', '
      '"has_time" INTEGER NOT NULL DEFAULT 0 CHECK ("has_time" IN (0, 1)), '
      '"time_minutes" INTEGER NULL, '
      '"has_reminder" INTEGER NOT NULL DEFAULT 0 '
      'CHECK ("has_reminder" IN (0, 1)), '
      '"reminder_offset_days" INTEGER NOT NULL DEFAULT 0, '
      '"recurrence" TEXT NOT NULL DEFAULT \'never\', '
      '"recurrence_parent_id" TEXT NULL, '
      '"sort_order" INTEGER NOT NULL DEFAULT 0, '
      'PRIMARY KEY ("id"));',
  'CREATE INDEX IF NOT EXISTS tasks_date_idx ON tasks(date);',
  'CREATE INDEX IF NOT EXISTS tasks_parent_idx '
      'ON tasks(recurrence_parent_id);',
  'CREATE UNIQUE INDEX IF NOT EXISTS tasks_parent_date_uniq '
      'ON tasks(recurrence_parent_id, date) '
      'WHERE recurrence_parent_id IS NOT NULL;',
];

LoopweekDatabase _v3Database() {
  return LoopweekDatabase.forTesting(NativeDatabase.memory(setup: (rawDb) {
    for (final statement in _v3Schema) {
      rawDb.execute(statement);
    }
    // Two rows a 1.0.3 user would have: one for 'today' (2026-08-08 in this
    // fixture), one completed yesterday.
    rawDb.execute(
      "INSERT INTO tasks (id, title, date, is_completed) VALUES"
      " ('keep1', 'Water the plants', ${_d(2026, 8, 8).millisecondsSinceEpoch ~/ 1000}, 0),"
      " ('keep2', 'Laundry', ${_d(2026, 8, 7).millisecondsSinceEpoch ~/ 1000}, 1);",
    );
    rawDb.execute('PRAGMA user_version = 3;');
  }));
}