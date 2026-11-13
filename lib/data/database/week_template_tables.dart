import 'package:drift/drift.dart';

/// Drift tables for week templates — a saved snapshot of one week's tasks
/// that can later be seeded onto another week. Infrastructure-level: there is
/// no domain model for templates, the repository owns all access.
@DataClassName('WeekTemplateRow')
class WeekTemplates extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// One captured task of a template. [weekday] is the Dart weekday of the day
/// the task was captured from (Monday = 1 ... Sunday = 7), so applying the
/// template maps each item back onto the matching day of any target week.
@DataClassName('WeekTemplateItemRow')
class WeekTemplateItems extends Table {
  TextColumn get id => text()();
  TextColumn get templateId => text()();
  IntColumn get weekday => integer()();
  TextColumn get title => text()();
  BoolColumn get hasTime => boolean()();

  /// hour*60+minute of the captured time, or null for a time-less item.
  IntColumn get timeMinutes => integer().nullable()();
  IntColumn get sortOrder => integer()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
