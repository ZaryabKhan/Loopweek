import 'package:flutter/material.dart';
import 'package:home_widget/home_widget.dart';

import 'package:loopweek/data/repositories/task_repository.dart';
import 'package:loopweek/domain/models/color_tag.dart';
import 'package:loopweek/domain/models/task.dart';

/// Pushes a compact snapshot of today's tasks to the Android home-screen
/// widget via the `home_widget` package. Toggling the widget checkboxes
/// triggers a background callback registered from `main.dart`.
///
/// The widget reads the user's accent color and the app's effective theme so
/// app + widget stay visually consistent (including dark mode). Data is sent
/// as simple marshalled strings/lists — the native side (Kotlin) renders the
/// list as an Android `RemoteViews`.
class HomeWidgetService {
  HomeWidgetService(this._repository);

  static const String androidName = 'LoopweekWidgetProvider';
  static const String _kTasks = 'loopweek.tasks';
  static const String _kAccent = 'loopweek.accent';
  static const String _kDate = 'loopweek.date';
  static const String _kTheme = 'loopweek.theme';

  final TaskRepository _repository;

  Future<void> pushTodaySnapshot({
    required ColorTag accent,
    required ThemeMode themeMode,
  }) async {
    final DateTime now = DateTime(
      DateTime.now().year,
      DateTime.now().month,
      DateTime.now().day,
    );
    final tasks = await _repository.watchTasksForDate(now).first;
    final sorted = [...tasks]
      ..sort((a, b) {
        if (a.isCompleted != b.isCompleted) {
          return a.isCompleted ? 1 : -1;
        }
        final sa = a.sortOrder.compareTo(b.sortOrder);
        return sa != 0 ? sa : a.title.compareTo(b.title);
      });

    // Render up to 10 entries; the native side decides visible count per size.
    // Marshalled as a single newline-separated string for reliable native
    // parsing. Each line: `<id>|<done 0|1>|<title>|<HH:MM or empty>`.
    final snapshot = sorted.take(10).map(_encodeTask).join('\n');
    await HomeWidget.saveWidgetData(_kTasks, snapshot);
    await HomeWidget.saveWidgetData(_kAccent, accent.encoded);
    await HomeWidget.saveWidgetData(_kDate, now.toIso8601String());
    // Send the raw theme mode ("system" | "light" | "dark") so the native
    // widget mirrors the app: forced light/dark are honored directly, and
    // "system" is resolved from the OS night mode at render time (so it stays
    // in step even while the app is closed).
    await HomeWidget.saveWidgetData(_kTheme, themeMode.name);
    await HomeWidget.updateWidget(
      androidName: androidName,
      qualifiedAndroidName: 'com.appcodecraft.loopweek.LoopweekWidgetProvider',
    );
  }

  /// Background callback entrypoint: toggle a task's completed state by id
  /// (the widget packs the task id into the intent extras under
  /// `loopweek.toggle`).
  Future<void> handleToggleFromWidget(dynamic rawId) async {
    if (rawId is! String || rawId.isEmpty) return;
    final task = await _repository.getTask(rawId);
    if (task == null) return;
    await _repository.setCompleted(id: rawId, completed: !task.isCompleted);
  }
}

String _encodeTask(Task t) =>
    '${t.id}|${t.isCompleted ? 1 : 0}|${t.title}|${_encodeTime(t)}';

String _encodeTime(Task t) => t.hasTime && t.time != null
    ? '${t.time!.hour.toString().padLeft(2, '0')}:'
          '${t.time!.minute.toString().padLeft(2, '0')}'
    : '';

extension _ColorRGB on ColorTag {
  String get encoded {
    // Accent color encoded as 'RR|GG|BB' so the native widget can parse it.
    final code = const {
      ColorTag.orange: 0xFFF4511E,
      ColorTag.pink: 0xFFE91E63,
      ColorTag.blue: 0xFF1E88E5,
      ColorTag.green: 0xFF43A047,
    }[this]!;
    final r = (code >> 16) & 0xFF;
    final g = (code >> 8) & 0xFF;
    final b = code & 0xFF;
    return '$r|$g|$b';
  }
}
