import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:home_widget/home_widget.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:loopweek/core/haptics/haptics_service.dart';
import 'package:loopweek/core/theme/accent_colors.dart';
import 'package:loopweek/data/database/database.dart';
import 'package:loopweek/data/repositories/task_repository.dart';
import 'package:loopweek/data/services/home_widget_service.dart';
import 'package:loopweek/data/services/notification_service.dart';
import 'package:loopweek/data/services/settings_service.dart';
import 'package:loopweek/domain/models/task.dart';
import 'package:loopweek/presentation/onboarding/welcome_sheet.dart';
import 'package:loopweek/presentation/providers.dart';
import 'package:loopweek/presentation/week/week_providers.dart';
import 'package:loopweek/presentation/week/week_view.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>();

/// Created in [main] and handed to [UncontrolledProviderScope] so the
/// notification tap/action handlers can read providers without a widget
/// context (the service itself stays UI-free).
late final ProviderContainer _appContainer;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock flow to portrait on phones so the week view stays compact. Set once
  // at process start; rebuilding the app does not need to re-apply it.
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  // Allow the home-screen widget's checkbox taps to toggle completion in a
  // background isolate without opening the app. Registered once at startup.
  HomeWidget.registerInteractivityCallback(_widgetToggleCallback);

  // Reminder notification responses: foreground taps/actions are forwarded
  // to the UI-layer callback below; background action presses run in a
  // top-level isolate entry point.
  NotificationService.onForegroundAction = _handleForegroundReminderAction;
  NotificationService.backgroundResponseHandler =
      _notificationActionBackground;

  final container = ProviderContainer();
  _appContainer = container;
  runApp(
    UncontrolledProviderScope(container: container, child: const LoopweekApp()),
  );
}

/// Completion path shared by the home-widget checkbox callback and the
/// reminder notification actions (foreground and background). Opens its own
/// database connection — required inside background isolates, which have no
/// Riverpod graph — updates the row and re-renders the home-screen widget.
///
/// [markAsDone] true/false sets the flag explicitly (notification actions);
/// null toggles it (widget checkbox). Returns the row's prior completion
/// state, or null when the row is missing or the write failed.
Future<bool?> completeTaskFromBackground(String id, {bool? markAsDone}) async {
  bool? prior;
  try {
    final dir = await getApplicationDocumentsDirectory();
    final file = File(p.join(dir.path, 'loopweek.db'));
    final executor = NativeDatabase.createInBackground(file);
    final db = LoopweekDatabase.forTesting(executor);
    final rows = await db
        .customSelect('SELECT is_completed FROM tasks WHERE id = ?;', [id])
        .get();
    if (rows.isNotEmpty) {
      prior = ((rows.first.data['is_completed'] as int?) ?? 0) == 1;
    }
    final resolved = markAsDone ?? !(prior ?? false);
    await db.customStatement(
      'UPDATE tasks SET is_completed = ? WHERE id = ?;',
      [resolved ? 1 : 0, id],
    );
    // Re-render the widget now; without this the checkbox state would only
    // refresh on the next scheduled widget update (30 min) or the next
    // app-side snapshot push.
    await HomeWidgetService.refreshTaskSnapshot(TaskRepository(db));
    await db.close();
  } catch (e) {
    debugPrint('background completion error: $e');
  }
  return prior;
}

/// Runs in a background isolate when the user taps a widget checkbox. The
/// widget encodes the tapped task id as `loopweek://toggle?id=<taskId>`.
@pragma('vm:entry-point')
Future<void> _widgetToggleCallback(Uri? uri) async {
  if (uri == null || uri.host != 'toggle') return;
  final id = uri.queryParameters['id'];
  if (id == null || id.isEmpty) return;
  await completeTaskFromBackground(id);
}

/// Runs in a background isolate when a reminder notification action is
/// pressed while the app is not foregrounded (plain body taps launch the app
/// instead and are ignored here).
@pragma('vm:entry-point')
Future<void> _notificationActionBackground(NotificationResponse response) async {
  final payload = ReminderPayload.tryDecode(response.payload);
  if (payload == null) return;
  switch (ReminderAction.fromActionId(response.actionId)) {
    case ReminderAction.open:
      return;
    case ReminderAction.markDone:
      await _markDoneInBackground(payload);
    case ReminderAction.remindTomorrow:
      await _remindTomorrowInBackground(payload);
  }
}

/// Reads one task row on a background-isolate-owned database connection.
Future<Task?> _readTaskFromBackground(String id) async {
  try {
    final dir = await getApplicationDocumentsDirectory();
    final executor = NativeDatabase.createInBackground(
      File(p.join(dir.path, 'loopweek.db')),
    );
    final db = LoopweekDatabase.forTesting(executor);
    final task = await TaskRepository(db).getTask(id);
    await db.close();
    return task;
  } catch (e) {
    debugPrint('background task read error: $e');
    return null;
  }
}

Future<void> _markDoneInBackground(ReminderPayload payload) async {
  // The title is needed for the next-open undo snackbar and is not part of
  // the payload, so read the row before completing it.
  final task = await _readTaskFromBackground(payload.taskId);
  await completeTaskFromBackground(payload.taskId, markAsDone: true);
  // The action handler isolate has its own plugin instance; constructing a
  // fresh service here is the documented flutter_local_notifications way to
  // reach the plugin from a background isolate.
  await NotificationService().cancelTaskReminder(payload.taskId);
  if (task == null) return;
  try {
    final sp = await SharedPreferences.getInstance();
    await SettingsService(sp).setNotifLastDone(
      jsonEncode({
        'taskId': payload.taskId,
        'title': task.title,
        'ts': DateTime.now().millisecondsSinceEpoch,
      }),
    );
  } catch (e) {
    debugPrint('Could not record notif.lastDone: $e');
  }
}

Future<void> _remindTomorrowInBackground(ReminderPayload payload) async {
  final task = await _readTaskFromBackground(payload.taskId);
  final notif = NotificationService();
  if (task == null || !_reminderStillApplies(task)) {
    await notif.cancelTaskReminder(payload.taskId);
    return;
  }
  final sp = await SharedPreferences.getInstance();
  final settings = SettingsService(sp);
  if (!settings.alertsEnabled) {
    // Master switch off must mean no reminder ever fires — dismiss only.
    await notif.cancelTaskReminder(payload.taskId);
    return;
  }
  if (_isBeyondSevenDayLimit(task)) {
    await notif.cancelTaskReminder(payload.taskId);
    return;
  }
  await notif.scheduleTaskReminder(
    taskId: task.id,
    title: task.title,
    scheduled: _remindTomorrowFire(task),
    taskDate: task.date,
    accent: AccentColors.of(settings.colorTag),
  );
}

/// Fire time for a "Remind tomorrow" action: the task's canonical fire time
/// pushed 24h ahead — same time of day, only the notified row moves.
DateTime _remindTomorrowFire(Task task) =>
    NotificationService.fireDateTimeFor(task).add(const Duration(hours: 24));

/// "Remind tomorrow" may not push the reminder more than 7 days past the
/// task's date; beyond that the reminder is dismissed instead of moved.
bool _isBeyondSevenDayLimit(Task task) {
  final newFire = _remindTomorrowFire(task);
  final newFireDate = DateTime(newFire.year, newFire.month, newFire.day);
  final limit = DateTime(task.date.year, task.date.month, task.date.day)
      .add(const Duration(days: 7));
  return newFireDate.isAfter(limit);
}

/// Whether a reminder should still exist for [task]. A completed task, a
/// parked one, or one whose reminder was turned off since the notification
/// fired means the action must not re-arm anything.
bool _reminderStillApplies(Task task) =>
    task.hasReminder && !task.isCompleted && !task.isSomeday;

/// Foreground notification taps and actions, forwarded from the service.
Future<void> _handleForegroundReminderAction(
  ReminderAction action,
  ReminderPayload payload,
) async {
  switch (action) {
    case ReminderAction.open:
      _appContainer.read(expandedDayProvider.notifier).state = payload.taskDate;
    case ReminderAction.markDone:
      await _markDoneFromForeground(payload);
    case ReminderAction.remindTomorrow:
      await _remindTomorrowFromForeground(payload);
  }
}

Future<void> _markDoneFromForeground(ReminderPayload payload) async {
  final repo = _appContainer.read(taskRepositoryProvider);
  final notif = _appContainer.read(notificationServiceProvider);
  final task = await repo.getTask(payload.taskId);
  if (task == null || task.isCompleted) {
    // Row gone or already done: the reminder is stale, dismiss it only.
    await notif.cancelTaskReminder(payload.taskId);
    return;
  }
  await completeTaskFromBackground(payload.taskId, markAsDone: true);
  await notif.cancelTaskReminder(payload.taskId);
  _invalidateTaskStreams();
  final context = _rootNavigatorKey.currentContext;
  if (context == null) return;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text('Done from reminder · ${task.title}'),
      duration: const Duration(seconds: 6),
      action: SnackBarAction(
        label: 'Undo',
        onPressed: () => _undoCompletionFromForeground(payload.taskId),
      ),
    ),
  );
}

/// Restores the prior (incomplete) state, but only if the row is still
/// completed — if the user re-toggled it in the meantime there is nothing
/// to undo.
Future<void> _undoCompletionFromForeground(String taskId) async {
  final task = await _appContainer.read(taskRepositoryProvider).getTask(taskId);
  if (task == null || !task.isCompleted) return;
  await completeTaskFromBackground(taskId, markAsDone: false);
  _invalidateTaskStreams();
}

Future<void> _remindTomorrowFromForeground(ReminderPayload payload) async {
  final repo = _appContainer.read(taskRepositoryProvider);
  final notif = _appContainer.read(notificationServiceProvider);
  final settings = _appContainer.read(settingsProvider);
  final task = await repo.getTask(payload.taskId);
  final canReschedule = task != null &&
      _reminderStillApplies(task) &&
      settings.alertsEnabled &&
      !_isBeyondSevenDayLimit(task);
  if (!canReschedule) {
    // Completed / parked / reminder off / switch off / window passed:
    // dismiss only, nothing is rescheduled.
    await notif.cancelTaskReminder(payload.taskId);
    return;
  }
  await notif.scheduleTaskReminder(
    taskId: task.id,
    title: task.title,
    scheduled: _remindTomorrowFire(task),
    taskDate: task.date,
    accent: AccentColors.of(settings.colorTag),
  );
}

/// The shared completion helper writes through its own database connection,
/// so drift's reactive streams on the main connection never hear about the
/// change. Invalidate them so the visible week reflects it immediately.
void _invalidateTaskStreams() {
  _appContainer.invalidate(tasksForDateProvider);
  _appContainer.invalidate(somedayTasksProvider);
  _appContainer.invalidate(hasAnyTasksProvider);
}

class LoopweekApp extends ConsumerWidget {
  const LoopweekApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);

    // Keep the lightweight haptics helper in sync with the user's toggle.
    Haptics.enabled = settings.hapticsEnabled;

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Loopweek',
      navigatorKey: _rootNavigatorKey,
      theme: settings.lightTheme(),
      darkTheme: settings.darkTheme(),
      themeMode: settings.themeMode,
      home: OnboardingGate(
        child: KeyedSubtree(
          key: ValueKey(settings.colorTag),
          child: const ReminderBootstrapper(child: WeekView()),
        ),
      ),
    );
  }
}

/// Runs the one-shot reminder reconciliation right after the first frame.
///
/// Scheduled notifications are the one feature that can be silently lost
/// behind the app's back (force-stop, plugin cache wipe, alarms dropped by
/// the OS, ids from an older build). Reconciling against the database on
/// every start makes reminders self-healing instead.
class ReminderBootstrapper extends ConsumerStatefulWidget {
  const ReminderBootstrapper({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<ReminderBootstrapper> createState() =>
      _ReminderBootstrapperState();
}

class _ReminderBootstrapperState extends ConsumerState<ReminderBootstrapper> {
  /// The subtree is re-keyed whenever the accent color changes; the sync must
  /// still run only once per process.
  static bool _syncStarted = false;

  @override
  void initState() {
    super.initState();
    if (_syncStarted) return;
    _syncStarted = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      // Kick-and-forget: the provider captures the result (and any error is
      // logged inside the provider itself, never thrown here).
      unawaited(ref.read(reminderSyncProvider.future));
      unawaited(_handleNextOpenNotifications());
    });
  }

  /// One-shot per process, at the first frame after the app home is up:
  ///
  /// - If the process was started by a notification body tap (cold start),
  ///   expand the payload's day.
  /// - If a background "Mark done" action ran since the last open (within
  ///   the 15-minute undo window and the row is still completed), surface
  ///   the same undo snackbar the foreground action shows.
  ///
  /// The stored last-done record is cleared afterwards either way.
  Future<void> _handleNextOpenNotifications() async {
    final messenger = ScaffoldMessenger.of(context);
    final repo = ref.read(taskRepositoryProvider);
    final notif = ref.read(notificationServiceProvider);
    final expandedDay = ref.read(expandedDayProvider.notifier);

    await notif.ensureInitialized();
    final launch = await notif.launchDetails();
    final response = launch?.notificationResponse;
    if (launch?.didNotificationLaunchApp ?? false) {
      if (response?.actionId == null) {
        final payload = ReminderPayload.tryDecode(response?.payload);
        if (payload != null) {
          expandedDay.state = payload.taskDate;
        }
      }
    }

    final sp = await SharedPreferences.getInstance();
    final settings = SettingsService(sp);
    final raw = settings.notifLastDone;
    if (raw == null) return;
    final record = _decodeLastDone(raw);
    if (record != null) {
      final age = DateTime.now()
          .difference(DateTime.fromMillisecondsSinceEpoch(record.ts));
      final task = age <= const Duration(minutes: 15)
          ? await repo.getTask(record.taskId)
          : null;
      if (task != null && task.isCompleted) {
        messenger.showSnackBar(
          SnackBar(
            content: Text('Done from reminder · ${record.title}'),
            duration: const Duration(seconds: 6),
            action: SnackBarAction(
              label: 'Undo',
              onPressed: () async {
                final current = await repo.getTask(record.taskId);
                if (current == null || !current.isCompleted) return;
                await completeTaskFromBackground(
                  record.taskId,
                  markAsDone: false,
                );
                _invalidateTaskStreams();
              },
            ),
          ),
        );
      }
    }
    // Handled or not, the record exists only for the next open — clear it.
    await settings.clearNotifLastDone();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

/// Decoded `notif.lastDone` record written by the background mark-done path.
class _LastDoneRecord {
  const _LastDoneRecord({
    required this.taskId,
    required this.title,
    required this.ts,
  });

  final String taskId;
  final String title;
  final int ts;
}

_LastDoneRecord? _decodeLastDone(String raw) {
  try {
    final Object? decoded = jsonDecode(raw);
    if (decoded is! Map ||
        decoded['taskId'] is! String ||
        decoded['title'] is! String ||
        decoded['ts'] is! int) {
      return null;
    }
    return _LastDoneRecord(
      taskId: decoded['taskId'] as String,
      title: decoded['title'] as String,
      ts: decoded['ts'] as int,
    );
  } catch (_) {
    return null;
  }
}
