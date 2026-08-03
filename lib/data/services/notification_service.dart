import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

/// Thin wrapper around `flutter_local_notifications` for scheduling optional
/// per-task reminders. No permissions are requested at startup — the spec
/// forbids that. [requestPermission] is called only when the user saves their
/// first alert.
class NotificationService {
  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  Future<void> ensureInitialized() async {
    if (_initialized) return;
    tz.initializeTimeZones();
    const AndroidInitializationSettings android =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings ios = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    const InitializationSettings settings = InitializationSettings(
      android: android,
      iOS: ios,
    );
    await _plugin.initialize(settings);
    _initialized = true;
  }

  /// Ask the OS for permission once the user actually opts in to a reminder.
  Future<bool> requestPermission() async {
    await ensureInitialized();
    final android = _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    if (android != null) {
      final granted = await android.requestNotificationsPermission();
      return granted ?? false;
    }
    final ios = _plugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>();
    if (ios != null) {
      final result = await ios.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      return result ?? false;
    }
    return false;
  }

  Future<void> scheduleTaskReminder({
    required String taskId,
    required String title,
    required DateTime scheduled,
  }) async {
    await ensureInitialized();
    await _plugin.cancel(taskId.hashCode);

    const NotificationDetails details = NotificationDetails(
      android: AndroidNotificationDetails(
        'loopweek_reminders',
        'Task reminders',
        channelDescription: 'Optional reminders for Loopweek tasks.',
        importance: Importance.high,
        priority: Priority.high,
        showWhen: true,
      ),
      iOS: DarwinNotificationDetails(),
    );

    final tz.TZDateTime when = _toTz(scheduled);
    await _plugin.zonedSchedule(
      taskId.hashCode,
      title,
      'Tap to open Loopweek.',
      when,
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  Future<void> cancelTaskReminder(String taskId) async {
    await _plugin.cancel(taskId.hashCode);
  }

  tz.TZDateTime _toTz(DateTime dt) {
    // Use the local time zone; the timezone package initializes it from the
    // device automatically when available. Falls back to UTC.
    final location = tz.local;
    return tz.TZDateTime.from(dt, location);
  }
}