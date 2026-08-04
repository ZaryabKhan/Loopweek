import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import 'package:loopweek/data/database/database.dart';
import 'package:loopweek/data/database/task_mapper.dart';
import 'package:loopweek/domain/models/recurrence.dart';
import 'package:loopweek/domain/models/task.dart';
import 'package:loopweek/domain/services/recurrence_generator.dart';

/// Single source of truth for task persistence + recurrence materialization.
class TaskRepository {
  TaskRepository(this._db, {Uuid? uuid}) : _uuid = uuid ?? const Uuid();

  final LoopweekDatabase _db;
  final Uuid _uuid;
  static const TaskMapper _mapper = TaskMapper();

  // ---- read ---------------------------------------------------------------

  Stream<List<Task>> watchTasksForDate(DateTime date) {
    final start = DateTime(date.year, date.month, date.day);
    final end = start.add(const Duration(days: 1));
    final query = _db.select(_db.tasks)
      ..where((t) => t.date.isBetweenValues(start, end))
      ..orderBy([
        (t) => OrderingTerm.asc(t.sortOrder),
        (t) => OrderingTerm.asc(t.title),
      ]);
    return query.map(_mapper.toDomain).watch();
  }

  Stream<Task?> watchTask(String id) {
    final query = _db.select(_db.tasks)..where((t) => t.id.equals(id));
    return query.map(_mapper.toDomain).watchSingleOrNull();
  }

  /// Live count of all tasks, used by the week view to tell a fresh install
  /// (show the first-task orientation) apart from a populated week.
  Stream<int> watchTaskCount() {
    return _db.select(_db.tasks).watch().map((rows) => rows.length);
  }

  Future<Task?> getTask(String id) async {
    final query = _db.select(_db.tasks)..where((t) => t.id.equals(id));
    final row = await query.getSingleOrNull();
    return row == null ? null : _mapper.toDomain(row);
  }

  /// All materialized occurrences linked back to the rule with [parentId].
  Future<List<Task>> getOccurrencesOf(String parentId) async {
    final rows = await (_db.select(
      _db.tasks,
    )..where((t) => t.recurrenceParentId.equals(parentId))).get();
    return rows.map(_mapper.toDomain).toList();
  }

  // ---- write --------------------------------------------------------------

  Future<Task> insertTask(Task task) async {
    final withId = task.id.isEmpty ? task.copyWith(id: _uuid.v4()) : task;
    await _db
        .into(_db.tasks)
        .insertOnConflictUpdate(_mapper.toCompanion(withId));
    return withId;
  }

  Future<void> updateTask(Task task) async {
    await _db.into(_db.tasks).insertOnConflictUpdate(_mapper.toCompanion(task));
  }

  Future<void> deleteTask(String id) async {
    await (_db.delete(_db.tasks)..where((t) => t.id.equals(id))).go();
  }

  Future<void> setCompleted({
    required String id,
    required bool completed,
  }) async {
    await (_db.update(_db.tasks)..where((t) => t.id.equals(id))).write(
      TasksCompanion(isCompleted: Value(completed)),
    );
  }

  Future<void> clearAllTasks() async {
    await _db.batch((batch) {
      batch.deleteAll(_db.tasks);
    });
  }

  Future<void> insertTaskBatch(List<Task> tasks) async {
    await _db.batch((batch) {
      for (final task in tasks) {
        final withId = task.id.isEmpty ? task.copyWith(id: _uuid.v4()) : task;
        batch.insert(
          _db.tasks,
          _mapper.toCompanion(withId),
          mode: InsertMode.insertOrReplace,
        );
      }
    });
  }

  Future<void> reorderTasksForDate({
    required DateTime date,
    required List<String> orderedIds,
  }) async {
    for (var i = 0; i < orderedIds.length; i++) {
      await (_db.update(_db.tasks)..where((t) => t.id.equals(orderedIds[i])))
          .write(TasksCompanion(sortOrder: Value(i)));
    }
  }

  // ---- recurrence ---------------------------------------------------------

  /// Materialize occurrences of [rule] for the window [start..end] (inclusive)
  /// by inserting independent rows linked back to [rule.id]. Existing
  /// occurrences (same rule id + same date) are skipped.
  Future<List<Task>> materializeOccurrences({
    required Task rule,
    required DateTime start,
    required DateTime end,
  }) async {
    if (!rule.recurrence.isRecurring) return const [];

    final dates = RecurrenceGenerator.occurrencesForWindow(
      rule: rule,
      startInclusive: start,
      endInclusive: end,
      includeAnchor: false,
    );

    if (dates.isEmpty) return const [];

    // Skip dates that already have an occurrence for this rule.
    final existing = await (_db.select(
      _db.tasks,
    )..where((t) => t.recurrenceParentId.equals(rule.id))).get();
    final existingDates = existing.map((e) => e.date).toSet();

    final created = <Task>[];
    for (final d in dates) {
      if (existingDates.any(
        (e) => e.year == d.year && e.month == d.month && e.day == d.day,
      )) {
        continue;
      }
      final occurrence = rule.copyWith(
        id: _uuid.v4(),
        date: d,
        isCompleted: false,
        recurrenceParentId: rule.id,
        recurrence: Recurrence.never,
        sortOrder: rule.sortOrder,
      );
      await _db.into(_db.tasks).insert(_mapper.toCompanion(occurrence));
      created.add(occurrence);
    }
    return created;
  }

  /// Stop future recurrence of the rule with [parentId] without touching
  /// generated history. Concretely: splits the source rule into a non-recurring
  /// anchor row going forward, by marking its recurrence as [Recurrence.never].
  Future<void> stopRecurrenceAfter(
    String parentId, {
    required DateTime todayDate,
  }) async {
    await (_db.update(_db.tasks)..where((t) => t.id.equals(parentId))).write(
      TasksCompanion(recurrence: Value(Recurrence.never.name)),
    );
  }
}
