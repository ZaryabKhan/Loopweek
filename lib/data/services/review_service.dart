import 'package:flutter/foundation.dart';
import 'package:in_app_review/in_app_review.dart';

import 'package:loopweek/data/services/settings_service.dart';

/// Launches the Google Play review dialog. A separate interface so unit
/// tests can substitute a fake — the real one touches a platform channel,
/// which must never load during widget smoke tests.
abstract class ReviewLauncher {
  /// True when this device can show the Play review dialog.
  Future<bool> isAvailable();

  /// Opens the quota-limited Play in-app review dialog.
  Future<void> requestReview();

  /// Opens the Play Store listing in the Play app (no quota).
  Future<void> openStoreListing();
}

/// The real launcher, backed by the in_app_review plugin.
class PlayReviewLauncher implements ReviewLauncher {
  const PlayReviewLauncher();

  @override
  Future<bool> isAvailable() => InAppReview.instance.isAvailable();

  @override
  Future<void> requestReview() => InAppReview.instance.requestReview();

  @override
  Future<void> openStoreListing() => InAppReview.instance.openStoreListing();
}

/// Decides when to ask for a Play rating, and asks.
///
/// Fires only at earned moments:
///
/// - Completing a task in the week view, via [recordCompletionAndMaybeAsk]
///   — but only once at least [_minCompletionsForAsk] tasks have been
///   completed in the app's whole history (persisted counter), so the ask
///   lands on an established habit, not a first tickle.
/// - Dismissing the fresh-week ritual banner after engaging with it
///   ([maybeAskForReview] directly).
///
/// Widget-checkbox and notification "Mark done" completions increment the
/// same counter but never attempt the ask — requestReview() from a
/// background isolate can silently no-op yet still burn Google's 30-day
/// quota window.
///
/// All other gating lives here:
///
/// - Playstore flavor only: [iapBuild] is injected at construction from
///   the compile-time DONATION_MODE constant, so the github flavor
///   (polar, the default) never reaches the review flow at runtime.
/// - 30-day cooldown after ANY attempt (the API exposes no dialog
///   outcome, so a decline costs the same cooldown as a rating),
///   persisted in SharedPreferences via [SettingsService] — survives app
///   restarts, which is what the quota needs.
/// - Once per session on top, so a burst of earned moments in one
///   sitting can only ever reach the dialog once.
///
/// Data-layer service per the app architecture: no BuildContext, no UI.
/// Every platform-channel call is fire-and-forget safe — [maybeAskForReview]
/// never throws (failures are logged and swallowed), so triggering it right
/// after a task completion can never surface an error or block the toggle's
/// await chain (ANR lens: nothing platform-channel sits under a UI
/// gesture's critical path).
class ReviewService {
  ReviewService({
    required bool iapBuild,
    required SettingsService settings,
    ReviewLauncher? launcher,
    DateTime Function()? clock,
  }) : _iapBuild = iapBuild,
       _settings = settings,
       _launcher = launcher ?? const PlayReviewLauncher(),
       _now = clock ?? DateTime.now;

  final bool _iapBuild;
  final SettingsService _settings;
  final ReviewLauncher _launcher;
  final DateTime Function() _now;

  /// Google throttles requestReview() unpredictably and silently; the app
  /// enforces its own visible rule instead of retrying into the quota.
  static const _cooldown = Duration(days: 30);

  /// Minimum lifetime task completions before an earned moment may ask.
  static const _minCompletionsForAsk = 3;

  bool _askedThisSession = false;

  /// True until this session has fired one earned-moment prompt.
  bool get canAskThisSession => !_askedThisSession;

  /// Records one real completion (app toggle, widget checkbox, or
  /// notification mark-done) and then evaluates the earned moment. The
  /// counter is cumulative and persisted, so the gate survives process
  /// death. Returns true when the dialog was actually requested.
  Future<bool> recordCompletionAndMaybeAsk() async {
    try {
      await _settings.setReviewCompletedTasks(
        _settings.reviewCompletedTasks + 1,
      );
    } catch (e) {
      debugPrint('Review completion count failed: $e');
    }
    return maybeAskForReview();
  }

  /// Evaluated at an earned moment. Returns true when the review dialog was
  /// actually requested (all gates passed); callers may ignore the result.
  Future<bool> maybeAskForReview() async {
    if (!_iapBuild) return false;
    if (_askedThisSession) return false;
    if (_settings.reviewCompletedTasks < _minCompletionsForAsk) {
      return false;
    }
    final last = _settings.reviewLastAttemptMs;
    final now = _now().millisecondsSinceEpoch;
    if (last != null && now - last < _cooldown.inMilliseconds) {
      return false;
    }
    try {
      if (!await _launcher.isAvailable()) return false;
      // Arm the cooldown BEFORE awaiting the dialog: requestReview()
      // resolves when the dialog closes (or is silently skipped by Play),
      // and a decline or process death mid-dialog must still count as an
      // attempt.
      _askedThisSession = true;
      await _settings.setReviewLastAttemptMs(now);
      await _launcher.requestReview();
      return true;
    } catch (e) {
      // Unavailable on some devices/storeless builds, or a transient
      // failure. Never propagate — the earned moment just ends quietly.
      debugPrint('Review flow failed: $e');
      return false;
    }
  }

  /// Settings row: the user explicitly asked for the rating screen.
  /// Bypasses the earned-moment gates (it IS the user's decision) but still
  /// records the attempt so the automatic prompt stays on the same 30-day
  /// rhythm. Falls back to the plain store listing when the dialog is
  /// unavailable or fails — the listing can always be rated.
  Future<void> openRatingScreen() async {
    try {
      if (await _launcher.isAvailable()) {
        await _settings.setReviewLastAttemptMs(_now().millisecondsSinceEpoch);
        await _launcher.requestReview();
      } else {
        await _launcher.openStoreListing();
      }
    } catch (e) {
      debugPrint('Rating screen failed: $e');
      try {
        await _launcher.openStoreListing();
      } catch (e2) {
        debugPrint('Store listing also failed: $e2');
      }
    }
  }
}
