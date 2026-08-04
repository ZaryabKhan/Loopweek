import 'package:flutter/material.dart' show TimeOfDay;

import 'package:loopweek/domain/models/color_tag.dart';
import 'package:loopweek/domain/models/recurrence.dart';
import 'package:loopweek/domain/models/task.dart';
import 'package:loopweek/presentation/week/week_providers.dart';

/// Generates dummy tasks for the 7 days of the week containing [anchor].
///
/// Used by the hidden testing-mode easter egg so the week view can be
/// populated with realistic data without manual entry.
List<Task> buildDummyTasksForWeek(DateTime anchor) {
  final dates = weekDatesFor(anchor);
  final tasks = <Task>[];
  var sequence = 0;

  tasks.add(
    Task(
      id: 'dummy-${sequence++}',
      title: 'Morning run',
      date: dates[1],
      colorTag: ColorTag.blue,
      hasTime: true,
      time: const TimeOfDay(hour: 7, minute: 0),
      recurrence: Recurrence.daily,
    ),
  );
  tasks.add(
    Task(
      id: 'dummy-${sequence++}',
      title: 'Groceries',
      date: dates[3],
      colorTag: ColorTag.green,
      hasTime: true,
      time: const TimeOfDay(hour: 18, minute: 30),
      isCompleted: true,
    ),
  );
  tasks.add(
    Task(
      id: 'dummy-${sequence++}',
      title: 'Team stand-up',
      date: dates[2],
      colorTag: ColorTag.pink,
      hasTime: true,
      time: const TimeOfDay(hour: 10, minute: 0),
      recurrence: Recurrence.weekly,
      sortOrder: 1,
    ),
  );
  tasks.add(
    Task(
      id: 'dummy-${sequence++}',
      title: 'Pay credit card bill',
      date: dates[4],
      colorTag: ColorTag.orange,
      hasTime: false,
      hasReminder: true,
      sortOrder: 0,
    ),
  );
  tasks.add(
    Task(
      id: 'dummy-${sequence++}',
      title: 'Call mom',
      date: dates[6],
      colorTag: ColorTag.pink,
      hasTime: true,
      time: const TimeOfDay(hour: 20, minute: 0),
      recurrence: Recurrence.weekly,
      sortOrder: 2,
    ),
  );
  tasks.add(
    Task(
      id: 'dummy-${sequence++}',
      title: 'Dentist appointment',
      date: dates[5],
      colorTag: ColorTag.blue,
      hasTime: true,
      time: const TimeOfDay(hour: 14, minute: 15),
      hasReminder: true,
      sortOrder: 0,
    ),
  );
  tasks.add(
    Task(
      id: 'dummy-${sequence++}',
      title: 'Read chapter',
      date: dates[0],
      colorTag: ColorTag.green,
      hasTime: false,
      recurrence: Recurrence.daily,
      sortOrder: 3,
    ),
  );
  tasks.add(
    Task(
      id: 'dummy-${sequence++}',
      title: 'Review PRs',
      date: dates[1],
      colorTag: ColorTag.orange,
      hasTime: true,
      time: const TimeOfDay(hour: 15, minute: 0),
      sortOrder: 4,
    ),
  );
  tasks.add(
    Task(
      id: 'dummy-${sequence++}',
      title: 'Reply to Alex',
      date: dates[4],
      colorTag: ColorTag.green,
      hasTime: false,
      isCompleted: true,
    ),
  );

  return tasks;
}
