import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart' show ThemeMode, TimeOfDay;

import 'package:loopweek/data/repositories/task_repository.dart';
import 'package:loopweek/data/services/settings_service.dart';
import 'package:loopweek/domain/models/color_tag.dart';
import 'package:loopweek/domain/models/first_day_of_week.dart';
import 'package:loopweek/domain/models/recurrence.dart';
import 'package:loopweek/domain/models/task.dart';

/// Purely local backup export/import: serializes every task plus the user
/// settings to a JSON file chosen via the system file picker, and restores
/// them by merging rows whose ids are not already present. No cloud, no
/// automatic backups — the user picks where the file lives.
class BackupService {
  BackupService(this._taskRepository, this._settingsService);

  final TaskRepository _taskRepository;
  final SettingsService _settingsService;

  static const _app = 'loopweek';
  static const _schema = 1;

  /// Asks the user where to save the backup and writes it. Returns a
  /// user-facing message; never throws.
  Future<String> exportBackup() async {
    try {
      final tasks = await _taskRepository.getAllTasks();
      final payload = {
        'app': _app,
        'schema': _schema,
        'exportedAt': DateTime.now().toUtc().toIso8601String(),
        'settings': {
          'colorTag': _settingsService.colorTag.name,
          'themeMode': _settingsService.themeMode.name,
          'alertsEnabled': _settingsService.alertsEnabled,
          'hapticsEnabled': _settingsService.hapticsEnabled,
          'firstDayOfWeek': _settingsService.firstDayOfWeek.name,
        },
        'tasks': tasks.map(_encodeTask).toList(),
      };
      final encoder = const JsonEncoder.withIndent('  ');
      final bytes = utf8.encode(encoder.convert(payload));
      final saved = await FilePicker.saveFile(
        fileName: 'loopweek-backup-${_fileStamp(DateTime.now())}.json',
        bytes: bytes,
        mimeType: 'application/json',
      );
      if (saved == null) return 'Backup cancelled.';
      return 'Exported ${tasks.length} tasks.';
    } catch (e) {
      return 'Backup failed: $e';
    }
  }

  /// Asks the user for a backup file, validates it, merges new tasks into the
  /// database and applies any backed-up settings. Reminders of imported tasks
  /// are re-armed by the startup reminder bootstrapper — nothing scheduled
  /// here. Returns a user-facing message; never throws.
  Future<String> importBackup() async {
    final List<PlatformFile> files;
    try {
      files = await FilePicker.pickFiles(
        dialogTitle: 'Choose a Loopweek backup',
        type: FileType.custom,
        allowedExtensions: const ['json'],
      );
    } catch (e) {
      return 'Import failed: $e';
    }
    if (files.isEmpty) return 'Import cancelled.';

    try {
      final bytes = await files.first.readAsBytes();
      final backup = _decode(bytes);

      final rows = <Task>[];
      var invalidSkipped = 0;
      for (final row in backup.tasks) {
        try {
          final task = _decodeTask(row);
          if (task == null) {
            invalidSkipped++;
            continue;
          }
          rows.add(task);
        } catch (_) {
          invalidSkipped++;
        }
      }

      final existingIds = (await _taskRepository.getAllTasks())
          .map((t) => t.id)
          .toSet();
      final fresh = rows.where((t) => !existingIds.contains(t.id)).toList();
      final duplicatesSkipped = rows.length - fresh.length;
      if (fresh.isNotEmpty) {
        await _taskRepository.insertTaskBatch(fresh);
      }

      if (backup.settings != null) {
        await _applySettings(backup.settings!);
      }

      return 'Imported ${fresh.length} tasks, $duplicatesSkipped duplicates '
          'skipped, $invalidSkipped invalid rows ignored.';
    } on _InvalidBackupException {
      return 'Not a valid Loopweek backup file.';
    } catch (e) {
      return 'Import failed: $e';
    }
  }

  // ---- export helpers ------------------------------------------------------

  Map<String, Object?> _encodeTask(Task t) => {
    'id': t.id,
    'title': t.title,
    'date': DateTime(t.date.year, t.date.month, t.date.day).toIso8601String(),
    'isCompleted': t.isCompleted,
    'colorTag': t.colorTag.name,
    'hasTime': t.hasTime,
    'time': t.hasTime && t.time != null
        ? '${_two(t.time!.hour)}:${_two(t.time!.minute)}'
        : null,
    'hasReminder': t.hasReminder,
    'reminderOffsetDays': t.reminderOffsetDays,
    'recurrence': t.recurrence.name,
    'recurrenceParentId': t.recurrenceParentId,
    'sortOrder': t.sortOrder,
  };

  String _fileStamp(DateTime t) =>
      '${t.year}${_two(t.month)}${_two(t.day)}-${_two(t.hour)}${_two(t.minute)}';

  String _two(int n) => n.toString().padLeft(2, '0');

  // ---- import helpers ------------------------------------------------------

  _Backup _decode(Uint8List? bytes) {
    if (bytes == null) throw const _InvalidBackupException();
    final Object? decoded;
    try {
      decoded = jsonDecode(utf8.decode(bytes));
    } catch (_) {
      throw const _InvalidBackupException();
    }
    if (decoded is! Map<String, dynamic>) throw const _InvalidBackupException();
    if (decoded['app'] != _app) throw const _InvalidBackupException();
    if (decoded['schema'] != _schema) throw const _InvalidBackupException();
    if (decoded['tasks'] is! List) throw const _InvalidBackupException();
    final settings = decoded['settings'];
    return _Backup(
      tasks: decoded['tasks'] as List,
      settings: settings is Map ? settings : null,
    );
  }

  /// Returns null when the row is structurally invalid and must be ignored.
  Task? _decodeTask(Object? raw) {
    if (raw is! Map) return null;
    final id = raw['id'];
    final title = raw['title'];
    if (id is! String || id.isEmpty) return null;
    if (title is! String || title.isEmpty) return null;
    final dateRaw = raw['date'];
    if (dateRaw is! String) return null;
    final DateTime date;
    try {
      date = DateTime.parse(dateRaw);
    } on FormatException {
      return null;
    }

    TimeOfDay? time;
    final timeRaw = raw['time'];
    if (timeRaw != null) {
      if (timeRaw is! String) return null;
      final parts = timeRaw.split(':');
      if (parts.length != 2) return null;
      final hour = int.tryParse(parts[0]);
      final minute = int.tryParse(parts[1]);
      if (hour == null || minute == null) return null;
      if (hour < 0 || hour > 23 || minute < 0 || minute > 59) return null;
      time = TimeOfDay(hour: hour, minute: minute);
    }

    return Task(
      id: id,
      title: title,
      date: date,
      isCompleted: raw['isCompleted'] == true,
      colorTag: ColorTag.fromName(_stringOrNull(raw['colorTag'])),
      hasTime: raw['hasTime'] == true,
      time: time,
      hasReminder: raw['hasReminder'] == true,
      reminderOffsetDays:
          (raw['reminderOffsetDays'] as int?) ?? 0,
      recurrence: Recurrence.fromName(_stringOrNull(raw['recurrence'])),
      recurrenceParentId: _stringOrNull(raw['recurrenceParentId']),
      sortOrder: (raw['sortOrder'] as int?) ?? 0,
    );
  }

  String? _stringOrNull(Object? value) => value is String ? value : null;

  /// Applies each backed-up setting independently; invalid or missing entries
  /// leave the corresponding local setting untouched.
  Future<void> _applySettings(Map settings) async {
    final colorTagName = _stringOrNull(settings['colorTag']);
    if (colorTagName != null &&
        ColorTag.values.any((t) => t.name == colorTagName)) {
      await _settingsService.setColorTag(ColorTag.fromName(colorTagName));
    }

    final themeModeName = _stringOrNull(settings['themeMode']);
    final mode = switch (themeModeName) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      'system' => ThemeMode.system,
      _ => null,
    };
    if (mode != null) {
      await _settingsService.setThemeMode(mode);
    }

    final alerts = settings['alertsEnabled'];
    if (alerts is bool) {
      await _settingsService.setAlertsEnabled(alerts);
    }

    final haptics = settings['hapticsEnabled'];
    if (haptics is bool) {
      await _settingsService.setHapticsEnabled(haptics);
    }

    final dayName = _stringOrNull(settings['firstDayOfWeek']);
    if (dayName != null &&
        FirstDayOfWeek.values.any((d) => d.name == dayName)) {
      await _settingsService.setFirstDayOfWeek(
        FirstDayOfWeek.fromName(dayName),
      );
    }
  }
}

class _Backup {
  const _Backup({required this.tasks, this.settings});

  final List tasks;
  final Map? settings;
}

class _InvalidBackupException implements Exception {
  const _InvalidBackupException();
}
