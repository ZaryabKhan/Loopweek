import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:loopweek/domain/models/color_tag.dart';

/// Persistent user settings: chosen accent color, theme mode, and the
/// "Times & Alerts" toggle.
///
/// Persisted with SharedPreferences. No cloud, no telemetry — 100% local.
class SettingsService {
  SettingsService(this._prefs);

  final SharedPreferences _prefs;

  static const _kColorTag = 'settings.colorTag';
  static const _kThemeMode = 'settings.themeMode';
  static const _kOnboardingSeen = 'onboarding.seen';
  static const _kLongPressHintSeen = 'onboarding.longPressHintSeen';

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

  /// Whether the first-run welcome sheet has been shown (and dismissed).
  bool get onboardingSeen => _prefs.getBool(_kOnboardingSeen) ?? false;
  Future<void> setOnboardingSeen() => _prefs.setBool(_kOnboardingSeen, true);

  /// Whether the one-time "hold a task" hint has been dismissed or made
  /// redundant by the user discovering the long-press gesture.
  bool get longPressHintSeen => _prefs.getBool(_kLongPressHintSeen) ?? false;
  Future<void> setLongPressHintSeen() =>
      _prefs.setBool(_kLongPressHintSeen, true);
}
