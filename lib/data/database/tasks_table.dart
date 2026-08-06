import 'package:drift/drift.dart';

/// Drift table for tasks. One row per occurrence (recurring rules generate
/// independent rows linked back to the rule via [recurrenceParentId]).
///
/// The data class is named [TaskRow] (via `@DataClassName`) to avoid a name
/// clash with the [Task] domain model in `domain/models/task.dart`.
@DataClassName('TaskRow')
class Tasks extends Table {
  TextColumn get id => text()();
  TextColumn get title => text()();
  DateTimeColumn get date => dateTime()();
  BoolColumn get isCompleted => boolean().withDefault(const Constant(false))();
  TextColumn get colorTag => text().withDefault(const Constant('orange'))();
  BoolColumn get hasTime => boolean().withDefault(const Constant(false))();
  IntColumn get timeMinutes => integer().nullable()();
  BoolColumn get hasReminder => boolean().withDefault(const Constant(false))();
  TextColumn get recurrence => text().withDefault(const Constant('never'))();
  TextColumn get recurrenceParentId => text().nullable()();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
