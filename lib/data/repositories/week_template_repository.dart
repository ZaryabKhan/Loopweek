import 'package:drift/drift.dart';
import 'package:flutter/material.dart' show TimeOfDay;
import 'package:uuid/uuid.dart';

import 'package:loopweek/data/database/database.dart';
import 'package:loopweek/data/repositories/task_repository.dart';
import 'package:loopweek/domain/models/color_tag.dart';
import 'package:loopweek/domain/models/task.dart';

/// Read-only summary of a saved template, feeding the picker sheet.
class TemplateSummary {
  const TemplateSummary({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.itemCount,
  });

  final String id;
  final String name;
  final DateTime createdAt;
  final int itemCount;
}

/// Saves a week's tasks as a named template and re-applies saved templates
/// onto a target week. Templates are infrastructure: no domain model, all
/// access goes through this repository.
class WeekTemplateRepository {
  WeekTemplateRepository(this._db, this._tasks, {Uuid? uuid})
    : _uuid = uuid ?? const Uuid();

  final LoopweekDatabase _db;
  final TaskRepository _tasks;
  final Uuid _uuid;

  /// Captures the non-Someday tasks of [weekDates] (one entry per day,
  /// matching weekdays recorded per item) into a new template named [name].
  /// Template and items are written in one transaction. Returns the number
  /// of captured items.
  Future<int> saveFromWeek(String name, List<DateTime> weekDates) async {
    final captured = <(int, Task)>[];
    for (final date in weekDates) {
      final dayTasks = await _tasks.watchTasksForDate(date).first;
      for (final task in dayTasks) {
        captured.add((date.weekday, task));
      }
    }

    return _db.transaction(() async {
      final templateId = _uuid.v4();
      await _db
          .into(_db.weekTemplates)
          .insert(
            WeekTemplatesCompanion.insert(
              id: templateId,
              name: name,
              createdAt: DateTime.now(),
            ),
          );
      await _db.batch((batch) {
        for (final (weekday, task) in captured) {
          batch.insert(
            _db.weekTemplateItems,
            WeekTemplateItemsCompanion.insert(
              id: _uuid.v4(),
              templateId: templateId,
              weekday: weekday,
              title: task.title,
              hasTime: task.hasTime,
              timeMinutes: Value(
                task.hasTime && task.time != null
                    ? task.time!.hour * 60 + task.time!.minute
                    : null,
              ),
              sortOrder: task.sortOrder,
            ),
          );
        }
      });
      return captured.length;
    });
  }

  /// Live list of saved templates, newest first, each with its item count.
  Stream<List<TemplateSummary>> watchTemplates() {
    final query = _db.select(_db.weekTemplates)
      ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]);
    return query.watch().asyncMap((rows) async {
      final counts = await _itemCountsByTemplate();
      return [
        for (final row in rows)
          TemplateSummary(
            id: row.id,
            name: row.name,
            createdAt: row.createdAt,
            itemCount: counts[row.id] ?? 0,
          ),
      ];
    });
  }

  Future<Map<String, int>> _itemCountsByTemplate() async {
    final count = _db.weekTemplateItems.id.count();
    final query = _db.selectOnly(_db.weekTemplateItems)
      ..addColumns([_db.weekTemplateItems.templateId, count])
      ..groupBy([_db.weekTemplateItems.templateId]);
    final rows = await query
        .map(
          (row) => MapEntry(
            row.read(_db.weekTemplateItems.templateId)!,
            row.read(count) ?? 0,
          ),
        )
        .get();
    return Map.fromEntries(rows);
  }

  /// Seeds [weekDates] with a saved template's items: each item lands on the
  /// week date whose weekday matches, appended after that day's existing
  /// non-Someday tasks (max sortOrder + 1 + its position among the template's
  /// items for that day). Days before [today] are skipped — nothing already
  /// on the week is deleted or overwritten. Returns the number of tasks
  /// created.
  Future<int> applyToWeek(
    String templateId,
    List<DateTime> weekDates,
    DateTime today,
    ColorTag accent,
  ) async {
    final items =
        await (_db.select(_db.weekTemplateItems)
              ..where((i) => i.templateId.equals(templateId))
              ..orderBy([
                (i) => OrderingTerm.asc(i.weekday),
                (i) => OrderingTerm.asc(i.sortOrder),
                (i) => OrderingTerm.asc(i.title),
              ]))
            .get();
    if (items.isEmpty) return 0;

    final todayStart = DateTime(today.year, today.month, today.day);
    final byWeekday = <int, List<WeekTemplateItemRow>>{};
    for (final item in items) {
      (byWeekday[item.weekday] ??= []).add(item);
    }

    // One max read per target day — computing it per item would make the
    // inserted tasks cascade their own maximum.
    final maxByDate = <DateTime, int>{};
    for (final weekday in byWeekday.keys) {
      final target = weekDates.firstWhere((d) => d.weekday == weekday);
      if (target.isBefore(todayStart)) continue;
      final dayTasks = await _tasks.watchTasksForDate(target).first;
      maxByDate[target] = dayTasks.fold<int>(
        -1,
        (max, task) => task.sortOrder > max ? task.sortOrder : max,
      );
    }

    final created = <Task>[];
    for (final entry in byWeekday.entries) {
      final target = weekDates.firstWhere((d) => d.weekday == entry.key);
      if (target.isBefore(todayStart)) continue;
      final base = maxByDate[target]!;
      for (var i = 0; i < entry.value.length; i++) {
        final item = entry.value[i];
        created.add(
          Task(
            id: _uuid.v4(),
            title: item.title,
            date: target,
            colorTag: accent,
            hasTime: item.hasTime,
            time: item.hasTime && item.timeMinutes != null
                ? TimeOfDay(hour: item.timeMinutes! ~/ 60, minute: item.timeMinutes! % 60)
                : null,
            sortOrder: base + 1 + i,
          ),
        );
      }
    }
    if (created.isEmpty) return 0;
    await _tasks.insertTaskBatch(created);
    return created.length;
  }
}
