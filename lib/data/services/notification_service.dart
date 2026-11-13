import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:intl/intl.dart';
import 'package:loopweek/domain/models/task.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

/// What the user did with a reminder notification. [actionId] mirrors the
/// plugin's `NotificationResponse.actionId`; a null id is a plain body tap.
enum ReminderAction {
  markDone('mark_done'),
  remindTomorrow('remind_tomorrow'),
  open(null);

  const ReminderAction(this.actionId);

  final String? actionId;

  static ReminderAction fromActionId(String? actionId) =>
      ReminderAction.values.firstWhere(
        (action) => action.actionId == actionId,
        orElse: () => ReminderAction.open,
      );
}

/// Data carried by every reminder notification payload (JSON): the notified
/// task row's id and its date, so handlers can act on the exact row without
/// re-deriving anything.
class ReminderPayload {
  const ReminderPayload({required this.taskId, required this.taskDate});

  final String taskId;
  final DateTime taskDate;

  static ReminderPayload? tryDecode(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    try {
      final Object? decoded = jsonDecode(raw);
      if (decoded is! Map || decoded['taskId'] is! String) return null;
      final date = DateTime.tryParse(decoded['date'] as String? ?? '');
      if (date == null) return null;
      return ReminderPayload(
        taskId: decoded['taskId'] as String,
        taskDate: DateTime(date.year, date.month, date.day),
      );
    } catch (_) {
      return null;
    }
  }

  String encode() => jsonEncode({
        'taskId': taskId,
        'date': DateFormat('yyyy-MM-dd').format(taskDate),
      });
}

/// Thin wrapper around `flutter_local_notifications` for scheduling optional
/// per-task reminders. No permissions are requested at startup — the spec
/// forbids that. [requestPermission] is called only when the user opts in to
/// a reminder.
///
/// Reliability design ("scheduled must mean delivered"):
///
/// - Android release builds run R8; `android/app/proguard-rules.pro` keeps
///   the plugin's Gson-serialized model classes, and `res/raw/keep.xml`
///   keeps the notification icon. Without those two files scheduled
///   notifications silently never show in release builds.
/// - The device timezone is resolved via `flutter_timezone` so scheduled
///   instants match the plugin's documented setup.
/// - Exact alarms can be revoked by the user on Android 12+. Scheduling
///   detects that and falls back to inexact alarms rather than dropping the
///   reminder.
/// - [syncReminders] reconciles the plugin state against the database once
///   per app start, so reminders self-heal after force-stops, cache wipes,
///   or any other lost-alarm scenario.
///
/// Notifications carry "Mark done" and "Remind tomorrow" actions. Presses
/// arrive via [ReminderAction]; the service only parses and forwards them —
/// the UI layer (main.dart) owns what actually happens.
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

  static const String _channelId = 'reminders';
  static const String _channelName = 'Reminders';
  static const String _channelDescription =
      'Optional reminders for Loopweek tasks.';

  /// Foreground taps and action presses land here after payload parsing.
  /// Assigned once in `main.dart` so this service never touches widgets,
  /// snackbars, or the Riverpod graph itself.
  static Future<void> Function(ReminderAction action, ReminderPayload payload)?
      onForegroundAction;

  /// Top-level background callback for notification action presses,
  /// registered from `main.dart` (it must be `@pragma('vm:entry-point')`
  /// there). Null in background isolates, which never spawn further ones.
  static Future<void> Function(NotificationResponse)?
      backgroundResponseHandler;

  bool _initialized = false;

  Future<void> ensureInitialized() async {
    if (_initialized) return;
    tz.initializeTimeZones();
    await _setDeviceTimezone();
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
    await _plugin.initialize(
      settings,
      onDidReceiveNotificationResponse: _onNotificationResponse,
      onDidReceiveBackgroundNotificationResponse: backgroundResponseHandler,
    );
    _initialized = true;
    await _recoverCorruptCache();
  }

  /// Foreground response dispatch: parse the payload, map the pressed action
  /// (null action id = body tap) and forward to the UI-layer callback.
  Future<void> _onNotificationResponse(NotificationResponse response) async {
    final payload = ReminderPayload.tryDecode(response.payload);
    if (payload == null) return;
    final handler = onForegroundAction;
    if (handler == null) return;
    await handler(ReminderAction.fromActionId(response.actionId), payload);
  }

  /// Launch details for a cold start triggered by a notification tap, so the
  /// next-open bootstrap can honor a body tap that launched the app. Must be
  /// called after [ensureInitialized]. Never throws.
  Future<NotificationAppLaunchDetails?> launchDetails() async {
    try {
      return await _plugin.getNotificationAppLaunchDetails();
    } catch (e) {
      debugPrint('Could not read notification launch details: $e');
      return null;
    }
  }

  /// Points the `timezone` package's local location at the device's current
  /// timezone. Without this, `tz.local` silently stays UTC; scheduling would
  /// still round-trip instants, but the plugin's documented setup and its
  /// date handling rely on the real location being set. Falls back to UTC if
  /// the lookup fails — never throws into startup.
  Future<void> _setDeviceTimezone() async {
    try {
      final info = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(info.identifier));
    } catch (e) {
      debugPrint('Could not resolve device timezone: $e');
    }
  }

  /// Guards against the known `flutter_local_notifications` "Missing type
  /// parameter" crash: the plugin persists scheduled notifications as JSON in
  /// a SharedPreferences cache and deserializes it with Gson. Data written by
  /// an older app version can reference a generic `Type` the current Gson
  /// cannot bind, causing `loadScheduledNotifications()` to throw on every
  /// `cancel`/`schedule` call on Android. Because the cache is corrupt it can
  /// never be read successfully again, so it must be cleared once; the corrupt
  /// JSON is worthless anyway since the plugin cannot restore the schedules
  /// from it. We detect that failure by attempting to list pending requests
  /// (which internally loads the same cache) and, if it throws, clear the
  /// native SharedPreferences so reminders work again.
  ///
  /// After this runs, [syncReminders] restores the reminders that the wiped
  /// cache lost, so recovery no longer leaves the user without reminders.
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

  /// Whether the OS currently allows showing notifications at all. Used to
  /// warn (instead of failing silently) when reminders are saved while
  /// notifications are blocked.
  Future<bool> hasPermission() async {
    await ensureInitialized();
    try {
      final android = _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      if (android != null) {
        return await android.areNotificationsEnabled() ?? false;
      }
      final ios = _plugin
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >();
      if (ios != null) {
        final options = await ios.checkPermissions();
        return options?.isAlertEnabled ?? false;
      }
    } catch (e) {
      debugPrint('Could not check notification permission: $e');
    }
    return false;
  }

  /// Notification ids must be non-negative and stable across app runs.
  /// FNV-1a is used instead of [String.hashCode] because the latter's
  /// algorithm is not pinned by the Dart spec and could change between SDK
  /// releases, which would orphan every pending reminder on upgrade.
  @visibleForTesting
  static int notificationIdFor(String taskId) {
    var hash = 0x811c9dc5; // FNV offset basis.
    for (final unit in taskId.codeUnits) {
      hash = ((hash ^ unit) * 0x01000193) & 0xFFFFFFFF;
    }
    return hash & 0x7FFFFFFF; // Mask to 31 bits: ids must be non-negative.
  }

  /// Canonical reminder fire time for a task row: its date at its time,
  /// falling back to 09:00 for time-less tasks, then shifted back by the
  /// user's chosen [Task.reminderOffsetDays]. Single source of truth used by
  /// both the save flow and the startup reconciler so they never drift.
  static DateTime fireDateTimeFor(Task task) {
    return DateTime(
      task.date.year,
      task.date.month,
      task.date.day,
      task.time?.hour ?? 9,
      task.time?.minute ?? 0,
    ).subtract(Duration(days: task.reminderOffsetDays));
  }

  /// Schedules a reminder at [scheduled], replacing any previously scheduled
  /// reminder for the same task. [accent] tints the Android notification with
  /// the user's chosen color; [taskDate] is the task's own date (not the fire
  /// time), carried in the payload so actions can reason about it.
  ///
  /// Never throws into the caller's save flow: a fire time in the past simply
  /// results in no reminder (the old one was already cancelled), and any
  /// plugin failure is logged rather than propagated. If exact alarms are not
  /// allowed (revoked on Android 12+) it falls back to an inexact alarm so
  /// the reminder is delivered — possibly a little late — rather than lost.
  Future<void> scheduleTaskReminder({
    required String taskId,
    required String title,
    required DateTime scheduled,
    required DateTime taskDate,
    required Color accent,
  }) async {
    await ensureInitialized();
    final int id = notificationIdFor(taskId);

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

    final NotificationDetails details = NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: _channelDescription,
        importance: Importance.high,
        priority: Priority.high,
        showWhen: true,
        color: accent,
        actions: [
          AndroidNotificationAction(
            ReminderAction.markDone.actionId!,
            'Mark done',
          ),
          AndroidNotificationAction(
            ReminderAction.remindTomorrow.actionId!,
            'Remind tomorrow',
          ),
        ],
      ),
      iOS: const DarwinNotificationDetails(),
    );

    final body = 'Scheduled for ${DateFormat('EEE, MMM d').format(scheduled)}';
    final payload = ReminderPayload(taskId: taskId, taskDate: taskDate);

    var mode = await _scheduleMode();
    try {
      await _zonedSchedule(id, title, body, payload, scheduled, details, mode);
    } catch (e) {
      // Exact alarms can be revoked between the check and the schedule call;
      // retry once with an inexact alarm before giving up.
      if (mode == AndroidScheduleMode.exactAllowWhileIdle) {
        try {
          await _zonedSchedule(
            id,
            title,
            body,
            payload,
            scheduled,
            details,
            AndroidScheduleMode.inexactAllowWhileIdle,
          );
          debugPrint(
            'Exact alarms unavailable ($e); reminder for task $taskId '
            'scheduled with an inexact alarm.',
          );
        } catch (fallbackError) {
          debugPrint(
            'Could not schedule reminder for task $taskId: $fallbackError',
          );
        }
        return;
      }
      debugPrint('Could not schedule reminder for task $taskId: $e');
    }
  }

  Future<void> cancelTaskReminder(String taskId) async {
    await ensureInitialized();
    try {
      await _plugin.cancel(notificationIdFor(taskId));
    } catch (e) {
      debugPrint('Could not cancel reminder for task $taskId: $e');
    }
  }

  /// Cancels every pending reminder. Used when the master Alerts switch is
  /// turned off — a disabled switch must mean no reminder ever fires, even
  /// ones scheduled before it was disabled. Never throws.
  Future<void> cancelAllReminders() async {
    await ensureInitialized();
    try {
      await _plugin.cancelAll();
    } catch (e) {
      debugPrint('Could not cancel all reminders: $e');
    }
  }

  /// Reconciles scheduled reminders with the database. [upcoming] must be
  /// every task row that has a reminder and a date of today or later (rules
  /// and occurrences alike).
  ///
  /// - Cancels every pending reminder that does not belong to one of those
  ///   tasks: deleted tasks, reminders switched off, or ids scheduled by an
  ///   older id scheme.
  /// - Schedules every upcoming reminder that is not already pending.
  ///
  /// Run once on every app start so reminders self-heal after force-stops,
  /// cache wipes, plugin upgrades, or any other lost-alarm scenario.
  Future<void> syncReminders(List<Task> upcoming, {required Color accent}) async {
    await ensureInitialized();

    final now = DateTime.now();
    final desired = <int, Task>{};
    for (final task in upcoming) {
      final fire = fireDateTimeFor(task);
      if (!fire.isAfter(now)) continue;
      desired[notificationIdFor(task.id)] = task;
    }

    Set<int> pendingIds;
    try {
      final pending = await _plugin.pendingNotificationRequests();
      pendingIds = pending.map((request) => request.id).toSet();
    } catch (e) {
      // A corrupt cache throws here; the recovery above clears it. Treat as
      // empty so everything gets (re)scheduled below.
      debugPrint('Could not list pending reminders during sync: $e');
      pendingIds = const <int>{};
    }

    // Orphans first: pending reminders for tasks that no longer need one.
    for (final pendingId in pendingIds) {
      if (desired.containsKey(pendingId)) continue;
      try {
        await _plugin.cancel(pendingId);
      } catch (e) {
        debugPrint('Could not cancel orphaned reminder $pendingId: $e');
      }
    }

    // Then fill the gaps. Anything already pending is left untouched, so a
    // healthy state makes this a cheap no-op.
    for (final entry in desired.entries) {
      if (pendingIds.contains(entry.key)) continue;
      final task = entry.value;
      await scheduleTaskReminder(
        taskId: task.id,
        title: task.title,
        scheduled: fireDateTimeFor(task),
        taskDate: task.date,
        accent: accent,
      );
    }
  }

  /// Exact alarms need a permission the user can revoke on Android 12+.
  /// Prefer them (they fire on the minute) but never depend on them: fall
  /// back to inexact alarms, which the OS always accepts.
  Future<AndroidScheduleMode> _scheduleMode() async {
    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (android == null) return AndroidScheduleMode.exactAllowWhileIdle;
    try {
      final canExact = await android.canScheduleExactNotifications();
      if (canExact ?? true) return AndroidScheduleMode.exactAllowWhileIdle;
    } catch (e) {
      debugPrint('Could not check exact-alarm permission: $e');
    }
    return AndroidScheduleMode.inexactAllowWhileIdle;
  }

  Future<void> _zonedSchedule(
    int id,
    String title,
    String body,
    ReminderPayload payload,
    DateTime scheduled,
    NotificationDetails details,
    AndroidScheduleMode mode,
  ) {
    return _plugin.zonedSchedule(
      id,
      title,
      body,
      _toTz(scheduled),
      details,
      payload: payload.encode(),
      androidScheduleMode: mode,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  tz.TZDateTime _toTz(DateTime dt) {
    // `TZDateTime.from` preserves the instant, so the alarm fires at the same
    // moment as [dt] regardless of which location it is expressed in.
    return tz.TZDateTime.from(dt, tz.local);
  }
}
