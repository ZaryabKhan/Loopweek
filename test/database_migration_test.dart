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
}
