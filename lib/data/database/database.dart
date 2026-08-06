import 'dart:io';

import 'package:drift/native.dart';
import 'package:drift/drift.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'package:loopweek/data/database/tasks_table.dart';

part 'database.g.dart';

@DriftDatabase(tables: [Tasks])
class LoopweekDatabase extends _$LoopweekDatabase {
  LoopweekDatabase() : super(_open());

  LoopweekDatabase.forTesting(super.e);

  @override
  int get schemaVersion => 2;

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
