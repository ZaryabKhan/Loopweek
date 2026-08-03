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
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        beforeOpen: (details) async {
          await customStatement(
              'CREATE INDEX IF NOT EXISTS tasks_date_idx ON tasks(date);');
          await customStatement(
              'CREATE INDEX IF NOT EXISTS tasks_parent_idx ON tasks(recurrence_parent_id);');
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