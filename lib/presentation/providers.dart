import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:loopweek/core/theme/app_theme.dart';
import 'package:loopweek/data/database/database.dart';
import 'package:loopweek/data/repositories/task_repository.dart';
import 'package:loopweek/data/services/notification_service.dart';
import 'package:loopweek/data/services/settings_service.dart';
import 'package:loopweek/data/services/home_widget_service.dart';
import 'package:loopweek/domain/models/color_tag.dart';

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

final notificationServiceProvider = Provider<NotificationService>(
  (ref) => NotificationService(),
);

final homeWidgetServiceProvider = Provider<HomeWidgetService>(
  (ref) => HomeWidgetService(ref.watch(taskRepositoryProvider)),
);

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
  bool onboardingSeen = false;
  bool longPressHintSeen = false;
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
    onboardingSeen = service.onboardingSeen;
    longPressHintSeen = service.longPressHintSeen;
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

  ThemeData lightTheme() => AppTheme.light(colorTag);
  ThemeData darkTheme() => AppTheme.dark(colorTag);
}
