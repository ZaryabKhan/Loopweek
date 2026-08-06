import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

/// Thin wrapper around `flutter_local_notifications` for scheduling optional
/// per-task reminders. No permissions are requested at startup — the spec
/// forbids that. [requestPermission] is called only when the user saves their
/// first alert.
///
/// Android note: the app's `AndroidManifest.xml` must declare the plugin's
/// `ScheduledNotificationReceiver` and `ScheduledNotificationBootReceiver`
/// (required since plugin v16), otherwise scheduled notifications never show.
class NotificationService {
  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static const MethodChannel _cacheChannel = MethodChannel(
    'loopweek/notification_cache',
  );

  bool _initialized = false;

  Future<void> ensureInitialized() async {
    if (_initialized) return;
    tz.initializeTimeZones();
    const AndroidInitializationSettings android = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
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
    await _recoverCorruptCache();
  }

  /// Guards against the known `flutter_local_notifications` "Missing type
  /// parameter" crash: the plugin persists scheduled notifications as JSON in a
  /// SharedPreferences cache and deserializes it with Gson. Data written by an
  /// older app version can reference a generic `Type` the current Gson cannot
  /// bind, causing `loadScheduledNotifications()` to throw on every
  /// `cancel`/`schedule` call on Android. Because the cache is corrupt it can
  /// never be read successfully again, so it must be cleared once; the corrupt
  /// JSON is worthless anyway since the plugin cannot restore the schedules
  /// from it. We detect that failure by attempting to list pending requests
  /// (which internally loads the same cache) and, if it throws, clear the
  /// native SharedPreferences so reminders work again.
  Future<void> _recoverCorruptCache() async {
    if (!Platform.isAndroid) return;
    try {
      await _plugin.pendingNotificationRequests();
      return; // Cache is healthy.
    } catch (_) {
      // ignore: avoid_catches_without_on_clauses
    }
    try {
      await _cacheChannel.invokeMethod<void>('clearScheduledNotifications');
      debugPrint('Cleared corrupt flutter_local_notifications cache.');
    } catch (e) {
      debugPrint('Could not clear corrupt notification cache: $e');
    }
  }

  /// Ask the OS for permission once the user actually opts in to a reminder.
  Future<bool> requestPermission() async {
    await ensureInitialized();
    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (android != null) {
      final granted = await android.requestNotificationsPermission();
      return granted ?? false;
    }
    final ios = _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >();
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

  /// Notification ids must be non-negative and stable across app runs. Dart
  /// string hash codes can be negative, so mask down to 31 bits.
  int _notificationIdFor(String taskId) => taskId.hashCode & 0x7FFFFFFF;

  /// Schedules a reminder at [scheduled], replacing any previously scheduled
  /// reminder for the same task.
  ///
  /// Never throws into the caller's save flow: a fire time in the past simply
  /// results in no reminder (the old one was already cancelled), and any
  /// plugin failure is logged rather than propagated.
  Future<void> scheduleTaskReminder({
    required String taskId,
    required String title,
    required DateTime scheduled,
  }) async {
    await ensureInitialized();
    final int id = _notificationIdFor(taskId);

    // Stop any previous reminder for this task first. Wrap in try/catch so a
    // stale/corrupt plugin cache can never break the caller's save flow.
    try {
      await _plugin.cancel(id);
    } catch (e) {
      debugPrint('Could not cancel old reminder for task $taskId: $e');
    }

    // `zonedSchedule` throws ArgumentError for past dates; a reminder whose
    // time has already passed should simply not fire.
    if (!scheduled.isAfter(DateTime.now())) return;

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

    try {
      await _plugin.zonedSchedule(
        id,
        title,
        'Tap to open Loopweek.',
        _toTz(scheduled),
        details,
        payload: taskId,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    } catch (e) {
      // e.g. exact alarms revoked in Android 14+ settings. The task itself is
      // saved; only the reminder is lost.
      debugPrint('Could not schedule reminder for task $taskId: $e');
    }
  }

  Future<void> cancelTaskReminder(String taskId) async {
    await ensureInitialized();
    try {
      await _plugin.cancel(_notificationIdFor(taskId));
    } catch (e) {
      debugPrint('Could not cancel reminder for task $taskId: $e');
    }
  }

  tz.TZDateTime _toTz(DateTime dt) {
    // `TZDateTime.from` preserves the instant, so the alarm fires at the same
    // moment as [dt] regardless of which location it is expressed in.
    return tz.TZDateTime.from(dt, tz.local);
  }
}
