import 'package:drift/drift.dart';
import 'package:flutter/material.dart' show TimeOfDay;
import 'package:loopweek/data/database/database.dart';
import 'package:loopweek/domain/models/color_tag.dart';
import 'package:loopweek/domain/models/recurrence.dart';
import 'package:loopweek/domain/models/task.dart';

/// Maps [Task] domain objects to/from Drift rows.
class TaskMapper {
  const TaskMapper();

  Task toDomain(TaskRow row) {
    return Task(
      id: row.id,
      title: row.title,
      date: row.date,
      isCompleted: row.isCompleted,
      colorTag: ColorTag.fromName(row.colorTag),
      hasTime: row.hasTime,
      time: row.timeMinutes == null
          ? null
          : TimeOfDay(
              hour: (row.timeMinutes! / 60).truncate(),
              minute: row.timeMinutes! % 60,
            ),
      hasReminder: row.hasReminder,
      reminderOffsetDays: row.reminderOffsetDays,
      recurrence: Recurrence.fromName(row.recurrence),
      recurrenceParentId: row.recurrenceParentId,
      sortOrder: row.sortOrder,
    );
  }

  TasksCompanion toCompanion(Task task) {
    return TasksCompanion.insert(
      id: task.id,
      title: task.title,
      date: task.date,
      isCompleted: Value(task.isCompleted),
      colorTag: Value(task.colorTag.name),
      hasTime: Value(task.hasTime),
      timeMinutes: Value(
        task.hasTime && task.time != null
            ? task.time!.hour * 60 + task.time!.minute
            : null,
      ),
      hasReminder: Value(task.hasReminder),
      reminderOffsetDays: Value(task.reminderOffsetDays),
      recurrence: Value(task.recurrence.name),
      recurrenceParentId: Value(task.recurrenceParentId),
      sortOrder: Value(task.sortOrder),
    );
  }
}
