import 'package:flutter/foundation.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Google Play in-app review prompt, gated so it only ever appears at a
/// moment the user has just earned something: completing a task.
///
/// Gating rules (all persisted in SharedPreferences so they survive
/// reinstalls of state via backups and across process restarts):
///
///   * At least [minCompletions] lifetime completions must be recorded
///     before the first prompt — never ask someone who just arrived.
///   * At most one prompt per [cooldown] (30 days) — the OS itself also
///     throttles the Play dialog, but this gate keeps the app side honest
///     and makes the completed-count cadence predictable.
///
/// The Google Play review API reports unavailable on devices without Play
/// services (e.g. open-source "github" flavor builds on de-Googled ROMs),
/// so this service is a silent no-op there — the same behavior the
/// in_app_purchase tip tiers already rely on. No flow is ever surfaced in
/// those builds because [isAvailable] resolves to false.
///
/// The prompt is always launched without a requestReview() surface of our
/// own: the moment (a just-completed task) IS the ask. Every failure is
/// swallowed and logged — the review flow is a nicety and must never
/// interfere with the completion interaction it was triggered from.
class ReviewService {
  ReviewService(this._sp, {InAppReview? inAppReview})
      : _inAppReview = inAppReview ?? InAppReview.instance;

  final SharedPreferences _sp;
  final InAppReview _inAppReview;

  /// Requires this many lifetime completions before the first prompt.
  static const int minCompletions = 3;

  /// Minimum time between two prompts.
  static const Duration cooldown = Duration(days: 30);

  static const String _kCompletions = 'review.completedCount';
  static const String _kLastPromptMs = 'review.lastPromptMs';

  /// Called after a task has been completed in the foreground UI.
  ///
  /// Increment-only: un-completing (toggles back) never decrements — the
  /// counter tracks engagement history, not current state.
  Future<void> onTaskCompleted() async {
    try {
      final count = _sp.getInt(_kCompletions) ?? 0;
      final newCount = count + 1;
      await _sp.setInt(_kCompletions, newCount);

      if (newCount < minCompletions) return;

      final lastMs = _sp.getInt(_kLastPromptMs) ?? 0;
      final last = DateTime.fromMillisecondsSinceEpoch(lastMs);
      if (DateTime.now().isBefore(last.add(cooldown))) return;

      // Check availability first: without Play services this is false and
      // the build (github flavor, emulators, de-Googled ROMs) no-ops.
      if (!await _inAppReview.isAvailable()) return;

      await _sp.setInt(
        _kLastPromptMs,
        DateTime.now().millisecondsSinceEpoch,
      );
      await _inAppReview.requestReview();
    } catch (e) {
      debugPrint('review prompt skipped: $e');
    }
  }
}
