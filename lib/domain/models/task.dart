import 'package:flutter/material.dart' show TimeOfDay;
import 'package:loopweek/domain/models/color_tag.dart';
import 'package:loopweek/domain/models/recurrence.dart';

/// Domain representation of a Task — used by the presentation layer.
///
/// This mirrors the Drift row but keeps the app decoupled from storage details.
class Task {
  final String id;
  final String title;
  final DateTime date;
  final bool isCompleted;
  final ColorTag colorTag;
  final bool hasTime;
  final TimeOfDay? time;
  final bool hasReminder;
  final Recurrence recurrence;
  final String? recurrenceParentId;
  final int sortOrder;

  const Task({
    required this.id,
    required this.title,
    required this.date,
    this.isCompleted = false,
    this.colorTag = ColorTag.orange,
    this.hasTime = false,
    this.time,
    this.hasReminder = false,
    this.recurrence = Recurrence.never,
    this.recurrenceParentId,
    this.sortOrder = 0,
  });

  Task copyWith({
    String? id,
    String? title,
    DateTime? date,
    bool? isCompleted,
    ColorTag? colorTag,
    bool? hasTime,
    TimeOfDay? time,
    bool? hasReminder,
    Recurrence? recurrence,
    String? recurrenceParentId,
    int? sortOrder,
    bool clearTime = false,
    bool clearRecurrenceParent = false,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      date: date ?? this.date,
      isCompleted: isCompleted ?? this.isCompleted,
      colorTag: colorTag ?? this.colorTag,
      hasTime: hasTime ?? this.hasTime,
      time: clearTime ? null : (time ?? this.time),
      hasReminder: hasReminder ?? this.hasReminder,
      recurrence: recurrence ?? this.recurrence,
      recurrenceParentId:
          clearRecurrenceParent ? null : (recurrenceParentId ?? this.recurrenceParentId),
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }

  /// Day-of-week offset for "Every Sunday"-style captions.
  /// DateTime.weekday: Monday = 1, Sunday = 7. We want Sunday = 0.
  int get weekdayIndex => date.weekday % 7;

  @override
  String toString() =>
      'Task($id, "$title", ${date.toIso8601String()}, completed=$isCompleted, '
      'rec=$recurrence)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is Task && other.id == id;

  @override
  int get hashCode => id.hashCode;
}