import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:loopweek/domain/models/color_tag.dart';
import 'package:loopweek/domain/models/first_day_of_week.dart';

/// Persistent user settings: chosen accent color, theme mode, and the
/// "Times & Alerts" toggle.
///
/// Persisted with SharedPreferences. No cloud, no telemetry — 100% local.
class SettingsService {
  SettingsService(this._prefs);

  final SharedPreferences _prefs;

  static const _kColorTag = 'settings.colorTag';
  static const _kThemeMode = 'settings.themeMode';
  static const _kFirstDayOfWeek = 'settings.firstDayOfWeek';
  static const _kOnboardingSeen = 'onboarding.seen';
  static const _kLongPressHintSeen = 'onboarding.longPressHintSeen';
  static const _kAlertsEnabled = 'settings.alertsEnabled';
  static const _kHapticsEnabled = 'settings.hapticsEnabled';
  static const _kRitualLastSeenWeekStart = 'ritual.lastSeenWeekStart';

  ColorTag get colorTag => ColorTag.fromName(_prefs.getString(_kColorTag));
  Future<void> setColorTag(ColorTag tag) =>
      _prefs.setString(_kColorTag, tag.name);

  ThemeMode get themeMode {
    switch (_prefs.getString(_kThemeMode)) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      case 'system':
      default:
        return ThemeMode.system;
    }
  }

  Future<void> setThemeMode(ThemeMode mode) {
    final value = mode == ThemeMode.light
        ? 'light'
        : mode == ThemeMode.dark
        ? 'dark'
        : 'system';
    return _prefs.setString(_kThemeMode, value);
  }

  /// Which day the week view starts on. 'system' follows the device locale.
  FirstDayOfWeek get firstDayOfWeek =>
      FirstDayOfWeek.fromName(_prefs.getString(_kFirstDayOfWeek));
  Future<void> setFirstDayOfWeek(FirstDayOfWeek value) =>
      _prefs.setString(_kFirstDayOfWeek, value.name);

  /// Whether the user has enabled the "Times & Alerts" master switch. This is
  /// the global gate for Loopweek task reminders.
  ///
  /// Defaults to true when the key was never written: that is the upgrade
  /// path from builds without a master switch, where reminders were armed
  /// purely per-task — those reminders must keep working. Fresh installs are
  /// unaffected: nothing happens until the user actually sets a reminder.
  bool get alertsEnabled => _prefs.getBool(_kAlertsEnabled) ?? true;
  Future<void> setAlertsEnabled(bool value) =>
      _prefs.setBool(_kAlertsEnabled, value);

  /// Whether haptic feedback is enabled for subtle interactions (checkboxes,
  /// toggles, accordion taps, etc.). Defaults to true for a premium feel.
  bool get hapticsEnabled => _prefs.getBool(_kHapticsEnabled) ?? true;
  Future<void> setHapticsEnabled(bool value) =>
      _prefs.setBool(_kHapticsEnabled, value);

  /// Whether the first-run welcome sheet has been shown (and dismissed).
  bool get onboardingSeen => _prefs.getBool(_kOnboardingSeen) ?? false;
  Future<void> setOnboardingSeen() => _prefs.setBool(_kOnboardingSeen, true);

  /// Whether the one-time "hold a task" hint has been dismissed or made
  /// redundant by the user discovering the long-press gesture.
  bool get longPressHintSeen => _prefs.getBool(_kLongPressHintSeen) ?? false;
  Future<void> setLongPressHintSeen() =>
      _prefs.setBool(_kLongPressHintSeen, true);

  /// Week start (date-only ISO string, yyyy-MM-dd) the fresh-week ritual
  /// banner was last rendered for — written at render, once per week.
  String? get ritualLastSeenWeekStart =>
      _prefs.getString(_kRitualLastSeenWeekStart);
  Future<void> setRitualLastSeenWeekStart(String weekStartIso) =>
      _prefs.setString(_kRitualLastSeenWeekStart, weekStartIso);

  /// Per-week dismissal flag for the ritual banner, keyed by the week's
  /// start date so a new week re-arms automatically.
  bool isRitualBannerDismissed(String weekStartIso) =>
      _prefs.getBool('ritual.bannerDismissed:$weekStartIso') ?? false;
  Future<void> setRitualBannerDismissed(String weekStartIso) =>
      _prefs.setBool('ritual.bannerDismissed:$weekStartIso', true);
}
