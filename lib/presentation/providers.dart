import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:loopweek/core/theme/accent_colors.dart';
import 'package:loopweek/core/theme/app_theme.dart';
import 'package:loopweek/data/database/database.dart';
import 'package:loopweek/data/repositories/task_repository.dart';
import 'package:loopweek/data/repositories/week_template_repository.dart';
import 'package:loopweek/data/services/backup_service.dart';
import 'package:loopweek/data/services/notification_service.dart';
import 'package:loopweek/data/services/settings_service.dart';
import 'package:loopweek/data/services/home_widget_service.dart';
import 'package:loopweek/domain/models/color_tag.dart';
import 'package:loopweek/domain/models/first_day_of_week.dart';

// ---- infra ----------------------------------------------------------------

final sharedPreferencesProvider = FutureProvider<SharedPreferences>(
  (ref) => SharedPreferences.getInstance(),
);

final databaseProvider = Provider<LoopweekDatabase>(
  (ref) => LoopweekDatabase(),
);

final taskRepositoryProvider = Provider<TaskRepository>(
  (ref) => TaskRepository(ref.watch(databaseProvider)),
);

final weekTemplateRepositoryProvider = Provider<WeekTemplateRepository>(
  (ref) => WeekTemplateRepository(
    ref.watch(databaseProvider),
    ref.watch(taskRepositoryProvider),
  ),
);

/// Live list of saved week templates, newest first. Feeds the picker sheet.
final weekTemplatesProvider = StreamProvider<List<TemplateSummary>>(
  (ref) => ref.watch(weekTemplateRepositoryProvider).watchTemplates(),
);

final notificationServiceProvider = Provider<NotificationService>(
  (ref) => NotificationService(),
);

/// One-shot startup reconciliation of scheduled reminders against the
/// database. Watched by the reminder bootstrapper in `main.dart`, so it runs
/// exactly once per app session: reminders lost to force-stops, plugin cache
/// wipes, or stale ids from older builds are re-scheduled, and pending
/// reminders for tasks that no longer need them are cancelled.
///
/// The reconciliation respects the Times & Alerts master switch: with the
/// switch off, reminders must not fire, so any stragglers are cancelled.
/// Settings load asynchronously; watching [settingsProvider] re-runs this
/// provider automatically once `load()` completes and notifies, so the early
/// return below is a temporary no-op, never a skipped sync. Failures are
/// logged, never surfaced — reminders are a best-effort nicety, not a reason
/// to break startup.
final reminderSyncProvider = FutureProvider<void>((ref) async {
  final settings = ref.watch(settingsProvider);
  if (!settings.isLoaded) return;
  try {
    final notifications = ref.watch(notificationServiceProvider);
    if (!settings.alertsEnabled) {
      await notifications.cancelAllReminders();
      return;
    }
    final repo = ref.watch(taskRepositoryProvider);
    final upcoming = await repo.tasksWithRemindersFrom(DateTime.now());
    await notifications.syncReminders(
      upcoming,
      accent: AccentColors.of(settings.colorTag),
    );
  } catch (e) {
    debugPrint('Reminder startup sync failed: $e');
  }
});

final homeWidgetServiceProvider = Provider<HomeWidgetService>(
  (ref) => HomeWidgetService(ref.watch(taskRepositoryProvider)),
);

/// SharedPreferences arrive via [sharedPreferencesProvider], so — like the
/// settings load itself — the backup service resolves once prefs are ready.
/// Reading `.future` later (e.g. on a settings-screen tap) is instantaneous.
final backupServiceProvider = FutureProvider<BackupService>((ref) async {
  final sp = await ref.watch(sharedPreferencesProvider.future);
  return BackupService(ref.watch(taskRepositoryProvider), SettingsService(sp));
});

// ---- settings -------------------------------------------------------------

/// Single observer-based controller, exposed as [ChangeNotifierProvider] for
/// simple synchronous reads + reactive theme rebuilds. The framework
/// auto-disposes the ChangeNotifier; we therefore only need to prime it.
final settingsProvider = ChangeNotifierProvider<ActiveSettings>((ref) {
  final notifier = ActiveSettings(ref);
  notifier.load();
  return notifier;
});

class ActiveSettings extends ChangeNotifier {
  ActiveSettings(this._ref);
  final Ref _ref;

  ColorTag colorTag = ColorTag.defaultValue;
  ThemeMode themeMode = ThemeMode.system;
  FirstDayOfWeek firstDayOfWeek = FirstDayOfWeek.system;
  bool onboardingSeen = false;
  bool longPressHintSeen = false;
  bool alertsEnabled = true;
  bool hapticsEnabled = true;
  bool isLoaded = false;
  bool _disposed = false;

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  Future<void> load() async {
    final sp = await _ref.read(sharedPreferencesProvider.future);
    final service = SettingsService(sp);
    colorTag = service.colorTag;
    themeMode = service.themeMode;
    firstDayOfWeek = service.firstDayOfWeek;
    onboardingSeen = service.onboardingSeen;
    longPressHintSeen = service.longPressHintSeen;
    alertsEnabled = service.alertsEnabled;
    hapticsEnabled = service.hapticsEnabled;
    isLoaded = true;
    _notify();
  }

  Future<void> setColorTag(ColorTag tag) async {
    final sp = _ref.read(sharedPreferencesProvider).valueOrNull;
    if (sp == null) return;
    await SettingsService(sp).setColorTag(tag);
    colorTag = tag;
    _notify();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    final sp = _ref.read(sharedPreferencesProvider).valueOrNull;
    if (sp == null) return;
    await SettingsService(sp).setThemeMode(mode);
    themeMode = mode;
    _notify();
  }

  Future<void> setFirstDayOfWeek(FirstDayOfWeek value) async {
    final sp = _ref.read(sharedPreferencesProvider).valueOrNull;
    if (sp == null) return;
    await SettingsService(sp).setFirstDayOfWeek(value);
    firstDayOfWeek = value;
    _notify();
  }

  Future<void> setOnboardingSeen() async {
    final sp = _ref.read(sharedPreferencesProvider).valueOrNull;
    if (sp == null) return;
    await SettingsService(sp).setOnboardingSeen();
    onboardingSeen = true;
    _notify();
  }

  Future<void> setLongPressHintSeen() async {
    final sp = _ref.read(sharedPreferencesProvider).valueOrNull;
    if (sp == null) return;
    await SettingsService(sp).setLongPressHintSeen();
    longPressHintSeen = true;
    _notify();
  }

  Future<void> setAlertsEnabled(bool value) async {
    final sp = _ref.read(sharedPreferencesProvider).valueOrNull;
    if (sp == null) return;
    await SettingsService(sp).setAlertsEnabled(value);
    alertsEnabled = value;
    _notify();
  }

  Future<void> setHapticsEnabled(bool value) async {
    final sp = _ref.read(sharedPreferencesProvider).valueOrNull;
    if (sp == null) return;
    await SettingsService(sp).setHapticsEnabled(value);
    hapticsEnabled = value;
    _notify();
  }

  ThemeData lightTheme() => AppTheme.light(colorTag);
  ThemeData darkTheme() => AppTheme.dark(colorTag);
}
