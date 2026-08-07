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
    // Half-open range [start, end): `isBetweenValues` is inclusive on both
    // ends, which would make a task stored at exactly next-day midnight (a
    // time-less task created for that day) match the previous day too.
    final query = _db.select(_db.tasks)
      ..where(
        (t) =>
            t.date.isBiggerOrEqualValue(start) & t.date.isSmallerThanValue(end),
      )
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

  /// Every row that carries a reminder and whose date is on or after the
  /// start of [date]'s day — standalone tasks, recurring rules, and
  /// materialized occurrences alike. Feeds the startup reminder reconciler,
  /// which re-schedules anything the OS or the plugin lost.
  Future<List<Task>> tasksWithRemindersFrom(DateTime date) async {
    final start = DateTime(date.year, date.month, date.day);
    final rows = await (_db.select(_db.tasks)
          ..where(
            (t) =>
                t.hasReminder.equals(true) &
                t.date.isBiggerOrEqualValue(start),
          )).get();
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

  /// Re-persists `sortOrder` for every id in [orderedIds] atomically. Using
  /// a single Drift batch keeps the writes inside one transaction, so a
  /// partial failure (or a concurrent reorder/complete) can never leave the
  /// day's ordering half-applied.
  Future<void> reorderTasksForDate({
    required DateTime date,
    required List<String> orderedIds,
  }) async {
    if (orderedIds.isEmpty) return;
    await _db.batch((batch) {
      for (var i = 0; i < orderedIds.length; i++) {
        batch.update(
          _db.tasks,
          TasksCompanion(sortOrder: Value(i)),
          where: (t) => t.id.equals(orderedIds[i]),
        );
      }
    });
  }

  // ---- recurrence ---------------------------------------------------------

  /// Materialize occurrences of [rule] for the window [start..end] (inclusive)
  /// by inserting independent rows linked back to [rule.id]. Existing
  /// occurrences (same rule id + same date) are skipped.
  ///
  /// The check-then-insert runs inside a single transaction and the inserts
  /// use `insertOrIgnore` against the unique index on
  /// `(recurrence_parent_id, date)`, so concurrent materialization for the
  /// same rule cannot produce duplicate occurrences and a mid-loop failure
  /// rolls back the whole batch.
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

    return _db.transaction(() async {
      // Skip dates that already have an occurrence for this rule. The SELECT
      // is consistent for the whole transaction, so no concurrent writer can
      // slip a duplicate in between this read and the inserts below.
      final existing = await (_db.select(
        _db.tasks,
      )..where((t) => t.recurrenceParentId.equals(rule.id))).get();
      final existingDates = existing.map((e) => _dateKey(e.date)).toSet();

      final created = <Task>[];
      for (final d in dates) {
        final key = _dateKey(d);
        if (existingDates.contains(key)) continue;
        // Reserve this date so multiple occurrences of the same date within
        // one batch don't collide.
        existingDates.add(key);
        final occurrence = rule.copyWith(
          id: _uuid.v4(),
          date: d,
          isCompleted: false,
          recurrenceParentId: rule.id,
          recurrence: Recurrence.never,
          reminderOffsetDays: rule.reminderOffsetDays,
          sortOrder: rule.sortOrder,
        );
        await _db
            .into(_db.tasks)
            .insert(
              _mapper.toCompanion(occurrence),
              mode: InsertMode.insertOrIgnore,
            );
        created.add(occurrence);
      }
      return created;
    });
  }

  static String _dateKey(DateTime d) => '${d.year}-${d.month}-${d.day}';

  /// Synchronize future occurrences of [rule] (dates >= [today]) with the
  /// current rule metadata and pattern. Existing future occurrences that no
  /// longer match the rule's recurrence are deleted; those that still match are
  /// updated to share the rule's title, color, time, reminder and sort order.
  /// Missing future occurrences are then materialized. Past occurrences are
  /// left untouched as history.
  ///
  /// This is important because occurrences are stored as independent rows, so
  /// editing a rule's title/color/reminder would otherwise leave future
  /// occurrences stale while the anchor row reflects the new values.
  Future<void> syncFutureOccurrences({
    required Task rule,
    required DateTime today,
  }) async {
    final futureCutoff = DateTime(today.year, today.month, today.day);

    if (!rule.recurrence.isRecurring) {
      // Stopping recurrence: remove all future occurrences, keep history.
      final futureRows =
          await (_db.select(_db.tasks)..where(
                (t) =>
                    t.recurrenceParentId.equals(rule.id) &
                    t.date.isBiggerOrEqualValue(futureCutoff),
              ))
              .get();
      await _db.batch((batch) {
        for (final row in futureRows) {
          batch.deleteWhere(_db.tasks, (t) => t.id.equals(row.id));
        }
      });
      return;
    }

    // Desired future dates for the current rule pattern.
    final end = futureCutoff.add(const Duration(days: 365));
    final desiredDates = RecurrenceGenerator.occurrencesForWindow(
      rule: rule,
      startInclusive: futureCutoff,
      endInclusive: end,
      includeAnchor: false,
    ).map(_dateKey).toSet();

    // Existing future occurrences.
    final existing = await getOccurrencesOf(rule.id);
    final future = existing
        .where((o) => !o.date.isBefore(futureCutoff))
        .toList();

    await _db.batch((batch) {
      for (final occurrence in future) {
        if (!desiredDates.contains(_dateKey(occurrence.date))) {
          // Pattern no longer produces this date; delete it.
          batch.deleteWhere(_db.tasks, (t) => t.id.equals(occurrence.id));
          continue;
        }
        // Keep the date/completion history, but mirror the rule's metadata.
        final updated = occurrence.copyWith(
          title: rule.title,
          colorTag: rule.colorTag,
          hasTime: rule.hasTime,
          time: rule.time,
          clearTime: !rule.hasTime,
          hasReminder: rule.hasReminder,
          reminderOffsetDays: rule.reminderOffsetDays,
          sortOrder: rule.sortOrder,
        );
        batch.update(
          _db.tasks,
          _mapper.toCompanion(updated),
          where: (t) => t.id.equals(updated.id),
        );
      }
    });

    // Fill any gaps (e.g. newly extended window or changed pattern).
    await materializeOccurrences(rule: rule, start: futureCutoff, end: end);
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
