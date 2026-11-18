// QA retest harness for PR7 (flutter_local_notifications 17 -> 22 upgrade).
//
// Exercises the REAL NotificationService scheduling path on an emulator so the
// upgrade is verified end-to-end, not just at the unit level. Permissions are
// NOT requested here: the qa-device-matrix.yml workflow pre-sets
// POST_NOTIFICATIONS (pm grant) and SCHEDULE_EXACT_ALARM (appops allow/deny)
// from adb before this test runs, per scenario.
//
// What this test does:
//   1. Initializes NotificationService (timezone, plugin v22 init, cache).
//   2. Schedules a one-shot reminder ~75s out ("QA exact alarm").
//   3. Schedules a second reminder ~240s out ("QA reboot restore") used by the
//      workflow's API 33 job, which reboots the emulator before it fires.
//   4. Asserts the plugin's pending-queue holds both, then prints
//      machine-readable QATEST markers into logcat for the bash assertions.
//
// The OS-level checks (alarm registered, notification actually fires, on-time,
// survives reboot) happen in the workflow's bash steps via dumpsys/logcat.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:loopweek/data/services/notification_service.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;

  testWidgets('PR7 retest: reminders schedule through the real service path',
      (tester) async {
    final svc = NotificationService();
    await svc.ensureInitialized();

    final notifPermission = await svc.hasPermission();
    debugPrint(
      'QATEST env api="${Platform.operatingSystemVersion}" '
      'notifPermission=$notifPermission',
    );
    // Pre-granted via `adb shell pm grant` in the workflow. On API 31/32 the
    // permission does not exist and areNotificationsEnabled() is true anyway.
    expect(notifPermission, isTrue,
        reason: 'POST_NOTIFICATIONS must be pre-granted via adb');

    final now = DateTime.now();
    final fire = now.add(const Duration(seconds: 75));
    await svc.scheduleTaskReminder(
      taskId: 'qa-retest-exact',
      title: 'QA exact alarm',
      scheduled: fire,
      taskDate: DateTime(now.year, now.month, now.day),
      accent: const Color(0xFF4353FF),
    );

    final rebootFire = now.add(const Duration(seconds: 240));
    await svc.scheduleTaskReminder(
      taskId: 'qa-reboot-restore',
      title: 'QA reboot restore',
      scheduled: rebootFire,
      taskDate: DateTime(now.year, now.month, now.day),
      accent: const Color(0xFF4353FF),
    );

    // Independent probe instance: the pending queue is the plugin's own state,
    // so this catches a silent schedule failure at the Dart level.
    final probe = FlutterLocalNotificationsPlugin();
    final pending = await probe.pendingNotificationRequests();
    final ids = pending.map((r) => r.id).toSet();
    debugPrint('QATEST pendingCount=${pending.length} '
        'hasExact=${ids.contains(NotificationService.notificationIdFor('qa-retest-exact'))} '
        'hasReboot=${ids.contains(NotificationService.notificationIdFor('qa-reboot-restore'))}');
    expect(pending.length, 2,
        reason: 'both reminders must reach the plugin pending queue');

    debugPrint(
      'QATEST fireEpochExact=${fire.millisecondsSinceEpoch ~/ 1000} '
      'fireEpochReboot=${rebootFire.millisecondsSinceEpoch ~/ 1000}',
    );
  });
}
