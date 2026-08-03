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
}