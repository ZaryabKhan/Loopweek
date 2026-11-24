import 'package:flutter/foundation.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Google Play in-app review prompt, gated so it only ever appears right
/// after the user completed a task — a moment of visible progress.
///
/// Gating rules (persisted in SharedPreferences across restarts):
///
///   * At least [minCompletions] lifetime completions before the first
///     prompt — never ask someone who just arrived.
///   * At most one prompt per [cooldown] — the OS throttles the Play dialog
///     too; this gate keeps the app-side cadence predictable.
///
/// Without Play services (open-source github flavor, de-Googled ROMs,
/// emulators), `isAvailable()` resolves false and this is a silent no-op —
/// the same convention as the in_app_purchase tip tiers. No Android
/// permission is involved: the dialog is rendered by the Play Store app
/// over IPC.
///
/// Best-effort by design: every failure is swallowed and logged so the
/// review flow can never interfere with the completion interaction that
/// triggered it.
class ReviewService {
  ReviewService(this._prefsFuture, {InAppReview? inAppReview})
      : _inAppReview = inAppReview ?? InAppReview.instance;

  /// Resolved lazily inside [onTaskCompleted]; by the time a completion can
  /// happen, SharedPreferences are always ready.
  final Future<SharedPreferences> _prefsFuture;

  final InAppReview _inAppReview;

  /// Lifetime completions required before the first prompt.
  static const int minCompletions = 3;

  /// Minimum time between two prompts.
  static const Duration cooldown = Duration(days: 30);

  static const String _kCompletions = 'review.completedCount';
  static const String _kLastPromptMs = 'review.lastPromptMs';

  /// Called after a foreground task completion — never on un-complete, and
  /// never from the background widget/notification paths.
  ///
  /// The counter is increment-only: un-completing never decrements. It
  /// tracks engagement history, not current state.
  Future<void> onTaskCompleted() async {
    try {
      final sp = await _prefsFuture;

      final count = (sp.getInt(_kCompletions) ?? 0) + 1;
      await sp.setInt(_kCompletions, count);
      if (count < minCompletions) return;

      final lastMs = sp.getInt(_kLastPromptMs) ?? 0;
      final nextAllowed =
          DateTime.fromMillisecondsSinceEpoch(lastMs).add(cooldown);
      if (DateTime.now().isBefore(nextAllowed)) return;

      // Without Play services this resolves false and the call no-ops.
      if (!await _inAppReview.isAvailable()) return;

      // Reserve the cooldown slot before launching: if the system drops
      // the dialog anyway, we still wait 30 days before trying again.
      await sp.setInt(_kLastPromptMs, DateTime.now().millisecondsSinceEpoch);
      await _inAppReview.requestReview();
    } catch (e) {
      debugPrint('Review prompt skipped: $e');
    }
  }
}
