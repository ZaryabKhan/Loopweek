import 'package:flutter/services.dart';

/// A tiny, app-wide haptics helper. It abstracts [HapticFeedback] so the UI
/// layer can fire subtle feedback without importing services directly, and
/// it makes it easy to respect a user-level "disable haptics" toggle.
abstract final class Haptics {
  /// Whether haptic feedback is enabled. Set once when settings load; defaults
  /// to true for a premium feel.
  static bool enabled = true;

  /// Light impact for minor UI confirmations: toggling a checkbox, tapping an
  /// accordion header, switching a toggle, etc.
  static void light() {
    if (!enabled) return;
    HapticFeedback.lightImpact();
  }

  /// Medium impact for more substantial actions: saving a task, opening a
  /// sheet, snapping a segmented control, etc.
  static void medium() {
    if (!enabled) return;
    HapticFeedback.mediumImpact();
  }

  /// A short selection click for discrete value changes: time picker wheels,
  /// day selector taps, segmented control switches, etc.
  static void selection() {
    if (!enabled) return;
    HapticFeedback.selectionClick();
  }
}
