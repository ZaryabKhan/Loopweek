import 'dart:io';

import 'package:drift/native.dart';
import 'package:drift/drift.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'package:loopweek/data/database/tasks_table.dart';
import 'package:loopweek/data/database/week_template_tables.dart';

part 'database.g.dart';

@DriftDatabase(tables: [Tasks, WeekTemplates, WeekTemplateItems])
class LoopweekDatabase extends _$LoopweekDatabase {
  LoopweekDatabase() : super(_open());

  LoopweekDatabase.forTesting(super.e);

  @override
  int get schemaVersion => 5;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onUpgrade: (m, from, to) async {
      if (from < 2) {
        // Before enforcing uniqueness for occurrence identity
        // (recurrence_parent_id, date), drop any duplicate occurrences
        // that the pre-transactional materialization may have written.
        // Keep one row per (parent, date) group (smallest id wins) and
        // delete the rest.
        await customStatement(
          'DELETE FROM tasks WHERE recurrence_parent_id IS NOT NULL '
          'AND id NOT IN ('
          '  SELECT MIN(id) FROM tasks '
          '  WHERE recurrence_parent_id IS NOT NULL '
          '  GROUP BY recurrence_parent_id, date'
          ');',
        );
      }
      if (from < 3) {
        // Added reminder_offset_days to persist the reminder lead time.
        await customStatement(
          'ALTER TABLE tasks ADD COLUMN reminder_offset_days INTEGER NOT NULL DEFAULT 0;',
        );
      }
      if (from < 4) {
        // Added is_someday for the Someday parking lot.
        await customStatement(
          'ALTER TABLE tasks ADD COLUMN is_someday INTEGER NOT NULL DEFAULT 0;',
        );
      }
      if (from < 5) {
        // Added week templates: week_templates holds the saved snapshot,
        // week_template_items its captured per-weekday tasks. The CREATE
        // statements mirror drift_dev's generated layout exactly so a
        // migrated database matches a fresh install.
        await customStatement(
          'CREATE TABLE IF NOT EXISTS "week_templates" ("id" TEXT NOT NULL, "name" TEXT NOT NULL, "created_at" INTEGER NOT NULL, PRIMARY KEY ("id"));',
        );
        await customStatement(
          'CREATE TABLE IF NOT EXISTS "week_template_items" ("id" TEXT NOT NULL, "template_id" TEXT NOT NULL, "weekday" INTEGER NOT NULL, "title" TEXT NOT NULL, "has_time" INTEGER NOT NULL CHECK ("has_time" IN (0, 1)), "time_minutes" INTEGER NULL, "sort_order" INTEGER NOT NULL, PRIMARY KEY ("id"));',
        );
      }
    },
    beforeOpen: (details) async {
      await customStatement(
        'CREATE INDEX IF NOT EXISTS tasks_date_idx ON tasks(date);',
      );
      await customStatement(
        'CREATE INDEX IF NOT EXISTS tasks_parent_idx ON tasks(recurrence_parent_id);',
      );
      // Enforce occurrence identity at the storage layer: a recurring
      // rule may have at most one materialized occurrence per date.
      await customStatement(
        'CREATE UNIQUE INDEX IF NOT EXISTS tasks_parent_date_uniq '
        'ON tasks(recurrence_parent_id, date) '
        'WHERE recurrence_parent_id IS NOT NULL;',
      );
    },
  );
}

LazyDatabase _open() {
  return LazyDatabase(() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File(p.join(dir.path, 'loopweek.db'));
    return NativeDatabase.createInBackground(file);
  });
}
